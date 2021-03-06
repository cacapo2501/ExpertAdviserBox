//+------------------------------------------------------------------+
//|                                       GetMountainsAndValleys.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| 山・谷を求める                                                   |
//+------------------------------------------------------------------+
void GetMountains(int begin, int terminate, int &array[]){
   GetVertexes(begin, terminate, PRICE_HIGH, array);
}
void GetValleys(int begin, int terminate, int &array[]){
   GetVertexes(begin, terminate, PRICE_LOW, array);
}
void GetVertexes(int begin, int terminate, ENUM_APPLIED_PRICE price, int &array[]){
   int linelength = front_count + tail_count + 1; //バーの本数
   
   //パラメータ検定
   //開始インデックスはバーの範囲内？
   begin = 0 > begin ? 0 : begin;
   //終了インデックスはバーの範囲内？
   terminate = Bars - linelength < terminate ? Bars - linelength : terminate;
   
   //価格は高値または安値
   if(price != PRICE_HIGH && price != PRICE_LOW) return;
   
   //回答配列を初期化する
   ArrayResize(array, terminate - begin + 1);
   ArrayInitialize(array, 0);
   
   //バーの本数分繰り返す
   for(int i = begin; i <= terminate - linelength ; i++){
      //直線を引く
      string linename = DrawTrendLine(i, i + linelength, price, "dummy");
      
      //最大スコアを求める
      double max_score = DBL_MIN;
      int max_index = 0;
      for(int j = 0; j < linelength; j++){
         double price_on_line = ObjectGetValueByShift(linename, i + j);
         double price_hi = iHigh(Symbol(), PERIOD_CURRENT, i + j);
         double price_lo = iLow(Symbol(), PERIOD_CURRENT, i + j);
         
         //スコアを求める
         double score = price == PRICE_HIGH ? price_hi - price_on_line : price_on_line - price_lo;
         //スコアは最大値を更新している？
         if(score >= max_score){
            max_score = score;
            max_index = j;
         } 
      }
      //最大スコアのインデックスを加算する
      array[i - begin + max_index]++;
      
      //直線を消す
      ObjectDelete(my_id, linename);
   }
}
