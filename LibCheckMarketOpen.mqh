//+------------------------------------------------------------------+
//|                                           LibCheckMarketOpen.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

//+------------------------------------------------------------------+
//| isTokyoOpen                                                      |
//|                                                                  |
//| 東京市場がオープンしているかを検定する                           |
//| GMTで0:00～6:00なら正の値、それ以外は負数を戻す                  |
//| <<引数>>                                                         |
//| datetime       aDateTime             検定する日時                |
//| double         aTimeDifference       時差(-12～+12)              |
//|                                                                  |
//| <<戻り値>>     double                市場がクローズするまでの秒  |
//|                                      ※負数のときはクローズ中    |
//+------------------------------------------------------------------+
double isTokyoOpen(datetime aDateTime, double aTimeDifference){
   //補正後日付を求める
   datetime _Check = aDateTime + aTimeDifference * 60 * 60;
   //検定日は平日？
   int _Weekday = TimeDayOfWeek(_Check);
   if(_Weekday == 0 || _Weekday == 6) return DBL_MIN;
   
   //時間を求める
   datetime _CloseTime = StrToTime("6:00"); //クローズ時刻
   
   //検定値を返す
   return _CloseTime - _Check;
}
//+------------------------------------------------------------------+
//| isLondonOpen                                                     |
//|                                                                  |
//| ロンドン市場がオープンしているかを検定する                       |
//| 冬時間GMTで8:00～16:00なら正の値、それ以外は負数を戻す           |
//| 夏時間GMTで7:00～15:00なら正の値、それ以外は負数を戻す           |
//| <<引数>>                                                         |
//| datetime       aDateTime             検定する日時                |
//| double         aTimeDifference       時差(-12～+12)              |
//|                                                                  |
//| <<戻り値>>     double                市場がクローズするまでの秒  |
//|                                      ※負数のときはクローズ中    |
//+------------------------------------------------------------------+
double isLondonOpen(datetime aDateTime, double aTimeDifference){
   //補正後日付を求める
   datetime _Check = aDateTime + aTimeDifference * 60 * 60;
   //検定日は平日？
   int _Weekday = TimeDayOfWeek(_Check);
   if(_Weekday == 0 || _Weekday == 6) return DBL_MIN;
   
   //時間を求める
   datetime _CloseTime; //クローズ時刻
   //夏時間なら15:00をセットする
   if(isLondonSummerTime(_Check)) _CloseTime = StrToTime("15:00");
   //冬時間なら16:00をセットする
   else                           _CloseTime = StrToTime("16:00");
   
   //検定値を返す
   return _CloseTime - _Check;
}
//+------------------------------------------------------------------+
//| isLondonSummerTime                                               |
//|                                                                  |
//| ロンドンがサマータイム実施中かを検定する                         |
//| <<引数>>                                                         |
//| datetime       aDateTime             検定する日時                |
//| double         aTimeDifference       時差(-12～+12)              |
//|                                                                  |
//| <<戻り値>>     bool                  実施中フラグ                |
//|                                      ※Trueのときは実施中        |
//+------------------------------------------------------------------+
bool isLondonSummerTime(datetime aDateTime, double aTimeDifference){
   
}