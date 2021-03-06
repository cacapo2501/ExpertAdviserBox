//+------------------------------------------------------------------+
//|                                                        MARSI.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   4
//--- plot Buy
#property indicator_label1  "Buy"
#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Sell
#property indicator_label2  "Sell"
#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- plot Trend
#property indicator_label3  "Trend"
#property indicator_type3   DRAW_ARROW
#property indicator_color3  clrGold
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1
//--- plot Range
#property indicator_label4  "Range"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrLimeGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1
//--- input parameters
input int      ma_period=14;                 //MAの期間パラメータ
input int      check_ratio=400;              //MAを監視する期間
input int      allowable_reverse_ratio=50;   //逆行と見做さない戻り幅
//--- indicator buffers
double         BuyBuffer[];
double         SellBuffer[];
double         TrendBuffer[];
double         RangeBuffer[];
double         MABuffer[];
double         RSIBuffer[];
int            check_period;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   IndicatorBuffers(6);
   SetIndexBuffer(0,BuyBuffer);
   SetIndexBuffer(1,SellBuffer);
   SetIndexBuffer(2,TrendBuffer);
   SetIndexBuffer(3,RangeBuffer);
   SetIndexBuffer(4,MABuffer);
   SetIndexBuffer(5,RSIBuffer);
//--- setting a code from the Wingdings charset as the property of PLOT_ARROW
   PlotIndexSetInteger(0,PLOT_ARROW,159);
   PlotIndexSetInteger(1,PLOT_ARROW,159);
   
   check_period=ma_period*check_ratio/100;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   int ma_limit=rates_total-prev_calculated+1;     //MA算出区間
   int check_limit=rates_total-prev_calculated+1;  //最大最小算出期間
   if(prev_calculated==0){
      ma_limit-=ma_period;
      check_limit-=ma_period+check_period;
   }
   
   for(int idx=ma_limit-1;idx>=0;idx--){
      //MAを求める
      MABuffer[idx]=iMA(Symbol(),PERIOD_CURRENT,ma_period,0,MODE_SMA,PRICE_MEDIAN,idx);
   }
   
   for(int idx=check_limit-1;idx>=0;idx--){
      //最大・最小を検出する
      int idx_max=ArrayMaximum(MABuffer,check_period,idx);
      int idx_min=ArrayMinimum(MABuffer,check_period,idx);
      double val_max=MABuffer[idx_max];
      double val_min=MABuffer[idx_min];
      if(val_max==val_min) continue;
      double val_current=MABuffer[idx];
      double rat_reverse;  //逆行率
      
      int idx_for_rsi;   //RSIを求めるために使用するインデックスの開始位置
      if(idx_max<idx_min){
         //最高値が直近
         rat_reverse=(val_max-val_current)/(val_max-val_min);
         idx_for_rsi=rat_reverse>allowable_reverse_ratio/100.?idx_max:idx_min;
      }
      else{
         //最安値が直近
         rat_reverse=(val_current-val_min)/(val_max-val_min);
         idx_for_rsi=rat_reverse>allowable_reverse_ratio/100.?idx_min:idx_max;
      }
      RSIBuffer[idx]=iRSIOnArray(MABuffer,ArraySize(MABuffer),idx_for_rsi-idx,idx);
      
      if(RSIBuffer[idx]>80||RSIBuffer[idx]<20) TrendBuffer[idx]=RSIBuffer[idx]>50?1:-1;
      else                                     RangeBuffer[idx]=0;
      
      BuyBuffer[idx]=RSIBuffer[idx]/50-1;
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
