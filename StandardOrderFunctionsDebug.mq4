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
#include "../ExpertAdviserBox/PriceRangeChecker.mqh"

input bool     using_trailing_stop_mode=true;
PriceRanges    *range=NULL;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   stoploss_pips=80.0;
   takeprofit_pips=30.0;
   trailing_stop_begin_pips=25.0;
   trailing_stop_step_pips=20.0;
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
   delete range;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!CheckPointer(range)) range=new PriceRanges(7,30,5,true);
   UpdateOrders();
   if(!CheckHolding()){
      //ストップロス・テイクプロフィットを設定する
      stoploss_pips=range.Get(7,(TimeHour(TimeCurrent()))%24,true,false)/10/_Point;
      takeprofit_pips=range.Get(2,(TimeHour(TimeCurrent()))%24,false,true)/10/_Point;
      trailing_stop_begin_pips=range.Get(1,TimeHour(TimeCurrent()),false,true)/10/_Point;
      trailing_stop_step_pips=range.Get(1,TimeHour(TimeCurrent()),false,true)/10/_Point;
      
      double cur_price=Close[0];
      double sfma_val=iMA(Symbol(),PERIOD_H1,6,0,MODE_SMA,PRICE_MEDIAN,0);
      double fma_val=iMA(Symbol(),PERIOD_H4,6,0,MODE_SMA,PRICE_MEDIAN,0);
      double sma_val=iMA(Symbol(),PERIOD_D1,6,0,MODE_SMA,PRICE_MEDIAN,0);
      if(cur_price<sfma_val&&sfma_val>fma_val&&fma_val>sma_val){
         SendBuyOrder(GetLots(stoploss_pips),true);
      }
      else if(cur_price>sfma_val&&sfma_val<fma_val&&fma_val<sma_val){
         SendSellOrder(GetLots(stoploss_pips),true);
      }
   }
  }
//+------------------------------------------------------------------+
