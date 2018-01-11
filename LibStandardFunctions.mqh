//+------------------------------------------------------------------+
//|                                         LibStandardFunctions.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

//+------------------------------------------------------------------+
//| このソースの目的: 汎用関数を定義する                             |
//|                                                                  |
//+------------------------------------------------------------------+
// マーケットが取引可能か検定する
bool StdFuncIsMarketOrderable(string _str_symbol){
   return MarketInfo(_str_symbol, MODE_TRADEALLOWED);
}
//提供されている価格の桁数を取得する
int StdFuncGetRealDigits(string _str_symbol){
   return (int)MarketInfo(_str_symbol, MODE_DIGITS);
}
//通貨ペアのpipsサイズを取得する
int StdFuncGetPipsDigits(string _str_symbol){
   //提供データの桁数を取得する
   int ___int_real_digits = StdFuncGetRealDigits(_str_symbol);
   
   //小数点以下の桁数が2か3のとき、1pipsのサイズは小数点以下2桁
   if(___int_real_digits == 2 || ___int_real_digits == 3) return 2;
   //小数点以下の桁数が4か5のとき、1pipsのサイズは小数点以下2桁
   if(___int_real_digits == 4 || ___int_real_digits == 5) return 4;
   
   //上記以外の場合は提供の桁数を返す
   return ___int_real_digits;
}
//ロット数が適切か検定する
double StdFuncIsLotsizeEnable(string _str_symbol, double _dbl_lots){
   double ___dbl_lots_max = MarketInfo(_str_symbol, MODE_MAXLOT);
   double ___dbl_lots_min = MarketInfo(_str_symbol, MODE_MINLOT);
   double ___dbl_lot_step = MarketInfo(_str_symbol, MODE_LOTSTEP);
   
   //ロットサイズはMin～Maxロット数の間？
   if(_dbl_lots > ___dbl_lots_max) return false;
   if(_dbl_lots < ___dbl_lots_min) return false;
   return true;      //使用可能なロット数
}
//pipsサイズから価格に変換する
double StdFuncPips2Price(double _dbl_pips_height, int _int_pips_digits, int _int_real_digits){
   return NormalizeDouble(_dbl_pips_height * MathPow(0.1, _int_pips_digits), _int_real_digits);
}
//価格を標準化する
double StdFuncNormalizePrice(double _dbl_price, int _int_real_digits){
   return NormalizeDouble(_dbl_price, _int_real_digits);
}