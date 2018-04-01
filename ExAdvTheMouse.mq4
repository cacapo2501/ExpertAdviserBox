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
input int pObjectiveBarCount = 5;
input double pExtractRatio = 0.6;
input double pStoploss = 0.25;
input double pTakeprofit = 0.10;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //***基準価格を更新する***
   static double lMaxBuyNow = 0; //最高買い注文価格
   static double lMinSellNow = 0; //最低売り注文価格
   static datetime lLastUpdate = 0; //最終価格更新時刻
   if(lLastUpdate != iTime(Symbol(), 0, 0)){
      //***注文価格を更新する***
      UpdateOrderPrice(lMaxBuyNow, lMinSellNow, pPeriod, true);
      
      //***最終価格更新時刻を更新する***
      lLastUpdate = iTime(Symbol(), 0, 0);
   }
   
   //***建玉は存在する？***
   if(GetActiveTicket(pPrimaryMagic, Symbol()) == -1){
      //***建玉なし***
      bool lBuyFlg = false, lSellFlg = false; //注文フラグ
      
      //フラグを更新する
      
      //注文フラグ（買い）ONなら注文する？
      if(lBuyFlg)       SendBuy();
      //注文フラグ（売り）ONなら注文する？
      else if(lSellFlg) SendSell();
      
   }
   else{
      //***建玉あり***
      bool lCloseFlg = false; //決済フラグ
      
      //決済フラグONなら決済する？
      if(lCloseFlg) SendClose();
   }
  }
//+------------------------------------------------------------------+
//| 注文価格更新                                                     |
//|                                                                  |
//| 買い注文・売り注文を送信する価格を更新する                       |
//| <<引数>>    double  &aBuy  買い価格                              |
//|             double  &aSell  売り価格                             |
//|             int     aBeginBar  検定最大期間                      |
//|             bool    aReqInit  強制初期化フラグ                   |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void UpdateOrderPrice(double &aMaxPrice, double &aMinPrice, int aBeginBar, bool aReqInit){
   //***最高値・最安値の位置を取得する***
   int lPeriod = aBeginBar - pObjectiveBarCount; //補正後の期間
   int lHighestBar = iHighest(Symbol(), 0, MODE_HIGH, lPeriod, pObjectiveBarCount); //最高値の位置
   int lLowestBar = iLowest(Symbol(), 0, MODE_LOW, lPeriod, pObjectiveBarCount); //最安値の位置
   double lMaxPrice = iHigh(Symbol(), 0, lHighestBar); //最高値
   double lMinPrice = iLow(Symbol(), 0, lLowestBar); //最安値
   
   //強制初期化フラグONなら買い価格・売り価格を更新する
   if(aReqInit){
      aMaxPrice = lMinPrice;
      aMinPrice = lMaxPrice;
   }
   
   //最大・最小区間は同じバーでない？(DIV/0対策)
   if(lHighestBar == lLowestBar) return;
   
   //全区間／最大最小区間が基準値以下なら戻る
   if(aBeginBar / MathAbs(lHighestBar - lLowestBar) < pExtractRatio) return;
   
   //このコールの最大最小／前コールの最大最小が基準値以下なら戻る
   if((aMaxPrice - aMinPrice) / ()
   
   //***最高値と最安値に十分な差分があるか検定する***
   if(!CheckDefiniteDifference(lHighestBar, lLowestBar, lMaxPrice, lMinPrice)){
      //十分な差分が認められなければ処理終了
      return;
   }
   
   //***より最新に近い区間についてネストコールして更新する***
   UpdateOrderPrice(aBuy, aSell, (int)MathMin(lHighestBar, lLowestBar), false);   
   return;
}
//+------------------------------------------------------------------+
//| 買い注文送信                                                     |
//|                                                                  |
//| 買い注文を送信する                                               |
//| <<引数>>    なし                                                 |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void SendBuy(){
   //注文を送信する
   OrderSend(Symbol(), OP_BUY, 0.1, Ask, pSlippage, Ask - pStoploss, 
                  Ask + pTakeprofit, NULL, pPrimaryMagic, 0, clrAqua);
}
//+------------------------------------------------------------------+
//| 売り注文送信                                                     |
//|                                                                  |
//| 売り注文を送信する                                               |
//| <<引数>>    なし                                                 |
//| <<戻り値>>  なし                                                 |
//+------------------------------------------------------------------+
void SendSell(){
   //注文を送信する
   OrderSend(Symbol(), OP_SELL, 0.1, Bid, pSlippage, Bid + pStoploss, 
                  Bid - pTakeprofit, NULL, pPrimaryMagic, 0, clrAqua);

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