//+------------------------------------------------------------------+
//|                                                     SimpleMA.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
#include "../ExpertAdviserBox/StandardFunctions.mqh"

//+------------------------------------------------------------------+
//| 移動平均クラス                                                   |
//+------------------------------------------------------------------+
class SimpleMA{
   private:
      const string               _symbol;
      const int                  _timeframe;
      const int                  _period;
      const ENUM_APPLIED_PRICE   _price;
      const ENUM_MA_METHOD       _method;
   public:
      SimpleMA(const string,const int,const int,const ENUM_APPLIED_PRICE,const ENUM_MA_METHOD);
      ~SimpleMA(void);
      double      GetCurrent(void);
      double      Get(const int);
      void        GetSection(double&[],const int,const int);
};
//コンストラクタ
SimpleMA::SimpleMA(
         const string symbol
        ,const int timeframe
        ,const int period
        ,const ENUM_APPLIED_PRICE price
        ,const ENUM_MA_METHOD method=MODE_SMA
):
         _symbol(symbol)
        ,_timeframe(timeframe)
        ,_period(period)
        ,_price(price)
        ,_method(method)
{
  
}
//デストラクタ
SimpleMA::~SimpleMA(void){}
//現在値取得
double SimpleMA::GetCurrent(){
   return this.Get(0);
}
//指定したインデックスの値を取得
double SimpleMA::Get(const int index){
   return iMA(_symbol,_timeframe,_period,0,(ENUM_MA_METHOD)_method,(ENUM_APPLIED_PRICE)_price,index);
}
//範囲取得
void SimpleMA::GetSection(double &arrResponse[],const int index_from,const int index_to){
   int i_size=index_to-index_from+1;
   ArrayResize(arrResponse,i_size);
   ArrayInitialize(arrResponse,EMPTY_VALUE);
   for(int idx=index_from;idx<=index_to;idx++){
      arrResponse[idx-index_from]=this.Get(idx);
   }
}