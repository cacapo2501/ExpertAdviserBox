//+------------------------------------------------------------------+
//|                                          LibMatchingSinCurve.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../ExpertAdviserBox/LibIndicatorCommon.mqh"
#include "../ExpertAdviserBox/LibHighLow.mqh"
//+------------------------------------------------------------------+
//| getHighLowMatchingScore                                          |
//|                                                                  |
//| 指定した期間の一致点数を求める。                                 |
//| <<点数の求め方>>                                                 |
//| 期間STを正規化したチャートと、正規化した正弦波ABを取得する。     |
//| 正弦波ABのうちのある区間CDにおいて、正規化チャートの一部期間UVの |
//| 値を含む場合、1-(UVの比率)を点数として加算する。加算した点数の平 |
//| 均をスコアとして戻す。                                           |
//|                                                                  |
//| <<引数>>                                                         |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| int            section_period        単位あたりの期間            |
//| int            sections              単位の数                    |
//| (※section_period * sections が検定期間となる)                   |
//| double         start_degree          開始角度                    |
//| double         end_degree            終了角度                    |
//| int            shift                 バーのシフト本数            |
//|                                                                  |
//| <<戻り値>>     double                平均スコア(最小 0 - 1 最大) |
//| ※検定NGまたは算出できなかった場合はNULLを戻す                   |
//+------------------------------------------------------------------+
double getHighLowMatchingScore(string symbol, int timeframe, int section_period, int sections, double start_degree, double end_degree, int shift){
   //入力値検定(検定NGの場合はNULLを戻す)
   if(!isPeriodValid(symbol, timeframe, section_period * sections, shift)) return NULL;
   
   //正規化された正弦波を取得する
   double norm_curve[];
   getSinCurveValues(norm_curve, sections + 1, start_degree, end_degree);
   
   //正規化されたチャートを取得する
   double norm_high[], norm_low[];
   getNormalizeChartValues(norm_high, norm_low, symbol, timeframe, section_period, sections, shift);
   
   //取得値の検定を行う(検定NGの場合はNULLを戻す)
   //正弦波とチャートの区間数は同じ？
   if(ArraySize(norm_high) + 1 != ArraySize(norm_curve)) return NULL;
   if(ArraySize(norm_low)  + 1 != ArraySize(norm_curve)) return NULL;
      
   //スコアを求める
   return getMatchingScore(norm_curve, norm_high, norm_low);
}
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
//+------------------------------------------------------------------+
//| getNormalizeChartValues                                          |
//|                                                                  |
//| チャートの指定区間の価格のHigh-Lowを求める。各セクションの値は全 |
//| 体の値を0-1として正規化する。                                    |
//|                                                                  |
//| <<引数>>                                                         |
//| &double        get_high[]            高値の値を格納する配列      |
//| &double        get_low[]             安値の値を格納する配列      |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| int            section_period        単位あたりの期間            |
//| int            sections              単位の数                    |
//| int            shift                 バーのシフト本数            |
//|                                                                  |
//| <<戻り値>>     double                高値・安値の正規化配列      |
//+------------------------------------------------------------------+
void getNormalizeChartValues(double &get_high[], double &get_low[], string symbol, int timeframe, int section_period, int sections, int shift){
   //回答する配列の要素数を初期化する
   ArrayResize(get_high, sections);
   ArrayResize(get_low,  sections);
   
   //期間全区間の最高値、最安値を求める
   double whole_highest = getHighestPrice(symbol, timeframe, section_period * sections, shift); //全区間の最高値
   double whole_lowest  = getLowestPrice (symbol, timeframe, section_period * sections, shift); //全区間の最安値
   
   //区間数だけ繰り返す
   for(int icnt = 0; icnt < sections; icnt++){
      //区間の高値・安値を取得する
      double section_highest = getHighestPrice(symbol, timeframe, section_period, icnt * section_period + shift); //区間の高値
      double section_lowest  = getLowestPrice (symbol, timeframe, section_period, icnt * section_period + shift); //区間の安値
      
      //区間の高値・安値を正規化する
      section_highest = getNormalizeValue(section_highest, whole_highest, whole_lowest);
      section_lowest  = getNormalizeValue(section_lowest,  whole_highest, whole_lowest);
      
      //値を配列にセットする
      //値の格納順は過去の値が小さい値になるよう設定する
      //例: 新しい方から0,1,2...5となっていた場合は5,4,3...0の順で格納する
      get_high[sections - 1 - icnt] = section_highest;
      get_low [sections - 1 - icnt] = section_lowest;
   }
}
//+------------------------------------------------------------------+
//| getNormalizeValue                                                |
//|                                                                  |
//| 値を最大値および最小値から正規化する。                           |
//|                                                                  |
//| <<引数>>                                                         |
//| double         value                 正規化する値                |
//| double         highest               区間の最高値                |
//| double         lowest                区間の最低値                |
//|                                                                  |
//| <<戻り値>>     double                正規化された値              |
//| ※最高値-最低値が0以下の場合はNULLを戻す                         |
//+------------------------------------------------------------------+
double getNormalizeValue(double value, double highest, double lowest){
   //入力値検定(検定NGの場合はNULLを戻す)
   //最高値-最低値は0より大？
   if(highest - lowest <= 0) return NULL;
   
   //正規化した値を戻す
   return (value - lowest) / (highest - lowest);
}
//+------------------------------------------------------------------+
//| getMatchingScore                                                 |
//|                                                                  |
//| 区間ごとのスコアを求める。とある区間MN(要素番号I)の点数は以下の  |
//| 手順で求める。                                                   |
//| (1) High[I]-Low[I]に正弦波[I]から正弦波[I+1]が内包される場合に   |
//|     1-(High[I]-Low[I])を総得点に加算する                         |
//| (2) 総得点を要素数で割る                                         |
//|                                                                  |
//| <<引数>>                                                         |
//| double[]       sin_curve             正規化したサインカーブ      |
//| double[]       high_price            正規化した区間の最高値      |
//| double[]       low_price             正規化した区間の最低値      |
//|                                                                  |
//| <<戻り値>>     double                正規化された値              |
//| ※最高値-最低値が0以下の場合はNULLを戻す                         |
//+------------------------------------------------------------------+
double getMatchingScore(double &sin_curve[], double &high_price[], double &low_price[]){
   //合計スコアを初期化する
   double score_total = 0; //合計スコア
   
   //要素数の数だけ繰り返す
   for(int icnt = 0; icnt < ArraySize(high_price); icnt++){
      //各要素の値を求める
      double sin_left = sin_curve[icnt]; //正弦波左端
      double sin_right = sin_curve[icnt + 1]; //正弦波右端
      double section_high = high_price[icnt]; //区間の最高値
      double section_low = low_price[icnt];  //区間の最低値
      
      //正弦波の大小を求める
      double sin_high = MathMax(sin_left, sin_right); //正弦波の大きい値
      double sin_low = MathMin(sin_left,sin_right); //正弦波の小さい値
      
      //正弦波は要素の範囲に収まる値？
      if(section_high >= sin_high && sin_low >= section_low){
         //合計スコアにこの区間のスコアを加算する
         score_total += 1 - (section_high - section_low);
      }
   }
   
   //合計スコアを要素数で割った値を戻す
   return score_total / ArraySize(high_price);
}