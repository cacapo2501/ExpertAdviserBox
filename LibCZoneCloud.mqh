//+------------------------------------------------------------------+
//|                                                LibCZoneCloud.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../Include/Arrays/ArrayObj.mqh"
#include "../ExpertAdviserBox/LibCVertex.mqh"
//+------------------------------------------------------------------+
//| 価格雲クラス                                                     |
//+------------------------------------------------------------------+
class CCloud : public CObject{
   public:
   double          _price_hi; //雲の上限価格
   double          _price_lo; //雲の下限価格
                   CCloud(double, double);      //コンストラクタ
                  ~CCloud(void);                //デストラクタ
   bool            InCloud(double);             //価格雲中検定
   void            DebugPrint();
};
//+------------------------------------------------------------------+
//| 価格雲クラス：コンストラクタ                                     |
//+------------------------------------------------------------------+
CCloud::CCloud(double price_hi, double price_lo){
   _price_hi = price_hi;
   _price_lo = price_lo;
}
//+------------------------------------------------------------------+
//| 価格雲クラス：デストラクタ                                       |
//+------------------------------------------------------------------+
CCloud::~CCloud(void){}
//+------------------------------------------------------------------+
//| 価格雲クラス：価格雲中検定                                       |
//+------------------------------------------------------------------+
bool CCloud::InCloud(double current_price){
   if(_price_hi >= current_price && current_price >= _price_lo) return true;
   return false;
}
void CCloud::DebugPrint(void){
   Print("Hi:", _price_hi, ", Lo:", _price_lo);
}
//+------------------------------------------------------------------+
//| 価格空クラス                                                     |
//+------------------------------------------------------------------+
class CSky : public CArrayObj{
   private:
   VertexManager *_vmanager;              //山渓管理クラス
   int            _element_least;         //雲になれる要素数
   double         _cloud_range;           //雲の厚さ
   public:
                  CSky(VertexManager*,int,double);    //コンストラクタ   
                 ~CSky(void);                         //デストラクタ
   void           Update();                           //更新処理
   void           CreateClouds();                     //雲を生成する
};
//+------------------------------------------------------------------+
//| 価格空クラス：コンストラクタ／デストラクタ                       |
//+------------------------------------------------------------------+
CSky::CSky(VertexManager *vmanager, int elements, double range){
   _vmanager = vmanager;
   _element_least = elements;
   _cloud_range = range;
}
CSky::~CSky(void){}
//+------------------------------------------------------------------+
//| 価格空クラス：更新処理                                           |
//+------------------------------------------------------------------+
void CSky::Update(void){
   //山渓管理オブジェクトを更新する
   _vmanager.Update();
   _vmanager.Sort(SORT_BY_PRICE);
   
   //雲を再生成する
   this.Clear();
   this.CreateClouds();
   
   //デバッグ用
   /*
   Print("Total(s):", this.Total());
   for(int i = 0; i < this.Total(); i++){
      CCloud *cloud = this.At(i);
      cloud.DebugPrint();
   }
   //*/
}
//+------------------------------------------------------------------+
//| 価格空クラス：雲を生成する                                       |
//+------------------------------------------------------------------+
void CSky::CreateClouds(void){
   //最低要素数のオブジェクトが格納されていない場合は処理終了
   if(_vmanager.Total() <= _element_least) return;
      
   //カーソルにオブジェクトを設定する
   int idx_lo = 0;                     //下限探索中の山渓インデックス
   int idx_hi = _element_least - 1;    //上限探索中の山渓インデックス
   while(idx_hi < _vmanager.Total() && idx_lo < _vmanager.Total()){
      Vertex *vtx_hi = _vmanager.At(idx_hi);
      Vertex *vtx_lo = _vmanager.At(idx_lo);
      if(!CheckPointer(vtx_hi) || !CheckPointer(vtx_lo)) return;
      
      //価格を求める
      double price_hi = vtx_hi.GetPrice();
      double price_lo = vtx_lo.GetPrice();
      
      //区間内の要素数は最低数に達している？
      if(price_hi - price_lo < _cloud_range && idx_hi - idx_lo >= _element_least){
         //雲を生成する
         CCloud *cloud = new CCloud(price_hi, price_lo);
         this.Add(cloud);
         //次のインデックスに進める
         idx_lo = idx_hi;
         idx_hi += _element_least;
      }
      
      //価格幅を調べる
      //価格幅は基準より狭い？
      if(price_hi - price_lo > _cloud_range){
         //インデックス範囲を広げる
         idx_lo++;
      }
      else{
         //インデックス範囲を狭める
         idx_hi++;
      }
   }
   
}