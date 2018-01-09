//+------------------------------------------------------------------+
//|                                               LibLotsManager.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

//+------------------------------------------------------------------+
//| このソースの目的: ポジションサイズ管理を行う。直近の損失から適切 |
//|                   なポジションサイズを超えないようにロット数を   |
//|                   返す。                                         |
//+------------------------------------------------------------------+
class LotsManager{
   private:
      double _dbl_max_margin;     //余剰金全額に対するマネジメントする金額の割合
      string _str_symbol;         //このクラスが扱う通貨ペア
      bool   _bln_allow_compound;   //複利運用を許可する
      double _dbl_max_lost_ratio;   //最大損失額の全体に占める割合
      double _dbl_adding_ratio;     //利益に対する最大余剰金の増分の比率
      bool fIsMaxMarginEnable();    //最大余剰金は適切か検定する
   public:
      LotsManager(double, string, bool);     //コンストラクタ
      ~LotsManager();    //デストラクタ
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
LotsManager::LotsManager(double __dbl_max_margin, string __str_symbol, bool __bln_allow_compound = true){
   //変数を初期化する
   _dbl_max_margin = __dbl_max_margin;
   _str_symbol     = __str_symbol;
   _bln_allow_compound = __bln_allow_compound;
   
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
   return (_dbl_max_margin > 0) && (_dbl_max_margin <= 1);
}