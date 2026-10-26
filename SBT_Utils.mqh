//+------------------------------------------------------------------+
//|                                                  SBT_Utils.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Candle helpers, price helpers, lot sizing, position counting.   |
//+------------------------------------------------------------------+
#ifndef SBT_UTILS_MQH
#define SBT_UTILS_MQH

#include "SBT_State.mqh"

//+------------------------------------------------------------------+
//| Candle type helpers                                              |
//+------------------------------------------------------------------+
bool IsBearish(int shift)
{
   return (iClose(_Symbol, PERIOD_CURRENT, shift) < iOpen(_Symbol, PERIOD_CURRENT, shift));
}

bool IsBullish(int shift)
{
   return (iClose(_Symbol, PERIOD_CURRENT, shift) > iOpen(_Symbol, PERIOD_CURRENT, shift));
}

bool IsBreak(double currentPrice, double referencePrice)
{
   if(trendDirection == 1)
      return (currentPrice > referencePrice);
   else
      return (currentPrice < referencePrice);
}

double GetInvalidationPrice()
{
   if(trendDirection == 1)
      return referenceHighForInvalidation;
   else
      return referenceLowForInvalidation;
}

double NormalizePrice(double price)
{
   return NormalizeDouble(price, _Digits);
}

//+------------------------------------------------------------------+
//| Range helpers (used by ABCDE + zones)                            |
//+------------------------------------------------------------------+
double FindLowestLowBetween(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, startTime);
   int endBar   = iBarShift(_Symbol, PERIOD_CURRENT, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double lowestLow = DBL_MAX;
   for(int i = from; i >= to; i--)
   {
      double l = iLow(_Symbol, PERIOD_CURRENT, i);
      if(l < lowestLow) lowestLow = l;
   }
   return (lowestLow == DBL_MAX) ? 0 : lowestLow;
}

double FindHighestHighBetween(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, startTime);
   int endBar   = iBarShift(_Symbol, PERIOD_CURRENT, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double highestHigh = -DBL_MAX;
   for(int i = from; i >= to; i--)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      if(h > highestHigh) highestHigh = h;
   }
   return (highestHigh == -DBL_MAX) ? 0 : highestHigh;
}

datetime FindTimeOfLowestLow(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, startTime);
   int endBar   = iBarShift(_Symbol, PERIOD_CURRENT, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double lowestLow = DBL_MAX;
   int    lowestBar = -1;
   for(int i = from; i >= to; i--)
   {
      double l = iLow(_Symbol, PERIOD_CURRENT, i);
      if(l < lowestLow) { lowestLow = l; lowestBar = i; }
   }
   if(lowestBar < 0) return 0;
   return iTime(_Symbol, PERIOD_CURRENT, lowestBar);
}

datetime FindTimeOfHighestHigh(datetime startTime, datetime endTime)
{
   if(startTime <= 0 || endTime <= 0) return 0;
   int startBar = iBarShift(_Symbol, PERIOD_CURRENT, startTime);
   int endBar   = iBarShift(_Symbol, PERIOD_CURRENT, endTime);
   if(startBar < 0 || endBar < 0) return 0;
   int from = MathMax(startBar, endBar);
   int to   = MathMin(startBar, endBar);
   double highestHigh = -DBL_MAX;
   int    highestBar = -1;
   for(int i = from; i >= to; i--)
   {
      double h = iHigh(_Symbol, PERIOD_CURRENT, i);
      if(h > highestHigh) { highestHigh = h; highestBar = i; }
   }
   if(highestBar < 0) return 0;
   return iTime(_Symbol, PERIOD_CURRENT, highestBar);
}

//+------------------------------------------------------------------+
//| Lot sizing                                                       |
//+------------------------------------------------------------------+
int VolumeDigitsFromStep(double step)
{
   if(step <= 0) return 2;
   int d = 0;
   while(step < 1.0 - 1e-12 && d < 10) { step *= 10.0; d++; }
   return d;
}

double RoundLotsToStep(double rawLots)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0) step = 0.01;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lots = MathFloor(rawLots / step) * step;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;
   int digs = VolumeDigitsFromStep(step);
   return NormalizeDouble(lots, digs);
}

double CalculateLotSize(double slPrice, double entryPrice)
{
   double slDistance = MathAbs(entryPrice - slPrice);
   if(slDistance <= 0) return 0;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * RiskPercent / 100.0;

   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(point <= 0 || tickValue <= 0) return 0;

   double valuePerLot = (slDistance / point) * tickValue;
   if(valuePerLot <= 0) return 0;

   double rawLots = riskMoney / valuePerLot;
   return RoundLotsToStep(rawLots);
}

//+------------------------------------------------------------------+
//| Position counting                                                |
//+------------------------------------------------------------------+
int GetCurrentPositionCount()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         {
            if(PositionGetInteger(POSITION_MAGIC) == ea_magic)
               count++;
         }
      }
   }
   return count;
}

bool CanOpenNewPosition()
{
   currentPositionCount = GetCurrentPositionCount();
   return (currentPositionCount < MaxConcurrentPositions);
}


//+------------------------------------------------------------------+
//| Check if LTF trade direction is aligned with HTF                 |
//+------------------------------------------------------------------+
bool IsTradeAlignedWithHTF(int ltfTradeDirection)
{
   if(!UseHTFTrendFilter) return true;
   if(htfTrendDirection == 0) return true; // HTF sideways → LTF governs
   return (htfTrendDirection == ltfTradeDirection);
}

#endif // SBT_UTILS_MQH
//+------------------------------------------------------------------+