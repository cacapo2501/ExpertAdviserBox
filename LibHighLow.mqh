//+------------------------------------------------------------------+
//|                                                   LibHighLow.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../ExpertAdviserBox/LibIndicatorCommon.mqh"
//+------------------------------------------------------------------+
//| getHighestPrice                                                  |
//|                                                                  |
//| 指定した期間の最高値を求める。                                   |
//| <<引数>>                                                         |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| int            period                検定期間                    |
//| int            shift                 期間のオフセット数          |
//|                                                                  |
//| <<戻り値>>     double                最高値                      |
//| ※period、shiftに不正な値がセットされていた場合はNULLを戻す      |
//+------------------------------------------------------------------+
double getHighestPrice(string symbol, int timeframe, int period, int shift){
   return iHigh(symbol, timeframe, iHighest(symbol, timeframe, MODE_HIGH, period, shift));
}
//+------------------------------------------------------------------+
//| getLowestPrice                                                   |
//|                                                                  |
//| 指定した期間の最安値を求める。                                   |
//| <<引数>>                                                         |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| int            period                検定期間                    |
//| int            shift                 期間のオフセット数          |
//|                                                                  |
//| <<戻り値>>     double                最安値                      |
//| ※period、shiftに不正な値がセットされていた場合はNULLを戻す      |
//+------------------------------------------------------------------+
double getLowestPrice(string symbol, int timeframe, int period, int shift){
   return iLow(symbol, timeframe, iLowest(symbol, timeframe, MODE_LOW, period, shift));
}