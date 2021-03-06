//+------------------------------------------------------------------+
//|                                            StandardFunctions.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| 汎用関数                                                         |
//+------------------------------------------------------------------+
//価格を取得する
double GetPrice(int index,ENUM_APPLIED_PRICE price,ENUM_TIMEFRAMES time=PERIOD_CURRENT){
   switch(price){
      case PRICE_CLOSE:
         return iClose(Symbol(),time,index);
      case PRICE_HIGH:
         return iHigh(Symbol(),time,index);
      case PRICE_LOW:
         return iLow(Symbol(),time,index);
      case PRICE_MEDIAN:
         return (GetPrice(index,PRICE_HIGH)+GetPrice(index,PRICE_LOW))/2;
      case PRICE_OPEN:
         return iOpen(Symbol(),time,index);
      default:
         return -DBL_MAX;
   }
}
//バーの開始時刻を取得する
datetime GetTime(int index,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT){
   return iTime(Symbol(),timeframe,index);
}
datetime NormalizeHour(int hour){
   while(hour<0) hour+=24;
   return hour%24;
}
//時刻からバーを求める
int GetBar(datetime time,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT){
   return iBarShift(Symbol(),timeframe,time);
}
//配列の先頭に要素を追加する(datetime型)
void AddValueAtHead(datetime &arrVal[],datetime value){
   int arr_size=ArraySize(arrVal);     //配列の大きさ
   //シフトできる要素がない場合は処理終了
   if(ArraySize(arrVal)==0) return;
   if(ArraySize(arrVal)==1) arrVal[0]=value;
   
   datetime tmpVal[];  //一時配列
   ArrayResize(tmpVal,arr_size);
   //元の配列→一時配列にコピーする
   ArrayCopy(tmpVal,arrVal);
   //一時配列→元の配列にシフトしながらコピーする
   ArrayCopy(arrVal,tmpVal,1,0,arr_size-1);
   //先頭の要素に値を格納する
   arrVal[0]=value;
}
//配列の先頭に要素を追加する(double型)
void AddValueAtHead(double &arrVal[],double value){
   int arr_size=ArraySize(arrVal);     //配列の大きさ
   //シフトできる要素がない場合は処理終了
   if(arr_size==0) return;
   if(arr_size==1) arrVal[0]=value;
   
   double tmpVal[];  //一時配列
   ArrayResize(tmpVal,arr_size);
   //元の配列→一時配列にコピーする
   ArrayCopy(tmpVal,arrVal);
   //一時配列→元の配列にシフトしながらコピーする
   ArrayCopy(arrVal,tmpVal,1,0,arr_size-1);
   //先頭の要素に値を格納する
   arrVal[0]=value;
}
//配列の末尾に要素を追加する(datetime型)
void AddValueAtTail(datetime &arrVal[],datetime value){
   int arr_size=ArraySize(arrVal);     //配列の大きさ
   //シフトできる要素がない場合は処理終了
   if(ArraySize(arrVal)==0) return;
   if(ArraySize(arrVal)==1) arrVal[0]=value;
   
   datetime tmpVal[];  //一時配列
   ArrayResize(tmpVal,arr_size);
   //元の配列→一時配列にコピーする
   ArrayCopy(tmpVal,arrVal);
   //一時配列→元の配列にシフトしながらコピーする
   ArrayCopy(arrVal,tmpVal,0,1,arr_size-1);
   //最後の要素に値を格納する
   arrVal[arr_size-1]=value;
}
void DelteValueAt(datetime &arrVal[],int idx){
   arrVal[idx]=EMPTY;
}
//配列を抽出する
void ArrayExtract(double &arrDst[],const double &arrVal[],const int begin,const int terminate){
   //配列が空のときは何もせずに終了
   if(ArraySize(arrVal)==0) return;
   //インデックス範囲無効のときは入力値を返す
   if(0>begin||ArraySize(arrVal)<terminate||begin>terminate){
      ArrayResize(arrDst,ArraySize(arrVal));
      ArrayCopy(arrDst,arrVal);
      return;
   }
   
   //配列を抽出する
   ArrayResize(arrDst,terminate-begin+1);
   ArrayCopy(arrDst,arrVal,0,begin,terminate-begin+1);
}
//平均を求める
double GetAverage(const double &arrVal[]){
   double sumVal=0;
   int cntValid=0;
   for(int idx=0;idx<ArraySize(arrVal);idx++){
      if(arrVal[idx]==EMPTY_VALUE) continue;
      cntValid++;
      sumVal+=arrVal[idx];
   }
   return NormalizeDouble(sumVal/cntValid,_Digits);
}
//平均を求める
double GetAverageInt(const int &arrVal[]){
   double sumVal=0;
   int cntValid=0;
   for(int idx=0;idx<ArraySize(arrVal);idx++){
      if(arrVal[idx]==INT_MAX||arrVal[idx]==INT_MIN) continue;
      sumVal+=(double)arrVal[idx];
      cntValid++;
   }
   return NormalizeDouble(sumVal/cntValid,_Digits);
}
//中間値を求める
double GetMedian(const double &arrVal[]){
   double arrSorted[];
   int arr_size=ArraySize(arrVal);
   
   ArrayCopy(arrSorted,arrVal);
   
   if(arr_size%2==0){
      //２で割りきれる場合→中間値前後の値の平均
      return (arrSorted[arr_size/2]+arrSorted[(arr_size-2)/2])/2;
   }
   else{
      //２で割り切れない場合→中間の値
      return arrSorted[(arr_size-1)/2];
   }
}
//傾向を求める
double GetDirection(const double &arrVal[],const double ignorant_level,const int ignore_reverse_bars=2){
   //無視レベルは0～0.5の間
   if(ignorant_level<=0||ignorant_level>=0.5) return EMPTY_VALUE;
   //許容範囲を求める
   double level_max=1-ignorant_level;
   double level_min=ignorant_level;
   //配列の最大値・最小値を求める
   int index_max=ArrayMaximum(arrVal);
   int index_min=ArrayMinimum(arrVal);
   double value_max=arrVal[index_max];
   double value_min=arrVal[index_min];
   /*/逆行期間が短い時は長いトレンドに乗る
   if(index_max>index_min&&index_min<ignore_reverse_bars) return -1;
   if(index_max<index_min&&index_max<ignore_reverse_bars) return +1;
   //*/
   double value_ratio=GetLevel(arrVal[0],value_max,value_min); //上下端区間内での相対位置
   double modify_ratio=GetLevel(value_ratio,level_max,level_min);  //レベル区間制限適用後相対位置
   
   return MathMin(1,MathMax(0,modify_ratio));
}
double GetMovementOfRange(const double &arrVal[],const double short_period_ratio){
   if(short_period_ratio<=0||short_period_ratio>=0.75) return -DBL_MAX;
   int short_period=(int)(ArraySize(arrVal)*short_period_ratio);
   //短期間の最大最小を求める
   int idx_short_max=ArrayMaximum(arrVal,short_period,0);
   int idx_short_min=ArrayMinimum(arrVal,short_period,0);
   double val_short_max=arrVal[idx_short_max];
   double val_short_min=arrVal[idx_short_min];
   //全区間の最大最小を求める
   int idx_all_max=ArrayMaximum(arrVal);
   int idx_all_min=ArrayMinimum(arrVal);
   double val_all_max=arrVal[idx_all_max];
   double val_all_min=arrVal[idx_all_min];
   
   if(val_all_max==val_all_min) return -DBL_MAX;
   return (val_short_max-val_short_min)/(val_all_max-val_all_min);
} 
//最大値-最小値における値の比率を求める
double GetLevel(const double target,const double val_max,const double val_min){
   if(val_max==val_min) return 0.5;
   return (target-val_min)/(val_max-val_min);
}
//最大値－最小値／変化量の総量を求める
double GetChangingRatio(const double &arrSrc[]){
   double total=0;
   for(int idx=1;idx<ArraySize(arrSrc);idx++){
      total+=MathAbs(arrSrc[idx]-arrSrc[idx-1]);
   }
   int idx_max=ArrayMaximum(arrSrc);
   int idx_min=ArrayMinimum(arrSrc);
   return (arrSrc[idx_max]-arrSrc[idx_min])/total;
}
//+------------------------------------------------------------------+
//| オブジェクト関数                                                 |
//+------------------------------------------------------------------+
void DrawArrow(datetime time1,double price1,int arrow_color,int arrow_code=75,string prefix=NULL,bool update=true){
   string name=GetArrowName(time1,prefix);      //今回生成する矢印の名称
   //すでに同名の矢印があり、上書きしない場合は処理を終了する
   if(!update&&ObjectFind(ChartID(),name)>=0){
      return;
   }
   //すでに同名の矢印がある場合は削除する
   else if(ObjectFind(ChartID(),name)>=0){
      ObjectDelete(ChartID(),name);
   }
   
   //矢印を描く
   ObjectCreate(ChartID(),name,OBJ_ARROW,0,time1,price1);
   //矢印を編集する
   ObjectSetInteger(ChartID(),name,OBJPROP_COLOR,arrow_color);       //矢印の色
   ObjectSetInteger(ChartID(),name,OBJPROP_ARROWCODE,arrow_code);    //矢印の文字コード
}
string GetArrowName(datetime time1,string prefix){
   return prefix+"ARROW_"+TimeToIntegerString(time1);
}
string TimeToIntegerString(datetime time1){
   return IntegerToString(TimeYear(time1),4,'0') + IntegerToString(TimeMonth(time1),2,'0')
          + IntegerToString(TimeDay(time1),2,'0') + IntegerToString(TimeHour(time1),2,'0')
           + IntegerToString(TimeMinute(time1),2,'0');
}