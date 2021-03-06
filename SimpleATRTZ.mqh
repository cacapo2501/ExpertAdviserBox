//+------------------------------------------------------------------+
//|                                                  SimpleATRTZ.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
#include "../ExpertAdviserBox/StandardFunctions.mqh"
//+------------------------------------------------------------------+
//| ATROfTimeZoneを取得する                                          |
//+------------------------------------------------------------------+
class SimpleATRTZ{
   private:
      const string               _symbol;
      const int                  _timeframe;
      const int                  _period;
      const datetime             _get_from;
   public:
      SimpleATRTZ(const string,const int,const int,const datetime);
      ~SimpleATRTZ(void);
      double      GetCurrent(void);
      double      Get(const int);
      void        GetSection(double&[]);
};
//コンストラクタ
SimpleATRTZ::SimpleATRTZ(const string symbol,const int timeframe,const int unit_period,const datetime get_from=D'2015/01/01 0:00'):
   _symbol(symbol),_timeframe(timeframe),_period(unit_period),_get_from(get_from)
{}
//デストラクタ
SimpleATRTZ::~SimpleATRTZ(void){}
//取得関数
double SimpleATRTZ::GetCurrent(){ return Get(0); }
double SimpleATRTZ::Get(const int shift){
   //トゥルーレンジを計算するインデックス数を取得する
   int idx_begin=GetBar(_get_from,PERIOD_H1);
   int idx_terminate=_period;
   double val_sum=0;
   int cnt_sum=0;
   for(int idx=idx_terminate;idx<idx_begin&&cnt_sum<5;idx++){
      datetime dt_from=GetTime(idx,PERIOD_H1);
      datetime dt_to=GetTime(idx-_period,PERIOD_H1);
      datetime dt_shift=GetTime(shift,PERIOD_H1);
      if(TimeHour(dt_to)==TimeHour(dt_shift)){
         int idx_hi=iHighest(Symbol(),PERIOD_H1,MODE_HIGH,_period,idx);
         int idx_lo=iLowest (Symbol(),PERIOD_H1,MODE_LOW ,_period,idx);
         double val_hi=iHigh(Symbol(),PERIOD_H1,idx_hi);
         double val_lo=iLow (Symbol(),PERIOD_H1,idx_lo);
         val_sum+=val_hi-val_lo;
         cnt_sum++;
      }
   }
   
   return val_sum/cnt_sum;
}