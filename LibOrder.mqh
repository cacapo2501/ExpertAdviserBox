//+------------------------------------------------------------------+
//|                                                     LibOrder.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../Include/Arrays/ArrayObj.mqh"
#include "../ExpertAdviserBox/LibIndicator.mqh"
//---列挙
enum ENUM_MODIFY_POLICY{
   POLICY_NONE,
   POLICY_TRAILING,
};
//+------------------------------------------------------------------+
//| 注文クラス                                                       |
//+------------------------------------------------------------------+
class COrder : public CObject{
   private:
      int      _ticket;
      int      _slippage;
      int      type;
      CIndicator *_ind;
   public:
      COrder(string,int,double,int,double,double,string,int,color);
      ~COrder(void);
      void     Update();
      void     Observe();
      bool     Having();
};
//+------------------------------------------------------------------+
//| 注文管理クラス                                                   |
//+------------------------------------------------------------------+
class COrderManager : public CArrayObj{
   private:
      CArrayObj   *i_manager;       //指標オブジェクト配列
      string      _symbol;           //通貨ペア名
      double      _max_lots;
      int         _slippage;
      double      _stoploss;
      double      _takeprofit;
      int         _magic;
      void        BuyNow(double);
      void        SellNow(double);
      void        CloseAllNow();
   public:
      COrderManager(int,int,double);
      ~COrderManager(void);
      void     Observe();
      void     Update();
      void     SetPolicy(int);
};
//+------------------------------------------------------------------+
//| 注文クラス：コンストラクタ                                       |
//+------------------------------------------------------------------+
COrder::COrder(string symbol        //通貨名
              ,int    operation     //種別
              ,double lots          //ロット数
              ,int    slippage      //スリッページ
              ,double stoploss      //損切り幅
              ,double takeprofit    //利食い幅
              ,string comment       //コメント
              ,int    magic         //マジックナンバー
              ,color  arrow_color   //矢印の色
){
   //ここにパラメータの検定処理を追加する
   
   //注文送信処理
   int success = -1;
   while(success == -1){
   if(operation == OP_BUY){
         success = OrderSend(symbol, operation,lots,Ask,slippage,Ask-stoploss,Ask+takeprofit,comment,magic,0,arrow_color); 
      }
      else{
         success = OrderSend(symbol, operation,lots,Bid,slippage,Bid+stoploss,Bid-takeprofit,comment,magic,0,arrow_color);
      }
   }
}
//+------------------------------------------------------------------+
//| 注文クラス：デストラクタ                                         |
//+------------------------------------------------------------------+
COrder::~COrder(void){
   bool success = false;
   while(!success){
      success = OrderClose(_ticket,OrderLots(),OrderClosePrice(),_slippage,_ind.GetCloseColor());
   }
}
//+------------------------------------------------------------------+
//| 注文管理クラス：コンストラクタ                                   |
//+------------------------------------------------------------------+
COrderManager::COrderManager(
               int         magic,                  //マジックナンバー
               int         slippage,               //スリッページ
               double      max_lots,               //最大ロット数
){
   
}
//+------------------------------------------------------------------+
//| 注文管理クラス：監視処理                                         |
//+------------------------------------------------------------------+
COrderManager::Observe(void){
   //注文の監視
   for(int i = this.Total() - 1; i >= 0; i--){
      COrder *order = this.At(i);
      if(CheckPointer(order)){
         order.Observe();
         if(!order.Having()){
            this.Delete(i);
         }
      }
   }
   
   //指標の監視
   for(int i = i_manager.Total() - 1; i >= 0; i--){
      CIndicator *indicator = i_manager.At(i);
      if(CheckPointer(indicator)){
         COrder *order = NULL;    //注文オブジェクト
         //買い注文する？
         if(indicator.ObserveOrderBuy()){
            order = new COrder(_symbol,OP_BUY,_max_lots,_slippage,_stoploss,_takeprofit,indicator.GetComment(),_magic,indicator.GetColor(OBS_ORDERBUY));
         }
         //売り注文する？
         if(indicator.ObserveOrderSell()){
            order = new COrder(_symbol,OP_SELL,_max_lots,_slippage,_stoploss,_takeprofit,indicator.GetComment(),_magic,indicator.GetColor(OBS_ORDERSELL));
         }
         //注文成立したなら管理配列に追加
         if(CheckPointer(order) && order.Having()){
            this.Add(order);
         }
         else{
            delete order;
         }
      }
   }
}
//+------------------------------------------------------------------+
//| 注文管理クラス：更新処理                                         |
//+------------------------------------------------------------------+
COrderManager::Update(void){
   //指標の更新
   for(int i = i_manager.Total() - 1; i >= 0; i--){
      CIndicator *indicator = i_manager.At(i);
      if(CheckPointer(indicator)){
         indicator.Update();
      }
   }
}