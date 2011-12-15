/*
"Excitement" - by Konstantin Sokhan
------------------------------------

====================================
This is the Arduino code.
====================================

Thanks to: 
Arduino.cc reference tutorials

*/

//Changeable VARS
//===============
const int numReadings = 10;
//===============

int readings[numReadings];      // the readings from the analog input
int index = 0;                  // the index of the current reading
int total = 0;                  // the running total
int average = 0;                // the average
byte twitter_new_ping;
int lastaverage;
int lastbuttonstate;
int buttonstate;
int buttonfade = 0;

void setup() 
{
  // read serial input (digital) from pin 2
  Serial.begin(9600);
  pinMode(2, INPUT);
  pinMode(A0,INPUT);
  pinMode(13,OUTPUT);

  // initialize all the readings to 0: 
  for (int thisReading = 0; thisReading < numReadings; thisReading++)  readings[thisReading] = 0;          


}

void loop() 
{
  // read lightsensor
  //==============
  total= total - readings[index];         
  readings[index] = analogRead(A0);
  total= total + readings[index];       
  index = index + 1;                    
  if (index >= numReadings) index = 0;                           
  average = total / numReadings;
  
  // read button
  //==============
  buttonstate = digitalRead(2);
  
  if (buttonstate == 1 && buttonfade < 255) 
  {
    buttonfade += 1;
    analogWrite(10, buttonfade);
    // wait for 30 milliseconds to see the dimming effect    
    delay(20);        
  } 
  else if(buttonstate == 0 && buttonfade > 0) 
  {
    buttonfade -= 1;
    analogWrite(10, buttonfade);
    // wait for 30 milliseconds to see the dimming effect    
    delay(20);        
  }
    
  if (buttonstate != lastbuttonstate || average != lastaverage) 
  {
    Serial.print(average);
    Serial.print(",");
    Serial.println(buttonstate);
    
    // update 'last' vars
    lastbuttonstate = buttonstate;
    lastaverage = average;
  }
  

  if (Serial.available()) twitter_new_ping = Serial.read();
  twitter_new_ping = int(twitter_new_ping);
  if (twitter_new_ping > 0) 
  {
      digitalWrite(13, HIGH);
      delay(100);
      digitalWrite(13, LOW);
      twitter_new_ping = 0;
  }
}