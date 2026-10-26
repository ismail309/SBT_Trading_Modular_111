//+------------------------------------------------------------------+
//|                                               HTF_Drawing.mqh    |
//|                                    Copyright 2026, sbt_trading   |
//|  HTF visuals mirroring LTF logic.                                |
//+------------------------------------------------------------------+
#ifndef HTF_DRAWING_MQH
#define HTF_DRAWING_MQH

#include "SBT_State.mqh"

//+------------------------------------------------------------------+
//| Delete all HTF visuals                                           |
//+------------------------------------------------------------------+
void HTF_DeleteAllVisuals()
{
   ObjectDelete(0, "HTF_Label0");
   ObjectDelete(0, "HTF_LabelA");
   ObjectDelete(0, "HTF_LabelB");
   ObjectDelete(0, "HTF_LabelC");
   ObjectDelete(0, "HTF_LabelD");
   ObjectDelete(0, "HTF_LabelE");

   ObjectDelete(0, "HTF_Line0A");
   ObjectDelete(0, "HTF_LineAB");
   ObjectDelete(0, "HTF_LineBC");
   ObjectDelete(0, "HTF_LineCD");
   ObjectDelete(0, "HTF_LineDE");

   ObjectDelete(0, "HTF_Level1_Line");
   ObjectDelete(0, "HTF_Level1_Label");
   ObjectDelete(0, "HTF_Level2_Line");
   ObjectDelete(0, "HTF_Level2_Label");
   ObjectDelete(0, "HTF_Level3_Line");
   ObjectDelete(0, "HTF_Level3_Label");
   ObjectDelete(0, "HTF_ChochConfirm");
}

//+------------------------------------------------------------------+
//| Draw HTF Text Label                                              |
//+------------------------------------------------------------------+
void HTF_DrawLabel(string name, datetime time, double price, string text, color col, int anchor)
{
   if(time <= 0 || price <= 0) return;
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

//+------------------------------------------------------------------+
//| Draw HTF Trend Line                                              |
//+------------------------------------------------------------------+
void HTF_DrawTrendLine(string name, datetime t1, double p1, datetime t2, double p2, color col, int width = 2, ENUM_LINE_STYLE style = STYLE_SOLID)
{
   if(t1 <= 0 || p1 <= 0 || t2 <= 0 || p2 <= 0) return;
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw HTF Level 1 (BoS)                                           |
//+------------------------------------------------------------------+
void HTF_DrawLevel1Line(double price, datetime time)
{
   if(price <= 0 || time <= 0) return;
   int periodSeconds = PeriodSeconds(HTF_Period);
   datetime startTime = time - (periodSeconds * 10);
   datetime endTime   = time + (periodSeconds * 20);

   HTF_DrawTrendLine("HTF_Level1_Line", startTime, price, endTime, price, clrDodgerBlue, 2);

   double labelPrice = price + (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);

   HTF_DrawLabel("HTF_Level1_Label", startTime + periodSeconds, labelPrice, "HTF BoS", clrDodgerBlue, ANCHOR_LOWER);
}

//+------------------------------------------------------------------+
//| Draw HTF Level 3 (Retracement)                                   |
//+------------------------------------------------------------------+
void HTF_DrawLevel3Line(double price, datetime retracementTime, datetime bosBreakTime)
{
   if(price <= 0 || retracementTime <= 0) return;
   int startBar = iBarShift(_Symbol, HTF_Period, retracementTime);
   int endBar   = iBarShift(_Symbol, HTF_Period, bosBreakTime);
   if(startBar < 0 || endBar < 0) return;

   datetime startCandleTime = iTime(_Symbol, HTF_Period, startBar);
   datetime endCandleTime = iTime(_Symbol, HTF_Period, endBar);
   int periodSeconds = PeriodSeconds(HTF_Period);
   datetime lineStartTime = startCandleTime - (periodSeconds * 10);
   datetime lineEndTime = endCandleTime;

   HTF_DrawTrendLine("HTF_Level3_Line", lineStartTime, price, lineEndTime, price, clrGoldenrod, 2);

   double labelPrice = price + (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);

   HTF_DrawLabel("HTF_Level3_Label", lineStartTime + periodSeconds, labelPrice, "HTF 3", clrGoldenrod, ANCHOR_LOWER);
}

//+------------------------------------------------------------------+
//| Draw HTF Level 2 (ChoCh) — DRAW ONLY, no state update            |
//+------------------------------------------------------------------+
void HTF_DrawLevel2Line(double level2Price, datetime level2Time, datetime bosBreakTime, int &barNumber)
{
   int endBar = iBarShift(_Symbol, HTF_Period, bosBreakTime);
   if(endBar < 0) return;

   datetime endCandleTime = iTime(_Symbol, HTF_Period, endBar);
   int periodSeconds = PeriodSeconds(HTF_Period);
   datetime lineStartTime = level2Time - (periodSeconds * 10);
   datetime lineEndTime = endCandleTime;

   // NOTE: state updates (htfCurrentChochLevel, barNumber) are handled by the CALLER
   barNumber = iBarShift(_Symbol, HTF_Period, level2Time);

   HTF_DrawTrendLine("HTF_Level2_Line", lineStartTime, level2Price, lineEndTime, level2Price, clrRed, 2);

   double labelPrice = level2Price - (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = level2Price - (15 * _Point * 10);

   HTF_DrawLabel("HTF_Level2_Label", lineStartTime + periodSeconds, labelPrice, "HTF 2", clrRed, ANCHOR_UPPER);
}

//+------------------------------------------------------------------+
//| Draw HTF ChoCh Confirmation                                      |
//+------------------------------------------------------------------+
void HTF_DrawChochConfirmation(double price, datetime time)
{
   if(price <= 0 || time <= 0) return;
   int periodSeconds = PeriodSeconds(HTF_Period);
   datetime lineStartTime = time - (periodSeconds * 10);
   double labelPrice = price - (25 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price - (25 * _Point * 10);

   HTF_DrawLabel("HTF_ChochConfirm", lineStartTime + periodSeconds, labelPrice, "HTF ChoCh/MsS", clrMagenta, ANCHOR_UPPER);
}

//+------------------------------------------------------------------+
//| Draw HTF ABCDE Visuals                                           |
//+------------------------------------------------------------------+
void HTF_DrawABCDEVisuals()
{
   color abcdeColor = clrGold;

   if(htfAbcde0_Time > 0 && htfAbcde0 > 0)
   {
      int anchor0 = (htfTrendDirection == 1) ? ANCHOR_LOWER : ANCHOR_UPPER;
      HTF_DrawLabel("HTF_Label0", htfAbcde0_Time, htfAbcde0, "0", abcdeColor, anchor0);
   }
   if(htfAbcdeA_Time > 0 && htfAbcdeA > 0)
   {
      int anchorA = (htfTrendDirection == 1) ? ANCHOR_UPPER : ANCHOR_LOWER;
      HTF_DrawLabel("HTF_LabelA", htfAbcdeA_Time, htfAbcdeA, "A", abcdeColor, anchorA);
   }
   if(htfAbcdeB_Time > 0 && htfAbcdeB > 0)
   {
      int anchorB = (htfTrendDirection == 1) ? ANCHOR_LOWER : ANCHOR_UPPER;
      HTF_DrawLabel("HTF_LabelB", htfAbcdeB_Time, htfAbcdeB, "B", abcdeColor, anchorB);
   }
   if(htfAbcdeC_Time > 0 && htfAbcdeC > 0)
   {
      int anchorC = (htfTrendDirection == 1) ? ANCHOR_UPPER : ANCHOR_LOWER;
      HTF_DrawLabel("HTF_LabelC", htfAbcdeC_Time, htfAbcdeC, "C", abcdeColor, anchorC);
   }
   if(htfAbcdeD_Time > 0 && htfAbcdeD > 0)
   {
      int anchorD = (htfTrendDirection == 1) ? ANCHOR_LOWER : ANCHOR_UPPER;
      HTF_DrawLabel("HTF_LabelD", htfAbcdeD_Time, htfAbcdeD, "D", abcdeColor, anchorD);
   }

   if(htfAbcde0_Time > 0 && htfAbcdeA_Time > 0 && htfAbcde0 > 0 && htfAbcdeA > 0)
      HTF_DrawTrendLine("HTF_Line0A", htfAbcde0_Time, htfAbcde0, htfAbcdeA_Time, htfAbcdeA, abcdeColor);
   if(htfAbcdeA_Time > 0 && htfAbcdeB_Time > 0 && htfAbcdeA > 0 && htfAbcdeB > 0)
      HTF_DrawTrendLine("HTF_LineAB", htfAbcdeA_Time, htfAbcdeA, htfAbcdeB_Time, htfAbcdeB, abcdeColor);
   if(htfAbcdeB_Time > 0 && htfAbcdeC_Time > 0 && htfAbcdeB > 0 && htfAbcdeC > 0)
      HTF_DrawTrendLine("HTF_LineBC", htfAbcdeB_Time, htfAbcdeB, htfAbcdeC_Time, htfAbcdeC, abcdeColor);
   if(htfAbcdeC_Time > 0 && htfAbcdeD_Time > 0 && htfAbcdeC > 0 && htfAbcdeD > 0)
      HTF_DrawTrendLine("HTF_LineCD", htfAbcdeC_Time, htfAbcdeC, htfAbcdeD_Time, htfAbcdeD, abcdeColor);

   if(htfAbcdeD_Time > 0)
   {
      datetime eTime = iTime(_Symbol, HTF_Period, 1);
      double ePrice = iClose(_Symbol, HTF_Period, 1);
      int anchorE = (htfTrendDirection == 1) ? ANCHOR_UPPER : ANCHOR_LOWER;
      HTF_DrawLabel("HTF_LabelE", eTime, ePrice, "E", abcdeColor, anchorE);
      if(htfAbcdeD > 0)
         HTF_DrawTrendLine("HTF_LineDE", htfAbcdeD_Time, htfAbcdeD, eTime, ePrice, abcdeColor);
   }
}

//+------------------------------------------------------------------+
//| Draw HTF Trend Label (top of chart)                              |
//+------------------------------------------------------------------+
void DrawHTFTrendLabel()
{
   string labelName = "HTF_Trend_Label";
   ObjectDelete(0, labelName);

   string text = "HTF (" + EnumToString(HTF_Period) + "): ";
   color col = clrGray;

   if(htfTrendDirection == 1) { text += "BULLISH"; col = clrLimeGreen; }
   else if(htfTrendDirection == -1) { text += "BEARISH"; col = clrCrimson; }
   else { text += "SIDEWAYS"; col = clrYellow; }

   datetime t = iTime(_Symbol, PERIOD_CURRENT, 0);
   double p = iHigh(_Symbol, PERIOD_CURRENT, 0);

   ObjectCreate(0, labelName, OBJ_TEXT, 0, t, p);
   ObjectSetString(0, labelName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, col);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 11);
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw HTF Mother Candle Box                                       |
//+------------------------------------------------------------------+
void HTF_DrawMotherCandleBox(datetime candleTime, double topPrice, double bottomPrice, string labelText)
{
   if(candleTime <= 0 || topPrice <= 0 || bottomPrice <= 0) return;
   
   if(topPrice < bottomPrice)
   {
      double temp = topPrice;
      topPrice = bottomPrice;
      bottomPrice = temp;
   }
   
   int periodSeconds = PeriodSeconds(HTF_Period);
   datetime startTime = candleTime;
   datetime endTime = candleTime + periodSeconds;
   
   ObjectDelete(0, "HTF_MotherCandle_Box");
   ObjectDelete(0, "HTF_MotherCandle_Label");
   
   ObjectCreate(0, "HTF_MotherCandle_Box", OBJ_RECTANGLE, 0, startTime, topPrice, endTime, bottomPrice);
   ObjectSetInteger(0, "HTF_MotherCandle_Box", OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, "HTF_MotherCandle_Box", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "HTF_MotherCandle_Box", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "HTF_MotherCandle_Box", OBJPROP_FILL, true);
   ObjectSetInteger(0, "HTF_MotherCandle_Box", OBJPROP_BACK, false);
   ObjectSetInteger(0, "HTF_MotherCandle_Box", OBJPROP_SELECTABLE, false);
   
   ObjectCreate(0, "HTF_MotherCandle_Label", OBJ_TEXT, 0, startTime, topPrice);
   ObjectSetString(0, "HTF_MotherCandle_Label", OBJPROP_TEXT, labelText);
   ObjectSetInteger(0, "HTF_MotherCandle_Label", OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, "HTF_MotherCandle_Label", OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, "HTF_MotherCandle_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "HTF_MotherCandle_Label", OBJPROP_ANCHOR, ANCHOR_LOWER);
}

// Update HTF_DeleteAllVisuals to include these
// Add these lines inside HTF_DeleteAllVisuals:
// ObjectDelete(0, "HTF_MotherCandle_Box");
// ObjectDelete(0, "HTF_MotherCandle_Label");

#endif // HTF_DRAWING_MQH
//+------------------------------------------------------------------+