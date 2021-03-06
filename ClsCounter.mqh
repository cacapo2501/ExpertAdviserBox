//+------------------------------------------------------------------+
//|                                                   ClsCounter.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

//+------------------------------------------------------------------+
//| ロガークラス                                                     |
//+------------------------------------------------------------------+
class clsLogger{
   private:
      string name;
      int sections;
      double values[];
      double getCheckPoint(int, double, double);
   public:
      clsLogger(string, int);
      ~clsLogger();
      void addLog(double);
};
//+------------------------------------------------------------------+
//| ロガークラスコンストラクタ                                       |
//+------------------------------------------------------------------+
clsLogger::clsLogger(string aName, int aSections){
   this.name = aName;
   this.sections = aSections;
   ArrayResize(values, 0);
}
//+------------------------------------------------------------------+
//| ロガークラスデストラクタ                                         |
//+------------------------------------------------------------------+
clsLogger::~clsLogger(void){
   //値の挿入するが0の場合は何もしない
   if(ArraySize(values) == 0){
      Print(this.name + ": No values added.");
      return;
   }
   //配列を分析する
   ArraySort(this.values, WHOLE_ARRAY, 0, MODE_ASCEND);
   //最大値・最小値を取得する
   double max_value = this.values[ArraySize(this.values) - 1];
   double min_value = this.values[0];
   
   //最大値～最小値をセクション数で等分し、その間の数を数える
   int count = 0; //セクションカウンタ
   double check_point = DBL_MIN; //セクション値
   int results[]; //結果格納配列
   ArrayResize(results, this.sections);
   //結果配列を0クリアする
   ArrayInitialize(results, 0);
   for(int i = 0; i < ArraySize(this.values); i++){
      //値がチェックポイントを超えている？
      while(this.values[i] > check_point && count < this.sections){
         //セクションカウンタをカウントアップしてチェックポイントを更新する
         check_point = getCheckPoint(++count, min_value, max_value);
      }
      //結果を加算する
      results[count - 1]++;
   }
   
   //結果を出力する
   string separator = "***********************************************************************************************";
   Print(separator);
   Print("*     " + this.name);
   Print(separator);
   //セクション数回繰り返す
   for(int i = 0; i < sections; i++){
      string str_min = DoubleToString(getCheckPoint(i, min_value, max_value), 4);
      string str_max = DoubleToString(getCheckPoint(i + 1, min_value, max_value), 4);
      Print(this.name + " Count[" + str_min + " - " + str_max + "] : " + IntegerToString(results[i]));
   }
   Print(separator);
}
clsLogger::addLog(double value){
   ArrayResize(this.values, ArraySize(this.values) + 1);
   this.values[ArraySize(this.values) - 1] = value;
}
double clsLogger::getCheckPoint(int aCount, double aMin, double aMax){
   if(aCount == this.sections) return aMax;
   return aMin + (double)aCount * (aMax -  aMin) / this.sections;
}