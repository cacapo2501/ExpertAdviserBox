//+------------------------------------------------------------------+
//|                                              LibOrderManager.mqh |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property strict

#include "..\\ExpertAdviserBox\\LibOrder.mqh"
#include "..\\Include\\\\Arrays\\ArrayObj.mqh"
//+------------------------------------------------------------------+
//| 機能：オーダーを管理する。                                       |
//|                                                                  |
//| 使い方：コンストラクタをOnInitで起動してインスタンスを作る。     |
//|         できたインスタンスで.addOrderして注文する。              |
//|         任意のタイミングで.closeOrderして決済する。              |
//|         建玉の状態は参照関数群を使用すること。                   |
//|         このインスタンスはOnDeinitで破棄すること。               |
//+------------------------------------------------------------------+
class ClsOrderManager{
   private :
      double __dbl_max_margin_ratio; //使用する証拠金の全証拠金に対する割合
      double __dbl_init_equity; //使用できる最大証拠金（初期値）
      double __dbl_last_equity; //前回更新時の有効証拠金
      int    __int_max_holding; //最大保有可能注文数
      
      bool   __bln_enlarge_margin; //使用する余剰金を増やすことを許可する
      bool   __bln_reduce_margin;  //使用する余剰金を減らすことを許可する
      double __dbl_last_lots; //前回注文時のロット数
      double __dbl_last_stoploss; //前回注文時の損切りPips
      double __dbl_last_takeprofit; //前回注文時の利食いPips
      
      int    __int_slippage; //スリッページ
      string __str_symbol; //注文種別
      CArrayObj *__car_orders; //注文を格納する
      
      void fUpdateMarginInformation(); //証拠金の状態を更新する
      void fUpdateArrayStatus(); //配列内の死んでいる注文を削除する
   public :
      bool initialized;  //初期化済みフラグ
      ClsOrderManager(double, bool, bool, int, int);      //コンストラクタ
      ~ClsOrderManager();     //デストラクタ
      void addOrder(int, bool, double, double, double);        //注文する（建玉を置く）
      void closeOrder();      //建玉を決済する
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
ClsOrderManager::ClsOrderManager(double _dbl_max_margin     //使用する余剰金の割合
                                ,bool _bln_enlarge_margin   //上昇方向に最大余剰金自動修正
                                ,bool _bln_reduce_margin    //下降方向に最大余剰金自動修正 
                                ,int  _int_max_holding = 10 //最大保有可能注文数
                                ,int _int_slippage = 0      //スリッページ
                                ){
   //フラグを初期化する
   initialized = false;
   
   //入力値を検定する
   //余剰金割合が使用できない値の場合、処理終了
   if(_dbl_max_margin <= 0.0 && _dbl_max_margin > 1) return;
   
   //プロパティを設定する
   __dbl_max_margin_ratio = _dbl_max_margin;
   __bln_enlarge_margin = _bln_enlarge_margin;
   __bln_reduce_margin = _bln_reduce_margin;
   __int_max_holding = _int_max_holding;
   __int_slippage = _int_slippage;
   
   //産出する必要のあるプロパティを設定する
   __dbl_init_equity = AccountInfoDouble(ACCOUNT_EQUITY) * _dbl_max_margin;
   
   //注文格納配列を初期化する
   __car_orders = new CArrayObj();
   
   //初期化完了
   //フラグを更新する
   initialized = true;
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
ClsOrderManager::~ClsOrderManager(void){
   //残っている注文を決済する
   while(__car_orders.Total() != 0){
      ClsOrder *___obj_order = __car_orders.At(__car_orders.Max());
      if(___obj_order == NULL) return;
      
      if(___obj_order.fCheckHaving()){
         ___obj_order.fSendClose();
      }
      delete ___obj_order;
      
      __car_orders.Delete(__car_orders.Max());
   }
}
//+------------------------------------------------------------------+
//| 注文する                                                         |
//+------------------------------------------------------------------+
void ClsOrderManager::addOrder(int _int_command, //注文の種類
                               bool _bln_use_last_param, //前回注文したパラメータと同じ値を使う
                               double _dbl_margin_ratio = 0, //使用する余剰金の全体に対する比率
                               double _dbl_stoploss_pips = 0, //損切りPips
                               double _dbl_takeprofit_pips = 0 //利食いPips
){
   double ___dbl_stoploss;
   double ___dbl_takeprofit;
   
   //有効注文数を取得する
   fUpdateArrayStatus();
   int ___int_count_at_start = __car_orders.Total(); //注文前の有効注文数
   //保有最大注文数に達していたら処理終了
   if(__int_max_holding <= ___int_count_at_start) return;
   
   //注文は前回と同じ？
   if(_bln_use_last_param){
      //前回の退避内容を復元する
      ___dbl_stoploss = __dbl_last_stoploss;
      ___dbl_takeprofit = __dbl_last_takeprofit;
   }
   else{
      //引数の内容を変数に設定する
      ___dbl_stoploss = _dbl_stoploss_pips;
      ___dbl_takeprofit = _dbl_takeprofit_pips;
   }
   
   //証拠金の状態を更新する
   fUpdateMarginInformation();
   
   //ロット数を求める
   double ___dbl_lots = __dbl_last_equity / MarketInfo(__str_symbol, MODE_MARGINREQUIRED) * _dbl_margin_ratio;
   
   //証拠金が足りなかったら処理終了
   if(!StdFuncCheckLots(__str_symbol, ___dbl_lots)){ return; }
   
   //注文する
   __car_orders.Add(new ClsOrder(__str_symbol, _int_command, __int_slippage, 
                                 ___dbl_stoploss, ___dbl_takeprofit, ___dbl_lots,
                                 0, clrNONE, false));
   //配列の状態を更新する
   fUpdateArrayStatus();
   int ___int_count_after_send = __car_orders.Total(); //注文完了後の有効注文数
   
   if(___int_count_after_send != ___int_count_at_start){
      //開始時と送信後で注文数が一致しない場合は注文成功とみなす
      //注文内容を退避する
      __dbl_last_stoploss = _dbl_stoploss_pips;
      __dbl_last_takeprofit = _dbl_takeprofit_pips;
   }
}
//+------------------------------------------------------------------+
//| 使用する証拠金額の情報を更新する                                 |
//+------------------------------------------------------------------+
void ClsOrderManager::fUpdateMarginInformation(void){
   double ___dbl_current_equity = AccountInfoDouble(ACCOUNT_EQUITY)
                                  * __dbl_max_margin_ratio;
   if(__dbl_last_equity == AccountInfoDouble(ACCOUNT_EQUITY)){
      return;
   }
   else if(__dbl_last_equity > AccountInfoDouble(ACCOUNT_EQUITY)){
      //有効証拠金が減っている場合
      __dbl_last_equity = ___dbl_current_equity;
   }
   else {
      //有効証拠金が増えている場合
      //証拠金額を増やす？
      if(__bln_enlarge_margin) __dbl_last_equity = ___dbl_current_equity;
      else                     __dbl_last_equity = MathMin(___dbl_current_equity, 
                                                           __dbl_init_equity);
   }
}
//+------------------------------------------------------------------+
//| 配列の健康状態を更新する                                         |
//+------------------------------------------------------------------+
void ClsOrderManager::fUpdateArrayStatus(void){
   for(int i = 0; i < __car_orders.Total(); i++){
      //注文を取得する
      ClsOrder *___obj_order = __car_orders.At(i);
      
      //注文のチケットが無効ならインスタンスを配列から削除する
      if(!___obj_order.fCheckHaving()){
         delete ___obj_order;
         __car_orders.Delete(i);
      } 
   }
}