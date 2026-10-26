//+------------------------------------------------------------------+
//|                                           SBT_Entry_Models.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Entry execution + SBT-1, SBT-2, and SBT-3 entry models.         |
//+------------------------------------------------------------------+
#ifndef SBT_ENTRY_MODELS_MQH
#define SBT_ENTRY_MODELS_MQH

#include "SBT_Zones.mqh"
#include "HTF_Trend.mqh"

//+------------------------------------------------------------------+
//| Helper: Check if a candle is a Doji (Based on 5-candle scan avg) |
//+------------------------------------------------------------------+
bool IsDoji(int shift, int bosBar)
{
   double open  = iOpen(_Symbol, PERIOD_CURRENT, shift);
   double close = iClose(_Symbol, PERIOD_CURRENT, shift);
   double bodySize = MathAbs(open - close);
   
   double totalBody = 0;
   int count = 0;
   for(int i = bosBar + 1; i <= bosBar + 5; i++)
   {
      double cOpen = iOpen(_Symbol, PERIOD_CURRENT, i);
      double cClose = iClose(_Symbol, PERIOD_CURRENT, i);
      totalBody += MathAbs(cOpen - cClose);
      count++;
   }
   
   if(count == 0) return false;
   double avgBody = totalBody / count;
   
   if(avgBody > 0)
      return (bodySize < (avgBody * 0.3));
      
   double pipSize = _Point;
   if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
   return (bodySize <= (2.0 * pipSize));
}

//+------------------------------------------------------------------+
//| Helper: Check overlap between MB zone and a target candle        |
//+------------------------------------------------------------------+
bool IsCandleOverlappingMB(int shift, double mbTop, double mbBottom, bool useWick)
{
   double open  = iOpen(_Symbol, PERIOD_CURRENT, shift);
   double close = iClose(_Symbol, PERIOD_CURRENT, shift);
   double high  = iHigh(_Symbol, PERIOD_CURRENT, shift);
   double low   = iLow(_Symbol, PERIOD_CURRENT, shift);
   
   double candleTop, candleBottom;
   
   if(useWick)
   {
      candleTop = high;
      candleBottom = low;
   }
   else
   {
      candleTop = MathMax(open, close);
      candleBottom = MathMin(open, close);
   }
   
   return (candleTop >= mbBottom && candleBottom <= mbTop);
}

//+------------------------------------------------------------------+
//| Helper: Check if an FVG overlaps the MB zone                     |
//+------------------------------------------------------------------+
bool IsFVGOverlappingMB(int i, double mbTop, double mbBottom, bool isBullishSetup, double &fvgExtreme, double &outFvgTop, double &outFvgBottom)
{
   double high_i_2 = iHigh(_Symbol, PERIOD_CURRENT, i + 2);
   double low_i    = iLow(_Symbol, PERIOD_CURRENT, i);
   double high_i   = iHigh(_Symbol, PERIOD_CURRENT, i);
   double low_i_2  = iLow(_Symbol, PERIOD_CURRENT, i + 2);

   if(isBullishSetup)
   {
      if(low_i > high_i_2)
      {
         double fvgTop = low_i;
         double fvgBottom = high_i_2;
         
         if(fvgTop >= mbBottom && fvgBottom <= mbTop)
         {
            fvgExtreme = fvgBottom;
            outFvgTop = fvgTop;
            outFvgBottom = fvgBottom;
            return true;
         }
      }
   }
   else
   {
      if(high_i < low_i_2)
      {
         double fvgTop = low_i_2;
         double fvgBottom = high_i;
         
         if(fvgTop >= mbBottom && fvgBottom <= mbTop)
         {
            fvgExtreme = fvgTop;
            outFvgTop = fvgTop;
            outFvgBottom = fvgBottom;
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Order execution                                                  |
//+------------------------------------------------------------------+
void OpenBuyOrder(double price, double sl, double tp, double lotSize, string comment = "")
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_BUY;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.type_filling = ORDER_FILLING_FOK;
   request.magic = ea_magic;
   request.comment = comment;

   if(!OrderSend(request, result))
   {
      Print("❌ BUY ORDER FAILED: ", result.retcode);
      return;
   }

   positionOpen = true;
   mainPositionTicket = result.order;
   mainPositionEntry = price;
   mainPositionSL = sl;
   mainPositionTP = tp;
   mainPositionLot = lotSize;
   partialProfitTaken = false;
   currentPositionCount = GetCurrentPositionCount();
}

void OpenSellOrder(double price, double sl, double tp, double lotSize, string comment = "")
{
   MqlTradeRequest request = {};
   MqlTradeResult result = {};

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lotSize;
   request.type = ORDER_TYPE_SELL;
   request.price = price;
   request.sl = sl;
   request.tp = tp;
   request.deviation = 10;
   request.type_filling = ORDER_FILLING_FOK;
   request.magic = ea_magic;
   request.comment = comment;

   if(!OrderSend(request, result))
   {
      Print("❌ SELL ORDER FAILED: ", result.retcode);
      return;
   }

   positionOpen = true;
   mainPositionTicket = result.order;
   mainPositionEntry = price;
   mainPositionSL = sl;
   mainPositionTP = tp;
   mainPositionLot = lotSize;
   partialProfitTaken = false;
   currentPositionCount = GetCurrentPositionCount();
}

//+------------------------------------------------------------------+
//| Check SBT-1 Entry (50% DZ/SZ Retracement - LIVE TICK)            |
//+------------------------------------------------------------------+
void CheckSBT1Entry()
{
   EnsureSLPriceIsSet();

   if(currentSLPrice <= 0) return;
   if(!CanOpenNewPosition()) return;
   
   // NEW: HTF ALIGNMENT FILTER
   if(!IsTradeAlignedWithHTF(trendDirection)) return;

   if(trendDirection == 1)  // BULLISH (DZ)
   {
      if(!dzConfirmed) return;
      if(level1BreakTime <= 0) return;
      if(dzMitigated) return;

      double midPrice = (dzTopPrice + dzBottomPrice) / 2.0;
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double prevClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      
      if(prevClose > midPrice && ask <= midPrice)
      {
         static datetime lastEntryBar = 0;
         if(iTime(_Symbol, PERIOD_CURRENT, 0) == lastEntryBar) return;
         
         double entryPrice = ask;
         double slPrice = currentSLPrice;

         if(slPrice >= entryPrice) return;

         double risk = entryPrice - slPrice;
         double tpPrice = entryPrice + (risk * RiskRewardRatio);
         double lotSize = CalculateLotSize(slPrice, entryPrice);
         
         if(lotSize > 0)
         {
            Print("✅ SBT-1 BULLISH ENTRY (50% DZ) at ASK=", ask);
            OpenBuyOrder(entryPrice, slPrice, tpPrice, lotSize, "SBT-1 BUY");

            dzMitigated = true;
            dzRightEdgeTime = 0;
            if(ObjectFind(0, "DemandZone_Label") >= 0)
               ObjectSetString(0, "DemandZone_Label", OBJPROP_TEXT, "DZ (mitigated)");
               
            lastEntryBar = iTime(_Symbol, PERIOD_CURRENT, 0);
         }
      }
   }
   else  // BEARISH (SZ)
   {
      if(!szConfirmed) return;
      if(level1BreakTime <= 0) return;
      if(szMitigated) return;

      double midPrice = (szTopPrice + szBottomPrice) / 2.0;
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double prevClose = iClose(_Symbol, PERIOD_CURRENT, 1);
      
      if(prevClose < midPrice && bid >= midPrice)
      {
         static datetime lastEntryBar = 0;
         if(iTime(_Symbol, PERIOD_CURRENT, 0) == lastEntryBar) return;
         
         double entryPrice = bid;
         double slPrice = currentSLPrice;

         if(slPrice <= entryPrice) return;

         double risk = slPrice - entryPrice;
         if(risk <= 0) return;

         double tpPrice = entryPrice - (risk * RiskRewardRatio);
         double lotSize = CalculateLotSize(slPrice, entryPrice);
         
         if(lotSize > 0)
         {
            Print("✅ SBT-1 BEARISH ENTRY (50% SZ) at BID=", bid);
            OpenSellOrder(entryPrice, slPrice, tpPrice, lotSize, "SBT-1 SELL");

            szMitigated = true;
            szRightEdgeTime = 0;
            if(ObjectFind(0, "SupplyZone_Label") >= 0)
               ObjectSetString(0, "SupplyZone_Label", OBJPROP_TEXT, "SZ (mitigated)");
               
            lastEntryBar = iTime(_Symbol, PERIOD_CURRENT, 0);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check SBT-2 Entry (MB Overlap with Demand/Supply Candle)         |
//+------------------------------------------------------------------+
void CheckSBT2Entry()
{
   if(mbTopPrice <= 0 || mbBottomPrice <= 0) return;
   if(mbMitigated) return;
   if(mbEntryCount >= 2) return;
   if(level1BreakTime <= 0) return;
   
   // NEW: HTF ALIGNMENT FILTER
   if(!IsTradeAlignedWithHTF(trendDirection)) return;

   if(mbPositionTicket > 0)
   {
      if(PositionSelectByTicket(mbPositionTicket)) return;
      else
      {
         HistorySelectByPosition(mbPositionTicket);
         int totalDeals = HistoryDealsTotal();
         bool hitTP = false;
         for(int i = 0; i < totalDeals; i++)
         {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(dealTicket, DEAL_REASON) == DEAL_REASON_TP) { hitTP = true; break; }
         }
         if(hitTP)
         {
            mbMitigated = true; mbRightEdgeTime = 0; mbEntryCount = 2; mbPositionTicket = 0;
            if(ObjectFind(0, "MB_Label") >= 0) ObjectSetString(0, "MB_Label", OBJPROP_TEXT, "MB (mitigated)");
            return;
         }
         mbPositionTicket = 0;
      }
   }

   // --- RUN SCAN ONLY ONCE PER BOS ---
   static datetime lastScannedBosTime = 0;
   if(level1BreakTime != lastScannedBosTime)
   {
      lastScannedBosTime = level1BreakTime;
      
      int bosBar = iBarShift(_Symbol, PERIOD_CURRENT, level1BreakTime);
      if(bosBar > 0)
      {
         int targetCandleBar = -1;
         double targetCandleExtreme = 0;
         
         // Determine the limit of the backward scan
         int limitBar = 0;
         if(trendDirection == 1 && dzDrawTime > 0)
            limitBar = iBarShift(_Symbol, PERIOD_CURRENT, dzDrawTime);
         else if(trendDirection == -1 && szDrawTime > 0)
            limitBar = iBarShift(_Symbol, PERIOD_CURRENT, szDrawTime);
            
         // If limitBar is invalid, default to 50 bars max scan
         if(limitBar <= 0) limitBar = bosBar + 50; 

         Print("🔍 SBT-2 SCAN START | MB Top: ", mbTopPrice, " | MB Bot: ", mbBottomPrice, " | BoS Bar: ", bosBar);

         if(trendDirection == 1) // BULLISH (Demand)
         {
            for(int i = bosBar + 1; i <= bosBar + 5; i++)
            {
               // Stop if we reach the Demand Zone candle
               if(i >= limitBar) break;

               double cOpen  = iOpen(_Symbol, PERIOD_CURRENT, i);
               double cClose = iClose(_Symbol, PERIOD_CURRENT, i);
               
               bool isDoj = IsDoji(i, bosBar);
               bool isBearishDoji = isDoj && (cClose <= cOpen);
               bool isBrsh = IsBearish(i);
               
               bool isOv = IsCandleOverlappingMB(i, mbTopPrice, mbBottomPrice, isDoj);
               
               Print("   Bar ", i, " | O:", cOpen, " C:", cClose, 
                     " H:", iHigh(_Symbol, PERIOD_CURRENT, i), " L:", iLow(_Symbol, PERIOD_CURRENT, i),
                     " | Bearish:", isBrsh, " Doji:", isDoj, " BearishDoji:", isBearishDoji, " Overlap:", isOv);

               if((isBrsh || isBearishDoji) && isOv)
               {
                  targetCandleBar = i; 
                  targetCandleExtreme = iLow(_Symbol, PERIOD_CURRENT, i); 
                  break;
               }
            }
         }
         else // BEARISH (Supply)
         {
            for(int i = bosBar + 1; i <= bosBar + 5; i++)
            {
               // Stop if we reach the Supply Zone candle
               if(i >= limitBar) break;

               double cOpen  = iOpen(_Symbol, PERIOD_CURRENT, i);
               double cClose = iClose(_Symbol, PERIOD_CURRENT, i);
               
               bool isDoj = IsDoji(i, bosBar);
               bool isBullishDoji = isDoj && (cClose >= cOpen);
               bool isBull = IsBullish(i);
               
               bool isOv = IsCandleOverlappingMB(i, mbTopPrice, mbBottomPrice, isDoj);
               
               Print("   Bar ", i, " | O:", cOpen, " C:", cClose, 
                     " H:", iHigh(_Symbol, PERIOD_CURRENT, i), " L:", iLow(_Symbol, PERIOD_CURRENT, i),
                     " | Bullish:", isBull, " Doji:", isDoj, " BullishDoji:", isBullishDoji, " Overlap:", isOv);

               if((isBull || isBullishDoji) && isOv)
               {
                  targetCandleBar = i; 
                  targetCandleExtreme = iHigh(_Symbol, PERIOD_CURRENT, i); 
                  break;
               }
            }
         }
         
         if(targetCandleBar < 0) 
         {
            Print("❌ SBT-2: No matching Demand/Supply candle found in the 5 candles before BoS.");
            sbt2_saved_extreme = 0;
         }
         else
         {
            Print("✅ SBT-2: Found matching candle at Bar ", targetCandleBar);

            datetime overlapTime = iTime(_Symbol, PERIOD_CURRENT, targetCandleBar);
            double overlapHigh = iHigh(_Symbol, PERIOD_CURRENT, targetCandleBar);
            double overlapLow = iLow(_Symbol, PERIOD_CURRENT, targetCandleBar);
            
            string overlapLabel = (trendDirection == 1) ? "Demand Candle Overlap" : "Supply Candle Overlap";
            DrawSBT2OverlapMarker(overlapTime, overlapHigh, overlapLow, overlapLabel);
            
            sbt2_saved_extreme = targetCandleExtreme; 
         }
      }
   }
   
   // --- ENTRY LOGIC (Runs every tick) ---
   if(sbt2_saved_extreme == 0) return;

   double prevOpen  = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double prevClose = iClose(_Symbol, PERIOD_CURRENT, 1);
   double prevHigh  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double prevLow   = iLow(_Symbol, PERIOD_CURRENT, 1);
   
   bool touchedZone = (prevHigh >= mbBottomPrice && prevLow <= mbTopPrice);
   if(!touchedZone) return;

   if(trendDirection == 1) // BULLISH
   {
      if(prevOpen > mbTopPrice && prevClose >= mbBottomPrice)
      {
         static datetime lastEntryBar = 0;
         if(iTime(_Symbol, PERIOD_CURRENT, 1) == lastEntryBar) return;
         
         double pipSize = _Point;
         if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
         double slPrice = sbt2_saved_extreme - (SLBufferPips * pipSize);
         
         double entryPrice = iOpen(_Symbol, PERIOD_CURRENT, 0);
         if(slPrice >= entryPrice) return;
         
         double risk = entryPrice - slPrice;
         double tpPrice = entryPrice + (risk * RiskRewardRatio);
         double lotSize = CalculateLotSize(slPrice, entryPrice);
         
         if(lotSize > 0)
         {
            Print("✅ SBT-2 BULLISH ENTRY (Attempt ", mbEntryCount + 1, "/2)!");
            OpenBuyOrder(entryPrice, slPrice, tpPrice, lotSize, "SBT-2 BUY");
            mbEntryCount++; mbPositionTicket = mainPositionTicket; lastEntryBar = iTime(_Symbol, PERIOD_CURRENT, 1);
            mbActiveEntryModel = 2;
         }
      }
   }
   else // BEARISH
   {
      if(prevOpen < mbBottomPrice && prevClose <= mbTopPrice)
      {
         static datetime lastEntryBar = 0;
         if(iTime(_Symbol, PERIOD_CURRENT, 1) == lastEntryBar) return;
         
         double pipSize = _Point;
         if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
         double slPrice = sbt2_saved_extreme + (SLBufferPips * pipSize);
         
         double entryPrice = iOpen(_Symbol, PERIOD_CURRENT, 0);
         if(slPrice <= entryPrice) return;
         
         double risk = slPrice - entryPrice;
         if(risk <= 0) return;
         
         double tpPrice = entryPrice - (risk * RiskRewardRatio);
         double lotSize = CalculateLotSize(slPrice, entryPrice);
         
         if(lotSize > 0)
         {
            Print("✅ SBT-2 BEARISH ENTRY (Attempt ", mbEntryCount + 1, "/2)!");
            OpenSellOrder(entryPrice, slPrice, tpPrice, lotSize, "SBT-2 SELL");
            mbEntryCount++; mbPositionTicket = mainPositionTicket; lastEntryBar = iTime(_Symbol, PERIOD_CURRENT, 1);
            mbActiveEntryModel = 2;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check SBT-3 Entry (MB Overlap with FVG)                          |
//+------------------------------------------------------------------+
void CheckSBT3Entry()
{   
   if(mbTopPrice <= 0 || mbBottomPrice <= 0) return;
   if(mbMitigated) return;
   if(mbEntryCount >= 2) return;
   if(level1BreakTime <= 0) return;
   
   // NEW: HTF ALIGNMENT FILTER
   if(!IsTradeAlignedWithHTF(trendDirection)) return;

   // Handle existing position / TP check
   if(mbPositionTicket > 0)
   {
      if(PositionSelectByTicket(mbPositionTicket)) return;
      else
      {
         HistorySelectByPosition(mbPositionTicket);
         int totalDeals = HistoryDealsTotal();
         bool hitTP = false;
         for(int i = 0; i < totalDeals; i++)
         {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(dealTicket, DEAL_REASON) == DEAL_REASON_TP) { hitTP = true; break; }
         }
         if(hitTP)
         {
            mbMitigated = true; mbRightEdgeTime = 0; mbEntryCount = 2; mbPositionTicket = 0;
            if(ObjectFind(0, "MB_Label") >= 0) ObjectSetString(0, "MB_Label", OBJPROP_TEXT, "MB (mitigated)");
            return;
         }
         mbPositionTicket = 0;
      }
   }

   // --- SBT-3 SCAN (Runs every tick until FVG is found) ---
   if(!mbFvgFound)
   {
      int bosBar = iBarShift(_Symbol, PERIOD_CURRENT, level1BreakTime);
      if(bosBar <= 0) return;

      // How many bars since BoS (we only want to scan for the first 5 bars after BoS)
      int barsSinceBos = bosBar - 0; 
      
      if(barsSinceBos <= 5)
      {
         // Find MB start and end
         int mbStartBar = iBarShift(_Symbol, PERIOD_CURRENT, mbDrawTime);
         int mbEndBar   = iBarShift(_Symbol, PERIOD_CURRENT, mbConfirmationTime);
         
         // 5 candles above and below MB
         int searchMax = MathMax(mbStartBar, mbEndBar) + 5; 
         int searchMin = MathMin(mbStartBar, mbEndBar) - 5; 
         
         int searchStart = MathMin(bosBar, searchMax); 
         int searchEnd   = MathMax(1, searchMin); 

         // Scan backwards from the newest closed candle
         for(int i = searchEnd; i <= searchStart; i++)
         {
            if(IsFVGOverlappingMB(i, mbTopPrice, mbBottomPrice, (trendDirection == 1), mbFvgSlLevel, mbFvgTop, mbFvgBottom))
            {
               mbFvgFound = true;
               DrawFVGRectangle(i, (trendDirection == 1), mbFvgTop, mbFvgBottom);
               Print("📊 SBT-3 FVG FOUND at bar ", i, " | Top: ", mbFvgTop, " | Bottom: ", mbFvgBottom);
               break;
            }
         }
      }
   }
   
   // --- ENTRY LOGIC (Runs every tick once FVG is found) ---
   if(!mbFvgFound) return; 

   double prevOpen  = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double prevClose = iClose(_Symbol, PERIOD_CURRENT, 1);
   double prevHigh  = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double prevLow   = iLow(_Symbol, PERIOD_CURRENT, 1);
   
   bool touchedZone = (prevHigh >= mbBottomPrice && prevLow <= mbTopPrice);
   if(!touchedZone) return; 

   if(trendDirection == 1) // BULLISH
   {
      if(prevOpen > mbTopPrice && prevClose >= mbBottomPrice)
      {
         static datetime lastEntryBar = 0;
         if(iTime(_Symbol, PERIOD_CURRENT, 1) == lastEntryBar) return;
         
         double pipSize = _Point;
         if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
         double slPrice = mbFvgSlLevel - (SLFVGBufferPips * pipSize);
         
         double entryPrice = iOpen(_Symbol, PERIOD_CURRENT, 0);
         if(slPrice >= entryPrice) return;
         
         double risk = entryPrice - slPrice;
         double tpPrice = entryPrice + (risk * RiskRewardRatio);
         double lotSize = CalculateLotSize(slPrice, entryPrice);
         
         if(lotSize > 0)
         {
            Print("✅ SBT-3 BULLISH ENTRY (Attempt ", mbEntryCount + 1, "/2)!");
            OpenBuyOrder(entryPrice, slPrice, tpPrice, lotSize, "SBT-3 BUY");
            mbEntryCount++; mbPositionTicket = mainPositionTicket; lastEntryBar = iTime(_Symbol, PERIOD_CURRENT, 1);
            mbActiveEntryModel = 3;
            mbActiveFvgExtreme = mbFvgSlLevel;
         }
      }
   }
   else // BEARISH
   {
      if(prevOpen < mbBottomPrice && prevClose <= mbTopPrice)
      {
         static datetime lastEntryBar = 0;
         if(iTime(_Symbol, PERIOD_CURRENT, 1) == lastEntryBar) return;
         
         double pipSize = _Point;
         if(_Digits == 5 || _Digits == 3) pipSize = _Point * 10;
         double slPrice = mbFvgSlLevel + (SLFVGBufferPips * pipSize);
         
         double entryPrice = iOpen(_Symbol, PERIOD_CURRENT, 0);
         if(slPrice <= entryPrice) return;
         
         double risk = slPrice - entryPrice;
         if(risk <= 0) return;
         
         double tpPrice = entryPrice - (risk * RiskRewardRatio);
         double lotSize = CalculateLotSize(slPrice, entryPrice);
         
         if(lotSize > 0)
         {
            Print("✅ SBT-3 BEARISH ENTRY (Attempt ", mbEntryCount + 1, "/2)!");
            OpenSellOrder(entryPrice, slPrice, tpPrice, lotSize, "SBT-3 SELL");
            mbEntryCount++; mbPositionTicket = mainPositionTicket; lastEntryBar = iTime(_Symbol, PERIOD_CURRENT, 1);
            mbActiveEntryModel = 3;
            mbActiveFvgExtreme = mbFvgSlLevel;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Monitor MB Trade (Invalidation for SBT-2 and SBT-3)              |
//+------------------------------------------------------------------+
void MonitorMBTrade()
{
   if(mbPositionTicket == 0) return;
   if(!PositionSelectByTicket(mbPositionTicket)) return;

   double currentClose = iClose(_Symbol, PERIOD_CURRENT, 1);
   
   if(trendDirection == 1) // Bullish
   {
      if(currentClose < mbBottomPrice)
      {
         Print("⚠️ MB TRADE INVALIDATED (Model ", mbActiveEntryModel, "): Closing trade.");
         trade.PositionClose(mbPositionTicket);
         mbPositionTicket = 0;
         
         if(mbEntryCount >= 2)
         {
            mbMitigated = true;
            mbRightEdgeTime = 0;
            if(ObjectFind(0, "MB_Label") >= 0)
               ObjectSetString(0, "MB_Label", OBJPROP_TEXT, "MB (mitigated)");
         }
      }
   }
   else // Bearish
   {
      if(currentClose > mbTopPrice)
      {
         Print("⚠️ MB TRADE INVALIDATED (Model ", mbActiveEntryModel, "): Closing trade.");
         trade.PositionClose(mbPositionTicket);
         mbPositionTicket = 0;
         
         if(mbEntryCount >= 2)
         {
            mbMitigated = true;
            mbRightEdgeTime = 0;
            if(ObjectFind(0, "MB_Label") >= 0)
               ObjectSetString(0, "MB_Label", OBJPROP_TEXT, "MB (mitigated)");
         }
      }
   }
}

#endif // SBT_ENTRY_MODELS_MQH
//+------------------------------------------------------------------+