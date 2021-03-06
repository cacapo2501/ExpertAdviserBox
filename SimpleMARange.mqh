//+------------------------------------------------------------------+
//|                                                SimpleMARange.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
#include "../ExpertAdviserBox/StandardFunctions.mqh"

//+------------------------------------------------------------------+
//| 移動平均帯クラス                                                 |
//+------------------------------------------------------------------+
class SimpleMARange{
   private:
      const string               _symbol;
      const int                  _timeframe;
      const string               _periods;
      const int                  _signal_slowing1;
      const int                  _signal_slowing2;
      const int                  _signal_slowing3;
   public:
      SimpleMARange(const string,const int,const string,const int,const int,const int);
      ~SimpleMARange(void);
      double      GetCurrentValue(void);
      double      GetValue(const int);
      void        GetValueSection(double&[],const int,const int);
      double      GetSignal(const int);
      bool        IsAscending(const int);
      bool        IsMin(const int,const int);
};
//コンストラクタ
SimpleMARange::SimpleMARange(
         const string symbol
        ,const int timeframe
        ,const string periods
        ,const int signal_slowing1
        ,const int signal_slowing2
        ,const int signal_slowing3
):
         _symbol(symbol)
        ,_timeframe(timeframe)
        ,_periods(periods)
        ,_signal_slowing1(signal_slowing1)
        ,_signal_slowing2(signal_slowing2)
        ,_signal_slowing3(signal_slowing3)
{
  
}
//デストラクタ
SimpleMARange::~SimpleMARange(void){}
//現在値取得
double SimpleMARange::GetCurrentValue(){
   return this.GetValue(0);
}
//指定したインデックスの値を取得
double SimpleMARange::GetValue(const int index){
   return iCustom(_symbol,_timeframe,"MARange",_periods,_signal_slowing1,_signal_slowing2,_signal_slowing3,0,index);
}
//範囲取得
void SimpleMARange::GetValueSection(double &arrResponse[],const int index_from,const int index_to){
   int i_size=index_to-index_from+1;
   ArrayResize(arrResponse,i_size);
   ArrayInitialize(arrResponse,EMPTY_VALUE);
   for(int idx=index_from;idx<=index_to;idx++){
      arrResponse[idx-index_from]=this.GetValue(idx);
   }
}
//現在シグナル取得
double SimpleMARange::GetSignal(const int index){
   return iCustom(_symbol,_timeframe,"MARange",_periods,_signal_slowing1,_signal_slowing2,_signal_slowing3,1,index);
}
//上昇中確認
bool SimpleMARange::IsAscending(const int index){
   return this.GetValue(index)>this.GetSignal(index);
}
//最小値確認
bool SimpleMARange::IsMin(const int begin,const int terminate){
   double target_val=this.GetValue(begin);
   for(int idx=begin+1;idx<=terminate;idx++){
      if(target_val>this.GetValue(idx)) return false;
   }
   
   return true;
}