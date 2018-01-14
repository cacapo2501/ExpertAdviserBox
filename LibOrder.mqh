//+------------------------------------------------------------------+
//|                                              LibOrderManager.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict
//標準関数
#include "..\\ExpertAdviserBox\\LibStandardFunctions.mqh"
#include "..\\Include\\\\Arrays\\ArrayObj.mqh"
//+------------------------------------------------------------------+
//| OrderManagerクラス :                                             |
//| チケット、通貨ペア、価格の操作をカプセル化ための準備             |
//| 使い方：                                                         |
//| 1. コンストラクタ起動でOrderSendする。                           |
//| 2. 必要があればfModifyOrderで損切り価格・利食い価格を変更する。  |
//| 3. fSendCloseを実行して手仕舞いする。                            |
//| 注意：                                                           |
//| ・成り行きのみ                                                   |
//| ・ナンピンには対応しない。                                       |
//| ・部分決済も対応しない。                                         |
//+------------------------------------------------------------------+
class ClsOrder : public CObject{
   private:
      string __str_symbol; //通貨ペア
      int __int_command; //注文の種類
      int __int_slippage; //スリッページ
      int __int_magic; //マジックナンバー
      bool __bln_debug; //デバッグフラグ
      int __int_ticket; //チケット番号
      color __clr_close; //決済の矢印の色
      
   public:
      //コンストラクタ
      ClsOrder(string, int, int, double, double, double, int, color, bool);
      //デストラクタ
      ~ClsOrder();
      //決済する
      void fSendClose();
      //取引中か検定する
      bool fCheckHaving();
   
   protected: //デバッグが済んだらコメントアウトをはずす
      //注文を取得する
      bool fSelectOrder();
      //注文を修正する
      void fModifyOrder(double, double);
      //注文の価格変動をpipsで取得する
      double fGetPriceVarying();
   
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
ClsOrder::ClsOrder(string _str_symbol //通貨ペア
                                ,int _int_command //注文の種類
                                ,int _int_slippage //スリッページ
                                ,double _dbl_stoploss_pips //損切り幅(pips)
                                ,double _dbl_takeprofit_pips //利食い幅(pips)
                                ,double _dbl_lots //ロット数
                                ,int _int_magic = 0 //マジックナンバー
                                ,color _clr_arrow = clrNONE //取引時の矢印の色
                                ,bool _bln_debug = false //デバッグフラグ
                                 ){
   //***** プロパティを初期化する *****
   __str_symbol = _str_symbol; 
   __int_command = _int_command;
   __int_slippage = _int_slippage;
   __int_magic = _int_magic;
   __clr_close = _clr_arrow;
   __bln_debug = __bln_debug; 
   
   __int_ticket = -1;
   
   //***** プロパティの検定を行う *****
   //通貨ペア
   if(MarketInfo(__str_symbol, MODE_ASK) <= 0){
      //0なら通貨ペアは存在しないと判定
      Print("この通貨ペアは存在しません。");
      return;
   }
   
   //指定された通貨が取引可能か検定する
   if(!StdFuncIsMarketOrderable(__str_symbol)) return;
   
   //注文の種類
   if(__int_command != OP_BUY && __int_command != OP_SELL){
      //注文がOP_BUY、OP_SELL以外の場合は不正とする
      Print("このコマンドは使用できません");
      return;
   }
   
   //スリッページは自己責任とする
   
   //***** マジックナンバーの取得 *****
   if(_int_magic == 0){
      int ___int_max_magic = 0;
      
      //現在の取引から最大の番号を取得する
      for(int i = 0; i < OrdersTotal(); i++){
         //注文を選択する
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)){
            //マジックナンバーは最大？
            if(OrderMagicNumber() > ___int_max_magic){
               //マジックナンバーを更新する
               ___int_max_magic = OrderMagicNumber();
            }
         }
      }
      
      //過去の取引から最大の番号を取得する
      for(int i = 0; i < OrdersHistoryTotal(); i++){
         //注文を選択する
         if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)){
            //マジックナンバーは最大？
            if(OrderMagicNumber() > ___int_max_magic){
               //マジックナンバーを更新する
               ___int_max_magic = OrderMagicNumber();
            }
         }
      }
   
      //マジックナンバーに最大の値＋１をセットする
      __int_magic = ++___int_max_magic;
   }
   else{
      __int_magic = _int_magic;
   }
   //***** 価格の取得 *****
   double ___dbl_price = 0; //取引価格
   double ___dbl_stoploss_price = 0; //損切り価格
   double ___dbl_takeprofit_price = 0; //利食い価格
   if     (__int_command == OP_BUY){
      //買いの場合
      ___dbl_price = MarketInfo(__str_symbol, MODE_ASK);
      ___dbl_stoploss_price = ___dbl_price - StdFuncPips2Price(__str_symbol, _dbl_stoploss_pips);
      ___dbl_takeprofit_price = ___dbl_price + StdFuncPips2Price(__str_symbol, _dbl_takeprofit_pips);
   }
   else if(__int_command == OP_SELL){
      //売りの場合
      ___dbl_price = MarketInfo(__str_symbol, MODE_BID);
      ___dbl_stoploss_price = ___dbl_price + StdFuncPips2Price(__str_symbol, _dbl_stoploss_pips);
      ___dbl_takeprofit_price = ___dbl_price - StdFuncPips2Price(__str_symbol, _dbl_takeprofit_pips);
   }
   
   //求めた価格がマイナスor損切り幅・利食い幅が0？
   if(___dbl_stoploss_price < 0 || ___dbl_takeprofit_price < 0 ||
      _dbl_stoploss_pips <= 0   || _dbl_takeprofit_pips <= 0   ){
      Print("取引価格が不正です。");
      return;
   }
   
   //***** ロット数の取得 *****
   double ___dbl_lots = StdFuncNormalizeAsLots(_str_symbol, _dbl_lots);
   if(___dbl_lots <= 0){
      Print("ロット数が不正です。");
      return;
   }
   
   //***** 矢印の色の取得 *****
   if(_clr_arrow == clrNONE){
      if(_int_command == OP_BUY)  _clr_arrow = clrBlue;
      if(_int_command == OP_SELL) _clr_arrow = clrMagenta;
   }
   
   //確定したパラメータを出力する
   string ___str_debug_comment = "＜設定値＞";
   if(__bln_debug){
      ___str_debug_comment +=   "通貨ペア : " + __str_symbol;
      ___str_debug_comment += ", 取引の種類 : " + IntegerToString(__int_command);
      ___str_debug_comment += ", マジックナンバー : " + IntegerToString(__int_magic);
   }
   else{
      ___str_debug_comment = NULL;
   }
   
   //***** 注文する *****
   __int_ticket = OrderSend(__str_symbol, 
                            __int_command, 
                            ___dbl_lots, 
                            ___dbl_price, 
                            __int_slippage, 
                            ___dbl_stoploss_price, 
                            ___dbl_takeprofit_price, 
                            ___str_debug_comment, 
                            __int_magic, 
                            0, 
                            _clr_arrow);
   if(__int_ticket == -1){
     Print("取引送信に失敗しました。"); 
   }
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
ClsOrder::~ClsOrder(void){}
//+------------------------------------------------------------------+
//| 決済する                                                         |
//+------------------------------------------------------------------+
void ClsOrder::fSendClose(void){
   //取引していない場合はFalseを返す
   if(!fCheckHaving()) return;
   
   //この通貨は取り引き可能？
   if(!StdFuncIsMarketOrderable(__str_symbol)) return;
   
   //***** 価格を取得する *****
   double ___dbl_price = 0;
        if(__int_command == OP_BUY ) ___dbl_price = MarketInfo(__str_symbol, MODE_BID);
   else if(__int_command == OP_SELL) ___dbl_price = MarketInfo(__str_symbol, MODE_ASK);
   //コマンド不正時は処理がここに来ない
   
   //***** ロット数を取得する *****
   fSelectOrder();
   double ___dbl_lots = OrderLots();
   
   //決済する
   bool ___result = OrderClose(__int_ticket, ___dbl_lots, ___dbl_price, __int_slippage, __clr_close);
   
   //決済に成功した場合は、チケットナンバーをクリアする
   if(___result) __int_ticket = -1;
   return;
}
//+------------------------------------------------------------------+
//| 注文を選択する                                                   |
//+------------------------------------------------------------------+
bool ClsOrder::fSelectOrder(void){
   return OrderSelect(__int_ticket, SELECT_BY_TICKET);
}
//+------------------------------------------------------------------+
//| 取引中か検定する                                                 |
//+------------------------------------------------------------------+
bool ClsOrder::fCheckHaving(void){
   return (__int_ticket != -1);
}
//+------------------------------------------------------------------+
//| 注文を修正する                                                   |
//+------------------------------------------------------------------+
void ClsOrder::fModifyOrder(double _dbl_new_stoploss, double _dbl_new_takeprofit){
   //注文は存在する？
   if(__int_ticket == -1) return;
   if(!fSelectOrder())    return;
   
   //***** 修正に必要なパラメータを取得する *****
   //現在価格
   double ___dbl_price = 0;   //現在価格
        if(__int_command == OP_BUY)  ___dbl_price = MarketInfo(__str_symbol, MODE_ASK);
   else if(__int_command == OP_SELL) ___dbl_price = MarketInfo(__str_symbol, MODE_BID);
   
   //損切り価格
   double ___dbl_stoploss = StdFuncPips2Price(__str_symbol, _dbl_new_stoploss);
   //損切り幅が0以下？
   if(___dbl_stoploss < 0) return;
   //損切り価格を求める
   if     (__int_command == OP_BUY)  ___dbl_stoploss = ___dbl_price - ___dbl_stoploss;
   else if(__int_command == OP_SELL) ___dbl_stoploss = ___dbl_price + ___dbl_stoploss;
   //損切り価格が0以下？
   if(___dbl_stoploss < 0) return;
   
   //利食い価格
   double ___dbl_takeprofit = StdFuncPips2Price(__str_symbol, _dbl_new_takeprofit);
   //損切り幅が0以下？
   if(___dbl_takeprofit < 0) return;
   //損切り価格を求める
   if     (__int_command == OP_BUY)  ___dbl_takeprofit = ___dbl_price + ___dbl_takeprofit;
   else if(__int_command == OP_SELL) ___dbl_takeprofit = ___dbl_price - ___dbl_takeprofit;
   //損切り価格が0以下？
   if(___dbl_takeprofit < 0) return;
   
   //***** 注文の修正を送信する *****
   bool ___result = OrderModify(__int_ticket, ___dbl_price, ___dbl_stoploss, ___dbl_takeprofit, 0, clrGold);
}