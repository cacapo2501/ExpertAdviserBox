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
   bool            _cloud_flg; //雲フラグ
                   CCloud(double, double, bool);//コンストラクタ
                  ~CCloud(void);                //デストラクタ
   bool            IsInRange(double);           //価格が範囲内か検定する
   void            DebugPrint();
};
//+------------------------------------------------------------------+
//| 価格雲クラス：コンストラクタ                                     |
//+------------------------------------------------------------------+
CCloud::CCloud(double price_hi, double price_lo, bool is_cloud){
   _price_hi = price_hi;
   _price_lo = price_lo;
   _cloud_flg = is_cloud;
}
//+------------------------------------------------------------------+
//| 価格雲クラス：デストラクタ                                       |
//+------------------------------------------------------------------+
CCloud::~CCloud(void){}
//+------------------------------------------------------------------+
//| 価格雲クラス：価格雲中検定                                       |
//+------------------------------------------------------------------+
bool CCloud::IsInRange(double cur_price){
   if(_cloud_flg){
      return (_price_hi >= cur_price && cur_price >= _price_lo); 
   }
   else{
      return (_price_hi > cur_price && cur_price > _price_lo); 
   }
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
   CCloud        *GetCurrentCloud(double);//雲を取得する
   public:
                  CSky(VertexManager*,int,double);    //コンストラクタ   
                 ~CSky(void);                         //デストラクタ
   void           Update();                           //更新処理
   void           CreateClouds();                     //雲を生成する
   bool           CheckInCloud(double);               //雲中か検定する
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
   bool last_flg_status = false;       //雲フラグ（前回）
   double price_begin = 0;             //現フラグの状態になった価格
   
   //雲クラスを初期化する
   this.Clear();
   
   while(idx_hi < _vmanager.Total() && idx_lo < _vmanager.Total()){
      Vertex *vtx_hi = _vmanager.At(idx_hi);
      Vertex *vtx_lo = _vmanager.At(idx_lo);
      if(!CheckPointer(vtx_hi) || !CheckPointer(vtx_lo)) return;
      
      //価格を求める
      double price_hi = vtx_hi.GetPrice();
      double price_lo = vtx_lo.GetPrice();
      
      //現在の雲の状態を取得する
      bool cur_status = (price_hi - price_lo) < _cloud_range;
      //雲の状態が更新？
      if(cur_status != last_flg_status){
         //雲オブジェクトを生成する
         CCloud *cloud = new CCloud(price_lo, price_begin, last_flg_status);
         this.Add(cloud);
         //情報を更新する
         price_begin = price_lo;
         last_flg_status = cur_status;
      }
      
      idx_hi++; idx_lo++;
   }
   //最後の雲オブジェクトを生成する
   CCloud *cloud = new CCloud(DBL_MAX, price_begin, last_flg_status);
   this.Add(cloud);
}
//+------------------------------------------------------------------+
//| 価格空クラス：検定処理                                           |
//+------------------------------------------------------------------+
bool CSky::CheckInCloud(double cur_price){
   static CCloud *last_pos = NULL; //前回起動時の雲ポインタ
   //雲ポインタが残っていない場合は再取得する
   if(!CheckPointer(last_pos) || !last_pos.IsInRange(cur_price)){
      last_pos = GetCurrentCloud(cur_price);
   }
   return last_pos.IsInRange(cur_price);
}
//+------------------------------------------------------------------+
//| 価格空クラス：雲を取得する                                       |
//+------------------------------------------------------------------+
CCloud* CSky::GetCurrentCloud(double cur_price){
   for(int i = 0; i < this.Total(); i++){
      CCloud *cloud = this.At(i);
      if(cloud.IsInRange(cur_price)) return cloud;
   }
   return NULL;
}