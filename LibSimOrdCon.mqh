//+------------------------------------------------------------------+
//|                                       LibSimpleOrderControll.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

#include "..\\ExpertAdviserBox\\LibStdFunc.mqh"
//+------------------------------------------------------------------+
//| このソースの目的: 引数の非常に多いOrder～系の引数に固定的な初期値|
//|                   を与えて、呼び出しを読みやすくするための最小単 |
//|                   位のクラスを定義する。                         |
//|                                                                  |
//| 挙動：コンストラクタでオーダーを送信して、デストラクタで手仕舞い |
//|       する。１オーダー１インスタンスとする。                     |
//|                                                                  |
//+------------------------------------------------------------------+

class SimpleOrderControll{
   private:
      string __str_symbol;             //この注文の通貨ペア
      int    __int_ticket;             //この注文が保有しているオーダーのチケット番号
      int    __int_slippage;           //オーダー内で共通のスリッページを格納しておく
      int    __int_retry_to_sleep;     //注文が失敗したとき、待機する時間
      double __dbl_stoploss;           //最後に注文したときのストップロス(pips)
      double __dbl_takeprofit;         //最後に注文したときのストップロス(pips)
      int    __int_digits;             //提供価格の精度
      int    __int_pips_digits;        //pips表現の精度
      color  __clr_open_arrow;         //注文時の矢印の色
      color  __clr_close_arrow;        //手仕舞い時の矢印の色
      bool fIsCommandable(int);              //使用できる注文形式か検定する
      bool fCheckVolume(double);             //ロット数が使用できる精度か検定する
      bool fIsLotsizeEnable(double);         //ロットサイズが適切か検定する
      double fGetOpenPrice(int);                    //注文価格を取得する
      double fGetStoplossPrice(int, double);        //損切り価格を取得する
      double fGetTakeprofitPrice(int, double);      //利食い価格を取得する
      
   public:
      SimpleOrderControll(string, int, double, int, double, double, color, color, int, int, string);        //コンストラクタ
      ~SimpleOrderControll();       //デストラクタ
      bool fSelectThisOrder();      //このインスタンスが持っているオーダーを選択する
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
SimpleOrderControll::SimpleOrderControll(string _str_symbol, 
                                         int    _int_command,
                                         double _dbl_volume,
                                         int    _int_slippage,
                                         double _dbl_stoploss,
                                         double _dbl_takeprofit,
                                         color  _clr_open_arrow,
                                         color  _clr_close_arrow,
                                         int    _int_sleeptime = 2500,
                                         int    _int_magicnumber = 0,
                                         string _str_comment = NULL){
   int ___int_retry = 0;            //注文の実行数
   
   //指定した通貨ペアが取引可能か検定する
   if(!StdFuncIsMarketOrderable(_str_symbol)) return;    //通貨ペアが存在しないときもここでNGとする？
   
   //パラメータをプロパティにセットする
   __str_symbol = _str_symbol;
   __int_ticket = -1;
   __int_slippage = _int_slippage;
   __int_retry_to_sleep = _int_sleeptime;
   __dbl_stoploss = _dbl_stoploss;
   __dbl_takeprofit =  _dbl_takeprofit;
   __clr_open_arrow = _clr_open_arrow;
   __clr_close_arrow = _clr_close_arrow;
   __int_digits = StdFuncGetRealDigits(_str_symbol);
   __int_pips_digits = StdFuncGetPipsDigits(_str_symbol);
   
   //パラメータが有効であるか検定する
   if(!fIsCommandable(_int_command)) return;    //コマンド
   if(!fIsLotsizeEnable(_dbl_volume)) return;   //ロット数
   
   
   //現在の取引価格を取得する
   double ___dbl_price = 0;
   if(_int_command == OP_BUY)  ___dbl_price = MarketInfo(_str_symbol, MODE_ASK);
   else                        ___dbl_price = MarketInfo(_str_symbol, MODE_BID);
   
   //必要なパラメータを取得する
   double ___dbl_stoploss = fGetStoplossPrice(_int_command, _dbl_stoploss);         //損切り価格
   double ___dbl_takeprofit = fGetTakeprofitPrice(_int_command, _dbl_takeprofit);   //利食い価格
   
   //注文する
   while((__int_ticket = OrderSend(_str_symbol,
                                   _int_command,
                                   _dbl_volume, 
                                   ___dbl_price, 
                                   _int_slippage, 
                                   ___dbl_stoploss, 
                                   ___dbl_takeprofit, 
                                   _str_comment, 
                                   _int_magicnumber, 
                                   0, 
                                   _clr_open_arrow)) == -1){
      //注文に３回失敗したら、強制終了する
      if(++___int_retry == 3) ExpertRemove();
      
      //一定時間待機する
      Sleep(__int_retry_to_sleep);                                
   }
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
SimpleOrderControll::~SimpleOrderControll(){
   int ___int_retry = 0;      //手仕舞いの実行数
   
   //現在の注文を選択する
   bool ___bool_flg = fSelectThisOrder();
   
   //手仕舞いのための変数を取得する
   double ___dbl_volume = OrderLots();
   double ___dbl_price  = OrderClosePrice();
   color  ___clr_arrow  = __clr_close_arrow;
   
   
   //手仕舞いする
   while(!OrderClose(__int_ticket, ___dbl_volume, ___dbl_price, __int_slippage, ___clr_arrow)){
      //注文回数が３回を上回ったらプログラムを止める
     if(++___int_retry == 3) ExpertRemove();
      
      //一定時間待機する
      Sleep(__int_retry_to_sleep);
   }
}
//+------------------------------------------------------------------+
//| private関数: コマンド形式検定                                    |
//+------------------------------------------------------------------+
bool SimpleOrderControll::fIsCommandable(int _int_command){
   if(_int_command == OP_BUY)  return true;
   if(_int_command == OP_SELL) return true;
   return false;
}
//+------------------------------------------------------------------+
//| private関数: 注文価格取得                                        |
//+------------------------------------------------------------------+
double SimpleOrderControll::fGetOpenPrice(int _int_command){
   if(_int_command == OP_BUY)  return MarketInfo(__str_symbol, MODE_ASK);
   if(_int_command == OP_SELL) return MarketInfo(__str_symbol, MODE_BID);
   return -1;
}
//+------------------------------------------------------------------+
//| public関数: 注文を選択する                                       |
//+------------------------------------------------------------------+
bool SimpleOrderControll::fSelectThisOrder(){
   return OrderSelect(__int_ticket, SELECT_BY_TICKET);
}
//+------------------------------------------------------------------+
//| private関数: ロットサイズが使用可能か検定する                    |
//+------------------------------------------------------------------+
bool SimpleOrderControll::fIsLotsizeEnable(double _dbl_lots){
   return StdFuncIsLotsizeEnable(__str_symbol, _dbl_lots);
}
//+------------------------------------------------------------------+
//| private関数：損切り価格を取得する                                |
//+------------------------------------------------------------------+
double SimpleOrderControll::fGetStoplossPrice(int _int_command, double _dbl_stoploss){
   //pipsの利食い幅から価格の利食い幅を取得する
   double ___dbl_real_stoploss = StdFuncPips2Price(_dbl_stoploss, __int_pips_digits);
   
   //コマンドから実際の利食い価格を返す
   if(_int_command == OP_BUY)  return fGetOpenPrice(_int_command) - ___dbl_real_stoploss;
   if(_int_command == OP_SELL) return fGetOpenPrice(_int_command) + ___dbl_real_stoploss;
   
   return -1;
}
//+------------------------------------------------------------------+
//| private関数：利食い価格を取得する                                |
//+------------------------------------------------------------------+
double SimpleOrderControll::fGetTakeprofitPrice(int _int_command, double _dbl_takeprofit){
   //pipsの利食い幅から価格の利食い幅を取得する
   double ___dbl_real_takeprofit = StdFuncPips2Price(_dbl_takeprofit, __int_pips_digits);
   
   //コマンドから実際の利食い価格を返す
   if(_int_command == OP_BUY)  return fGetOpenPrice(_int_command) + ___dbl_real_takeprofit;
   if(_int_command == OP_SELL) return fGetOpenPrice(_int_command) - ___dbl_real_takeprofit;
   
   return -1;
}