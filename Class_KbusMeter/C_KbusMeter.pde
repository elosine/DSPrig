// DECLARE/INITIALIZE CLASS SET
KbusMeterSet kbusmeterz = new KbusMeterSet();

/**
 *
 *
 /// PUT IN SETUP ///
 osc.plug(kbusmeterz, "mk", "/mkkbusmeter");
 osc.plug(kbusmeterz, "rmv", "/rmvkbusmeter");
 osc.plug(kbusmeterz, "rmvall", "/rmvallkbusmeter");
 /// PUT IN DRAW ///
 kbusmeterz.drw();
 */


class KbusMeter {

  // CONSTRUCTOR VARIALBES //
  int ix;
  float x, y, w, h;
  // CLASS VARIABLES //
  float l, r, t, b, c, m;
  float val = 0.0;

  // CONSTRUCTORS //

  /// Constructor 1 ///
  KbusMeter(int aix, float ax, float ay, float aw, float ah) {
    ix = aix;
     x=ax;
     y=ay;
     w=aw;
     h=ah;
    l = x;
    r = x+w;
    t = y;
    b = y+h;
    c = l + (w/2);
    m = t + (h/2);
  } //end constructor 1

  //  DRAW METHOD //
  void drw() {
    //bounding box
    stroke(255, 255, 0);
    strokeWeight(4);
    rectMode(CORNER);
    noFill();
    rect(l, t, w, h);
    //get val
    osc.send("/getkval", new Object[]{ip, port, ix}, sc);
    float gval = map(val, 0.0, 1.0, 0.0, h);
    //fill rect

    noStroke();
    fill(153, 255, 0);
    rect(l, b-gval, w, gval);
  } //End drw

 
  //
  //
}  //End class

////////////////////////////////////////////////////////////
/////////////   CLASS SET     //////////////////////////////
////////////////////////////////////////////////////////////

class KbusMeterSet {
  ArrayList<KbusMeter> cset = new ArrayList<KbusMeter>();

  // Make Instance Method //
  void mk(int ix, float x, float y, float w, float h) {
    cset.add( new KbusMeter(ix,x,y,w,h) );
  } //end mk method

  // Remove Instance Method //
  void rmv(int ix) {
    for (int i=cset.size ()-1; i>=0; i--) {
      KbusMeter inst = cset.get(i);
      if (inst.ix == ix) {
        cset.remove(i);
        break;
      }
    }
  } //End rmv method

  // Draw Set Method //
  void drw() {
    for (KbusMeter inst : cset) {
      inst.drw();
    }
  }//end drw method

  // Recieve Control Value //
  void reckval(int ix, float kval) {
    for (int i=cset.size ()-1; i>=0; i--) {
      KbusMeter inst = cset.get(i);
      if (inst.ix == ix) {
        inst.val = kval;
        break;
      }
    }
  } //End rmv method
  //
  //
} // END CLASS SET CLASS