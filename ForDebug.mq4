//+------------------------------------------------------------------+
//|                                                     ForDebug.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

#include "..\ExpertAdviserBox\LibOrderManager.mqh"

int __slippage = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //SimpleOrderControlクラスは仕様の誤認識による計画倒れ。
   
   //OrderManagerクラス
   OrderManager *order = new OrderManager(OP_BUY, __slippage, Symbol(), 20.0, 5.0, 0.1, NULL);
   order.fSendInitializedOrder();
   order.fSendCloseAll();     //最初の決済←成功するはず
   
   order.fSendCloseAll();     //2回目の決済←失敗する
   delete order;
   
   order = new OrderManager(OP_SELL, __slippage, Symbol(), 20.0, 5.0, 0.0, NULL); //オーダーを作る（ロット数異常）
   order.fSendInitializedOrder();
   if(order.fSelectHoldingOrder()) order.fSendCloseAll();
   delete order;
   
   order = new OrderManager(OP_SELL, __slippage, Symbol(), 0.0, 5.0, 0.1, NULL); //オーダーを作る（損切り幅不正）
   order.fSendInitializedOrder();
   if(order.fSelectHoldingOrder()) order.fSendCloseAll();
   delete order;
   
   order = new OrderManager(OP_SELL, __slippage, Symbol(), 20.0, 0.0, 0.1, NULL); //オーダーを作る（利食い幅不正）
   order.fSendInitializedOrder();
   if(order.fSelectHoldingOrder()) order.fSendCloseAll();
   delete order;
   
   //強制停止
   ExpertRemove();
   
  }
