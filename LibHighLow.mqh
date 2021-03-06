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
double getHighestPrice(string _symbol, int _timeframe, int _period, int _shift){
   return iHigh(_symbol, _timeframe, iHighest(_symbol, _timeframe, MODE_HIGH, _period, _shift));
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
double getLowestPrice(string _symbol, int _timeframe, int _period, int _shift){
   return iLow(_symbol, _timeframe, iLowest(_symbol, _timeframe, MODE_LOW, _period, _shift));
}
//+------------------------------------------------------------------+
//| getHighestPriceZone                                              |
//|                                                                  |
//| 指定した期間の最高値付近の値幅                                   |
//| <<引数>>                                                         |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| int            period                検定期間                    |
//| int            shift                 期間のオフセット数          |
//| double         zone                  値幅の区間の検定期間の比率  |
//|                                                                  |
//| <<戻り値>>     double                値幅                        |
//| ※period、shiftに不正な値がセットされていた場合はNULLを戻す      |
//+------------------------------------------------------------------+
double getHighestPriceZone(string _symbol, int _timeframe, int _period, int _shift, double _zone){
   //ゾーンの期間を求める
   int zone_count = (int)MathCeil((double)_period * _zone);
   
   //最高値とその位置を求める
   double max_price = getHighestPrice(_symbol, _timeframe, _period, _shift); //最高値
   int max_pos = iHighest(_symbol, _timeframe, MODE_HIGH, _period, _shift); //最高値の位置
   
   //最高値の前後区間を求める
   int zone_begin = max_pos - zone_count / 2;
   
   //最高値区間の最安値を求める
   double min_price = getLowestPrice(_symbol, _timeframe, zone_count, zone_begin); //最安値
   
   //最高値と最安値の差分を戻す
   return max_price - min_price;
}