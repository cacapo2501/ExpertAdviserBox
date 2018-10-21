//+------------------------------------------------------------------+
//|                                       StandardOrderFunctions.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
input int      magic=867;           //マジックナンバー
input int      slippage=0;          //スリッページ
input bool     allow_compound=false;//可変ロットモード
input double   max_lost_ratio=0.03; //最大損失割合
input double   fixed_lots=0.1;      //固定ロット時のロット数
input int      try_to_open=1;       //この回数だけ注文を投げて全部エラーだったら諦める
datetime       lastopen=0;
//+------------------------------------------------------------------+
//| 注文用関数                                                       |
//+------------------------------------------------------------------+
//注文保持検定
bool CheckHolding(){
   for(int idx=OrdersTotal()-1;idx>=0;idx--){
      if(OrderSelect(idx,SELECT_BY_POS)){
         if(OrderSymbol()==Symbol()&&     //シンボルが一致
            OrderMagicNumber()==magic){   //マジックナンバーが一致
            //ポジション保持中
            return true;
         }
      }
   }
   //ポジションなし
   return false;
}
//建玉チケット番号取得
int GetTicket(){
   for(int idx=OrdersTotal()-1;idx>=0;idx--){
      if(OrderSelect(idx,SELECT_BY_POS)){
         if(OrderSymbol()==Symbol()&&     //シンボルが一致
            OrderMagicNumber()==magic){   //マジックナンバーが一致
            //チケット番号を返す
            return OrderTicket();
         }
      }
   }
   //取得に失敗した場合
   return -1;
}
//買い注文
void SendBuyOrder(const double lots,const double stoploss,const double takeprofit,bool show_log=false){
   if(!CheckLastOpenTime()) return;
   if(lots==0) return;
   
   int send_count=0;
   double normalize_stoploss=NormalizeDouble(stoploss,_Digits);
   double normalize_takeprofit=NormalizeDouble(takeprofit,_Digits);
   
   int response=-1; //注文結果
   lastopen=TimeCurrent();
   while(response==-1){
      send_count++;
      response=OrderSend(Symbol(),OP_BUY,lots,Ask,slippage,normalize_stoploss,normalize_takeprofit,NULL,magic,0,0xFF5555);
      int last_error=GetLastError();
      if(show_log){
         Print("Order=BUY : lots=",lots,", Price=",Bid,", S/L=",stoploss,", T/P=",takeprofit,", Error:",last_error);
      }
      
      //送信に何度も失敗する場合はEAを停止する
      if(response==-1&&send_count>=try_to_open) {
         ExpertRemove();
         return;
      }
   }
}
//売り注文
void SendSellOrder(const double lots,const double stoploss,const double takeprofit,bool show_log=false){
   if(!CheckLastOpenTime()) return;
   if(lots==0) return;
   
   int send_count=0;
   double normalize_stoploss=NormalizeDouble(stoploss,_Digits);
   double normalize_takeprofit=NormalizeDouble(takeprofit,_Digits);
   
   int response=-1;
   lastopen=TimeCurrent();
   while(response==-1){
      send_count++;
      response=OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,normalize_stoploss,normalize_takeprofit,NULL,magic,0,0x5555FF);
      int last_error=GetLastError();
      if(show_log){
         Print("Order=SELL: lots=",lots,", Price=",Bid,", S/L=",stoploss,", T/P=",takeprofit,", Error:",last_error);
      }
      
      //送信に何度も失敗する場合はEAを停止する
      if(response==-1&&send_count>=try_to_open) {
         ExpertRemove();
         return;
      }
   }
}
//ロット数検定
bool CheckLots(double lots){
   return MarketInfo(Symbol(),MODE_MINLOT)<lots;
}
//決済
void SendClose(const int ticket,const double lots=0){
   bool response=false;          //決済の結果
   if(!CheckHolding()) return;
   double real_lots=lots==0? OrderLots(): lots; //決済ロット数
   color clr_arrow=(color)(OrderType()==OP_BUY? 0xDDDD77: 0x77DDDD);
   
   while(!response){
      response=OrderClose(ticket,real_lots,OrderClosePrice(),slippage,clr_arrow);
   }
}
//修正
void SendModify(const int ticket,const double stoploss,const double takeprofit){
   bool response=false;
   if(!CheckHolding()) return;
   double mod_price=0;
   if(OrderType()==OP_BUY){
      mod_price=Ask;
   }
   else{
      mod_price=Bid;
   }
   
   double normalize_stoploss=NormalizeDouble(stoploss,_Digits);      //補正後損切り価格
   double normalize_takeprofit=NormalizeDouble(takeprofit,_Digits);  //補正後利食い価格
   //注文に補正がない場合は処理終了
   if(normalize_stoploss==OrderStopLoss()&&normalize_takeprofit==OrderTakeProfit()) return;
   
   while(!response){
      response=OrderModify(ticket,mod_price,normalize_stoploss,normalize_takeprofit,0,0xDD77DD);
      int last_error=GetLastError();
      if(last_error/100==1) return; //設定ミスによる無限ループ回避
   }
}
//連続建玉制限
bool CheckLastOpenTime(){
   return lastopen<=Time[2];
}
//+------------------------------------------------------------------+
//| ポジションサイズを取得する                                       |
//+------------------------------------------------------------------+
double GetLots(double stoploss_height){
   if(stoploss_height==0) return 0;
   if(allow_compound){
      double max_lost_margin=AccountFreeMargin()*max_lost_ratio;  //最大許容損失額
      double permittion_lots=max_lost_margin*MarketInfo(Symbol(),MODE_POINT)/(stoploss_height*MarketInfo(Symbol(),MODE_TICKVALUE)); //許容損失から求めたロット数
      double margin_lots=AccountFreeMargin()/MarketInfo(Symbol(),MODE_MARGINREQUIRED);  //証拠金ベースの最大ロット数
      
      double calculated_lots=MathMin(permittion_lots,margin_lots);   //計算上の最大ロット数
      
      double max_lots=MarketInfo(Symbol(),MODE_MAXLOT);  //通貨ペアの最大ロット数
      double min_lots=MarketInfo(Symbol(),MODE_MINLOT);  //通貨ペアの最小ロット数
      double lot_step=MarketInfo(Symbol(),MODE_LOTSTEP); //通貨ペアのロットステップ
      
      double response_lots=(int)(calculated_lots/lot_step)*lot_step;   //正規化
      if(response_lots<=min_lots) {
         return 0;
      }
      response_lots=MathMax(min_lots,MathMin(max_lots,response_lots));  //実際のロット数
      Print("実際のロット数:",response_lots);
      return NormalizeDouble(response_lots,2);
      
   }
   else return fixed_lots;
}

