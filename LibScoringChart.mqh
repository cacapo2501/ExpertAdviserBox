//+------------------------------------------------------------------+
//|                                              LibScoringChart.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../ExpertAdviserBox/LibIndicatorCommon.mqh"
//+------------------------------------------------------------------+
//| getScoreOfChart                                                  |
//|                                                                  |
//| スコアマトリックスを元に、チャートの点数を計算して返す。         |
//| スコアマトリックスは２次元の配列であり、その値は0-1でなければ    |
//| ならない。                                                       |
//| チャートをスコアマトリックス数で縦横ともに分割して、そのマスの   |
//| 中にローソクが存在する場合は総得点にスコアを加算する。           |
//| 最後に点数を加算した回数で総得点を割ったものを戻り値にセットする |
//|                                                                  |
//| <<マトリックスの作り方>>                                         |
//| 3x3のマトリックスの場合、以下の要素順を使用する                  |
//|           ←古        新→                                       |
//|                                                                  |
//| ↑高値      1    2    3                                          |
//|                                                                  |
//|             4    5    6                                          |
//|                                                                  |
//| ↓安値      7    8    9                                          |
//|                                                                  |
//| <<引数>>                                                         |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| double[]       score                 スコアマトリックス          |
//| int            hcount                スコア配列の要素数（縦）    |
//| int            vcount                スコア配列の要素数（横）    |
//| int            period                検定対象バーの本数          |
//| int            shift                 バーのシフト本数            |
//|                                                                  |
//| <<戻り値>>     double                総得点÷加算回数            |
//| ※加算回数が0回のときはNULLを返す                                |
//|                                                                  |
//+------------------------------------------------------------------+
double getScoreChart(string symbol, int timeframe, double &score[], int hcount, int vcount, int period, int shift){ 
   //***********************************************
   //    入力値の検定(検定NGならNULLを返す)
   //***********************************************
   //検定対象　バー本数とシフト本数の参照範囲は正常？
   if(!isPeriodValid(symbol, timeframe, period, shift)) return NULL;
   
   //配列の要素数が0でない？
   if(hcount <= 0 || vcount <= 0) return NULL;
   
   //スコアマトリックスの要素数はhcount*vcountと同じ？
   if(ArraySize(score) != hcount * vcount) return NULL;
   
   //***********************************************
   //    セルの情報を作成する
   //***********************************************
   double price_high = iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, period, shift)); //期間内の最高値
   double price_low  = iLow (Symbol(), 0, iLowest (Symbol(), 0, MODE_LOW , period, shift)); //期間内の最安値
   
   double cell_width = hcount / vcount; //１マスの横幅
   double cell_height = (price_high - price_low) / vcount; //１マスの縦幅
   
   double edge_left = period + shift; //チャートの左端
   double edge_top  = price_high;     //チャートの上端
   
   //***********************************************
   //    ローソク存在マトリックスを生成
   //***********************************************
   bool exist[]; //ローソク存在マトリックス
   
   //ローソク存在マトリックスを初期化する
   ArrayResize(exist, hcount * vcount); 
   ArrayInitialize(exist, false);
   
   //各マスについてローソクが存在するか検定を行い、結果を格納する
   for(int x = 0; x < hcount; x++){
      for(int y = 0; y < vcount; y++){
         //上下左右の座標を求める
         double left = getLeft(edge_left, cell_width, x);
         double right = getRight(edge_left, cell_width, x);
         double top = getTop(edge_top, cell_height, y);
         double bottom = getBottom(edge_top, cell_height, y);
         
         //ローソクが存在するかを取得する
         exist[x + y * hcount] = isPriceExist(symbol, timeframe, right, left, top, bottom);
      }
   }
   
   //***********************************************
   //    総得点を計算する
   //***********************************************
   double sum = 0; //総得点
   int sum_count = 0; //加算回数
   
   //総得点を求める
   for(int i = 0; i < ArraySize(score); i++){
      //ローソクが存在するときはスコアを加算する
      if(exist[i]){
         sum += score[i];
         sum_count++;
      }
   }
   
   //加算回数が0の場合はNULLを返す
   if(sum_count == 0) return NULL;
   
   //総得点を加算回数で割った値を戻す
   return sum / sum_count;
}
//+------------------------------------------------------------------+
//| isPriceExist                                                     |
//|                                                                  |
//| 期間内、価格帯内にローソクが存在する場合はTrueを返す             |
//|                                                                  |
//| <<引数>>                                                         |
//| string         symbol                通貨シンボル                |
//| int            timeframe             適用するタイムフレーム      |
//| double         begin                 期間の右端                  |
//| double         terminate             期間の左端                  |
//| double         high                  価格の上端                  |
//| double         low                   価格の下端                  |
//|                                                                  |
//| <<戻り値>>     double                総得点÷加算回数            |
//| ※加算回数が0回のときはNULLを返す                                |
//|                                                                  |
//+------------------------------------------------------------------+
bool isPriceExist(string symbol, int timeframe, double begin, double terminate, double high, double low){
   //***********************************************
   //    入力値の検定(検定NGならNULLを返す)
   //***********************************************
   if(begin > terminate) return NULL;
   if(high < low) return NULL;
   
   //***********************************************
   //    期間をintに変換する
   //***********************************************
   int int_left = (int)MathCeil(terminate); //左端(整数)
   int int_right = (int)MathFloor(begin);   //右端(整数)
   int period = int_left - int_right; //左端-右端の期間
   int shift = int_right; //右端のシフト位置
   
   //***********************************************
   //    ローソクがあるか検定する
   //***********************************************
   double sector_high = iHigh(symbol, timeframe, iHighest(symbol, timeframe, MODE_HIGH, period, shift)); //期間の最高値
   double sector_low  = iLow (symbol, timeframe, iLowest (symbol, timeframe, MODE_LOW , period, shift));  //期間の最安値
   
   //セルの上端が期間の最安値より下ならFalse
   if(sector_high < low) return false;
   
   //セルの下端が期間の最高値より上ならFalse
   if(sector_low > high) return false;
   
   //上記を満たしていたらtrue
   return true;
}
//+------------------------------------------------------------------+
//| getLeft                                                          |
//|                                                                  |
//| 指定したセルの左端のx座標を求める                                |
//|                                                                  |
//| <<引数>>                                                         |
//| double         edge_left             チャートの左端              |
//| double         cell_width            セルの幅                    |
//| int            shift                 左端からのセルの位置        |
//|                                                                  |
//| <<戻り値>>     double                左端のx座標                 |
//|                                                                  |
//+------------------------------------------------------------------+
double getLeft(double edge_left, double cell_width, int shift){
   return edge_left - cell_width * shift;
}
//+------------------------------------------------------------------+
//| getRight                                                         |
//|                                                                  |
//| 指定したセルの右端のx座標を求める                                |
//|                                                                  |
//| <<引数>>                                                         |
//| double         edge_left             チャートの左端              |
//| double         cell_width            セルの幅                    |
//| int            shift                 左端からのセルの位置        |
//|                                                                  |
//| <<戻り値>>     double                右端のx座標                 |
//|                                                                  |
//+------------------------------------------------------------------+
double getRight(double edge_left, double cell_width, int shift){
   return edge_left - cell_width * (shift + 1);
}
//+------------------------------------------------------------------+
//| getTop                                                           |
//|                                                                  |
//| 指定したセルの上端のy座標を求める                                |
//|                                                                  |
//| <<引数>>                                                         |
//| double         edge_top              チャートの上端              |
//| double         cell_height           セルの高さ                  |
//| int            shift                 上端からのセルの位置        |
//|                                                                  |
//| <<戻り値>>     double                上端のy座標                 |
//|                                                                  |
//+------------------------------------------------------------------+
double getTop(double edge_top, double cell_height, int shift){
   return edge_top - cell_height * shift;
}
//+------------------------------------------------------------------+
//| getBottom                                                        |
//|                                                                  |
//| 指定したセルの下端のy座標を求める                                |
//|                                                                  |
//| <<引数>>                                                         |
//| double         edge_top              チャートの上端              |
//| double         cell_height           セルの高さ                  |
//| int            shift                 上端からのセルの位置        |
//|                                                                  |
//| <<戻り値>>     double                下端のy座標                 |
//|                                                                  |
//+------------------------------------------------------------------+
double getBottom(double edge_top, double cell_height, int shift){
   return edge_top - cell_height * (shift + 1);
}