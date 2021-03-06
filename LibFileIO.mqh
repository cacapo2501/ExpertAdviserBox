//+------------------------------------------------------------------+
//|                                                    LibFileIO.mqh |
//|                                                         Takamaro |
//|                   https://github.com/cacapo2501/ExpertAdviserBox |
//+------------------------------------------------------------------+
#property copyright "Takamaro"
#property link      "https://github.com/cacapo2501/ExpertAdviserBox"
#property strict

bool LibFIOWriteLogFlag;
int __gFileHandle;
string __gLogLine;
//+------------------------------------------------------------------+
//| ログファイルオープン処理                                         |
//+------------------------------------------------------------------+
void LibFIOOpenLogFile(string aLogFileName){
   if(!LibFIOWriteLogFlag) return;
   
   __gFileHandle = FileOpen(aLogFileName + ".log", FILE_WRITE | FILE_TXT);
   __gLogLine = NULL;
   return;
}
//+------------------------------------------------------------------+
//| ログファイルクローズ処理                                         |
//+------------------------------------------------------------------+
void LibFIOCloseLogFile(){
   if(!LibFIOWriteLogFlag) return;
   
   FileClose(__gFileHandle);
}
//+------------------------------------------------------------------+
//| パラメータログ出力処理                                           |
//+------------------------------------------------------------------+
void LibFIOWriteParameter(string aName, double aValue, int aDigits = 5){
   __gLogLine = aName + " = " + DoubleToString(aValue, aDigits);
   LibFIOFlushLogLine();
}
void LibFIOWriteParameter(string aName, int aValue){
   __gLogLine = aName + " = " + IntegerToString(aValue);
   LibFIOFlushLogLine();
}
void LibFIOWriteParameter(string aName, string aValue){
   __gLogLine = aName + " = \"" + aValue + "\"";
   LibFIOFlushLogLine();
}
//+------------------------------------------------------------------+
//| ログに境界線を入れる                                             |
//+------------------------------------------------------------------+
void LibFIOWriteHorizontalBar(string aChar){
   for(int i = 0; i < 25; i++){
      __gLogLine += aChar;
   }
   LibFIOFlushLogLine();
}
//+------------------------------------------------------------------+
//| ログ出力処理                                                     |
//+------------------------------------------------------------------+
void LibFIOFlushLogLine(){
   //ログを出さないときは処理終了
   if(!LibFIOWriteLogFlag){
      __gLogLine = NULL;
      return;
   }
   
   //出力変数を初期化する
   string lMainString = NULL;
   
   //ログ出力情報を取得する
   lMainString += TimeToString(TimeCurrent(), TIME_DATE) + ",";
   lMainString += TimeToString(TimeCurrent(), TIME_SECONDS) + ",";
   
   //本文を設定する
   lMainString += __gLogLine;
   
   //改行を挿入する
   lMainString += "\n";
   
   //ログに出力する
   FileWriteString(__gFileHandle, lMainString);
   __gLogLine = NULL;
}
