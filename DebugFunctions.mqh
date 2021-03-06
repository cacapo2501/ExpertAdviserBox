//+------------------------------------------------------------------+
//|                                               DebugFunctions.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| デバッグ用関数                                                   |
//+------------------------------------------------------------------+
void PrintOriginal(const string name,const double value){
   Print(name,"=",DoubleToString(value,_Digits));
}
void PrintOriginal(const string name,const int &values[]){
   string str_print=name+"["+IntegerToString(ArraySize(values))+"]={";
   if(ArraySize(values)!=0){
      str_print+=IntegerToString(values[0],_Digits);
      for(int i=1;i<ArraySize(values);i++){
         str_print+=","+IntegerToString(values[i]);
      }
   }
   str_print+="}";
   Print(str_print);
}
void PrintOriginal(const string name,const double &values[]){
   string str_print=name+"["+IntegerToString(ArraySize(values))+"]={";
   if(ArraySize(values)!=0){
      str_print+=DoubleToString(values[0],_Digits);
      for(int i=1;i<ArraySize(values);i++){
         str_print+=","+DoubleToString(values[i],_Digits);
      }
   }
   str_print+="}";
   Print(str_print);
}
void PrintOriginalLowerThan(const string name,const double &values[],const double level){
   for(int idx=0;idx<ArraySize(values);idx++){
      if(values[idx]<level){
         PrintOriginal(name,values);
         return;
      }
   }
}
//+------------------------------------------------------------------+
