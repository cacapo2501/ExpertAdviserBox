//+------------------------------------------------------------------+
//|                                                 SimpleZigZag.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property library
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict

#include "../ExpertAdviserBox/SimpleMA.mqh"
//+------------------------------------------------------------------+
//| ZigZagクラス                                                     |
//+------------------------------------------------------------------+
class SimpleZigZag{
   private:
      const string               _symbol;
      const int                  _timeframe;
      const int                  _depth;
      const int                  _deviation;
      const int                  _backstep;
   public:
      SimpleZigZag(const string,const int,const int,const int,const int);
      ~SimpleZigZag(void);
      double      GetCurrent(void);
      double      Get(const int);
      void        GetVertexIndex(int&[],const int);
};
//コンストラクタ
SimpleZigZag::SimpleZigZag(
         const string symbol
        ,const int timeframe
        ,const int depth
        ,const int deviation
        ,const int backstep
):
         _symbol(symbol)
        ,_timeframe(timeframe)
        ,_depth(depth)
        ,_deviation(deviation)
        ,_backstep(backstep)
{
  
}
//デストラクタ
SimpleZigZag::~SimpleZigZag(void){}
//現在値取得
double SimpleZigZag::GetCurrent(){
   return this.Get(0);
}
//指定したインデックスの値を取得
double SimpleZigZag::Get(const int index){
   return iCustom(_symbol,_timeframe,"ZigZag",_depth,_deviation,_backstep,0,index);
}
//範囲取得
void SimpleZigZag::GetVertexIndex(int &arrIdx[],const int count){
   //配列を初期化する
   ArrayResize(arrIdx,count*2);
   ArrayInitialize(arrIdx,EMPTY_VALUE);
   
   //頂点を検索する
   int get_count=0;           //取得済みの頂点数
   int first_vertex_type=0;   //最初の頂点の向き(V:-1、A:+1)
   for(int idx=0;idx<Bars-1;idx++){
      if(this.Get(idx)!=EMPTY_VALUE){
         arrIdx[get_count++]=idx;
      }
      if(get_count>=count*2) break;
   }
}