//+------------------------------------------------------------------+
//|                                            PriceRangeChecker.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../ExpertAdviserBox/StandardFunctions.mqh"
#include "../ExpertAdviserBox/DebugFunctions.mqh"
//+------------------------------------------------------------------+
//| 価格遷移の幅を求めるクラス                                       |
//+------------------------------------------------------------------+
class PriceRanges{
   private:
      double arrRangeMax[][24];
      double arrRangeMin[][24];
      double GetRange(const int,const int,const int,const int);
      bool   CheckRegistHour(const int,const int,const int,const int);
   public:
      PriceRanges(const int,const int,const int,const bool);
      ~PriceRanges();
      double Get(const int,const int,const bool,const bool);
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
PriceRanges::PriceRanges(const int period,const int samples,const int ignorant,const bool debug){
   ArrayResize(arrRangeMax,period+1);
   ArrayResize(arrRangeMin,period+1);
   
   for(int cnt1=1;cnt1<=period;cnt1++){
      for(int cnt2=0;cnt2<24;cnt2++){
         arrRangeMax[cnt1][cnt2]=GetRange(cnt2,cnt1,ignorant,samples);
         arrRangeMin[cnt1][cnt2]=GetRange(cnt2,cnt1,samples-ignorant-1,samples);
      }
   }
   
   //データをファイルに出力する
   if(debug){
      int handle=FileOpen("PriceRangesData("+Symbol()+")_"+TimeToString(TimeCurrent(),TIME_DATE)+".csv", FILE_CSV|FILE_WRITE,",");
      
      //インデックスの出力
      string sLineIndex=NULL;
      for(int idx2=0;idx2<period;idx2++){
         sLineIndex+=","+IntegerToString(idx2);
      }
      FileWrite(handle,sLineIndex);
      
      //データ（最大）の出力
      for(int idx=0;idx<24;idx++){
         string sLineMax=IntegerToString(idx);
         for(int idx2=0;idx2<period;idx2++){
            sLineMax+=","+DoubleToString(arrRangeMax[idx2][idx],_Digits);
         }
         
         FileWrite(handle,sLineMax);
      }
      //データ最小の出力
      for(int idx=0;idx<24;idx++){
         string sLineMin=IntegerToString(idx);
         for(int idx2=0;idx2<period;idx2++){
            sLineMin+=","+DoubleToString(arrRangeMin[idx2][idx],_Digits);
         }
         
         FileWrite(handle,sLineMin);
      }
      FileClose(handle);
   }
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
PriceRanges::~PriceRanges(void){}
//+------------------------------------------------------------------+
//| 価格幅を求める                                                   |
//+------------------------------------------------------------------+
double PriceRanges::GetRange(const int hour,const int period,const int ignorant,const int samples){
   int iSampleCount=0;
   double arrRange[];
   
   ArrayResize(arrRange,samples);
   
   //samplesの回数だけ値を求める
   for(int idx=0;idx<Bars&&iSampleCount<samples;idx++){
      int current_hour=TimeHour(GetTime(idx));
      if(current_hour==(hour+period)%24&&GetTime(period+idx,PERIOD_H1)==GetTime(idx,PERIOD_H1)-60*period*60){
         double max_price=GetPrice(iHighest(Symbol(),PERIOD_H1,MODE_HIGH,period,idx),PRICE_HIGH,PERIOD_H1);
         double min_price=GetPrice(iLowest(Symbol(),PERIOD_H1,MODE_LOW,period,idx),PRICE_LOW,PERIOD_H1);
         
         arrRange[iSampleCount++]=max_price-min_price;
      }
   }
   
   //値をソートする
   ArraySort(arrRange,0,0,MODE_DESCEND);
   
   //値を取得する
   return arrRange[ignorant];
}
double PriceRanges::Get(const int period,const int hour,const bool max_flag,const bool min_flag){
   if(max_flag==min_flag) return -1;
   
   if(max_flag) return this.arrRangeMax[period][(int)NormalizeHour(hour)];
   if(min_flag) return this.arrRangeMin[period][(int)NormalizeHour(hour)];
   return -1;
} 
bool PriceRanges::CheckRegistHour(const int _idx,const int _get_hour,const int _bars_shift,const int _passed_minute){
   const datetime _terminate_time=GetTime(_idx,PERIOD_H1);
   const datetime _begin_time=GetTime(_idx-_bars_shift,PERIOD_H1);
   const int _param_passed_time=_passed_minute*60;
   const int _begin_hour=TimeHour(_begin_time);
   if(_terminate_time-_begin_time>_param_passed_time) return false;
   if(_get_hour!=_begin_hour) return false;
   
   return true;
}