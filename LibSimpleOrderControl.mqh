//+------------------------------------------------------------------+
//|                                        LibSimpleOrderControl.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

#include "..\\ExpertAdviserBox\\LibStandardFunctions.mqh"
//+------------------------------------------------------------------+
//| このソースの目的: 引数の非常に多いOrder～系の引数に固定的な初期値|
//|                   を与えて、呼び出しを読みやすくするための最小単 |
//|                   位のクラスを定義する。                         |
//|                                                                  |
//| 挙動：コンストラクタでオーダーを送信して、デストラクタで手仕舞い |
//|       する。１オーダー１インスタンスとする。                     |
//|                                                                  |
//+------------------------------------------------------------------+

class SimpleOrderControl{
   private:
      string __str_symbol;             //この注文の通貨ペア
      int    __int_ticket;             //この注文が保有しているオーダーのチケット番号
      int    __int_command;            //この注文の種類
      double __dbl_closed_ratio;       //このオーダーの部分決済されたロットの割合
      int    __int_slippage;           //オーダー内で共通のスリッページ
      int    __int_retry_to_sleep;     //注文が失敗したとき、待機する時間
      double __dbl_stoploss;           //最後に注文したときの損切り幅(pips)
      double __dbl_takeprofit;         //最後に注文したときの利食い幅(pips)
      double __dbl_min_stoploss;       //許可する最小損切り幅
      double __dbl_min_takeprofit;     //許可する最小利食い幅
      int    __int_digits;             //提供価格の精度
      int    __int_pips_digits;        //pips表現の精度
      color  __clr_open_arrow;         //注文時の矢印の色
      color  __clr_close_arrow;        //手仕舞い時の矢印の色
      bool fIsCommandable(int);              //使用できる注文形式か検定する
      bool fIsLotsizeEnable(double);         //ロットサイズが適切か検定する
      bool fIsClosingRatioEnable(double);    //一部決済の内容が妥当であるか検定する
      bool fCloseOrder(double);                     //オーダーを引数のロット数で決済する
      double fGetNormalizeLots(double);             //ロット数の精度を整える
      double fGetPrice();                           //注文価格を取得する
      double fGetStoplossPrice(double);             //損切り価格を取得する
      double fGetTakeprofitPrice(double);           //利食い価格を取得する
   
   protected:
      bool fModifyOrder(double, double);        //注文を修正する
      bool fSelectThisOrder();                  //このインスタンスが持っているオーダーを選択する
      bool fClosePartOfLots(double);            //注文を一部決済する
   
   public:
      SimpleOrderControl(string, int, double, int, double, double, color, color, int, int, string, double, double);        //コンストラクタ
      ~SimpleOrderControl();       //デストラクタ
      bool fInitializeSuccessed();  //初期化が成功しているかを返す
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
SimpleOrderControl::SimpleOrderControl(string _str_symbol, 
                                         int    _int_command,
                                         double _dbl_volume,
                                         int    _int_slippage,
                                         double _dbl_stoploss,
                                         double _dbl_takeprofit,
                                         color  _clr_open_arrow,
                                         color  _clr_close_arrow,
                                         int    _int_sleeptime = 2500,
                                         int    _int_magicnumber = 0,
                                         string _str_comment = NULL,
                                         double _dbl_min_stoploss = 1,
                                         double _dbl_min_takeprofit = 1){
   int ___int_retry = 0;            //注文の実行数
      
   //指定した通貨ペアが取引可能か検定する
   if(!StdFuncIsMarketOrderable(_str_symbol)) return;    //通貨ペアが存在しないときもここでNGとする？
   
   //パラメータをプロパティにセットする
   __str_symbol = _str_symbol;
   __int_ticket = -1;
   __dbl_closed_ratio = 1;
   __int_command = _int_command;
   __int_slippage = _int_slippage;
   __int_retry_to_sleep = _int_sleeptime;
   __dbl_stoploss = _dbl_stoploss;
   __dbl_takeprofit =  _dbl_takeprofit;
   __clr_open_arrow = _clr_open_arrow;
   __clr_close_arrow = _clr_close_arrow;
   __int_digits = StdFuncGetRealDigits(_str_symbol);
   __int_pips_digits = StdFuncGetPipsDigits(_str_symbol);
   __dbl_min_stoploss = _dbl_min_stoploss;
   __dbl_min_takeprofit = _dbl_takeprofit;
   
   //パラメータが有効であるか検定する
   if(!fIsCommandable(_int_command)) return;    //コマンド
   if(!fIsLotsizeEnable(_dbl_volume)) return;   //ロット数
   
   //現在の取引価格を取得する
   double ___dbl_price = 0;
   if(_int_command == OP_BUY)  ___dbl_price = MarketInfo(_str_symbol, MODE_ASK);
   else                        ___dbl_price = MarketInfo(_str_symbol, MODE_BID);
   
   //必要なパラメータを取得する
   double ___dbl_stoploss = fGetStoplossPrice(_dbl_stoploss);         //損切り価格
   double ___dbl_takeprofit = fGetTakeprofitPrice(_dbl_takeprofit);   //利食い価格
   //価格が不正な値の場合は処理終了
   if(___dbl_stoploss <= 0 || ___dbl_takeprofit <= 0) return;
   
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
SimpleOrderControl::~SimpleOrderControl(){
   //初期化に失敗している＝チケット番号がない場合は処理終了
   if(!fInitializeSuccessed()) return;
   
   //現在の注文を選択する(取得失敗した場合は強制終了)
   bool ___bool_flg = fSelectThisOrder();
   if(!___bool_flg) ExpertRemove();
   
   bool ___dummy = fCloseOrder(OrderLots());
}
//+------------------------------------------------------------------+
//| private関数：決済する                                            |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fCloseOrder(double _dbl_lots = -1){
   int ___int_retry = 0;      //手仕舞いの実行数
   
   bool ___bln_flg = fSelectThisOrder();     //オーダーを選択する
   double ___dbl_max_lots = OrderLots();     //総ロット数
   
   //ロット数が-1でなければ、全決済を許可しない
   if(___dbl_max_lots == _dbl_lots) return false;
   //ロット数が0なら決済しない
   if(_dbl_lots == 0) return false;
   //ロット数が-1なら総ロット数を決済ロット数にセットする
   if(_dbl_lots == -1) _dbl_lots = ___dbl_max_lots;
   
   //手仕舞いのための変数を取得する
   double ___dbl_price  = OrderClosePrice();
   
   //手仕舞いする
   while(!OrderClose(__int_ticket, _dbl_lots, ___dbl_price, __int_slippage, __clr_close_arrow)){
      //注文回数が３回を上回ったらプログラムを止める
      if(++___int_retry == 3) ExpertRemove();
      
      //一定時間待機する
      Sleep(__int_retry_to_sleep);
   }
   
   return true;
}
//+------------------------------------------------------------------+
//| private関数: コマンド形式検定                                    |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fIsCommandable(int _int_command){
   if(_int_command == OP_BUY)  return true;
   if(_int_command == OP_SELL) return true;
   return false;
}
//+------------------------------------------------------------------+
//| private関数: 注文価格取得                                        |
//+------------------------------------------------------------------+
double SimpleOrderControl::fGetPrice(){
   if(__int_command == OP_BUY)  return MarketInfo(__str_symbol, MODE_ASK);
   if(__int_command == OP_SELL) return MarketInfo(__str_symbol, MODE_BID);
   return -1;
}
//+------------------------------------------------------------------+
//| public関数: 注文を選択する                                       |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fSelectThisOrder(){
   return OrderSelect(__int_ticket, SELECT_BY_TICKET);
}
//+------------------------------------------------------------------+
//| private関数: ロットサイズが使用可能か検定する                    |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fIsLotsizeEnable(double _dbl_lots){
   return StdFuncIsLotsizeEnable(__str_symbol, _dbl_lots);
}
//+------------------------------------------------------------------+
//| private関数：損切り価格を取得する                                |
//+------------------------------------------------------------------+
double SimpleOrderControl::fGetStoplossPrice(double _dbl_stoploss){
   //設定された利食いpipsが最低値以下の場合は-1を返す
   if(_dbl_stoploss < __dbl_min_stoploss) return -1;
   
   //pipsの利食い幅から価格の利食い幅を取得する
   double ___dbl_real_stoploss = StdFuncNormalizePrice(StdFuncPips2Price(_dbl_stoploss, __int_pips_digits), __int_digits);
   
   //コマンドから実際の利食い価格を返す
   if(__int_command == OP_BUY)  return fGetPrice() - ___dbl_real_stoploss;
   if(__int_command == OP_SELL) return fGetPrice() + ___dbl_real_stoploss;
   
   return -1;
}
//+------------------------------------------------------------------+
//| private関数：利食い価格を取得する                                |
//+------------------------------------------------------------------+
double SimpleOrderControl::fGetTakeprofitPrice(double _dbl_takeprofit){
   //設定された利食いpipsが最低値以下の場合は-1を返す
   if(_dbl_takeprofit < __dbl_min_takeprofit) return -1;
   
   //pipsの利食い幅から価格の利食い幅を取得する
   double ___dbl_real_takeprofit = StdFuncNormalizePrice(StdFuncPips2Price(_dbl_takeprofit, __int_pips_digits), __int_digits);
   
   //コマンドから実際の利食い価格を返す
   if(__int_command == OP_BUY)  return fGetPrice() + ___dbl_real_takeprofit;
   if(__int_command == OP_SELL) return fGetPrice() - ___dbl_real_takeprofit;
   
   return -1;
}
//+------------------------------------------------------------------+
//| public関数：インスタンス化が成功しているかを返す                 |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fInitializeSuccessed(void){
   return __int_ticket != -1;
}
//+------------------------------------------------------------------+
//| protected関数：注文を修正する                                    |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fModifyOrder(double _dbl_stoploss,double _dbl_takeprofit){
   ENUM_MARKETINFO ___enm_askbid;
   //オーダーの種類から取得する価格を設定する
   if     (__int_command == OP_BUY) ___enm_askbid = MODE_ASK;
   else if(__int_command == OP_SELL) ___enm_askbid = MODE_BID;
   else return false;
   
   //価格を取得する
   double ___dbl_price = fGetPrice();
   double ___dbl_stoploss = fGetStoplossPrice(_dbl_stoploss);
   double ___dbl_takeprofit = fGetTakeprofitPrice(_dbl_takeprofit);
   
   bool ___bln_success = OrderModify(__int_ticket, ___dbl_price, ___dbl_stoploss, ___dbl_takeprofit, 0, __clr_open_arrow);
   if(___bln_success){
      __dbl_stoploss   = _dbl_stoploss;
      __dbl_takeprofit = _dbl_takeprofit;
   }
   
   return ___bln_success;
}
//+------------------------------------------------------------------+
//| protected関数：注文を一部決済する                                |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fClosePartOfLots(double _dbl_closing_ratio){
   //引数は有効値か？
   if(fIsClosingRatioEnable(_dbl_closing_ratio)) return false;
   
   //パラメータを取得する(取得失敗時は処理終了)
   bool ___bool_flg = fSelectThisOrder();
   if(!___bool_flg) return false;
   
   //パラメータを取得する
   double ___dbl_normalized_lots =        //正規化したロット数
            fGetNormalizeLots(_dbl_closing_ratio * OrderLots());
   
   //取得したロット数が0なら決済しない
   if(___dbl_normalized_lots == 0) return false;
   
   //決済する
   return fCloseOrder(___dbl_normalized_lots);
}
//+------------------------------------------------------------------+
//| private関数：一部決済の引数を検定する                            |
//+------------------------------------------------------------------+
bool SimpleOrderControl::fIsClosingRatioEnable(double _dbl_ratio){
   if(_dbl_ratio >= __dbl_closed_ratio) return false;
   if(_dbl_ratio <= 0) return false;
   return true;
}
//+------------------------------------------------------------------+
//| private関数：ロット数の精度を整える                              |
//+------------------------------------------------------------------+
double SimpleOrderControl::fGetNormalizeLots(double _dbl_lots){
   //精度を取得する
   int ___int_digits = -(int)MathLog10(MarketInfo(__str_symbol, MODE_LOTSTEP));
   
   //取得した精度で正規化する
   double ___dbl_normalized = NormalizeDouble(_dbl_lots, ___int_digits);
   if(MarketInfo(__str_symbol, MODE_MINLOT) > ___dbl_normalized) return 0;
   return ___dbl_normalized;
}
