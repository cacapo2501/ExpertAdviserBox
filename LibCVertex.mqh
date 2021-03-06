//+------------------------------------------------------------------+
//|                                                   LibCVertex.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../Include/Object.mqh"
//+------------------------------------------------------------------+
//| 頂点クラス                                                       |
//+------------------------------------------------------------------+
class CVertex:public CObject{
   private:
      string _symbol;         //通貨ペア
      datetime _time;         //時間
      double _price;          //価格
      string _name;           //オブジェクト名
      void DrawArrow(int);                            //矢印を描画する
   public:
      CVertex(void);
      ~CVertex(void);
      void SetValue(string,string,int,datetime,double);  //値を設定する
      double GetPrice();                                 //価格を取得する
      datetime GetTime();                                //時間を取得する
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
CVertex::CVertex(void){
   _symbol=NULL;
   _time=0;
   _price=0;
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
CVertex::~CVertex(void){
   ObjectDelete(ChartID(),_name);
}
//+------------------------------------------------------------------+
//| パラメータを設定する                                             |
//+------------------------------------------------------------------+
void CVertex::SetValue(string symbol,string name,int clr_arrow,datetime time,double price){
   this._symbol=symbol;
   this._name=name;
   this._time=time;
   this._price=price;
   DrawArrow(clr_arrow);
}
//+------------------------------------------------------------------+
//| オブジェクトを描画する                                           |
//+------------------------------------------------------------------+
void CVertex::DrawArrow(int clr_arrow=0xFFFFF){
   if(_symbol!=NULL){
      ObjectCreate(ChartID(),_name,OBJ_ARROW,0,_time,_price);
      ObjectSetInteger(ChartID(),_name,OBJPROP_COLOR,clr_arrow);
   }
}
//+------------------------------------------------------------------+
//| Get関数                                                          |
//+------------------------------------------------------------------+
double CVertex::GetPrice(void){ return _price; }
datetime CVertex::GetTime(void) { return _time; }