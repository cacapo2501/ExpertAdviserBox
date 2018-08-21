//+------------------------------------------------------------------+
//|                                                   LibCVertex.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../Include/Arrays/ArrayObj.mqh"
//+------------------------------------------------------------------+
//| Enumerations                                                     |
//+------------------------------------------------------------------+
enum ENUM_VERTEX_TYPE
  {
   TYPE_MOUNTAIN=1,
   TYPE_VALLEY=2,
  };
enum ENUM_SORT_MODE{
   SORT_BY_TIME = 1,
   SORT_BY_PRICE = 2,
};
//+------------------------------------------------------------------+
//| Vertex Class                                                     |
//+------------------------------------------------------------------+
class Vertex : public CObject
  {
private:
   string            _symbol;
   int               _timeframe;
   int               _type;
   datetime          _time;
   datetime          _created;
public:
                     Vertex(string,int,int,datetime);
                     Vertex(string,int,double);
                    ~Vertex(void);
   bool              IsVertex(int, int);
   datetime          GetTime(void) const { return _time; }
   double            GetPrice(void) const;
   datetime          GetCreatedTime(void) const { return _created; }
   int               Compare(const CObject*,const int) const;
  };
//+------------------------------------------------------------------+
//| Vertex Manager Class                                             |
//+------------------------------------------------------------------+
class VertexManager : public CArrayObj
  {
private:
   string            _symbol;
   int               _timeframe;
   datetime          _last_update;
   int               _max_count;
   int               _segment_period;
   int               _segment_offset;
public:
                     VertexManager(string,int,int,int,int,int);
                    ~VertexManager(void);
   void              Update();
   void              Evaluate(datetime);
  };
//+------------------------------------------------------------------+
//| Vertex Class : Constructor                                       |
//+------------------------------------------------------------------+
Vertex::Vertex(string symbol,int timeframe,int type,datetime time)
  {
   _symbol=symbol;
   _timeframe=timeframe;
   _type=type;
   _time=time;
   _created=TimeCurrent();
  }
//+------------------------------------------------------------------+
//| Vertex Class : Destructor                                        |
//+------------------------------------------------------------------+
Vertex::~Vertex(void){}
//+------------------------------------------------------------------+
//| Vertex Class : Is Vertex                                         |
//+------------------------------------------------------------------+
bool Vertex::IsVertex(int period, int offset){
   int idx_current = iBarShift(_symbol, _timeframe, _time);
   int bar_begin = idx_current - offset;
   if(bar_begin < 0) return false;
   
   if(_type==TYPE_MOUNTAIN){
      int idx_highest = iHighest(_symbol, _timeframe, MODE_HIGH, period, bar_begin);
      return idx_highest == idx_current;
   }
   else{
      int idx_lowest = iLowest (_symbol, _timeframe, MODE_LOW , period, bar_begin);
      return idx_lowest == idx_current;
   }
}
//+------------------------------------------------------------------+
//| Vertex Class : Get Price                                         |
//+------------------------------------------------------------------+
double Vertex::GetPrice(void) const{
   int bar = iBarShift(_symbol, _timeframe, _time);
   if(_type == TYPE_MOUNTAIN)
      return iHigh(_symbol, _timeframe, bar);
   else
      return iLow(_symbol, _timeframe, bar);
}
//+------------------------------------------------------------------+
//| Vertex Class : Compare                                           |
//+------------------------------------------------------------------+
int Vertex::Compare(const CObject *node,const int mode = 0) const{
   const Vertex *vtx = node;
   if(mode == SORT_BY_PRICE){
      double result = this.GetPrice() - vtx.GetPrice();
      if(result == 0) return 0;
      return (int)(result / MathAbs(result));
   }
   if(mode == SORT_BY_TIME){
      long result = this.GetTime() - vtx.GetTime();
      if(result == 0) return 0;
      return result > 0 ? 1 : -1;
   }
   return 0;
}
//+------------------------------------------------------------------+
//| Vertex Manager Class : Constructor                               |
//+------------------------------------------------------------------+
VertexManager::VertexManager(string symbol,int timeframe, int preload_bars, int segment_period, int segment_offset,int max_count)
  {
   _symbol=symbol;
   _timeframe=timeframe;
   _last_update= iTime(Symbol(), PERIOD_CURRENT, preload_bars);
   _segment_period = segment_period;
   _segment_offset = segment_offset;
   _max_count = max_count;
  }
//+------------------------------------------------------------------+
//| Vertex Manager Class : Destructor                                |
//+------------------------------------------------------------------+
VertexManager::~VertexManager(){}
//+------------------------------------------------------------------+
//| Vertex Manager Class : Update                                    |
//+------------------------------------------------------------------+
void VertexManager::Update()
  {
   int bar_updated = iBarShift(_symbol, _timeframe, _last_update);
   int idx_current = iBarShift(_symbol, _timeframe, TimeCurrent());
   if(bar_updated > idx_current){
      for(int i = bar_updated - 1; i >= 0; i--){
         Evaluate(iTime(_symbol, _timeframe, i + _segment_offset));
      }
      
      this.Sort(SORT_BY_TIME);
      if(this.Total() > _max_count){
         int delete_size = this.Total() - _max_count;
         this.DeleteRange(0, delete_size);
      }
      
      Print("VTX_CNT:", this.Total());
      _last_update = iTime(_symbol, _timeframe, 0);
   }
  }
//+------------------------------------------------------------------+
//| Vertex Manager Class : Evaluate                                  |
//+------------------------------------------------------------------+
void VertexManager::Evaluate(datetime time){
   Vertex *cand_mt = new Vertex(_symbol, _timeframe, TYPE_MOUNTAIN, time);
   Vertex *cand_vl = new Vertex(_symbol, _timeframe, TYPE_VALLEY, time);
   
   if(cand_mt.IsVertex(_segment_period, _segment_offset)) 
      this.Add(cand_mt); 
   else 
      delete cand_mt;
   if(cand_vl.IsVertex(_segment_period, _segment_offset)) 
      this.Add(cand_vl); 
   else 
      delete cand_vl;
}
