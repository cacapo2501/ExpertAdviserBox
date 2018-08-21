//+------------------------------------------------------------------+
//|                                                  MisterCloud.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict

#include "../Include/Arrays/ArrayObj.mqh"

input int magic = 10270;
input int segment_before = 5;
input int segment_after = 10;
input int preload = 985;
input int max_vertex_count = 200;
input int least_elements = 4;
input double search_range = 0.01;
input string prefix = "Mr.Cloud";
string prefix_check = prefix + "_Arrow";
string prefix_hline = prefix + "_HLine";
string prefix_label = prefix + "_Label";

#include "../ExpertAdviserBox/LibCZoneCloud.mqh"
#include "../ExpertAdviserBox/LibEasyOrder.mqh"

//--- Global Variables
VertexManager *manager_m15;
CSky          *sky_m15;
long my_id;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   int segment_period = segment_before + segment_after; 
   int segment_begin = 0;
   int preload_total = preload + segment_period;
   manager_m15=new VertexManager(Symbol(),PERIOD_M15, preload_total, segment_period, segment_begin, max_vertex_count);
   sky_m15 = new CSky(manager_m15, least_elements, search_range);
   sky_m15.Update();
   
   my_id = ChartID();
   
   ObjectsDeleteAll(ChartID(),prefix);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   delete sky_m15;
   delete manager_m15;
//---
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   sky_m15.Update();
   
   static bool last_state = false;
   static double last_price = 0;
   static double last_open_price = 0;
   double cur_price = iClose(Symbol(), PERIOD_CURRENT, 0);
   bool in_cloud = false;
   int cloud_number = 0;
   Print(sky_m15.Total());
   for(int i = 0; i < sky_m15.Total(); i++){
      CCloud *check = sky_m15.At(i);
      if(check._price_lo <= cur_price && cur_price <= check._price_hi){
         in_cloud = true;
         cloud_number = i;
      }
   }
   
   bool state_change = (last_state == in_cloud);
   bool ascending = (cur_price > last_price);
   bool descending = (cur_price < last_price);
   
   if(GetTicket(magic) == -1){
      if(state_change && !in_cloud /*&& CheckPointer(upper) && CheckPointer(lower)*/){
         /*
         if(ascending) SendBuy(magic, cur_price - lower._price_lo, upper._price_lo - cur_price);
         if(descending) SendSell(magic, upper._price_hi - cur_price, lower._price_hi - cur_price);
         //*/
      }
      
      if(GetTicket(magic) != -1){
         last_open_price = iClose(Symbol(), PERIOD_CURRENT, 0);
      }
   }
   
   last_price = cur_price;
   last_state = in_cloud;
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
