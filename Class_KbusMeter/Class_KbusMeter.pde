import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress sc;
NetAddress me;

String ip;
int port = 12321;

void setup() {
  size(500, 500);
  osc = new OscP5(this, port);
  sc = new NetAddress("127.0.0.1", 57120);
  me = new NetAddress("127.0.0.1", 12321);
  ip = osc.ip();
  osc.plug(kbusmeterz, "mk", "/mkkmeter");
  osc.plug(kbusmeterz, "rmv", "/rmvkmeter");
  osc.plug(kbusmeterz, "rmvall", "/rmvallkmeter");
  osc.plug(kbusmeterz, "reckval", "/kval");
  osc.send("/mkkmeter", new Object[]{0, 20.0, 20.0, 25.0, 140.0},me);
}


void draw() {
  background(0);
  kbusmeterz.drw();
}