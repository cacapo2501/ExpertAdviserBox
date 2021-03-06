//+------------------------------------------------------------------+
//|                                         LibStandardFunctions.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict
//+------------------------------------------------------------------+
//| 機能: 汎用関数を定義する                                         |
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 市場情報を取得する                                               |
//+------------------------------------------------------------------+
//取引通貨が存在するか検定する
bool StdFuncIsSymbolAvialable(string _str_symbol){
   return MarketInfo(_str_symbol, MODE_ASK) == 0;
}
// マーケットが取引可能か検定する
bool StdFuncIsMarketOrderable(string _str_symbol){
   return MarketInfo(_str_symbol, MODE_TRADEALLOWED);
}
//+------------------------------------------------------------------+
//| 値を変換する                                                     |
//+------------------------------------------------------------------+
//桁数→ポイント数に変換する
double StdFuncDigits2Point(int _int_digits){
   return MathPow(0.1, _int_digits);
}
//ポイント数→桁数に変換する
int StdFuncPoint2Digits(double _dbl_point){
   int ___int_ret = 0;
   double ___dbl_check = _dbl_point;
   
   //検定数値が0の場合は処理終了(無限ループチェック)
   if(___dbl_check == 0) return -1;
   
   //1よろ小さい間、繰り返す
   while(___dbl_check < 1){
      //10倍にする
      ___dbl_check *= 10;
      ___int_ret ++;
   }
   
   return ___int_ret;
}
//pips→価格に変換する
double StdFuncPips2Price(string _str_symbol, double _dbl_value){
   double ___dbl_pips = StdFuncGetPipsUnit(_str_symbol);
   
   return StdFuncNormalizeAsPrice(_str_symbol, _dbl_value * ___dbl_pips);
}
//+------------------------------------------------------------------+
//| 値を正規化する                                                   |
//+------------------------------------------------------------------+
//ロット数として正規化する
double StdFuncNormalizeAsLots(string _str_symbol, double _dbl_lots){
   int ___int_digits = StdFuncPoint2Digits(MarketInfo(_str_symbol, MODE_LOTSTEP));
   return NormalizeDouble(_dbl_lots, ___int_digits);
}
//価格として正規化する
double StdFuncNormalizeAsPrice(string _str_symbol, double _dbl_price){
   int ___int_digits = StdFuncGetPointDigits(_str_symbol);
   return NormalizeDouble(_dbl_price, ___int_digits);
}
//+------------------------------------------------------------------+
//| 単位を取得する                                                   |
//+------------------------------------------------------------------+
//Pipsの桁数を取得する
int StdFuncGetPipsDigits(string _str_symbol){
   int ___int_digits = StdFuncGetPointDigits(_str_symbol);
   if(___int_digits == 3 || ___int_digits == 5) ___int_digits--;
   return ___int_digits;
}
//Pipsの最小ポイント数を取得する
double StdFuncGetPipsUnit(string _str_symbol){
   return StdFuncDigits2Point(StdFuncGetPipsDigits(_str_symbol));
}
//提供されている価格の桁数を取得する
int StdFuncGetPointDigits(string _str_symbol){
   return (int)MarketInfo(_str_symbol, MODE_DIGITS);
}
//提供されている価格の最小ポイント数を取得する
double StdFuncGetPointUnit(string _str_symbol){
   return MarketInfo(_str_symbol, MODE_POINT);
}
//+------------------------------------------------------------------+
//| 検定する                                                         |
//+------------------------------------------------------------------+
bool StdFuncCheckLots(string _str_symbol, double _dbl_lots){
   //値を正規化する
   double ___dbl_normalized = StdFuncNormalizeAsLots(_str_symbol, _dbl_lots);
   
   //値は最大ロット～最小ロット？
   if(___dbl_normalized > MarketInfo(_str_symbol, MODE_MAXLOT) ||
      ___dbl_normalized < MarketInfo(_str_symbol, MODE_MINLOT)){
      return false;  
   }
   
   //値は余剰証拠金以下？
   //必要な証拠金
   double ___dbl_required = MarketInfo(_str_symbol, MODE_MARGINREQUIRED) * ___dbl_normalized;
   double ___dbl_available = AccountFreeMargin(); //余剰証拠金
   
   if(___dbl_required < ___dbl_available) return true;
   else                                   return false;
}