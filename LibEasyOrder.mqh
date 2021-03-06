//+------------------------------------------------------------------+
//|                                                 LibEasyOrder.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| 注文関数                                                         |
//+------------------------------------------------------------------+
void SendBuy(int aMagic, double aStoploss, double aTakeprofit){
   bool foo = OrderSend(Symbol(), OP_BUY, 0.1, Ask, 0, Ask - aStoploss, 
                           Ask + aTakeprofit, NULL, aMagic, 0, clrBlue);
}
void SendSell(int aMagic, double aStoploss, double aTakeprofit){
   bool foo = OrderSend(Symbol(), OP_SELL, 0.1, Bid, 0, Bid + aStoploss, 
                           Bid - aTakeprofit, NULL, aMagic, 0, clrRed);
}
void SendClose(int aMagic){
   int lTicket = GetTicket(aMagic);
   if(lTicket == -1) return;
   
   if(OrderType() == OP_BUY){
      bool foo = OrderClose(lTicket, OrderLots(), Bid, 0, clrAqua);
   }
   else{
      bool foo = OrderClose(lTicket, OrderLots(), Ask, 0, clrMagenta);
   }
}
void SendMod(int aMagic, double aStoploss, double aTakeprofit){
   int lTicket = GetTicket(aMagic);
   if(lTicket == -1) return;
   
   if(OrderType() == OP_BUY){
      bool foo = OrderModify(lTicket, Ask, Ask - aStoploss, 
                                       Ask + aTakeprofit, 0, clrLime);
   }
   else{
      bool foo = OrderModify(lTicket, Bid, Bid + aStoploss, 
                                       Bid - aTakeprofit, 0, clrOrange);
   }
}
int GetTicket(int aMagic){
   for(int i = OrdersTotal(); i >= 0; i--){
      if(OrderSelect(i, SELECT_BY_POS)){
         if(OrderMagicNumber() == aMagic && OrderSymbol() == Symbol()){
            return OrderTicket();
         }
      }
   }
   
   return -1;
}