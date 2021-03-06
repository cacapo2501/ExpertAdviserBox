//+------------------------------------------------------------------+
//|                                                CurveAnalyzer.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| 曲線データ                                                       |
//+------------------------------------------------------------------+
class CurveInfo{
   private:
      CurveInfo      *sub_info;        //副曲線情報
      int            i_index_max;      //入力データ（高値側）の最大値インデックス
      int            i_index_min;      //入力データ（安値側）の最小値インデックス
      double         f_range_all;      //データの高さ（絶対値）
      bool           b_initialized;    //初期化済みフラグ
      int            i_direction;      //傾きフラグ
   public:
      CurveInfo(const double&[],const double&[],const double,const int);
      ~CurveInfo(void);
      CurveInfo*     GetSubCurve(void);      //副曲線情報クラスを取得する
      double         GetCurveRange(void);    //データの高さを取得する
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
CurveInfo::CurveInfo(const double &data_hi[],const double &data_lo[],const double parent_range,const int direction=0){
   //フラグを初期化する
   b_initialized=false;
   
   //データの検定処理
   //配列の長さはHiLoで同じ？
   if(ArraySize(data_hi)!=ArraySize(data_lo)) return;
   int i_size_data=ArraySize(data_hi);    //データ区間の要素数
   
   double f_value_hi_max=data_hi[ArrayMaximum(data_hi)];    //Hiデータの最高値
   double f_value_lo_max=data_hi[ArrayMaximum(data_lo)];    //Loデータの最高値
   double f_value_hi_min=data_hi[ArrayMinimum(data_hi)];    //Hiデータの最低値
   double f_value_lo_min=data_hi[ArrayMinimum(data_lo)];    //Loデータの最低値
   //Hiの最大値はLoの最大値より大？
   if(f_value_hi_max<f_value_lo_max) return;
   //Hiの最小値はLoの最小値より大？
   if(f_value_hi_min<f_value_lo_min) return;
   
   //初期値を設定する
   i_index_max=ArrayMaximum(data_hi);  //最高値の位置
   i_index_min=ArrayMinimum(data_lo);  //最安値の位置
   f_range_all=data_hi[i_index_max]-data_lo[i_index_min];
   
   //ここまでが必須の設定--------------------------------------------+
   //初期化済みとする
   b_initialized=true;
   //これ以降はセットされない可能性がある----------------------------+
   
   //最高値と最安値の差分が区間長の80%を超えていたら副区間を作成しない
   if(i_size_data*0.8<MathAbs(i_index_max-i_index_min)) return;
   
   double sub_data_hi[];         //副カーブ用高値データ配列
   double sub_data_lo[];         //副カーブ用低値データ配列
   int sub_array_len=i_index_max<i_index_min?i_index_max:i_index_min;
   
   //副配列を初期化する
   ArrayResize(sub_data_hi,sub_array_len);
   ArrayCopy(sub_data_hi,data_hi,0,0,sub_array_len);
   ArrayResize(sub_data_lo,sub_array_len);
   ArrayCopy(sub_data_lo,data_lo,0,0,sub_array_len);
   
   //副曲線情報を設定する
   sub_info=new CurveInfo(sub_data_hi,sub_data_lo,f_range_all);
}
//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
CurveInfo::~CurveInfo(void){
   delete sub_info;
}
//+------------------------------------------------------------------+
//| 取得関数                                                         |
//+------------------------------------------------------------------+
//副曲線情報
CurveInfo* CurveInfo::GetSubCurve(void){
   return sub_info;
}
//子孫のデータの高さ
double CurveInfo::GetCurveRange(void){
   return f_range_all;
}