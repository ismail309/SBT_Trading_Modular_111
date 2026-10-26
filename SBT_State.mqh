//+------------------------------------------------------------------+
//|                                                  SBT_State.mqh   |
//|                                    Copyright 2026, sbt_trading   |
//|  Single source of truth for all EA global state.                 |
//+------------------------------------------------------------------+
#ifndef SBT_STATE_MQH
#define SBT_STATE_MQH

#include "SBT_Common.mqh"

//=========================================================
// HTF TREND STATE (Full Parallel to LTF)
//=========================================================
int      htfTotalBars                      = 0;
int      htfTrendDirection                 = 0; // 0 = undefined

// HTF Bullish
bool     htfBullishEstablished             = false;
double   htfHighestHighSinceTrendStart     = 0;
datetime htfHighestHighSinceTrendStart_Time = 0;

// HTF Bearish
bool     htfBearishEstablished             = false;
double   htfLowestLowSinceTrendStart       = 0;
datetime htfLowestLowSinceTrendStart_Time  = 0;

// HTF Retracement
bool     htfRetracementStarted             = false;
datetime htfRetracementStartTime           = 0;
int      htfRetracementRuleUsed            = 0;
double   htfReferenceHighForInvalidation   = 0;
double   htfReferenceLowForInvalidation    = 0;

// HTF Mother Candle
bool     htfMotherCandleActive             = false;
double   htfMotherCandleOpen               = 0;
double   htfMotherCandleHigh               = 0;
double   htfMotherCandleLow                = 0;
datetime htfMotherCandleTime               = 0;

// HTF ChoCh
bool     htfChochConfirmed                 = false;
double   htfCurrentChochLevel              = 0;

// HTF Levels
double   htfLevel1Price                    = 0;
datetime htfLevel1BreakTime                = 0;
double   htfLevel2Price                    = 0;
double   htfLevel3Price                    = 0;
datetime htfLevel3DrawTime                 = 0;

// HTF ABCDE
bool     htfAbcdeActive                    = false;
int      htfAbcdeWave                      = 0;
double   htfAbcde0                         = 0;
double   htfAbcdeA                         = 0;
double   htfAbcdeB                         = 0;
double   htfAbcdeC                         = 0;
double   htfAbcdeD                         = 0;
datetime htfAbcde0_Time                    = 0;
datetime htfAbcdeA_Time                    = 0;
datetime htfAbcdeB_Time                    = 0;
datetime htfAbcdeC_Time                    = 0;
datetime htfAbcdeD_Time                    = 0;
int      htfAbcdeRetraceRuleCount          = 0;
bool     htfAbcdeA_BodyBroken              = false;

// HTF Trend Switch Tracking
string   htfLastSwitchReason   = "None";
datetime htfLastSwitchTime     = 0;
string   htfPendingChochOrigin = "Normal"; // "Normal" or "ABCDE 5-Wave"

//=========================================================
// LTF TREND STATE
//=====================================================

//--- Trend & Detection
int      trendDirection                    = 1;
int      totalBars                         = 0;

// Bullish
bool     bullishTrendEstablished           = false;
double   highestHighSinceTrendStart        = 0;
datetime highestHighSinceTrendStart_Time   = 0;
datetime bullishTrendStartTime             = 0;

// Bearish
bool     bearishTrendEstablished           = false;
double   lowestLowSinceTrendStart          = 0;
datetime lowestLowSinceTrendStart_Time     = 0;
datetime bearishTrendStartTime             = 0;

datetime trendStartTimeGlobal              = 0;

//--- Trend Continuation
bool     trendContinuation                 = false;
bool     trendContinuationConfirmed        = false;
datetime trendContinuationTime             = 0;
double   trendContinuationPrice            = 0;

//--- Retracement Detection
bool     retracementStarted                = false;
datetime retracementStartTime              = 0;
int      retracementRuleUsed               = 0;
double   referenceHighForInvalidation      = 0;
double   referenceLowForInvalidation       = 0;

bool     motherCandleActive                = false;
double   motherCandleOpen                  = 0;
double   motherCandleLow                   = 0;
double   motherCandleHigh                  = 0;
datetime motherCandleTime                  = 0;

//--- ChoCh / MSS
bool     chochConfirmed                    = false;
double   currentChoChLevel                 = 0;
int      consecutiveBearishBelowChoCh      = 0;
int      consecutiveBullishAboveChoCh      = 0;

//--- DZ (Bullish)
bool     dzConfirmed                       = false;
bool     dzMitigated                       = false;
double   dzTopPrice                        = 0;
double   dzBottomPrice                     = 0;
double   dzCandleHigh                      = 0;
double   dzCandleLow                       = 0;
datetime dzDrawTime                        = 0;
int      dzConfirmationBar                 = 0;

//--- SZ (Bearish)
bool     szConfirmed                       = false;
bool     szMitigated                       = false;
double   szTopPrice                        = 0;
double   szBottomPrice                     = 0;
double   szCandleLow                       = 0;
double   szCandleHigh                      = 0;
datetime szDrawTime                        = 0;
int      szConfirmationBar                 = 0;

//--- MB (Mitigation Block)
bool     mbMitigated                       = false;
double   mbTopPrice                        = 0;
double   mbBottomPrice                     = 0;
datetime mbDrawTime                        = 0;
datetime mbConfirmationTime                = 0; 

//--- Zone right-edge tracking (dynamic width)
datetime dzRightEdgeTime  = 0;
datetime szRightEdgeTime  = 0;
datetime mbRightEdgeTime  = 0;
datetime bbbRightEdgeTime = 0;
datetime qmlRightEdgeTime = 0;
datetime dbRightEdgeTime  = 0;
datetime dtRightEdgeTime  = 0;
datetime sbbRightEdgeTime = 0;

//--- PD Arrays & SL
PDArray  demandCandle;
PDArray  supplyCandle;
PDArray  fvg;
double   currentSLPrice                    = 0;
datetime slDrawTime                        = 0;

//--- Position & Level Tracking
bool     positionOpen                      = false;
double   currentPositionSL                 = 0;
double   currentPositionTP                 = 0;
double   currentPositionEntry              = 0;
int      currentPositionCount              = 0;
ulong    mainPositionTicket                = 0;
double   mainPositionEntry                 = 0;
double   mainPositionSL                    = 0;
double   mainPositionTP                    = 0;
double   mainPositionLot                   = 0;
bool     partialProfitTaken                = false;

double   currentLevel3Price                = 0;
datetime level3DrawTime                    = 0;
datetime level1DrawTime                    = 0;
datetime level1BreakTime                   = 0;
double   level1BreakPrice                  = 0;

//--- Zone Tracking
// BBB (Bullish Breaker Block) - previously SZ
bool     bbbConfirmed                      = false;
bool     bbbMitigated                      = false;
double   bbbTopPrice                       = 0;
double   bbbBottomPrice                    = 0;
datetime bbbDrawTime                       = 0;
datetime bbbConfirmationTime               = 0;


//--- SBB (Supply Breaker Block) - Bearish MSS
bool     sbbConfirmed                      = false;
bool     sbbMitigated                      = false;
double   sbbTopPrice                       = 0;
double   sbbBottomPrice                    = 0;
datetime sbbDrawTime                       = 0;
datetime sbbConfirmationTime               = 0;

// QML - previously MB
bool     qmlConfirmed                      = false;
bool     qmlMitigated                      = false;
double   qmlTopPrice                       = 0;
double   qmlBottomPrice                    = 0;
datetime qmlDrawTime                       = 0;
datetime qmlConfirmationTime               = 0;

// DB (Double Bottom)
bool     dbConfirmed                       = false;
bool     dbMitigated                       = false;
double   dbTopPrice                        = 0;
double   dbBottomPrice                     = 0;
datetime dbDrawTime                        = 0;
datetime dbConfirmationTime                = 0;
double   dbCandleOpen                      = 0;
double   dbCandleClose                     = 0;

//--- DT (Double Top) - Bearish MSS
bool     dtConfirmed                       = false;
bool     dtMitigated                       = false;
double   dtTopPrice                        = 0;
double   dtBottomPrice                     = 0;
datetime dtDrawTime                        = 0;
datetime dtConfirmationTime                = 0;
double   dtCandleOpen                      = 0;
double   dtCandleClose                     = 0;

int      ea_magic                          = 123456;

//--- ABCDE (Elliott Wave)
bool     abcdeActive                       = false;
int      abcdeWave                         = 0;   // 0=idle, 1=A set, 3=B/C set, 5=E confirmed
double   abcde0                            = 0;
double   abcdeA                            = 0;
double   abcdeB                            = 0;
double   abcdeC                            = 0;
double   abcdeD                            = 0;
datetime abcde0_Time                       = 0;
datetime abcdeA_Time                       = 0;
datetime abcdeB_Time                       = 0;
datetime abcdeC_Time                       = 0;
datetime abcdeD_Time                       = 0;
int      abcdeRetraceRuleCount             = 0;
bool     abcdeA_BodyBroken                 = false;
bool     abcdeChochFiredThisBar            = false; // priority flag vs normal 2-candle ChoCh

//--- SBT-2 and SBT-3 Entry Tracking
int      mbEntryCount                      = 0;
bool     mbWaitingReentry                  = false;
ulong    mbPositionTicket                  = 0;
datetime mbEntryAnchorTime                 = 0; // Tracks the specific overlap candle for SL
double   mbActiveFvgExtreme                = 0;
int      mbActiveEntryModel                = 0;

//--- SBT-3 FVG Tracking
bool     mbFvgFound                        = false;
double   mbFvgTop                          = 0;
double   mbFvgBottom                       = 0;
double   mbFvgSlLevel                      = 0; // The FVG extreme (bottom for buy, top for sell)

double   sbt2_saved_extreme                = 0;

#endif // SBT_STATE_MQH
//+------------------------------------------------------------------+