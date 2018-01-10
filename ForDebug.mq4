//+------------------------------------------------------------------+
//|                                                     ForDebug.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

#include "..\ExpertAdviserBox\LibSimpleOrderControl.mqh"
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
//---
   SimpleOrderControlDebugger(OP_BUY,  0.1, 10.0, 20.0, clrAqua, clrBlue);     //正常（買い）
   SimpleOrderControlDebugger(OP_SELL, 0.1, 10.0, 20.0, clrAqua, clrBlue);     //正常（売り）
   
   SimpleOrderControlDebugger(OP_BUY,  0,   10.0, 20.0, clrWhite, clrBlack);   //ロット数が不正
   SimpleOrderControlDebugger(OP_BUY,  0.1, 0,    20.0, clrWhite, clrBlack);   //損切り幅が不正
   SimpleOrderControlDebugger(OP_BUY,  0.1, 10.0, 0,    clrWhite, clrBlack);   //利食い幅が不正
   
   //オーダーの確認(0になること)
   while(OrderLots() != 0);
   
   //強制停止
   ExpertRemove();
   
  }
//+------------------------------------------------------------------+
//| SimpleOrderControllのデバッガー                                  |
//+------------------------------------------------------------------+
void SimpleOrderControlDebugger(int _int_command,              //注文方向
                                double _dbl_lots,              //ロット数
                                double _dbl_stoploss,          //損切り幅(pips)
                                double _dbl_takeprofit,        //利食い幅(pips)
                                color _clr_open = clrWhite,    //注文時の矢印の色
                                color _clr_close = clrBlack    //決済時の矢印の色
                                ){
   SimpleOrderControl *soc = new SimpleOrderControl(Symbol(), _int_command, _dbl_lots, 0, _dbl_stoploss, _dbl_takeprofit, _clr_open, _clr_close);
   delete soc;
}
