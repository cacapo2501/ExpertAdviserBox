//+------------------------------------------------------------------+
//|                                              LibOrderManager.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

#include "..\\ExpertAdviserBox\\LibStandardFunctions.mqh"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
class OrderManager{
   private:
      //プライベートプロパティ
      
      int __int_ticket; //チケット番号
      int __int_command; //注文種別
      int __int_slippage; //スリッページ
      int __int_pips_digits; //pipsの精度
      int __int_real_digits; //配信価格の精度
      color __clr_open; //注文時の矢印の色
      color __clr_close; //決済時の矢印の色
      string __str_symbol; //通貨ペア
      string __str_comment; //コメント
      double __dbl_max_lots; //ロット数(初回注文時)
      double __dbl_stoploss; //損切り幅(pips)
      double __dbl_takeprofit; //利食い幅(pips)
      
      //プライベート関数
      double fGetOpenModifyPrice(); //価格を取得する(注文・修正時)
      double fGetClosePrice(); //価格を取得する(決済時)
      double fGetStoplossPrice(); //現在価格における損切り価格を取得する
      double fGetTakeprofitPrice(); //現在価格における利食い価格を取得する
      void fSendOpen(double); //注文を送信する
      void fSendClose(double); //決済を送信する
      bool fIsParamsAvailable(); //パラメータが有効な値であるか検定する
      
   public:      
      //デバッグ後もpublicの関数
      OrderManager(int, int, string, double, double, double, string);      //コンストラクタ
      ~OrderManager();     //デストラクタ
      void fSendInitializedOrder(); //初期化した注文をサーバに送信する
      void fSendCloseAll(); //保有している建玉をすべて決済するようサーバに送信する
      
      //デバッグ後にprotectedにする関数
   //protected:
      void fSelectHoldingOrder(); //保有している注文を選択する(OrderSelect)
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
OrderManager::OrderManager(
                           int    _int_command     //OP_BUY or OP_SELL
                          ,int    _int_slippage    //スリッページ
                          ,string _str_symbol      //通貨ペア
                          ,double _dbl_stoploss    //損切りpips
                          ,double _dbl_takeprofit  //利食いpips
                          ,double _dbl_lots        //総ロット数
                          ,string _str_comment     //送信コメント
                          ){
   //パラメータをプロパティにセットする
   //初期化に必要なプロパティ
   __str_symbol  = _str_symbol;
   __int_command = _int_command;
   
   //普通のプロパティ
   __int_slippage = _int_slippage;
   __int_ticket = -1;
   __int_real_digits = StdFuncGetRealDigits(__str_symbol);
   __int_pips_digits = StdFuncGetPipsDigits(__str_symbol);
   __str_comment = _str_comment;
   __dbl_stoploss = _dbl_stoploss;
   __dbl_takeprofit = _dbl_takeprofit;
   __dbl_max_lots = _dbl_lots;
   
   if(__int_command == OP_BUY){
      __clr_open  = clrBlue;
      __clr_close = clrAqua;
   }
   else{
      __clr_open  = clrRed;
      __clr_close = clrMagenta;
   }
   
   //パラメータを検定する
   if(!fIsParamsAvailable()) return;
   
   //総ロット数を正規化する
   int ___int_lots_digits = (int)MathLog10(MarketInfo(__str_symbol, MODE_LOTSTEP));
   __dbl_max_lots = NormalizeDouble(__dbl_max_lots, ___int_lots_digits);
   
}
//+------------------------------------------------------------------+
//| 値を取得する                                                     |
//+------------------------------------------------------------------+
double OrderManager::fGetOpenModifyPrice(){
   if(!fIsParamsAvailable()) return -1;         //価格が適切か検定する
   if(__int_command == OP_BUY)  return MarketInfo(__str_symbol, MODE_ASK);
   if(__int_command == OP_SELL) return MarketInfo(__str_symbol, MODE_BID);
   return -1;
}
double OrderManager::fGetClosePrice(){
   if(!fIsParamsAvailable()) return -1;         //価格が適切か検定する
   if(__int_command == OP_BUY)  return MarketInfo(__str_symbol, MODE_BID);
   if(__int_command == OP_SELL) return MarketInfo(__str_symbol, MODE_ASK);
   return -1;
}
double OrderManager::fGetStoplossPrice(){
   if(!fIsParamsAvailable()) return -1;         //価格が適切か検定する
   double ___dbl_stoploss = StdFuncPips2Price(__dbl_stoploss, __int_pips_digits, __int_real_digits);   //損切り幅(価格)
   double ___dbl_price = fGetOpenModifyPrice();                                     //価格
   
   if(__int_command == OP_BUY)  return ___dbl_price - ___dbl_stoploss;
   if(__int_command == OP_SELL) return ___dbl_price + ___dbl_stoploss;
   
   return -1;
}
double OrderManager::fGetTakeprofitPrice(){
   if(!fIsParamsAvailable()) return -1;         //価格が適切か検定する
   double ___dbl_takeprofit = StdFuncPips2Price(__dbl_takeprofit, __int_pips_digits, __int_real_digits);   //損切り幅(価格)
   double ___dbl_price = fGetOpenModifyPrice();                                     //価格
   
   if(__int_command == OP_BUY)  return ___dbl_price + ___dbl_takeprofit;
   if(__int_command == OP_SELL) return ___dbl_price - ___dbl_takeprofit;
   
   return -1;
}
//+------------------------------------------------------------------+
//| 値の検定する                                                     |
//+------------------------------------------------------------------+
bool OrderManager::fIsParamsAvailable(){
   //注文種別
   if     (__int_command == OP_BUY);
   else if(__int_command == OP_SELL);
   else return false;
   
   //シンボルは有効？
   int ___i;
   for(___i = 0; ___i < SymbolsTotal(true); ___i++){
      if(__str_symbol == SymbolName(___i, true)) break;
   }
   if(___i > SymbolsTotal(true)) return false;
   
   //チケット番号
   if(__int_ticket < -1) return false;
   
   //総ロット数
   double ___dbl_mod_lot = StdFuncNormalizeLots(__str_symbol, __dbl_max_lots);
   if(StdFuncIsLotsizeEnable(__str_symbol, ___dbl_mod_lot)) return false;
   __dbl_max_lots = ___dbl_mod_lot;
   
   //スリッページは自己責任。基本的にユーザが設定できるようにinput化しておくこと。
   
   return true;
}
//+------------------------------------------------------------------+
//| 注文を送信する                                                   |
//+------------------------------------------------------------------+
void OrderManager::fSendOpen(
                             double _dbl_lots //送信するロットの割合
                             ){   
   //今オーダーを保有していたら終了
   if(__int_ticket != -1) return;
   
   //最大３回注文を送信する
   int ___int_count = 0;  //注文の送信回数
   while((__int_ticket = OrderSend(__str_symbol,
                              __int_command,
                              _dbl_lots,
                              fGetOpenModifyPrice(),
                              __int_slippage,
                              fGetStoplossPrice(),
                              fGetTakeprofitPrice(),
                              __str_comment,
                              0,
                              0,
                              __clr_open)) != -1){
      //３回目だったら処理終了
      if(++___int_count >= 3) return;
      
      //5秒待機する
      Sleep(5000);
   }
}
//+------------------------------------------------------------------+
//| 注文を選択する                                                   |
//+------------------------------------------------------------------+
void OrderManager::fSelectHoldingOrder(void){
   //OrderSelectする
   bool ___dummy = OrderSelect(__int_ticket, SELECT_BY_TICKET);
}
//+------------------------------------------------------------------+
//| 決済を送信する                                                   |
//+------------------------------------------------------------------+
void OrderManager::fSendClose(double _dbl_lots){
   //チケットがない場合は処理終了
   if(__int_ticket == -1) return;
   
   //決済を送信する
   bool ___result = false;
   while(!(___result = OrderClose(__int_ticket, _dbl_lots, fGetClosePrice(), __int_slippage, __clr_close))){
      //決済を３回以上した場合は処理終了
      if(++___result >= 3) return;
      
      //5秒待機する
      Sleep(5000); 
   }
}
//+------------------------------------------------------------------+
//| 最初の注文を送信する                                             |
//+------------------------------------------------------------------+
void OrderManager::fSendInitializedOrder(void){
   //値の検定は、コンストラクタで行っているので省略
   
   //最大ロット数で注文を送信する
   fSendOpen(__dbl_max_lots);
}
//+------------------------------------------------------------------+
//| 全建玉を決済する                                                 |
//+------------------------------------------------------------------+
void OrderManager::fSendCloseAll(void){
   //建玉の残りロット数を取得する
   fSelectHoldingOrder();
   double ___dbl_last_lots = OrderLots();
   
   //決済を送信する
   fSendClose(___dbl_last_lots);
}