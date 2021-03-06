//+------------------------------------------------------------------+
//|                                                   TaksObjPro.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict

#include "../ExpertAdviserBox/LibEasyOrder.mqh"

const string prefix = "TOP_";
const string prefix_trend_line = prefix + "TR_";
const string prefix_channel_line = prefix + "CNL_";
const string prefix_arrow_check = prefix + "CHK_";
const string prefix_hline = prefix + "HLINE_";
const string prefix_label = prefix + "LABEL_"; 
const string suffix_broken_line = "_BREAK";

//--- input parameters
input bool     debug_mode = true; //デバッグモード
input ENUM_TIMEFRAMES time_frame1 = PERIOD_M15; //第１時間軸
input ENUM_TIMEFRAMES time_frame2 = PERIOD_H1;  //第２時間軸
input ENUM_TIMEFRAMES time_frame3 = PERIOD_H4;  //第３時間軸
input int      arrow_check_period = 80; //チェックマークをつける期間
input int      delete_trend_line_period = 15; //トレンドラインを削除するタイミング
input int      volatility_period = 80; //ボラティリティを取得する期間
input int      check_level = 3; //チェックマークをつける頻度(1:多い～10:少ない)
input int      check_before = 7; //チェックマーク走査期間（前）
input int      check_after = 3; //チェックマーク走査期間（後）
input int      observation_period = 7; //割り込み本数を監視する期間
input double   stoploss_weight = 1.5; //損切りの乗数
input double   takeprofit_weight = 2.0; //利食いの乗数
input color    debug_check_hi_color = 0xCCAAAA; //デバッグ用山の色
input color    debug_check_lo_color = 0xAAAACC; //デバッグ用谷の色
input color    hline_hi_color = 0x88BBDD; //抵抗線の色
input color    hline_lo_color = 0xBBDD88; //支持線の色
input color    broken_hline_hi_color = 0x333366; //ブレークした抵抗線の色
input color    broken_hline_lo_color = 0x663333; //ブレークした支持線の色
input color    trend_hi_color = 0xCCAAAA; //下降トレンドラインの色
input color    trend_lo_color = 0xAAAACC; //上昇トレンドラインの色
input color    broken_trend_hi_color = 0x995555; //ブレークした下降トレンドラインの色
input color    broken_trend_lo_color = 0x555599; //ブレークした上昇トレンドラインの色
//+------------------------------------------------------------------+
//| 構造体                                                           |
//+------------------------------------------------------------------+
struct STRUCT_BULL_BEAR{
   int TRLineHighBroken;
   int TRLineLowBroken;
};
//+------------------------------------------------------------------+
//| 列挙                                                             |
//+------------------------------------------------------------------+
enum TREND_DIR{
   RANGE_OR_BOTH = 0,
   ASCEND = 1,
   DESCEND = 2,
};
enum TREND_STATUS{
   LIVING,
   BROKEN,
};
enum TREND_REMOVE_STATUS{
  NOTYET,
  WAITFORREMOVE,
  IMMEDIATELY,
};
enum PRICE_TYPE{
   TYPE_HIGH,
   TYPE_LOW,
};
enum SORT_RULE{
   SORT_STRENGTH,
   SORT_RANGE,
   SORT_DRAW_RECENT,
   SORT_BREAK_RECENT,
};
//+------------------------------------------------------------------+
//| グローバル変数                                                   |
//+------------------------------------------------------------------+
long my_id;
int magic = 1092;
double stoploss = 0;
double takeprofit = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   my_id = ChartID();
   
   //最初のオブジェクト描画処理を行う
   if(!DrawObjectsAndParameters()){
      //描画に失敗した場合は異常終了
      return(INIT_FAILED);   
   }
   
   //第１時間軸が最小でなければ初期化失敗
   if(time_frame1 > time_frame2 || time_frame1 > time_frame3){
      return(INIT_FAILED);
   }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(IsTesting()){
      ObjectsDeleteAll(my_id, prefix);
   }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   static datetime last_obj_update = 0; //最後にオブジェクトを更新したタイミング
   static double last_mod_price = 0; //最後に修正を送信した価格
   static int tr_lo = 0, tr_hi = 0;
   if(last_obj_update != iTime(Symbol(), PERIOD_CURRENT, 0)){
      //オブジェクトを描画する
      DrawObjectsAndParameters();
      
      //最終更新時刻を更新する
      last_obj_update = iTime(Symbol(), PERIOD_CURRENT, 0);
   }
  }
//+------------------------------------------------------------------+
//| オブジェクトを描画する                                           |
//+------------------------------------------------------------------+
bool DrawObjectsAndParameters(int period = 0){
   int aryHi1[], aryLo1[]; //第１時間軸の頂点の配列
   int aryHi2[], aryLo2[]; //第２時間軸の頂点の配列
   int aryHi3[], aryLo3[]; //第３時間軸の頂点の配列
   
   //初回起動？
   bool init_flg = period == 0 ? false : true;
   
   //チャートを更新する
   
   //これまでに描画した頂点を削除する
   ObjectsDeleteAll(my_id, prefix_arrow_check);
   
   //頂点の一覧を取得する
   if(!DrawCheckMarks(aryHi1, aryLo1, 0, time_frame1, period) ||
      !DrawCheckMarks(aryHi2, aryLo2, 0, time_frame2, period) ||
      !DrawCheckMarks(aryHi3, aryLo3, 0, time_frame3, period))
      return false;
   
   //頂点をマージする
   int aryHi[], aryLo[];
   MergeVertexArrays(aryHi, aryHi1, aryHi2, aryHi3);
   MergeVertexArrays(aryLo, aryLo1, aryLo2, aryLo3);
   
   //トレンドラインを描く
   if(!DrawTrendLines(DESCEND, aryHi) ||
      !DrawTrendLines(ASCEND, aryLo)){
      return false;
   }
   
   //支持線・抵抗線を描く
   if(!DrawHLines(PRICE_HIGH, aryHi) ||
      !DrawHLines(PRICE_LOW,  aryLo)){
      return false;
   }
   
   //トレンドラインを評価する
   EvaluateTrendLine();
   //支持線・抵抗線を評価する
   EvaluateHLine();
   
   //利食い幅、損切り幅を求める
   double aryVol[];
   GetVolatilityArray(aryVol, aryHi1, aryLo1);
   stoploss = GetStoploss(aryVol) * stoploss_weight;
   takeprofit = GetTakeprofit(aryVol) * takeprofit_weight;
   
   
   
   return true;
}
//+------------------------------------------------------------------+
//| 頂点の配列をマージする                                           |
//+------------------------------------------------------------------+
void MergeVertexArrays(int &aryRes[], int &aryPrm1[], int &aryPrm2[], int &aryPrm3[]){
   //回答配列を初期化する
   ArrayResize(aryRes, ArraySize(aryPrm1), ArraySize(aryPrm1) + ArraySize(aryPrm2) + ArraySize(aryPrm3));
   
   //1つ目の配列をまるごとコピーする
   ArrayCopy(aryRes, aryPrm1);
   
   //2つ目の配列の各要素を回答配列にセットする
   for(int i = 0; i < ArraySize(aryPrm2); i++){
      AddElementToMergedArray(aryRes, aryPrm2[i]);
   }
   
   //3つ目の配列の各要素を回答配列にセットする
   for(int i = 0; i < ArraySize(aryPrm3); i++){
      AddElementToMergedArray(aryRes, aryPrm3[i]);
   }
   
   //配列をソートする
   ArraySort(aryRes);
}
//重複しないように配列に要素を追加する
void AddElementToMergedArray(int &aryDst[], int element){
   //配列に要素が存在するか検定する
   for(int i = 0; i < ArraySize(aryDst); i++){
      //存在する場合は処理終了
      if(aryDst[i] == element) return;
   }
   
   //要素を配列に追加する
   IntArrayAddElement(aryDst, element);
}
//+------------------------------------------------------------------+
//| チェックマークをつける                                           |
//+------------------------------------------------------------------+
bool DrawCheckMarks(int &aryHi[], int &aryLo[], int shift, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT, int period = 0){
   int begin = shift; //開始点
   int terminate = shift + (period != 0 ? period : arrow_check_period); //終了点
   
   //頂点を取得する
   if(!GetVertexes(aryHi, TYPE_HIGH, begin, terminate, timeframe) || 
      !GetVertexes(aryLo, TYPE_LOW , begin, terminate, timeframe)) {
      return false;
   }
   
   if(debug_mode){
      //頂点を描く
      if(!DrawVertexes(aryHi, TYPE_HIGH) ||
         !DrawVertexes(aryLo, TYPE_LOW)){
         return false;   
      }
   }
   
   return true;
}
//+------------------------------------------------------------------+
//| 頂点を取得する                                                   |
//+------------------------------------------------------------------+
bool GetVertexes(int &aryRes[], PRICE_TYPE price, int begin, int terminate, ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT){
   int aryScore[];
   ArrayResize(aryScore, terminate - begin + 1);
   ArrayInitialize(aryScore, 0);
   
   //すべてのバーで処理を繰り返す
   for(int i = begin + check_after; i <= terminate - check_before; i++){
      //現在のバーで一番高値をつけているバーを求める
      int idx_max = GetMaxScore(price, i, terminate, timeframe);
      
      //上記処理で最高値のバーにポイントを加算する
      if(idx_max != -1) aryScore[idx_max]++;
   }
   
   //回答を初期化する
   ArrayResize(aryRes, 0, terminate - begin + 1);
   
   //スコア以上のバーを求めて、その一覧を作成する
   for(int i = begin; i <= terminate; i++){
      if(aryScore[i] >= check_level){
         //デフォルト時間軸の頂点のインデックスに変換する
         int idx = i;
         if(_Period != timeframe) idx = ConvertIndexToCurrentTimeFrame(price, i, timeframe);
         IntArrayAddElement(aryRes, idx);
      }
   }
   
   //スコア以上のバーがないときは処理終了
   if(ArraySize(aryRes) <= 0) {
      return true;
   }
   
   //最後の要素は動く可能性があるので削除
   ArrayResize(aryRes, ArraySize(aryRes) - 1);
   
   return true;
}
//+------------------------------------------------------------------+
//| 現在の時間軸の頂点に変換する                                     |
//+------------------------------------------------------------------+
int ConvertIndexToCurrentTimeFrame(PRICE_TYPE price, int idxPrm, ENUM_TIMEFRAMES tfPrm){
   int idxFrom = iBarShift(Symbol(), PERIOD_CURRENT, iTime(Symbol(), tfPrm, idxPrm - 1)); //変換後インデックスFrom
   int idxTo = iBarShift(Symbol(), PERIOD_CURRENT, iTime(Symbol(), tfPrm, idxPrm)); //変換後インデックスTo
   
   int period = idxTo - idxFrom;
   return price == TYPE_HIGH ? iHighest(Symbol(), PERIOD_CURRENT, MODE_HIGH, period, idxFrom):
                               iLowest (Symbol(), PERIOD_CURRENT, MODE_LOW , period, idxFrom);
}
//+------------------------------------------------------------------+
//| 一番高値（安値）をつけているバーを求める                         |
//+------------------------------------------------------------------+
int GetMaxScore(PRICE_TYPE price, int shift, int limit, ENUM_TIMEFRAMES timeframe){
   int begin = shift - check_after;
   if(begin <= 0) begin = 0;
   int terminate = shift + check_before;
   if(terminate >= limit) terminate = limit;
   
   //最高価格・最低価格を求める
   if(price == TYPE_HIGH){
      return iHighest(Symbol(), timeframe, MODE_HIGH, terminate - begin + 1, begin);
   }
   if(price == TYPE_LOW){
      return iLowest(Symbol(), timeframe, MODE_LOW, terminate - begin + 1, begin);
   }
   
   Print("GetMaxScoreのパラメータが不正です。price : ", price);
   return -1;
}
//+------------------------------------------------------------------+
//| 配列に要素を追加する                                             |
//+------------------------------------------------------------------+
void IntArrayAddElement(int &ary[], int value){
   ArrayResize(ary, ArraySize(ary) + 1);
   ary[ArraySize(ary) - 1] = value;
}
//+------------------------------------------------------------------+
//| トレンドラインを引く                                             |
//+------------------------------------------------------------------+
bool DrawTrendLines(TREND_DIR dir, int &aryIdx[]){
   //頂点の数が２個に満たない場合は終了
   if(ArraySize(aryIdx) < 2) return true;
   
   Print("dir : ", dir, ", ArraySize : ", ArraySize(aryIdx));
   int max_base_idx = ArraySize(aryIdx);
   
   //対象となる軸頂点すべてに対して処理を行う
   for(int i = 0; i < max_base_idx; i++){
      //すべての頂点に対して処理を行う
      for(int j = i + 1; j < ArraySize(aryIdx); j++){
         //トレンドラインを１本描く
         if(!DrawTrendLine(dir, aryIdx[i], aryIdx[j])){
            return false;
         }
      }
   }
   
   return true;
}
//+------------------------------------------------------------------+
//| 頂点を描く                                                       |
//+------------------------------------------------------------------+
bool DrawVertexes(int &ary[], PRICE_TYPE price){
   for(int i = 0; i < ArraySize(ary); i++){
      if(!DrawVertex(price, ary[i])){
         return false;
      }
   }
   
   return true;
}
bool DrawVertex(PRICE_TYPE price, int idx1){
   datetime time1 = iTime(Symbol(), PERIOD_CURRENT,idx1);
   double price1 = price == TYPE_HIGH ? iHigh(Symbol(), PERIOD_CURRENT, idx1) : 
                                         iLow(Symbol(), PERIOD_CURRENT, idx1);
   string str_hilo = price == TYPE_HIGH ? "Hi_" : "Lo_";
   string arrow_name = prefix_arrow_check + str_hilo + DateTimeToInteger(time1);
   int arrow_color = price == TYPE_HIGH ? debug_check_hi_color : debug_check_lo_color;
   
   //同じ名前のオブジェクトが存在する場合は処理終了
   if(IsExistObject(arrow_name)) return true;
   
   bool res = ObjectCreate(my_id, arrow_name, OBJ_ARROW_CHECK, 0, time1, price1);
   if(res){
      ObjectSetInteger(my_id, arrow_name, OBJPROP_COLOR, arrow_color);
   }
   else{
      Print("頂点の出力に失敗しました。index : ", idx1, ", price : ", price);
   }
   
   return res;
}
//+------------------------------------------------------------------+
//| 日付時刻を整数の文字列に変換する                                 |
//+------------------------------------------------------------------+
string DateTimeToInteger(datetime time){
   string yyyy = IntegerToString(TimeYear(time), 4, '0');
   string mm = IntegerToString(TimeMonth(time), 2, '0');
   string dd = IntegerToString(TimeDay(time), 2, '0');
   string hh = IntegerToString(TimeHour(time), 2, '0');
   string nn = IntegerToString(TimeMinute(time), 2, '0');
   
   return yyyy + mm + dd + hh + nn;
}
//+------------------------------------------------------------------+
//| トレンドラインを評価する                                         |
//+------------------------------------------------------------------+
void EvaluateTrendLine(){
   //すべてのトレンドラインについて評価する
   for(int i = ObjectsTotal(my_id, 0, OBJ_TREND) - 1; i >= 0 ; i--){
      string line_name = ObjectName(my_id, i, 0, OBJ_TREND);
      
      if(!GetStatus(line_name) && Deletable(line_name) == IMMEDIATELY) {
         ObjectDelete(my_id, GetTrendLineName(i));
      }
   }
   
   return;  
}
//+------------------------------------------------------------------+
//| トレンドラインの属性を取得する                                   |
//+------------------------------------------------------------------+
PRICE_TYPE GetObjectAttribute(string obj_name){
   PRICE_TYPE price = NULL;
   if(StringFind(obj_name, "Hi") >= 0) price = TYPE_HIGH;
   if(StringFind(obj_name, "Lo") >= 0) price = TYPE_LOW;
   
   return price;
}
TREND_DIR GetDirection(string obj_name){
   TREND_DIR res = RANGE_OR_BOTH;
   if(StringFind(obj_name, "Hi") >= 0) res = DESCEND;
   if(StringFind(obj_name, "Lo") >= 0) res = ASCEND;
   
   return res;
}
//+------------------------------------------------------------------+
//| 配列の合計を求める                                               |
//+------------------------------------------------------------------+
int IntArraySum(int &ary[]){
   int res = 0;
   for(int i = 0; i < ArraySize(ary); i++){
      res += ary[i];
   }
   return res;
}
//+------------------------------------------------------------------+
//| 支持線・抵抗線を描く                                             |
//+------------------------------------------------------------------+
bool DrawHLines(ENUM_APPLIED_PRICE price, int &ary[]){
   double last_price = price == PRICE_HIGH ? -DBL_MAX : DBL_MAX; //最後の価格
   //配列の数分繰り返す
   for(int i = 0; i < ArraySize(ary); i++){
      //価格１を求める
      double price1 = price == PRICE_HIGH ? iHigh(Symbol(), PERIOD_CURRENT, ary[i]) :
                                            iLow(Symbol(), PERIOD_CURRENT, ary[i]) ;
      //価格１が妥当？
      if((price == PRICE_HIGH && price1 > last_price) || 
         (price == PRICE_LOW  && price1 < last_price)){
         //時間１、オブジェクト名を求める
         datetime time1 = iTime(Symbol(), PERIOD_CURRENT, ary[i]);
         string obj_name = prefix_hline + (price == PRICE_HIGH ? "Hi" : "Lo") + DateTimeToInteger(time1);
         
         //同じ名前のオブジェクトがある？
         if(!IsExistObject(obj_name)){
            //ない場合はオブジェクトを描く
            ObjectCreate(my_id, obj_name, OBJ_HLINE, 0, time1, price1);
            ObjectSetInteger(my_id, obj_name, OBJPROP_COLOR, price == PRICE_HIGH ? hline_hi_color : hline_lo_color);
         }
         
         //最後の価格を更新する
         last_price = price1;
      }
   }
   return true;
}
//+------------------------------------------------------------------+
//| オブジェクトが存在するか検定する                                 |
//+------------------------------------------------------------------+
bool IsExistObject(string search_name){
   for(int i = 0; i < ObjectsTotal(); i++){
      string obj_name = ObjectName(i);
      if(StringFind(obj_name, search_name) >= 0) return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//| 支持線・抵抗線について検定する                                   |
//+------------------------------------------------------------------+
void EvaluateHLine(){   
   //前バーの価格を取得する
   double open_price_now = iOpen(Symbol(), PERIOD_CURRENT, 0); //現在の始値
   
   //すべての支持抵抗線について評価する
   for(int i = ObjectsTotal(my_id, 0, OBJ_HLINE) - 1; i >= 0; i--){
      string obj_name = ObjectName(my_id, i, 0, OBJ_HLINE); //支持抵抗線の名称
      bool broken_flg = GetBroken(obj_name);
      //支持抵抗線を割り込んでいる？
      if(!broken_flg && CheckHorizontalLineBroken(obj_name, open_price_now)){
         PRICE_TYPE type = GetObjectAttribute(obj_name);
         ObjectSetInteger(my_id, obj_name, OBJPROP_COLOR, type == TYPE_HIGH ? broken_hline_hi_color : broken_hline_lo_color);
         ObjectSetInteger(my_id, obj_name, OBJPROP_STYLE, STYLE_DOT);
         datetime broken_time = iTime(Symbol(), PERIOD_CURRENT, 0);
         string broken_suffix = suffix_broken_line + DateTimeToInteger(broken_time);
         ObjectSetString(my_id, obj_name, OBJPROP_NAME, obj_name + broken_suffix);
         obj_name += broken_suffix;
      }
      
      //支持抵抗線が十分に古い？
      if(GetBroken(obj_name) && GetBrokenBar(obj_name) >= delete_trend_line_period){
         ObjectDelete(my_id, obj_name);
      }
   }
}
//+------------------------------------------------------------------+
//| 抵抗線・支持線を割り込んでいるか検定する                         |
//+------------------------------------------------------------------+
bool CheckHorizontalLineBroken(string obj_name, double open_price){
   //オブジェクト種類が抵抗線・支持線でないなら検定しない
   if(StringFind(obj_name, prefix_hline) < 0) return false;
   //オブジェクトがブレーク済みの場合は検定しない
   if(StringFind(obj_name, suffix_broken_line) >= 0) return false;
   //価格１と属性を求める
   double price1 = ObjectGetDouble(my_id, obj_name, OBJPROP_PRICE1);
   PRICE_TYPE price = GetObjectAttribute(obj_name);
   //価格１は割り込んでいる？
   if(price == TYPE_HIGH && open_price > price1) return true;
   if(price == TYPE_LOW  && open_price < price1) return true;
   return false;
}
//+------------------------------------------------------------------+
//| ボラティリティ配列を生成する                                     |
//+------------------------------------------------------------------+
void GetVolatilityArray(double &aryVol[], const int &aryHi[], const int &aryLo[]){
   //回答配列を初期化する
   ArrayResize(aryVol, 0, ArraySize(aryHi) + ArraySize(aryLo));
   
   ENUM_APPLIED_PRICE price = PRICE_CLOSE; //候補になる配列の種別
   int cand_begin = 0, cand_terminate = 0; //候補のインデックス
   int hi_count = 0, lo_count = 0; //カウンタ
   //頂点の数がなくなるまで繰り返す
   while(hi_count < ArraySize(aryHi) || lo_count < ArraySize(aryLo)){
      if(hi_count >= ArraySize(aryHi)){
         //高値の残りがない＝残りの安値を設定する
         price = PRICE_LOW;
         cand_begin = lo_count;
         cand_terminate = ArraySize(aryLo) - 1;
         lo_count = ArraySize(aryLo);
      }
      else if(lo_count >= ArraySize(aryLo)){
         //安値の残りがない＝残りの高値を設定する
         price = PRICE_HIGH;
         cand_begin = hi_count;
         cand_terminate = ArraySize(aryHi) - 1;
         hi_count = ArraySize(aryHi);
      }
      else if(aryHi[hi_count] == aryLo[lo_count]){
         //高値安値ともに同じインデックス
         price = PRICE_CLOSE;
         hi_count++;
         lo_count++;
      }
      else if(aryHi[hi_count] < aryLo[lo_count]){
         //高値の方が小さい
         price = PRICE_HIGH;
         cand_begin = hi_count;
         while(aryHi[hi_count] < aryLo[lo_count]){
            cand_terminate = hi_count++;
            if(hi_count >= ArraySize(aryHi)) break;
         }
      }
      else{
         //安値の方が小さい
         price = PRICE_LOW;
         cand_begin = lo_count;
         while(aryHi[hi_count] > aryLo[lo_count]){
            cand_terminate = lo_count++;
            if(lo_count >= ArraySize(aryLo)) break;
         }
      }
      
      //最も高い（低い）頂点の値を求める
      double max_price = 0;
      if(price == PRICE_HIGH) max_price = GetHighestVertexPrice(aryHi, price, cand_begin, cand_terminate);
      if(price == PRICE_LOW)  max_price = GetHighestVertexPrice(aryLo, price, cand_begin, cand_terminate);
      
      //結果を格納する
      if(max_price != 0){
         ArrayResize(aryVol, ArraySize(aryVol) + 1);
         aryVol[ArraySize(aryVol) - 1] = max_price;
      }
   }
}
//+------------------------------------------------------------------+
//| 連続インデックスの最高値・最安値を求める                         |
//+------------------------------------------------------------------+
double GetHighestVertexPrice(const int &aryIdx[], const ENUM_APPLIED_PRICE price, const int begin, const int terminate){
   double price_max = price == PRICE_HIGH ? iHigh(Symbol(), PERIOD_CURRENT, begin) :
                                            iLow(Symbol(), PERIOD_CURRENT, begin);
   for(int i = begin + 1; i <= terminate; i++){
      double price_now = price == PRICE_HIGH ? iHigh(Symbol(), PERIOD_CURRENT, i) :
                                               iLow(Symbol(), PERIOD_CURRENT, i);
      price_max = price == PRICE_HIGH ? MathMax(price_max, price_now) : MathMin(price_max, price_now);
   }
   return price_max;
}
//+------------------------------------------------------------------+
//| 損切りの幅を求める                                               |
//+------------------------------------------------------------------+
double GetStoploss(const double &aryVol[]){
   //要素が取得できない場合は処理終了
   if(ArraySize(aryVol) == 0) return -1;
   
   //１ずつ差分を取得する
   double diff[]; //差分
   ArrayResize(diff, 0);
   for(int i = 1; i < ArraySize(aryVol); i ++){
      DoubleArrayAddElement(diff, MathAbs(aryVol[i - 1] - aryVol[i]));
   }
   
   //差分配列をソートする
   ArraySort(diff, WHOLE_ARRAY, 0, MODE_ASCEND);
   //回答するインデックスを求める
   int res_idx = ArraySize(diff) * 3 / 4;
   return diff[res_idx];
}
//+------------------------------------------------------------------+
//| 利食いの幅を求める                                               |
//+------------------------------------------------------------------+
double GetTakeprofit(const double &aryVol[]){
   //要素が取得できない場合は処理終了
   if(ArraySize(aryVol) == 0) return -1;
   
   //偶数インデックスの差分を取得する
   double diff[]; //差分
   ArrayResize(diff, 0);
   for(int i = 2; i < ArraySize(aryVol); i += 2){
      DoubleArrayAddElement(diff, MathAbs(aryVol[i - 2] - aryVol[i]));
   }
   
   //奇数インデックスの差分を取得する
   for(int i = 3; i < ArraySize(aryVol); i += 2){
      DoubleArrayAddElement(diff, MathAbs(aryVol[i - 2] - aryVol[i]));
   }
   
   //差分配列をソートする
   ArraySort(diff, WHOLE_ARRAY, 0, MODE_ASCEND);
   //回答するインデックスを求める
   int res_idx = ArraySize(diff) * 3 / 4;
   return diff[res_idx];
}
//+------------------------------------------------------------------+
//| 小数配列に値を格納する                                           |
//+------------------------------------------------------------------+
void DoubleArrayAddElement(double &array[], const double value){
   ArrayResize(array, ArraySize(array) + 1);
   array[ArraySize(array) - 1] = value;
}
//+------------------------------------------------------------------+
//| トレンドラインクラス・コンストラクタ                             |
//+------------------------------------------------------------------+
bool DrawTrendLine(TREND_DIR dir, int idx1,int idx2){
   datetime time1, time2; //時間
   time1 = iTime(Symbol(), PERIOD_CURRENT, idx1);  //起点の時間
   time2 = iTime(Symbol(), PERIOD_CURRENT, idx2);  //終点の時間
   
   double price1, price2; //価格
   if(dir == DESCEND){
      price1 = iHigh(Symbol(), PERIOD_CURRENT, idx1); //起点の高値
      price2 = iHigh(Symbol(), PERIOD_CURRENT, idx2); //終点の高値
   }
   else{
      price1 = iLow(Symbol(), PERIOD_CURRENT, idx1); //起点の安値
      price2 = iLow(Symbol(), PERIOD_CURRENT, idx2); //終点の安値
   }
   
   //オブジェクトの名称を取得する
   string str_hilo = dir == DESCEND ? "Hi_" : "Lo_";
   string res_name = prefix_trend_line + str_hilo + DateTimeToInteger(time2) + "->" + DateTimeToInteger(time1);
   if(SearchSameNameTrendLine(res_name)) {
      return true;
   }
   
   //オブジェクトを生成する
   bool res_create = ObjectCreate(my_id, res_name, OBJ_TREND, 0, time2, price2, time1, price1);
   if(res_create){
      ObjectSetInteger(my_id, res_name, OBJPROP_COLOR, dir == DESCEND ? trend_hi_color : trend_lo_color);
   }
   else {
      Print("トレンドラインの出力に失敗しました。dir : ", dir ,", index1 : ", idx1, ", index2 : ", idx2);
      return false;
   }
   
   //有効性の検定を行う
   if(!TrendLineEnable(res_name)){
      ObjectDelete(my_id, res_name);
   }
   
   return true;
}
//+------------------------------------------------------------------+
//| 同じ名前のトレンドラインがあるか検索する                         |
//+------------------------------------------------------------------+
bool SearchSameNameTrendLine(string name){
   for(int i = 0; i < ObjectsTotal(my_id, 0, OBJ_TREND); i++){
      string cur_name = ObjectName(my_id, i, 0, OBJ_TREND);
      if(StringFind(cur_name, name) >= 0) return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//| トレンドラインクラス・使用可能判定処理                           |
//+------------------------------------------------------------------+
bool TrendLineEnable(string line_name){
   datetime time2 = GetTime2(line_name);
   datetime time1 = GetTime1(line_name);
   double price2 = GetPrice2(line_name);
   double price1 = GetPrice1(line_name);
   double between_price = GetBetweenPrice(line_name); // 価格１→価格２の最低値
   double after_price = GetAfterPrice(line_name); //現在→価格１の最低値
   TREND_DIR dir = GetDirection(line_name); //トレンドラインの向き
   
   //価格の上下関係の検定を行う
   if(dir == DESCEND){
      if(price1 <= price2) return false;
      if(between_price <= after_price) return false;
   }
   else{
      if(price1 >= price2) return false;
      if(between_price >= after_price) return false;
   }
   
   //現在→価格１の最低値を記録したバーを調べる
   int min_bar = 0;
   
   //インデックス１～インデックス２を結ぶ直線を下回る（上回る）価格が存在しない
   for(int i = min_bar; i < GetBar1(line_name); i++){
      double comp_price = dir == DESCEND ? iHigh(Symbol(), PERIOD_CURRENT, i):
                                                iLow(Symbol(), PERIOD_CURRENT, i);
      if(dir == DESCEND && comp_price > GetPriceOnLine(line_name, i)) return false;
      if(dir == ASCEND  && comp_price < GetPriceOnLine(line_name, i)) return false;
   }
   
   return true;
}
//+------------------------------------------------------------------+
//| トレンドラインクラス・ステータス更新処理                         |
//+------------------------------------------------------------------+
bool GetStatus(string line_name){
   //すでにブレークしている場合は何もしない
   if(GetBroken(line_name)) return false;
   
   TREND_DIR dir = GetDirection(line_name);
   int break_index = -1;
   //時間１～現在の間で価格がブレークしていない
   for(int i = GetBar2(line_name) - 1; i >= 0; i--){
      double open_price = iOpen(Symbol(), PERIOD_CURRENT, i);
      if(dir == DESCEND && open_price > GetPriceOnLine(line_name, i)) break_index = i;
      if(dir == ASCEND  && open_price < GetPriceOnLine(line_name, i)) break_index = i;
      if(break_index != -1) break;
   }
   
   //今回の検定でブレイクした場合は名称を更新する
   if(break_index != -1){
      datetime update_dt = iTime(Symbol(), PERIOD_CURRENT, break_index);
      string update_name = line_name + suffix_broken_line + DateTimeToInteger(update_dt);
      ObjectSetString(my_id, line_name, OBJPROP_NAME, update_name);
      ObjectSetInteger(my_id, update_name, OBJPROP_COLOR, dir == DESCEND ? broken_trend_hi_color : broken_trend_lo_color);
      ObjectSetInteger(my_id, update_name, OBJPROP_STYLE, STYLE_DOT);
   }
   
   return break_index == -1;
}
//+------------------------------------------------------------------+
//| トレンドラインクラス・期間内の最高価格を求める                   |
//+------------------------------------------------------------------+
double GetBetweenPrice(string line_name){
   TREND_DIR dir = GetDirection(line_name);
   int vertex_idx = GetBetweenIndex(line_name);
   
   //属性が下降のとき：最安値を取得する
   if(dir == DESCEND){
      return iLow(Symbol(), PERIOD_CURRENT, vertex_idx);
   }
   //属性が上昇のとき：最高値を取得する
   else{
      return iHigh(Symbol(), PERIOD_CURRENT, vertex_idx);
   }
}
int GetBetweenIndex(string line_name){
   TREND_DIR dir = GetDirection(line_name);
   int begin = GetBar2(line_name) + 1;
   int period = GetBar1(line_name) - GetBar2(line_name) - 1;
   
   //属性が下降のとき：最安値を取得する
   if(dir == DESCEND){
      int min_idx = iLowest(Symbol(), PERIOD_CURRENT, MODE_LOW, period, begin);
      return min_idx;
   }
   //属性が上昇のとき：最高値を取得する
   else{
      int max_idx = iHighest(Symbol(), PERIOD_CURRENT, MODE_HIGH, period, begin);
      return max_idx;
   }
}
//+------------------------------------------------------------------+
//| トレンドラインクラス・期間後の最高価格を求める                   |
//+------------------------------------------------------------------+
double GetAfterPrice(string line_name){
   TREND_DIR dir = GetDirection(line_name);
   int period = GetBar2(line_name) - 1;
   
   //属性が下降のとき：最安値を取得する
   if(dir == DESCEND){
      int min_idx = iLowest(Symbol(), PERIOD_CURRENT, MODE_LOW, period, 0);
      return iLow(Symbol(), PERIOD_CURRENT, min_idx);
   }
   //属性が上昇のとき：最高値を取得する
   else{
      int max_idx = iHighest(Symbol(), PERIOD_CURRENT, MODE_HIGH, period, 0);
      return iHigh(Symbol(), PERIOD_CURRENT, max_idx);
   }
}
//+------------------------------------------------------------------+
//| トレンドラインクラス・削除可能検定                               |
//+------------------------------------------------------------------+
TREND_REMOVE_STATUS Deletable(string line_name){
   if(GetBroken(line_name)){
      int delete_index = iBarShift(Symbol(), PERIOD_CURRENT, GetBrokenTime(line_name));
      
      if(delete_index > arrow_check_period){
         return IMMEDIATELY;
      }
      return WAITFORREMOVE;
   }
   else return NOTYET;
}
//+------------------------------------------------------------------+
//| トレンドラインの名称を取得する                                   |
//+------------------------------------------------------------------+
string GetTrendLineName(int index){
   return ObjectName(my_id, index, 0, OBJ_TREND);
}
datetime GetTime2(string line_name){ return (datetime)ObjectGetInteger(my_id, line_name, OBJPROP_TIME2); }
datetime GetTime1(string line_name){ return (datetime)ObjectGetInteger(my_id, line_name, OBJPROP_TIME1); }
double GetPrice2(string line_name){ return ObjectGetDouble(my_id, line_name, OBJPROP_PRICE2); }
double GetPrice1(string line_name){ return ObjectGetDouble(my_id, line_name, OBJPROP_PRICE1); }
int GetBar2(string line_name){ return iBarShift(Symbol(), PERIOD_CURRENT, GetTime2(line_name)); }
int GetBar1(string line_name){ return iBarShift(Symbol(), PERIOD_CURRENT, GetTime1(line_name)); }
double GetPriceOnLine(string line_name, int idx){ return ObjectGetValueByShift(line_name, idx); }
//+------------------------------------------------------------------+
//| トレンドラインのブレーク状態を取得する                           |
//+------------------------------------------------------------------+
bool GetBroken(string line_name){
   return StringFind(line_name, suffix_broken_line) >= 0;
}
//+------------------------------------------------------------------+
//| トレンドラインの削除時刻を取得する                               |
//+------------------------------------------------------------------+
datetime GetBrokenTime(string line_name){
   //ブレイクしない場合は最大時刻を返す
   if(StringFind(line_name, suffix_broken_line) < 0) return (datetime)-1;
   
   //ブレーク時刻を取得する
   int str_break_time_idx = StringFind(line_name, suffix_broken_line) + StringLen(suffix_broken_line); //時間が格納されている位置
   string str_break_time = StringSubstr(line_name, str_break_time_idx, 12); //抽出した時刻文字列
   
   //文字列→時刻に変換する
   string yyyy = StringSubstr(str_break_time, 0, 4); //年
   string mm = StringSubstr(str_break_time, 4, 2); //月
   string dd = StringSubstr(str_break_time, 6, 2); //日
   string hh = StringSubstr(str_break_time, 8, 2); //時
   string nn = StringSubstr(str_break_time, 10, 2); //分
   string combined = yyyy + "." + mm + "." + dd + " " + hh + ":" +nn;
   datetime res = StrToTime(combined);
   return res;
}
int GetBrokenBar(string line_name){
   return iBarShift(Symbol(), PERIOD_CURRENT, GetBrokenTime(line_name));
}
//+------------------------------------------------------------------+
//| トレンドラインの一覧を取得する                                   |
//+------------------------------------------------------------------+
void GetTrendLinesList(string &list[], TREND_DIR dir = RANGE_OR_BOTH, TREND_STATUS status = LIVING){
   //配列を初期化する
   ArrayResize(list, 0, ObjectsTotal(my_id, 0, OBJ_TREND));
   
   //生きているトレンドラインを総なめする
   for(int i = 0; i < ObjectsTotal(my_id, 0, OBJ_TREND); i++){
      string cur_name = ObjectName(my_id, i, 0, OBJ_TREND);
      if(StringFind(cur_name, prefix_trend_line) < 0) continue;
      if(status == LIVING && StringFind(cur_name, suffix_broken_line) >= 0) continue;
      if(status == BROKEN && StringFind(cur_name, suffix_broken_line) < 0) continue;
      if(dir != RANGE_OR_BOTH && StringFind(cur_name, dir == DESCEND ? "Hi" : "Lo") < 0) continue; 
      ArrayResize(list, ArraySize(list) + 1);
      list[ArraySize(list) - 1] = cur_name;
   }
}
//+------------------------------------------------------------------+
//| 期間後の最低価格(最高価格)をつけたインデックス求める             |
//+------------------------------------------------------------------+
int GetAfterIndex(string line_name){
   TREND_DIR dir = GetDirection(line_name);
   int period = GetBar2(line_name) - 1;
   
   //属性が下降のとき：最安値を取得する
   if(dir == DESCEND){
      return iLowest(Symbol(), PERIOD_CURRENT, MODE_LOW, period, 0);
   }
   //属性が上昇のとき：最高値を取得する
   else{
      return iHighest(Symbol(), PERIOD_CURRENT, MODE_HIGH, period, 0);
   }
}
//+------------------------------------------------------------------+
//| トレンドラインの強さ順にソートする                               |
//+------------------------------------------------------------------+
void SortTrendLineList(string &aryRes[], string &aryPar[], SORT_RULE sort, int sort_order = 1){
   ArrayResize(aryRes, ArraySize(aryPar));
   
   //トレンドライン名称の先頭に強さを追加して格納する
   for(int i = 0; i < ArraySize(aryPar); i++){
      int strength = 0;
      switch(sort){
         case SORT_STRENGTH: 
            strength = GetTrendLineStrength(aryPar[i]); 
            break;
         case SORT_BREAK_RECENT:
            strength = GetBrokenBar(aryPar[i]);
            break;
         case SORT_DRAW_RECENT:
            strength = GetBar2(aryPar[i]);
            break;
         case SORT_RANGE:
            strength = GetRangeFromCurrent(aryPar[i]);
            break;
      }
      aryRes[i] = IntegerToString(strength, 6, '0') + aryPar[i];
   }
   
   SortStringArray(aryRes);
   
   for(int i = 0; i < ArraySize(aryRes); i++){
      aryRes[i] = StringSubstr(aryRes[i], 6);
   }
}
//+------------------------------------------------------------------+
//| トレンドラインの強さを取得する                                   |
//+------------------------------------------------------------------+
int GetTrendLineStrength(string line_name){
   return (int)MathAbs(GetBar1(line_name) - GetBar2(line_name));
}
//+------------------------------------------------------------------+
//| 現在価格からトレンドラインまでの距離を取得する                   |
//+------------------------------------------------------------------+
int GetRangeFromCurrent(string line_name){
   static datetime last_called = 0;
   static double range_hi = 0, range_lo = 0;
   if(last_called != iTime(Symbol(), PERIOD_CURRENT, 0)){
      static int aryHi[], aryLo[];
      DrawCheckMarks(aryHi, aryLo, 0);
      last_called = iTime(Symbol(), PERIOD_CURRENT, 0);
      range_hi = iHigh(Symbol(), PERIOD_CURRENT, ArraySize(aryHi) > 0 ? aryHi[0] : 0);
      range_lo = iLow (Symbol(), PERIOD_CURRENT, ArraySize(aryLo) > 0 ? aryLo[0] : 0);
   }
   
   double line_price = GetPriceOnLine(line_name, 0);
   if(range_hi > line_price && line_price > range_lo) return 0;
   return (int)(MathMax(line_price - range_hi, range_lo - line_price) * MathPow(10, Digits)) % 1000000;
}
//+------------------------------------------------------------------+
//| 文字列をソートする                                               |
//| sort_order = 1で昇順、sort_order = -1で降順                      |
//+------------------------------------------------------------------+
void SortStringArray(string &aryPar[], int sort_order = 1){
   //ソート方向の指示異常時は処理終了
   if(sort_order != 1 && sort_order != -1) return;
   
   bool sort_flg = false; //この週未ソートフラグ
   //未ソートになるまで繰り返す
   while(!sort_flg){
      sort_flg = true;
      //バブルソートする
      for(int i = 1; i < ArraySize(aryPar); i++){
         if(StringCompare(aryPar[i - 1], aryPar[i]) * sort_order > 0){
            string temp = aryPar[i - 1];
            aryPar[i - 1] = aryPar[i];
            aryPar[i] = temp;
            sort_flg = false;
         }
      }
   }
}