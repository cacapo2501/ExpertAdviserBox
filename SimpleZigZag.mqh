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

#include "../ExpertAdviserBox/StandardFunctions.mqh"
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
      void        GetVertexIndex(int&[],const int);
   public:
      SimpleZigZag(const string,const int,const int,const int,const int);
      ~SimpleZigZag(void);
      double      GetCurrent(void);
      double      Get(const int);
      bool        GetVertexes(double&[],double&[],const int);
      bool        GetPrices(double&[],const int);
      bool        GetSpan(int&[],const int);
      bool        GetMovement(double&[],const int);
      int         GetCurrentDirection(void);
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
   for(int idx=0;idx<Bars-1;idx++){
      if(this.Get(idx)>0){
         arrIdx[get_count++]=idx;
      }
      if(get_count>=count*2) break;
   }
}
//頂点を取得する
bool SimpleZigZag::GetVertexes(double &arrMt[],double &arrVl[],const int max_vertexes){
   //頂点のインデックスを取得する
   int arrIdx[];
   GetVertexIndex(arrIdx,max_vertexes*2+1);
   //取得した頂点数が設定数に満たない場合はFalse回答
   if(arrIdx[max_vertexes*2]==EMPTY_VALUE) return false;
   
   //回答配列を初期化する
   ArrayResize(arrMt,max_vertexes);
   ArrayResize(arrVl,max_vertexes);
   ArrayInitialize(arrMt,EMPTY_VALUE);
   ArrayInitialize(arrVl,EMPTY_VALUE);
   
   //回答を設定する
   int cnt_mt=0,cnt_vl=0;     //設定数カウンタ 
   for(int idx=1; idx<=max_vertexes*2;idx++){
      if(this.Get(arrIdx[idx])==0) return false;
      if(this.Get(arrIdx[idx])>this.Get(arrIdx[idx-1])){
         //傾斜は右肩下がり
         arrVl[cnt_vl++]=this.Get(arrIdx[idx-1]);
      }
      else if(this.Get(arrIdx[idx])<this.Get(arrIdx[idx-1])){
         //傾斜は右肩上がり
         arrMt[cnt_mt++]=this.Get(arrIdx[idx-1]);
      }
   }
   
   return true;
}
//頂点のソート配列を取得する
bool SimpleZigZag::GetPrices(double &arrPrc[],const int count){
   //頂点のインデックスを取得する
   int arrIdx[];
   this.GetVertexIndex(arrIdx,count*2);
   
   //回答配列を初期化する
   ArrayResize(arrPrc,count*2);
   ArrayInitialize(arrPrc,EMPTY_VALUE);
   
   //回答を設定する
   for(int idx=0;idx<count*2;idx++){
      if(this.Get(arrIdx[idx])==0) return false;
      arrPrc[idx]=this.Get(arrIdx[idx]);
   }
   
   //回答を降順でソートする
   ArraySort(arrPrc,WHOLE_ARRAY,0,MODE_DESCEND);
   return true;
}
//頂点のピッチを求める
bool SimpleZigZag::GetSpan(int &arrSpan[],const int count){
   //配列を初期化する
   ArrayResize(arrSpan,count*2);
   ArrayInitialize(arrSpan,0);
   
   //頂点を取得する
   int arrVtx[];
   this.GetVertexIndex(arrVtx,count+1);
   
   //頂点同士の間隔を求める
   for(int idx=1;idx<=count*2;idx++){
      //頂点が取得しきれてなかったら処理失敗
      if(arrVtx[idx]==0) return false;
      //頂点間の期間を求める
      arrSpan[idx-1]=arrVtx[idx]-arrVtx[idx-1];
      //右肩下がりの時は-1を掛ける
      if(this.Get(arrVtx[idx])<this.Get(arrVtx[idx-1])){
         arrSpan[idx-1]*=-1;
      }
   }
   
   return true;
}
//頂点の変動高を求める
bool SimpleZigZag::GetMovement(double &arrHeight[],const int count){
   //配列を取得する
   ArrayResize(arrHeight,count*2);
   ArrayInitialize(arrHeight,0);
   
   //頂点の配列を取得する
   int arrVtx[];
   this.GetVertexIndex(arrVtx,count+1);
   
   //取得する頂点の数だけ繰り返す
   for(int idx=1;idx<=count*2;idx++){
      //頂点が取得できていない時はfalse回答
      if(arrVtx[idx]==0) return false;
      //隣り合う頂点の差分を求める
      arrHeight[idx-1]=this.Get(arrVtx[idx])-this.Get(arrVtx[idx-1]);
   }
   
   return true;
}
//現在の値動きの向きを取得する(1:上昇、-1:下降)
int SimpleZigZag::GetCurrentDirection(void){
   double arrVal[];     //値格納配列
   GetVertexIndex(arrVal,1);
   
   return arrVal[0]>arrVal[1]?1:-1;
}