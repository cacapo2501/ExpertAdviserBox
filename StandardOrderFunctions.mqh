//+------------------------------------------------------------------+
//|                                       StandardOrderFunctions.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

#include "../ExpertAdviserBox/StandardFunctions.mqh"
input int      magic=867;              //マジックナンバー
input int      slippage=0;             //スリッページ
input bool     allow_compound=false;   //可変ロットモード
input double   max_lost_ratio=0.03;    //最大損失割合
input double   fixed_lots=0.1;         //固定ロット時のロット数
input int      try_to_open=1;          //この回数だけ注文を投げて全部エラーだったら諦める
input int      max_holding_hour=5;     //最大保有時間(0で検定しない)
datetime       lastopen=0;             //最後にチェックした時刻
double         trailing_stop_begin_pips=0;   //トレーリングストップ開始(pips)
double         trailing_stop_step_pips=0;    //トレーリングストップ開始ステップ(pips)
double         stoploss_pips=0;        //ストップロス幅(pips)
double         takeprofit_pips=0;      //テイクプロフィット幅(pips)
double         next_modify_price=0;    //次注文修正タイミング
datetime       order_limit_time[];     //注文制限時間帯
bool           trailing_stop=false;    //トレーリングストップモード
int            check_modify_idx=0;     //カレンダチェック用カウンタ（修正注文）
int            check_open_idx=0;       //カレンダチェック用カウンタ（新規注文）
string         calendar_definition="1_0200,1_1700,1_2000,2_0200,2_1700,2_2000,3_0200,3_1700,3_2000,4_0200,4_1700,4_2000,5_0200,5_1700,5_2000";     //取引カレンダ定義
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
//注文更新処理
void UpdateOrders(){
   //カレンダを更新する
   static datetime lastupdate=0;
   static int lastupdate_dayofweek=0;
   if(lastupdate!=Time[0]){
      if(lastupdate==0||lastupdate_dayofweek>TimeDayOfWeek(TimeCurrent())){
         //毎日0:00-14:00は新規注文可、14:00-16:00は修正注文可、16:00-0:00は取引不可
         SetOrderLimitTime(calendar_definition);
      }
      lastupdate_dayofweek=TimeDayOfWeek(TimeCurrent());
      lastupdate=Time[0];
   }
   
   //修正注文受付時刻終了？
   if(CheckHolding()&&!CheckSendModifyLimitTime()){
      //禁止期間中なら全ポジション決済
      while(CheckHolding()){
         SendClose(OrderTicket());
      }
      return;
   }
   
   //最大保有時間検定
   if(max_holding_hour!=0&&OrderOpenTime()<GetTime(max_holding_hour,PERIOD_H1)){
      //保有時間を超過していたら決済する
      while(CheckHolding()){
         SendClose(OrderTicket());
      }
   }
   
   //ポジションを持っていたら更新する
   if(CheckHolding()){
      if(trailing_stop&&CheckSendModifyLimitTime()){
         if(OrderType()==OP_BUY){
            if(Ask>next_modify_price){
               //更新する
               SendModify(OrderTicket(),Ask-stoploss_pips*10*_Point,Ask+trailing_stop_step_pips*20*_Point);
               next_modify_price=Ask+trailing_stop_step_pips*10*_Point;
            }
         }
         if(OrderType()==OP_SELL){
            if(Bid<next_modify_price){
               //更新する
               SendModify(OrderTicket(),Bid+stoploss_pips*10*_Point,Bid-trailing_stop_step_pips*20*_Point);
               next_modify_price=Bid-trailing_stop_step_pips*10*_Point;
            }
         }
      }
   }
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
void SendBuyOrder(const double lots,bool show_log=false){
   if(!CheckLastOpenTime()) return;
   if(!CheckSendOpenLimitTime()) return;
   if(lots==0) return;
   
   int send_count=0;
   double normalize_stoploss=Ask-NormalizeDouble(stoploss_pips*10*_Point,_Digits);
   double normalize_takeprofit=Ask+NormalizeDouble((trailing_stop?trailing_stop_begin_pips*2:takeprofit_pips)*10*_Point,_Digits);
   next_modify_price=Ask+NormalizeDouble(trailing_stop_begin_pips*10*_Point,_Digits);
   
   int response=-1; //注文結果
   lastopen=TimeCurrent();
   while(response==-1){
      send_count++;
      response=OrderSend(Symbol(),OP_BUY,lots,Ask,slippage,normalize_stoploss,normalize_takeprofit,NULL,magic,0,0xFF5555);
      int last_error=GetLastError();
      if(show_log){
         Print("Order=BUY : lots=",lots,", Price=",Bid,", S/L=",DoubleToString(stoploss_pips,1),", T/P=",DoubleToString(takeprofit_pips,1),", Error:",last_error);
      }
      
      //送信に何度も失敗する場合はEAを停止する
      if(response==-1&&send_count>=try_to_open) {
         ExpertRemove();
         return;
      }
   }
}
//売り注文
void SendSellOrder(const double lots,bool show_log=false){
   if(!CheckLastOpenTime()) return;
   if(!CheckSendOpenLimitTime()) return;
   if(lots==0) return;
   
   int send_count=0;
   double normalize_stoploss=Bid+NormalizeDouble(stoploss_pips*10*_Point,_Digits);
   double normalize_takeprofit=Bid-NormalizeDouble((trailing_stop?trailing_stop_begin_pips*2:takeprofit_pips)*10*_Point,_Digits);
   next_modify_price=Bid-NormalizeDouble(trailing_stop_begin_pips*10*_Point,_Digits);
   
   int response=-1;
   lastopen=TimeCurrent();
   while(response==-1){
      send_count++;
      response=OrderSend(Symbol(),OP_SELL,lots,Bid,slippage,normalize_stoploss,normalize_takeprofit,NULL,magic,0,0x5555FF);
      int last_error=GetLastError();
      if(show_log){
         Print("Order=SELL: lots=",lots,", Price=",Bid,", S/L=",DoubleToString(stoploss_pips,1),", T/P=",DoubleToString(takeprofit_pips,1),", Error:",last_error);
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
   color clr_arrow=(color)(OrderType()==OP_BUY? 0xCC4444: 0x4444CC);
   
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
double GetLots(double _stoploss_pips){
   if(_stoploss_pips==0) _stoploss_pips=stoploss_pips;
   if(allow_compound){
      double max_lost_margin=AccountFreeMargin()*max_lost_ratio;  //最大許容損失額
      double permittion_lots=max_lost_margin*MarketInfo(Symbol(),MODE_POINT)/(_stoploss_pips*10*_Point*MarketInfo(Symbol(),MODE_TICKVALUE)); //許容損失から求めたロット数
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
      //Print("実際のロット数:",response_lots);
      return NormalizeDouble(response_lots,2);
      
   }
   else return fixed_lots;
}
//+------------------------------------------------------------------+
//| 注文制限時間に関する処理                                         |
//+------------------------------------------------------------------+
bool CheckSendOpenLimitTime(){
   while(ArraySize(order_limit_time)>check_open_idx&&order_limit_time[check_open_idx]<TimeCurrent()){
      check_open_idx++;
      Print("カウントアップ！");
   }
   //インデックスの範囲外の場合、制限時間内
   if(ArraySize(order_limit_time)<=check_open_idx) return false;
   //インデックスの２番目または３番目の場合は制限時間内
   if(check_open_idx%3==1) return true;
   return false;
}
bool CheckSendModifyLimitTime(){
   while(ArraySize(order_limit_time)>check_modify_idx&&order_limit_time[check_modify_idx]<TimeCurrent()){
      check_modify_idx++;
      Print("カウントアップ！");
   }
   //インデックスの範囲外の場合、制限時間内
   if(ArraySize(order_limit_time)<=check_modify_idx) return false;
   //インデックスの３番目の場合は制限時間内
   if(check_modify_idx%3==2||check_modify_idx%3==1) return true;
   return false;
}
//注文制限設定関数
void SetOrderLimitTime(string limit="1_0000,5_2359,5_2359"){
   string splitstr[];      //入力文字列
   //入力を分割する
   StringSplit(limit,',',splitstr);
   //3の倍数でなければ処理終了
   if(ArraySize(splitstr)%3!=0) return;
   //配列の大きさを変更する
   ArrayResize(order_limit_time,ArraySize(splitstr));
   
   for(int idx=0;idx<ArraySize(splitstr);idx++){
      order_limit_time[idx]=GetLimitTime(splitstr[idx]);
      Print("格納した時刻[",idx,"]=",order_limit_time[idx]);
   }
   //カウンタをリセットする
   check_open_idx=1;
   check_modify_idx=1;
}
//制限時刻取得
datetime GetLimitTime(string str_time){
   string str_split[];
   StringSplit(str_time,'_',str_split);
   
   string yyyy,mm,dd,hh,mi;
   long shift_day=0;
   if(StringLen(str_split[0])==8){
      yyyy=StringSubstr(str_split[0],0,4);
      mm=StringSubstr(str_split[0],4,2);
      dd=StringSubstr(str_split[0],6,2);
   }
   else{
      yyyy=IntegerToString(TimeYear(TimeCurrent()),4,'0');
      mm=IntegerToString(TimeMonth(TimeCurrent()),2,'0');
      dd=IntegerToString(TimeDay(TimeCurrent()),2,'0');
      
      if(StringLen(str_split[0])==1){
         shift_day=StringToInteger(str_split[0])-TimeDayOfWeek(TimeCurrent());
         shift_day*=24*60*60;
      }
   }
   
   hh=StringSubstr(str_split[1],0,2);
   mi=StringSubstr(str_split[1],2,2);
   return StringToTime(yyyy+"."+mm+"."+dd+" "+hh+":"+mi)+(int)shift_day;
}
//取引時間定義を生成する
string GetDailyCycleDefinition(int begin,int terminate,int close){
   //前日か検定する
   bool begin_zen,terminate_zen,close_zen;  //前日フラグ
   begin_zen=begin<0?true:false;
   terminate_zen=terminate<0?true:false;
   close_zen=close<0?true:false;
   
   string sRes=NULL;
   for(int idx=1;idx<=5;idx++){
      sRes+=IntegerToString(idx-(begin_zen?1:0))+"_"+IntegerToString((begin+(begin_zen?24:0)),2,'0')+"00,";
      sRes+=IntegerToString(idx-(terminate_zen?1:0))+"_"+IntegerToString((terminate+(terminate_zen?24:0)),2,'0')+"00,";
      sRes+=IntegerToString(idx-(close_zen?1:0))+"_"+IntegerToString((close+(close_zen?24:0)),2,'0')+"00";
      if(idx!=5) sRes+=",";
   }
   return sRes;
}