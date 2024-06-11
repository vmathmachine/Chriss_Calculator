public static class Box {
  
  //////////////// ATTRIBUTES ///////////////
  
  //spatial attributes
  float x=0, y=0; //position WRT parent's surface (or to screen if no parent)
  float w=0, h=0; //width & height
  float r=0;      //corner radius
  
  float dx1=0, dx2=0, dy1=0, dy2=0; //special: how far the drawn edge is from the actual hitbox. Should always be non-negative, and their sums should not exceed the dimensions
  //This should be 0 for pretty much everything, but sometimes it can be good for buttons, in case your button's hitbox is too small but you don't want to expand its drawn size
  
  //drawing attributes
  boolean fill=true, stroke=true; //whether it fills & has a stroke
  float strokeWeight=2;           //stroke weight
  color fillColor, strokeColor;   //fill & stroke color
  
  //other display attributes
  Text[] text = new Text[0]; //the text(s) we display on the box (empty by default)
  PImage image;              //the image to draw (null by default) TODO add this
  
  //parent
  Panel parent; //the panel this is inside of
  Mmio mmio;    //the ancestor panel everything is inside of
  
  //other attributes
  boolean mobile = true; //if true, the box moves with its parent's surface. If false, it stays glued to its parent's window
  boolean active = true; //if active, the box will be displayed and carry out all its duties. If not, it gets ignored until it is active again
  
  //////////////// CONSTRUCTORS ///////////////
  
  Box() { } //default constructor
  
  Box(final float x2, final float y2) { x=x2; y=y2; } //constructor w/ position
  
  Box(final float x2, final float y2, final float w2, final float h2) { //constructor w/ dimensions
    x=x2; y=y2; w=w2; h=h2; //set attributes
  }
  
  Box(final float x2, final float y2, final float w2, final float h2, final float r2) { //constructor w/ full dimensions
    this(x2,y2,w2,h2); r=r2; //set attributes
  }
  
  //////////////// GETTERS ////////////////
  
  float getX() { return !mobile || parent==null ? x : x+parent.getSurfaceX(); } //get x position WRT parent
  float getY() { return !mobile || parent==null ? y : y+parent.getSurfaceY(); } //get y position WRT parent
  
  float getObjX() { return parent==null ? x : x+(mobile ? parent.getObjSurfaceX() : parent.getObjX()); } //get x position on screen (obj=objective)
  float getObjY() { return parent==null ? y : y+(mobile ? parent.getObjSurfaceY() : parent.getObjY()); } //get y position on screen
  
  float getWidth () { return w; } //get width
  float getHeight() { return h; } //get height
  float getRadius() { return r; } //get radius
  
  float[] getDisp() { return new float[] {dx1,dx2,dy1,dy2}; }
  
  Panel getParent() { return parent; } //get parent
  
  boolean   fills() { return   fill; } //get whether it fills
  boolean strokes() { return stroke; } //get whether it strokes
  float getStrokeWeight() { return strokeWeight; } //get strokeWeight
  color getFillColor   () { return    fillColor; } //get fill color
  color getStrokeColor () { return  strokeColor; } //get stroke color
  
  //////////////// SETTERS ////////////////
  
  Box setX(final float x2) { x=x2; return this; } //set x
  Box setY(final float y2) { y=y2; return this; } //set y
  Box setW(final float w2) { w=w2; return this; } //set width
  Box setH(final float h2) { h=h2; return this; } //set height
  Box setR(final float r2) { r=r2; return this; } //set radius
  Box setPos(final float x2, final float y2) { x=x2; y=y2; return this; }
  Box setDims(final float w2, final float h2) { w=w2; h=h2; return this; }
  
  Box setDisp(final float x1, final float x2, final float y1, final float y2) { dx1=x1; dx2=x2; dy1=y1; dy2=y2; return this; }
  
  Box setParent(final Panel p) { //set parent
    if(parent==p) { return this; } //if same parent, do nothing
    
    if(parent!=null) { parent.children.remove(this); } //if currently has a parent, estrange
    if(p!=null) { p.children.add(this); mmio=p.mmio; } //if will have parent, join family
    parent=p;                                          //set parent
    
    return this; //return result
  }
  
  Box setFill        (final boolean f) {         fill=f; return this; }
  Box setStroke      (final boolean s) {       stroke=s; return this; }
  Box setStrokeWeight(final   float s) { strokeWeight=s; return this; }
  
  Box setFill  (final color f) { fillColor  =f; return this; } //set fill color
  Box setStroke(final color s) { strokeColor=s; return this; } //set stroke color
  
  Box setPalette(final Box b) { //copies over all of its color & draw attributes
    fill = b.fill; stroke = b.stroke; //copy whether it has fill/stroke
    strokeWeight = b.strokeWeight;    //copy its stroke weight
    fillColor = b.fillColor; strokeColor = b.strokeColor; //copy its fill & stroke color
    return this; //return result
  }
  
  Box setShape(final Box b) { //copies over the exact shape
    w = b.w; h = b.h; r = b.r; //set the width, height, & radius
    return this;               //return result
  }
  
  Box setText(Text... texts) { //sets the texts
    text = new Text[texts.length]; //initialize array
    for(int n=0;n<texts.length;n++) { text[n] = texts[n]; } //set each element
    return this; //return result
  }
  
  Box setText(String txt, float siz, color col) {
    this.setText(new Text(txt,0.5*w,0.5*h,siz,col,CENTER,CENTER));
    return this;
  }
  
  Box setText(String txt, color col) {
    float wid = mmio.getTextWidth(txt,32); int lines = Mmio.getLines(txt);
    float siz = min(32*(w-2*Mmio.xBuff)/wid, ((h-2*Mmio.yBuff)/lines-0.902)/1.164);
    this.setText(txt,siz,col);
    return this;
  }
  
  Box setText(String txt, color col, float buffX, float buffY) {
    float wid = mmio.getTextWidth(txt,32); int lines = Mmio.getLines(txt);
    float siz = min(32*(w-2*buffX)/wid, ((h-2*buffY)/lines-0.902)/1.164);
    this.setText(txt,siz,col);
    return this;
  }
  
  Box setMobile(final boolean m) { mobile=m; return this; }
  
  Box setActive(final boolean a) { active=a; return this; }
  
  ////////////////////////////// DRAWING/DISPLAY //////////////////////////////////
  
  void display(final PGraphics graph, float buffX, float buffY) { //displays on a particular PGraphics (whose top left corner is at buffX, buffY on the parent)
    //float x3 = getObjX()-x2, y3 = getObjY()-y2; //get location where you should actually draw
    float x3 = getX()-buffX, y3 = getY()-buffY; //get location where you should actually draw
    setDrawingParams(graph);                    //set drawing parameters
    graph.rect(x3,y3,w,h,r);                    //draw rectangle
    
    for(Text t : text) { //loop through all the texts
      t.display(graph,-x3,-y3); //draw them all
    }
  }
  
  void setDrawingParams(final PGraphics graph) {
    if(fill) { graph.fill(fillColor); } else { graph.noFill(); }
    if(stroke) { graph.stroke(strokeColor); graph.strokeWeight(strokeWeight); } else { graph.noStroke(); }
  }
  
  
  ////////////////////////// HITBOX ///////////////////////////////////
  
  protected boolean hitboxNoCheck(final float x2, final float y2) {
    final float x3=x2-getObjX(), y3=y2-getObjY();                    //get position relative to top left corner
    return active && x3>=-dx1 && y3>=-dy1 && x3<=w+dx2 && y3<=h+dy2; //determine if it's within the bounding box (account for displacement)
  }
  
  protected boolean hitboxNoCheck(final Cursor curs) { return hitboxNoCheck(curs.x,curs.y); }
  
  boolean hitbox(final float x2, final float y2) {
    return (parent==null || parent.hitbox(x2,y2)) && hitboxNoCheck(x2,y2);
  } //if not in parent's hitbox, automatic false. Otherwise, check hitbox
  
  boolean hitbox(final Cursor curs) { return hitbox(curs.x,curs.y); }
}

static class Text {
  String text; //text
  float x, y;  //text position
  float size;  //text size
  color fill;  //text color
  int alignX, alignY; //text alignment
  
  Text(String txt, float x2, float y2, float siz, color col, int alx, int aly) { //constructor w/ attributes
    text = txt; x=x2; y=y2; size=siz; fill=col; alignX=alx; alignY=aly;
  }
  
  /*@Override
  public Text clone() {
    return new Text(text,x,y,size,fill,alignX,alignY);
  }
  
  @Override
  public boolean equals(final Object obj) {
    if(!(obj instanceof Text)) { return false; }
    Text txt = (Text)obj;
    return text.equals(txt.text) && size==txt.size && fill==txt.fill;
  }
  
  @Override
  public int hashCode() { return 961*fill+31*Float.floatToIntBits(size)+text.hashCode(); }*/
  
  //TODO see if these /|\ are necessary. They probably aren't
  
  @Override
  public String toString() { return text; } //string is the string
  
  public String getText() { return text; } //text is the text
  
  public void display(final PGraphics graph, float buffX, float buffY) {    //displays itself onto the pgraphics, assuming the pgraphics is at position buffX,buffY WRT the parent
    graph.fill(fill); graph.textSize(size); graph.textAlign(alignX,alignY); //set drawing parameters
    graph.text(text,x-buffX,y-buffY);                                       //draw
  }
  
  
  
}

//clone, equals, hashCode, toString

//BOOL: fill, stroke
//FLOAT: strokeWeight, textSize
//COLOR: fillColor, strokeColor
//INT: textAlign, textAlignY
