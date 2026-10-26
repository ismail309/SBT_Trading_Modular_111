//+------------------------------------------------------------------+
//|                                                  SBT_ABCDE.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  ABCDE (Elliott Wave) visuals, wave tracking, ABCDE ChoCh fire.  |
//+------------------------------------------------------------------+
#ifndef SBT_ABCDE_MQH
#define SBT_ABCDE_MQH

#include "SBT_Zones.mqh"

//+------------------------------------------------------------------+
//| Forward declarations                                             |
//+------------------------------------------------------------------+
void CleanupZonesForABCDE();

//+------------------------------------------------------------------+
//| ABCDE visuals                                                    |
//+------------------------------------------------------------------+
void DeleteABCDEVisuals()
{
   ObjectDelete(0, "ABCDE_Label0");
   ObjectDelete(0, "ABCDE_LabelA");
   ObjectDelete(0, "ABCDE_LabelB");
   ObjectDelete(0, "ABCDE_LabelC");
   ObjectDelete(0, "ABCDE_LabelD");
   ObjectDelete(0, "ABCDE_LabelE");

   ObjectDelete(0, "ABCDE_Line0A");
   ObjectDelete(0, "ABCDE_LineAB");
   ObjectDelete(0, "ABCDE_LineBC");
   ObjectDelete(0, "ABCDE_LineCD");
   ObjectDelete(0, "ABCDE_LineDE");

   ObjectDelete(0, "ABCDE_HLineA");
   ObjectDelete(0, "ABCDE_HLineB");
   ObjectDelete(0, "ABCDE_HLineC");
   ObjectDelete(0, "ABCDE_HLineD");
}

void DrawABCDELabel(string name, datetime time, double price, string text, color col, int anchor)
{
   if(!ShowABCDEVisuals) return;
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 11);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, anchor);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
}

void DrawABCDELine(string name, datetime t1, double p1, datetime t2, double p2, color col)
{
   if(!ShowABCDEVisuals) return;
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void DrawABCDEHorizontal(string name, double price, datetime timeStart, color col, ENUM_LINE_STYLE style = STYLE_DOT)
{
   if(!ShowABCDEVisuals) return;
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime t1 = timeStart - (periodSeconds * 20);
   datetime t2 = iTime(_Symbol, PERIOD_CURRENT, 0) + (periodSeconds * 20);

   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

void DrawABCDEVisuals()
{
   if(!ShowABCDEVisuals) return;

   if(abcde0_Time > 0 && abcde0 > 0)
   {
      int anchor0 = (trendDirection == 1) ? ANCHOR_LOWER : ANCHOR_UPPER;
      DrawABCDELabel("ABCDE_Label0", abcde0_Time, abcde0, "0", COLOR_ABCDE, anchor0);
   }

   if(abcdeA_Time > 0 && abcdeA > 0)
   {
      int anchorA = (trendDirection == 1) ? ANCHOR_UPPER : ANCHOR_LOWER;
      DrawABCDELabel("ABCDE_LabelA", abcdeA_Time, abcdeA, "A", COLOR_ABCDE, anchorA);
   }

   if(abcdeB_Time > 0 && abcdeB > 0)
   {
      int anchorB = (trendDirection == 1) ? ANCHOR_LOWER : ANCHOR_UPPER;
      DrawABCDELabel("ABCDE_LabelB", abcdeB_Time, abcdeB, "B", COLOR_ABCDE, anchorB);
   }

   if(abcdeC_Time > 0 && abcdeC > 0)
   {
      int anchorC = (trendDirection == 1) ? ANCHOR_UPPER : ANCHOR_LOWER;
      DrawABCDELabel("ABCDE_LabelC", abcdeC_Time, abcdeC, "C", COLOR_ABCDE, anchorC);
   }

   if(abcdeD_Time > 0 && abcdeD > 0)
   {
      int anchorD = (trendDirection == 1) ? ANCHOR_LOWER : ANCHOR_UPPER;
      DrawABCDELabel("ABCDE_LabelD", abcdeD_Time, abcdeD, "D", COLOR_ABCDE, anchorD);
   }

   if(abcdeD_Time > 0)
   {
      datetime eTime = iTime(_Symbol, PERIOD_CURRENT, 1);
      double ePrice = iClose(_Symbol, PERIOD_CURRENT, 1);
      int anchorE = (trendDirection == 1) ? ANCHOR_UPPER : ANCHOR_LOWER;
      DrawABCDELabel("ABCDE_LabelE", eTime, ePrice, "E", COLOR_ABCDE, anchorE);
   }

   if(abcde0_Time > 0 && abcdeA_Time > 0 && abcde0 > 0 && abcdeA > 0)
      DrawABCDELine("ABCDE_Line0A", abcde0_Time, abcde0, abcdeA_Time, abcdeA, COLOR_ABCDE);

   if(abcdeA_Time > 0 && abcdeB_Time > 0 && abcdeA > 0 && abcdeB > 0)
      DrawABCDELine("ABCDE_LineAB", abcdeA_Time, abcdeA, abcdeB_Time, abcdeB, COLOR_ABCDE);

   if(abcdeB_Time > 0 && abcdeC_Time > 0 && abcdeB > 0 && abcdeC > 0)
      DrawABCDELine("ABCDE_LineBC", abcdeB_Time, abcdeB, abcdeC_Time, abcdeC, COLOR_ABCDE);

   if(abcdeC_Time > 0 && abcdeD_Time > 0 && abcdeC > 0 && abcdeD > 0)
      DrawABCDELine("ABCDE_LineCD", abcdeC_Time, abcdeC, abcdeD_Time, abcdeD, COLOR_ABCDE);

   if(abcdeD_Time > 0 && abcdeD > 0)
   {
      datetime eTime = iTime(_Symbol, PERIOD_CURRENT, 1);
      double ePrice = iClose(_Symbol, PERIOD_CURRENT, 1);
      DrawABCDELine("ABCDE_LineDE", abcdeD_Time, abcdeD, eTime, ePrice, COLOR_ABCDE);
   }

   if(abcdeA_Time > 0 && abcdeA > 0)
      DrawABCDEHorizontal("ABCDE_HLineA", abcdeA, abcdeA_Time, clrGray);

   if(abcdeB_Time > 0 && abcdeB > 0)
      DrawABCDEHorizontal("ABCDE_HLineB", abcdeB, abcdeB_Time, clrGray);

   if(abcdeC_Time > 0 && abcdeC > 0)
      DrawABCDEHorizontal("ABCDE_HLineC", abcdeC, abcdeC_Time, clrGray);

   if(abcdeD_Time > 0 && abcdeD > 0)
      DrawABCDEHorizontal("ABCDE_HLineD", abcdeD, abcdeD_Time, clrGray);
}

void ResetABCDE()
{
   abcdeActive           = false;
   abcdeWave             = 0;
   abcde0                = 0;
   abcdeA                = 0;
   abcdeB                = 0;
   abcdeC                = 0;
   abcdeD                = 0;
   abcdeA_Time           = 0;
   abcdeB_Time           = 0;
   abcdeC_Time           = 0;
   abcdeD_Time           = 0;
   abcde0_Time           = 0;
   abcdeRetraceRuleCount = 0;
   abcdeA_BodyBroken     = false;

   DeleteABCDEVisuals();
}

//+------------------------------------------------------------------+
//| Update ABCDE tracking                                            |
//+------------------------------------------------------------------+
void UpdateABCDE(bool ruleFired, int ruleUsed, double triggerPrice)
{
   double bodyClose1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   datetime barTime1 = iTime(_Symbol, PERIOD_CURRENT, 1);
   
   if(abcdeActive)
   {
      if(abcdeWave >= 3 && abcdeB > 0)
      {
         if(trendDirection == 1 && bodyClose1 > abcdeB) { ResetABCDE(); return; }
         if(trendDirection == -1 && bodyClose1 < abcdeB) { ResetABCDE(); return; }
      }
      
      if(abcdeWave == 1 && abcde0 > 0)
      {
         if(trendDirection == 1 && bodyClose1 > abcde0) { ResetABCDE(); return; }
         if(trendDirection == -1 && bodyClose1 < abcde0) { ResetABCDE(); return; }
      }
   }
   
      // CHECK FOR 5-WAVE COMPLETION AND FORCE TREND FLIP
   if(abcdeActive && abcdeWave == 3)
   {
      bool eConfirmed = false;
      
      if(trendDirection == 1 && bodyClose1 < abcdeC)
         eConfirmed = true;
      else if(trendDirection == -1 && bodyClose1 > abcdeC)
         eConfirmed = true;
      
      if(eConfirmed)
      {
         // 1. Set the reason for the dashboard
         htfLastSwitchReason = "ABCDE 5-Wave";
         htfLastSwitchTime = iTime(_Symbol, PERIOD_CURRENT, 1);
         
         // 2. Find Wave D (Highest High between C and current bar)
         if(trendDirection == 1)
         {
            abcdeD = FindHighestHighBetween(abcdeC_Time, barTime1);
            abcdeD_Time = FindTimeOfHighestHigh(abcdeC_Time, barTime1);
         }
         else
         {
            abcdeD = FindLowestLowBetween(abcdeC_Time, barTime1);
            abcdeD_Time = FindTimeOfLowestLow(abcdeC_Time, barTime1);
         }
         
         if(abcdeD > 0 && abcdeD_Time > 0)
         {
            abcdeWave = 5;
            FireABCDEChoCh(); // This function forces the flip
         }
         return;
      }
   }
   
   if(abcdeActive && abcdeWave == 1 && !abcdeA_BodyBroken)
   {
      if(trendDirection == 1 && bodyClose1 < abcdeA)
         abcdeA_BodyBroken = true;
      else if(trendDirection == -1 && bodyClose1 > abcdeA)
         abcdeA_BodyBroken = true;
   }
   
   if(!ruleFired) return;
   
   if(abcdeRetraceRuleCount == 0 && !abcdeActive)
   {
      if(trendDirection == 1)
      {
         abcde0 = highestHighSinceTrendStart;
         abcde0_Time = highestHighSinceTrendStart_Time;
         if(abcde0_Time <= 0) return;
         abcdeA = FindLowestLowBetween(abcde0_Time, barTime1);
         abcdeA_Time = FindTimeOfLowestLow(abcde0_Time, barTime1);
      }
      else
      {
         abcde0 = lowestLowSinceTrendStart;
         abcde0_Time = lowestLowSinceTrendStart_Time;
         if(abcde0_Time <= 0) return;
         abcdeA = FindHighestHighBetween(abcde0_Time, barTime1);
         abcdeA_Time = FindTimeOfHighestHigh(abcde0_Time, barTime1);
      }
      
      if(abcdeA > 0 && abcdeA_Time > 0)
      {
         abcdeActive = true;
         abcdeWave = 1;
         abcdeRetraceRuleCount = 1;
         abcdeA_BodyBroken = false;
         DrawABCDEVisuals();
      }
   }
   else if(abcdeRetraceRuleCount == 1 && abcdeActive && abcdeWave == 1 && abcdeA_BodyBroken)
   {
      abcdeRetraceRuleCount = 2;
      
      if(trendDirection == 1)
      {
         // Wave B is the absolute highest high between A and C
         abcdeC = FindLowestLowBetween(abcdeA_Time, barTime1);
         abcdeC_Time = FindTimeOfLowestLow(abcdeA_Time, barTime1);
         
         if(abcdeC_Time > 0)
         {
             // THIS IS THE FIX
            abcdeB = FindHighestHighBetween(abcdeA_Time, abcdeC_Time);
            abcdeB_Time = FindTimeOfHighestHigh(abcdeA_Time, abcdeC_Time);
         }
         
         if(abcdeB >= abcde0) { ResetABCDE(); return; }
         if(abcdeC >= abcdeA) { ResetABCDE(); return; }
      }
      else
      {
         abcdeC = FindHighestHighBetween(abcdeA_Time, barTime1);
         abcdeC_Time = FindTimeOfHighestHigh(abcdeA_Time, barTime1);
         
         if(abcdeC_Time > 0)
         {
            abcdeB = FindLowestLowBetween(abcdeA_Time, abcdeC_Time);
            abcdeB_Time = FindTimeOfLowestLow(abcdeA_Time, abcdeC_Time);
         }
         
         if(abcdeB <= abcde0) { ResetABCDE(); return; }
         if(abcdeC <= abcdeA) { ResetABCDE(); return; }
      }
      
      if(abcdeB > 0 && abcdeC > 0 && abcdeB_Time > 0 && abcdeC_Time > 0)
      {
         abcdeWave = 3;
         DrawABCDEVisuals();
      }
      else
      {
         ResetABCDE();
      }
   }
}

//+------------------------------------------------------------------+
//| Fire ABCDE ChoCh — wave 5 confirmed                              |
//| Light trend switch: no BBB/QML/DB/SBB/DT, no position close      |
//| SZ/DZ anchor: bullish/bearish candle in C→D leg whose close is   |
//|               closest to wave D. MB: closest candle on D→E leg   |
//|               whose close is still beyond BoS(C).                |
//+------------------------------------------------------------------+
void FireABCDEChoCh()
{
   Print("🎯 ABCDE ChoCh FIRED — E confirmed at Wave C price: ", abcdeC);
   
   // --- UPDATE DASHBOARD REASON HERE ---
   htfLastSwitchReason = "ABCDE 5-Wave";
   htfLastSwitchTime = iTime(_Symbol, PERIOD_CURRENT, 1);
   // ------------------------------------
   
    // FORCE DASHBOARD UPDATE
   UpdateDashboard();
   
   bool bearishReversal = (trendDirection == 1);

   DrawABCDEVisuals();

   // Conf 2b: delete old ChoCh/Level1/Level2/Level3/MB/DZ/SZ objects
   CleanupZonesForABCDE();

   // ChoCh line = Level 2 at wave D
   currentChoChLevel = abcdeD;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = abcdeD_Time - (periodSeconds * 10);
   datetime lineEndTime   = abcdeD_Time + (periodSeconds * 20);

   ObjectCreate(0, "ChoCh_Line", OBJ_TREND, 0, lineStartTime, abcdeD, lineEndTime, abcdeD);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_COLOR, COLOR_LEVEL2);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice = abcdeD - (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = abcdeD - (15 * _Point * 10);

   ObjectCreate(0, "ChoCh_Label", OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, "ChoCh_Label", OBJPROP_TEXT, "2");
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_COLOR, COLOR_LEVEL2);
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "ChoCh_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_ANCHOR, ANCHOR_UPPER);

   // BoS line at wave C
   DrawABCDEBoSLine(abcdeC, abcdeC_Time);

   // ============ DZ/SZ from C→D leg ============
   int cBar = iBarShift(_Symbol, PERIOD_CURRENT, abcdeC_Time);
   int dBar = iBarShift(_Symbol, PERIOD_CURRENT, abcdeD_Time);

   if(cBar >= 0 && dBar >= 0)
   {
      int fromBar = MathMin(cBar, dBar);
      int toBar   = MathMax(cBar, dBar);

      if(bearishReversal)
      {
         // -------- SZ (bearish reversal) --------
         // top = highest high in C→D leg
         double szTop = -DBL_MAX;
         for(int i = fromBar; i <= toBar; i++)
         {
            double h = iHigh(_Symbol, PERIOD_CURRENT, i);
            if(h > szTop) szTop = h;
         }

         // anchor = bullish candle whose CLOSE is closest to wave D high
         double closestDist = DBL_MAX;
         int    anchorBar = -1;
         for(int i = fromBar; i <= toBar; i++)
         {
            if(IsBullish(i))
            {
               double close = iClose(_Symbol, PERIOD_CURRENT, i);
               double dist = MathAbs(abcdeD - close);
               if(dist < closestDist)
               {
                  closestDist = dist;
                  anchorBar = i;
               }
            }
         }

         if(anchorBar >= 0 && szTop > 0)
         {
            double szBottom = iOpen(_Symbol, PERIOD_CURRENT, anchorBar);
            datetime szAnchorTime = iTime(_Symbol, PERIOD_CURRENT, anchorBar);
            double szAnchorHigh  = iHigh(_Symbol, PERIOD_CURRENT, anchorBar);
            double szAnchorLow   = iLow(_Symbol, PERIOD_CURRENT, anchorBar);

            // host DrawSupplyZone requires openPrice < level2Price
            if(szBottom >= szTop)
               szBottom = MathMin(szBottom, szTop - _Point);

            Print("📊 ABCDE SZ: anchorBar=", anchorBar,
                  " anchorTime=", TimeToString(szAnchorTime),
                  " closeDistToD=", DoubleToString(closestDist, _Digits),
                  " szTop=", szTop, " szBottom(open)=", szBottom);

            DrawSupplyZone(szAnchorTime, szBottom, szAnchorHigh, szAnchorLow,
                           szTop, abcdeD_Time, abcdeC_Time);
         }
         else
         {
            Print("⚠️ ABCDE SZ: no bullish anchor found in C→D leg");
         }
      }
      else
      {
         // -------- DZ (bullish reversal) --------
         // bottom = lowest low in C→D leg
         double dzBottom = DBL_MAX;
         for(int i = fromBar; i <= toBar; i++)
         {
            double l = iLow(_Symbol, PERIOD_CURRENT, i);
            if(l < dzBottom) dzBottom = l;
         }

         // anchor = bearish candle whose CLOSE is closest to wave D low
         double closestDist = DBL_MAX;
         int    anchorBar = -1;
         for(int i = fromBar; i <= toBar; i++)
         {
            if(IsBearish(i))
            {
               double close = iClose(_Symbol, PERIOD_CURRENT, i);
               double dist = MathAbs(close - abcdeD);
               if(dist < closestDist)
               {
                  closestDist = dist;
                  anchorBar = i;
               }
            }
         }

         if(anchorBar >= 0 && dzBottom > 0)
         {
            double dzTop = iOpen(_Symbol, PERIOD_CURRENT, anchorBar);
            datetime dzAnchorTime = iTime(_Symbol, PERIOD_CURRENT, anchorBar);
            double dzAnchorHigh  = iHigh(_Symbol, PERIOD_CURRENT, anchorBar);
            double dzAnchorLow   = iLow(_Symbol, PERIOD_CURRENT, anchorBar);

            // host DrawDemandZone requires openPrice > level2Price
            if(dzTop <= dzBottom)
               dzTop = MathMax(dzTop, dzBottom + _Point);

            Print("📊 ABCDE DZ: anchorBar=", anchorBar,
                  " anchorTime=", TimeToString(dzAnchorTime),
                  " closeDistToD=", DoubleToString(closestDist, _Digits),
                  " dzTop(open)=", dzTop, " dzBottom=", dzBottom);

            DrawDemandZone(dzAnchorTime, dzTop, dzAnchorHigh, dzAnchorLow,
                           dzBottom, abcdeD_Time, abcdeC_Time);
         }
         else
         {
            Print("⚠️ ABCDE DZ: no bearish anchor found in C→D leg");
         }
      }
   }
   else
   {
      Print("⚠️ ABCDE DZ/SZ: invalid C or D bar index (cBar=", cBar, " dBar=", dBar, ")");
   }

   // ============ MB after BoS (scan B→C and C→D for closest close to C) ============
   int mbStartBar = -1;
   double mbTop = 0, mbBottom = 0;
   datetime mbStartTime = 0;
   double smallestDist = DBL_MAX;

   int bBar = iBarShift(_Symbol, PERIOD_CURRENT, abcdeB_Time);
   // dBar is already declared earlier in FireABCDEChoCh

   Print("========================================");
   Print("🔍 MB SCANNING - START");
   Print("   Wave C Time: ", TimeToString(abcdeC_Time), " | Price: ", DoubleToString(abcdeC, _Digits));
   Print("   Wave B Time: ", TimeToString(abcdeB_Time), " | Bar Index: ", bBar);
   Print("   Wave D Time: ", TimeToString(abcdeD_Time), " | Bar Index: ", dBar);

   if(bBar >= 0 && dBar >= 0)
   {
      int startIndex = MathMax(bBar, dBar); // oldest (B)
      int endIndex   = MathMin(bBar, dBar); // newest (D)

      if(bearishReversal)
      {
         // Find the BEARISH candle closest to C in B→D
         for(int i = endIndex; i <= startIndex; i++)
         {
            if(IsBearish(i))
            {
               double close = iClose(_Symbol, PERIOD_CURRENT, i);
               double dist = MathAbs(close - abcdeC);
               
               Print("   [Bearish Candle] Bar: ", i, 
                     " Time: ", TimeToString(iTime(_Symbol, PERIOD_CURRENT, i)),
                     " O: ", DoubleToString(iOpen(_Symbol, PERIOD_CURRENT, i), _Digits),
                     " H: ", DoubleToString(iHigh(_Symbol, PERIOD_CURRENT, i), _Digits),
                     " L: ", DoubleToString(iLow(_Symbol, PERIOD_CURRENT, i), _Digits),
                     " C: ", DoubleToString(close, _Digits),
                     " | Dist to C: ", DoubleToString(dist, _Digits));
                     
               if(dist < smallestDist)
               {
                  smallestDist = dist;
                  mbStartBar = i;
                  mbTop = abcdeC;
                  mbBottom = close;
               }
            }
         }
      }
      else
      {
         // Find the BULLISH candle closest to C in B→D
         for(int i = endIndex; i <= startIndex; i++)
         {
            if(IsBullish(i))
            {
               double close = iClose(_Symbol, PERIOD_CURRENT, i);
               double dist = MathAbs(close - abcdeC);
               
               Print("   [Bullish Candle] Bar: ", i, 
                     " Time: ", TimeToString(iTime(_Symbol, PERIOD_CURRENT, i)),
                     " O: ", DoubleToString(iOpen(_Symbol, PERIOD_CURRENT, i), _Digits),
                     " H: ", DoubleToString(iHigh(_Symbol, PERIOD_CURRENT, i), _Digits),
                     " L: ", DoubleToString(iLow(_Symbol, PERIOD_CURRENT, i), _Digits),
                     " C: ", DoubleToString(close, _Digits),
                     " | Dist to C: ", DoubleToString(dist, _Digits));
                     
               if(dist < smallestDist)
               {
                  smallestDist = dist;
                  mbStartBar = i;
                  mbBottom = close;
                  mbTop = abcdeC;
               }
            }
         }
      }
   }

   if(mbStartBar >= 0 && mbTop > mbBottom)
   {
      // 1. Get the exact time of the candle we just found
      datetime anchorCandleTime = iTime(_Symbol, PERIOD_CURRENT, mbStartBar);
      
      // 2. Apply the 2-candle left buffer to that exact time
      int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
      mbStartTime = anchorCandleTime - (periodSeconds * ZoneLeftBufferCandles);
      
      // 3. Find the BoS confirmation candle time (where price actually closed past C)
      datetime bosTime = iTime(_Symbol, PERIOD_CURRENT, 1); // fallback
      for(int i = 1; i <= 20; i++)
      {
         double close = iClose(_Symbol, PERIOD_CURRENT, i);
         if(bearishReversal && close < abcdeC) 
         { 
            bosTime = iTime(_Symbol, PERIOD_CURRENT, i); 
            break; 
         }
         if(!bearishReversal && close > abcdeC) 
         { 
            bosTime = iTime(_Symbol, PERIOD_CURRENT, i); 
            break; 
         }
      }
      
      Print("========================================");
      Print("✅ MB FOUND & DRAWING");
      Print("   Anchor Bar: ", mbStartBar);
      Print("   Anchor Time: ", TimeToString(anchorCandleTime));
      Print("   Start Time (with buffer): ", TimeToString(mbStartTime));
      Print("   BoS Time (End): ", TimeToString(bosTime));
      Print("   MB Top: ", DoubleToString(mbTop, _Digits));
      Print("   MB Bottom: ", DoubleToString(mbBottom, _Digits));
      Print("========================================");
      
      // 4. Draw from the left-buffered anchor to the BoS candle
      DrawMitigationBlock(mbStartTime, mbBottom, mbTop, bosTime, bosTime);
   }
   else
   {
      Print("⚠️ ABCDE MB: no qualifying candle found. Using C-D fallback.");
      
      int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
      datetime fallbackStart = abcdeC_Time - (periodSeconds * ZoneLeftBufferCandles);
      datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 1);
      
      Print("   Fallback Start Time (C - buffer): ", TimeToString(fallbackStart));
      Print("   Fallback End Time (current): ", TimeToString(currentTime));
      
      if(bearishReversal)
         DrawMitigationBlock(fallbackStart, abcdeC, abcdeD, currentTime, currentTime);
      else
         DrawMitigationBlock(fallbackStart, abcdeD, abcdeC, currentTime, currentTime);
   }

   // ============ Light trend switch (no BBB/QML/DB/SBB/DT) ============
   if(bearishReversal)
   {
      trendDirection = -1;
      bullishTrendEstablished = false;
      highestHighSinceTrendStart = 0;
      highestHighSinceTrendStart_Time = 0;
      bearishTrendEstablished = true;
      lowestLowSinceTrendStart = abcdeC;
      lowestLowSinceTrendStart_Time = abcdeC_Time;
      bearishTrendStartTime = TimeCurrent();
   }
   else
   {
      trendDirection = 1;
      bearishTrendEstablished = false;
      lowestLowSinceTrendStart = 0;
      lowestLowSinceTrendStart_Time = 0;
      bullishTrendEstablished = true;
      highestHighSinceTrendStart = abcdeC;
      highestHighSinceTrendStart_Time = abcdeC_Time;
      bullishTrendStartTime = TimeCurrent();
   }
   

   // Clear retracement / ChoCh tracking
   retracementStarted = false;
   retracementStartTime = 0;
   retracementRuleUsed = 0;
   referenceHighForInvalidation = 0;
   referenceLowForInvalidation = 0;
   motherCandleActive = false;
   consecutiveBearishBelowChoCh = 0;
   consecutiveBullishAboveChoCh = 0;
   chochConfirmed = false;

   // Reset Level tracking
   currentLevel3Price = 0;
   level3DrawTime = 0;
   level1BreakTime = abcdeC_Time;
   level1BreakPrice = abcdeC;
   level1DrawTime = abcdeC_Time;

   // PRIORITY FLAG: skip normal 2-candle ChoCh this bar
   abcdeChochFiredThisBar = true;

   // Reset ABCDE tracking state (keep visuals)
   abcdeActive           = false;
   abcdeWave             = 0;
   abcde0                = 0;
   abcdeA                = 0;
   abcdeB                = 0;
   abcdeC                = 0;
   abcdeD                = 0;
   abcde0_Time           = 0;
   abcdeA_Time           = 0;
   abcdeB_Time           = 0;
   abcdeC_Time           = 0;
   abcdeD_Time           = 0;
   abcdeRetraceRuleCount = 0;
   abcdeA_BodyBroken     = false;

   Print("✅ ABCDE light trend switch complete. trendDirection=", trendDirection);
  
}

#endif // SBT_ABCDE_MQH
//+------------------------------------------------------------------+