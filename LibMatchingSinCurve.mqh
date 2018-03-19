//+------------------------------------------------------------------+
//|                                          LibMatchingSinCurve.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../ExpertAdviserBox/LibIndicatorCommon.mqh"
//+------------------------------------------------------------------+
//| getSinCurveValues                                                |
//|                                                                  |
//| 指定した角度の正弦波の離散値を0-1に正規化して戻す                |
//| <<引数>>                                                         |
//| &double        get_array[]           生成した値を格納する配列    |
//| int            sections              分割数                      |
//| double         start_degree          開始角度                    |
//| double         end_degree            終了角度                    |
//|                                                                  |
//| <<戻り値>>     なし                                              |
//+------------------------------------------------------------------+
void getSinCurveValues(double &get_array[], int sections, double start_degree, double end_degree){   
   //配列を初期化する
   ArrayResize(get_array, sections);
   ArrayInitialize(get_array, 0.);
   
   //開始角度、終了角度をラジアンに変換する
   double start_radian = start_degree * M_PI / 180.; //開始ラジアン
   double end_radian   = end_degree   * M_PI / 180.; //終了ラジアン
   
   //開始角度＞終了角度の場合は終了ラジアンに2Piを加算する
   if(start_radian > end_radian) end_radian += 2 * M_PI;
   
   //増分ステップを求める
   double step_radian = (end_radian - start_radian) / (sections - 1); //増分ラジアン
   
   //配列内の最大値、最小値を保持するための変数を初期化する
   double max_value = DBL_MIN;
   double min_value = DBL_MIN;
   
   //配列に生の正弦波の値をセットする
   for(int icnt = 0; icnt < sections; icnt++){
      get_array[icnt] = MathSin(start_radian + (double)icnt * step_radian);
      
      //配列の最大値、最小値を更新する
      max_value = MathMax(max_value, get_array[icnt]);
      min_value = MathMin(min_value, get_array[icnt]);
   }
   
   //配列の値を0-1で正規化する
   double value_diff = max_value - min_value; //配列内の最大値と最小値の差
   for(int icnt = 0; icnt < sections; icnt++){
      get_array[icnt] = (get_array[icnt] - min_value) / value_diff;
   }
}
