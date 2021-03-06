//+------------------------------------------------------------------+
//|                                                    LibCTrend.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../ExpertAdviserBox/LibCVertex.mqh"
//+------------------------------------------------------------------+
//| トレンドラインクラス                                             |
//+------------------------------------------------------------------+
class CTrend:public CObject{
   private:
      string  _symbol;
      CVertex *_vertex1;
      CVertex *_vertex2;
      string  _name;
      bool    CheckVertexExists();
   public:
      CTrend(void);
      ~CTrend(void);
      void SetValue(string,string,int,CVertex*,CVertex*);
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
CTrend::CTrend(void){
   _symbol=NULL;
   _vertex1=NULL;
   _vertex2=NULL;
   _name=NULL;
}
//+------------------------------------------------------------------+
//| デストラクタ                                                                 |
//+------------------------------------------------------------------+
CTrend::~CTrend(void){
   ObjectDelete(ChartID(),_name);
   delete _vertex1;
   delete _vertex2;
}
//+------------------------------------------------------------------+
//| 値を設定する                                                     |
//+------------------------------------------------------------------+
void CTrend::SetValue(string symbol,string name,int clr_trend,CVertex *vertex1,CVertex *vertex2){
   _symbol=symbol;
   _name=name;
   _vertex1=vertex1;
   _vertex2=vertex2;
   
   if(CheckVertexExists()){
      ObjectCreate(ChartID(),_name,OBJ_TREND,0,_vertex1.GetTime(),_vertex1.GetPrice(),
                                               _vertex2.GetTime(),_vertex2.GetPrice());
      ObjectSetInteger(ChartID(),_name,OBJPROP_COLOR,clr_trend);
   }
}
//+------------------------------------------------------------------+
//| 頂点が設定されているか検定する                                   |
//+------------------------------------------------------------------+
bool CTrend::CheckVertexExists(void){
   return CheckPointer(_vertex1)&&CheckPointer(_vertex2);
}