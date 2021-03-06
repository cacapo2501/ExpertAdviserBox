//+------------------------------------------------------------------+
//|                                                    SimpleRSI.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| RSIクラス                                                        |
//+------------------------------------------------------------------+
class SimpleRSI{
   private:
      const string               _symbol;
      const int                  _timeframe;
      const int                  _period;
      const ENUM_APPLIED_PRICE   _price;
   public:
      SimpleRSI(const string,const int,const int,const ENUM_APPLIED_PRICE);
      ~SimpleRSI(void);
      double      GetCurrent(void);
      double      Get(const int);
      void        GetSection(double&[],const int,const int);
};
//コンストラクタ
SimpleRSI::SimpleRSI(
         const string symbol
        ,const int timeframe
        ,const int period
        ,const ENUM_APPLIED_PRICE price
):
         _symbol(symbol)
        ,_timeframe(timeframe)
        ,_period(period)
        ,_price(price)
{
  
}
//デストラクタ
SimpleRSI::~SimpleRSI(void){}
//現在値取得
double SimpleRSI::GetCurrent(){
   return this.Get(0);
}
//指定したインデックスの値を取得
double SimpleRSI::Get(const int index){
   return iRSI(_symbol,_timeframe,_period,_price,index);
}
//範囲取得
void SimpleRSI::GetSection(double &arrResponse[],const int index_from,const int index_to){
   int i_size=index_to-index_from+1;
   ArrayResize(arrResponse,i_size);
   ArrayInitialize(arrResponse,EMPTY_VALUE);
   for(int idx=index_from;idx<=index_to;idx++){
      arrResponse[idx-index_from]=this.Get(idx);
   }
}