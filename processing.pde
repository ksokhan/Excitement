/*
"Excitement" - by Konstantin Sokhan
------------------------------------

====================================
This is the processing code.
====================================

Thanks to:
-->	processing serial communication (processing.org app example)
-->	rss feed processing:
	http://btk.tillnagel.com/tutorials/rss-feeds-processing.html
-->	and most importantly, threading!
	http://wiki.processing.org/w/Threading

*/

// SERIAL VARS
//============
import processing.serial.*;
Serial my_port;                          // Create object from Serial class
int rx_byte;                             // Variable for data received from the serial port
// input vars
float[] vals;
int button_pressed = 0;
int buttonoff = 0;
float ltsensor;
String noserialsignal = "ERROR --> Could not find any serial data... please check connections";

//RSS VARIABLES
//================
int rss_count = 0;
String rss_last = "";
Load_twitter_data rssthread;

//BLOB VARIABLES
//================
blobsystem b;


void setup() 
{
  //set up serial

    String portName = Serial.list()[0];
    my_port = new Serial( this, portName, 9600 );  
    my_port.bufferUntil('\n');

  
  
  //drawing setup
  size( 800, 500 );                      // Window size in pixels
  ellipseMode(CENTER);
  noStroke();
  smooth();
  
  // START RSS data thread
  //======================
  rssthread = new Load_twitter_data(1500);
  rssthread.start();
  
  // initialize the blob object
  //===========================
  b = new blobsystem(rss_count);
  
  println("///////////// \n///////////// \n Starting... \n///////////// \n/////////////");
  
}

void draw() {
  if (noserialsignal != null) {println(noserialsignal); noserialsignal = null;};
  background(70+(button_pressed/2)+ltsensor/3 , 10 + ltsensor/4 , 50+ltsensor/3 , 10);                 //   use it to shade the background color.

  b.run();

  while (rss_count > 0) 
  {  
    my_port.write(rss_count);  //send to serial (arduino) so it can blink the light...
    b.addBlob();
    rss_count -= 1;
  }
  
  
    // set bounds and increase/decrease on mouse pressed
    if (vals[1] == 1 && button_pressed < 255) 
    {
      button_pressed++;
    } 
    else if(vals[1] == 0 && button_pressed > 0)
    {
      button_pressed--;
    }
 
}


void serialEvent( Serial myPort )
{
  noserialsignal = null;
  String inString = myPort.readStringUntil('\n');
  if (inString != null) 
  {
    // trim off any whitespace:
    inString = trim(inString);
    // split the string on the commas and convert the 
    // resulting substrings into an integer array:
    vals = float(split(inString, ","));
    if (frameCount < 2)  return;
    ltsensor = map(vals[0], 0, 1023, 0, 255);
    buttonoff = int(vals[1]);
  }
}

class Load_twitter_data extends Thread 
{
  boolean running = true;
  int waittime;
  String url = "http://search.twitter.com/search.atom?q=exciting";  
  
  Load_twitter_data (int w) 
  {
    waittime = w;
  }
  
  void start () 
  {
    super.start();
  }
  
  void run () 
  {
    while (running = true)
    {
      XMLElement rss = new XMLElement(getPapplet(), url);
      int i = 0;
      String val = "just as long as its not blank";
      for (i = 10; val.equals(rss_last) == false && i < rss.getChildCount(); i++)
      {
        XMLElement a = rss.getChild(i).getChild(0);
        val = a.getContent();
      }
      //subtract 11, since they are part of the header, not actual entries.
      rss_count = i - 11; 
      //if (rss_count > 0) rss_count = 0;   
      //only return available when there is new data from feed.
      if (rss_count > 0) 
      {
        // update last rss to latest one.
        XMLElement a = rss.getChild(10).getChild(0);
        rss_last = a.getContent();
      }
      //System.out.println("thread is done!");
      try {sleep((long)(waittime));} catch (Exception e) {}
    }
  }
}


class blobsystem 
{
  ArrayList blobs;
  
  blobsystem(int num) 
  {
    blobs = new ArrayList();              // Initialize the arraylist
    for (int i = 0; i < num; i++) 
    {
      blobs.add(new blob(random(100)));    // Add "num" amount of particles to the arraylist
    }
  }
  
  void run() 
  {
    // Cycle through the ArrayList backwards b/c we are deleting
    for (int i = blobs.size()-1; i >= 0; i--)
    {
      blob p = (blob) blobs.get(i);
      p.run();
      if (p.dead()) 
      {
        blobs.remove(i);
      }
    }
  }

  void addBlob() 
  {
    blobs.add(new blob(random(100)));
  }
  
  // A method to test if the particle system still has blobs
  boolean dead() 
  {
    if (blobs.isEmpty())
    {
      return true;
    } else {
      return false;
    }
  }
}


class blob
{
  PVector loc;
  PVector vel;
  //PVector acc;
  float zindex;
  float r;
  float timer;
  
  blob(float z) 
  {
    zindex = z;
    //acc = new PVector(0,0,0); // new PVector(0,(button_pressed/200));
    vel = new PVector(random(-1,1),random(-1,1));
    loc = new PVector(int(width/2 - 5 + random(-100,100)), int(height/2 - 5 + random(-100,100)) );
    r = 5.0;
    timer = 300.0;
  }

  void run() 
  {
    update();
    render();
  }

  // Method to update location
  void update()
  {
    //vel.add(acc);
    loc.add(vel);
    timer -= 0.09;
    
    //adds accelleration into centre if button pressed
    if (buttonoff == 1)
    {
      if (loc.x < width/2) vel.add(0.1,0,0);
      if (loc.y < height/2) vel.add(0,0.1,0);
      if (loc.x > width/2) vel.add(-0.1,0,0);
      if (loc.y > height/2) vel.add(0,-0.1,0);
    }
    
    // make them kind of go to the centre.... a bit.
    if (frameCount%20 == 0)
    {
      if (loc.x < width/2) vel.add(0.2,0,0);
      if (loc.y < height/2) vel.add(0,0.2,0);
      if (loc.x > width/2) vel.add(-0.2,0,0);
      if (loc.y > height/2) vel.add(0,-0.3,0);
    }
    
    //slow down speed
      if (vel.mag() > 5) vel.div(1.3);

    
    //wraparound to other side as they go over edge... 
    //nice optimized code from: http://processing.org/learning/topics/flocking.html
    if (loc.x <= r/2) vel.x = abs(vel.x);
    if (loc.y <= r/2) vel.y = abs(vel.y);
    if (loc.x >= width-r/2) vel.x = -abs(vel.x);
    if (loc.y >= height-r/2) vel.y = -abs(vel.y);
    
  }

  // Method to display
  void render()
  {
    ellipseMode(CENTER);
    fill(200+(ltsensor/4),200+(ltsensor/3),200+(ltsensor/4), timer + zindex);
    r = 4.0 + zindex / 60 + timer / 40;
    ellipse(loc.x,loc.y,r,r);
  }
  
  // Is the particle still useful?
  boolean dead() 
  {
    if (timer + zindex <= 0.0)
    {
      return true;
    } else {
      return false;
    }
  }

}

// function for XMLElement.... needs the parent (PApplet) while its inside of a class.
PApplet getPapplet ()
{
    return this;
}
