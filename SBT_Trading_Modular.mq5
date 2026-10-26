//+------------------------------------------------------------------+
//|                                                sbt_trading.mq5   |
//|                                    Copyright 2026, sbt_trading   |
//|                                          Modular entry point     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, sbt_trading"
#property version   "1.20"
#property strict

#include <SBT/SBT_Common.mqh>
#include <SBT/SBT_State.mqh>
#include <SBT/SBT_Utils.mqh>
#include <SBT/SBT_Drawing.mqh>
#include <SBT/SBT_Trend.mqh>
#include <SBT/SBT_Retracement.mqh>
#include <SBT/SBT_Zones.mqh>
#include <SBT/SBT_ABCDE.mqh>
#include <SBT/SBT_Entry_Models.mqh>
#include <SBT/SBT_Position.mqh>
#include <SBT/HTF_Trend.mqh>
#include <SBT/HTF_Drawing.mqh>
#include <SBT/SBT_Dashboard.mqh>

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   ea_magic = MagicNumber;
   trendDirection = TrendDirection;
   
   if(UseHTFTrendFilter)
   Print("   HTF Filter: ", EnumToString(HTF_Period), " ON");

   Print("========================================");
   Print("SBT_TRADING EA INITIALIZED");
   Print("   Trend Direction: ", trendDirection == 1 ? "BULLISH" : "BEARISH");
   Print("   Magic Number: ", ea_magic);
   Print("   Show ABCDE Visuals: ", ShowABCDEVisuals ? "ON" : "OFF");
   Print("========================================");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeleteDashboard();
   Print("SBT_TRADING EA deinitialized");
}

//+------------------------------------------------------------------+
//| Main OnTick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   bool newBar = false;
   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      newBar = true;
      abcdeChochFiredThisBar = false;  // reset priority flag each new bar
   }

   // Update HTF trend (runs only on new HTF bar internally)
   if(UseHTFTrendFilter)
      UpdateHTFTrend();
      
   // =================================================================
   // 1. REAL-TIME POSITION MANAGEMENT & SBT-2 ENTRY (Runs every tick)
   // =================================================================
   CheckPartialProfit();
   UpdatePositionManagement();
   
    if(!trendContinuationConfirmed)
   {
      CheckSBT1Entry();
      CheckSBT2Entry();
      CheckSBT3Entry();
      MonitorMBTrade();
   }

   // =================================================================
   // 2. BAR-CLOSE LOGIC (Only runs on new bars)
   // =================================================================
   
   if(!newBar) return;
   
    if(ObjectFind(0, "MotherCandle_Box") >= 0)
      Print("✅ Box exists on chart at ", TimeToString((datetime)ObjectGetInteger(0, "MotherCandle_Box", OBJPROP_TIME, 0)));
   else
      Print("❌ Box not found");
      
   // Refresh dashboard
   UpdateDashboard();

   totalBars = Bars(_Symbol, PERIOD_CURRENT);
   if(totalBars < 10) return;

   DetectTrend();
   if(!IsTrendEstablished()) return;

   if(trendDirection == 1)
      UpdateDZStatus();
   else
      UpdateSZStatus();

   UpdateMBStatus();

   // MSS zone mitigation tracking
   UpdateBBBStatus();
   UpdateQMLStatus();
   UpdateDBStatus();
   UpdateDTStatus();
   UpdateSBBStatus();

   // Grow live zones' right edge to last closed bar
   ExtendZoneRightEdges();

   CheckTrendContinuation();

   // ============ ABCDE RULE CHECK + Update ============
   int abcdeRuleUsed = 0;
   double abcdeTriggerPrice = 0;
   bool abcdeRuleFired = false;

   if(trendDirection == 1)
      abcdeRuleFired = CheckBullishRetracementRulesABCDE(abcdeRuleUsed, abcdeTriggerPrice);
   else
      abcdeRuleFired = CheckBearishRetracementRulesABCDE(abcdeRuleUsed, abcdeTriggerPrice);
   
   // FORCE ABCDE to update if it is already active (tracking B, C, D)
   if(abcdeActive)
      abcdeRuleFired = true; 
   
      UpdateABCDE(abcdeRuleFired, abcdeRuleUsed, abcdeTriggerPrice);

   // --- FORCE 5-WAVE FLIP IF BODY CLOSES BEYOND C ---
   if(abcdeActive && abcdeWave == 3 && abcdeC > 0)
   {
      double currClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      
      bool eConfirmed = false;
      if(trendDirection == 1 && currClose < abcdeC) eConfirmed = true;
      if(trendDirection == -1 && currClose > abcdeC) eConfirmed = true;
      
      if(eConfirmed)
      {
         Print("🎯 LTF FORCE FLIP: 5-Wave completed (body closed beyond C)");
         
         // Update Dashboard
         htfLastSwitchReason = "ABCDE 5-Wave";
         htfLastSwitchTime = iTime(_Symbol, PERIOD_CURRENT, 1);
         
         // Refresh dashboard
         UpdateDashboard();
         
         if(trendDirection == 1) // Bullish → Bearish
         {
            trendDirection = -1;
            bullishTrendEstablished = false;
            highestHighSinceTrendStart = 0;
            bearishTrendEstablished = true;
            lowestLowSinceTrendStart = currClose;
            lowestLowSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, 1);
         }
         else // Bearish → Bullish
         {
            trendDirection = 1;
            bearishTrendEstablished = false;
            lowestLowSinceTrendStart = 0;
            bullishTrendEstablished = true;
            highestHighSinceTrendStart = currClose;
            highestHighSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, 1);
         }
         
         
         // Reset ABCDE & clear Mother Candle
         abcdeWave = 0;
         abcdeActive = false;
         motherCandleActive = false;
         ObjectDelete(0, "MotherCandle_Box");
         ObjectDelete(0, "MotherCandle_Label");
      }
   }


   // ============ CHOCH CONFIRMATION (skip if ABCDE fired this bar) ============
   if(!abcdeChochFiredThisBar && !chochConfirmed && currentChoChLevel > 0)
   {
      double currentClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      double previousClose = iClose(_Symbol, PERIOD_CURRENT, 2);

      if(trendDirection == 1)
      {
         bool currentBelow = (currentClose < currentChoChLevel);
         bool previousBelow = (previousClose < currentChoChLevel);

         if(currentBelow && previousBelow)
         {
            chochConfirmed = true;
            Print("🎯 CHOCH/MSS CONFIRMED! (Bullish → Bearish)");
            DrawChoChConfirmation(currentChoChLevel, currentBarTime);
            
            SwitchToBearish(currentClose, currentBarTime);
         }
      }
      else if(trendDirection == -1)
      {
         bool currentAbove = (currentClose > currentChoChLevel);
         bool previousAbove = (previousClose > currentChoChLevel);

         if(currentAbove && previousAbove)
         {
            chochConfirmed = true;
            Print("🎯 CHOCH/MSS CONFIRMED! (Bearish → Bullish)");
            DrawChoChConfirmation(currentChoChLevel, currentBarTime);
            SwitchToBullish(currentClose, currentBarTime);
         }
      }
   }
   
   // ============ UPDATE HH/LL WITH TIME ============
   if(trendDirection == 1)
   {
      double currentCandleHigh = iHigh(_Symbol, PERIOD_CURRENT, 1);
      if(currentCandleHigh > highestHighSinceTrendStart)
      {
         Print("🔼 HH Updated: Old=", highestHighSinceTrendStart, " New=", currentCandleHigh, 
               " Time=", TimeToString(iTime(_Symbol, PERIOD_CURRENT, 1)));
         highestHighSinceTrendStart = currentCandleHigh;
         highestHighSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, 1);
      }
   }
   else
   {
      double currentCandleLow = iLow(_Symbol, PERIOD_CURRENT, 1);
      if(currentCandleLow < lowestLowSinceTrendStart)
      {
         Print("🔽 LL Updated: Old=", lowestLowSinceTrendStart, " New=", currentCandleLow, 
               " Time=", TimeToString(iTime(_Symbol, PERIOD_CURRENT, 1)));
         lowestLowSinceTrendStart = currentCandleLow;
         lowestLowSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, 1);
      }
   }

   // ============ CHECK FOR BREAK - NEW BoS ============
   if(retracementStarted)
   {
      double currentClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      datetime currentBarTimeForLabel = iTime(_Symbol, PERIOD_CURRENT, 1);

      bool invalidated = false;
      if(trendDirection == 1)
         invalidated = (currentClose > referenceHighForInvalidation);
      else
         invalidated = (currentClose < referenceLowForInvalidation);

      if(invalidated)
      {
      
      
         // DEBUG LOG
         Print("========================================");
         Print("⚠️ RETRACEMENT INVALIDATED");
         Print("   Close Price: ", currentClose);
         Print("   Locked Ref Price: ", referenceHighForInvalidation);
         Print("   Time: ", TimeToString(currentBarTimeForLabel));
         Print("========================================");
         
          // ADD THESE TWO LINES
         ObjectDelete(0, "MotherCandle_Box");
         ObjectDelete(0, "MotherCandle_Label");
         
         ObjectDelete(0, "BBB_Rectangle");
         ObjectDelete(0, "BBB_Label");
         ObjectDelete(0, "QML_Rectangle");
         ObjectDelete(0, "QML_Label");
         ObjectDelete(0, "DB_Rectangle");
         ObjectDelete(0, "DB_Label");
         ObjectDelete(0, "SBB_Rectangle");
         ObjectDelete(0, "SBB_Label");
         ObjectDelete(0, "DT_Rectangle");
         ObjectDelete(0, "DT_Label");

         bbbConfirmed = false;
         bbbMitigated = false;
         bbbTopPrice = 0;
         bbbBottomPrice = 0;
         bbbDrawTime = 0;

         qmlConfirmed = false;
         qmlMitigated = false;
         qmlTopPrice = 0;
         qmlBottomPrice = 0;
         qmlDrawTime = 0;

         dbConfirmed = false;
         dbMitigated = false;
         dbTopPrice = 0;
         dbBottomPrice = 0;
         dbDrawTime = 0;

         sbbConfirmed = false;
         sbbMitigated = false;
         sbbTopPrice = 0;
         sbbBottomPrice = 0;
         sbbDrawTime = 0;

         dtConfirmed = false;
         dtMitigated = false;
         dtTopPrice = 0;
         dtBottomPrice = 0;
         dtDrawTime = 0;

         int totalObjects = ObjectsTotal(0, -1, OBJ_TEXT);
         for(int i = totalObjects - 1; i >= 0; i--)
         {
            string objName = ObjectName(0, i);
            if(StringFind(objName, "ChoCh_Confirm_Label") >= 0)
               ObjectDelete(0, objName);
         }

         chochConfirmed = false;
         currentChoChLevel = 0;

         level1BreakTime = currentBarTimeForLabel;
         level1BreakPrice = currentClose;

         double refPrice = (trendDirection == 1) ? referenceHighForInvalidation : referenceLowForInvalidation;
         DrawLevel1Line(refPrice, retracementStartTime);

         int highestHighBar = iBarShift(_Symbol, PERIOD_CURRENT, retracementStartTime);
         int bosBreakBar = iBarShift(_Symbol, PERIOD_CURRENT, currentBarTimeForLabel);
         int level2BarNumber = 0;

         if(highestHighBar >= 0 && bosBreakBar >= 0)
         {
            int startBar = MathMin(highestHighBar, bosBreakBar);
            int endBar = MathMax(highestHighBar, bosBreakBar);

            double level2PriceLocal = 0;
            int level2Bar = -1;

            if(trendDirection == 1)
            {
               double lowestLow = DBL_MAX;
               for(int i = startBar; i <= endBar; i++)
               {
                  double low = iLow(_Symbol, PERIOD_CURRENT, i);
                  if(low < lowestLow) { lowestLow = low; level2Bar = i; }
               }
               if(level2Bar >= 0)
               {
                  level2PriceLocal = lowestLow;
                  datetime level2Time = iTime(_Symbol, PERIOD_CURRENT, level2Bar);
                  DrawLevel2Line(level2PriceLocal, level2Time, currentBarTimeForLabel, level2BarNumber);

                  double lowestBearishClose = DBL_MAX;
                  int lowestBearishCloseBar = -1;
                  for(int i = startBar; i <= endBar; i++)
                  {
                     if(IsBearish(i))
                     {
                        double close = iClose(_Symbol, PERIOD_CURRENT, i);
                        if(close < lowestBearishClose) { lowestBearishClose = close; lowestBearishCloseBar = i; }
                     }
                  }
                  if(lowestBearishCloseBar >= 0)
                  {
                     datetime lowestBearishCloseTime = iTime(_Symbol, PERIOD_CURRENT, lowestBearishCloseBar);
                     double bearishCandleOpen = iOpen(_Symbol, PERIOD_CURRENT, lowestBearishCloseBar);
                     double bearishCandleHigh = iHigh(_Symbol, PERIOD_CURRENT, lowestBearishCloseBar);
                     double bearishCandleLow = iLow(_Symbol, PERIOD_CURRENT, lowestBearishCloseBar);
                     DrawDemandZone(lowestBearishCloseTime, bearishCandleOpen, bearishCandleHigh, bearishCandleLow,
                                    level2PriceLocal, retracementStartTime, currentBarTimeForLabel);
                  }
               }
            }
            else
            {
               double highestHigh = -DBL_MAX;
               for(int i = startBar; i <= endBar; i++)
               {
                  double high = iHigh(_Symbol, PERIOD_CURRENT, i);
                  if(high > highestHigh) { highestHigh = high; level2Bar = i; }
               }
               if(level2Bar >= 0)
               {
                  level2PriceLocal = highestHigh;
                  datetime level2Time = iTime(_Symbol, PERIOD_CURRENT, level2Bar);
                  DrawLevel2Line(level2PriceLocal, level2Time, currentBarTimeForLabel, level2BarNumber);

                  double highestBullishClose = -DBL_MAX;
                  int highestBullishCloseBar = -1;
                  for(int i = startBar; i <= endBar; i++)
                  {
                     if(IsBullish(i))
                     {
                        double close = iClose(_Symbol, PERIOD_CURRENT, i);
                        if(close > highestBullishClose) { highestBullishClose = close; highestBullishCloseBar = i; }
                     }
                  }
                  if(highestBullishCloseBar >= 0)
                  {
                     datetime highestBullishCloseTime = iTime(_Symbol, PERIOD_CURRENT, highestBullishCloseBar);
                     double bullishCandleOpen = iOpen(_Symbol, PERIOD_CURRENT, highestBullishCloseBar);
                     double bullishCandleHigh = iHigh(_Symbol, PERIOD_CURRENT, highestBullishCloseBar);
                     double bullishCandleLow = iLow(_Symbol, PERIOD_CURRENT, highestBullishCloseBar);
                     DrawSupplyZone(highestBullishCloseTime, bullishCandleOpen, bullishCandleHigh, bullishCandleLow,
                                    level2PriceLocal, retracementStartTime, currentBarTimeForLabel);
                  }
               }
            }
         }

         int retracementTriggerBar = iBarShift(_Symbol, PERIOD_CURRENT, retracementStartTime);
         int preRetracementBar = retracementTriggerBar + 1;

         if(preRetracementBar > 0 && level2BarNumber > 0)
         {
            datetime mbStartTime = 0, mbEndTime = 0;
            double mbBottom = 0, mbTop = 0;
            double level1Price = (trendDirection == 1) ? referenceHighForInvalidation : referenceLowForInvalidation;
            FindMitigationBlock(preRetracementBar, level2BarNumber, mbStartTime, mbEndTime, mbBottom, mbTop, level1Price);
            if(mbStartTime > 0 && mbTop > mbBottom)
            {
               datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 1);
               DrawMitigationBlock(mbStartTime, mbBottom, mbTop, currentTime, level1BreakTime);
            }
         }

         retracementStarted = false;
         motherCandleActive = false;
      }
   }

   // ============ LOOK FOR NEW RETRACEMENT ============
   // Only look for a new retracement if one hasn't started AND no Mother Candle is currently being tracked.
   if(!retracementStarted)
   {
      int ruleUsed = 0;
      double triggerCandlePrice = 0;

      if(CheckRetracementRules(ruleUsed, triggerCandlePrice))
      {
         double refPrice = 0;
         datetime trendStartTime = (trendDirection == 1) ? highestHighSinceTrendStart_Time : lowestLowSinceTrendStart_Time;
         datetime retracementTime = iTime(_Symbol, PERIOD_CURRENT, 1);
         
         if(trendDirection == 1)
         {
            refPrice = FindHighestHighBetween(trendStartTime, retracementTime);
            if(refPrice <= 0) refPrice = MathMax(triggerCandlePrice, highestHighSinceTrendStart);
            referenceHighForInvalidation = refPrice;
         }
         else
         {
            refPrice = FindLowestLowBetween(trendStartTime, retracementTime);
            if(refPrice <= 0) refPrice = MathMin(triggerCandlePrice, lowestLowSinceTrendStart);
            referenceLowForInvalidation = refPrice;
         }

         retracementStarted = true;
         retracementStartTime = retracementTime;
         retracementRuleUsed = ruleUsed;

         DrawLevel3Line(refPrice, retracementStartTime, currentBarTime);
         
         Print("========================================");
         Print("📊 RETRACEMENT CONFIRMED (Level 3 Locked)");
         Print("   Rule Used: ", ruleUsed);
         Print("   Level 3 Price: ", refPrice);
         Print("   Tracking suspended until next BoS");
         Print("========================================");
      }
   }
}
//+------------------------------------------------------------------+