//+------------------------------------------------------------------+
//|                                                SBT_Drawing.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  All chart drawing functions: SL, Levels 1/2/3, ChoCh, ABCDE     |
//|  BoS, zones (MB/DZ/SZ/BBB/QML/DB/SBB/DT), ChoCh confirmation.    |
//|  Includes dynamic right-edge extension and minimum time width.   |
//+------------------------------------------------------------------+
#ifndef SBT_DRAWING_MQH
#define SBT_DRAWING_MQH

#include "SBT_Utils.mqh"

//+------------------------------------------------------------------+
//| Forward declarations (defined in SBT_Zones.mqh)                  |
//+------------------------------------------------------------------+
void FindClosestPDArray(double level2Price, datetime level2Time, datetime referenceTime);
void FindClosestPDArraySZ(double level2Price, datetime level2Time, datetime referenceTime);
void EnsureSLPriceIsSet();

//+------------------------------------------------------------------+
//| Helper: Ensure zone has minimum visual time width                |
//+------------------------------------------------------------------+
void EnsureMinimumZoneTimeWidth(datetime &startTime, datetime &endTime)
{
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   
   // Calculate current width in candles
   int timeDiff = (int)(endTime - startTime);
   int candles = timeDiff / periodSeconds;
   
   // If it's too narrow, expand it
   if(candles < MinZoneCandlesLeft + MinZoneCandlesRight)
   {
      startTime -= (periodSeconds * MinZoneCandlesLeft);
      endTime   += (periodSeconds * MinZoneCandlesRight);
   }
}

//+------------------------------------------------------------------+
//| Draw Stop Loss Line                                              |
//+------------------------------------------------------------------+
void DrawStopLossLine(double price, datetime referenceTime)
{
   if(price <= 0 || referenceTime <= 0) return;

   currentSLPrice = price;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime startTime = referenceTime - (periodSeconds * 10);
   datetime endTime = referenceTime + (periodSeconds * 20);

   ObjectDelete(0, "SL_Line");
   ObjectDelete(0, "SL_Label");

   ObjectCreate(0, "SL_Line", OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSetInteger(0, "SL_Line", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SL_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "SL_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "SL_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "SL_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice;
   if(trendDirection == 1)
   {
      labelPrice = price - (15 * _Point);
      if(_Digits == 5 || _Digits == 3) labelPrice = price - (15 * _Point * 10);
   }
   else
   {
      labelPrice = price + (15 * _Point);
      if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);
   }

   ObjectCreate(0, "SL_Label", OBJ_TEXT, 0, startTime + periodSeconds, labelPrice);
   ObjectSetString(0, "SL_Label", OBJPROP_TEXT, "SL");
   ObjectSetInteger(0, "SL_Label", OBJPROP_COLOR, clrRed);
   ObjectSetInteger(0, "SL_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "SL_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "SL_Label", OBJPROP_ANCHOR, trendDirection == 1 ? ANCHOR_UPPER : ANCHOR_LOWER);
}

//+------------------------------------------------------------------+
//| Draw Level 1 line                                                |
//+------------------------------------------------------------------+
void DrawLevel1Line(double price, datetime time)
{
   level1DrawTime = time;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime startTime = time - (periodSeconds * 10);
   datetime endTime = time + (periodSeconds * 20);

   ObjectCreate(0, "Level1_Line", OBJ_TREND, 0, startTime, price, endTime, price);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "Level1_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice = price + (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);

   ObjectCreate(0, "Level1_Label", OBJ_TEXT, 0, startTime + periodSeconds, labelPrice);
   ObjectSetString(0, "Level1_Label", OBJPROP_TEXT, "1. BoS");
   ObjectSetInteger(0, "Level1_Label", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "Level1_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "Level1_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "Level1_Label", OBJPROP_ANCHOR, ANCHOR_LOWER);

   currentLevel3Price = 0;
   level3DrawTime = 0;
}

//+------------------------------------------------------------------+
//| Draw Level 3 line                                                |
//+------------------------------------------------------------------+
void DrawLevel3Line(double price, datetime retracementTime, datetime bosBreakTime)
{
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, retracementTime);
   int endBar = iBarShift(_Symbol, PERIOD_CURRENT, bosBreakTime);
   if(startBar < 0 || endBar < 0) return;

   datetime startCandleTime = iTime(_Symbol, PERIOD_CURRENT, startBar);
   datetime endCandleTime = iTime(_Symbol, PERIOD_CURRENT, endBar);

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = startCandleTime - (periodSeconds * 10);
   datetime lineEndTime = endCandleTime;

   ObjectCreate(0, "Level3_Line", OBJ_TREND, 0, lineStartTime, price, lineEndTime, price);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_COLOR, COLOR_LEVEL3);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "Level3_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice = price + (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price + (15 * _Point * 10);

   ObjectCreate(0, "Level3_Label", OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, "Level3_Label", OBJPROP_TEXT, "3");
   ObjectSetInteger(0, "Level3_Label", OBJPROP_COLOR, COLOR_LEVEL3);
   ObjectSetInteger(0, "Level3_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "Level3_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "Level3_Label", OBJPROP_ANCHOR, ANCHOR_LOWER);

   currentLevel3Price = price;
   level3DrawTime = retracementTime;
}

//+------------------------------------------------------------------+
//| Draw Level 2 line                                                |
//+------------------------------------------------------------------+
void DrawLevel2Line(double level2Price, datetime level2Time, datetime bosBreakTime, int &barNumber)
{
   int endBar = iBarShift(_Symbol, PERIOD_CURRENT, bosBreakTime);
   if(endBar < 0) return;

   datetime endCandleTime = iTime(_Symbol, PERIOD_CURRENT, endBar);
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = level2Time - (periodSeconds * 10);
   datetime lineEndTime = endCandleTime;

   currentChoChLevel = level2Price;
   barNumber = iBarShift(_Symbol, PERIOD_CURRENT, level2Time);

   ObjectCreate(0, "ChoCh_Line", OBJ_TREND, 0, lineStartTime, level2Price, lineEndTime, level2Price);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_COLOR, COLOR_LEVEL2);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "ChoCh_Line", OBJPROP_RAY_LEFT, false);

   double labelPrice = level2Price - (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = level2Price - (15 * _Point * 10);

   ObjectCreate(0, "ChoCh_Label", OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, "ChoCh_Label", OBJPROP_TEXT, "2");
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_COLOR, COLOR_LEVEL2);
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "ChoCh_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "ChoCh_Label", OBJPROP_ANCHOR, ANCHOR_UPPER);
}

//+------------------------------------------------------------------+
//| Draw ChoCh Confirmation                                          |
//+------------------------------------------------------------------+
void DrawChoChConfirmation(double price, datetime time)
{
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = time - (periodSeconds * 10);
   double labelPrice = price - (25 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = price - (25 * _Point * 10);

   string labelName = "ChoCh_Confirm_Label_" + IntegerToString((long)time);

   ObjectCreate(0, labelName, OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "ChoCh/MsS");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrMagenta);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_UPPER);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, false);
   ObjectSetInteger(0, labelName, OBJPROP_BACK, false);

   Print("📊 ChoCh/MsS Label drawn at ", price, " Time: ", TimeToString(time));
}

//+------------------------------------------------------------------+
//| Draw ABCDE BoS line at Wave C                                    |
//+------------------------------------------------------------------+
void DrawABCDEBoSLine(double bosPrice, datetime bosTime)
{
   if(bosPrice <= 0 || bosTime <= 0) return;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime lineStartTime = bosTime - (periodSeconds * 10);
   datetime lineEndTime   = bosTime + (periodSeconds * 20);

   ObjectDelete(0, "ABCDE_BoS_Line");
   ObjectDelete(0, "ABCDE_BoS_Label");

   ObjectCreate(0, "ABCDE_BoS_Line", OBJ_TREND, 0, lineStartTime, bosPrice, lineEndTime, bosPrice);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_BACK, false);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_RAY_LEFT, false);
   ObjectSetInteger(0, "ABCDE_BoS_Line", OBJPROP_SELECTABLE, false);

   double labelPrice = (trendDirection == 1) ? bosPrice + (15 * _Point) : bosPrice - (15 * _Point);
   if(_Digits == 5 || _Digits == 3) labelPrice = (trendDirection == 1) ? bosPrice + (15 * _Point * 10) : bosPrice - (15 * _Point * 10);

   ObjectCreate(0, "ABCDE_BoS_Label", OBJ_TEXT, 0, lineStartTime + periodSeconds, labelPrice);
   ObjectSetString(0, "ABCDE_BoS_Label", OBJPROP_TEXT, "1. BoS (C)");
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_COLOR, COLOR_LEVEL1);
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, "ABCDE_BoS_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_ANCHOR, trendDirection == 1 ? ANCHOR_LOWER : ANCHOR_UPPER);
   ObjectSetInteger(0, "ABCDE_BoS_Label", OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw Mitigation Block (MB)                                       |
//+------------------------------------------------------------------+
void DrawMitigationBlock(datetime startTime, double bottomPrice, double topPrice, datetime referenceTime, datetime confirmationTime = 0)
{
   Print("========================================");
   Print("📊 DRAW MB - START");
   Print("   startTime: ", startTime > 0 ? TimeToString(startTime) : "NOT SET");
   Print("   bottomPrice: ", bottomPrice > 0 ? DoubleToString(bottomPrice, _Digits) : "NOT SET");
   Print("   topPrice: ", topPrice > 0 ? DoubleToString(topPrice, _Digits) : "NOT SET");
   Print("   referenceTime: ", referenceTime > 0 ? TimeToString(referenceTime) : "NOT SET");
   Print("========================================");

   if(startTime <= 0 || bottomPrice <= 0 || topPrice <= 0 || referenceTime <= 0) return;
   if(topPrice <= bottomPrice) return;

   mbTopPrice = topPrice;
   mbBottomPrice = bottomPrice;
   mbDrawTime = startTime;
   mbMitigated = false;
   mbConfirmationTime = (confirmationTime > 0) ? confirmationTime : referenceTime;
   
    // Reset SBT-2 state
   mbEntryCount = 0;
   mbWaitingReentry = false;
   mbPositionTicket = 0;
   mbEntryAnchorTime = 0;
   
   // NEW: Reset SBT-2 extreme
   sbt2_saved_extreme = 0; 
   
   // Reset SBT-3 state
   mbFvgFound = false;
   mbFvgSlLevel = 0;
   mbFvgTop = 0;
   mbFvgBottom = 0;
   mbActiveEntryModel = 0;
   mbActiveFvgExtreme = 0;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   
   datetime lineStartTime = startTime;
   datetime lineEndTime   = referenceTime;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "MB_Rectangle");
   ObjectDelete(0, "MB_Label");
   // Delete old SBT-3 FVG when a new MB is drawn
   ObjectDelete(0, "SBT3_FVG_Rectangle");
   ObjectDelete(0, "SBT3_FVG_Label");
   
   ObjectDelete(0, "SBT2_Overlap_Box"); //
   ObjectDelete(0, "SBT2_Overlap_Label"); //

   ObjectCreate(0, "MB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_COLOR, COLOR_MB);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "MB_Rectangle", OBJPROP_HIDDEN, false);

   mbRightEdgeTime = lineEndTime;

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "MB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "MB_Label", OBJPROP_TEXT, "MB");
   ObjectSetInteger(0, "MB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "MB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "MB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "MB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   Print("✅ MB DRAWN: Bottom=", bottomPrice, " Top=", topPrice, 
         " From=", TimeToString(lineStartTime), " To=", TimeToString(lineEndTime));
}

//+------------------------------------------------------------------+
//| Draw FVG Overlap Zone (Wick-to-Wick, grows with MB)              |
//+------------------------------------------------------------------+
void DrawFVGRectangle(int fvgBar, bool isBullish, double fvgTop, double fvgBottom)
{
   // The FVG is formed by 3 candles: i+2, i+1, and i.
   // fvgBar is the index 'i' (the newest candle).
   // Start time is the oldest candle (i+2)
   datetime startTime = iTime(_Symbol, PERIOD_CURRENT, fvgBar + 2); 
   
   // Right edge: Match the current MB right edge (or current time if not set)
   datetime endTime = (mbRightEdgeTime > 0) ? mbRightEdgeTime : iTime(_Symbol, PERIOD_CURRENT, 1);
   
   string objName = "SBT3_FVG_Rectangle";
   ObjectDelete(0, objName);
   
   // fvgTop and fvgBottom are the exact wick prices calculated in IsFVGOverlappingMB
   ObjectCreate(0, objName, OBJ_RECTANGLE, 0, startTime, fvgTop, endTime, fvgBottom);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, isBullish ? clrLightGreen : clrLightPink);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_HIDDEN, false);
   
   string labelName = "SBT3_FVG_Label";
   ObjectDelete(0, labelName);
   
   double midPrice = (fvgTop + fvgBottom) / 2.0;
   datetime midTime = startTime + (endTime - startTime) / 2;
   
   ObjectCreate(0, labelName, OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, "FVG");
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, isBullish ? clrGreen : clrRed);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_CENTER);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw Demand Zone (DZ)                                            |
//+------------------------------------------------------------------+
void DrawDemandZone(datetime candleTime, double openPrice, double highPrice, double lowPrice, double level2Price, datetime referenceTime, datetime bosBreakTime)
{
   if(candleTime <= 0 || openPrice <= 0 || level2Price <= 0) return;
   if(openPrice <= level2Price) return;

   dzTopPrice = openPrice;
   dzBottomPrice = level2Price;
   dzDrawTime = candleTime;
   dzCandleHigh = highPrice;
   dzCandleLow = lowPrice;
   dzConfirmed = false;
   dzMitigated = false;
   dzConfirmationBar = 0;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneLeftBufferCandles;
   if(leftCandles < 0) leftCandles = 2;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime   = referenceTime + periodSeconds;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "DemandZone_Rectangle");
   ObjectDelete(0, "DemandZone_Label");

   ObjectCreate(0, "DemandZone_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, openPrice, lineEndTime, level2Price);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_COLOR, COLOR_DZ);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_HIDDEN, false);

   dzRightEdgeTime = lineEndTime;

   double midPrice = (openPrice + level2Price) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "DemandZone_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "DemandZone_Label", OBJPROP_TEXT, "DZ");
   ObjectSetInteger(0, "DemandZone_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "DemandZone_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "DemandZone_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "DemandZone_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   FindClosestPDArray(level2Price, candleTime, referenceTime);
   EnsureSLPriceIsSet();
   Print("DZ DRAWN: Top=", openPrice, " Bottom=", level2Price);
}

//+------------------------------------------------------------------+
//| Draw Supply Zone (SZ)                                            |
//+------------------------------------------------------------------+
void DrawSupplyZone(datetime candleTime, double openPrice, double highPrice, double lowPrice, double level2Price, datetime referenceTime, datetime bosBreakTime)
{
   if(candleTime <= 0 || openPrice <= 0 || level2Price <= 0) return;
   if(openPrice >= level2Price) return;

   szTopPrice = level2Price;
   szBottomPrice = openPrice;
   szDrawTime = candleTime;
   szCandleLow = lowPrice;
   szCandleHigh = highPrice;
   szConfirmed = false;
   szMitigated = false;
   szConfirmationBar = 0;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneLeftBufferCandles;
   if(leftCandles < 0) leftCandles = 2;

   datetime lineStartTime = referenceTime - (periodSeconds * leftCandles);
   datetime lineEndTime   = referenceTime + periodSeconds;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "SupplyZone_Rectangle");
   ObjectDelete(0, "SupplyZone_Label");

   ObjectCreate(0, "SupplyZone_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, level2Price, lineEndTime, openPrice);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_COLOR, COLOR_SZ);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_HIDDEN, false);

   szRightEdgeTime = lineEndTime;

   double midPrice = (level2Price + openPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "SupplyZone_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "SupplyZone_Label", OBJPROP_TEXT, "SZ");
   ObjectSetInteger(0, "SupplyZone_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "SupplyZone_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "SupplyZone_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "SupplyZone_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   FindClosestPDArraySZ(level2Price, candleTime, referenceTime);
   EnsureSLPriceIsSet();
   Print("SZ DRAWN: Top=", level2Price, " Bottom=", openPrice);
}

//+------------------------------------------------------------------+
//| Draw Bullish Breaker Block (BBB)                                 |
//+------------------------------------------------------------------+
void DrawBBB(double topPrice, double bottomPrice, datetime anchorTime, datetime confirmationTime)
{
   if(topPrice <= 0 || bottomPrice <= 0 || anchorTime <= 0 || confirmationTime <= 0) return;
   if(topPrice <= bottomPrice) return;

   bbbTopPrice = topPrice;
   bbbBottomPrice = bottomPrice;
   bbbDrawTime = anchorTime;
   bbbConfirmationTime = confirmationTime;
   bbbConfirmed = true;
   bbbMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneLeftBufferCandles;
   if(leftCandles < 0) leftCandles = 2;

   datetime lineStartTime = anchorTime - (periodSeconds * leftCandles);
   datetime lineEndTime   = confirmationTime + periodSeconds;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "BBB_Rectangle");
   ObjectDelete(0, "BBB_Label");

   ObjectCreate(0, "BBB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_COLOR, clrDodgerBlue);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_HIDDEN, false);

   bbbRightEdgeTime = lineEndTime;

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "BBB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "BBB_Label", OBJPROP_TEXT, "BBB");
   ObjectSetInteger(0, "BBB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "BBB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "BBB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "BBB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   Print("BBB DRAWN: Top=", topPrice, " Bottom=", bottomPrice,
         " anchor=", TimeToString(anchorTime), " confirmation=", TimeToString(confirmationTime));
}

//+------------------------------------------------------------------+
//| Draw QML                                                         |
//+------------------------------------------------------------------+
void DrawQML(double topPrice, double bottomPrice, datetime anchorTime, datetime confirmationTime)
{
   if(topPrice <= 0 || bottomPrice <= 0 || anchorTime <= 0 || confirmationTime <= 0) return;
   if(topPrice <= bottomPrice) return;

   qmlTopPrice = topPrice;
   qmlBottomPrice = bottomPrice;
   qmlDrawTime = anchorTime;
   qmlConfirmationTime = confirmationTime;
   qmlConfirmed = true;
   qmlMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneLeftBufferCandles;
   if(leftCandles < 0) leftCandles = 2;

   datetime lineStartTime = anchorTime - (periodSeconds * leftCandles);
   datetime lineEndTime   = confirmationTime + periodSeconds;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "QML_Rectangle");
   ObjectDelete(0, "QML_Label");

   ObjectCreate(0, "QML_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_COLOR, clrBlueViolet);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "QML_Rectangle", OBJPROP_HIDDEN, false);

   qmlRightEdgeTime = lineEndTime;

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "QML_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "QML_Label", OBJPROP_TEXT, "QML");
   ObjectSetInteger(0, "QML_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "QML_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "QML_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "QML_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   Print("QML DRAWN: Top=", topPrice, " Bottom=", bottomPrice,
         " anchor=", TimeToString(anchorTime), " confirmation=", TimeToString(confirmationTime));
}

//+------------------------------------------------------------------+
//| Draw Double Bottom (DB)                                          |
//+------------------------------------------------------------------+
void DrawDB(datetime candleTime, double openPrice, double closePrice, double level3Price, datetime confirmationTime)
{
   if(candleTime <= 0 || openPrice <= 0 || closePrice <= 0 || level3Price <= 0 || confirmationTime <= 0) return;
   if(openPrice <= level3Price) return;

   dbCandleOpen = openPrice;
   dbCandleClose = closePrice;
   dbTopPrice = openPrice;
   dbBottomPrice = level3Price;
   dbDrawTime = candleTime;
   dbConfirmed = true;
   dbMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneLeftBufferCandles;
   if(leftCandles < 0) leftCandles = 2;

   datetime lineStartTime = candleTime - (periodSeconds * leftCandles);
   datetime lineEndTime   = confirmationTime + periodSeconds;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "DB_Rectangle");
   ObjectDelete(0, "DB_Label");

   ObjectCreate(0, "DB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, openPrice, lineEndTime, level3Price);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_COLOR, clrLimeGreen);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "DB_Rectangle", OBJPROP_HIDDEN, false);

   dbRightEdgeTime = lineEndTime;

   double midPrice = (openPrice + level3Price) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "DB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "DB_Label", OBJPROP_TEXT, "DB");
   ObjectSetInteger(0, "DB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "DB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "DB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "DB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);
}

//+------------------------------------------------------------------+
//| Draw SBB (Supply Breaker Block)                                  |
//+------------------------------------------------------------------+
void DrawSBB(double topPrice, double bottomPrice, datetime anchorTime, datetime confirmationTime)
{
   if(topPrice <= 0 || bottomPrice <= 0 || anchorTime <= 0 || confirmationTime <= 0) return;
   if(topPrice <= bottomPrice) return;

   sbbTopPrice = topPrice;
   sbbBottomPrice = bottomPrice;
   sbbDrawTime = anchorTime;
   sbbConfirmationTime = confirmationTime;
   sbbConfirmed = true;
   sbbMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneLeftBufferCandles;
   if(leftCandles < 0) leftCandles = 2;

   datetime lineStartTime = anchorTime - (periodSeconds * leftCandles);
   datetime lineEndTime   = confirmationTime + periodSeconds;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "SBB_Rectangle");
   ObjectDelete(0, "SBB_Label");

   ObjectCreate(0, "SBB_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, topPrice, lineEndTime, bottomPrice);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_COLOR, clrDarkOrange);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_HIDDEN, false);

   sbbRightEdgeTime = lineEndTime;

   double midPrice = (topPrice + bottomPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "SBB_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "SBB_Label", OBJPROP_TEXT, "SBB");
   ObjectSetInteger(0, "SBB_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "SBB_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "SBB_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "SBB_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);

   Print("SBB DRAWN: Top=", topPrice, " Bottom=", bottomPrice,
         " anchor=", TimeToString(anchorTime), " confirmation=", TimeToString(confirmationTime));
}

//+------------------------------------------------------------------+
//| Draw Double Top (DT)                                             |
//+------------------------------------------------------------------+
void DrawDT(datetime candleTime, double openPrice, double closePrice, double level3Price, datetime confirmationTime)
{
   if(candleTime <= 0 || openPrice <= 0 || closePrice <= 0 || level3Price <= 0 || confirmationTime <= 0) return;
   if(openPrice >= level3Price) return;

   dtCandleOpen = openPrice;
   dtCandleClose = closePrice;
   dtTopPrice = level3Price;
   dtBottomPrice = openPrice;
   dtDrawTime = candleTime;
   dtConfirmed = true;
   dtMitigated = false;

   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   int leftCandles = ZoneLeftBufferCandles;
   if(leftCandles < 0) leftCandles = 2;

   datetime lineStartTime = candleTime - (periodSeconds * leftCandles);
   datetime lineEndTime   = confirmationTime + periodSeconds;

   EnsureMinimumZoneTimeWidth(lineStartTime, lineEndTime);

   ObjectDelete(0, "DT_Rectangle");
   ObjectDelete(0, "DT_Label");

   ObjectCreate(0, "DT_Rectangle", OBJ_RECTANGLE, 0, lineStartTime, level3Price, lineEndTime, openPrice);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_COLOR, clrCrimson);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_FILL, true);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_BACK, true);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "DT_Rectangle", OBJPROP_HIDDEN, false);

   dtRightEdgeTime = lineEndTime;

   double midPrice = (level3Price + openPrice) / 2.0;
   datetime midTime = lineStartTime + (lineEndTime - lineStartTime) / 2;

   ObjectCreate(0, "DT_Label", OBJ_TEXT, 0, midTime, midPrice);
   ObjectSetString(0, "DT_Label", OBJPROP_TEXT, "DT");
   ObjectSetInteger(0, "DT_Label", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "DT_Label", OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, "DT_Label", OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, "DT_Label", OBJPROP_ANCHOR, ANCHOR_CENTER);
}

//+------------------------------------------------------------------+
//| Extend live zones' right edge to last closed bar                 |
//| Called only on new-bar events (per design Q4).                   |
//+------------------------------------------------------------------+
void ExtendZoneRightEdges()
{
   datetime newRight = iTime(_Symbol, PERIOD_CURRENT, 1);
   if(newRight <= 0) return;

   // --- DZ ---
   if(dzRightEdgeTime > 0 && !dzMitigated && ObjectFind(0, "DemandZone_Rectangle") >= 0)
   {
      if(newRight > dzRightEdgeTime)
      {
         ObjectSetInteger(0, "DemandZone_Rectangle", OBJPROP_TIME, 1, newRight);
         dzRightEdgeTime = newRight;
      }
   }

   // --- SZ ---
   if(szRightEdgeTime > 0 && !szMitigated && ObjectFind(0, "SupplyZone_Rectangle") >= 0)
   {
      if(newRight > szRightEdgeTime)
      {
         ObjectSetInteger(0, "SupplyZone_Rectangle", OBJPROP_TIME, 1, newRight);
         szRightEdgeTime = newRight;
      }
   }

   // --- MB ---
   if(mbRightEdgeTime > 0 && !mbMitigated && ObjectFind(0, "MB_Rectangle") >= 0)
   {
      if(newRight > mbRightEdgeTime)
      {
         ObjectSetInteger(0, "MB_Rectangle", OBJPROP_TIME, 1, newRight);
         mbRightEdgeTime = newRight;
         
         // Extend the FVG right edge as well (if it exists)
         if(mbFvgFound && ObjectFind(0, "SBT3_FVG_Rectangle") >= 0)
         {
            ObjectSetInteger(0, "SBT3_FVG_Rectangle", OBJPROP_TIME, 1, newRight);
            
            // Also update the label position
            if(ObjectFind(0, "SBT3_FVG_Label") >= 0)
            {
               double fvgMid = (mbFvgTop + mbFvgBottom) / 2.0;
               ObjectSetInteger(0, "SBT3_FVG_Label", OBJPROP_TIME, 0, newRight); // Move to new right edge
               ObjectSetDouble(0, "SBT3_FVG_Label", OBJPROP_PRICE, 0, fvgMid);
            }
         }
      }
   }

   // --- BBB ---
   if(bbbRightEdgeTime > 0 && !bbbMitigated && ObjectFind(0, "BBB_Rectangle") >= 0)
   {
      if(newRight > bbbRightEdgeTime)
      {
         ObjectSetInteger(0, "BBB_Rectangle", OBJPROP_TIME, 1, newRight);
         bbbRightEdgeTime = newRight;
      }
   }

   // --- QML ---
   if(qmlRightEdgeTime > 0 && !qmlMitigated && ObjectFind(0, "QML_Rectangle") >= 0)
   {
      if(newRight > qmlRightEdgeTime)
      {
         ObjectSetInteger(0, "QML_Rectangle", OBJPROP_TIME, 1, newRight);
         qmlRightEdgeTime = newRight;
      }
   }

   // --- DB ---
   if(dbRightEdgeTime > 0 && !dbMitigated && ObjectFind(0, "DB_Rectangle") >= 0)
   {
      if(newRight > dbRightEdgeTime)
      {
         ObjectSetInteger(0, "DB_Rectangle", OBJPROP_TIME, 1, newRight);
         dbRightEdgeTime = newRight;
      }
   }

   // --- SBB ---
   if(sbbRightEdgeTime > 0 && !sbbMitigated && ObjectFind(0, "SBB_Rectangle") >= 0)
   {
      if(newRight > sbbRightEdgeTime)
      {
         ObjectSetInteger(0, "SBB_Rectangle", OBJPROP_TIME, 1, newRight);
         sbbRightEdgeTime = newRight;
      }
   }

   // --- DT ---
   if(dtRightEdgeTime > 0 && !dtMitigated && ObjectFind(0, "DT_Rectangle") >= 0)
   {
      if(newRight > dtRightEdgeTime)
      {
         ObjectSetInteger(0, "DT_Rectangle", OBJPROP_TIME, 1, newRight);
         dtRightEdgeTime = newRight;
      }
   }
}

//+------------------------------------------------------------------+
//| Draw SBT-2 Overlapping Candle Marker                             |
//+------------------------------------------------------------------+
void DrawSBT2OverlapMarker(datetime candleTime, double topPrice, double bottomPrice, string labelText)
{
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime startTime = candleTime;
   datetime endTime = candleTime + periodSeconds;

   ObjectDelete(0, "SBT2_Overlap_Box");
   ObjectDelete(0, "SBT2_Overlap_Label");

   ObjectCreate(0, "SBT2_Overlap_Box", OBJ_RECTANGLE, 0, startTime, topPrice, endTime, bottomPrice);
   ObjectSetInteger(0, "SBT2_Overlap_Box", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, "SBT2_Overlap_Box", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "SBT2_Overlap_Box", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "SBT2_Overlap_Box", OBJPROP_FILL, false);
   ObjectSetInteger(0, "SBT2_Overlap_Box", OBJPROP_BACK, false);
   ObjectSetInteger(0, "SBT2_Overlap_Box", OBJPROP_SELECTABLE, false);

   ObjectCreate(0, "SBT2_Overlap_Label", OBJ_TEXT, 0, startTime + (periodSeconds/2), topPrice);
   ObjectSetString(0, "SBT2_Overlap_Label", OBJPROP_TEXT, labelText);
   ObjectSetInteger(0, "SBT2_Overlap_Label", OBJPROP_COLOR, clrYellow);
   ObjectSetInteger(0, "SBT2_Overlap_Label", OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, "SBT2_Overlap_Label", OBJPROP_ANCHOR, ANCHOR_LOWER);
}


void DrawMotherCandleBox(datetime candleTime, double topPrice, double bottomPrice, string labelText)
{
   if(candleTime <= 0 || topPrice <= 0 || bottomPrice <= 0) return;
   
   if(topPrice < bottomPrice)
   {
      double temp = topPrice;
      topPrice = bottomPrice;
      bottomPrice = temp;
   }
   
   int periodSeconds = PeriodSeconds(PERIOD_CURRENT);
   datetime startTime = candleTime;
   datetime endTime = candleTime + periodSeconds;
   
   ObjectDelete(0, "MotherCandle_Box");
   ObjectDelete(0, "MotherCandle_Label");
   
   // Use OBJ_RECTANGLE_LABEL? No, OBJ_RECTANGLE requires chart coordinates.
   bool created = ObjectCreate(0, "MotherCandle_Box", OBJ_RECTANGLE, 0, startTime, topPrice, endTime, bottomPrice);
   
   ObjectSetInteger(0, "MotherCandle_Box", OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, "MotherCandle_Box", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, "MotherCandle_Box", OBJPROP_WIDTH, 3); // Thicker
   ObjectSetInteger(0, "MotherCandle_Box", OBJPROP_FILL, true); // Filled for visibility
   ObjectSetInteger(0, "MotherCandle_Box", OBJPROP_BACK, false);
   
   ObjectCreate(0, "MotherCandle_Label", OBJ_TEXT, 0, startTime, topPrice);
   ObjectSetString(0, "MotherCandle_Label", OBJPROP_TEXT, labelText);
   ObjectSetInteger(0, "MotherCandle_Label", OBJPROP_COLOR, clrOrange);
   ObjectSetInteger(0, "MotherCandle_Label", OBJPROP_FONTSIZE, 10);
   
   Print("🔍 DEBUG: ObjectCreate result: ", created, " | Name: MotherCandle_Box | Time: ", TimeToString(startTime), " | Top: ", topPrice, " | Bottom: ", bottomPrice);
}

#endif // SBT_DRAWING_MQH
//+------------------------------------------------------------------+