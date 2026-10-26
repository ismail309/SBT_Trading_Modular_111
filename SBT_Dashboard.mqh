//+------------------------------------------------------------------+
//|                                              SBT_Dashboard.mqh   |
//+------------------------------------------------------------------+
#ifndef SBT_DASHBOARD_MQH
#define SBT_DASHBOARD_MQH

#include "SBT_State.mqh"

void UpdateDashboard()
{
   int startX = 20;
   int startY = 70;
   int lineHeight = 40;
   int fontSize = 10;
   string font = "Consolas";

   // 8 Rows now
   string rowLabels[8] = {
      "LTF Trend",
      "HTF Trend",
      "LTF Retracement",
      "HTF ChoCh Level",
      "LTF ChoCh Level",
      "HTF Filter",
      "HTF Last Switch",
      "HTF Switch Time"
   };

   string ltfTrendStr = (trendDirection == 1) ? "BULLISH" : (trendDirection == -1 ? "BEARISH" : "SIDEWAYS");
   string htfTrendStr = (htfTrendDirection == 1) ? "BULLISH" : (htfTrendDirection == -1 ? "BEARISH" : "SIDEWAYS");
   string ltfRetStr = retracementStarted ? "YES" : "NO";
   string htfChochStr = (htfCurrentChochLevel > 0) ? DoubleToString(htfCurrentChochLevel, _Digits) : "-";
   string ltfChochStr = (currentChoChLevel > 0) ? DoubleToString(currentChoChLevel, _Digits) : "-";
   string filterStr = UseHTFTrendFilter ? "ON (" + EnumToString(HTF_Period) + ")" : "OFF";
   string switchReason = htfLastSwitchReason;
   string switchTime = (htfLastSwitchTime > 0) ? TimeToString(htfLastSwitchTime, TIME_DATE|TIME_MINUTES) : "-";

   color ltfCol = (trendDirection == 1) ? clrLimeGreen : (trendDirection == -1 ? clrCrimson : clrYellow);
   color htfCol = (htfTrendDirection == 1) ? clrLimeGreen : (htfTrendDirection == -1 ? clrCrimson : clrYellow);
   color retCol = retracementStarted ? clrGold : clrGray;
   color filterCol = UseHTFTrendFilter ? clrLimeGreen : clrGray;
   color switchCol = (switchReason == "ABCDE 5-Wave") ? clrOrange : (switchReason == "HTF ChoCh/MSS" ? clrMagenta : clrGray);

   string values[8] = { ltfTrendStr, htfTrendStr, ltfRetStr, htfChochStr, ltfChochStr, filterStr, switchReason, switchTime };
   color valueColors[8] = { ltfCol, htfCol, retCol, clrAqua, clrAqua, filterCol, switchCol, clrLightGray };

   // Draw Header
   string headerName = "DASH_Header";
   ObjectDelete(0, headerName);
   ObjectCreate(0, headerName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, headerName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, headerName, OBJPROP_XDISTANCE, startX);
   ObjectSetInteger(0, headerName, OBJPROP_YDISTANCE, startY);
   ObjectSetString(0, headerName, OBJPROP_TEXT, "SBT TRADING - DASHBOARD");
   ObjectSetString(0, headerName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, headerName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, headerName, OBJPROP_COLOR, clrGold);
   ObjectSetInteger(0, headerName, OBJPROP_BACK, false);
   ObjectSetInteger(0, headerName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, headerName, OBJPROP_HIDDEN, true);

   // Draw Rows
   for(int i = 0; i < 8; i++)
   {
      string labelName = "DASH_Label_" + IntegerToString(i);
      string valueName = "DASH_Value_" + IntegerToString(i);
      int y = startY + 30 + (i * lineHeight);

      ObjectDelete(0, labelName);
      ObjectCreate(0, labelName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, labelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_XDISTANCE, startX);
      ObjectSetInteger(0, labelName, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, labelName, OBJPROP_TEXT, rowLabels[i] + ":");
      ObjectSetString(0, labelName, OBJPROP_FONT, font);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, clrLightGray);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, labelName, OBJPROP_HIDDEN, true);

      ObjectDelete(0, valueName);
      ObjectCreate(0, valueName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, valueName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, valueName, OBJPROP_XDISTANCE, startX + 300);
      ObjectSetInteger(0, valueName, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, valueName, OBJPROP_TEXT, values[i]);
      ObjectSetString(0, valueName, OBJPROP_FONT, "Consolas Bold");
      ObjectSetInteger(0, valueName, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, valueName, OBJPROP_COLOR, valueColors[i]);
      ObjectSetInteger(0, valueName, OBJPROP_BACK, false);
      ObjectSetInteger(0, valueName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, valueName, OBJPROP_HIDDEN, true);
   }
}

void DeleteDashboard()
{
   ObjectDelete(0, "DASH_Header");
   for(int i = 0; i < 8; i++) // Now 8 rows
   {
      ObjectDelete(0, "DASH_Label_" + IntegerToString(i));
      ObjectDelete(0, "DASH_Value_" + IntegerToString(i));
   }
}

#endif // SBT_DASHBOARD_MQH