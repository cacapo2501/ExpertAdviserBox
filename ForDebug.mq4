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
   fClsOrderManagerDebugger(Symbol(), OP_BUY, 10.0, 1.0, 0.1, 0, clrNONE, true);    //正常・買い
   fClsOrderManagerDebugger(Symbol(), OP_SELL, 10.0, 1.0, 0.1, 1000, clrYellow);    //正常・売り
   
   fClsOrderManagerDebugger(Symbol() + "foo", OP_BUY, 10.0, 1.0, 0.1, 0, clrNONE);  //通貨ペア異常
   fClsOrderManagerDebugger(Symbol(), -1, 10.0, 1.0, 0.1, 0, clrNONE);              //取引種別異常
   fClsOrderManagerDebugger(Symbol(), OP_BUY, 0.0, 1.0, 0.1, 0, clrNONE);           //損切り幅異常
   fClsOrderManagerDebugger(Symbol(), OP_BUY, 10.0, 0, 0.1, 0, clrNONE);            //利食い幅異常
   fClsOrderManagerDebugger(Symbol(), OP_BUY, 100000.0, 1.0, 0.1, 0, clrNONE);      //損切り価格異常
   fClsOrderManagerDebugger(Symbol(), OP_SELL, 0.0, 100000.0, 0.1, 0, clrNONE);     //利食い価格異常
   fClsOrderManagerDebugger(Symbol(), OP_BUY, 10.0, 1.0, 0, 0, clrNONE);            //ロット数異常
   
   //強制停止
   ExpertRemove();
   
  }
//+------------------------------------------------------------------+
//| OrderManagerクラス                                               |
//+------------------------------------------------------------------+
void fClsOrderManagerDebugger(string _str_symbol, int _int_command, double _dbl_stoploss, double _dbl_takeprofit, double _dbl_lots, int _int_magic, color _clr_arrow, bool _bln_twice_closing = false){
   Print("*** デバッグ開始-OrderManager");
   ClsOrderManager *clorder = new ClsOrderManager(_str_symbol, _int_command, 0, _dbl_stoploss, _dbl_takeprofit, _dbl_lots, _int_magic, _clr_arrow, true);
   clorder.fSendClose();
   if(_bln_twice_closing) clorder.fSendClose();
   delete clorder;
   Print("*** デバッグ終了-OrderManager");
}