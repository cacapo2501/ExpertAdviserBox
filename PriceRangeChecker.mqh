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
         Print("RangeMax["+IntegerToString(cnt2)+","+IntegerToString(cnt1)+"]="+DoubleToString(arrRangeMax[cnt1][cnt2]));
      }
   }
   
   //データをファイルに出力する
   if(debug){
      int handle=FileOpen("PriceRangesData.csv", FILE_CSV|FILE_WRITE,",");
      for(int idx=0;idx<24;idx++){
         string sLineMax="RangeMax["+IntegerToString(idx)+"]=";
         for(int idx2=0;idx2<period;idx2++){
            sLineMax+=","+DoubleToString(arrRangeMax[idx2][idx],_Digits);
         }
         
         FileWrite(handle,sLineMax);
      }
      
      for(int idx=0;idx<24;idx++){
         string sLineMin="RangeMin["+IntegerToString(idx)+"]=";
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
      if((current_hour+period)%24==hour&&GetTime(period+idx,PERIOD_H1)==GetTime(idx,PERIOD_H1)-60*period*60){
         double max_price=GetPrice(iHighest(Symbol(),PERIOD_H1,MODE_HIGH,period,idx),PRICE_HIGH,PERIOD_H1);
         double min_price=GetPrice(iLowest(Symbol(),PERIOD_H1,MODE_LOW,period,idx),PRICE_LOW,PERIOD_H1);
         
         arrRange[iSampleCount++]=max_price-min_price;
      }
   }
   
   PrintOriginal("RangeAray",arrRange);
   
   //値をソートする
   ArraySort(arrRange,0,0,MODE_DESCEND);
   
   //値を取得する
   return arrRange[ignorant];
}
double PriceRanges::Get(const int period,const int hour,const bool max_flag,const bool min_flag){
   if(max_flag==min_flag) return -1;
   
   if(max_flag) return this.arrRangeMax[period][hour];
   if(min_flag) return this.arrRangeMin[period][hour];
   return -1;
} 