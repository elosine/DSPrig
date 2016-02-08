import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress sc;

float x = 100;
float y = 100;
float w = 50;
float h = 100;
float l,r,t,b,c,m; 
float val = 0.0;
String ip;
int port = 12321;



void setup(){
  size(500,500);
  osc = new OscP5(this, port);
  sc = new NetAddress("127.0.0.1", 57120);
  osc.plug(this, "reckval", "/kval");
  l = x;
  r = x+w;
  t = y;
  b = y+h;
  c = l + (w/2);
  m = t + (h/2);
  ip = osc.ip(); 
}


void draw(){
  background(0);
  //bounding box
  stroke(255,255,0);
  strokeWeight(4);
  rectMode(CORNER);
  noFill();
  rect(l,t,w,h);
  //get val
  osc.send("/getkval", new Object[]{ip,port,0}, sc);
  float gval = map(val, 0.0, 1.0, 0.0, h);
    //fill rect

  noStroke();
  fill(153, 255, 0);
  rect(l, b-gval, w, gval);
  
  
}

void reckval(int bus, float kval){
  val = kval;
}