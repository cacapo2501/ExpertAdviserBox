//+------------------------------------------------------------------+
//|                                               LibLotsManager.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

#include "..\\ExpertAdviserBox\\LibStandardFunctions.mqh"
//+------------------------------------------------------------------+
//| このソースの目的: ポジションサイズ管理を行う。直近の損失から適切 |
//|                   なポジションサイズを超えないようにロット数を   |
//|                   返す。                                         |
//+------------------------------------------------------------------+
class LotsManager{
   private:
      bool   __bln_initialized;    //初期化済みフラグ
      double __dbl_max_lost_ratio; //全証拠金のうち、1注文で損失を許容する割合
      bool   ___bln_variable_equity; //証拠金額を変動させる
      double __dbl_fixed_equity;   //初期の証拠金比率
      string __str_symbol;         //通貨ペア
      
   public:
      LotsManager(double, double, double, bool, string);     //コンストラクタ
      ~LotsManager();                          //デストラクタ
      double fGetUsableMargin(double);         //使用する証拠金額を取得する
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
LotsManager::LotsManager(double _dbl_max_lost_ratio  //許容損失割合
                        ,double _dbl_max_equity      //最大証拠金(*1)
                        ,double _dbl_equity_ratio    //証拠金の使用割合(*1)
                        ,bool   _bln_equity_variable //証拠金の増減に合わせて使用割合を可変にする？
                        ,string _str_fixed_symbol    //通貨ペア
){
   //初期化フラグをfalseに設定する
   __bln_initialized = false;
   
   //引数を検定する
   //(*1)の片方設定検定
   bool ___bln_check_flg = true;
   if(_dbl_equity_ratio == 0 && _dbl_max_equity == 0){
      ___bln_check_flg = false;
   }
   if(_dbl_equity_ratio != 0 && _dbl_max_equity != 0){
      ___bln_check_flg = false;
   }
   
   //検定NGなら処理終了
   if(!___bln_check_flg) return;
   
   //***** プロパティを設定する *****
   double ___dbl_equity = AccountInfoDouble(ACCOUNT_EQUITY); //証拠金合計
   
   //最大使用証拠金関連
   ___bln_variable_equity = _bln_equity_variable;
   if(___bln_variable_equity){
      __dbl_max_lost_ratio = _dbl_equity_ratio;
      if(__dbl_max_lost_ratio == 0){
         __dbl_max_lost_ratio = _dbl_max_equity / ___dbl_equity;
      }
      __dbl_fixed_equity = 0;
   }
   else{
      __dbl_fixed_equity = _dbl_max_equity;
      if(__dbl_fixed_equity == 0){
         __dbl_fixed_equity = ___dbl_equity * _dbl_equity_ratio;
      }
      __dbl_max_lost_ratio = 0;
   }
   __str_symbol = _str_fixed_symbol;
   
   //初期化完了
   __bln_initialized = true;
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
LotsManager::~LotsManager(){
   
}
//+------------------------------------------------------------------+
//| 証拠金額を取得する                                               |
//+------------------------------------------------------------------+
double LotsManager::fGetUsableMargin(double _dbl_max_lost_pips){
   //1ロットあたりの損失額を求める
   double ___dbl_lost_point_unit = MarketInfo(__str_symbol, MODE_TICKVALUE) / MarketInfo(__str_symbol, MODE_TICKSIZE);
   double ___dbl_allow_lost = StdFuncPips2Price(__str_symbol, _dbl_max_lost_pips);
   double ___dbl_lotstep = MarketInfo(__str_symbol, MODE_LOTSTEP);
   
   double ___dbl_normal_lotsize = 
}