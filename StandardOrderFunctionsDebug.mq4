//+------------------------------------------------------------------+
//|                                  StandardOrderFunctionsDebug.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict

#include "../ExpertAdviserBox/StandardOrderFunctions.mqh"

input bool     using_trailing_stop_mode=true;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   stoploss_pips=30.0;
   takeprofit_pips=15.0;
   trailing_stop_begin_pips=6.0;
   trailing_stop_step_pips=6.0;
   trailing_stop=using_trailing_stop_mode;
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
   UpdateOrders();
   if(!CheckHolding()){
      double cur_price=Close[0];
      double fma_val=iMA(Symbol(),PERIOD_CURRENT,5,0,MODE_SMA,PRICE_MEDIAN,0);
      double sma_val=iMA(Symbol(),PERIOD_CURRENT,12,0,MODE_SMA,PRICE_MEDIAN,0);
      if(cur_price>fma_val&&fma_val>sma_val){
         SendBuyOrder(0.1,false);
      }
      else if(cur_price<fma_val&&fma_val<sma_val){
         SendSellOrder(0.1,false);
      }
   }
  }
//+------------------------------------------------------------------+
