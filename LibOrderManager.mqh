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
      int __int_price_digits; //配信価格の精度
      string __str_symbol; //通貨ペア
      double __dbl_max_lots; //ロット数(初回注文時)
      double __dbl_stoploss; //損切り幅(pips)
      double __dbl_takeprofit; //利食い幅(pips)
      
      //プライベート関数
      double fGetOpenModifyPrice(); //価格を取得する(注文・修正時)
      double fGetClosePrice(); //価格を取得する(決済時)
      double fGetStoplossPrice(); //現在価格における損切り価格を取得する
      double fGetTakeprofitPrice(); //現在価格における利食い価格を取得する
      
      bool fIsParamsAvailable(); //パラメータが有効な値であるか検定する
};

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
   double ___dbl_stoploss = StdFuncPips2Price(__dbl_stoploss, __int_pips_digits, __int_price_digits);   //損切り幅(価格)
   double ___dbl_price = fGetOpenModifyPrice();                                     //価格
   
   if(__int_command == OP_BUY)  return ___dbl_price - ___dbl_stoploss;
   if(__int_command == OP_SELL) return ___dbl_price + ___dbl_stoploss;
   
   return -1;
}
double OrderManager::fGetTakeprofitPrice(){
   if(!fIsParamsAvailable()) return -1;         //価格が適切か検定する
   double ___dbl_takeprofit = StdFuncPips2Price(__dbl_takeprofit, __int_pips_digits, __int_price_digits);   //損切り幅(価格)
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