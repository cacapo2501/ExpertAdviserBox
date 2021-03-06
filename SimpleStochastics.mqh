//+------------------------------------------------------------------+
//|                                            SimpleStochastics.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
#include "../ExpertAdviserBox/StandardFunctions.mqh"

//+------------------------------------------------------------------+
//| ストキャスティクスクラ                                           |
//+------------------------------------------------------------------+
class SimpleStochastics{
   private:
      const string               _symbol;
      const int                  _timeframe;
      const int                  _k_period;
      const int                  _d_period;
      const int                  _slowing_period;
   public:
      SimpleStochastics(const string,const int,const int,const int,const int);
      ~SimpleStochastics(void);
      double      GetCurrent(void);
      double      GetMain(const int);
      void        GetMainSection(double&[],const int,const int);
      double      GetSignal(const int);
      bool        IsGoldenCrossing(const int,const double,const int);
      bool        IsDeadCrossing(const int,const double,const int);
};
//コンストラクタ
SimpleStochastics::SimpleStochastics(
         const string symbol
        ,const int timeframe
        ,const int k_period
        ,const int d_period
        ,const int slowing_period
):
         _symbol(symbol)
        ,_timeframe(timeframe)
        ,_k_period(k_period)
        ,_d_period(d_period)
        ,_slowing_period(slowing_period)
{
  
}
//デストラクタ
SimpleStochastics::~SimpleStochastics(void){}
//現在値取得
double SimpleStochastics::GetCurrent(){
   return this.GetMain(0);
}
//指定したインデックスの値を取得
double SimpleStochastics::GetMain(const int index){
   return iStochastic(_symbol,_timeframe,_k_period,_d_period,_slowing_period,MODE_SMA,STO_LOWHIGH,MODE_MAIN,index);
}
//指定したインデックスのシグナル値を取得
double SimpleStochastics::GetSignal(const int index){
   return iStochastic(_symbol,_timeframe,_k_period,_d_period,_slowing_period,MODE_SMA,STO_LOWHIGH,MODE_SIGNAL,index);
}
//指定したインデックス区間の値を配列で取得
void SimpleStochastics::GetMainSection(double &arrRes[],const int idx_from,const int idx_to){
   int i_size=idx_to-idx_from+1;
   ArrayResize(arrRes,i_size);
   
   for(int idx=0;idx<i_size;idx++){
      arrRes[idx]=GetMain(idx+idx_from);
   }
}
//ゴールデンクロス検知
bool SimpleStochastics::IsGoldenCrossing(const int index,const double ignorant_level,const int shift=3){
   double ignorant_reverse_level=100-ignorant_level;
   double main_current=this.GetMain(index);
   double signal_current=this.GetSignal(index);
   double main_old=this.GetMain(index+shift);
   double signal_old=this.GetSignal(index+shift);
   
   //メインが無視レベルを超えている場合はFalse回答する
   if(main_current<ignorant_level){
      return false;
   }
   //ゴールデンクロスを検出する
   if((main_current-signal_current>0)&&(main_old-signal_old<=0)) return true;
   return false;
}
//デッドクロス検知
bool SimpleStochastics::IsDeadCrossing(const int index,const double ignorant_level,const int shift=3){
   double ignorant_reverse_level=100-ignorant_level;
   double main_current=this.GetMain(index);
   double signal_current=this.GetSignal(index);
   double main_old=this.GetMain(index+shift);
   double signal_old=this.GetSignal(index+shift);
   
   //メインが規定値を無視レベルを超えていたらFalseを回答する
   if(main_current>ignorant_reverse_level){
      return false;
   }
   //デッドクロスを検出する
   if((main_current-signal_current<0)&&(main_old-signal_old>=0)) return true;
   return false;
}