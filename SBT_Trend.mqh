//+------------------------------------------------------------------+
//|                                                  SBT_Trend.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Trend detection, trend switches (bull/bear), MSS continuation,  |
//|  zone cleanup helpers.                                           |
//+------------------------------------------------------------------+
#ifndef SBT_TREND_MQH
#define SBT_TREND_MQH

#include "SBT_Drawing.mqh"

//+------------------------------------------------------------------+
//| Forward declarations (defined in SBT_ABCDE.mqh)                  |
//+------------------------------------------------------------------+
void ResetABCDE();

//+------------------------------------------------------------------+
//| Detect Trend                                                     |
//+------------------------------------------------------------------+
void DetectTrend()
{
   if(trendDirection == 1)
   {
      if(!bullishTrendEstablished)
      {
         for(int i = totalBars - 1; i >= 0; i--)
         {
            double candleHigh = iHigh(_Symbol, PERIOD_CURRENT, i);
            if(i == totalBars - 1)
            {
               highestHighSinceTrendStart = candleHigh;
               highestHighSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, i);
               continue;
            }
            if(candleHigh > highestHighSinceTrendStart)
            {
               bullishTrendEstablished = true;
               highestHighSinceTrendStart = candleHigh;
               highestHighSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, i);
               trendStartTimeGlobal = highestHighSinceTrendStart_Time;
               Print("✅ BULLISH TREND ESTABLISHED at ", highestHighSinceTrendStart);
               break;
            }
         }
      }
   }
   else
   {
      if(!bearishTrendEstablished)
      {
         for(int i = totalBars - 1; i >= 0; i--)
         {
            double candleLow = iLow(_Symbol, PERIOD_CURRENT, i);
            if(i == totalBars - 1)
            {
               lowestLowSinceTrendStart = candleLow;
               lowestLowSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, i);
               continue;
            }
            if(candleLow < lowestLowSinceTrendStart)
            {
               bearishTrendEstablished = true;
               lowestLowSinceTrendStart = candleLow;
               lowestLowSinceTrendStart_Time = iTime(_Symbol, PERIOD_CURRENT, i);
               bearishTrendStartTime = lowestLowSinceTrendStart_Time;
               Print("✅ BEARISH TREND ESTABLISHED at ", lowestLowSinceTrendStart);
               break;
            }
         }
      }
   }
}

bool IsTrendEstablished()
{
   if(trendDirection == 1)
      return bullishTrendEstablished;
   else
      return bearishTrendEstablished;
}

//+------------------------------------------------------------------+
//| Switch to Bullish Trend (Bearish → Bullish) — full host path     |
//+------------------------------------------------------------------+
void SwitchToBullish(double closePrice, datetime currentBarTime)
{
   Print("🔄 SWITCHING TO BULLISH TREND (Bearish → Bullish)");

   if(szTopPrice > 0 && szBottomPrice > 0 && szDrawTime > 0)
      DrawBBB(szTopPrice, szBottomPrice, szDrawTime, currentBarTime);

   if(mbTopPrice > 0 && mbBottomPrice > 0 && mbDrawTime > 0)
      DrawQML(mbTopPrice, mbBottomPrice, mbDrawTime, currentBarTime);

   if(currentLevel3Price > 0 && level1BreakTime > 0)
   {
      int level1Bar = iBarShift(_Symbol, PERIOD_CURRENT, level1BreakTime);
      int currentBar = iBarShift(_Symbol, PERIOD_CURRENT, currentBarTime);

      if(level1Bar >= 0 && currentBar >= 0)
      {
         int fromBar = MathMin(level1Bar, currentBar);
         int toBar = MathMax(level1Bar, currentBar);

         datetime dbCandleTime = 0;
         double dbOpen = 0, dbClose = 0;
         double lowestClose = DBL_MAX;
         int lowestBar = -1;

         for(int i = fromBar; i <= toBar; i++)
         {
            if(IsBearish(i))
            {
               double close = iClose(_Symbol, PERIOD_CURRENT, i);
               double low = iLow(_Symbol, PERIOD_CURRENT, i);

               if(low > currentLevel3Price && close < lowestClose)
               {
                  lowestClose = close;
                  lowestBar = i;
               }
            }
         }

         if(lowestBar >= 0)
         {
            dbCandleTime = iTime(_Symbol, PERIOD_CURRENT, lowestBar);
            dbOpen = iOpen(_Symbol, PERIOD_CURRENT, lowestBar);
            dbClose = iClose(_Symbol, PERIOD_CURRENT, lowestBar);

            if(dbCandleTime > 0 && dbOpen > 0 && dbClose > 0)
               DrawDB(dbCandleTime, dbOpen, dbClose, currentLevel3Price, currentBarTime);
         }
      }
   }

   trendDirection = 1;
   bearishTrendEstablished = false;
   lowestLowSinceTrendStart = 0;
   lowestLowSinceTrendStart_Time = 0;
   bullishTrendEstablished = true;
   highestHighSinceTrendStart = closePrice;
   highestHighSinceTrendStart_Time = currentBarTime;
   bullishTrendStartTime = currentBarTime;

   retracementStarted = false;
   retracementStartTime = 0;
   retracementRuleUsed = 0;
   referenceHighForInvalidation = 0;
   referenceLowForInvalidation = 0;
   motherCandleActive = false;

   dzConfirmed = false;
   dzMitigated = false;
   dzTopPrice = 0;
   dzBottomPrice = 0;
   dzDrawTime = 0;
   dzCandleHigh = 0;
   dzCandleLow = 0;
   dzConfirmationBar = 0;

   szConfirmed = false;
   szMitigated = false;
   szTopPrice = 0;
   szBottomPrice = 0;
   szDrawTime = 0;
   szCandleLow = 0;
   szCandleHigh = 0;
   szConfirmationBar = 0;

   mbMitigated = false;
   mbTopPrice = 0;
   mbBottomPrice = 0;
   mbDrawTime = 0;
   mbConfirmationTime = 0;
   mbEntryCount = 0;
   mbPositionTicket = 0;
   
   dzRightEdgeTime = 0;
   szRightEdgeTime = 0;
   mbRightEdgeTime = 0;

   currentLevel3Price = 0;
   level3DrawTime = 0;
   level1BreakTime = 0;
   level1BreakPrice = 0;
   level1DrawTime = 0;

   consecutiveBearishBelowChoCh = 0;
   consecutiveBullishAboveChoCh = 0;
   chochConfirmed = false;
   currentChoChLevel = 0;

   ObjectDelete(0, "Level1_Line");
   ObjectDelete(0, "Level1_Label");
   ObjectDelete(0, "Level3_Line");
   ObjectDelete(0, "Level3_Label");
   ObjectDelete(0, "DemandZone_Rectangle");
   ObjectDelete(0, "DemandZone_Label");
   ObjectDelete(0, "SupplyZone_Rectangle");
   ObjectDelete(0, "SupplyZone_Label");
   ObjectDelete(0, "MB_Rectangle");
   ObjectDelete(0, "MB_Label");
   ObjectDelete(0, "ChoCh_Line");
   ObjectDelete(0, "ChoCh_Label");
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "SL_Label");
   ObjectDelete(0, "SBT3_FVG_Rectangle");
   ObjectDelete(0, "SBT3_FVG_Label");

   Print("✅ BULLISH TREND ACTIVATED");
}

//+------------------------------------------------------------------+
//| Switch to Bearish Trend (Bullish → Bearish) — full host path     |
//+------------------------------------------------------------------+
void SwitchToBearish(double closePrice, datetime currentBarTime)
{
   Print("🔄 SWITCHING TO BEARISH TREND (Bullish → Bearish)");

   if(dzTopPrice > 0 && dzBottomPrice > 0 && dzDrawTime > 0)
      DrawSBB(dzTopPrice, dzBottomPrice, dzDrawTime, currentBarTime);

   if(mbTopPrice > 0 && mbBottomPrice > 0 && mbDrawTime > 0)
      DrawQML(mbTopPrice, mbBottomPrice, mbDrawTime, currentBarTime);

   if(currentLevel3Price > 0 && level1BreakTime > 0)
   {
      int level1Bar = iBarShift(_Symbol, PERIOD_CURRENT, level1BreakTime);
      int currentBar = iBarShift(_Symbol, PERIOD_CURRENT, currentBarTime);

      if(level1Bar >= 0 && currentBar >= 0)
      {
         int fromBar = MathMin(level1Bar, currentBar);
         int toBar = MathMax(level1Bar, currentBar);

         datetime dtCandleTime = 0;
         double dtOpen = 0, dtClose = 0;
         double highestClose = -DBL_MAX;
         int highestBar = -1;

         for(int i = fromBar; i <= toBar; i++)
         {
            if(IsBullish(i))
            {
               double close = iClose(_Symbol, PERIOD_CURRENT, i);
               double high = iHigh(_Symbol, PERIOD_CURRENT, i);

               if(high < currentLevel3Price && close > highestClose)
               {
                  highestClose = close;
                  highestBar = i;
               }
            }
         }

         if(highestBar >= 0)
         {
            dtCandleTime = iTime(_Symbol, PERIOD_CURRENT, highestBar);
            dtOpen = iOpen(_Symbol, PERIOD_CURRENT, highestBar);
            dtClose = iClose(_Symbol, PERIOD_CURRENT, highestBar);

            if(dtCandleTime > 0 && dtOpen > 0 && dtClose > 0)
               DrawDT(dtCandleTime, dtOpen, dtClose, currentLevel3Price, currentBarTime);
         }
      }
   }

   trendDirection = -1;
   bullishTrendEstablished = false;
   highestHighSinceTrendStart = 0;
   highestHighSinceTrendStart_Time = 0;
   bearishTrendEstablished = true;
   lowestLowSinceTrendStart = closePrice;
   lowestLowSinceTrendStart_Time = currentBarTime;
   bearishTrendStartTime = currentBarTime;

   retracementStarted = false;
   retracementStartTime = 0;
   retracementRuleUsed = 0;
   referenceHighForInvalidation = 0;
   referenceLowForInvalidation = 0;
   motherCandleActive = false;

   dzConfirmed = false;
   dzMitigated = false;
   dzTopPrice = 0;
   dzBottomPrice = 0;
   dzDrawTime = 0;

   szConfirmed = false;
   szMitigated = false;
   szTopPrice = 0;
   szBottomPrice = 0;
   szDrawTime = 0;

   mbMitigated = false;
   mbTopPrice = 0;
   mbBottomPrice = 0;
   mbDrawTime = 0;
   
   dzRightEdgeTime = 0;
   szRightEdgeTime = 0;
   mbRightEdgeTime = 0;

   currentLevel3Price = 0;
   level3DrawTime = 0;
   level1BreakTime = 0;
   level1BreakPrice = 0;
   level1DrawTime = 0;

   consecutiveBearishBelowChoCh = 0;
   consecutiveBullishAboveChoCh = 0;
   chochConfirmed = false;
   currentChoChLevel = 0;

   ObjectDelete(0, "Level1_Line");
   ObjectDelete(0, "Level1_Label");
   ObjectDelete(0, "Level3_Line");
   ObjectDelete(0, "Level3_Label");
   ObjectDelete(0, "DemandZone_Rectangle");
   ObjectDelete(0, "DemandZone_Label");
   ObjectDelete(0, "SupplyZone_Rectangle");
   ObjectDelete(0, "SupplyZone_Label");
   ObjectDelete(0, "MB_Rectangle");
   ObjectDelete(0, "MB_Label");
   ObjectDelete(0, "ChoCh_Line");
   ObjectDelete(0, "ChoCh_Label");
   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "SL_Label");
   ObjectDelete(0, "SBT3_FVG_Rectangle");
   ObjectDelete(0, "SBT3_FVG_Label");
   
   ObjectDelete(0, "MotherCandle_Box");
   ObjectDelete(0, "MotherCandle_Label");

   Print("✅ BEARISH TREND ACTIVATED with SBB, QML, DT");
}

//+------------------------------------------------------------------+
//| Cleanup MSS Zones Only (Keep normal DZ/SZ and MB)                |
//+------------------------------------------------------------------+
void CleanupMSSZonesKeepNormal()
{
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
   ObjectDelete(0, "SBT3_FVG_Rectangle");
   ObjectDelete(0, "SBT3_FVG_Label");
   
   // Cleanup SBT-2 Overlap marker
   ObjectDelete(0, "SBT2_Overlap_Box");
   ObjectDelete(0, "SBT2_Overlap_Label");
   
   
   sbt2_saved_extreme = 0;
   mbFvgFound = false;
   mbFvgSlLevel = 0;
   mbActiveEntryModel = 0;
   mbActiveFvgExtreme = 0;

   bbbConfirmed = false;
   bbbMitigated = false;
   bbbTopPrice = 0;
   bbbBottomPrice = 0;
   bbbDrawTime = 0;
   bbbConfirmationTime = 0;

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
   sbbConfirmationTime = 0;

   dtConfirmed = false;
   dtMitigated = false;
   dtTopPrice = 0;
   dtBottomPrice = 0;
   dtDrawTime = 0;
   
   bbbRightEdgeTime = 0;
   qmlRightEdgeTime = 0;
   dbRightEdgeTime  = 0;
   sbbRightEdgeTime = 0;
   dtRightEdgeTime  = 0;

   trendContinuation = false;
   trendContinuationConfirmed = false;
   trendContinuationTime = 0;
   trendContinuationPrice = 0;
}

//+------------------------------------------------------------------+
//| Check Trend Continuation - Treat as BoS                          |
//+------------------------------------------------------------------+
void CheckTrendContinuation()
{
   // ========== BULLISH MSS (Bearish → Bullish) ==========
   if(bbbConfirmed && !trendContinuationConfirmed && trendDirection == 1 && dbConfirmed && dbBottomPrice > 0)
   {
      double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
      double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);

      if(close1 < dbBottomPrice && close2 < dbBottomPrice)
      {
         trendContinuationConfirmed = true;
         trendContinuationTime = iTime(_Symbol, PERIOD_CURRENT, 1);
         trendContinuationPrice = close1;

         double level1Price = dbBottomPrice;
         datetime level1Time = trendContinuationTime;

         double level2Price = currentLevel3Price;
         if(level2Price <= 0) level2Price = dbTopPrice;
         datetime level2Time = level3DrawTime;
         if(level2Time <= 0) level2Time = level1Time;

         int dbBar = iBarShift(_Symbol, PERIOD_CURRENT, dbDrawTime);
         if(dbBar < 0) dbBar = 20;

         CleanupMSSZonesKeepNormal();

         trendDirection = -1;
         bearishTrendEstablished = true;
         bearishTrendStartTime = level1Time;
         bullishTrendEstablished = false;
         lowestLowSinceTrendStart = level1Price;
         lowestLowSinceTrendStart_Time = level1Time;

         DrawLevel1Line(level1Price, level1Time);

         int level2BarNumber = 0;
         DrawLevel2Line(level2Price, level2Time, level1Time, level2BarNumber);

         currentLevel3Price = 0;
         level3DrawTime = 0;
         level1BreakTime = level1Time;
         level1BreakPrice = level1Price;
         level1DrawTime = level1Time;

         retracementStarted = false;
         ResetABCDE();
      }
   }

   // ========== BEARISH MSS (Bullish → Bearish) ==========
   if(sbbConfirmed && !trendContinuationConfirmed && trendDirection == -1 && dtConfirmed && dtTopPrice > 0)
   {
      double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
      double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);

      if(close1 > dtTopPrice && close2 > dtTopPrice)
      {
         trendContinuationConfirmed = true;
         trendContinuationTime = iTime(_Symbol, PERIOD_CURRENT, 1);
         trendContinuationPrice = close1;

         double level1Price = dtTopPrice;
         datetime level1Time = trendContinuationTime;

         double level2Price = currentLevel3Price;
         if(level2Price <= 0) level2Price = dtBottomPrice;
         datetime level2Time = level3DrawTime;
         if(level2Time <= 0) level2Time = level1Time;

         int dtBar = iBarShift(_Symbol, PERIOD_CURRENT, dtDrawTime);
         if(dtBar < 0) dtBar = 20;

         CleanupMSSZonesKeepNormal();

         trendDirection = 1;
         bullishTrendEstablished = true;
         bullishTrendStartTime = level1Time;
         bearishTrendEstablished = false;
         highestHighSinceTrendStart = level1Price;
         highestHighSinceTrendStart_Time = level1Time;

         DrawLevel1Line(level1Price, level1Time);

         int level2BarNumber = 0;
         DrawLevel2Line(level2Price, level2Time, level1Time, level2BarNumber);

         currentLevel3Price = 0;
         level3DrawTime = 0;
         level1BreakTime = level1Time;
         level1BreakPrice = level1Price;
         level1DrawTime = level1Time;

         retracementStarted = false;
         ResetABCDE();
      }
   }
}

//+------------------------------------------------------------------+
//| Cleanup host zones before ABCDE re-draw (Conf 2b)                |
//+------------------------------------------------------------------+
void CleanupZonesForABCDE()
{
   // 1. Delete Level, ChoCh, DZ, SZ, MB objects
   ObjectDelete(0, "Level1_Line");
   ObjectDelete(0, "Level1_Label");
   ObjectDelete(0, "Level3_Line");
   ObjectDelete(0, "Level3_Label");
   ObjectDelete(0, "ChoCh_Line");
   ObjectDelete(0, "ChoCh_Label");

   ObjectDelete(0, "DemandZone_Rectangle");
   ObjectDelete(0, "DemandZone_Label");
   ObjectDelete(0, "SupplyZone_Rectangle");
   ObjectDelete(0, "SupplyZone_Label");

   ObjectDelete(0, "MB_Rectangle");
   ObjectDelete(0, "MB_Label");
   
   ObjectDelete(0, "SBT3_FVG_Rectangle");
   ObjectDelete(0, "SBT3_FVG_Label");

   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "SL_Label");

   // 2. Cleanup any ChoCh confirmation text
   int totalObjects = ObjectsTotal(0, -1, OBJ_TEXT);
   for(int i = totalObjects - 1; i >= 0; i--)
   {
      string objName = ObjectName(0, i);
      if(StringFind(objName, "ChoCh_Confirm_Label") >= 0)
         ObjectDelete(0, objName);
   }
   
   // 4. Cleanup the SBT-2 Overlap marker
   ObjectDelete(0, "SBT2_Overlap_Box");
   ObjectDelete(0, "SBT2_Overlap_Label");
   
   
   // 5. Cleanup MSS Zones (BBB, SBB, QML, DB, DT)
   // This deletes the objects and resets the global state flags
   CleanupMSSZonesKeepNormal();
}

#endif // SBT_TREND_MQH
//+------------------------------------------------------------------+