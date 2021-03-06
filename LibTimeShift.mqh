//+------------------------------------------------------------------+
//|                                                 LibTimeShift.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict
//+------------------------------------------------------------------+
//| 指定時間前のバーが何本目であるかを返す                           |
//+------------------------------------------------------------------+
class clsTime2BarShift{
   private:
      int timeunit;
   public:
      clsTime2BarShift();
      ~clsTime2BarShift();
      int getBarShift(int, int, int, int);
      datetime getFutureTime(int, int);
      void getBarCount(int&, int&, int);
};
//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
clsTime2BarShift::clsTime2BarShift(void){
   //単位時間を求める
   int _TimeUnit = INT_MAX;
   for(int i = 0; i < 100; i++){
      int _ThisUnitTime = (int)(iTime(Symbol(), 0, i) - iTime(Symbol(), 0, i + 1));
      _TimeUnit = _TimeUnit < _ThisUnitTime ? _TimeUnit : _ThisUnitTime;
   }
   timeunit = _TimeUnit;
}
//+------------------------------------------------------------------+
//| 時間からバーの本数を取得する                                     |
//+------------------------------------------------------------------+
int clsTime2BarShift::getBarShift(int _minutes,int _hours,int _days,int _shift){
   //基準となるバーを求める
   datetime _based_bar = iTime(Symbol(), 0, _shift);
   
   //何秒前を取得するかを算出する
   int _seconds = 0;
   _seconds += _minutes * 60;
   _seconds += _hours * 60 * 60;
   _seconds += _days * 60 * 60 * 24;
   _seconds += (int)(iTime(Symbol(), 0, 0) -_based_bar);
   
   //厳密なバー本数を求める
   int _exact_bar = iBarShift(Symbol(), 0, _seconds, true);
   return _exact_bar;
}
//+------------------------------------------------------------------+
//| 未来の時刻のバー（予定値）を求める                               |
//+------------------------------------------------------------------+
datetime clsTime2BarShift::getFutureTime(int _minutes,int _hours){
   int _seconds = 0;
   _seconds += _minutes * 60;
   _seconds += _hours * 60 * 60;
   return _seconds / timeunit;
}
//+------------------------------------------------------------------+
//| 指定バー本数が何時間何分後かを求める                             |
//+------------------------------------------------------------------+
void clsTime2BarShift::getBarCount(int &_minutes,int &_hours,int _bars){
   //バー本数と単位時間をかける
   int _seconds = _bars * timeunit;
   
   //回答をセットする
   
}