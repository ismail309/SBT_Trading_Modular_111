//+------------------------------------------------------------------+
//|                                               SBT_Position.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Position management: partial profit at Level 3 + breakeven.     |
//+------------------------------------------------------------------+
#ifndef SBT_POSITION_MQH
#define SBT_POSITION_MQH

#include "SBT_Entry_Models.mqh"

//+------------------------------------------------------------------+
//| Check Partial Profit - DISABLED                                  |
//+------------------------------------------------------------------+
void CheckPartialProfit()
{
   return; // Partial profits removed per request
}

//+------------------------------------------------------------------+
//| Update Position Management (Move SL to BE at 1:1 RR)             |
//+------------------------------------------------------------------+
void UpdatePositionManagement()
{
   if(!positionOpen) return;
   if(!UseBreakeven) return;
   if(mainPositionTicket == 0) return;
   if(!PositionSelectByTicket(mainPositionTicket)) return;
   if(PositionGetString(POSITION_SYMBOL) != _Symbol) return;
   if(PositionGetInteger(POSITION_MAGIC) != ea_magic) return;

   long posType = PositionGetInteger(POSITION_TYPE);
   double currentPrice = SymbolInfoDouble(_Symbol, posType == POSITION_TYPE_BUY ? SYMBOL_BID : SYMBOL_ASK);
   double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double currentSL = PositionGetDouble(POSITION_SL);
   double currentTP = PositionGetDouble(POSITION_TP);

   // Use the ACTUAL SL from the position to calculate risk. 
   // If currentSL is 0 (unlikely), fallback to mainPositionSL.
   double riskSL = (currentSL > 0) ? currentSL : mainPositionSL;
   double initialRisk = MathAbs(entryPrice - riskSL);

   // Avoid division by zero
   if(initialRisk <= 0) return;

   // Calculate Current RR
   double rrCurrent = 0;
   if(posType == POSITION_TYPE_BUY)
      rrCurrent = (currentPrice - entryPrice) / initialRisk;
   else if(posType == POSITION_TYPE_SELL)
      rrCurrent = (entryPrice - currentPrice) / initialRisk;

   // If we reach 1:1 RR, and SL is not yet at BE
   if(rrCurrent >= BreakevenTriggerRR)
   {
      bool slNeedsUpdate = false;
      if(posType == POSITION_TYPE_BUY && currentSL < entryPrice) slNeedsUpdate = true;
      if(posType == POSITION_TYPE_SELL && currentSL > entryPrice) slNeedsUpdate = true;

      if(slNeedsUpdate)
      {
         MqlTradeRequest request = {};
         MqlTradeResult result = {};

         request.action = TRADE_ACTION_SLTP;
         request.position = mainPositionTicket;
         request.symbol = _Symbol;
         request.sl = entryPrice;
         request.tp = currentTP;
         request.magic = ea_magic;
         
         if(!OrderSend(request, result))
            Print("❌ Failed to move SL to BE. Error: ", result.retcode);
         else
            Print("✅ SL moved to Breakeven at price: ", entryPrice);
      }
   }
}

#endif // SBT_POSITION_MQH
//+------------------------------------------------------------------+