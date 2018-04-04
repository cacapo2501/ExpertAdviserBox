//+------------------------------------------------------------------+
//|                                                ExAdvTheMouse.mq4 |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property version   "1.00"
#property strict

input int pPrimaryMagic = 1900;
input int pSlippage = 0;
input int pPeriod = 96;
input int pMinSearchHiLoBar = 5;
input int pMaxSearchHiLoBar = 25;
input double pStoploss = 0.25;
input double pTakeprofit = 0.15;
input double pTrailSize = 0.1;

int gFileHandle = -1;
string gLogLine;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   OpenLogFile();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   CloseLogFile();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //***基準価格を更新する***
   static datetime lLastUpdate = 0; //最終価格更新時刻
   static double lBuyPrice = DBL_MAX; //これを超えたら買う価格
   static double lSellPrice = DBL_MIN; //これを割り込んだら売る価格
   static double lModifyPrice = 0; //トレール注文する価格
   if(lLastUpdate != iTime(Symbol(), 0, 0)){
      //***チャートの状態を取得する***
      UpdateOrderPrice(lBuyPrice, lSellPrice);
      
      //ログに更新情報を出力する
      WriteParameter("BUY PRICE", lBuyPrice, 3);
      WriteParameter("SELL PRICE", lSellPrice, 3);
      
      //***最終価格更新時刻を更新する***
      lLastUpdate = iTime(Symbol(), 0, 0);
   }
   
   //***建玉は存在する？***
   if(GetActiveTicket(pPrimaryMagic, Symbol()) == -1){
      //***建玉なし***
      double lCurPrice = iClose(Symbol(), 0, 0);
      bool lBuyFlg = (lBuyPrice < lCurPrice);   //買い注文フラグ
      bool lSellFlg = (lSellPrice > lCurPrice); //売り注文フラグ
      
      //フラグを更新する(適宜Falseとする)
      //売り買いともにON→注文しない
      if(lBuyFlg && lSellFlg) return;
      
      //注文フラグ（買い）ONなら注文する？
      if(lBuyFlg)       SendBuy(lModifyPrice);
      //注文フラグ（売り）ONなら注文する？
      else if(lSellFlg) SendSell(lModifyPrice);
   }
   else{
      //***建玉あり***
      bool lCloseFlg = false; //決済フラグ
      
      //決済フラグONなら決済する？
      if(lCloseFlg) SendClose();
      
      //トレール注文するか検定する
      int lTicket = GetActiveTicket(pPrimaryMagic, Symbol());
      //価格を比較する
      int lType = OrderType();
      if(lType == OP_BUY && lModifyPrice < Ask) {
         OrderModify(lTicket, Ask, Ask - pStoploss, Ask + pTakeprofit, 0, clrLime);
         lModifyPrice = Ask + pTrailSize;
      }
      if(lType == OP_SELL && lModifyPrice > Bid) {
         OrderModify(lTicket, Bid, Bid + pStoploss, Bid - pTakeprofit, 0, clrOrange);
         lModifyPrice = Bid - pTrailSize;
      }
   }
  }
//+------------------------------------------------------------------+
//| 注文価格取得処理                                                 |
//|                                                                  |
//| 買い価格・売り価格の基準となるバーの位置を求める                 |
//| <<引数>>    なし                                                 |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void UpdateOrderPrice(double &aSendBuyPrice, double &aSendSellPrice){
   int lMaxBar = pPeriod;  //最高値バーの位置
   int lMinBar = pPeriod;  //最安値バーの位置
   
   //バーの位置を求める
   getHighLowBarPosition(lMaxBar, lMinBar);
   
   //求めたバーの位置から価格を求める
   double lMaxPrice = getHighestPrice(lMaxBar);
   double lMinPrice = getLowestPrice(lMinBar);
   
   //価格差を求める
   double lDifPrice = lMaxPrice - lMinPrice;
   
   aSendBuyPrice = lMaxPrice;
   aSendSellPrice = lMinPrice;
}
//+------------------------------------------------------------------+
//| トレンド価格取得処理                                             |
//|                                                                  |
//| 買い価格・売り価格の基準となるバーの位置を求める                 |
//| <<引数>>    int     &aMaxBar  最高値バーの位置                   |
//|             int     &aMinBar  最安値バーの位置                   |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
double getOnTrendJudgePrice(){
   return 0;
}
//+------------------------------------------------------------------+
//| 反発価格取得処理                                                 |
//|                                                                  |
//| 買い価格・売り価格の基準となるバーの位置を求める                 |
//| <<引数>>    int     &aMaxBar  最高値バーの位置                   |
//|             int     &aMinBar  最安値バーの位置                   |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
double getOnReverseJudgePrice(){
   return 0;
}

//+------------------------------------------------------------------+
//| 最高値・最安値バー位置取得                                       |
//|                                                                  |
//| 買い価格・売り価格の基準となるバーの位置を求める。               |
//| 計算終了するバーの位置はパラメタで指定する                       |
//| <<引数>>    int     &aMaxBar  最高値バーの位置                   |
//|             int     &aMinBar  最安値バーの位置                   |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void getHighLowBarPosition(int &aMaxBar, int &aMinBar){
   //バーの位置をバックアップする
   int lBackUpMaxBar = aMaxBar;
   int lBackUpMinBar = aMinBar;
   
   //最高値・最安値のバーの位置は同じ？
   if(aMaxBar == aMinBar){
      //最高値・最安値の位置を再計算する
      aMaxBar = getHighestBar(aMaxBar);
      aMinBar = getLowestBar(aMinBar);
   }
   else if(aMaxBar < aMinBar){
      //最高値が最安値の位置より現在に近い
      //最安値の位置を再計算する
      aMinBar = getLowestBar(aMaxBar);
   }
   else{
      //最安値が最高値の位置より現在に近い
      //最高値の位置を再計算する
      aMaxBar = getHighestBar(aMinBar);
   }
   
   //次のバーを検索するか検定する
   if(pMaxSearchHiLoBar <= MathMin(aMaxBar, aMinBar)){
      //近い方が検索期間より遠い場合は再帰呼び出しする
      getHighLowBarPosition(aMaxBar, aMinBar);
   }
   else if(pMinSearchHiLoBar <= MathMin(aMaxBar, aMinBar)){
      //近い方が検索期間を割り込んでいる場合は復元して戻る
      aMaxBar = lBackUpMaxBar;
      aMinBar = lBackUpMinBar;
      return;
   }
}
//+------------------------------------------------------------------+
//| 最高値価格取得                                                   |
//|                                                                  |
//| 最高値を求める                                                   |
//| <<引数>>    int     &aPeriod  求める期間                         |
//| <<戻り値>>  double  最高値                                       |
//+------------------------------------------------------------------+
double getHighestPrice(int aPeriod){
   return iHigh(Symbol(), 0, iHighest(Symbol(), 0, MODE_HIGH, aPeriod, 0));
}
//+------------------------------------------------------------------+
//| 最安値価格取得                                                   |
//|                                                                  |
//| 最安値を求める                                                   |
//| <<引数>>    int     &aPeriod  求める期間                         |
//| <<戻り値>>  double  最安値                                       |
//+------------------------------------------------------------------+
double getLowestPrice(int aPeriod){
   return iLow(Symbol(), 0, iLowest(Symbol(), 0, MODE_LOW, aPeriod, 0));
}
//+------------------------------------------------------------------+
//| 最高値位置取得                                                   |
//|                                                                  |
//| 最高値バーの位置を求める                                         |
//| <<引数>>    int     &aPeriod  求める期間                         |
//| <<戻り値>>  int     バーの位置                                   |
//+------------------------------------------------------------------+
int getHighestBar(int aPeriod){
   return iHighest(Symbol(), 0, MODE_HIGH, aPeriod, 0);
}
//+------------------------------------------------------------------+
//| 最安値位置取得                                                   |
//|                                                                  |
//| 最安値バーの位置を求める                                         |
//| <<引数>>    int     &aPeriod  求める期間                         |
//| <<戻り値>>  int     バーの位置                                   |
//+------------------------------------------------------------------+
int getLowestBar(int aPeriod){
   return iLowest(Symbol(), 0, MODE_LOW, aPeriod, 0);
}
//+------------------------------------------------------------------+
//| 買い注文送信                                                     |
//|                                                                  |
//| 買い注文を送信する                                               |
//| <<引数>>    なし                                                 |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void SendBuy(double &aTrailPrice){
   //注文を送信する
   bool foo = OrderSend(Symbol(), OP_BUY, 0.1, Ask, pSlippage, Ask - pStoploss, 
                  Ask + pTakeprofit, NULL, pPrimaryMagic, 0, clrAqua);
   aTrailPrice = Ask + pTrailSize;
}
//+------------------------------------------------------------------+
//| 売り注文送信                                                     |
//|                                                                  |
//| 売り注文を送信する                                               |
//| <<引数>>    なし                                                 |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void SendSell(double &aTrailPrice){
   //注文を送信する
   bool foo = OrderSend(Symbol(), OP_SELL, 0.1, Bid, pSlippage, Bid + pStoploss, 
                  Bid - pTakeprofit, NULL, pPrimaryMagic, 0, clrMagenta);

   aTrailPrice = Bid - pTrailSize;
}
//+------------------------------------------------------------------+
//| 決済注文送信                                                     |
//|                                                                  |
//| 決済注文を送信する                                               |
//| <<引数>>    なし                                                 |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void SendClose(){}
//+------------------------------------------------------------------+
//| 有効チケット番号取得                                             |
//|                                                                  |
//| このEAが建てた建玉のチケット番号を取得する                       |
//| <<引数>>  int     aMagic   マジックナンバー                      |
//|           string  aSymbol  通貨ペア名称                          |
//| <<戻り値>>  int  チケット番号                                    |
//|                  ※見つからないときは-1を返す                    |
//+------------------------------------------------------------------+
int GetActiveTicket(int aMagic, string aSymbol){
   for(int i = 0; i < OrdersTotal(); i++){
      if(OrderSelect(i, SELECT_BY_POS)){
         if(OrderMagicNumber() == aMagic &&
            IsSameSymbol(aSymbol, OrderSymbol()))
            return OrderTicket();
      }
   }
   
   return -1;
}
//+------------------------------------------------------------------+
//| シンボル名称検定                                                 |
//|                                                                  |
//| 通貨ペアが同じであるか検定する                                   |
//| <<引数>>  string  aSymbol1  通貨ペア名称1                        |
//|           string  aSymbol2  通貨ペア名称2                        |
//| <<戻り値>>  bool  検定結果                                       |
//+------------------------------------------------------------------+
bool IsSameSymbol(string aSymbol1, string aSymbol2){
   return StringSubstr(aSymbol1, 0, 6) == StringSubstr(aSymbol2, 0, 6);

}
//+------------------------------------------------------------------+
//| ログファイルオープン処理                                         |
//+------------------------------------------------------------------+
void OpenLogFile(){
   gFileHandle = FileOpen("ExAdvTheMouseLog.txt", FILE_WRITE | FILE_TXT);
   gLogLine = NULL;
   return;
}
//+------------------------------------------------------------------+
//| ログファイルクローズ処理                                         |
//+------------------------------------------------------------------+
void CloseLogFile(){
   FileClose(gFileHandle);
}
//+------------------------------------------------------------------+
//| パラメータログ出力処理                                           |
//+------------------------------------------------------------------+
void WriteParameter(string aName, double aValue, int aDigits = 5){
   gLogLine = aName + " = " + DoubleToString(aValue, aDigits);
   FlushLogLine();
}
void WriteParameter(string aName, int aValue){
   gLogLine = aName + " = " + IntegerToString(aValue);
   FlushLogLine();
}
void WriteParameter(string aName, string aValue){
   gLogLine = aName + " = \"" + aValue + "\"";
   FlushLogLine();
}
//+------------------------------------------------------------------+
//| ログ出力処理                                                     |
//+------------------------------------------------------------------+
void FlushLogLine(){
   //出力変数を初期化する
   string lMainString = NULL;
   
   //ログ出力情報を取得する
   lMainString += TimeToString(TimeCurrent(), TIME_DATE) + ",";
   lMainString += TimeToString(TimeCurrent(), TIME_SECONDS) + ",";
   
   //本文を設定する
   lMainString += gLogLine;
   
   //改行を挿入する
   lMainString += "\n";
   
   //ログに出力する
   FileWriteString(gFileHandle, lMainString);
   gLogLine = NULL;
}