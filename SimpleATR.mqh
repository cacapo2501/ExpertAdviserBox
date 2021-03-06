//+------------------------------------------------------------------+
//|                                                    SimpleATR.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| ATRクラス                                                        |
//+------------------------------------------------------------------+
class SimpleATR{
   private:
      const string               _symbol;
      const int                  _timeframe;
      const int                  _period;
   public:
      SimpleATR(const string,const int,const int);
      ~SimpleATR(void);
      double      GetCurrent(void);
      double      Get(const int);
      void        GetSection(double&[],const int,const int);
};
//コンストラクタ
SimpleATR::SimpleATR(
         const string symbol
        ,const int timeframe
        ,const int period
):
         _symbol(symbol)
        ,_timeframe(timeframe)
        ,_period(period)
{
  
}
//デストラクタ
SimpleATR::~SimpleATR(void){}
//現在値取得
double SimpleATR::GetCurrent(){
   return this.Get(0);
}
//指定したインデックスの値を取得
double SimpleATR::Get(const int index){
   return iATR(_symbol,_timeframe,_period,index);
}
//範囲取得
void SimpleATR::GetSection(double &arrResponse[],const int index_from,const int index_to){
   int i_size=index_to-index_from+1;
   ArrayResize(arrResponse,i_size);
   ArrayInitialize(arrResponse,EMPTY_VALUE);
   for(int idx=index_from;idx<=index_to;idx++){
      arrResponse[idx-index_from]=this.Get(idx);
   }
}
