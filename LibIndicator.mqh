//+------------------------------------------------------------------+
//|                                                 LibIndicator.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../Include/Arrays/ArrayObj.mqh"
//+------------------------------------------------------------------+
//| 列挙体                                                           |
//+------------------------------------------------------------------+
enum ENUM_OBSERVE_TYPE{
   OBS_NOTSEL = 0,
   OBS_ORDERBUY = 1,             //買い建玉のタイミングを取得する
   OBS_ORDERSELL = 2,            //売り建玉のタイミングを取得する
   OBS_CLOSEBUY = 3,             //買い決済のタイミングを取得する
   OBS_CLOSESELL = 4,            //売り決済のタイミングを取得する
};
//+------------------------------------------------------------------+
//| 指標クラス                                                       |
//+------------------------------------------------------------------+
class CIndicator : public CObject{
   private:
      string ID;                                      //ID名称
      virtual bool ObserveOrderBuy();                 //買い建玉のタイミング検定処理
      virtual bool ObserveOrderSell();                //売り建玉のタイミング検定処理
      virtual bool ObserveCloseBuy();                 //買い決済のタイミング検定処理
      virtual bool ObserveCloseSell();                //売り決済のタイミング検定処理
   public:
      CIndicator();                                   //コンストラクタ
      ~CIndicator(void);                              //デストラクタ
      bool              Observe(int);                 //監視処理
      virtual void      Update();                     //更新処理
      string            GetID() { return ID; }        //ID取得
      virtual string    GetComment();                 //注文時コメント取得
      virtual color     GetOrderColor();              //注文矢印色取得
      virtual color     GetCloseColor();              //決済矢印色取得
};
class CIndicatorManager : public CArrayObj{
   public:
      CIndicatorManager(void);                        //コンストラクタ
      ~CIndicatorManager(void);                       //デストラクタ
      string            ObserveAll();                 //監視処理
      void              UpdateAll();                  //更新処理
      bool              Add(CIndicator&);             //インジケータを追加する
      string            GetID(int);                   //ID名称を取得する
};
//+------------------------------------------------------------------+
//| 指標クラス：コンストラクタ                                       |
//+------------------------------------------------------------------+
CIndicator::CIndicator(void){
   
}
//+------------------------------------------------------------------+
//| 指標クラス：デストラクタ                                         |
//+------------------------------------------------------------------+
CIndicator::~CIndicator(void){
}
//+------------------------------------------------------------------+
//| 指標クラス：監視処理                                             |
//+------------------------------------------------------------------+
bool CIndicator::Observe(int observe_type){
   switch((ENUM_OBSERVE_TYPE)observe_type){
      case OBS_ORDERBUY:
         return ObserveOrderBuy();
      case OBS_ORDERSELL:
         return ObserveOrderSell();
      case OBS_CLOSEBUY:
         return ObserveCloseBuy();
      case OBS_CLOSESELL:
         return ObserveCloseSell();
      default:
         return false;
   }
}
//---仮想関数の初期化
bool CIndicator::ObserveOrderBuy(void)  { return false; }
bool CIndicator::ObserveOrderSell(void) { return false; }
bool CIndicator::ObserveCloseBuy(void)  { return false; }
bool CIndicator::ObserveCloseSell(void) { return false; }
void CIndicator::Update(void){}
string CIndicator::GetComment(void)     { return NULL; }
color  CIndicator::GetOrderColor(void)  { return 0; }
color  CIndicator::GetCloseColor(void)  { return 0; }
//+------------------------------------------------------------------+
//| 指標監視クラス：コンストラクタ                                   |
//+------------------------------------------------------------------+
CIndicatorManager::CIndicatorManager(void){
   
}
//+------------------------------------------------------------------+
//| 指標管理クラス：デストラクタ                                     |
//+------------------------------------------------------------------+
CIndicatorManager::~CIndicatorManager(void){

}
//+------------------------------------------------------------------+
//| 指標管理クラス：全指標オブジェクト監視                           |
//+------------------------------------------------------------------+
string CIndicatorManager::ObserveAll(void){
   string reason = NULL;  //回答（反応のあった指標）
   
   //すべての指標で繰り返し処理する
   for(int i = 0; i < this.Total(); i++){
      CIndicator *ind = this.At(i);
      if(CheckPointer(ind)){
         //買い検定
         if(ind.Observe(OBS_ORDERBUY)){
            reason += (reason == NULL ? NULL : ",") + ind.GetID() + ":BUY";
         }
         //売り検定
         if(ind.Observe(OBS_ORDERSELL)){
            reason += (reason == NULL ? NULL : ",") + ind.GetID() + ":SELL";
         }
      }
   }
   
   return reason;
}
//+------------------------------------------------------------------+
//| 指標管理クラス：指標IDを取得する                                 |
//+------------------------------------------------------------------+
string CIndicatorManager::GetID(int index){
   CIndicator *ind = this.At(index);
   if(CheckPointer(ind)){
      return ind.GetID();
   }
   return NULL;
}
//+------------------------------------------------------------------+
//| 指標管理クラス：指標を追加する                                   |
//+------------------------------------------------------------------+
bool CIndicatorManager::Add(CIndicator &indicator){
   for(int i = 0; i < this.Total(); i++){
      CIndicator *now = this.At(i);
      if(StringCompare(now.GetID(), indicator.GetID()) == 0) return false;
   }
   
   return this.Add(indicator);
}