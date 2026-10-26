//+------------------------------------------------------------------+
//|                                                 SBT_Common.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Shared: colors, inputs, structs, enums, magic, trade object     |
//+------------------------------------------------------------------+
#ifndef SBT_COMMON_MQH
#define SBT_COMMON_MQH

#property strict

#include <Trade/Trade.mqh>

//--- Trade object (defined once, here)
CTrade trade;

//--- Colors
#define COLOR_LEVEL1 clrDodgerBlue
#define COLOR_LEVEL2 clrRed
#define COLOR_LEVEL3 clrGoldenrod
#define COLOR_MB     clrBlueViolet
#define COLOR_DZ     clrLimeGreen
#define COLOR_SZ     clrCrimson
#define COLOR_SL     clrRed
#define COLOR_ABCDE  clrGold

//--- Input Parameters for HTF
input bool   UseHTFTrendFilter               = true;              // Enable HTF Trend Alignment
input ENUM_TIMEFRAMES HTF_Period             = PERIOD_H4;         // Higher Timeframe (H1/H4/D1)
input bool   ShowHTFTrendLabel               = true;              // Show HTF trend on chart
input int    HTF_MaxScanBars                 = 100;               // HTF max bars to scan for trend (default 100)

//--- Input Parameters
input int    TrendDirection                = 1;      // 1 = Bullish, -1 = Bearish
input int    SLBufferPips                  = 5;      // Stop Loss buffer in pips (Demand Candle)
input int    SLFVGBufferPips               = 10;     // Stop Loss buffer in pips for FVG
input int    MaxCandlesToScan              = 30;     // Maximum candles to scan for PD arrays
input int    BackwardCandlesToScanForMB    = 10;     // Number of candles to scan backward for MB
input double RiskPercent                   = 1.0;    // Risk percentage of equity
input double RiskRewardRatio               = 3.0;    // Risk to Reward ratio (1:3 for full TP)
input bool   UseBreakeven                  = true;   // Enable Breakeven after 1:1
input double BreakevenTriggerRR            = 1.0;    // Move to breakeven at 1:1
input int    MagicNumber                   = 123456; // EA Magic Number for position identification
input int    MaxConcurrentPositions        = 5;      // Maximum positions allowed at once

input int    ZoneLeftBufferCandles         = 2;      // Candles to the LEFT of anchor (buffer)

input bool   ShowABCDEVisuals              = true;   // Draw ABCDE labels + trend lines

input int MinZoneCandlesLeft               = 5;     // Minimum candles to the LEFT of zone
input int MinZoneCandlesRight              = 5;     // Minimum candles to the RIGHT of zone
input string BreakevenComment              = "Closed by BE"; // Comment when Breakeven is hit

//--- PD Array Structure
struct PDArray
{
   string   type;
   double   top;
   double   bottom;
   datetime startTime;
   datetime endTime;
   bool     isValid;
};

#endif // SBT_COMMON_MQH
//+------------------------------------------------------------------+