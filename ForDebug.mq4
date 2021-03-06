//+------------------------------------------------------------------+
//|                                                     ForDebug.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

#include "..\ExpertAdviserBox\LibOrderManager.mqh"

int __slippage = 0;
ClsOrderManager *g_obj_ordmanage = NULL;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   //注文管理インスタンスを作る
   g_obj_ordmanage = new ClsOrderManager(1.0, true, true);
   if(!g_obj_ordmanage.initialized) return(INIT_FAILED);
   
   //Orderクラスデバッグ
   fClsOrderDebugger(Symbol(), OP_BUY, 10.0, 1.0, 0.1, 0, clrNONE, true);    //正常・買い
   fClsOrderDebugger(Symbol(), OP_SELL, 10.0, 1.0, 0.1, 1000, clrYellow);    //正常・売り
   
   fClsOrderDebugger(Symbol() + "foo", OP_BUY, 10.0, 1.0, 0.1, 0, clrNONE);  //通貨ペア異常
   fClsOrderDebugger(Symbol(), -1, 10.0, 1.0, 0.1, 0, clrNONE);              //取引種別異常
   fClsOrderDebugger(Symbol(), OP_BUY, 0.0, 1.0, 0.1, 0, clrNONE);           //損切り幅異常
   fClsOrderDebugger(Symbol(), OP_BUY, 10.0, 0, 0.1, 0, clrNONE);            //利食い幅異常
   fClsOrderDebugger(Symbol(), OP_BUY, 100000.0, 1.0, 0.1, 0, clrNONE);      //損切り価格異常
   fClsOrderDebugger(Symbol(), OP_SELL, 0.0, 100000.0, 0.1, 0, clrNONE);     //利食い価格異常
   fClsOrderDebugger(Symbol(), OP_BUY, 10.0, 1.0, 0, 0, clrNONE);            //ロット数異常
   
   Print("◆デバッグスタート◆");
   //return(INIT_FAILED);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   //注文管理インスタンスを削除する
   delete g_obj_ordmanage;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {   
   //StandardFunction
   
   //SimpleOrderControlクラスは仕様の誤認識による計画倒れ。
   
   //OrderManagerクラスデバッグ
   static int ___int_last_day = 0;  //最終起動日
   static int ___int_last_hour = 0; //最終起動時間帯
   
   //この時間帯初めてのティック処理？
   if(___int_last_day != TimeDay(TimeCurrent()) || ___int_last_hour != TimeHour(TimeCurrent())){
      //午前中？
      if(TimeHour(TimeCurrent()) < 12){
         //注文する
         if(MathMod(TimeHour(TimeCurrent()), 2) == 0){
            g_obj_ordmanage.addOrder(OP_BUY, false, 0.05, 80, 60);
         }
         else{
            g_obj_ordmanage.addOrder(OP_SELL, false, 0.05, 80, 60);
         }
      }
      else{
      
      }
   }
      
   //日付・時間帯を更新する
   ___int_last_hour = TimeHour(TimeCurrent());
   ___int_last_day = TimeDay(TimeCurrent());
  }
//+------------------------------------------------------------------+
//| OrderManagerクラス                                               |
//+------------------------------------------------------------------+
void fClsOrderDebugger(string _str_symbol, int _int_command, double _dbl_stoploss, double _dbl_takeprofit, double _dbl_lots, int _int_magic, color _clr_arrow, bool _bln_twice_closing = false){
   ClsOrder *clorder = new ClsOrder(_str_symbol, _int_command, 0, _dbl_stoploss, _dbl_takeprofit, _dbl_lots, _int_magic, _clr_arrow, true);
   clorder.fSendClose();
   if(_bln_twice_closing) clorder.fSendClose();
   delete clorder;
}