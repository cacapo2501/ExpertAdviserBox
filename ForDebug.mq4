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
   SimpleOrderControl *soc = new SimpleOrderControl(Symbol(), OP_BUY, 0.1, 0, 20.0, 1.0, clrAqua, clrBlue);
   if(!soc.fInitializeSuccessed()){
      Sleep(10000);
   }
   
   delete soc;
   Sleep(10000);
   
   soc = new SimpleOrderControl(Symbol(), OP_SELL, 0.1, 0, 20.0, 1.0, clrMagenta, clrRed);
   if(!soc.fInitializeSuccessed()){
      Sleep(10000);
   }
   
   delete soc;
   ExpertRemove();
  }
//+------------------------------------------------------------------+
