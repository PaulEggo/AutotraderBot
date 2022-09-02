#include <Trade/Trade.mqh>

CTrade trade;
ulong posTicket = 0;
datetime prev_time;

int cur_positions = 0;
int bar_counter = 0;
int consecutive_bars = 3;
bool condition_fulfilled = false;

datetime exp_date = D'2022.03.19';

bool flag = true;

int OnInit() { 
   Print("AutoTradeBot Initialized");   
   
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   
   Print("AutoTradeBot Deinitialized");
}

bool isNewBar(const bool print_log = true) { 
   /*if(flag) {
      prev_time = iTime(_Symbol, PERIOD_CURRENT, 0); 
      flag = false;
      return(false);
   }*/
   
   datetime currbar_time = iTime(_Symbol, PERIOD_CURRENT, 0); 
   
   // If open time changes, a new bar has arrived. 
   if(currbar_time > prev_time) {
      prev_time = currbar_time;  
      return (true); 
   } 
   
   return (false); 
}


void OnTick() {

   /*if(TimeCurrent() > exp_date) {
      return;
   }*/

   int handleHandler = iBands(Symbol(), Period(), 46, 20, 0.35, PRICE_CLOSE);
   
   double UpperBandArray[];
   double LowerBandArray[];
   double MidBandArray[];
   
   CopyBuffer(handleHandler, 0, 0, 2, MidBandArray);
   CopyBuffer(handleHandler, 1, 0, 2, UpperBandArray);
   CopyBuffer(handleHandler, 2, 0, 2, LowerBandArray);

   double open  = iOpen(Symbol(), Period(), 0);
   double high  = iHigh(Symbol(), Period(), 0);
   double low   = iLow(Symbol(), Period(), 0);   
   double close = iClose(Symbol(), Period(), 0);
   
   //Print("Open Price: " + DoubleToString(open) + ", Close Price: " + DoubleToString(close));
   //Print("Low Price: " + DoubleToString(low) + ", High Price: " + DoubleToString(high));
   //Print("Upper Band: " + DoubleToString(UpperBandArray[0]) + ", Lower Band: " + DoubleToString(LowerBandArray[0]));
   
   bool wasDownThenUpBBTop = (open < UpperBandArray[1]) && (close > UpperBandArray[1]) ? true : false;
   if(wasDownThenUpBBTop) {
      Print("Was bellow the Upper Band then went above it");
   }
   bool wasUpThenDownBBTop = (open > UpperBandArray[1]) && (close < UpperBandArray[1]) ? true : false;
   if(wasUpThenDownBBTop) {
      Print("Was above the Upper Band then went bellow it");
   }
   bool wasUpthenDownBBBottom = (open > LowerBandArray[1]) && (close < LowerBandArray[1]) ? true : false;
   if(wasUpthenDownBBBottom) {
      Print("Was above the Lower Band then went bellow it");
   }
   bool wasDownThenUpBBBottom = (open < LowerBandArray[1]) && (close > LowerBandArray[1]) ? true : false;
   if(wasDownThenUpBBBottom) {
      Print("Was bellow the Upper Band then went above it");
   }
   
   // If a Position in open
   if(posTicket > 0 && PositionSelectByTicket(posTicket)) {
      int posType = (int)PositionGetInteger(POSITION_TYPE);
      
      // Calculate n consecutive bars condition
      if(isNewBar() && !condition_fulfilled) {
         if(posType == POSITION_TYPE_BUY) {   
            double lowT   = iLow(Symbol(), Period(), 1); 
            if(lowT > UpperBandArray[0]) {
               bar_counter++;
            }
            else {
               bar_counter = 0;
            }
            
            if(bar_counter == consecutive_bars) {
               condition_fulfilled = true;  
            }        
         }
         else if(posType == POSITION_TYPE_SELL) {
            double highT   = iHigh(Symbol(), Period(), 1); 
            if(highT < LowerBandArray[0]) {
               bar_counter++;
            }
            else {
               bar_counter = 0;
            }
            
            if(bar_counter == consecutive_bars) {
               condition_fulfilled = true;
               Print("Consecutive bars condition fulfilled");
            }     
         }
      }
   
      // Update Stop Losses
      if(posType == POSITION_TYPE_BUY) {
         if(condition_fulfilled) {
            trade.PositionModify(posTicket, MidBandArray[1], 0);
         }
         else {
            trade.PositionModify(posTicket, LowerBandArray[1], 0);
         }           
      }
      else if(posType == POSITION_TYPE_SELL) {
         if(condition_fulfilled) {
            trade.PositionModify(posTicket, MidBandArray[1], 0);
         }
         else {
            trade.PositionModify(posTicket, UpperBandArray[1], 0);
         }   
      }  
   }
   
   
   if(wasDownThenUpBBTop && posTicket == 0) {
      // Open Buy Position
      cur_positions = 1;
      trade.Buy(1, _Symbol, 0, LowerBandArray[1], 0, NULL);
      posTicket = trade.ResultOrder();
      prev_time = iTime(_Symbol, PERIOD_CURRENT, 0); 
      Print("Open new buy positon");
   }
   else if(wasUpthenDownBBBottom && posTicket == 0) {
      // Open Sell Position
      cur_positions = 1;
      trade.Sell(1, _Symbol, 0, UpperBandArray[1], 0, NULL);
      posTicket = trade.ResultOrder();
      prev_time = iTime(_Symbol, PERIOD_CURRENT, 0);
      Print("Open new sell positon");
   }
   else {
      // No Action
   }
   
   return;
}

void OnTrade() {

   int numberOfPositions = PositionsTotal();
   
   if(numberOfPositions < cur_positions) {
      Print("Close positon");
      posTicket = 0;   
      cur_positions = 0;
      bar_counter = 0;
      condition_fulfilled = false;
   }
}
