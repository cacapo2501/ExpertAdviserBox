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
      double __dbl_max_margin;     //余剰金全額に対するマネジメントする金額の割合
      string __str_symbol;         //このクラスが扱う通貨ペア
      bool   __bln_allow_compound;   //複利運用を許可する
      double __dbl_max_lost_ratio;   //最大損失額の全体に占める割合
      bool fIsMaxMarginEnable();    //最大余剰金は適切か検定する
   public:
      LotsManager(string, double, double, bool);     //コンストラクタ
      ~LotsManager();    //デストラクタ
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
LotsManager::LotsManager(string _str_symbol, double _dbl_max_lost_ratio, double _dbl_max_margin = 1, bool _bln_allow_compound = true){
   //変数を初期化する
   __dbl_max_margin = _dbl_max_margin;
   __str_symbol     = _str_symbol;
   __bln_allow_compound = _bln_allow_compound;
   __dbl_max_lost_ratio = _dbl_max_lost_ratio;
   
   //通貨ペアは存在する組み合わせ？
   //StdFuncを使う
   
   //最大余剰金は口座の余剰金以内？
   if(!fIsMaxMarginEnable()) return;
   
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
LotsManager::~LotsManager(){

}
//+------------------------------------------------------------------+
//| 最大余剰金検定                                                   |
//+------------------------------------------------------------------+
bool LotsManager::fIsMaxMarginEnable(void){
   
   return (__dbl_max_margin > 0) && (__dbl_max_margin <= 1);
}