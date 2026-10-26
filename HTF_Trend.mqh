//+------------------------------------------------------------------+
//|                                                 HTF_Trend.mqh    |
//|                                    Copyright 2026, sbt_trading   |
//|  Full HTF engine mirroring LTF logic on HTF_Period.              |
//+------------------------------------------------------------------+
#ifndef HTF_TREND_MQH
#define HTF_TREND_MQH

#include "SBT_State.mqh"
#include "HTF_Drawing.mqh"

//+------------------------------------------------------------------+
//| HTF Candle Helpers                                               |
//+------------------------------------------------------------------+
bool HTF_IsBearish(int shift) { return (iClose(_Symbol, HTF_Period, shift) < iOpen(_Symbol, HTF_Period, shift)); }
bool HTF_IsBullish(int shift) { return (iClose(_Symbol, HTF_Period, shift) > iOpen(_Symbol, HTF_Period, shift)); }

//+------------------------------------------------------------------+
//| HTF Range Helpers                                                |
//+------------------------------------------------------------------+
double HTF_FindLowestLowBetween(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double lowestLow = DBL_MAX;
   for(int i = from; i >= to; i--)
   {
      double l = iLow(_Symbol, HTF_Period, i);
      if(l < lowestLow) lowestLow = l;
   }
   return (lowestLow == DBL_MAX) ? 0 : lowestLow;
}

double HTF_FindHighestHighBetween(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double highestHigh = -DBL_MAX;
   for(int i = from; i >= to; i--)
   {
      double h = iHigh(_Symbol, HTF_Period, i);
      if(h > highestHigh) highestHigh = h;
   }
   return (highestHigh == -DBL_MAX) ? 0 : highestHigh;
}

datetime HTF_FindTimeOfLowestLow(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double lowestLow = DBL_MAX;
   int lowestBar = -1;
   for(int i = from; i >= to; i--)
   {
      double l = iLow(_Symbol, HTF_Period, i);
      if(l < lowestLow) { lowestLow = l; lowestBar = i; }
   }
   if(lowestBar < 0) return 0;
   return iTime(_Symbol, HTF_Period, lowestBar);
}

datetime HTF_FindTimeOfHighestHigh(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, HTF_Period, startTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double highestHigh = -DBL_MAX;
   int highestBar = -1;
   for(int i = from; i >= to; i--)
   {
      double h = iHigh(_Symbol, HTF_Period, i);
      if(h > highestHigh) { highestHigh = h; highestBar = i; }
   }
   if(highestBar < 0) return 0;
   return iTime(_Symbol, HTF_Period, highestBar);
}

//+------------------------------------------------------------------+
//| HTF Trend Detection                                              |
//+------------------------------------------------------------------+
void HTF_DetectTrend()
{
   htfTotalBars = Bars(_Symbol, HTF_Period);
   if(htfTotalBars < 30) return;
   int maxScan = MathMin(htfTotalBars, HTF_MaxScanBars);

   if(htfTrendDirection == 1)
   {
      if(!htfBullishEstablished)
      {
         for(int i = maxScan - 1; i >= 0; i--)
         {
            double candleHigh = iHigh(_Symbol, HTF_Period, i);
            if(i == maxScan - 1)
            {
               htfHighestHighSinceTrendStart = candleHigh;
               htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, i);
               continue;
            }
            if(candleHigh > htfHighestHighSinceTrendStart)
            {
               htfBullishEstablished = true;
               htfHighestHighSinceTrendStart = candleHigh;
               htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, i);
               break;
            }
         }
      }
   }
   else if(htfTrendDirection == -1)
   {
      if(!htfBearishEstablished)
      {
         for(int i = maxScan - 1; i >= 0; i--)
         {
            double candleLow = iLow(_Symbol, HTF_Period, i);
            if(i == maxScan - 1)
            {
               htfLowestLowSinceTrendStart = candleLow;
               htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, i);
               continue;
            }
            if(candleLow < htfLowestLowSinceTrendStart)
            {
               htfBearishEstablished = true;
               htfLowestLowSinceTrendStart = candleLow;
               htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, i);
               break;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| HTF Retracement Rules                                            |
//+------------------------------------------------------------------+
bool HTF_CheckRetracementRules(int &ruleUsed, double &triggerPrice)
{
   double currOpen1  = iOpen(_Symbol, HTF_Period, 1);
   double currClose1 = iClose(_Symbol, HTF_Period, 1);
   double currHigh1  = iHigh(_Symbol, HTF_Period, 1);
   double currLow1   = iLow(_Symbol, HTF_Period, 1);
   double prevOpen   = iOpen(_Symbol, HTF_Period, 2);
   double prevClose  = iClose(_Symbol, HTF_Period, 2);
   double prevHigh   = iHigh(_Symbol, HTF_Period, 2);
   double prevLow    = iLow(_Symbol, HTF_Period, 2);
   
   bool currBearish = HTF_IsBearish(1);
   bool currBullish = HTF_IsBullish(1);
   bool prevBullish = HTF_IsBullish(2);
   bool prevBearish = HTF_IsBearish(2);

   if(htfMotherCandleActive)
   {
      int motherBar = iBarShift(_Symbol, HTF_Period, htfMotherCandleTime, false);
      if(motherBar < 1) motherBar = 1;

      if(htfTrendDirection == 1)  // BULLISH
      {
         bool invalidated = false;
         bool triggered = false;
         
         for(int i = 1; i <= motherBar; i++)
         {
            double cOpen = iOpen(_Symbol, HTF_Period, i);
            double cClose = iClose(_Symbol, HTF_Period, i);
            
            if(cClose > cOpen && cClose > htfMotherCandleOpen)
            {
               invalidated = true;
               Print("   ❌ HTF Mother Candle CANCELLED - Bullish closed above Open");
               break;
            }
            
            if(cClose < cOpen && cClose < htfMotherCandleLow)
            {
               triggered = true;
            }
         }
         
         if(invalidated)
         {
            htfMotherCandleActive = false;
            if(PERIOD_CURRENT == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            return false;
         }
         
         if(triggered)
         {
            ruleUsed = 3;
            triggerPrice = currHigh1;
            htfMotherCandleActive = false;
            if(PERIOD_CURRENT == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            Print("   ✅ HTF RULE 3 TRIGGERED! (Mother Candle)");
            return true;
         }
         
         return false;
      }
      else  // BEARISH
      {
         bool invalidated = false;
         bool triggered = false;
         
         for(int i = 1; i <= motherBar; i++)
         {
            double cOpen = iOpen(_Symbol, HTF_Period, i);
            double cClose = iClose(_Symbol, HTF_Period, i);
            
            if(cClose < cOpen && cClose < htfMotherCandleOpen)
            {
               invalidated = true;
               Print("   ❌ HTF Mother Candle CANCELLED - Bearish closed below Open");
               break;
            }
            
            if(cClose > cOpen && cClose > htfMotherCandleHigh)
            {
               triggered = true;
            }
         }
         
         if(invalidated)
         {
            htfMotherCandleActive = false;
            if(PERIOD_CURRENT == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            return false;
         }
         
         if(triggered)
         {
            ruleUsed = 3;
            triggerPrice = currLow1;
            htfMotherCandleActive = false;
            if(PERIOD_CURRENT == HTF_Period) 
            {
               ObjectDelete(0, "HTF_MotherCandle_Box");
               ObjectDelete(0, "HTF_MotherCandle_Label");
            }
            Print("   ✅ HTF RULE 3 TRIGGERED! (Mother Candle)");
            return true;
         }
         
         return false;
      }
   }

   if(htfTrendDirection == 1)
   {
      if(currBearish && prevBullish && currLow1 <= prevLow && currClose1 <= prevLow)
      {
         ruleUsed = 1; triggerPrice = currHigh1; return true;
      }
      if(currBearish && HTF_IsBearish(2) && currClose1 < iLow(_Symbol, HTF_Period, 2))
      {
         ruleUsed = 2; triggerPrice = currHigh1; return true;
      }
      if(!htfRetracementStarted && !htfMotherCandleActive)
      {
         double highestOpen = -DBL_MAX;
         int bestMotherBar = -1;
         
         for(int i = 1; i <= 10; i++)
         {
            if(HTF_IsBearish(i))
            {
               double open = iOpen(_Symbol, HTF_Period, i);
               if(open > highestOpen)
               {
                  highestOpen = open;
                  bestMotherBar = i;
               }
            }
         }
         
         if(bestMotherBar > 0)
         {
            htfMotherCandleActive = true;
            htfMotherCandleOpen = iOpen(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleLow = iLow(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleTime = iTime(_Symbol, HTF_Period, bestMotherBar);
            
            if(PERIOD_CURRENT == HTF_Period)
               HTF_DrawMotherCandleBox(htfMotherCandleTime, htfMotherCandleOpen, htfMotherCandleLow, "Bearish Mother");
               
            Print("   ✅ HTF Mother Candle SET (Bearish) at Bar ", bestMotherBar);
            return false;
         }
      }
   }
   else
   {
      if(currBullish && prevBearish && currHigh1 >= prevHigh && currClose1 >= prevHigh)
      {
         ruleUsed = 1; triggerPrice = currLow1; return true;
      }
      if(currBullish && HTF_IsBullish(2) && currClose1 > iHigh(_Symbol, HTF_Period, 2))
      {
         ruleUsed = 2; triggerPrice = currLow1; return true;
      }
      if(!htfRetracementStarted && !htfMotherCandleActive)
      {
         double lowestOpen = DBL_MAX;
         int bestMotherBar = -1;
         
         for(int i = 1; i <= 10; i++)
         {
            if(HTF_IsBullish(i))
            {
               double open = iOpen(_Symbol, HTF_Period, i);
               if(open < lowestOpen)
               {
                  lowestOpen = open;
                  bestMotherBar = i;
               }
            }
         }
         
         if(bestMotherBar > 0)
         {
            htfMotherCandleActive = true;
            htfMotherCandleOpen = iOpen(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleHigh = iHigh(_Symbol, HTF_Period, bestMotherBar);
            htfMotherCandleTime = iTime(_Symbol, HTF_Period, bestMotherBar);
            
            if(PERIOD_CURRENT == HTF_Period)
               HTF_DrawMotherCandleBox(htfMotherCandleTime, htfMotherCandleOpen, htfMotherCandleHigh, "Bullish Mother");
               
            Print("   ✅ HTF Mother Candle SET (Bullish) at Bar ", bestMotherBar);
            return false;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| HTF ABCDE Update                                                 |
//+------------------------------------------------------------------+
void HTF_UpdateABCDE(bool ruleFired, int ruleUsed, double triggerPrice)
{
   double bodyClose1 = iClose(_Symbol, HTF_Period, 1);
   datetime barTime1 = iTime(_Symbol, HTF_Period, 1);
   
   if(htfAbcdeActive)
   {
      if(htfAbcdeWave >= 3 && htfAbcdeB > 0)
      {
         if(htfTrendDirection == 1 && bodyClose1 > htfAbcdeB) { htfAbcdeActive = false; return; }
         if(htfTrendDirection == -1 && bodyClose1 < htfAbcdeB) { htfAbcdeActive = false; return; }
      }
      if(htfAbcdeWave == 1 && htfAbcde0 > 0)
      {
         if(htfTrendDirection == 1 && bodyClose1 > htfAbcde0) { htfAbcdeActive = false; return; }
         if(htfTrendDirection == -1 && bodyClose1 < htfAbcde0) { htfAbcdeActive = false; return; }
      }
   }
   
   if(htfAbcdeActive && htfAbcdeWave == 3)
   {
      bool eConfirmed = false;
      if(htfTrendDirection == 1 && bodyClose1 < htfAbcdeC) eConfirmed = true;
      else if(htfTrendDirection == -1 && bodyClose1 > htfAbcdeC) eConfirmed = true;
      
      if(eConfirmed)
      {
         if(htfTrendDirection == 1)
         {
            htfAbcdeD = HTF_FindHighestHighBetween(htfAbcdeC_Time, barTime1);
            htfAbcdeD_Time = HTF_FindTimeOfHighestHigh(htfAbcdeC_Time, barTime1);
         }
         else
         {
            htfAbcdeD = HTF_FindLowestLowBetween(htfAbcdeC_Time, barTime1);
            htfAbcdeD_Time = HTF_FindTimeOfLowestLow(htfAbcdeC_Time, barTime1);
         }
         if(htfAbcdeD > 0 && htfAbcdeD_Time > 0)
            htfAbcdeWave = 5;
         return;
      }
   }
   
   if(htfAbcdeActive && htfAbcdeWave == 1 && !htfAbcdeA_BodyBroken)
   {
      if(htfTrendDirection == 1 && bodyClose1 < htfAbcdeA) htfAbcdeA_BodyBroken = true;
      else if(htfTrendDirection == -1 && bodyClose1 > htfAbcdeA) htfAbcdeA_BodyBroken = true;
   }
   
   if(!ruleFired) return;
   
   if(htfAbcdeRetraceRuleCount == 0 && !htfAbcdeActive)
   {
      if(htfTrendDirection == 1)
      {
         htfAbcde0 = htfHighestHighSinceTrendStart;
         htfAbcde0_Time = htfHighestHighSinceTrendStart_Time;
         if(htfAbcde0_Time <= 0) return;
         htfAbcdeA = HTF_FindLowestLowBetween(htfAbcde0_Time, barTime1);
         htfAbcdeA_Time = HTF_FindTimeOfLowestLow(htfAbcde0_Time, barTime1);
      }
      else
      {
         htfAbcde0 = htfLowestLowSinceTrendStart;
         htfAbcde0_Time = htfLowestLowSinceTrendStart_Time;
         if(htfAbcde0_Time <= 0) return;
         htfAbcdeA = HTF_FindHighestHighBetween(htfAbcde0_Time, barTime1);
         htfAbcdeA_Time = HTF_FindTimeOfHighestHigh(htfAbcde0_Time, barTime1);
      }
      if(htfAbcdeA > 0 && htfAbcdeA_Time > 0)
      {
         htfAbcdeActive = true;
         htfAbcdeWave = 1;
         htfAbcdeRetraceRuleCount = 1;
         htfAbcdeA_BodyBroken = false;
      }
   }
   else if(htfAbcdeRetraceRuleCount == 1 && htfAbcdeActive && htfAbcdeWave == 1 && htfAbcdeA_BodyBroken)
   {
      htfAbcdeRetraceRuleCount = 2;
      if(htfTrendDirection == 1)
      {
         htfAbcdeC = HTF_FindLowestLowBetween(htfAbcdeA_Time, barTime1);
         htfAbcdeC_Time = HTF_FindTimeOfLowestLow(htfAbcdeA_Time, barTime1);
         if(htfAbcdeC_Time > 0)
         {
            htfAbcdeB = HTF_FindHighestHighBetween(htfAbcdeA_Time, htfAbcdeC_Time);
            htfAbcdeB_Time = HTF_FindTimeOfHighestHigh(htfAbcdeA_Time, htfAbcdeC_Time);
         }
         if(htfAbcdeB >= htfAbcde0) { htfAbcdeActive = false; return; }
         if(htfAbcdeC >= htfAbcdeA) { htfAbcdeActive = false; return; }
      }
      else
      {
         htfAbcdeC = HTF_FindHighestHighBetween(htfAbcdeA_Time, barTime1);
         htfAbcdeC_Time = HTF_FindTimeOfHighestHigh(htfAbcdeA_Time, barTime1);
         if(htfAbcdeC_Time > 0)
         {
            htfAbcdeB = HTF_FindLowestLowBetween(htfAbcdeA_Time, htfAbcdeC_Time);
            htfAbcdeB_Time = HTF_FindTimeOfLowestLow(htfAbcdeA_Time, htfAbcdeC_Time);
         }
         if(htfAbcdeB <= htfAbcde0) { htfAbcdeActive = false; return; }
         if(htfAbcdeC <= htfAbcdeA) { htfAbcdeActive = false; return; }
      }
      if(htfAbcdeB > 0 && htfAbcdeC > 0 && htfAbcdeB_Time > 0 && htfAbcdeC_Time > 0)
         htfAbcdeWave = 3;
      else
         htfAbcdeActive = false;
   }
}

//+------------------------------------------------------------------+
//| HTF Master Update (called on new HTF bar)                        |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| HTF Master Update (called on new HTF bar)                        |
//+------------------------------------------------------------------+
void UpdateHTFTrend()
{
   datetime htfBarTime = iTime(_Symbol, HTF_Period, 0);
   static datetime lastHTFBar = 0;
   if(htfBarTime == lastHTFBar) return;
   lastHTFBar = htfBarTime;

   htfTotalBars = Bars(_Symbol, HTF_Period);
   if(htfTotalBars < 30) { htfTrendDirection = 0; return; }

   // --- INITIAL DETECTION ---
   static bool htfInitialized = false;
   if(!htfInitialized)
   {
      htfInitialized = true;
      htfTrendDirection = 1;
      htfBullishEstablished = false;
      htfHighestHighSinceTrendStart = 0;
      htfHighestHighSinceTrendStart_Time = 0;
      HTF_DetectTrend();
      bool bullishOK = htfBullishEstablished;
      double bullHH = htfHighestHighSinceTrendStart;
      datetime bullHHTime = htfHighestHighSinceTrendStart_Time;
      
      htfTrendDirection = -1;
      htfBearishEstablished = false;
      htfLowestLowSinceTrendStart = 0;
      htfLowestLowSinceTrendStart_Time = 0;
      HTF_DetectTrend();
      bool bearishOK = htfBearishEstablished;
      double bearLL = htfLowestLowSinceTrendStart;
      datetime bearLLTime = htfLowestLowSinceTrendStart_Time;
      
      if(bullishOK && bearishOK) htfTrendDirection = (bullHHTime > bearLLTime) ? 1 : -1;
      else if(bullishOK) htfTrendDirection = 1;
      else if(bearishOK) htfTrendDirection = -1;
      else htfTrendDirection = 0;
      
      htfBullishEstablished = false;
      htfBearishEstablished = false;
      htfHighestHighSinceTrendStart = 0;
      htfLowestLowSinceTrendStart = 0;
      
      if(htfTrendDirection == 1)
      {
         htfBullishEstablished = true;
         htfHighestHighSinceTrendStart = bullHH;
         htfHighestHighSinceTrendStart_Time = bullHHTime;
      }
      else if(htfTrendDirection == -1)
      {
         htfBearishEstablished = true;
         htfLowestLowSinceTrendStart = bearLL;
         htfLowestLowSinceTrendStart_Time = bearLLTime;
      }
      Print("📊 HTF INITIAL → Trend: ", htfTrendDirection == 1 ? "BULLISH" : (htfTrendDirection == -1 ? "BEARISH" : "SIDEWAYS"));
   }
   
   HTF_DetectTrend();
   
   if(htfBullishEstablished || htfBearishEstablished)
   {
      int ruleUsed = 0;
      double trigPrice = 0;
      bool ruleFired = false;
      
      // 1. BoS invalidation
      if(htfRetracementStarted)
      {
         double currClose = iClose(_Symbol, HTF_Period, 1);
         datetime currBarTime = iTime(_Symbol, HTF_Period, 1);
         
         bool invalidated = false;
         if(htfTrendDirection == 1)
            invalidated = (currClose > htfReferenceHighForInvalidation);
         else
            invalidated = (currClose < htfReferenceLowForInvalidation);
         
         if(invalidated)
         {
            Print("📊 HTF BoS DETECTED | Close: ", currClose);
            
            double l1Price = (htfTrendDirection == 1) ? htfReferenceHighForInvalidation : htfReferenceLowForInvalidation;
            datetime l1Time = htfRetracementStartTime;
            
            if(PERIOD_CURRENT == HTF_Period)
               HTF_DrawLevel1Line(l1Price, l1Time);
            
            int fromBar = MathMin(iBarShift(_Symbol, HTF_Period, htfRetracementStartTime), iBarShift(_Symbol, HTF_Period, currBarTime));
            int toBar = MathMax(iBarShift(_Symbol, HTF_Period, htfRetracementStartTime), iBarShift(_Symbol, HTF_Period, currBarTime));
            
            double l2Price = 0;
            datetime l2Time = 0;
            
            if(htfTrendDirection == 1)
            {
               double lowestLow = DBL_MAX;
               for(int i = fromBar; i <= toBar; i++)
               {
                  double low = iLow(_Symbol, HTF_Period, i);
                  if(low < lowestLow) { lowestLow = low; l2Time = iTime(_Symbol, HTF_Period, i); }
               }
               l2Price = lowestLow;
            }
            else
            {
               double highestHigh = -DBL_MAX;
               for(int i = fromBar; i <= toBar; i++)
               {
                  double high = iHigh(_Symbol, HTF_Period, i);
                  if(high > highestHigh) { highestHigh = high; l2Time = iTime(_Symbol, HTF_Period, i); }
               }
               l2Price = highestHigh;
            }
            
            htfCurrentChochLevel = l2Price;
            htfLevel2Price = l2Price;
            
            if(htfAbcdeWave == 5)
               htfPendingChochOrigin = "ABCDE 5-Wave";
            else
               htfPendingChochOrigin = "Normal";
            
            if(PERIOD_CURRENT == HTF_Period)
            {
               int level2BarNumber = 0;
               HTF_DrawLevel2Line(l2Price, l2Time, currBarTime, level2BarNumber);
            }
            
            htfRetracementStarted = false;
            htfMotherCandleActive = false;
         }
      }
      
      // 2. Look for retracement
      if(!htfRetracementStarted)
      {
         ruleFired = HTF_CheckRetracementRules(ruleUsed, trigPrice);
         
         if(ruleFired)
         {
            if(htfTrendDirection == 1)
            {
               datetime trendStartTime = htfHighestHighSinceTrendStart_Time;
               datetime retracementTime = iTime(_Symbol, HTF_Period, 1);
               double refPrice = HTF_FindHighestHighBetween(trendStartTime, retracementTime);
               if(refPrice <= 0) refPrice = MathMax(trigPrice, htfHighestHighSinceTrendStart);
               htfReferenceHighForInvalidation = refPrice;
            }
            else
            {
               datetime trendStartTime = htfLowestLowSinceTrendStart_Time;
               datetime retracementTime = iTime(_Symbol, HTF_Period, 1);
               double refPrice = HTF_FindLowestLowBetween(trendStartTime, retracementTime);
               if(refPrice <= 0) refPrice = MathMin(trigPrice, htfLowestLowSinceTrendStart);
               htfReferenceLowForInvalidation = refPrice;
            }
            
            htfRetracementStarted = true;
            htfRetracementStartTime = iTime(_Symbol, HTF_Period, 1);
            htfRetracementRuleUsed = ruleUsed;
            
            if(PERIOD_CURRENT == HTF_Period)
               HTF_DrawLevel3Line(trigPrice, htfRetracementStartTime, iTime(_Symbol, HTF_Period, 1));
         }
      }
      
            // 3. ABCDE
      HTF_UpdateABCDE(ruleFired, ruleUsed, trigPrice);
      
      // --- FORCE 5-WAVE FLIP IF BODY CLOSES BEYOND C ---
      if(htfAbcdeActive && htfAbcdeWave == 3 && htfAbcdeC > 0)
      {
         double currClose = iClose(_Symbol, HTF_Period, 1);
         
         bool eConfirmed = false;
         if(htfTrendDirection == 1 && currClose < htfAbcdeC) eConfirmed = true;
         if(htfTrendDirection == -1 && currClose > htfAbcdeC) eConfirmed = true;
         
         if(eConfirmed)
         {
            Print("🎯 HTF FORCE FLIP: 5-Wave completed (body closed beyond C)");
            
            // Update Dashboard
            htfLastSwitchReason = "ABCDE 5-Wave";
            htfLastSwitchTime = iTime(_Symbol, HTF_Period, 1);
            
            if(htfTrendDirection == 1) // Bullish → Bearish
            {
               htfTrendDirection = -1;
               htfBullishEstablished = false;
               htfHighestHighSinceTrendStart = 0;
               htfBearishEstablished = true;
               htfLowestLowSinceTrendStart = currClose;
               htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
            }
            else // Bearish → Bullish
            {
               htfTrendDirection = 1;
               htfBearishEstablished = false;
               htfLowestLowSinceTrendStart = 0;
               htfBullishEstablished = true;
               htfHighestHighSinceTrendStart = currClose;
               htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
            }
            
            // Reset ABCDE & clear Mother Candle
            htfAbcdeWave = 0;
            htfAbcdeActive = false;
            htfCurrentChochLevel = 0;
            htfLevel2Price = 0;
            htfMotherCandleActive = false;
            ObjectDelete(0, "HTF_MotherCandle_Box");
            ObjectDelete(0, "HTF_MotherCandle_Label");
         }
      }
      
      // 4. ChoCh Confirmation (Force trend shift even if retracement was active)
      if(htfCurrentChochLevel > 0)
      {
         double currentClose = iClose(_Symbol, HTF_Period, 1);
         double previousClose = iClose(_Symbol, HTF_Period, 2);
         
         bool chochFired = false;
         
         if(htfTrendDirection == 1 && currentClose < htfCurrentChochLevel && previousClose < htfCurrentChochLevel)
         {
            Print("🎯 HTF CHOCH (Bullish → Bearish) at ", htfCurrentChochLevel);
            
            htfLastSwitchReason = (htfPendingChochOrigin == "ABCDE 5-Wave") ? "ABCDE 5-Wave" : "HTF ChoCh/MSS";
            htfLastSwitchTime = iTime(_Symbol, HTF_Period, 1);
            
            if(PERIOD_CURRENT == HTF_Period)
               HTF_DrawChochConfirmation(htfCurrentChochLevel, iTime(_Symbol, HTF_Period, 1));
               
            htfTrendDirection = -1;
            htfBullishEstablished = false;
            htfHighestHighSinceTrendStart = 0;
            htfHighestHighSinceTrendStart_Time = 0;
            htfBearishEstablished = true;
            htfLowestLowSinceTrendStart = currentClose;
            htfLowestLowSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
            chochFired = true;
         }
         else if(htfTrendDirection == -1 && currentClose > htfCurrentChochLevel && previousClose > htfCurrentChochLevel)
         {
            Print("🎯 HTF CHOCH (Bearish → Bullish) at ", htfCurrentChochLevel);
            
            htfLastSwitchReason = (htfPendingChochOrigin == "ABCDE 5-Wave") ? "ABCDE 5-Wave" : "HTF ChoCh/MSS";
            htfLastSwitchTime = iTime(_Symbol, HTF_Period, 1);
            
            if(PERIOD_CURRENT == HTF_Period)
               HTF_DrawChochConfirmation(htfCurrentChochLevel, iTime(_Symbol, HTF_Period, 1));
               
            htfTrendDirection = 1;
            htfBearishEstablished = false;
            htfLowestLowSinceTrendStart = 0;
            htfLowestLowSinceTrendStart_Time = 0;
            htfBullishEstablished = true;
            htfHighestHighSinceTrendStart = currentClose;
            htfHighestHighSinceTrendStart_Time = iTime(_Symbol, HTF_Period, 1);
            chochFired = true;
         }
         
         if(chochFired)
         {
            // FORCE RESET ALL RETRACEMENT STATES
            htfCurrentChochLevel = 0;
            htfLevel2Price = 0;
            htfRetracementStarted = false;
            htfMotherCandleActive = false;
            htfAbcdeActive = false;
            htfAbcdeWave = 0;
            htfAbcdeRetraceRuleCount = 0;
            htfAbcdeA_BodyBroken = false;
            htfPendingChochOrigin = "Normal";
            
             motherCandleActive = false;
             ObjectDelete(0, "MotherCandle_Box");
             ObjectDelete(0, "MotherCandle_Label");
         }
      }
   }
   
   // 5. Final Draws
   if(PERIOD_CURRENT == HTF_Period)
   {
      if(ShowHTFTrendLabel) DrawHTFTrendLabel();
      if(htfAbcdeWave >= 1) HTF_DrawABCDEVisuals();
   }
   
   Print("📊 HTF TREND (", EnumToString(HTF_Period), ") → ",
         htfTrendDirection == 1 ? "BULLISH 🟢" : (htfTrendDirection == -1 ? "BEARISH 🔴" : "SIDEWAYS ⚪"),
         " | RetStarted: ", htfRetracementStarted,
         " | ChoChLevel: ", DoubleToString(htfCurrentChochLevel, _Digits));
}

#endif // HTF_TREND_MQH
//+------------------------------------------------------------------+