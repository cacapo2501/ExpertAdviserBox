//+------------------------------------------------------------------+
//|                                           LibIndicatorCommon.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

//+------------------------------------------------------------------+
//| isPeriodValid                                                    |
//|                                                                  |
//| 検定対象期間がバーの本数を超えて参照していた場合、Falseを戻す    |
//| <<引数>>                                                         |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| int            period                検定期間                    |
//| int            shift                 期間のオフセット数          |
//|                                                                  |
//| <<戻り値>>     bool                  検定結果                    |
//| ※period、shiftに不正な値がセットされていた場合もFalseを戻す     |
//+------------------------------------------------------------------+
bool isPeriodValid(string symbol, int timeframe, int period, int shift){
   if(period <= 0) return false;
   if(shift < 0) return false;
   if(period + shift - 1 > iBars(symbol, timeframe)) return false;
   return true;
}
