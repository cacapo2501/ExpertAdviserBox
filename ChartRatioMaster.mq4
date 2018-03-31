//+------------------------------------------------------------------+
//|                                             ChartRatioMaster.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict

//基本設定
input int _fast_period = 16; //短期の期間
input int _slow_period = 49; //長期の期間
input int _magic = 18000; //マジックナンバー
input int _slippage = 0; //スリッページ

//短時間・注文系変数
input double _a_time_max = 0.15; //点A-左軸時間の最大比率
input double _b_time_max = 0.30; //点B-右軸時間の最大比率
input double _c_price_min = 0.45; //点C-下軸価格の最小比率
input double _c_price_max = 0.65; //点C-下軸価格の最大比率

//注文制御変数
input double _update_ratio = 0.50; //注文更新のタイミング（利食い幅のｘ％のとき更新）

//グローバル変数
double _next_update_price = 0; //次注文更新を行う価格
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int ticket = getTicket(Symbol(), _magic); //チケット番号
   double stoploss = 0; //損切り幅
   double takeprofit = 0; //利食い幅
   
   if(ticket == -1){
      //注文を保有していない場合
      bool buy_flg = checkBuy();   //買い注文するかの検定
      bool sell_flg = checkSell(); //売り注文するかの検定
      
      //売買フラグ不正？
      if(buy_flg && sell_flg){
         Alert("エラー : 売買フラグが両方共立っている。");
         ExpertRemove(); return;
      }
      
      //注文サイズを求める
      double lots = -1; //ロットサイズ
      if(buy_flg || sell_flg){
         lots = getLotSize();
         stoploss = getStopLoss();
         takeprofit = getTakeProfit();
      }
      
      //注文する
      if(buy_flg)  sendBuy(Symbol(), lots, _magic, stoploss, takeprofit);  //買い注文
      if(sell_flg) sendSell(Symbol(), lots, _magic, stoploss, takeprofit); //売り注文
   }
   else{
      //注文を選択する
      if(!OrderSelect(getTicket(Symbol(), _magic), SELECT_BY_TICKET)){
         //注文が選択できないときはアラートを発行して終了する
         Alert("エラー : チケット番号が取得できない。");
         ExpertRemove();
         return;
      }
      
      //注文更新価格の検定を行い、それを超えていれば注文更新処理を行う
      if(reachUpdatePrice()) updateOrder();
   }
  }
//+------------------------------------------------------------------+
//| オーダーの有無を確認する                                         |
//| <<引数>>                                                         |
//| string         symbol                通貨ペアの名称              |
//| int            magic                 マジックナンバー            |
//|                                                                  |
//| <<戻り値>>     int                   チケット番号                |
//|  ※持っていないときは-1を返す                                    |
//+------------------------------------------------------------------+
int getTicket(string __symbol, int __magic){
   //ポジションをすべて検索する
   for(int i = OrdersTotal() - 1; i >= 0 ;i--){
      //各ポジションごとに検定する
      if(OrderSelect(i, SELECT_BY_POS)){
         //注文は入力したシンボルとマジックナンバーに一致？
         if(OrderMagicNumber() == __magic && OrderSymbol() == __symbol){
            //チケット番号を戻す
            return OrderTicket();
         }
      }
   }
   
   //不一致の場合は-1を戻す
   return -1;
}
//+------------------------------------------------------------------+
//| 買い注文送信処理                                                 |
//|                                                                  |
//| 買い注文を送信する                                               |
//| <<引数>>                                                         |
//| string         symbol                通貨ペアの名称              |
//| double         lots                  ロット数                    |
//| int            magic                 マジックナンバー            |
//| double         stoploss              損切り幅                    |
//| double         takeprofit            利食い幅                    |
//|                                                                  |
//| <<戻り値>>     bool                  成否判定                    |
//+------------------------------------------------------------------+
bool sendBuy(string __symbol, double __lots, int __magic, double __stoploss, double __takeprofit){
   //次注文更新価格をセットする
   _next_update_price = Ask + __takeprofit * _update_ratio;
   
   //注文する
   return OrderSend(__symbol, OP_BUY, __lots, Ask, _slippage, Ask - __stoploss, Ask + __takeprofit, NULL, __magic, 0, clrAqua);
}
//+------------------------------------------------------------------+
//| 売り注文送信処理                                                 |
//|                                                                  |
//| 売り注文を送信する                                               |
//| <<引数>>                                                         |
//| string         symbol                通貨ペアの名称              |
//| double         lots                  ロット数                    |
//| int            magic                 マジックナンバー            |
//| double         stoploss              損切り幅                    |
//| double         takeprofit            利食い幅                    |
//|                                                                  |
//| <<戻り値>>     bool                  成否判定                    |
//+------------------------------------------------------------------+
bool sendSell(string __symbol, double __lots, int __magic, double __stoploss, double __takeprofit){
   //次注文更新価格をセットする
   _next_update_price = Bid - __takeprofit * _update_ratio;
   
   //注文する
   return OrderSend(__symbol, OP_SELL, __lots, Bid, _slippage, Bid + __stoploss, Bid - __takeprofit, NULL, __magic, 0, clrMagenta);
}

//+------------------------------------------------------------------+
//| 注文更新処理                                                     |
//|                                                                  |
//| 注文を更新する                                                   |
//+------------------------------------------------------------------+
bool sendUpdate(double __new_stoploss, double __new_takeprofit){
   if(OrderType() == OP_BUY){
      return OrderModify(OrderTicket(), Ask, Ask - __new_stoploss, Ask + __new_takeprofit, 0, clrLime);
   }
   else if(OrderType() == OP_SELL){
      return OrderModify(OrderTicket(), Bid, Bid + __new_stoploss, Bid - __new_takeprofit, 0, clrYellow);
   }
   else{
      //注文種別が不正
      Alert("エラー : 注文がOP_BUYでもOP_SELLでもない。");
      ExpertRemove();
      return false;
   }
}
//+------------------------------------------------------------------+
//| 買い注文判定処理                                                 |
//|                                                                  |
//| 買い注文するタイミングであるかを検定する                         |
//| <<引数>>       なし                                              |
//|                                                                  |
//| <<戻り値>>     bool                  成否判定                    |
//+------------------------------------------------------------------+
bool checkBuy(){
   return checkSend(Symbol(), false);
}
//+------------------------------------------------------------------+
//| 売り注文判定処理                                                 |
//|                                                                  |
//| 売り注文するタイミングであるかを検定する                         |
//| <<引数>>       なし                                              |
//|                                                                  |
//| <<戻り値>>     bool                  成否判定                    |
//+------------------------------------------------------------------+
bool checkSell(){
   return checkSend(Symbol(), true);
}
//+------------------------------------------------------------------+
//| 注文前判定処理                                                   |
//|                                                                  |
//| 買い注文するタイミングであるかを検定する                         |
//| <<引数>>                                                         |
//| reverse        bool                  売り方向の判定を行う        |
//|                                                                  |
//| <<戻り値>>     bool                  成否判定                    |
//+------------------------------------------------------------------+
bool checkSend(string __symbol, bool __swap){
   //点Cの位置関係を調べる
   //最高値、最安値のx位置を求める
   int hi_time = iHighest(__symbol, 0, MODE_HIGH, _fast_period, 0); //最高値の横軸の位置
   int lo_time = iLowest(__symbol, 0, MODE_LOW, _fast_period, 0);   //最安値の横軸の位置
   
   //最高値と最安値のx位置が0の場合は処理終了
   if(hi_time == lo_time) return false;
   
   //A,Bのx位置を求める
   double a_time = __swap ? lo_time : hi_time; //点Aの時刻（絶対値）
   double b_time = __swap ? hi_time : lo_time; //点Bの時刻（絶対値）
   a_time = ((double)_fast_period - a_time) / _fast_period; //相対位置に変換
   b_time = b_time / _fast_period;                          //相対位置に変換
   
   //Cのy位置を求める
   double c_price = iClose(__symbol, 0, 0);       //点Cの縦軸の位置(絶対値)
   double hi_price = iHigh(__symbol, 0, hi_time);  //最高値
   double lo_price = iLow(__symbol, 0, lo_time);   //最安値
   if(hi_price == lo_price){
      Alert("エラー : 指標値に問題がある。");
      ExpertRemove();
      return false;
   }
   c_price = (c_price - lo_price) / (hi_price - lo_price); //相対値に変換
   
   //位置について判定する（一つでも満たさなければFalse回答）
   //点A, B, Cの位置が比率範囲内？
   if(a_time < _a_time_max && b_time < _b_time_max) //A,Bの判定
      if(_c_price_min < c_price && c_price < _c_price_max) //Cの判定
         return true;

   return false;
}
//+------------------------------------------------------------------+
//| 損切り幅算出処理                                                 |
//|                                                                  |
//| 現在の損切り価格幅を求める                                       |
//+------------------------------------------------------------------+
double getStopLoss(){
   
   return 0.25;
}
//+------------------------------------------------------------------+
//| 利食い幅算出処理                                                 |
//|                                                                  |
//| 現在の利食い価格幅を求める                                       |
//+------------------------------------------------------------------+
double getTakeProfit(){
   return 0.15;
}
//+------------------------------------------------------------------+
//| ロットサイズ算出処理                                             |
//|                                                                  |
//| 取得した条件で注文を行う際のロットサイズを求める                 |
//+------------------------------------------------------------------+
double getLotSize(){
   //とりあえず10000通貨を返す
   return 0.1;
}
//+------------------------------------------------------------------+
//| 更新価格到達検定                                                 |
//|                                                                  |
//| 注文を更新する価格に達しているか検定する                         |
//+------------------------------------------------------------------+
bool reachUpdatePrice(){
   //とりあえず
   return false;
}
//+------------------------------------------------------------------+
//| 注文更新処理                                                     |
//|                                                                  |
//| 注文を更新する処理を読み出す                                     |
//+------------------------------------------------------------------+
bool updateOrder(){
   return sendUpdate(0., 0.);
}