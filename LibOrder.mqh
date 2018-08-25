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
//+------------------------------------------------------------------+
//| 注文クラス                                                       |
//+------------------------------------------------------------------+
class COrder : public CObject{
   public:
      COrder(int, double, double, double);
      ~COrder(void);
      void        Buy(double, double, double);
};
//+------------------------------------------------------------------+
//| 注文管理クラス                                                   |
//+------------------------------------------------------------------+
class COrderManager : public CArrayObj{
   private:
      CIndicatorManager       *i_manager;       //指標管理クラス
      void     BuyNow(double);
      void     SellNow(double);
      void     CloseAllNow();
   public:
      COrderManager();
      ~COrderManager(void);
      void     Observe();
      void     Update();
};
//+------------------------------------------------------------------+
//| 注文管理クラス：コンストラクタ                                   |
//+------------------------------------------------------------------+
COrderManager::COrderManager(
               int      magic,                  //マジックナンバー
               int      slippage,               //スリッページ
               double   max_lots,               //最大ロット数
               CIndicatorManager *i_manager,    //インジケータオブジェクト
){
   
}
//+------------------------------------------------------------------+
//| 注文管理クラス：監視処理                                         |
//+------------------------------------------------------------------+
COrderManager::Observe(void){
   //注文の監視
   
   
   //指標の監視
   i_manager.ObserveAll();
}