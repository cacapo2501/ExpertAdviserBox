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
      string __str_symbol; //通貨ペア
      double __dbl_max_lots; //ロット数(初回注文時)
      double __dbl_stoploss; //損切り幅(pips)
      double __dbl_takeprofit; //利食い幅(pips)
      double __dbl_lots_ratio; //決済済み割合
      
      //プライベート関数
      double fGetOpenModifyPrice(); //価格を取得する(注文・修正時)
      double fGetClosePrice(); //価格を取得する(決済時)
      double fGetStoplossPrice(); //現在価格における損切り価格を取得する
      double fGetTakeprofitPrice(); //現在価格における利食い価格を取得する
      void fSendOrder(double); //注文を送信する
      void fCloseOrder(double); //決済を送信する
      bool fIsParamsAvailable(); //パラメータが有効な値であるか検定する
      
   public:
      OrderManager(int, int, string, double, double, double);      //コンストラクタ
      ~OrderManager();     //デストラクタ
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
                          ){
   //パラメータをプロパティにセットする
   __int_command = _int_command;
   __str_symbol  = _str_symbol;
   __int_slippage = _int_slippage;
   __int_ticket = -1;
   __int_real_digits = StdFuncGetRealDigits(__str_symbol);
   __int_pips_digits = StdFuncGetPipsDigits(__str_symbol);
   __dbl_stoploss = _dbl_stoploss;
   __dbl_takeprofit = _dbl_takeprofit;
   __dbl_max_lots = _dbl_lots;
   
   //パラメータを検定する
   if(!fIsParamsAvailable()) return;
   
   //総ロット数で注文する
   __dbl_lots_ratio = 0;
   fSendOrder(__dbl_max_lots);
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
   
   //チケット番号
   if(__int_ticket < -1) return false;
   
   
   return true;
}
//+------------------------------------------------------------------+
//| 注文を送信する                                                   |
//+------------------------------------------------------------------+
void OrderManager::fSendOrder(
                             double _dbl_lots  //送信するロット数
                             ){
   if(!fIsParamsAvailable()) return;
   
   //今オーダーを保有していない？
   //保有していたら終了
   if(__int_ticket != -1) {
      
   }
}
//+------------------------------------------------------------------+
//| 注文を参照できるよう選択する                                     |
//+------------------------------------------------------------------+
