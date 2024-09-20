import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import vsync.*; 
import java.util.Iterator; 
import java.util.Stack; 
import java.util.EnumMap; 
import complexnumbers.*; 
import java.awt.datatransfer.Clipboard; 
import java.awt.datatransfer.StringSelection; 
import java.awt.datatransfer.Transferable; 
import java.awt.datatransfer.DataFlavor; 
import java.awt.datatransfer.UnsupportedFlavorException; 
import java.awt.Toolkit; 
import java.math.BigInteger; 
import java.util.EnumMap; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class Calculator_5 extends PApplet {














/*import android.app.Activity;
import android.view.WindowManager;
import android.view.View;
import android.os.*;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.Context;
import android.app.Activity;
import android.os.Looper;

import android.content.SharedPreferences;*/

static int debugCount = 0;

Mmio io;

long time = 0, timePrev = 0;
long timeLastFrame;

static long timeRec[] = new long[32]; //DEBUG this is used to measure how much time each part of a specific process takes
static long timeRecSq[] = new long[32]; //this will measure the square of all those (so we can get the standard deviation)
static long numTimesRec = 0;         //this is how many times we've recorded the times taken (so that we can show times in milliseconds)
static long sumTimeSq = 0;           //this will record the sum of the SQUARES of times taken to perform an entire iteration
static boolean showPerformance = false;     //this boolean is just whether or not we wanna show those measurements

static CalcHistory history; //this stores and displays the calculator history
static EquatList equatList; //this stores and displays the equations we're gonna graph out
static KeyPanel ctrlPanel; //this stores the entirety of the key pad

boolean saveWorks = true;

//static long init;

static Panel keyPad, graphMenu; //panel to show history, to hold the list of equations, to list out the 2D equations, to list out the 3D equations, to show the keypad, and to show the graph menu
//static Panel graphMenu;
static Textbox query; //query field in calculator mode

Graph   grapher2D; //the grapher used to graph in 2D
Graph3D grapher3D; //the grapher used to graph in 3D

static GraphMode keypadMode = GraphMode.NONE; //this helps us identify which variables need to be available on the keypad
boolean showExtraKeys = false; //whether or not we're currently displaying the extra keys at the bottom

PGraphics defDrawer; //pgraphics object to display using the default engine

static char dirChar;

final static float relativeMarginWidth = 0.037f;

static boolean pcOrMobile = false; //true means pc, false means mobile (determines how the interface gets initialized)
//TODO make something a little less...odd...than the above solution

public void settings() {
  System.setProperty("jogl.disable.openglcore", "false"); //get the thing to work properly
  size(450,900,P2D);
}

public void setup() {
  //size(450,900,P2D);
  
  dirChar = directoryCharacter();
  
  Textbox.defaultHandleRadius = 0.023f*width;
  
  io = new Mmio(this);
  io.cursors.add(new Cursor(mouseX,mouseY)); //PC only
  //androidInitClipboard(this);     //Android only
  //androidInitSharedPreferences(); //Android only
  interfaceInit(io);
  
  grapher2D = new Graph(width/2.0f,height/2.0f,height/12.0f).setVisible(false);
  grapher3D = new Graph3D(0,0,0,width,(int)(0.9f*height),1).setVisible(false);
  
  equatList.grapher2D = grapher2D;
  equatList.grapher3D = grapher3D;
  
  if(saveWorks) { //if saving works
    history.loadFromDisk("saves"+dirChar+"History"); //load the history from the disk
    loadEquations(); //load graphs from disk
  }
  
  //init = System.currentTimeMillis();
  
  time = timePrev = System.currentTimeMillis();
  //Complex.omit_Option = false;
  
  defDrawer = createGraphics(width,height);
}

public void draw() {
  background(0);
  time = System.currentTimeMillis();
  
  if(io.keyLast!=null && time-io.keyTime>500 && (time-io.keyTime)%30 < (timePrev-io.keyTime)%30) { //if needed, update the keys we press and hold
    io.keyPresser(io.keyLast, io.keyCodeLast, true);
  }
  
  io.targetAllChildren(); //perform the targeting algorithm on all boxes
  //io.updateCursorsAndroid(touches); //Android only, records all changes in the touches[] array and updates accordingly
  io.updateButtonHold(time, timePrev); //update the buttons that are being held down
  io.updatePanelScroll(io.cursors.get(0)); //PC only, records all updates in the mouseWheel and updates accordingly
  io.updatePanelDrag();       //update the act of cursor(s) dragging panel(s)
  io.updateCaretsRecursive(); //update the caret positions (if we're dragging them)
  io.updatePhysicsRecursive(0.001f*(time - timePrev));
  
  if(io.typer!=null && io.typer.correctHandlesLater) { //shhhhh, I'll put this somewhere better, later
    io.typer.buddy.correctHandles();
    //here's where we'd have to say to remove handles IF the handles should be removed
    io.typer.correctHandlesLater = false;
  }
  
  io.removeHandles(); //remove all handles scheduled to be removed
  
  grapher2D.updateFromTouches(io,0,0.055555556f*height); //update both graphs based on our interactions with the screen
  grapher3D.updateFromTouches(io,0,0.055555556f*height);
  
  updateParCount();             //update the display field for the number of parentheses
  equatList.updateCheckmarks(); //update the checkmarks for each equation
  
  defDrawer.beginDraw(); //begin drawing
  defDrawer.background(0); //set background to 0
  
  grapher2D.display(defDrawer,0,0.055555556f*height,width,0.9f*height,equatList.plots2D()); //display 2d graph
  
  io.display(defDrawer,0,0); //display user interface
  
  defDrawer.endDraw();   //finish drawing
  background(defDrawer); //display results
  
  grapher3D.display(g,0,0.055555556f*height,width,0.9f*height,equatList.plots3D()); //display 3d graph
  
  io.wheelEventX = io.wheelEventY = 0;
  io.bufferGarbageCollect(); //garbage collect unused buffers
  timePrev = time;           //update time
  io.updateCursorDPos();     //update previous draw positions (ALWAYS DO THIS AT THE END)
  
  if(showPerformance && frameCount%30 == 1) { //DEBUG
    float rate = 30000f/(System.currentTimeMillis()-timeLastFrame);
    println("\nFramerate: "+rate+", frame count: "+frameCount);
    println("Time Record: ");
    long total=0; for(long n:timeRec) { total+=n; }
    float mean = (float)total/numTimesRec; float vari = (float)sumTimeSq/numTimesRec - mean*mean;
    String rec="Total time (ms): "+mean+" (+-"+sqrt(vari/numTimesRec)+")"; println(rec);
    rec="Times (ms): "; for(long n:timeRec) { rec+=(float)n/numTimesRec+"\t"; } println(rec);
    rec="Percentages: "; for(long n:timeRec) { rec+=n*100f/total+"\t"; } println(rec);
    rec="Dev of Percent: "; for(int n=0;n<timeRec.length;n++) { rec+=100f*sqrt(timeRecSq[n]-(float)(timeRec[n]*timeRec[n])/total)/total+"\t"; } println(rec);
    timeLastFrame = System.currentTimeMillis();
  }
  
  //if(frameCount%30 == 1) { println(frameRate); } //DEBUG
}

public static String getUsefulInfo(Exception ex) { //obtain useful information about an exception when it is thrown
  String info = ex.getClass().getSimpleName()+": "+ex.getMessage(); //initialize the message with the exception type and the message
  StackTraceElement[] stack = ex.getStackTrace(); //obtain the stack trace
  for(StackTraceElement e : stack) { //loop through all elements
    info += "\t"+e;                  //append each stack trace element, indented and separated by endlines
  }
  return info; //return result
}


public void mouseWheel(MouseEvent event) {
  if(io.shiftHeld) { io.wheelEventX = event.getCount(); }
  else             { io.wheelEventY = event.getCount(); }
}

public void mousePressed() {
  Cursor curs = io.cursors.get(0); //PC: there's only one cursor
  
  if(curs.press==0) { //if the cursor was previously not pressed
    io.setCursorSelect(curs); //set the cursor select to whatever it's selecting
  }
  
  curs.press(mouseButton); //press the correct button
  
  io.updateButtons(curs, (byte)1, false); //update the buttons, with code 1 for pressing
  
  if(io.typer!=null && io.typer.selectMenu!=null && curs.select!=io.typer.selectMenu && (curs.select==null || curs.select.parent!=io.typer.selectMenu)) {
    io.typer.removeSelectMenu(); //if there's a typer with a select menu, the cursor isn't selecting it, and the cursor isn't selecting a button on it, remove the select menu
  }
}

public void mouseReleased() {
  Cursor curs = io.cursors.get(0); //PC: there's only one cursor
  curs.release(mouseButton); //release the correct button
  
  io.updateButtons(curs, (byte)0, false); //update the buttons, with code 0 for releasing
  //TODO make this compatible with multiple mouse buttons being pressed & released
  
  if(curs.press==0) {     //if cursor isn't pressing anymore
    curs.setSelect(null); //set select for the just-released cursor to null
  }
  
  if(io.typer!=null && io.typer.hMode==Textbox.HighlightMode.MOBILE && io.typer.selectMenu==null && io.typer.highlighting) {
    io.typer.addSelectMenu();
  }
}

public void mouseMoved() {
  Cursor curs = io.cursors.get(0); //PC: there's only one cursor
  curs.updatePos(mouseX,mouseY);   //change the cursor position
  
  io.updateButtons(curs, (byte)2, false); //update the buttons, with code 2 for moving
}

public void mouseDragged() {
  Cursor curs = io.cursors.get(0); //PC: there's only one cursor
  curs.updatePos(mouseX,mouseY);   //change the cursor position
  
  Mmio.attemptSelectPromotion(curs); //attempt select promotion
  io.updateButtons(curs, (byte)3, false); //update the buttons, with code 3 for dragging
}

public void keyPressed() {
  if(io.keyLast==null || io.keyLast!=key || io.keyCodeLast!=keyCode) {
    io.keyLast=key; io.keyCodeLast=keyCode; io.keyTime=System.currentTimeMillis();
    if(key==ENTER || key==RETURN) { hitEnter(); io.updatePressCount(); } //if we hit enter/return: perform the hit enter functionality, then reset all the press counts
    else { io.keyPresser(key, keyCode, false); } //otherwise, use the built-in key presser
  }
  
  if(key==CODED && keyCode==  SHIFT) { io.shiftHeld = true; } //if the shift key is held down, shiftHeld becomes true
  if(key==CODED && keyCode==CONTROL) { io.ctrlHeld  = true; } //if the ctrl key is held down, ctrlHeld becomes true
  
  //println("Key event:", key, int(key), keyCode);
}

public void keyReleased() {
  io.keyReleaser(key, keyCode);
  
  //println("Key event:", key, int(key), keyCode);
}

public static boolean match(char a, char b) { //returns true if they're the same key, just with/without shift/ctrl held down
  if(a==b) { return true; } //if they're the same, return true
  
  if(a>='a'-96 && a<='z'-96) { int diff=b-a; return diff==96 || diff==64; } //if a is CTRL-ed: return true if b is capital or lowercase a w/out the CTRL
  if(b>='a'-96 && b<='z'-96) { int diff=a-b; return diff==96 || diff==64; } //if b is CTRL-ed: return true if a is capital or lowercase b w/out the CTRL
  if(a>='A' && a<='Z') { return b-a == 32; } //if a is a capital letter: return true if b is lowercase a
  if(b>='A' && b<='Z') { return a-b == 32; } //if b is a capital letter: return true if a is lowercase b
  
  //now, we have to check symbols
  String part1 = "`1234567890-=[]\\;',./", part2 = "~!@#$%^&*()_+{}|:\"<>?"; //make a string of lowercase symbols and one of uppercase symbols
  int indA = (part1+part2).indexOf(a), indB = (part2+part1).indexOf(b);      //find where each char is in part1+part2 and part2+part1
  return indA==indB && indA!=-1; //return true iff they are shift complements of each other
}





/*Action typeAnsPrefix(final char inp) { return new Action() { public void act() { if(io.typer!=null) {
  if(io.typer==query && io.typer.size()==0) { io.typer.insert("Ans"+inp); }
  else { io.typer.type(inp); }
} } }; }*/
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
  float strokeWeight=1;           //stroke weight
  int fillColor, strokeColor;   //fill & stroke color
  
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
  
  public float getX() { return !mobile || parent==null ? x : x+parent.getSurfaceX(); } //get x position WRT parent
  public float getY() { return !mobile || parent==null ? y : y+parent.getSurfaceY(); } //get y position WRT parent
  
  public float getObjX() { return parent==null ? x : x+(mobile ? parent.getObjSurfaceX() : parent.getObjX()); } //get x position on screen (obj=objective)
  public float getObjY() { return parent==null ? y : y+(mobile ? parent.getObjSurfaceY() : parent.getObjY()); } //get y position on screen
  
  //these are for obtaining the position relative to some ancestor object
  public float getXRelTo(Panel p) {
    if(p==this) { return 0; } //relative to ourself, we are at position 0
    if(parent==null) { throw new RuntimeException("Cannot obtain x position of "+getClass().getSimpleName()+" relative to cousin "+p.getClass().getSimpleName()); } //if we hit a dead end, throw an exception
    return x+(mobile ? parent.getSurfaceXRelTo(p) : parent.getXRelTo(p)); //otherwise, add x to either the parent's relative position or relative surface position to p
  }
  public float getYRelTo(Panel p) {
    if(p==this) { return 0; } //relative to ourself, we are at position 0
    if(parent==null) { throw new RuntimeException("Cannot obtain y position of "+getClass().getSimpleName()+" relative to cousin "+p.getClass().getSimpleName()); } //if we hit a dead end, throw an exception
    return y+(mobile ? parent.getSurfaceYRelTo(p) : parent.getYRelTo(p)); //otherwise, add y to either the parent's relative position or relative surface position to p
  }
  
  public float getWidth () { return w; } //get width
  public float getHeight() { return h; } //get height
  public float getRadius() { return r; } //get radius
  
  public float[] getDisp() { return new float[] {dx1,dx2,dy1,dy2}; }
  
  public Panel getParent() { return parent; } //get parent
  
  public boolean   fills() { return   fill; } //get whether it fills
  public boolean strokes() { return stroke; } //get whether it strokes
  public float getStrokeWeight() { return strokeWeight; } //get strokeWeight
  public int getFillColor   () { return    fillColor; } //get fill color
  public int getStrokeColor () { return  strokeColor; } //get stroke color
  
  //////////////// SETTERS ////////////////
  
  public Box setX(final float x2) { x=x2; return this; } //set x
  public Box setY(final float y2) { y=y2; return this; } //set y
  public Box setW(final float w2) { w=w2; return this; } //set width
  public Box setH(final float h2) { h=h2; return this; } //set height
  public Box setR(final float r2) { r=r2; return this; } //set radius
  public Box setPos(final float x2, final float y2) { x=x2; y=y2; return this; }
  public Box setDims(final float w2, final float h2) { w=w2; h=h2; return this; }
  
  public Box setDisp(final float x1, final float x2, final float y1, final float y2) { dx1=x1; dx2=x2; dy1=y1; dy2=y2; return this; }
  
  public Box setParent(final Panel p) { //set parent
    if(parent==p) { return this; } //if same parent, do nothing
    
    if(parent!=null) { parent.children.remove(this); } //if currently has a parent, estrange
    if(p!=null) { p.children.add(this); mmio=p.mmio; } //if will have parent, join family
    parent=p;                                          //set parent
    
    return this; //return result
  }
  
  public Box setFill        (final boolean f) {         fill=f; return this; }
  public Box setStroke      (final boolean s) {       stroke=s; return this; }
  public Box setStrokeWeight(final   float s) { strokeWeight=s; return this; }
  
  public Box setFill  (final int f) { fillColor  =f; return this; } //set fill color
  public Box setStroke(final int s) { strokeColor=s; return this; } //set stroke color
  
  public Box setPalette(final Box b) { //copies over all of its color & draw attributes
    fill = b.fill; stroke = b.stroke; //copy whether it has fill/stroke
    strokeWeight = b.strokeWeight;    //copy its stroke weight
    fillColor = b.fillColor; strokeColor = b.strokeColor; //copy its fill & stroke color
    return this; //return result
  }
  
  public Box setShape(final Box b) { //copies over the exact shape
    w = b.w; h = b.h; r = b.r; //set the width, height, & radius
    return this;               //return result
  }
  
  public Box setText(Text... texts) { //sets the texts
    text = new Text[texts.length]; //initialize array
    for(int n=0;n<texts.length;n++) { text[n] = texts[n]; } //set each element
    return this; //return result
  }
  
  public Box setText(String txt, float siz, int col) {
    this.setText(new Text(txt,0.5f*w,0.5f*h,siz,col,CENTER,CENTER));
    return this;
  }
  
  public Box setText(String txt, int col) {
    float wid = mmio.getTextWidth(txt,32); int lines = Mmio.getLines(txt);
    float siz = min(32*(w-2*Mmio.xBuff)/wid, ((h-2*Mmio.yBuff)/lines-0.902f)/1.164f);
    this.setText(txt,siz,col);
    return this;
  }
  
  public Box setText(String txt, int col, float buffX, float buffY) {
    float wid = mmio.getTextWidth(txt,32); int lines = Mmio.getLines(txt);
    float siz = min(32*(w-2*buffX)/wid, ((h-2*buffY)/lines-0.902f)/1.164f);
    this.setText(txt,siz,col);
    return this;
  }
  
  public Box setMobile(final boolean m) { mobile=m; return this; }
  
  public Box setActive(final boolean a) { active=a; return this; }
  
  ////////////////////////////// DRAWING/DISPLAY //////////////////////////////////
  
  public void display(final PGraphics graph, float buffX, float buffY) { //displays on a particular PGraphics (whose top left corner is at buffX, buffY on the parent)
    //float x3 = getObjX()-x2, y3 = getObjY()-y2; //get location where you should actually draw
    float x3 = getX()-buffX, y3 = getY()-buffY; //get location where you should actually draw
    setDrawingParams(graph);                    //set drawing parameters
    graph.rect(x3,y3,w,h,r);                    //draw rectangle
    
    for(Text t : text) { //loop through all the texts
      t.display(graph,-x3,-y3); //draw them all
    }
  }
  
  public void setDrawingParams(final PGraphics graph) {
    if(fill) { graph.fill(fillColor); } else { graph.noFill(); }
    if(stroke) { graph.stroke(strokeColor); graph.strokeWeight(strokeWeight); } else { graph.noStroke(); }
  }
  
  
  ////////////////////////// HITBOX ///////////////////////////////////
  
  protected boolean hitboxNoCheck(final float x2, final float y2) {
    final float x3=x2-getObjX(), y3=y2-getObjY();                    //get position relative to top left corner
    return active && x3>=-dx1 && y3>=-dy1 && x3<=w+dx2 && y3<=h+dy2; //determine if it's within the bounding box (account for displacement)
  }
  
  protected boolean hitboxNoCheck(final Cursor curs) { return hitboxNoCheck(curs.x,curs.y); }
  
  public boolean hitbox(final float x2, final float y2) {
    return (parent==null || parent.hitbox(x2,y2)) && hitboxNoCheck(x2,y2);
  } //if not in parent's hitbox, automatic false. Otherwise, check hitbox
  
  public boolean hitbox(final Cursor curs) { return hitbox(curs.x,curs.y); }
}

static class Text {
  String text; //text
  float x, y;  //text position
  float size;  //text size
  int fill;  //text color
  int alignX, alignY; //text alignment
  
  Text(String txt, float x2, float y2, float siz, int col, int alx, int aly) { //constructor w/ attributes
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
static class Buffer {
  
  ////////////// ATTRIBUTES /////////////////////////
  
  PGraphics graph;        //PGraphics object to load pixels onto
  boolean inUse   =false; //whether it's currently in use
  boolean canWrite=false; //whether the PGraphics is writeable
  byte usage=0;           //a record of whether is was used in the last 8 garbage collection cycles
  
  byte shouldStamp=1;     //time dependent attribute, used to label the buffer while being used to determine if it should be stamped. 1=yes, 0=no
  //when being used to display something that literally could not use a smaller buffer, we stamp it. Otherwise, we don't stamp it, since we'd be better off using a smaller buffer
  
  //////////////// CONSTRUCTORS //////////////////////
  
  Buffer(PApplet app, int w, int h) {
    graph = app.createGraphics(w,h); //load graphics buffer
  }
  
  ///////////////// GETTERS ////////////////////////
  
  public PGraphics getGraphics() { return graph; }
  public boolean isInUse() { return inUse; }
  public byte getUsage() { return usage; }
  public int width() { return graph.width; }
  public int height() { return graph.height; }
  
  public boolean wasUsed() { return usage!=0; } //returns whether it was used in the past 8 seconds
  
  /////////////// SETTERS ///////////////////////////
  
  public void stamp() { usage|=1; } //stamps to show it's been used
  public void step() { usage<<=1; } //takes 1 step: shift bits of usage recorder
  
  public Buffer setShouldStamp(boolean b) { shouldStamp = b?(byte)1:0; return this; } //sets whether it should be stamped, returns self
  
  public void use() { inUse=true; usage|=shouldStamp; } //sets that it's in use
  public void beginDraw() { inUse=canWrite=true; usage|=shouldStamp; graph.beginDraw(); graph.clear();
    //graph.loadPixels(); java.util.Arrays.fill(graph.pixels, 0x00FFFFFF); graph.updatePixels(); //for Android and Processing 2.0, since the clear function doesn't quite work
  } //sets that it's in use AND starts editing PGraphics object (starting with clearing the background completely)
  public void endDraw()   { canWrite=false; graph.endDraw();  } //stops editing PGraphics object
  public void useNt() { inUse=false; } //sets that it's no longer in use (usen't)
  
  
  ////////////////// TESTING ///////////////////////////
  
  public void selfTest() { graph.noFill(); graph.strokeWeight(3); graph.stroke(0xffFF00FF); graph.rect(0,0,graph.width,graph.height); } //test to make sure the buffer's actually there
}
static enum State { DISABLED, DEAD, HOVER, PRESS }; //the 4 states a button can be in
//(disabled = greyed out, dead = not selected, hover = hovered over, press = being pressed

public static class Button extends Box {
  
  ///////////////////////// ATTRIBUTES /////////////////////////
  
  int pressCount = 0; //how many times it's been pressed in a row (resets when you press something else)
  
  Action onPress   = emptyAction; //the functionality when pressed
  Action onRelease = emptyAction; //the functionality when released
  Action onHeld    = emptyAction; //the functionality when held down for a certain amount of time
  int holdTimer = 500;  //how long you have to hold down in milliseconds (0.5 s by default)
  int holdFreq  = 30;   //how frequently the hold functionality is repeatedly applied (technically, inverse frequency, 0.03s by default)
  long firstActivated;  //when it was first activated since being held down (in ms after 1970)
  
  ClickProgressor progress = new ClickProgressor(); //tracks how the user interacts with it
  
  boolean selectOnPress  =false , //if true, button only registers press if it was selected when you first clicked (if false, moving your mouse into the hitbox will always select it, so long as it's pressed and in button mode)
          selectOnRelease=true ;  //if true, button only registers release if it was selected when you released it (if false, moving your mouse out of the hitbox won't deselect it)
  
  //example of button where select on press is false: most smartphone touch screen buttons, where you can press something, then move your cursor away as you realized you pressed the wrong button, then move your cursor back to the right button & press it
  //example of button where select on release is false: up and down arrows on a scroll bar. If you press those, then move your cursor, they stay pressed
  
  HashMap<Cursor, Boolean> cursors = new HashMap<Cursor, Boolean>(); //list of cursors that are pressing this button, as well as 1 boolean to represent if the button is being held down by this cursor
  
  
  
  //the 1s bit indicates it's hovered, 2s bit indicates it's pressed, and 4s bit indicates it's being held. 1 and 2 are mutually exclusive, while 4s bit implies 2s bit
  //the button is actually pressed if at least one entry is pressed. otherwise, it's hovered if at least one is hovered. otherwise, it's either disabled or dead
  //no entries will be dead because dead entries get removed
  
  ///////////////////////// CONSTRUCTORS /////////////////////////
  
  Button() { } //default constructor
  
  Button(final float x2, final float y2, final float w2, final float h2) { //constructor with parameters
    super(x2,y2,w2,h2); setTimings(Mmio.timing1,Mmio.timing2,Mmio.timing3);
  }
  
  Button(final float x2, final float y2, final float w2, final float h2, final float r2) { //constructor with parameters (and radius)
    super(x2,y2,w2,h2,r2); setTimings(Mmio.timing1,Mmio.timing2,Mmio.timing3);
  }
  
  ///////////////////////// GETTERS /////////////////////////
  
  
  
  ///////////////////////// SETTTERS /////////////////////////
  
  public Button setFills  (final int a, final int b, final int c) { progress.  fill.put(State.DEAD,a); progress.  fill.put(State.HOVER,b); progress.  fill.put(State.PRESS,c); return this; }
  public Button setStrokes(final int a, final int b, final int c) { progress.stroke.put(State.DEAD,a); progress.stroke.put(State.HOVER,b); progress.stroke.put(State.PRESS,c); return this; }
  public Button setTimings(final float a, final float b, final float c) { progress.duration.put(State.DEAD,round(1000*a)); progress.duration.put(State.HOVER,round(1000*b)); progress.duration.put(State.PRESS,round(1000*c)); return this; }
  
  public Button setFills  (final int a, final int c) { progress.  fill.put(State.DEAD,a); progress.  fill.put(State.HOVER,lerpColor(a,c,0.5f,RGB)); progress.  fill.put(State.PRESS,c); return this; }
  public Button setStrokes(final int a, final int c) { progress.stroke.put(State.DEAD,a); progress.stroke.put(State.HOVER,lerpColor(a,c,0.5f,RGB)); progress.stroke.put(State.PRESS,c); return this; }
  
  public Button setFills  (final int a) { progress.  fill.put(State.DEAD,a); progress.  fill.put(State.HOVER,a); progress.  fill.put(State.PRESS,a); return this; }
  public Button setStrokes(final int a) { progress.stroke.put(State.DEAD,a); progress.stroke.put(State.HOVER,a); progress.stroke.put(State.PRESS,a); return this; }
  
  public Button setStroke(final boolean s) { super.setStroke(s); if(!stroke) { setStrokes(0,0,0); } return this; }
  
  public Button setOnClick(final Action act) { onPress=act; return this; } //sets the behavior when clicked
  public Button setOnRelease(final Action act) { onRelease=act; return this; } //sets the behavior when released
  public Button setOnHeld(final Action act, final float... hold) { //sets the behavior when held down for a certain amount of time
    onHeld=act; //set hold down behavior
    if(hold.length>0) { holdTimer=round(1000*hold[0]); } //if specified, set how long it has to be held down
    return this; //return result
  }
  
  public Button setPalette(final Button b) { //sets the color palette to be a perfect match of the inputted button
    progress.fill   = (HashMap<State,Integer>)b.progress.  fill.clone(); //clone the fill values
    progress.stroke = (HashMap<State,Integer>)b.progress.stroke.clone(); //clone the stroke values
    stroke = b.stroke;             //set whether it even has a stroke
    strokeWeight = b.strokeWeight; //set its stroke weight
    return this;                   //return result
  }
  
  public Button setOnClickListener(final Action act) { return setOnClick(act); } //does the same thing as setOnClick, but given a different name for ease of use for those comfortable with android studio
  
  public Button disable() { progress.curr = State.DISABLED; return this; }
  public Button  enable() { progress.curr = State.DEAD;     return this; }
  
  ///////////////////////// DRAWING/DISPLAY /////////////////////////
  
  public void setDrawingParams(final PGraphics graph) {
    graph.fill(progress.getFill());
    if(stroke) { graph.strokeWeight(strokeWeight); graph.stroke(progress.getStroke()); } else { graph.noStroke(); }
  }
  
  
  //////////////////////// REACTORS ////////////////////////////////
  
  //returns whether the cursor is in its hitbox
  public boolean respondToChange(final Cursor curs, final byte code, boolean selected) { //responds to change in the cursor (code tells us what kind of change. 0=release, 1=press, 2=move, 3=drag) (select tells us if the cursor is already touching something)
    if(progress.curr==State.DISABLED) { return false; } //if disabled, do nothing
    
    boolean hitbox = hitbox(curs); //record whether the cursor is in this button
    
    if(cursors.get(curs) == null) { //if this cursor ISN'T pressing the button:
      if(hitbox && !selected) { //first, make sure the cursor is in the hitbox AND hasn't already selected something else
        if(code==1) {              //if the cursor just pressed:
          cursors.put(curs, true); //push this cursor to the list, with hold being true
          onPress.act();           //perform the onPress event
          if(onPress != emptyAction) {   //if an action was performed:
            mmio.updatePressCount(this); //update the press counters for each button
          }
          if(cursors.size()==1) { firstActivated = System.currentTimeMillis(); } //set the exact time when this button was pressed (unless another cursor already beat us to it)
        }
        else if(curs.press!=0 && !selectOnPress && curs.select instanceof Button) { //otherwise, if the cursor is already pressed and in button-select mode, and we're allowed to do it this way:
          cursors.put(curs, false); //push this cursor to the list, with hold being false. Don't activate press functionality, it doesn't apply for this case
        }
      }
    }
    
    else { //if this cursor IS pressing the button:
      if(code==0) { //if the cursor is just released:
        onRelease.act();             //perform the onRelease event
        ++pressCount;                //increment press counter
        mmio.updatePressCount(this); //update the press counters for each button
        
        cursors.remove(curs); //remove this cursor from the list
      }
      else if((code&2)==2 && selectOnRelease && !hitbox) { //otherwise, if the cursor just left the hitbox, and leaving makes it deactivate
        cursors.remove(curs); //remove this cursor from the list
      }
      //TODO see if we should even bother checking the code&2, since it just tells us if the mouse moved. Which, I'm pretty sure was just a shortcut to see if we had to check the hitbox, which has already been calculated
    }
    
    //finally, use the updated information to update the click progressor:
    updateProgressor();
    
    //TODO make it so different mouse buttons can do different things
    return hitbox;
  }
  //potential brainbending glitch: what happens if you do something with a button, then it disappears? Like, you scroll away and can no longer see it?
  
  
  public void updateProgressor() { //updates the click progressor
    if(cursors.size()==0) { //if no cursors are pressing this button
      State swap = State.DEAD;       //the state we will swap to
      for(Cursor c : mmio.cursors) { //loop through all cursors
        if(hitbox(c)) { swap = State.HOVER; break; } //if at least one cursor is in the hitbox, swap to hover
      }
      progress.update(swap); //swap to that state
    }
    else { progress.update(State.PRESS); } //if at least one cursor is pressing this button, swap to the pressed state
  }
}

interface Action { public void act(); }

static Action emptyAction = new Action() { public void act() { } }; //empty action

//Action typeAction(final InputCode inp) { return new Action() { public void act() { if(io.typer!=null) { io.typer.readInput(inp); } } }; }



static class ClickProgressor { //a class specifically dedicated to measuring and tracking the progress of the color change in a button
  
  /////////////////// ATTRIBUTES //////////////////////////
  
  State curr=State.DEAD; //current state
  long lastEvent;   //time of last event in milliseconds
  int lastFill;   //the color it was at the start of this
  int lastStroke; //same, but for stroke
  
  HashMap<State,Integer>     fill = new HashMap<State,Integer>(4); //the fill colors when not pressed, hovered over, and pressed
  HashMap<State,Integer>   stroke = new HashMap<State,Integer>(4); //the stroke colors when not pressed, hovered over, and pressed
  HashMap<State,Integer> duration = new HashMap<State,Integer>(4); //the time it takes to fully switch to a particular state
  
  //////////////////// CONSTRUCTORS //////////////////////
  
  ClickProgressor() {  }
  //TODO make this more privatized, if appropriate
  
  //////////////////// GETTERS ////////////////////////////
  
  private int getColor(int lastColor, HashMap<State, Integer> colorMap) {
    if(duration.get(curr)==0) { return colorMap.get(curr); } //if transition is instantaneous, return the current color
    
    long time = System.currentTimeMillis();                      //find the current time
    float progress = (time-lastEvent)/(float)duration.get(curr); //divide the time passed by the total time it takes
    progress = constrain(progress,0,1);                          //constrain to the range 0-1
    
    return lerpColor(lastColor,colorMap.get(curr),progress,RGB); //return the lerping between the two colors
  }
  
  public int getFill() { return getColor(lastFill, fill); } //gets current fill
  
  public int getStroke() { return getColor(lastStroke, stroke); } //gets current stroke
  
  //////////////////// PROGRESSION ///////////////////////
  
  public void update(final State state) { //initiates a new event & updates accordingly
    if(state==curr) { return; } //if this state is exactly the same as the old state, DO NOTHING
    
    lastFill = getFill(); lastStroke = getStroke(); //update the initial stroke and fill
    lastEvent = System.currentTimeMillis();         //set the time of the event
    curr = state;                                   //lastly, update the state
  }
}
public static class CMatrix { //Complex Matrix
  
  //////////////// ATTRIBUTES ///////////////////
  int h, w;             //the dimensions
  Complex[][] elements; //an array of all elements
  //NOTE: Dimensions are important. Especially w, as it allows us to know the width of the matrix, even if the height is 0
  
  /////////////// CONSTRUCTORS ////////////////////
  
  CMatrix() { h=w=0; elements = new Complex[0][0]; } //creates 0x0 matrix
  
  CMatrix(int h_, int w_, Complex... c) { //creates matrix given dimensions and complex elements
    if(h_<0||w_<0)      { throw new NegativeArraySizeException("Cannot instantiate "+h_+"x"+w_+" matrix");                  } //negative size: throw exception
    if(c.length!=h_*w_) { throw new RuntimeException("Cannot instantiate "+h_+"x"+w_+" matrix with "+c.length+" elements"); } //wrong number of elements: throw exception
    h=h_; w=w_; elements = new Complex[h][w];   //set dimensions & initialize element array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      if(c[i*w+j]==null) { throw new NullPointerException("Matrix cannot have null elements"); } //if any elements are null, throw exception
      elements[i][j] = c[i*w+j]; //set each element
    }
  }
  
  CMatrix(int h_, int w_, double... d) { //creates matrix given dimensions and real elements
    if(h_<0||w_<0)      { throw new NegativeArraySizeException("Cannot instantiate "+h_+"x"+w_+" matrix");                  } //negative size: throw exception
    if(d.length!=h_*w_) { throw new RuntimeException("Cannot instantiate "+h_+"x"+w_+" matrix with "+d.length+" elements"); } //wrong number of elements: throw exception
    h=h_; w=w_; elements = new Complex[h][w];   //set dimensions & initialize element array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j] = new Complex(d[i*w+j]);   //set each element
    }
  }
  
  CMatrix(int h_, int w_) { //creates hxw zero matrix
    h=h_; w=w_; elements = new Complex[h][w]; //set dimensions & init element array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { elements[i][j] = Cpx.zero(); } //set each element to 0
  }
  
  CMatrix(CVector... v) { //loads matrix from array of rows
    if(v.length==0) { throw new MatrixSizeException("Ambiguous Dimensions: Cannot determine width of 0x??? matrix"); }
    h=v.length; w=v[0].size();    //set dimensions
    elements = new Complex[h][w]; //load array
    for(int i=0;i<h;i++) { //loop through all rows
      if(v[i]==null)     { throw new NullPointerException("Matrix cannot have null rows"); }
      if(v[i].size()!=w) { throw new MatrixSizeException("Cannot create jagged matrix"); }
      for(int j=0;j<w;j++) {                 //loop through all columns
        elements[i][j] = v[i].get(j).copy(); //set each element (deep copying)
      }
    }
  }
  
  private CMatrix(int h_, int w_, Complex[][] c) {
    h=h_; w=w_; elements = c; //set dimensions and elements
  }
  
  //////////////// INHERITED METHODS ///////////////////////
  
  @Override
  public boolean equals(final Object obj) {
    if(!(obj instanceof CMatrix)) { return false; } //only matrices can equal
    CMatrix comp = (CMatrix)obj;                    //cast to CMatrix
    if(comp.h!=h || comp.w!=w) { return false; }    //if dimensions don't match, they're not equal
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {     //loop through all elements
      if(!elements[i][j].equals(comp.elements[i][j])) { return false; } //if any don't equal, return false
    }
    return true; //if all conditions have been met, both matrices are equal
  }
  
  @Override
  public int hashCode() { //an equals method demands a consistent hashcode method
    int hash = w^h; //init to width XOR height
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {
      hash = 31*hash+elements[i][j].hashCode(); //repeatedly mult by 31 & add each element's hashcode
    }
    return hash; //return result
  }
  
  @Override
  public CMatrix clone() { //form deep copy of matrix
    Complex[][] inst = new Complex[h][w];       //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].clone();      //clone each element
    }
    return new CMatrix(h, w, inst); //create and return new cloned matrix
  }
  
  public String toString(int dig) { //cast to a string given a specified number of digits of precision
    double threshold = 0; //how small something has to be to be rounded down to 0
    if(Complex.omit_Option) { //if we omit small parts, the threshold is non-zero
      double biggest = biggest(); //find the biggest element
      threshold = Math.min(1e-11d*biggest, 1e-12d); //set our threshold to either 10^-12, or 10^-11*biggest element
    }
    
    StringBuilder res = new StringBuilder("["); //initialize to opening left bracket
    for(int i=0;i<h;i++) {   //loop through all rows
      res.append("[");       //start each row with left bracket
      for(int j=0;j<w;j++) { //loop through all columns
        if(elements[i][j].lazyabs()<threshold) { res.append("0"); } //if this element is below our threshold, round down to 0
        else { res.append(elements[i][j].toString(dig)); } //concatenate each individual element, outputted to the given amount of precision
        if(j!=w-1) { res.append(","); }                    //put a comma after all entries but the last
      }
      res.append("]");                //end each row with a right bracket
      if(i!=h-1) { res.append(","); } //put a comma after all rows but the last
    }
    return res.append("]").toString(); //close with right bracket, return result
  }
  
  @Override
  public String toString() { return toString(-1); } //default toString: output result to maximum precision
  
  ////////////////// GETTERS/SETTERS /////////////////////////
  
  public Complex get(int i, int j) { return elements[i-1][j-1]; }
  public int width () { return w; }
  public int height() { return h; }
  public String getDimensions() { return h+"x"+w; }
  
  public CVector getRow(int i) {
    Complex[] c = new Complex[w]; //load array
    for(int j=0;j<w;j++) { c[j] = elements[i][j]; } //set each element
    return new CVector(c); //return result
  }
  
  public void set(int i, int j, Complex c) {
    if(c==null) { throw new RuntimeException("Cannot give matrix null elements"); }
    elements[i-1][j-1] = c;
  }
  
  ///////////////// OBSCURE YET REALLY USEFUL FUNCTIONS ////////////////////
  
  public double biggest() { //largest lazy absolute value of all elements
    double max = 0; //init to 0
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      max = Math.max(max, b.lazyabs());              //find the maximum lazy abs
    }
    return max; //return result
  }
  
  ///////////////// REALLY BASIC FUNCTIONS ////////////////////
  
  public boolean isSquare() { return w==h; }
  public boolean isColumn() { return w==1; }
  public boolean isRow   () { return h==1; }
  public boolean sameDims(CMatrix m) { return w==m.w && h==m.h; }
  
  public boolean isReal() {
    for(Complex[] a : elements) for(Complex b : a) { if(b.im!=0) { return false; } } //if even one element isn't real, return false
    return true; //otherwise, return true
  }
  public boolean isInf() {
    for(Complex[] a : elements) for(Complex b : a) { if(b.isInf()) { return true; } } //if even one element is infinite, return true
    return false; //otherwise, return false
  }
  public boolean isNaN() {
    for(Complex[] a : elements) for(Complex b : a) { if(b.isNaN()) { return true; } } //if even one element is NaN, return true
    return false; //otherwise, return false
  }
  
  public static CMatrix zero(int h_, int w_) { return new CMatrix(h_, w_); }
  public static CMatrix identity(int dim) {
    Complex[][] inst = new Complex[dim][dim]; //instantiate square matrix
    for(int i=0;i<dim;i++) for(int j=0;j<dim;j++) { //loop through all elements
      inst[i][j] = i==j ? Cpx.one() : Cpx.zero();   //set them to 1 if diagonal, 0 otherwise
    }
    return new CMatrix(dim,dim,inst); //create identity matrix & return result
  }
  
  ///////////////// BASIC FUNCTIONS ///////////////////////
  
  public CMatrix transpose() { //returns the transpose
    Complex[][] inst = new Complex[w][h]; //load transpose array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[j][i] = elements[i][j].copy();       //set each element (while swapping indices)
    }
    return new CMatrix(w,h,inst); //create and return new transposed matrix
  }
  
  public CMatrix negeq() { //negate-equals
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.negeq(); //negate each element
    }
    return this; //return result
  }
  public CMatrix neg() { //returns the matrix negated
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].neg();        //negate each element
    }
    return new CMatrix(h,w,inst); //create and return new negated matrix
  }
  
  public CMatrix muleqI() { //multiply-equals by i
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.muleqI(); //multiply each element by i
    }
    return this; //return result
  }
  public CMatrix mulI() { //returns the matrix multiplied by i
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mulI();       //multiply each element by i
    }
    return new CMatrix(h,w,inst); //create and return matrix multiplied by i
  }
  
  public CMatrix diveqI() { //divide-equals by i
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.diveqI(); //divide each element by i
    }
    return this; //return result
  }
  public CMatrix divI() { //returns the matrix divided by i
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].divI();       //divide each element by i
    }
    return new CMatrix(h,w,inst); //create and return matrix divided by i
  }
  
  public CMatrix conjeq() { //complex-conjugate-equals
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.conjeq(); //conjugate each element
    }
    return this; //return result
  }
  public CMatrix conj() { //returns the complex conjugate
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].conj(); //conjugate each element
    }
    return new CMatrix(h, w, inst); //create and return new conjugated matrix
  }
  
  public CMatrix re() { //returns the real part of the matrix
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = new Complex(elements[i][j].re); //take the real part of each element
    }
    return new CMatrix(h, w, inst); //create and return new real-ed matrix
  }
  
  public CMatrix im() { //returns the imaginary part of the matrix
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = new Complex(elements[i][j].im); //take the imaginary part of each element
    }
    return new CMatrix(h, w, inst); //create and return new imaginari-ed matrix
  }
  
  public CMatrix herm() { //returns the hermitian (conjugate transpose)
    Complex[][] inst = new Complex[w][h]; //load transpose array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[j][i] = elements[i][j].conj(); //conjugate each element (while swapping indices)
    }
    return new CMatrix(w, h, inst); //create and return new conjugate-transposed matrix
  }
  
  ////////////////////// ARITHMETIC ////////////////////////
  
  public CMatrix addeq(final CMatrix m) { //add-equals two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot add "+getDimensions()+" + "+m.getDimensions()); } //if dimensions don't match, throw exception
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      elements[i][j].addeq(m.elements[i][j]); //add matching elements
    }
    return this; //return result
  }
  
  public CMatrix subeq(final CMatrix m) { //subtract-equals two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot subtract "+getDimensions()+" - "+m.getDimensions()); } //if dimensions don't match, throw exception
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      elements[i][j].subeq(m.elements[i][j]); //subtract matching elements
    }
    return this; //return result
  }
  
  public CMatrix muleq(final Complex c) { //multiply-equals matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot multiply matrix by null"); } //if null, throw exception
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j].muleq(c); //multiply each element by scalar
    }
    return this; //return result
  }
  public CMatrix muleq(final double d) { //multiply-equals by real scalar
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j].muleq(d); //multiply each element by scalar
    }
    return this; //return result
  }
  public CMatrix muleqI(final double d) { //multiply-equals by imaginary scalar
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j].muleqI(d); //multiply each element by scalar
    }
    return this; //return result
  }
  
  public CMatrix diveq(final Complex c) { //divide-equals matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot divide matrix by null"); } //if null, throw exception
    return muleq(c.inv()); //multiply-equals by the reciprocal of c
  }
  public CMatrix diveq(final double d) { //divide-equals matrix by real scalar
    return muleq(1d/d);           //multiply-equals by the reciprocal of d
  }
  public CMatrix diveqI(final double d) { //divide-equals matrix by imaginary scalar
    return muleqI(-1d/d);          //multiply-equals by the reciprical of di
  }
  
  
  
  public CMatrix add(final CMatrix m) { //add two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot add "+getDimensions()+" + "+m.getDimensions()); } //if dimensions don't match, throw exception
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = elements[i][j].add(m.elements[i][j]); //add matching elements
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  public CMatrix sub(final CMatrix m) { //subtract two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot subtract "+getDimensions()+" - "+m.getDimensions()); } //if dimensions don't match, throw exception
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = elements[i][j].sub(m.elements[i][j]); //subtract matching elements
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  public CMatrix mul(final Complex c) { //multiply matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot multiply matrix by null"); } //if null, throw exception
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mul(c); //multiply each element by scalar
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  public CMatrix mul(final double d) { //multiply matrix by real scalar
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mul(d); //multiply each element by scalar
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  public CMatrix mulI(final double d) { //multiply matrix by imaginary scalar
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mulI(d); //multiply each element by imaginary scalar
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  public CMatrix div(final Complex c) { //divide matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot divide matrix by null"); } //if null, throw exception
    return mul(c.inv()); //multiply by reciprocal of c
  }
  public CMatrix div(final double d) { //divide matrix by real scalar
    return mul(1d/d); //multiply by reciprocal of d
  }
  public CMatrix divI(final double d) { //divide matrix by imaginary scalar
    return mulI(-1d/d); //multiply by reciprocal of di
  }
  
  
  public CMatrix mul(final CMatrix m) { //returns the product of two matrices
    if(w!=m.h) { throw new MatrixSizeException("Cannot multiply "+getDimensions()+" by "+m.getDimensions()); } //if width of first doesn't match height of second, throw exception
    Complex[][] inst = new Complex[h][m.w]; //instantiate array (dimensions are height of first x width of second)
    for(int i=0;i<h;i++) for(int j=0;j<m.w;j++) { //loop through all elements
      inst[i][j] = new Complex(); //initialize each element to 0
      for(int k=0;k<w;k++) {      //compute each element via a dot product of the first matrix's row w/ the second matrix's column
        inst[i][j].addeq( elements[i][k].mul(m.elements[k][j]) ); //add each element-wise product
      }
    }
    return new CMatrix(h,m.w,inst); //return resulting matrix
  }
  
  public CVector mul(final CVector v) { //returns the matrix multiplied by a column vector
    if(w!=v.size()) { throw new MatrixSizeException("Cannot multiply "+getDimensions()+" matrix by vector of size "+v.size()); } //if the width doesn't match the dimension, throw exception
    Complex[] inst = new Complex[h]; //instantiate array (height = height)
    for(int i=0;i<h;i++) { //loop through all elements
      inst[i] = new Complex(); //initialize each element to 0
      for(int j=0;j<w;j++) {   //compute each element via a dot product of the matrix's row w/ this vector
        inst[i].addeq(elements[i][j].mul(v.elements[j])); //add each element-wise product
      }
    }
    return new CVector(inst); //create & return the resulting vector
  }
  
  public CVector mulLeft(final CVector v) { //returns a row vector multiplied by this matrix
    if(h!=v.size()) { throw new MatrixSizeException("Cannot multiply vector of size "+v.size()+" by "+getDimensions()+" matrix"); } //if the height doesn't match the dimensions, throw exception
    Complex[] inst = new Complex[w]; //instantiate array (width = width)
    for(int j=0;j<w;j++) { //loop through all elements
      inst[j] = new Complex(); //initialize each element to 0
      for(int i=0;i<h;i++) {   //compute each element via a dot product of the vector with the matrix's column
        inst[j].addeq(elements[i][j].mul(v.elements[i])); //add each element-wise product
      }
    }
    return new CVector(inst); //create & return the resulting vector
  }
  
  public CMatrix addeq(final Complex s) { //add-equals a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    for(int n=0;n<h;n++) { elements[n][n].addeq(s); } //add our scalar to each diagonal entry
    return this; //return result
  }
  
  public CMatrix subeq(final Complex s) { //subtract-equals a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    for(int n=0;n<h;n++) { elements[n][n].subeq(s); } //subtract our scalar from each diagonal entry
    return this; //return result
  }
  
  public CMatrix add(final Complex s) { //add a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    Complex[][] inst = new Complex[h][w];       //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = i==j ? elements[i][j].add(s) : elements[i][j].clone(); //set each element, being sure to add the scalar to diagonal entries
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  public CMatrix sub(final Complex s) { //subtract a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    Complex[][] inst = new Complex[h][w];       //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = i==j ? elements[i][j].sub(s) : elements[i][j].clone(); //set each element, being sure to subtract the scalar from diagonal entries
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  public CMatrix addeq(final double s) { return addeq(new Complex(s)); }
  public CMatrix subeq(final double s) { return subeq(new Complex(s)); }
  public CMatrix add(final double s) { return add(new Complex(s)); }
  public CMatrix sub(final double s) { return sub(new Complex(s)); }
  
  //////////////////// MATRIX FUNCTIONS /////////////////////////////////
  
  public Complex trace() { //returns the trace
    if(h!=w) { throw new IllegalArgumentException("Cannot take trace of "+getDimensions()+" (must be square)"); } //if not square, throw exception
    Complex trace = new Complex();                        //initialize trace to 0
    for(int n=0;n<h;n++) { trace.addeq(elements[n][n]); } //add up each diagonal element
    return trace;                                         //return result
  }
  
  public Complex determinant() { //returns the determinant
    if(h!=w) { throw new IllegalArgumentException("Cannot take determinant of "+getDimensions()+" (must be square)"); } //if not square, throw exception
    switch(h) { //switch the dimensions
      case 0: return Cpx.one();             //0x0: determinant is 1
      case 1: return elements[0][0].copy(); //1x1: determinant is the only element
      case 2: return elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])); //2x2: ad-bc
      case 3: return get(1,1).mul(get(2,2).mul(get(3,3)).subeq(get(2,3).mul(get(3,2)))) .addeq( //3x3: Rule of Saurus
                     get(1,2).mul(get(2,3).mul(get(3,1)).subeq(get(2,1).mul(get(3,3))))).addeq(
                     get(1,3).mul(get(2,1).mul(get(3,2)).subeq(get(2,2).mul(get(3,1)))));
      //default: throw new RuntimeException("Determinants have not yet been implemented for matrices of size "+getDimensions());
      default: { //4x4 and onward:
        CMatrix echelon = clone(); //clone the matrix
        Complex factor = echelon.rowEchelon(); //put in upper row echelon, record what the determinant multiplied by
        for(int n=0;n<h;n++) { if(echelon.elements[n][n].equals(0)) { return Cpx.one(); } } //if any of the diagonal elements are 0, the determinant is 0
        return factor; //otherwise, return the factor
      }
    }
  }
  
  public Complex frobenius(final CMatrix m) { //takes the frobenius product (very similar to the dot product)
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot take Frobenius product between "+getDimensions()+" and "+m.getDimensions()); } //if different dimensions, throw exception
    Complex prod = new Complex(); //initialize product to 0
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      prod.addeq(elements[i][j].conj().mul(m.elements[i][j])); //add together each element-wise product (with this being conjugated, I guess)
    }
    return prod; //return result
  }
  
  public double frobeniusSq() { //takes the square frobenius norm
    double prod = 0; //initialize product to 0
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      prod+=b.absq();                                //add together the absolute square of each element
    }
    return prod;
  }
  
  public double frobenius() { //takes the frobenius norm
    return Math.sqrt(frobeniusSq());
  }
  
  //////////////////// MATRIX SOLVING ////////////////////////////////////
  
  private static class Fusion { int ind; boolean bool; Fusion(int a, boolean b) { ind=a; bool=b; } }
  
  private static boolean lazyCompare(Complex[] a, Complex[] b, int column) { //compares two rows, finds which one has the larger or earlier leading term, column is where to start. Returns true if the second is bigger, false otherwise
    for(int i=column;i<a.length;i++) { //loop through all elements
      if(!a[i].equals(0) || !b[i].equals(0)) { //if at least one element isn't 0:
        return b[i].lazyabs()>a[i].lazyabs();  //return true if b is larger, false otherwise
      }
    }
    return false; //if they're both full of 0s, return false (index is right after the end)
  }
  
  private static int leadingNonzeroIndex(Complex[] a, int column) { //locates the leading non-zero index (column is the smallest index it could be)
    for(int i=column;i<a.length;i++) { //loop through all elements
      if(!a[i].equals(0)) { return i; } //return the index of the first non-zero element
    }
    return a.length; //if none were found, return the element right after the end
  }
  
  private Fusion swapWithLargerRow(int row, int column) { //takes this row, looks for a row with a larger leading element. If found, it swaps the two rows (column is the first element to check) (returns the index of leading element & whether swap occurred)
    int bestRow = row;         //the index of the largest row
    for(int i=row+1;i<h;i++) { //loop through all rows after this one
      boolean comp = lazyCompare(elements[bestRow],elements[i],column); //compare this row with the current best row
      if(comp) { bestRow = i; }                                         //if this row is better, it's now the current best row
    }
    int ind = leadingNonzeroIndex(elements[bestRow], column); //find the location of the first non-zero
    if(bestRow==row) { //if the current row is the best row:
      return new Fusion(ind, false); //return the index as well as false (to indicate there was no swapping)
    }
    else { //otherwise:
      Complex[] temp = elements[row]; elements[row] = elements[bestRow]; elements[bestRow] = temp; //swap the two rows
      return new Fusion(ind, true); //return the index as well as true (to indicate there was swapping)
    }
  }
  
  private Complex rowEchelon() { //reduces matrix to upper row echelon, while also swapping rows for the sake of roundoff, dividing rows so their leading term is 1 for the sake of roundoff, and also returns the ratio between the determinant before & after this transformation
    int column = 0;             //the index of the first element on the current row that is not guaranteed to be 0
    Complex factor = Cpx.one(); //the number our determinant divided by by through all these transformations
    for(int row=0;row<h;row++) { //loop through all rows
      
      //first, make sure our row has the largest leading term
      Fusion fuse = swapWithLargerRow(row, column); //try to swap with the largest row
      column = fuse.ind;                            //update the value of column
      if(fuse.bool) { factor.negeq(); }             //if a swap occurred, negate the factor
      if(column==w) { return factor; }              //if the column is out of bounds, the rest of the rows are all 0s and there's nothing left to do
      
      //next, divide this row by the leading term
      factor.muleq(elements[row][column]); //multiply our factor by the leading term (since that's what this row is going to divide by)
      Complex inv = column==w-1 ? new Complex() : elements[row][column].inv(); //compute the reciprocal of the leading term (unless we're at the end, then we don't need to)
      elements[row][column] = Cpx.one(); //now, we multiply each element in this row by this inverse. Except the leading term, we can just set that to 1
      for(int j=column+1;j<w;j++) {     //loop through all elements to the right of the leading one
        elements[row][j].muleq(inv);   //multiply them all by that inverse
      }
      
      //then, we subtract a multiple of this row from each row after it, causing their leading term to be 0
      for(int i=row+1;i<h;i++) {
        Complex lead = elements[i][column]; //record the leading term
        elements[i][column] = Cpx.zero();   //now, we subtract the row-th row times lead from this row, element by element. This one can be shortcutted, however, since we can just set it to 0
        for(int j=column+1;j<w;j++) {       //loop through all elements to the right of the leading one
          elements[i][j].subeq(elements[row][j].mul(lead)); //subtract the corresponding element from row row, multiplied by the leading term
        }
      }
      
      //finally, just increment the column number
      column++; //we can do this, because we know the column-th element of all rows after row is 0, and now row is incrementing
    }
    
    return factor; //lastly, we just return the factor
  }
  
  public void reduceRowEchelon() { //takes row echelon matrix and converts to reduced row echelon (backsolving)
    for(int row=h-1;row>=0;row--) { //loop through all rows backwards
      int column = leadingNonzeroIndex(elements[row], row); //find the first non-zero index
      if(column==w) { continue; }                       //if out of bounds, go to the next iteration (on the previous row)
      if(!elements[row][column].equals(1)) { throw new RuntimeException("Why the fuck is the leading term "+elements[row][column]+"?"); } //TEST
      for(int i=0;i<row;i++) {              //loop through all rows before this one
        Complex lead = elements[i][column]; //grab the element on this row, above the leading term of row row
        elements[i][column] = Cpx.zero();   //now, we subtract row row * lead from this row. We can partially shortcut by just setting this term to 0, then doing that to the rest of them
        for(int j=column+1;j<w;j++) {       //loop through all columns after that one
          elements[i][j].subeq(elements[row][j].mul(lead)); //subtract the same element from row row, but scaled by lead
        }
      }
    }
  }
  
  public CMatrix augment(CMatrix m) { //returns the result of augmenting this matrix with another
    if(h!=m.h) { throw new MatrixSizeException("Cannot augment "+getDimensions()+" with "+m.getDimensions()); }
    Complex[][] aug = new Complex[h][w+m.w]; //instantiate new augmented matrix
    for(int i=0;i<h;i++) { //loop through all rows
      for(int j=0;j<w;j++) { aug[i][j] = elements[i][j].clone(); } //copy over these elements
      for(int j=0;j<m.w;j++) { aug[i][j+w] = m.elements[i][j].clone(); } //copy over the elements from the other matrix
    }
    return new CMatrix(h,w+m.w,aug); //construct and return the new augmented matrix
  }
  
  public CMatrix augment(CVector v) { //returns the result of augmenting this matrix with a vector
    if(h!=v.size()) { throw new MatrixSizeException("Cannot augment "+getDimensions()+" with vector of size "+v.size()); }
    Complex[][] aug = new Complex[h][w+1]; //instantiate new augmented matrix
    for(int i=0;i<h;i++) { //loop through all rows
      for(int j=0;j<w;j++) { aug[i][j] = elements[i][j].clone(); } //copy over these elements
      aug[i][w] = v.elements[i].clone(); //copy over the elements from the vector
    }
    return new CMatrix(h,w+1,aug); //construct & return the new augmented matrix
  }
  
  public CMatrix leftDivide(CMatrix m) { //computes this^-1 * m
    if(h!=w) { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(w!=m.h) { throw new MatrixSizeException("Cannot perform "+getDimensions()+" \\ "+m.getDimensions()); } //if dimensions don't match, throw exception
    
    if(h==0) { return new CMatrix(0,m.w); } //0x0 matrix: return 0x(m.w) matrix
    if(h==1) { return m.div(elements[0][0]); } //1x1 matrix: return m / the only element
    if(h==2) { //2x2 matrix: Cramer's rule
      Complex[][] inst = new Complex[2][m.w];       //instantiate array of complex numbers
      Complex factor = elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])).inv(); //compute 1 / the determinant
      for(int j=0;j<m.w;j++) { //loop through all columns
        inst[0][j] = elements[1][1].mul(m.elements[0][j]).subeq(elements[0][1].mul(m.elements[1][j])).muleq(factor); //compute one element
        inst[1][j] = elements[0][0].mul(m.elements[1][j]).subeq(elements[1][0].mul(m.elements[0][j])).muleq(factor); //compute the other element
      }
      return new CMatrix(2,m.w,inst); //construct & return the resulting matrix
    }
    //otherwise, we have to solve by Gaussian elimination
    
    CMatrix aug = augment(m); //first, augment this with the matrix m
    aug.rowEchelon();         //convert into upper row echelon
    if(aug.elements[h-1][h-1].equals(0)) { //if at least one diagonal element is 0:
      //The matrix is uninvertible. Now we just have to figure out if there are 0 solutions or infinite solutions
      for(int i=h-1;i>=0;i--) { //loop through all rows backwards, stop when we reach one with a non-zero diagonal
        if(!aug.elements[i][i].equals(0)) { throw new RuntimeException("Cannot invert matrix: Infinite Solutions"); } //if all the degenerate rows were filled with 0s, we have infinite solutions
        for(int j=i+1;j<w;j++) { if(!aug.elements[i][j].equals(0)) { throw new RuntimeException("Cannot invert matrix: No Solutions"); } } //otherwise, if at least one element in a degenerate row contains a non-zero, there are no solutions
      }
    }
    aug.reduceRowEchelon(); //otherwise, reduce the row echelon
    
    Complex[][] inst = new Complex[h][m.w]; //instantiate new array for the resulting matrix
    for(int i=0;i<h;i++) for(int j=0;j<m.w;j++) { //loop through all elements
      inst[i][j] = aug.elements[i][j+w];          //set each element (cutting out the part augmented to the left)
    }
    return new CMatrix(h,m.w,inst); //construct resulting matrix & return result
  }
  
  public CMatrix rightDivide(CMatrix m) { //computes this * m^-1
    if(m.h!=m.w) { throw new MatrixSizeException("Cannot invert "+m.getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(w!=m.h) { throw new MatrixSizeException("Cannot perform "+getDimensions()+" / "+m.getDimensions()); } //if dimensions don't match, throw exception
    if(w==0) { return new CMatrix(0,w); } //special case: 0x0 matrix, return 0xw matrix
    
    return m.transpose().leftDivide(transpose()).transpose(); //now, just transpose them both, perform left division, and transpose back
  }
  //TODO TEST
  
  public CMatrix inv() { //computes the inverse
    if(h!=w) { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    
    if(h==0) { return new CMatrix(0,0); } //0x0 matrix: return 0x0 matrix
    if(h==1) { if(elements[0][0].equals(0)) { throw new RuntimeException("Matrix is uninvertible"); } return new CMatrix(1,1,elements[0][0].inv()); } //1x1 matrix: return 1 / the only element
    if(h==2) { //2x2 matrix: Cramer's rule
      Complex factor = elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])).inv(); //compute 1 / the determinant
      if(factor.isInf() || factor.isNaN()) { throw new RuntimeException("Matrix is uninvertible"); }       //if overflow: throw exception
      return new CMatrix(2,2, new Complex[][] {{elements[1][1].copy(),elements[0][1].neg()}, {elements[1][0].neg(), elements[0][0].copy()}}).muleq(factor); //return the adjugate over the determinant
    }
    //otherwise, we have to solve by Gaussian elimination
    
    CMatrix aug = augment(CMatrix.identity(h)); //augment with an identity matrix
    aug.rowEchelon();                           //convert into upper row echelon
    if(aug.elements[h-1][h-1].equals(0)) { //if at least one diagonal element is 0:
      throw new RuntimeException("Matrix is uninvertible"); //throw exception
    }
    aug.reduceRowEchelon(); //otherwise, reduce the row echelon
    
    Complex[][] inst = new Complex[h][w]; //instantiate new array for the resulting matrix
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = aug.elements[i][j+w];        //set each element (cutting out the part augmented to the left)
    }
    CMatrix inv = new CMatrix(h,w,inst); //construct the resulting matrix
    
    CMatrix adjust = inv.mul(this).mul(inv); //compute a Newton-Raphson adjustment
    inv.muleq(2).subeq(adjust);              //perform the adjustment
    return inv;                              //return result
    
    //return new CMatrix(h,w,inst); //construct resulting matrix & return result
  }
  
  public CVector leftDivide(CVector v) { //computes this^-1 * v
    if(h!=w)        { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(w!=v.size()) { throw new MatrixSizeException("Cannot perform "+getDimensions()+" \\ vector of size "+v.size()); } //if dimensions don't match, throw exception
    
    if(h==0) { return new CVector(); } //0x0 matrix: return 0D vector
    if(h==1) { return v.div(elements[0][0]); } //1x1 matrix: return v / the only element
    if(h==2) { //2x2 matrix: Cramer's rule
      Complex factor = elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])).inv(); //compute 1 / the determinant
      Complex x = elements[1][1].mul(v.elements[0]).subeq(elements[0][1].mul(v.elements[1])).muleq(factor); //compute x
      Complex y = elements[0][0].mul(v.elements[1]).subeq(elements[1][0].mul(v.elements[0])).muleq(factor); //compute y
      return new CVector(x,y); //construct & return the resulting matrix
    }
    //otherwise, we have to solve by Gaussian elimination
    
    CMatrix aug = augment(v); //first, augment this with the matrix m
    aug.rowEchelon();         //convert into upper row echelon
    if(aug.elements[h-1][h-1].equals(0)) { //if at least one diagonal element is 0:
      //The matrix is uninvertible. Now we just have to figure out if there are 0 solutions or infinite solutions
      for(int i=h-1;i>=0;i--) { //loop through all rows backwards, stop when we reach one with a non-zero diagonal
        if(!aug.elements[i][i].equals(0)) { throw new RuntimeException("Cannot invert matrix: Infinite Solutions"); } //if all the degenerate rows were filled with 0s, we have infinite solutions
        for(int j=i+1;j<w;j++) { if(!aug.elements[i][j].equals(0)) { throw new RuntimeException("Cannot invert matrix: No Solutions"); } } //otherwise, if at least one element in a degenerate row contains a non-zero, there are no solutions
      }
    }
    aug.reduceRowEchelon(); //otherwise, reduce the row echelon
    
    Complex[] inst = new Complex[h]; //instantiate new array for the resulting vector
    for(int i=0;i<h;i++) {           //loop through all elements
      inst[i] = aug.elements[i][w];  //set each element (cutting out everything but the last column)
    }
    return new CVector(inst); //construct resulting vector & return result
  }
  
  public CVector rightDivide(CVector v) { //computes v * this^-1
    if(h!=w) { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(h!=v.size()) { throw new MatrixSizeException("Cannot perform vector["+v.size()+"] / "+getDimensions()); } //if dimensions don't match, throw exception
    if(v.size()==0) { return new CVector(); } //special case: 0x0 matrix, return 0-D vector
    
    return transpose().leftDivide(v); //now, just transpose this, then perform left division. Surprisingly, yes, it is exactly that simple
  }
  
  ///////////////////////////////////////// EIGENVALUES / EIGENVECTORS /////////////////////////////////////////////////////
  
  public CMatrix upperHessenberg() { //computes & returns the upper hessenberg form
    if(h!=w) { throw new MatrixSizeException("Cannot put "+getDimensions()+" into upper Hessenberg form (must be square)"); } //if not square, throw exception
    
    CMatrix clone = clone();      //clone the matrix
    clone.putInUpperHessenberg(); //put the clone into upper Hessenberg
    return clone;                 //return result
  }
  
  private void putInUpperHessenberg() { //puts matrix into upper Hessenberg (ASSUMING that it's square)
    if(h<3) { return; } //if 0x0, 1x1, or 2x2, there is no subdiagonal, it's already in upper Hessenberg, you can quit
    
    for(int p=0;p<h-2;p++) { //loop through all but the last 2 columns, recursively making each column's subdiagonal all 0s w/out changing the eigenvalues
      //first, construct the Householder vector
      Complex[] vector = new Complex[h-p-1]; //initialize vector to use as base for Householder transformation
      double magSq = 0;                      //this will be used to compute the frobenius norm at the same time we initialize all elements of the vector
      for(int i=p+1;i<h;i++) {                 //loop through all elements of the Householder vector
        vector[i-p-1] = elements[i][p].copy(); //set each element (copying for safety)
        magSq += vector[i-p-1].absq();         //compute the sum of the absolute square of each element
      }
      if(magSq==vector[0].absq()) { continue; } //special case: the Householder vector is 0 or points in the x direction: the subdiagonal is all 0s, there's no more work to be done here
      //now, we have to shift the vector in the x direction by a given amount. First, compute that amount.
      Complex change = (vector[0].equals(0) ? Cpx.one() : vector[0].sgn()).muleq(Math.sqrt(magSq)); //it's the frobenius norm times either the signum of element 0 or times 1
      vector[0].addeq(change);  //add that change
      
      //next, construct the Householder matrix
      magSq += 2*vector[0].re*change.re+2*vector[0].im*change.im-change.absq(); //first, adjust the frobenius square, accounting for the vector now being adjusted
      double factor = 2d/magSq; //compute twice the reciprocal of the frobenius square (makes things easier in a bit)
      Complex[][] matrix = new Complex[h-p-1][h-p-1];     //initialize its dimensions
      for(int i=0;i<h-p-1;i++) for(int j=0;j<h-p-1;j++) { //loop through all elements
        if(i==j) { matrix[i][j] = new Complex(1-vector[i].absq()*factor); } //if i==j, set it to 1-2|v_i|^2/||v||^2
        else { matrix[i][j] = vector[i].mul(vector[j].conj()).muleq(-factor); } //otherwise, set it to -2v_iconj(v_j)/||v||^2    
      }
      CMatrix householder = new CMatrix(h-p-1,h-p-1,matrix); //use 2D array to construct Householder matrix
      //println(matrix[0][0], matrix[0][1], matrix[1][0], matrix[1][1]);
      
      
      //now, we just have to replace our whole matrix A with H*A*H, where H is a slightly altered version of the matrix above.
      //Altered i.e. We expanded its dimensions to the up/left until it was the same size as A, then put an identity matrix on the top left
      //To do this, we consider 4 quadrants of A. The top left quadrant does not change. The top right quadrant multiplies on the right by H.
      //The bottom left quadrant multiplies on the left by H (which can be shortcutted). The bottom right is multiplied on the left AND right by H.
      
      //First, the bottom left:
      elements[p+1][p] = change.neg(); //a shortcut: the rightmost column vector multiplies by the householder (causing it to point in the x direction), and every other vector was already 0 and won't change after multiplication
      for(int n=p+2;n<h;n++) { elements[n][p] = Cpx.zero(); } //since it's an x vector, the first element isn't 0, the rest are 0
      
      //Next, multiply the top & bottom right by the householder (A*H):
      Complex[][] copy = new Complex[h][w-p-1];         //create the matrix we use to generate the product
      copy2DArray(elements, 0,p+1, copy, 0,0, h,w-p-1); //copy the right 2 quadrants into the copy matrix
      CMatrix product = new CMatrix(h,w-p-1,copy).mul(householder); //right multiply by householder
      copy2DArray(product.elements, 0,0, elements, 0,p+1, h,w-p-1); //copy the product back into this matrix, but only the top right quadrant
      
      //Finally, left multiply the bottom right by the householder (H*A):
      copy = new Complex[h-p-1][w-p-1];                             //create the matrix we use to generate the last product
      copy2DArray(product.elements, p+1,0, copy, 0,0, h-p-1,w-p-1); //copy the bottom right quadrant into this copy matrix
      product = householder.mul(new CMatrix(h-p-1,w-p-1,copy));     //left multiply by householder
      copy2DArray(product.elements, 0,0, elements, p+1,p+1, h-p-1,w-p-1); //copy the product back into this matrix
    }
  }
  
  private CMatrix[] qrDecomposeHessy() { //performs QR decomposition (PRE-REQUISITE: MUST BE IN UPPER HESSENBERG)
    CMatrix qTotal = identity(h); //load the Q in QR decomposition (which is initialized to an identity matrix)
    
    for(int p=0;p<h-1;p++) { //loop through all iterations of this
      Complex[] vector = new Complex[] {elements[p][p].copy(), elements[p+1][p].copy()};            //load our householder vector
      double magSq = vector[0].absq()+vector[1].absq();                                             //compute the vector's frobenius square
      Complex change = (vector[0].equals(0) ? Cpx.one() : vector[0].sgn()).muleq(Math.sqrt(magSq)); //compute how much the vector's x coord must change by
      vector[0].addeq(change);                   //shift our x position by that much
      magSq = vector[0].absq()+vector[1].absq(); //recompute the frobenius square
      
      double factor = -2d/magSq; //compute this useful factor
      Complex[][] q = new Complex[][] {{new Complex(1+factor*vector[0].absq()),vector[0].mul(vector[1].conj()).muleq(factor)}, {vector[0].conj().mul(vector[1]).muleq(factor),new Complex(1+factor*vector[1].absq())}};
      //compute the above 2x2 matrix. We'll now be left multiplying rows p and p+1 by the above matrix
      
      //now, we have to left multiply this matrix by the above matrix (with the implication that it's being shoved into an identity at position p,p)
      elements[p][p] = change.neg(); elements[p+1][p] = Cpx.zero(); //left multiply first non-zero vector by q, resulting in an x vector
      for(int j=p+1;j<w;j++) { //loop through all columns to the right of that column, and left multiply them by q
        Complex temp = q[0][0].mul(elements[p][j]).addeq(q[0][1].mul(elements[p+1][j]));     //compute the x value (without setting)
        elements[p+1][j] = q[1][0].mul(elements[p][j]).addeq(q[1][1].mul(elements[p+1][j])); //compute the y value (with setting)
        elements[p][j] = temp;                                                               //set the x value
      }
      
      //lastly, we right multiply our total q with our 2x2 q. Specifically, we'll be multiplying columns p and p+1 by that 2x2 matrix (ignoring stuff below p+1, since that's all 0)
      //row p+1 is a y vector, all rows before that are x vectors, all rows after that are 0
      for(int i=0;i<=p;i++) { //loop through all rows before p+1
        qTotal.elements[i][p+1] = q[0][1].mul(qTotal.elements[i][p]); //compute and set the second value
        qTotal.elements[i][p].muleq(q[0][0]);                         //compute and set the first value
      }
      qTotal.elements[p+1][p] = q[1][0].mul(qTotal.elements[p+1][p+1]); //compute and set the first value of row p+1
      qTotal.elements[p+1][p+1].muleq(q[1][1]);                         //compute and set the second value of row p+1
    }
    return new CMatrix[] {qTotal,this}; //return Q and R
  }
  
  private static Complex[] eigenvalues2x2(Complex[][] mat) { //finds the eigenvalues of the given 2x2 matrix
    Complex ht = mat[0][0].lazyabs()>=9.97920154767359906d ? mat[0][0].scalb(-1).addeq(mat[1][1].scalb(-1)) : mat[0][0].add(mat[1][1]).scalbeq(-1); //compute the half trace (never overflows)
    Complex dt = mat[0][0].mul(mat[1][1]).subeq(mat[0][1].mul(mat[1][0]));                                                                          //compute the determinant (might overflow)
    if(dt.isInf() || dt.isNaN()) { //if infinite or NaN:
      ht.scalbeq(-512); dt = mat[0][0].scalb(-512).mul(mat[1][1].scalb(-512)).subeq(mat[0][1].scalb(-512).mul(mat[1][0].scalb(-512))); //divide half trace by 2^512, determinant by 2^1024
      Complex[] eig = solveQuad(ht, dt);        //solve the quadratic
      eig[0].scalbeq(512); eig[1].scalbeq(512); //multiply both by 2^512
      return eig;                               //return result
    }
    if(ht.sq().subeq(dt).lazyabs()==Double.POSITIVE_INFINITY) { //if discriminant overflows:
      ht.scalbeq(-512); dt.scalbeq(-1024); //scale down half trace by 2^512, determinant by 2^1024
      Complex[] eig = solveQuad(ht, dt);   //solve the quadratic
      eig[0].scalbeq(512); eig[1].scalbeq(512); //multiply both by 2^512
      return eig;                               //return result
    }
    if(ht.sq().equals(0) && !ht.equals(0) && dt.equals(0) && mat[0][1].lazyabs()<1 && mat[1][0].lazyabs()<1) { //if the components are all too small:
      ht.scalbeq(512); dt = mat[0][0].scalb(512).mul(mat[1][1].scalb(512)).subeq(mat[0][1].scalb(512).mul(mat[1][0].scalb(512))); //multiply half trace by 2^512, determinant by 2^1024
      Complex[] eig = solveQuad(ht,dt);           //solve the quadratic
      eig[0].scalbeq(-512); eig[1].scalbeq(-512); //divide both by 2^512
      return eig;                                 //return result
    }
    return solveQuad(ht,dt); //default: just use the quadratic formula
  }
  
  private static Complex[] solveQuad(Complex ht, Complex dt) { //solve quadratic 2x2 eigenvalues given half trace and determinant
    if(ht.absq()>2.5e5f*dt.lazyabs()) { //trace² is much larger than determinant:
      ht.scalbeq(1); Complex inv = ht.inv(); //Quadratic formula will fail due to roundoff. Instead, compute approximation. First, find trace, find 1/trace
      Complex eig1 = dt.mul(inv.sq()).addeq(1).muleq(dt).muleq(inv); //smallest eigenvalue ~= |M|/Tr(M)+|M|²/Tr(M)³
      return new Complex[] {eig1, ht.subeq(eig1)}; //the other eigenvalue will be Tr(M)-(smallest). Return them both
    }
    //otherwise, use the standard formula
    Complex root = ht.sq().subeq(dt).sqrt(); //compute √(ht²-dt) (square root of discriminant)
    return new Complex[] {ht.add(root), ht.sub(root)}; //compute & return ht±√(ht²-dt)
  }
  
  /*private static Complex[] eigenvalues2x2(Complex[][] mat) { //finds the eigenvalues of the given 2x2 matrix
    Complex trace = mat[0][0].add(mat[1][1]); //compute trace
    Complex det   = mat[0][0].mul(mat[1][1]).subeq(mat[0][1].mul(mat[1][0])); //compute determinant
    
    Complex eigen1;
    if(trace.absq()>1E6*det.lazyabs()) { //trace² is much larger than determinant:
      Complex inv = trace.inv();         //quadratic formula will fail due to roundoff
      eigen1=det.mul(inv.sq()).add(1).muleq(det).muleq(inv); //smallest eigenvalue ~= |M|/Tr(M)+|M|²/Tr(M)^3
    }
    else {                               //otherwise:
      eigen1=trace.add(trace.sq().subeq(det.mul(4)).sqrt()).muleq(0.5); //use the quadratic formula
    }
    
    return new Complex[] {eigen1, trace.subeq(eigen1)}; //the sum of both eigenvalues is the trace, so we already know the other one. return both eigenvalues
  }*/
  
  /*private static Complex[] eigenvalues2x2(Complex[][] mat) { //finds the eigenvalues of the given 2x2 matrix
    if(mat[0][0].isInf() || mat[0][1].isInf() || mat[1][0].isInf() || mat[1][1].isInf()) { } //TODO deal with that
    Complex ht = mat[0][0].add(mat[1][1]).muleq(0.5); //compute half trace
    if(ht.isInf()) { ht = mat[0][0].mul(0.5).add(mat[1][1].mul(0.5)); } //if it overflows, try computing it another way
    Complex dt = mat[0][0].mul(mat[1][1]).subeq(mat[0][1].mul(mat[1][0])); //compute determinant
    
    boolean overflow = dt.isInf();
    if(overflow) { ht.scalbeq(-511); dt = mat[0][0].scalb(-511).mul(mat[1][1].scalb(-511)).subeq(mat[0][1].scalb(-511).mul(mat[1][0].scalb(-511))); } //determinant overflows: scale back
    else if(ht.lazyabs()>1.375e154d) { overflow=true; ht.scalbeq(-511); dt.scalbeq(-1022); } //trace squared overflows: scale back
    
    Complex diff = ht.sq().subeq(dt); //compute discriminant of quadratic
    boolean adj = diff.isInf();
    if(adj) { diff = ht.mul(0.5).sq().subeq(dt.mul(0.25)); }
    
    
  }*/
  
  private Complex[] getEigenvalues() { //obtains & returns eigenvalues, all while editing the original matrix
    Complex[] eigen = new Complex[h]; //initialize eigenvalue array
    
    putInUpperHessenberg(); //convert this matrix to upper hessenberg
    int iter = 0;
    while(h>1) { //perform the following until we only have 1 (or 0) rows left
      
      if(elements[h-1][w-2].lazyabs() <= elements[h-1][w-1].ulpMax()*8) { //if the lowest subdiagonal element is practically 0:
        eigen[h-1] = elements[h-1][w-1]; //set one of the eigenvalues to the bottom-right eigenvalue
        
        Complex[][] replace = new Complex[h-1][w-1];      //begin shrinking the matrix by 1
        copy2DArray(elements, 0,0, replace,0,0, h-1,w-1); //copy the elements over to the replace matrix
        elements = replace; h--; w--;                     //replace the elements array, decrement dimensions
        
        continue; //start the iteration all over (to make sure height is at least 1)
      }
      
      //otherwise, we have to perform the QR algorithm repeatedly until the lowest subdiagonal is 0
      Complex scalar; //this is what we will subtract to speed up the QR algorithm
      Complex[] vals = eigenvalues2x2(new Complex[][] {{elements[h-2][w-2],elements[h-2][w-1]},{elements[h-1][w-2],elements[h-1][w-1]}}); //compute the eigenvalues of the bottom right 2x2 submatrix
      
      if(vals[0].sub(elements[h-1][w-1]).lazyabs() <= vals[1].sub(elements[h-1][w-1]).lazyabs()) { scalar = vals[0]; } //set our scalar to whichever eigenvalue is closest to the bottom right element
      else                                                                                       { scalar = vals[1]; }
      
      CMatrix[] qr = subeq(scalar).qrDecomposeHessy(); //subtract the scalar, then QR decompose (note: this matrix will be in upper hessenberg)
      elements = mul(qr[0]).elements;                  //replace this (which is Q*R) with R*Q
      addeq(scalar);                                   //add back the scalar
      iter++;
    }
    
    if(h==1) { eigen[0] = elements[0][0]; } //lastly, grab the final eigenvalue from this now 1x1 matrix
    
    return eigen; //and now, finally, return the eigenvalues
  }
  
  public Complex[] eigenvalues() { //computes the eigenvalues
    if(h!=w) { throw new RuntimeException("Cannot compute eigenvalues for "+getDimensions()+" (only works for square matrices)"); } //if not square, throw an exception
    
    if(h==0) { return new Complex[0]; } //0x0: return empty array
    if(h==1) { return new Complex[] {elements[0][0].copy()}; } //1x1: return the only element
    if(h==2) { return eigenvalues2x2(elements); } //2x2: use quadratic formula
    
    Complex[] eig = clone().getEigenvalues(); //otherwise, use the QR algorithm to compute the eigenvalues, being sure to clone this matrix so nothing is overwritten
    //then, run 1 iteration of Newton's method to make things slightly more accurate
    for(Complex c : eig) { //loop through all eigenvalues
      try { CMatrix inv = sub(c).inv(); c.addeq(inv.trace().inv()); } //lambda += 1/Tr((M-lambda*I)^-1)
      catch(RuntimeException ex) { }                                  //if (M-lambda*I) is uninvertible, this eigenvalue does NOT need adjusting
    }
    //now, finally, we have to group together identical eigenvalues
    for(int n=0;n<h;) { //loop through the eigenvalue array
      int mult = 1; //multiplicity of this eigenvalue
      while(n+mult<h && eig[n].equals(eig[n+mult])) { mult++; } //for each identical eigenvalue right after this one, increment multiplicity (also, make sure to stop before going out of bounds)
      for(int k=n+mult+1;k<h;k++) {   //loop through all eigenvalues after the group of identical eigenvalues (also skip the one that was obviously different)
        if(eig[n].equals(eig[k])) { //if both eigenvalues are the same
          Complex temp = eig[n+mult]; eig[n+mult] = eig[k]; eig[k] = temp; ++mult; //swap both indices, increment multiplicity
        }
      }
      n+=mult; //increment the index by the multiplicity
    }
    
    return eig; //return result
    //return clone().getEigenvalues(); //otherwise, use the QR algorithm to compute the eigenvalues, being sure to clone this matrix so nothing is overwritten
  }
  
  private CVector[] eigenvectorsGivenEigenvalues(Complex[] vals) { //computes the eigenvectors given the eigenvalues
    CVector[] vec = new CVector[h];    //initialize vector array
    for(int n=0;n<h;) {             //loop through all eigenvalues/vectors
      int mult = 1; //first, find the multiplicity of this eigenvalue
      for(int k=n+1;k<h && vals[n].equals(vals[k]);k++) { ++mult; } //increment multiplicity until we reach the end or find an eigenvalue that's different
      
      CMatrix rref = sub(vals[n]);      //subtract each eigenvalue to create a degenerate matrix
      rref.rowEchelon();                //put into upper row echelon
      rref.elements[h-1][w-1].set(0);   //make the bottom right element 0
      rref.reduceRowEchelon();          //put it into reduced row echelon form (rref)
      
      //next, we have to rearrange our rows so that each row either has a leading 1 in the diagonal element or is empty (i.e. all 0)
      int dim = 0; //at the same time, we will also calculate the dimension of our eigenspace (which is equal to the number of rows which are all 0s)
      boolean pivot[] = new boolean[h]; //this array will tell us which rows will and won't be used as pivot points for our eigenspace (true=will, false=won't)
      
      for(int i=0;i<h;i++) { //loop through all rows
        if(!rref.elements[i][i].equals(1)) { //if the diagonal element isn't 1:
          Complex[] temp = rref.elements[h-1]; //grab the last row (which is empty
          for(int i2=h-1;i2>i;i2--) { //loop through all rows backwards
            rref.elements[i2] = rref.elements[i2-1]; //replace each row w/ the previous row
          }
          rref.elements[i] = temp; //replace this row with that empty row at the end
          
          pivot[i] = true; //this row can and will be used as a pivot 
          ++dim;           //increment the eigenspace dimension
        }
      }
      
      Complex[][] vecs = new Complex[dim][h]; //create array of arrays, each of which will be used to initialize vectors
      
      int ind = 0; //the index in our vecs array
      for(int i=0;i<h;i++) if(pivot[i]) { //loop through all rows in our rref matrix (skip the non-pivots)
        //set the corresponding vector equal to the negative of column i, but with the diagonal element set to 1
        for(int j=0;j<i;j++) { vecs[ind][j] = rref.elements[j][i].negeq(); } //set the elements above this to the negative of the corresponding elements
        vecs[ind][i] = Cpx.one(); //set the diagonal element to 1
        for(int j=i+1;j<h;j++) { vecs[ind][j] = rref.elements[j][i]; } //set the elements below to the corresponding elements (which are all 0, but let's save space :) )
        ++ind; //increment the index
      }
      
      for(int n2=0;n2<dim;n2++) { //now, we have to loop through all the basis vectors we're going to insert
        vec[n+n2] = new CVector(vecs[n2]).frobeniusUnit(); //set each vector (making sure to normalize it)
      }
      
      for(int n2=dim;n2<mult;n2++) { //lastly, we have to insert the redundant eigenvectors (this happens if the multiplicity exceeds the eigenspace dimension)
        vec[n+n2] = vec[n+dim-1].clone(); //fill it with the last vector
      }
      
      n+=mult; //increment n by the multiplicity of this eigenvalue
    }
    return vec; //return result
  }
  
  public CVector[] eigenvectors() {
    if(h!=w) { throw new RuntimeException("Cannot compute eigenvectors for "+getDimensions()+" (only works for square matrices)"); } //if not square, throw an exception
    
    if(h==0) { return new CVector[0]; } //0x0: return empty array
    if(h==1) { return new CVector[] {new CVector(1)}; } //1x1: return single vector [1]
    
    return eigenvectorsGivenEigenvalues(eigenvalues()); //default: grab the eigenvalues, use those to compute the eigenvectors
  }
  
  public Object[] eigenvalues_and_vectors() {
    Complex[] val = eigenvalues();
    CVector[] vec = eigenvectorsGivenEigenvalues(eigenvalues());
    return new Object[] {val, vec};
  }
  
  ///////////////////////////////////////// POWERS, LOGARITHMS, AND OTHER IMPORTANT FUNCTIONS //////////////////////////////////////
  
  public CMatrix sq() { return mul(this); } //square
  public CMatrix cub() { return mul(sq()); } //cube
  
  public CMatrix pow(int a) { //raise to an integer power (using exponentiation by squaring)
    if(a==1) { return clone(); }
    
    if(!isSquare()) { throw new RuntimeException("Cannot raise "+getDimensions()+" ^ "+a+" (it's not a square)"); }
    
    if(a<0) { return inv().pow(-a); } //a is negative: return inverse ^ -a
    
    CMatrix ans=CMatrix.identity(h); //return value: M^a (init to Identity in case a==0)
    int ex=a;                        //copy of a
    CMatrix iter=clone();            //M ^ (2 ^ (whatever digit we're at))
    boolean inits=false;             //true once ans is initialized (to something other than 1)
    
    while(ex!=0) {                               //loop through all a's digits (if a==0, exit loop, return 1)
      if((ex&1)==1) {
        if(inits) { ans = ans.mul(iter);    } //mult ans by iter ONLY if this digit is 1
        else      { ans = iter; inits=true; } //if ans still = Identity, set ans=iter (instead of multiplying by iter)
      }
      ex >>= 1;                             //remove the last digit
      if(ex!=0) { iter = iter.sq(); }       //square the iterator (unless the loop is over)
    }
    
    return ans; //return the result
  }
  
  public CMatrix pow(double a) {
    if((int)a==a) { return pow((int)a); }
    if(!isSquare()) { throw new RuntimeException("Cannot raise "+getDimensions()+" ^ "+a+" (it's not a square)"); }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? vals[i].pow(a) : new Complex(); }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  public CMatrix pow(Complex a) {
    if(a.isReal()) { return pow(a.re); }
    if(!isSquare()) { throw new RuntimeException("Cannot raise "+getDimensions()+" ^ "+a+" (it's not a square)"); }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? vals[i].pow(a) : new Complex(); }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  public CMatrix sqrt(boolean... b) {
    if(!isSquare()) { throw new RuntimeException("Cannot square root "+getDimensions()+" (it's not a square)"); }
    if(b.length!=h) { throw new RuntimeException(getDimensions()+" square root requires "+h+" parameters"); }
    
    if(h==0) { return new CMatrix(0,0); }
    if(h==1) { return new CMatrix(1,1,b[0] ? elements[0][0].sqrt() : elements[0][0].sqrt().negeq()); }
    if(h==2) {
      Complex[] vals = eigenvalues2x2(elements);
      Complex l1 = b[0] ? vals[0].sqrt() : vals[0].sqrt().negeq(), l2 = b[1] ? vals[1].sqrt() : vals[1].sqrt().negeq();
      return add(l1.mul(l2)).diveq(l1.add(l2));
    }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? (b[i] ? vals[i].sqrt() : vals[i].sqrt().negeq()) : new Complex(); }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  private CMatrix evaluateFunction(String name, MatFunc f) {
    if(!isSquare()) { throw new RuntimeException("Cannot evaluate"+name+" on "+getDimensions()+" (it's not a square)"); }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {
      vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? f.func(0,vals[i]) : new Complex();
    }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  final static MatFunc sqrt = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.sqrt(); }
    double coef = 1; for(int k=0;k<n;k++) { coef*=0.5f-k; } return inp.pow(0.5f-n).muleq(coef);
  } },
  exp = new MatFunc() { public Complex func(int n, Complex inp) { return inp.exp(); } },
  log = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.log(); }
    double coef = 1; for(int k=1;k<n;k++) { coef*=-k; } return inp.pow(-n).muleq(coef);
  } },
  sin = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? (n&2)==0 ? inp.sin() : inp.sin().negeq() : (n&2)==0 ? inp.cos() : inp.cos().negeq(); } },
  cos = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? (n&2)==0 ? inp.cos() : inp.cos().negeq() : (n&2)!=0 ? inp.sin() : inp.sin().negeq(); } },
  sinh = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? inp.sinh() : inp.cosh(); } },
  cosh = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? inp.cosh() : inp.sinh(); } },
  atan = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.atan(); }
    Complex term = inp.addI(1).pow(-n).subeq(inp.subI(1).pow(-n)).muleq(0.5f*Mafs.factorial(n-1));
    if((n&1)==0) { term.diveqI(); } else { term.muleqI(); }
    return term;
  } },
  atanh = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.atanh(); }
    Complex term = inp.sub(1).pow(-n).subeq(inp.add(1).pow(-n)).muleq(0.5f*Mafs.factorial(n-1));
    if((n&1)==1) { term.negeq(); }
    return term;
  } },
  loggamma = new MatFunc() { public Complex func(int n, Complex inp) { return Cpx2.polygamma(n-1,inp); } };
  
  public CMatrix sqrt() {
    if(!isSquare()) { throw new RuntimeException("Cannot square root "+getDimensions()+" (it's not a square)"); }
    if(h==0) { return new CMatrix(0,0); }
    if(h==1) { return new CMatrix(1,1, elements[0][0].sqrt()); }
    if(h==2) {
      Complex[] vals = eigenvalues2x2(elements);
      Complex l1 = vals[0].sqrt(), l2 = vals[1].sqrt();
      return add(l1.mul(l2)).diveq(l1.add(l2));
    }
    return evaluateFunction("square root",sqrt);
  }
  public CMatrix exp() { return evaluateFunction("exponential",exp); }
  public CMatrix log() { return evaluateFunction("logarithm",log); }
  public CMatrix sin() { return evaluateFunction("sine",sin); }
  public CMatrix cos() { return evaluateFunction("cosine",cos); }
  public CMatrix sinh() { return evaluateFunction("sinh",sinh); }
  public CMatrix cosh() { return evaluateFunction("cosh",cosh); }
  public CMatrix atan() { return evaluateFunction("arc tangent",atan); }
  public CMatrix atanh() { return evaluateFunction("atanh",atanh); }
  
  public CMatrix tan() { return evaluateFunction("tan",cos).leftDivide(evaluateFunction("tan",sin)); }
  public CMatrix tanh() { return evaluateFunction("tanh",cosh).leftDivide(evaluateFunction("tanh",sinh)); }
  public CMatrix sec() { return evaluateFunction("sec",cos).inv(); }
  public CMatrix csc() { return evaluateFunction("csc",sin).inv(); }
  public CMatrix cot() { return evaluateFunction("cot",sin).leftDivide(evaluateFunction("cot",cos)); }
  public CMatrix sech() { return evaluateFunction("sech",cosh).inv(); }
  public CMatrix csch() { return evaluateFunction("csch",sinh).inv(); }
  public CMatrix coth() { return evaluateFunction("coth",sinh).leftDivide(evaluateFunction("coth",cosh)); }
  
  public CMatrix loggamma() { return evaluateFunction("lnΓ",loggamma); }
  public CMatrix factorial() { return add(1).evaluateFunction("!",loggamma).exp(); }
  
  ///////////////////////////////////// LOAD FROM MATRIX /////////////////////////////////
  
  public static CMatrix loadFromString(String s) {
    if(!s.startsWith("[[") || !s.endsWith("]]")) { return null; } //if it doesn't start with [[ and end with ]], return null
    s = s.substring(2,s.length()-2);     //remove [[ and ]]
    
    if(s.startsWith("]")) { //special case: nx0 matrix
      int hig = 1; //calculate the height of the matrix
      while(s.startsWith("],[")) { //repeatedly remove the first 3 characters
        s = s.substring(3);        //remove them
        hig++;                     //increment the height
      }
      if(s.length()==0) { return new CMatrix(hig,0); } //if there's nothing left, return the result
      else { return null; } //otherwise, this matrix is invalid, return the result
    }
    
    String[] split = s.split("\\],\\["); //split into substrings separated by commas with braces around them
    Complex[][] arr = new Complex[split.length][]; //initialize 2D array
    int wid = -1;                                  //width of the array
    for(int i=0;i<arr.length;i++) {                //loop through all the rows
      
      String[] split2 = split[i].split(",");       //split each row into substrings separated by commas
      if(wid==-1) { wid = split2.length; }         //find the actual width
      else if(wid!=split2.length) { return null; } //each array must be of the same length
      
      arr[i] = new Complex[wid];                   //initialize each row
      for(int j=0;j<split2.length;j++) {           //loop through each column
        arr[i][j] = Cpx.complex(split2[j]);        //cast each substring to a complex
      }
    }
    return new CMatrix(arr.length,wid,arr); //create and return matrix
  }
  
  ///////////////////// ARRAY COPYING //////////////////////
  
  public static void copy2DArray(Complex[][] src, int srcPos1, int srcPos2, Complex[][] dest, int destPos1, int destPos2, int length1, int length2) {
    for(int i=0;i<length1;i++) { //loop through all rows we copy over
      System.arraycopy(src[i+srcPos1],srcPos2, dest[i+destPos1],destPos2, length2); //copy over each row
    }
  }
}

public static class MatrixSizeException extends RuntimeException {
  public MatrixSizeException() {
    super("Matrix dimensions are not compatible for the specified operation");
  }
  
  public MatrixSizeException(String message) {
    super(message);
  }
}

static interface MatFunc { //an interface just for storing matrix functions
  public Complex func(int n, Complex inp); //returns the n-th derivative of the function evaluated at input inp
}
public static class CVector implements Iterable<Complex> {
  /////////////// ATTRIBUTES /////////////////
  
  Complex[] elements; //all the elements (x,y,z, etc.)
  
  /////////////// CONSTRUCTORS /////////////////
  
  CVector() { elements = new Complex[0]; }
  
  CVector(Complex... c) {
    for(Complex c2 : c) { if(c2==null) { throw new NullPointerException("Vector cannot have null elements"); } }
    elements = new Complex[c.length];
    arrayCopy(c, elements);
  }
  
  CVector(double... d) {
    elements = new Complex[d.length];
    for(int n=0;n<d.length;n++) { elements[n] = new Complex(d[n]); }
  }
  
  //////////////// INHERITED METHODS ///////////////////
  
  public @Override
  boolean equals(final Object obj) {
    if(!(obj instanceof CVector)) { return false; } //not a vector: return false
    CVector v = (CVector)obj;
    if(v.size() != size()) { return false; } //different sizes: return false
    for(int n=0;n<size();n++) { if(!get(n).equals(v.get(n))) { return false; } } //one or more elements don't equal: return false
    return true; //otherwise, return true
  }
  
  public @Override
  int hashCode() {
    int hash = 0;
    for(Complex c : this) { hash = 31*hash + c.hashCode(); }
    return hash;
  }
  
  public @Override
  CVector clone() {
    Complex[] arr = new Complex[size()];
    for(int n=0;n<size();n++) { arr[n] = elements[n].clone(); }
    return new CVector(arr);
  }
  
  public String toString(int dig) {
    double threshold = 0; //how small something has to be to be rounded down to 0
    if(Complex.omit_Option) { //if we omit small parts, the threshold is non-zero
      double biggest = lazyMag(); //find the biggest element
      threshold = Math.min(1e-11d*biggest, 1e-12d); //set our threshold to either 10^-12, or 10^-11*biggest element
    }
    
    String result = "["; //initialize to opening left bracket
    for(int n=0;n<size();n++) {            //loop through all elements in the array
      if(elements[n].lazyabs()<threshold) { result+="0"; } //if this element is below our threshold, round down to 0
      else { result += elements[n].toString(dig); } //concatenate each element, outputted to the given amount of precision
      if(n!=size()-1) { result+=","; }     //put a comma after all entries but the last
    }
    return result+"]"; //close with right bracket, return result
  }
  
  public @Override
  String toString() { return toString(-1); } //default toString: output result to maximum precision
  
  public @Override
  Iterator<Complex> iterator() { return new Iterator<Complex>() {
    private int index = 0;
    public Complex next() { return elements[index++]; }
    public boolean hasNext() { return index<elements.length; }
  }; }
  
  //////////////// GETTERS / SETTERS /////////////////////
  
  public int size() { return elements.length; }
  
  public Complex get(int ind) { return elements[ind]; }
  
  public void set(int ind, Complex c) {
    if(c==null) { throw new NullPointerException("Cannot give vector null elements"); }
    elements[ind] = c;
  }
  public void set(int ind, double d) { elements[ind] = new Complex(d); }
  
  //////////////// ARITHMETIC //////////////////////
  
  public double lazyMag() { double mag = 0; for(Complex c : this) { mag = Math.max(mag, c.lazyabs()); } return mag; }
  
  public boolean isReal() { for(Complex c : this) { if(!c.isReal( )) { return false; } } return  true; }
  public boolean isZero() { for(Complex c : this) { if(!c.equals(0)) { return false; } } return  true; }
  public boolean isInf () { for(Complex c : this) { if( c.isInf ( )) { return  true; } } return false; }
  
  public CVector negeq () { for(Complex c : this) { c.negeq (); } return this; }
  public CVector muleqI() { for(Complex c : this) { c.muleqI(); } return this; }
  public CVector diveqI() { for(Complex c : this) { c.diveqI(); } return this; }
  public CVector conjeq() { for(Complex c : this) { c.conjeq(); } return this; }
  
  public CVector neg () { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].neg (); } return new CVector(arr); }
  public CVector mulI() { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mulI(); } return new CVector(arr); }
  public CVector divI() { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].divI(); } return new CVector(arr); }
  public CVector conj() { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].conj(); } return new CVector(arr); }
  
  public Complex magSq() { Complex res=Cpx.zero(); for(Complex c : this) { res.addeq(c.sq()); } return res; }
  public Complex mag() {
    double mag = lazyMag(); //first, for the sake of preventing overflow/underflow, compute the lazy magnitude
    if(mag<=1.055e-154d) { Complex sum=Cpx.zero(); for(Complex c : this) { sum.addeq(c.scalb( 1022).sq()); } return sum.sqrt().scalb(-1022); } //if it underflows, we * by 2^1022, find the magnitude, and / by 2^1022
    if(mag>=9.481e+153d) { Complex sum=Cpx.zero(); for(Complex c : this) { sum.addeq(c.scalb(-1022).sq()); } return sum.sqrt().scalb( 1022); } //if it  overflows, we / by 2^1022, find the magnitude, and * by 2^1022
    
    Complex sum=Cpx.zero(); for(Complex c : this) { sum.addeq(c.sq()); } return sum.sqrt(); //default: add the square of each term, find the square root
  }
  
  
  
  public CVector addeq(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot add vector["+size()+"] to vector["+v.size()+"]"); }
    for(int n=0;n<size();n++) { get(n).addeq(v.get(n)); }
    return this;
  }
  public CVector subeq(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot subtract vector["+size()+"] minus vector["+v.size()+"]"); }
    for(int n=0;n<size();n++) { get(n).subeq(v.get(n)); }
    return this;
  }
  public CVector muleq(final Complex c) { for(Complex c2 : this) { c2.muleq(c); } return this; }
  public CVector muleq(final  double d) { for(Complex c  : this) {  c.muleq(d); } return this; }
  public CVector diveq(final Complex c) { Complex inv = c.inv(); for(Complex c2 : this) { c2.muleq(inv); } return this; }
  public CVector diveq(final  double d) { double  inv = 1d/d;    for(Complex c  : this) {  c.muleq(inv); } return this; }
  
  
  public CVector add(final CVector v) {
    if(elements.length!=v.elements.length) { throw new IllegalArgumentException("Cannot add vector["+elements.length+"] to vector["+v.elements.length+"]"); }
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].add(v.elements[n]); }
    return new CVector(arr);
  }
  public CVector sub(final CVector v) {
    if(elements.length!=v.elements.length) { throw new IllegalArgumentException("Cannot subtract vector["+elements.length+"] minus vector["+v.elements.length+"]"); }
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].sub(v.elements[n]); }
    return new CVector(arr);
  }
  public CVector mul(final Complex c) {
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(c); }
    return new CVector(arr);
  }
  public CVector mul(final double d) {
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(d); }
    return new CVector(arr);
  }
  public CVector div(final Complex c) { return mul(c.inv()); }
  public CVector div(final double d) { return mul(1d/d); }
  
  public CVector uniteq() {
    Complex normInv = mag().inv();
    for(Complex c : this) { c.muleq(normInv); }
    return this;
  }
  public CVector unit() {
    Complex normInv = mag().inv();
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(normInv); }
    return new CVector(arr);
  }
  
  
  
  public Complex dot(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot dot vector["+size()+"] with vector["+v.size()+"]"); }
    Complex dot = Cpx.zero();
    for(int n=0;n<size();n++) { dot.addeq(get(n).mul(v.get(n))); }
    return dot;
  }
  public Complex pDot(final CVector v) {
    if(size()!=2 || v.size()!=2) { throw new IllegalArgumentException("Cannot perpendicular-dot vector["+size()+"] with vector["+v.size()+"]"); }
    return get(0).mul(v.get(1)).subeq(get(1).mul(v.get(0)));
  }
  public CVector perp() {
    if(elements.length!=2) { throw new IllegalArgumentException("Cannot apply perpendicular operator to vector["+size()+"]"); }
    return new CVector(elements[1].neg(), elements[0].copy());
  }
  public CVector cross(final CVector v) {
    if(size()!=3 || v.size()!=3) { throw new IllegalArgumentException("Cannot cross vector["+size()+"] with vector["+v.size()+"]"); }
    return new CVector(get(1).mul(v.get(2)).subeq(get(2).mul(v.get(1))), get(2).mul(v.get(0)).subeq(get(0).mul(v.get(2))), get(0).mul(v.get(1)).subeq(get(1).mul(v.get(0))));
  }
  public Complex tripleScalar(final CVector u, final CVector v) {
    if(size()!=3 || u.size()!=3 || v.size()!=3) { throw new IllegalArgumentException("Cannot perform triple scalar product on vector["+size()+"], vector["+u.size()+"], and vector["+v.size()+"]"); }
    return get(0).mul(u.get(1).mul(v.get(2)).subeq(u.get(2).mul(v.get(1)))).addeq(get(1).mul(u.get(2).mul(v.get(0)).subeq(u.get(0).mul(v.get(2))))).addeq(get(2).mul(u.get(0).mul(v.get(1)).subeq(u.get(1).mul(v.get(0)))));
  }
  
  public Complex wedgeMagSq(final CVector v) { //computes the magnitude squared of the wedge product
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot wedge vector["+size()+"] with vector["+v.size()+"]"); } //must have same dimensions
    return magSq().muleq(v.magSq()).subeq(dot(v).sq()); // |a|²|b|²-(a.b)²
  }
  public Complex wedgeMag(final CVector v) { //computes the magnitude of the wedge product
    return wedgeMagSq(v).sqrt(); //square root of magnitude squared
  }
  public Complex wedgeComponent(final CVector v, final int i, final int j) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot wedge vector["+size()+"] with vector["+v.size()+"]"); } //must have same dimensions
    if(i<0 || j<0 || i>=size() || j>=size()) { throw new IllegalArgumentException("Cannot find component "+i+","+j+" of vector["+size()+"] wedge vector["+v.size()+"]"); }
    return get(i).mul(v.get(j)).subeq(get(j).mul(v.get(i)));
  }
  
  
  public Complex distSq(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot find distance between vector["+size()+"] and vector["+v.size()+"]"); } //must have same dimensions
    Complex sum = Cpx.zero();
    for(int n=0;n<size();n++) { sum.addeq(get(n).sub(v.get(n)).sq()); }
    return sum;
  }
  public Complex dist(final CVector v) {
    return distSq(v).sqrt();
  }
  
  public Complex angleBetween(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot find angle between vector["+size()+"] and vector["+v.size()+"]"); }
    double mag1 = lazyMag(), mag2 = v.lazyMag(); //first, to prevent overflow/underflow, compute the lazy magnitudes
    //TODO the rest of the overflow/underflow protection
    Complex cos = dot(v).diveq(magSq().muleq(v.magSq()).sqrt());
    return cos.acos();
  }
  
  
  public double frobeniusMagSq() {
    double sum=0; for(Complex c : this) { sum+=c.absq(); } return sum;
  }
  //double frobeniusMag() { return Math.sqrt(frobeniusMagSq()); }
  public double frobeniusMag() {
    double mag = lazyMag(); //first, for the sake of preventing overflow/underflow, compute the lazy magnitude
    if(mag<=1.055e-154d) { double sum=0; for(Complex c : this) { sum+=c.scalb( 1022).absq(); } return Math.scalb(Math.sqrt(sum),-1022); } //if it underflows, we * by 2^1022, find the magnitude, and / by 2^1022
    if(mag>=9.481e+153d) { double sum=0; for(Complex c : this) { sum+=c.scalb(-1022).absq(); } return Math.scalb(Math.sqrt(sum), 1022); } //if it  overflows, we / by 2^1022, find the magnitude, and * by 2^1022
    
    double sum=0; for(Complex c : this) { sum+=c.absq(); } return Math.sqrt(sum); //default: add the absolute square of each term, find the square root
  }
  
  public Complex frobeniusProduct(final CVector v) {
    if(elements.length!=v.elements.length) { throw new IllegalArgumentException("Cannot perform Frobenius product on vector["+elements.length+"] and vector["+v.elements.length+"]"); }
    Complex sum = Cpx.zero();
    for(int n=0;n<elements.length;n++) { sum.addeq(elements[n].mul(v.elements[n].conj())); }
    return sum;
  }
  
  public CVector frobeniusUnit() {
    double inv = 1d/frobeniusMag();
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(inv); }
    return new CVector(arr);
  }
  
  
  public CVector re() {
    Complex[] arr = new Complex[size()];
    for(int n=0;n<size();n++) { arr[n] = new Complex(elements[n].re); }
    return new CVector(arr);
  }
  
  public CVector im() {
    Complex[] arr = new Complex[size()];
    for(int n=0;n<size();n++) { arr[n] = new Complex(elements[n].im); }
    return new CVector(arr);
  }
  
  public static CVector zero(final int dim) {
    double[] d = new double[dim];
    return new CVector(d);
  }
  
  public static CVector loadFromString(String s) {
    if(!s.startsWith("[") || !s.endsWith("]")) { return null; } //if doesn't start with [ and ], return null
    if(s.equals("[]")) { return new CVector(); } //if it's empty, return an empty vector
    s = s.substring(1,s.length()-1); //remove [ and ]
    String[] split = s.split(","); //split into substrings separated by commas
    Complex[] elem = new Complex[split.length]; //initialize complex array
    for(int n=0;n<split.length;n++) { elem[n] = Cpx.complex(split[n]); } //cast each substring to a complex
    return new CVector(elem); //return resulting vector
  }
}


public static class Cpx3 extends Cpx2 {
  public static Complex polygamma2(int m, Complex z) {
    if(m==-2) { return kFunction(z,false).addeq(mul(sub(Math.log(2*Math.PI)+1,z),z,0.5f)); }
    return polygamma(m,z);
  }
  
  public static Complex kFunction(Complex a, boolean expo) { //K-Function
    
    if(a.equals(0)) { return one(); } //special case a==0: return 1
    
    Complex z=a.re>=0 ? a.add(5) : sub(6,a); //either perform the K-Function 5 steps ahead & work backwards, or do the same thing for 1-a & use a reflection formula
    
    Complex expon=mul(z,z.sub(1),0.5f).addeq(1.0d/12).muleq(ln(z)).subeq(sq(z.mul(0.5f))); //initialize our exponent
    
    Complex iter=sq(z.inv()); //this is what the term will multiply by each time
    Complex term=iter.copy(); //this'll store z^(-2k+2)
    
    for(int k=2;k<8;k++) {
      expon.subeq(term.mul(Bernoulli[k<<1]/(4*k*(2*k-1)*(k-1)))); //add each term
      term.muleq(iter); //multiply by the iterator
    }
    
    for(int n=1;n<=5;n++) { //loop through the five numbers right before z, and subtract said numbers times their natural log
      expon.subeq(ln(z.sub(n)).muleq(z.sub(n)));
    }
    
    if(a.re<0) { //if a is less than 0, apply the (very intricate) reflection formula
      expon.addeq(Cl2(a.mul(2*Math.PI)).div(2*Math.PI)); //for starters, the exponent has to add a scaled version of the clausen function

      Complex reflector=a.mul(sub(1,a));        //this is our reflector.  It will either be added or subtracted from our answer, depending on the imaginary part
      Complex b=a.sub(Math.ceil(a.re));         //I'll be honest, I don't fully understand how this reflection works, I mostly just used trial and error on a very exception-heavy problem
      reflector.addeq(b.mul(b.add(1)));
      reflector.muleqI(HALFPI);
      if(a.im<0) { expon.addeq(reflector); } //if the imaginary part is negative, add the reflector
      else       { expon.subeq(reflector); } //if it's positive or 0, subtract the reflector
    }
    
    expon.re+=0.2487544770337843d; //add the log of the Glaisher-Kinkelin constant
    
    return expo ? exp(expon) : expon; //return the natural exponent of our result (unless we want the log-K function)
  }
  
  public static Complex barnesG(Complex z) { //returns the Barnes G-Function of z
    if(z.isInt() && z.re<=0) { return zero(); }                       //special case z is non-positive integer: return 0
    Complex ans = exp(sub(z,1).muleq(loggamma(z))).diveq(kFunction(z,true)); //G(z)=Γ(z)^(z-1)/K(z)
    if(z.im==0) { ans.im=0; }
    return ans;
  }
  
  ////////////////////////////// ZETA FUNCTIONS ///////////////////////////
  
  public static Complex zeta(Complex s) {
    if(Math.abs(s.im)>30 && s.re>-4 && s.re<5) { return zeta2(s); }
    else                                       { return zeta1(s); }
  }
  
  private static Complex zeta1(Complex s) {
    
    if(s.re<0.5f) {
      if(Math.abs(s.im)>300) { return exp(s.sub(1).mul(Math.log(2*Math.PI)).add(s.mulI().abs2().mul(HALFPI)).add(loggamma(sub(1,s)))).mul(zeta1(sub(1,s))).mulI(csgn(s.im)); }
      return mul(pow(complex(2*Math.PI),s),sin(s.mul(HALFPI)),gamma(sub(1,s))) .mul(zeta1(sub(1,s))).div(Math.PI);
    }
    
    double[] coef={1.0d, -1.0d, 1.0d, -1.0d, 1.0d, -0.9999999999999956d, 0.9999999999997994d, -0.9999999999938609d, 0.9999999998649105d, -0.9999999977694676d,
            0.9999999714737119d, -0.9999997104537386d, 0.9999976222939507d, -0.9999839584657739d, 0.999909963580878d, -0.9995752248158726d, 0.998300908965645d, -0.9941953510449523d, 0.9829544651872266d, -0.9567257315192d,
            0.9044921225074828d, -0.8156949871875634d, 0.6869855506262866d, -0.5283436869577361d, 0.36280435095577035d, -0.21751716776255578d, 0.11124997091266166d, -0.04729731398489733d, 0.016192457785229986d, -0.004275662228214578d,
            8.152497252699953e-4d, -9.970680093230158e-5d, 5.86510593719421e-6d};
    
    Complex sum=zero();
    for(int n=1;n<=coef.length;n++) {
      sum.addeq(mul(pow(new Complex(n),s.neg()),coef[n-1]));
    }
    
    return div(sum,sub(1,pow(complex(2),sub(1,s))));
  }
  
  private static Complex zeta2(Complex s) {
    Complex t=sub(0.5f,s).muleqI();
    int m=(int)Math.floor(sqrt(t.mul(csgn(s.im)/(2*Math.PI))).re);
    
    Complex theta=rsTheta(s.sub(0.5f).diveqI()); //compute the Riemann-Siegel Theta Function
    
    Complex sum=(m==0?zero():cos(theta));
    for(int k=2;k<=m;k++) {
      sum.addeq( cos(theta.sub(t.mul(Math.log(k)))).diveq(Math.sqrt(k)) );
    }
    sum.muleq(2);
    
    Complex sum2=zero();
    Complex term=one();
    Complex iter=sqrt(div(2*Math.PI*csgn(s.im),t));
    Complex inp=iter.inv().subeq(m).muleq(2).subeq(1);
    
    double[] coef={0.5d,0.5d,1.2337005501361697d,1.2337005501361697d,0.41576387242884216d,-17.571264781494055d,-89.76409950303267d,-348.55262483408745d,-764.3879449480118d,1784.5561668662722d,29190.148401564962d,202565.10667286662d,814080.3882205525d,
            974030.8878581069d,-1.957849534898767e7d,-2.2459951712568212e8d,-1.390261988148928e9d,-4.633697498894301e9d,1.6887987043774656e10d,4.036267034527721e11d,3.580901293164045e12d,1.8567163359058586e13d,6.489660305505916e12d,
            -1.0340517738538868e15d,-1.3024983661929054e16d,-9.2205787899349568e16d,-2.57539235105429344e17d,3.3255537896359675e18d,6.3351064269818356e19d,5.831853872469764e20d,2.7815735241170354e21d,-1.064709072231034e22d};
    Complex[] deriv=new Complex[19];
    Complex termd=one(), iterd=inp.abs2().sub(0.5f);
    //if(testmessage) { println(iterd); }
    for(int n=0;n<19;n++) if(n!=13 && n!=16 && n!=17) { deriv[n]=zero(); }
    for(int n2=0;n2<coef.length;n2++) {
      for(int n=0;n<19;n++) if(n!=13 && n!=16 && n!=17 && n<coef.length-n2) {
        deriv[n].addeq(termd.mul(coef[n2+n]));
      }
      termd.muleq(iterd.div(n2+1));
    }
    if(!inp.isRoot()) { for(int n=1;n<17;n+=2) if(n!=13) { deriv[n].negeq(); } }
    
    
    Complex[] out={deriv[0], deriv[3].div(-12*Math.PI*Math.PI), deriv[2].div(16*Math.PI*Math.PI).add(deriv[6].div(288*pow(Math.PI,4))), deriv[1].div(-32*Math.PI*Math.PI).sub(deriv[5].div(120*pow(Math.PI,4))).sub(deriv[9].div(10368*pow(Math.PI,6)))
            ,deriv[0].mul(143/(18432*Math.PI*Math.PI)).add(deriv[4].mul(19/(1536*pow(Math.PI,4)))).add(deriv[8].mul(11/(23040*pow(Math.PI,6)))).add(deriv[12].div(497664*pow(Math.PI,8)))
            ,deriv[3].mul(-2879/(221184*pow(Math.PI,4))).sub(deriv[7].mul(901/(645120*pow(Math.PI,6)))).sub(deriv[11].mul(7/(414720*pow(Math.PI,8)))).sub(deriv[15].div(29859840*pow(Math.PI,10)))
            ,deriv[2].mul(2879/(294912*pow(Math.PI,4))).add(deriv[5].mul(79267/(26542080*pow(Math.PI,6)))).add(deriv[10].mul(18889/(232243200*pow(Math.PI,8)))).add(deriv[14].mul(17/(39813120*pow(Math.PI,10)))).add(deriv[18].div(2149908480L*pow(Math.PI,12)))
    };
    
    for(int n=0;n<out.length;n++) {
      sum2.addeq(term.mul(out[n]));
      term.muleq(iter);
    }
    sum2.muleq(sqrt(iter));
    
    if((m&1)==0) { sum.subeq(sum2); }
    else         { sum.addeq(sum2); }
    
    sum.muleq(exp(theta.divI()));
    
    return sum;
  }
  
  public static Complex rsTheta(Complex t) { //returns the Riemann-Siegel Theta function
    
    Complex s=t.mulI().addeq(0.5f);
    
    Complex theta=sub(Math.log(Math.PI),s.mul(Math.log(2*Math.PI)).add(loggamma(sub(1,s))));
    if(Math.abs(s.im)>400) { theta.subeq(s.mulI(HALFPI).abs2().subeq(new Complex(LOG2,-HALFPI*csgn(s.im))));                                    }
    else                   { theta.subeq(ln(sin(s.mul(HALFPI)))).subeq(iTimes(2*Math.PI*csgn(s.re*s.im)*Math.round(0.25f*csgn(s.re)*(1-s.re)))); }
    theta.muleqI(-0.5f);
    if(t.im==0) { theta.im=0; }
    
    return theta;
  }
  
  public static Complex rsZFunction(Complex t) { //returns the Riemann-Siegel Z Function
    
    Complex s=t.mulI().addeq(0.5f);
    Complex res=zeta(s).muleq(exp(rsTheta(t).muleqI())); //compute the result
    if(t.im==0) { res.im=0; }
    return res;
  }
  
  ///////////////////////////// POLYLOGARITHMS ////////////////////////////
  
  public static Complex Li2(Complex z) { return polylog(2,z); } //dilogarithm of complex input z
  
  public static Complex Cl2(Complex z) { //returns the clausen function of complex z
    if(z.im==0) { return new Complex(Li2(exp(iTimes(z.re))).im); } //if a is real, return the imaginary part of Li2(e^(ai))
    return Li2(exp(z.mulI())).sub(Li2(exp(z.divI()))).mulI(-0.5d); //otherwise, return (Li2(e^(ai))-Li2(e^(-ai)))/(2i)
  }
  
  private static Complex powPolylog(int s, Complex z, int iters) { //computes the polylogarithm via a power series
    if(absq(z)>1) {
      Complex reflector=bernPoly(s,ln(z.neg()).muleqI(-1.0d/(2*Math.PI)).addeq(0.5f)).muleq(pow(iTimes(2*Math.PI),s).negeq());
      if(z.im==0 && z.re>0 && z.re<1) {
        reflector.addeq(pow(ln(z),s-1).muleqI(2*Math.PI*s));
      }
      double fact=1.0d;
      for(long k=1;k<=s;k++) { fact*=k; }
      reflector.diveq(fact);
      if((s&1)==0) { return reflector.subeq(powPolylog(s,z.inv(),iters)); }
      else         { return reflector.addeq(powPolylog(s,z.inv(),iters)); }
    }
    
    Complex sum=zero(), expo=z.copy();
    for(int n=1;n<=iters;n++) {
      sum.addeq(expo.div(pow(n,s)));
      expo.muleq(z);
    }
    
    return sum;
  }
  
  private static Complex logPolylog(int s, Complex lnz, int iters) { //computes polylogarithm via a power series of the natural logarithm (plus an ln(-ln(z)) term)
    double[] zetaPos={-0.5d,INF,1.64493406684822644d,1.20205690315959429d,1.08232323371113819d,1.03692775514336993d,1.01734306198444914d,1.00834927738192283d,1.00407735619794434d,
            1.00200839282608221d,1.00099457512781808d,1.00049418860411946d,1.00024608655330804d,1.00012271334757848d,1.00006124813505870d,1.00003058823630702d,1.00001528225940865d};
    double[] zetaNeg={-0.5d,-1.0d/12,0,1.0d/120,0,-1.0d/252,0,1.0d/240,0,-1.0d/132,0,691.0d/32760,0,-1.0d/12,0,3617.0d/8160,0,-43867.0d/14364,0,174611.0d/6600,0,-77683.0d/276,0,
            236364091.0d/65520,0,-657931.0d/12,0,3392780147.0d/3480,0,-1723168255201.0d/85932,0,7709321041217.0d/16320,0,-151628697551.0d/12,0,26315271553053477373.0d/6909840,
            0,-154210205991661.0d/12};
    //create arrays to store precomputed values for the zeta function at particular points
    
    Complex sum=zero(), expo=one(), iter=lnz.copy(); //init sum, exponent, and iterator
    
    for(int n=0;n<s-1;n++) { //compute Σ[n=0,s-2] ζ(s-n)ln(z)^n/n!
      if(s-n>16) {
        double zetaapprox=1;
        for(int k=2;k<=10;k++) { zetaapprox+=pow(k,-s); }
        sum.addeq(expo.mul(zetaapprox));
      }
      else { sum.addeq(expo.mul(zetaPos[s-n])); }
      expo.muleq(iter).diveq(n+1);
    }
    
    if(!iter.equals(0)) { //this term can only be added if lnz!=0 (otherwise, we get lim(x→0) xln(x) = 0)
      double Harmon=0.0d;
      for(int n=1;n<s;n++) { Harmon+=1.0d/n; }
      sum.addeq(sub(Harmon,ln(iter.neg())).muleq(expo)); //add ln(z)^(s-1)/(s-1)!*(Σ[n=1,s-1]1/n - ln(-ln(z)))
    }
    expo.muleq(iter).diveq(s); //exponent := ln(z)^s/s!
    
    sum.subeq(expo.mul(0.5d));   //subtract exponent/2
    expo.muleq(iter).diveq(s+1); //exponent := ln(z)^(s+1)/(s+1)!
    iter.muleq(iter);            //square the iterator
    
    for(int n=0;n<=iters-s;n++) { //add Σ[n=0,iters-s → ∞] ζ(2n+1)*ln(z)^(s+2n+1)/(s+2n+1)!
      sum.addeq(expo.mul(zetaNeg[2*n+1]));
      expo.muleq(iter).diveq((2*n+s+2)*(2*n+s+3));
    }
    
    return sum; //return summation
  }
  
  public static Complex polylog(int s, Complex z) { //computes the s-th polylogarithm of complex z
    
    if(s<2) { //if s<2, then we can compute the polylogarithm through explicit means
      if(s==1) { return ln(sub(1,z)).negeq(); } //Li1(z) = -ln(1-z)
      if(s==0) { return z.div(sub(1,z));      } //Li0(z) = z/(1-z)
      if(s<0) {                                 //for negative s, we take a power series, where each coefficient is found through a sum. (both sums are finite)
        Complex iter=z.div(sq(sub(1,z))); //iterator
        Complex expo=iter.copy();         //exponent = iter ^ k
        Complex sum=zero();               //sum
        double term_init=1;               //equals (-1)^(k-1) * (2k choose k+1) each iteration
        for(int k=1;k<=(1-s)>>1;k++) {    //perform power series
          double coef=0;                  //init coefficient to 0
          double term=term_init;          //term equals (-1)^(j-k) times (2k choose j+k)
          for(int j=1;j<=k;j++) {         //coef=Σ[j=1,k] (-1)^(j-k) * (2k choose j+k) * j^(2ceil(-s/2))
            coef+=term*pow(j,(~s&~1)+2);
            term*=(j-k)/(double)(j+k);
          }
          if((s&1)==1) { coef/=k; }                      //if s odd, divide by k
          sum.addeq(expo.mul(coef));                     //add coef * exponent
          expo.muleq(iter);                              //exponent mults by iterator
          term_init*=-(2*k+1)*(2*k+2)/(double)(k*(k+2));
        }
        if((s&1)==0) { sum.muleq(div(add(1,z),sub(1,z))); } //multiply by this thing if s is even
        return sum;                                         //return sum
      }
    }
    //approximate polylogarithm through a combination of the power series, log series, duplication formula, & reflection formula
    
    Complex u=ln(z), v=u.div(2*Math.PI);                      //u=ln(z), v=ln(z)/(2π)
    Complex lnneg=v.add(iTimes(0.5f*csgn(-v.im)));             //ln(-z)/(2π)
    Complex lnsq=v.mul(2).addeq(iTimes(Math.round(-2*v.im))); //ln(z²)/(2π)
    
    //"CONVergence", each # is proportional to the approx convergence time of each alg. If an alg never converges, the denom becomes negative, so
    //we use this max(0,#) trick to turn any negative denom to 0, to represent ∞ convergence time
    double[] conv={2.0d/Math.abs(u.re), 1.0d/Math.max(0,-ln(v).re), 1.0d/Math.max(0,-ln(lnsq).re), 1.0d/Math.max(0,-ln(lnneg).re)};
    
    conv[2]+=conv[3];     //we could initialize them all at once, but it's slightly faster this way
    conv[3]+=0.5f*conv[0];
    
    double mins=INF; //minimum convergence rate
    int best=-1;     //index of the best convergence rate
    
    for(int n=0;n<4;n++) if(conv[n]<mins) { mins=conv[n]; best=n; } //sequential search for minimum
    
    Complex ans;
    
    switch(best) {
      case 0 : ans = powPolylog(s,z,20); break;                      //alg 0: power series (combined w/ refl. formula for |z|>1)
      case 1 : ans = logPolylog(s,u,20); break;                      //alg 1: power series of ln(z) (plus an ln(-ln(z)) term)
      case 2 : ans = logPolylog(s,lnsq.mul(2*Math.PI),14).muleq(pow(2,1-s)).subeq(logPolylog(s,lnneg.mul(2*Math.PI),14)); break; //duplication formula w/ 2 log series
      default: ans = powPolylog(s,sq(z)              ,15).muleq(pow(2,1-s)).subeq(logPolylog(s,lnneg.mul(2*Math.PI),15)); break; //duplication formula w/ 1 power & 1 log series
    }
    
    if(z.im==0 && z.re<=1) { ans.im=0; }
    return ans;
  }
  
  public static Complex bernPoly(int n, Complex z) { //computes the nth Bernoulli polynomial for Complex z
    if(n==0) { return one(); } //special case, n=0: return 1
    Complex sum=zero(), expo=((n&1)==0)?one():z.mul(n), iter=sq(z);
    for(int k=n&1;k<n-1;k++) {
      sum.addeq(expo.mul(Bernoulli[n-k]));
      expo.muleq(z).muleq(((double)(n-k))/(k+1));
    }
    sum.addeq(expo.mul(z.div(n).sub(0.5d)));
    return sum;
  }
  
  ///////////////////////////// EXPONENTIAL INTEGRALS ///////////////////////////
  
  public static Complex ein(Complex a) { //takes the (adjusted) Exponential integral of complex input a
    if((a.re-0.179d)*(a.re-0.179d)/598.487d+a.im*a.im/194.017d <= 1.0d) {
      Complex sum=zero();        //this is used to store a long summation
      Complex term=a.copy();     //this is used to store each term in the series
      Complex iter=a.mul(-0.5d); //this is what term will multiply by each time
      double sum2=1.0d;          //this will be used to store a sum within the sum
      
      for(int n=1;n<=40;n++) {
        sum.addeq(term.mul(sum2)); //add each term
        
        term.muleq(iter.div(n+1));         //multiply the term by the iterator
        if((n&1)==0) { sum2+=1.0d/(n+1); } //only if n is even, add 1/(n+1) to the nested sum
      }
      
      sum.muleq(exp(a.mul(0.5f)));          //multiply the sum by e^(a/2)
      return sum.add(GAMMA); //return the sum plus the mascheroni constant
    }
    
    else {
      double[][] coef={{1,-7.44437068161936701e2d, 1.96396372895146870e5d,-2.37750310125431834e7d, 1.43073403821274637e9d,-4.33736238870432523e10d, 6.40533830574022023e11d,-4.20968180571076940e12d, 1.00795182980368575e13d,-4.94816688199951963e12d, -4.94701168645415960e11d},
              {1,-7.46437068161927678e2d, 1.97865247031583951e5d,-2.41535670165126845e7d, 1.47478952192985465e9d,-4.58595115847765780e10d, 7.08501308149515402e11d,-5.06084464593475077e12d, 1.43468549171581016e13d,-1.11535493509914254e13d},
              {1,-8.13595201151686150e2d, 2.35239181626478200e5d,-3.12557570795778731e7d, 2.06297595146763354e9d,-6.83052205423625007e10d, 1.09049528450362786e12d,-7.57664583257834349e12d, 1.81004487464664575e13d,-6.43291613143049485e12d, -1.36517137670871689e12d},
              {1,-8.19595201151451564e2d, 2.40036752835578778e5d,-3.26026661647090822e7d, 2.23355543278099360e9d,-7.87465017341829930e10d, 1.39866710696414565e12d,-1.17164723371736605e13d, 4.01839087307656620e13d,-3.99653257887490811e13d}};
      
      Complex[] numden={zero(), zero(), zero(), zero()}; //these will give us the numerators and denominators of the f and g auxiliary functions
      
      Complex term, iter=sq(a.inv()); //term and iterator
      
      for(int m=0;m<4;m++) { //loop through all 4 entries in the numden array
        term=one();          //initialize term to 1
        for(double c: coef[m]) {        //loop through the coefficients
          numden[m].addeq(term.mul(c)); //add each term times the coefficient
          term.muleq(iter);             //multiply the term by the iterator
        }
      }
      
      Complex auxf=numden[0].div(numden[1].mul(a)), auxg=numden[2].div(numden[3]).mul(iter); //compute the auxiliary f and g functions
      
      Complex ret=add(auxf,auxg).mul(exp(a)); //this is what we will return
      if(a.im>0 || a.im==0 && a.re<0) { ret.im+=Math.PI; }
      else if(a.im<0)                 { ret.im-=Math.PI; }
      ret.subeq(ln(a)); //subtract the natural logarithm
      
      return ret; //return the result
    }
  }
  
  public static Complex trigInt(Complex a, boolean CorS) { //this takes either the Ci or Si of complex a
    Complex sample=ein(a.mulI()); //first, calculate the regularized Exponential integral of a*i
    
    if(a.im==0) { //if a is real:
      return new Complex(CorS ? sample.re : sample.im); //either return the real or imaginary part of the Ein, depending on if it's the Ci or Si function
    }
    
    if(CorS) { return sample.add(ein(a.divI())).mul(0.5f); } //Ci(x)=(Ein(xi)+Ein(-xi))/2
    return sample.sub(ein(a.divI())).mulI(-0.5d);           //Si(x)=(Ein(xi)-Ein(-xi))/(2i)
  }
  
  public static Complex auxInt(Complex a, boolean fOrg) { //this takes the auxiliary f or g function of  complex a
    if(fOrg) { return sub(HALFPI,trigInt(a,false)).mul(cos(a)).add(add(trigInt(a,true),ln(a),GAMMA).mul(sin(a))); }
    else     { return sub(HALFPI,trigInt(a,false)).mul(sin(a)).sub(add(trigInt(a,true),ln(a),GAMMA).mul(cos(a))); }
  }
  
  ///////////////////////////// ELLIPTIC INTEGRALS //////////////////////////////
  
  private static Complex[] AGM_method(Complex k, int type) { //this computes the AGM between k and 1.  If the type is 2, it also computes the derivative of the AGM
    if(k.equals(0)) { return new Complex[] {zero(),complex(-INF)}; } //special case: k==0, return 0 & -∞
    if(k.equals(1)) { return new Complex[] {one (),complex(0.5f) }; } //special case: k==1, return 0 & 1/2
    
    Complex a=one(), b=k.copy(), c=zero(), d=one(); //initialize a, b, c, & d to 1, k, 0, 1
    Complex b2, d2;                                 //declare b2 and d2 to store copies of b & d
    
    for(short n=0;n<8;n++) {  //loop through several iterations of the process below
      b2=b.copy();            //copy b
      b=sqrt(mul(a,b));       //set b=geometric mean
      if(type==2) {           //do this step only if type is 2
        d2=d.copy();          //copy d
        d=add(mul(b2,c),mul(a,d)).div(b.mul(2)); //set d = derivative of b
        c=add(c,d2).mul(0.5f); //set c = derivative of a
      }
      a=add(a,b2).mul(0.5f);   //set a = arithmeic mean
    }
    
    if(absq(a.sub(b))>=1e-10f)            { println("AGM Error: " +str(a)+"!="+str(b)); } //if a!=b,
    if(type==2 && absq(c.sub(d))>=1e-10f) { println("AGM' Error: "+str(c)+"!="+str(d)); } //or c!=d, it's an error as the series didn't converge fast enough
    
    return new Complex[] {a,c.mul(k)}; //return an array containing the AGM and its derivative (times k)
  }
  
  public static Complex completeF(Complex k) { //returns the complete elliptic integral of the first kind for complex k
    if(k.equals(0)) { return complex(HALFPI); } //special case: if k==0, return π/2
    if(k.equals(1)) { return complex(INF);    } //special case: if k==1, return ∞
    
    return div(HALFPI,AGM_method(sqrt(sub(1,k)),1)[0]); //return π/(2*AGM)
  }
  
  public static Complex completeE(Complex k) { //returns the complete elliptic integral of the second kind for complex k
    if(k.equals(0)) { return complex(HALFPI); } //special case: k==0, return π/2
    if(k.equals(1)) { return one();           } //special case: k==1, return 1
    
    Complex[] AGM=AGM_method(sqrt(sub(1,k)),2); //find the AGM & AGM'
    
    return k.mul(AGM[1]).div(AGM[0]).add(sub(1,k)).div(AGM[0]).mul(HALFPI); //return π/(2*AGM) * (k√(1-k)*(AGM'/AGM)+1-k)
  }
  
  public static Complex completePI(Complex n, Complex k) { //returns the complete elliptic integral of the third kind for complex k and n
    if(k.equals(0)) { return div(HALFPI,sqrt(sub(1,n)));      } //special case: k==0, return π/(2√(1-n))
    if(n.equals(0)) { return completeF(k);                    } //special case: n==0, return F(k)
    if(k.equals(1) || n.equals(1)) { return new Complex(INF); } //special case: k==1 or n==1, return ∞
    
    Complex[] storage=carlson(zero(),sub(1,k),one(),sub(1,n),3); //compute the carlson symmetric R_F and R_J
    
    Complex ans=storage[0].add(mul(storage[1],n.div(3))); //compute R_F+n/3*R_J
    
    return ans; //return the result
  }
  
  private static Complex[] carlson(Complex x, Complex y, Complex z, Complex p, int type) { //this returns the carlson symmetric R_F of x,y,z (and possibly RJ of x,y,z,p if type is 2 or 3)
    Complex mu=add(x,y.add(z)).div(3); //this is the mean between the x, y, and z
    
    double delta=10000*Math.max(Math.max(absq(x.sub(mu)), absq(y.sub(mu))), absq(z.sub(mu))); //this is how far the inputs are from the mean
    
    if(type==3) { delta=Math.max(delta, 10000*absq(p.sub(mu))); }                            //if the type is 3, we need to include p in our results
    
    Complex part=zero(); //this is the sum of all the stuff we add on to the R_D function (even if it's only for type 2 or 3, it still must be declared in this scope)
    double pow4=1.0d;    //this will divide by 4 each iteration, and will be multiplied by a sum we'll perform at the end to find R_D
    
    while(delta > absq(mu)) { //while all terms are far apart, use the following duplication formula,
      Complex s1=sqrt(x), s2=sqrt(y), s3=sqrt(z);        //compute the √ of x, y, and z
      Complex lambda=s1.mul(add(s2,s3)).add(mul(s2,s3)); //compute lambda in our duplication formula
      
      delta*=0.0625d; //divide our square difference by 16
      
      if(type==2||type==3) { //if the type is either 2 or 3, there's an extra step to this
        if(type==2) {
          part.addeq(div(3*pow4, mul(s3,add(s1,s3),add(s2,s3)) )); //type 2: add on a special case of type 3 where p==z
        }
        else        {         //type 3: unlike type 2, this isn't a special case, and we have to give p some special treatment since it isn't z
          Complex s4=sqrt(p); //find the square root of p
          Complex sto=sqrt(mul(sub(p,x),sub(p,y),sub(p,z))); //store this thing to save on multiplications
          part.addeq(atan( sto.div(mul(add(s1,s4),add(s2,s4),add(s3,s4))) ).mul(6*pow4).div(sto)); //add this big ass equation
          p=add(p,lambda).div(4); //perform the "duplication" on p as well
        }
        pow4*=0.25d; //pow4 must divide by 4
      }
      
      x =add(x ,lambda).muleq(0.25f);  //set x, y, z, and mu to themselves plus lambda all over 4
      y =add(y ,lambda).muleq(0.25f);  //for some reason, this is called a "duplication formula"
      z =add(z ,lambda).muleq(0.25f);
      mu=add(mu,lambda).muleq(0.25f);
    }
    
    //now we compute the R_F function
    
    Complex z1=x.div(mu).sub(1), z2=y.div(mu).sub(1), z3=z.div(mu).sub(1); //these are the ratio between how far x y & z are from mu and mu itself
    Complex E2=z1.mul(add(z2,z3)).add(mul(z2,z3)), E3=mul(z1,z2,z3);       //E2 & E3 are the sum of all 2nd & 3rd degree products with x,y,z
    
    Complex sum=sub(1,E2.div(10)).sub(E3.div(14)).add(sq(E2).div(24)).add(mul(E2,E3,3.0d/44)).add(sq(E3).mul(3.0d/104)).sub(cub(E2).mul(5.0d/208)).sub(mul(sq(E2),E3,0.0625d)); //approximation
    //1-E2/10+E3/14+E2^2/24+3E2E3/44+3E3^2/104-5E2^3/208-E2^2E3/16
    
    sum.diveq(sqrt(mu)); //divide the sum by the square root of mu, and we now have R_F
    
    if(type==1) { return new Complex[] {sum}; } //if the type is 1, return only the R_F function
    if(type==2) { p=z.copy();                 } //if the type is 2, set p equal to z
    
    //note now the type can only be 2 or 3
    
    //now we compute the R_J function
    
    mu=add(add(x,y),add(z,p.mul(2))).div(5); //change the mu value
    
    z1=x.div(mu).sub(1); z2=y.div(mu).sub(1); z3=z.div(mu).sub(1); //change the z values
    Complex z4=p.div(mu).sub(1);                                   //create a new z value
    
    E2=z1.mul(add(z2,z3)).add(mul(z2,z3)).sub(sq(z4).mul(3));
    E3=z4.mul(z1.mul(add(z2,z3)).add(mul(z2,z3)).sub(sq(z4))).mul(2).add(z1.mul(mul(z2,z3)));
    Complex E4=z4.mul(z1.mul(add(z2,z3)).add(mul(z2,z3))).add(mul(mul(z1,z2),mul(z3,2))).mul(z4);
    Complex E5=mul(mul(z1,z2),mul(z3,sq(z4)));
    
    Complex sum2=sub(1,E2.mul(3.0d/14)).sub(E3.div(6)).sub(E4.mul(3.0d/22)).sub(E5.mul(3.0d/26)).add(sq(E3).mul(9.0d/88)).add(mul(E2,E3,9.0d/52)).add(mul(E2,E4,0.15d)).add(mul(E2,E5,9.0d/68)).add(sq(E3).mul(0.075d)).add(mul(E3,E4,9.0d/68)).sub(cub(E2).div(16)).sub(mul(sq(E2),E3,45.0d/272));
    //1-3E2/14-E3/6-3E4/22-3E5/26+9E3^2/88+9E2E3/52+3E2E4/20+9E2E5/68-E2^3/16-45E2^2E3/272
    
    sum2.muleq(pow4);             //divide the sum by 4^(whatever)
    sum2.diveq(mul(mu,sqrt(mu))); //divide by mu^(3/2)
    sum2.addeq(part);             //add the additional part
    
    return new Complex[] {sum,sum2}; //return the result
  }
  
  public static Complex incompleteF(Complex theta, Complex k) {   //returns the incomplete elliptic F function of complex numbers theta and k
    
    if(k.equals(0)) { return theta.copy(); } //k==0: the integral evaluates to theta
    if(k.equals(1)) {                        //k==1: the integral simplifies, but isn't always defined
      if(theta.re>= HALFPI) { return complex( INF); } //theta>=π/2: return ∞
      if(theta.re<=-HALFPI) { return complex(-INF); } //theta<=-π/2: return -∞
      return ln(add(tan(theta),sec(theta)));          //otherwise, return ln(sec(theta)+tan(theta))
    }
    if(Math.abs(theta.im)>100) {                               //theta has large imaginary part: approximate the integral with two complete elliptic integrals
      double adjust=Math.round((theta.re-0.5f*arg(k))/Math.PI); //find how many times π goes into theta
      Complex ans=(theta.im>0) ? completeF(sub(1,k)).mulI() : completeF(sub(1,k)).divI(); //set our answer to ±K(1-k)i
      if(adjust!=0) { ans.addeq(completeF(k).mul(2*adjust)); } //if π goes into theta, add on K(k) times 2*adjust
      return ans;                                              //return the result
    }
    
    double adjust=Math.round(theta.re/Math.PI); //find how many times π goes into theta
    Complex inp=theta.sub(Math.PI*adjust);      //our input is theta minus π times our adjustment
    
    if(inp.equals(0))       { return completeF(k).mul(2*adjust);   } //if the modulo is 0 or -π/2, we can finish the calculation with completeF
    if(inp.equals(-HALFPI)) { return completeF(k).mul(2*adjust-1); }
    
    Complex sum=carlson(sq(cos(inp)),sub(1,sq(sin(inp)).mul(k)),one(),zero(),1)[0]; //compute the RF of cos²,1-ksin²,1
    
    sum.muleq(sin(inp)); //multiply by the sine
    
    if(adjust!=0) { sum.addeq(completeF(k).mul(2*adjust)); } //add F(k) times how many times π goes into theta
    
    return sum; //return the result
  }
  
  public static Complex incompleteE(Complex theta, Complex k) { //returns the incomplete elliptic E function of complex theta and k
    
    if(k.equals(0)) { return theta.copy(); } //k==0: just return theta
    if(k.equals(1)) {                        //k==1: return the integral of |cos(x)|dx
      return sin(theta).mul(Math.IEEEremainder(theta.re/Math.PI+0.5f,2)>0 ? 1 : -1).sub(2*Math.round(-theta.re/Math.PI));
    }
    if(Math.abs(theta.im)>100) {                               //theta has large imaginary part: approximate with exponents
      Complex ans=mul(exp(theta.im>0 ? theta.divI() : theta.mulI()),sqrt(k),0.5f); //take √(k)e^(theta/±i)/2
      ans=(theta.im>0 == ans.isRoot()) ? ans.mulI() : ans.divI();                 //mult/div by i, depending on csgn, and on sgn of imag part
      //Most of the equation is solved. This always evaluates to something huge, thus the rest of the approximation is insignificant...
      
      if(ans.re==0 || ans.im==0) { //...unless either the re or im is 0
        Complex term=sub(completeF(sub(1,k)),completeE(sub(1,k))); //compute F(1-k)-E(1-k)
        term=theta.im>0 ? term.mulI() : term.divI();               //multiply by ±i
        
        double adjust=Math.round((theta.re-0.5f*arg(k))/Math.PI);  //find how many E(k)'s to tack on
        if(adjust!=0) { term.addeq(completeE(k).mul(2*adjust)); } //if it goes in at all, tack on those E(k)'s
        
        ans.addeq(term); //add this term to our integral
      }
      
      return ans; //return the result
    }
    
    double adjust=Math.round(theta.re/Math.PI); //find how many times π goes into theta
    Complex inp=theta.sub(Math.PI*adjust);      //our input is theta minus π times our adjustment
    
    if(inp.equals(0))       { return completeE(k).mul(2*adjust);   } //if the modulo is 0 or -π/2, we can finish the calculation with completeE
    if(inp.equals(-HALFPI)) { return completeE(k).mul(2*adjust-1); }
    
    Complex sins=sin(inp); //compute the sine
    
    Complex[] storage=carlson(sq(cos(inp)),sub(1,mul(sq(sins),k)),one(),zero(),2); //find R_F and R_J
    
    Complex sum=storage[0], sum2=storage[1]; //store these forms as two variables
    
    sum2.muleq(sq(sins).mul(k.div(3)));
    
    sum.subeq(sum2);                       //subtract the other sum
    sum.muleq(sins);                       //multiply entire sum by sin(theta)
    if(adjust!=0) {
      sum.addeq(completeE(k).mul(2*adjust)); //add the complete elliptic E times how many times π goes into theta
    }
    
    return sum; //return the result
  }
  
  //////////////////////////// BESSEL /////////////////////////////
  
  public static Complex besselJ(Complex a, Complex z) { //the Bessel J function
    if(0.00585385632d*z.re*z.re + 0.00242167992d*z.im*z.im < 1) {
      return besselJ_taylor(a, z, 32); //if close to 0, return a Taylor's series
    }
    return besselJ_asymp(a, z, 32); //otherwise, return an asymptotic expansion
  }
  
  public static Complex besselY(Complex a, Complex z) { //the Bessel Y function
    if(0.00585385632d*z.re*z.re + 0.00242167992d*z.im*z.im < 1) {
      return besselJY_taylor(a, z, 32)[1]; //if close to 0, return a Taylor's series (kind of)
    }
    return besselY_asymp(a, z, 32); //otherwise, return an asymptotic expansion
  }
  
  public static Complex[] besselJY(Complex a, Complex z) { //both Bessel functions
    if(0.00585385632d*z.re*z.re + 0.00242167992d*z.im*z.im < 1) {
      return besselJY_taylor(a, z, 32); //if close to 0, return their Taylor's series
    }
    return besselJY_asymp(a, z, 32); //otherwise, return their asymptotic expansion
  }
  
  public static Complex besselI(Complex a, Complex z) { //the modified Bessel I function
    return besselJ(a, z.mulI()) .muleq(exp(a.mulI(-HALFPI))); //take J of zi, then divide by i^a
  }
  
  public static Complex besselK(Complex a, Complex z) { //the modified Bessel K function
    if(z.im>=0) { return besselH2(a,z.mulI()).muleq(exp(a.add(1).mulI(-HALFPI))); } //it should be noted that both of these are equivalent for z.re>0
    else        { return besselH1(a,z.mulI()).muleq(exp(a.add(1).mulI( HALFPI))); }
  }
  
  public static Complex besselH1(Complex a, Complex z) { //the Hankel function #1
    Complex[] jy = besselJY(a,z); //compute J and Y
    return jy[0].addeq(jy[1].muleqI()); //return J+Yi
  }
  
  public static Complex besselH2(Complex a, Complex z) { //the Hankel function #2
    Complex[] jy = besselJY(a,z); //compute J and Y
    return jy[0].subeq(jy[1].muleqI()); //return J-Yi
  }
  
  private static Complex besselJ_taylor(Complex a, Complex z, int stop) { //approximates the Bessel J function w/ a Taylor's series
    
    if(a.isInt() && a.re<0) { //special case: a is a negative integer
      return besselJ_taylor(a.neg(),z,stop).muleq(a.re%2==0 ? 1 : -1); //J(a,z) = (-1)^a*J(-a,z)d
    }
    
    Complex sum = zero();               //the sum
    Complex term = (z.mul(0.5f)).pow(a); //each term in the summation
    term.diveq(factorial(a));           //initially just (z/2)^a/a!
    Complex mul = z.mul(0.5f).sq().negeq(); //one of the things the term multiplies by each iteration, -z^2/4
    for(int m=0;m<=stop;m++) { //loop through all terms in the sum
      sum.addeq(term);         //add each term
      term.muleq(mul).diveq(a.add(m+1).mul(m+1)); //update to the next term = (-1)^m(z/2)^(2m+a)/(m!(a+m)!)
    }
    return sum; //return result
  }
  
  private static Complex[] besselJY_taylor(Complex a, Complex z, int stop) { //approximates the Bessel J and Y functions w/ a power series
    if(a.isInt()) { //special case: if a is an integer:
      return besselJY_taylor((int)a.re, z, stop); //use the specialized function for when a is an integer
    }
    
    //otherwise, we compute Y(a,z) as (J(a,z)cos(pi*a)-J(-a,z))/sin(pi*a)
    Complex[] trig = a.mul(Math.PI).fsincos(); //find sin and cos of pi*a
    
    Complex sum1 = zero(), sum2 = zero(); //these store both sums to make both bessel J functions
    Complex term1 = (z.mul(0.5f)).pow(a).diveq(factorial(a));      //each term in each summation, initially just (z/2)^(+-a)/((+-a)!)
    //Complex term2 = (z.mul(0.5)).pow(a.neg()).diveq(factorial(a.neg())); //TODO have this term be solved in terms of the other term
    Complex term2 = trig[0].div(mul(Math.PI,term1,a));            //however, using reflection rules, we can solve for the second one in terms of the first, making this slightly faster
    Complex mul = z.mul(0.5f).sq().negeq(); //one of the things both terms multiply by each iteration, -z^2/4
    for(int m=0;m<=stop;m++) { //loop through all terms in the sum
      sum1.addeq(term1);       //add up each term
      sum2.addeq(term2);
      
      term1.muleq(mul).diveq(add(m+1,a).mul(m+1)); //update to the next term = (-1)^m(z/2)^(2m+-a)/(m!(m+-a)!)
      term2.muleq(mul).diveq(sub(m+1,a).mul(m+1));
    }
    
    //return besselJ_taylor(a,z,stop).mul(trig[1]).subeq(besselJ_taylor(a.neg(),z,stop)).diveq(trig[0]); //do this
    return new Complex[] {sum1, sum1.mul(trig[1]).subeq(sum2).diveq(trig[0])}; //lastly, plug in all the stuff and return J and Y
  }
  
  private static Complex[] besselJY_taylor(int a, Complex z, int stop) {
    if(a<0) {
      Complex[] result = besselJY_taylor(-a,z,stop); //a is negative: negate a,
      if((a&1)==1) { result[0].negeq(); result[1].negeq(); } //multiply by (-1)^a
      return result; //return the result
    }
    
    //to compute the Bessel Y function, we have to compute 3 sums and add/subtract them together
    
    Complex termInit = z.mul(0.5f).pow(a).diveq(factorial(a)); //First, let's compute this. Trust me, it'll save us on powers and, more importantly, gamma functions
    
    //first, we compute the sum of a bunch of terms with negative powers:
    //(well, the powers aren't all negative, these are just powers less than a)
    Complex sum1 = zero();          //the sum itself
    Complex term = termInit.mul(a); //the term
    Complex mul = div(4,z.sq()); //one of the things the term multiplies by each time
    term.muleq(mul);             //initialize the term to (z/2)^(a-2)/(a-1)!
    for(int k=0;k<a;k++) { //loop through all a terms
      sum1.addeq(term);                      //add each term in the series
      term.muleq((k+1)*(a-k-1)).muleq(mul); //update each term, should be (z/2)^(a-2k-2) * k!/(a-k-1)!
    }
    
    //finally, the last 2 sums:
    Complex sum2 = zero(); //a sum of powers >= a
    Complex j    = zero(); //and a sum of powers >= a, multiplied by ln(z/2). This will be the same as 2J(a,z)ln(z/2)
    
    term = termInit;               //the term, initialized to (z/2)^a/a!
    mul = z.mul(0.5f).sq().negeq(); //part of what we multiply by each time, -z^2/4
    double harmonic = -2*GAMMA;    //and, the sum of two harmonic series, each of which get initialized to -gamma because that's just how it works
    for(int k=1;k<=a;k++) { harmonic += 1d/k; } //initialize the harmonic series term
    
    for(int m=0;m<=stop;m++) { //loop through the infinite remaining iterations until we reach the point at which we agreed to stop
      sum2.addeq(term.mul(harmonic));  //each iteration, the sum adds the term times the harmonic sum
      j.addeq(term);                   //meanwhile, the J sum just adds the term bare butt
      
      double inv = 1d/((m+1)*(a+m+1)); //precompute a reciprocal to save on divisions
      term.muleq(mul).muleq(inv);      //each iteration, the term = (-1)^m*(z/2)^(2m+a)/(m!(a+m)!), so we multiply by -(z/2)^2 / ((m+1)(a+m+1)
      harmonic += (a+2*m+2)*inv;       //each iteration, the harmonic sum = digamma(m+1)+digamma(a+m+1), so we add 1/(m+1)+1/(a+m+1) = (a+2m+2)/((m+1)(a+m+1))
    }
    
    Complex y = j.mul(z.mul(0.5f).ln()).muleq(2) .subeq(sum1).subeq(sum2).diveq(Math.PI); //multiply the j term by the 2ln(z/2), then combine the 3 sums and divide by pi
    
    return new Complex[] {j,y}; //return the resulting j and y
  }
  
  private static Complex besselJ_asymp(Complex a, Complex z, int stop) { //approximates the Bessel J function w/ an asymptotic series
    if(z.re<0) { //if the real part is negative:
      //reflection formula: J(a,z) = J(a,-z)*(-1)^+-a, where +-1 is csgn(z/i)
      Complex j = besselJ_asymp(a,z.neg(),stop);             //compute this on -z
      if(a.isInt()) { return a.re%2==0 ? j : j.neg(); }      //if integer, the reflection is simple
      return j.muleq(exp(a.mulI(z.im>=0?Math.PI:-Math.PI))); //otherwise, (-1)^a isn't as simple
    }
    
    Complex inv = z.inv(); //compute 1/z
    Complex[] trig = z.sub(a.mul(0.5f).addeq(0.25f).muleq(Math.PI)).fsincos(); //compute sine and cosine of z-(2a+1)π/4
    Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
    return trig[1].muleq(pq[0]).subeq(trig[0].muleq(pq[1])).muleq(sqrt(inv.div(HALFPI))); //finally, take (cos*P-sin*Q)*√(2/(πz))
  }
  
  private static Complex besselY_asymp(Complex a, Complex z, int stop) { //approximates the Bessel Y function w/ an asymptotic series
    if(z.re<0) { //if the real part is negative:
      //reflection formula: Y(a,z) = Y(a,-z)*(-1)^-+a +- 2i*cos(pi*a)*J(a,-z), where +-1 is csgn(z/i)
      
      Complex inv = z.inv().negeq(); //compute -1/z
      Complex[] trig = z.add(a.mul(0.5f).addeq(0.25f).muleq(Math.PI)).negeq().fsincos(); //compute the sine and cosine of -z-(2a+1)π/4
      Complex[] trig2 = a.mul(Math.PI).fsincos();                                      //also compute the sine and cosine of πa
      Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
      int csgn = z.im>=0 ? 1 : -1;         //compute csgn(z/i)
      
      Complex y = pq[0].mul(trig[0]).addeq(pq[1].mul(trig[1])); //compute Y (ignoring the (pi/2*z)^(-1/2) term)
      Complex j = pq[0].mul(trig[1]).subeq(pq[1].mul(trig[0])); //compute J
      return y.muleq(trig2[1].sub(trig2[0].mulI(csgn))) .addeq(mul(j, new Complex(0,2*csgn),trig2[1])) .muleq(sqrt(inv.div(HALFPI))); //return y*(-1)^(-+a) +- j*2icos (making sure to include the (pi/2*z)^(-1/2) term)
    }
    
    //otherwise, we evaluate it normally
    Complex inv = z.inv(); //compute 1/z
    Complex[] trig = z.sub(a.mul(0.5f).addeq(0.25f).muleq(Math.PI)).fsincos(); //compute sine and cosine of z-(2a+1)π/4
    Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
    return trig[0].muleq(pq[0]).addeq(trig[1].muleq(pq[1])).muleq(sqrt(inv.div(HALFPI))); //finally, take (sin*P+cos*Q)*√(2/(πz))
  }
  
  private static Complex[] besselJY_asymp(Complex a, Complex z, int stop) { //approximates both Bessel functions w/ an asymptotic series
    if(z.re<0) { //if the real part is negative:
      //reflection formula: Y(a,z) = Y(a,-z)*(-1)^-+a +- 2i*cos(pi*a)*J(a,-z), where +-1 is csgn(z/i)
      
      Complex inv = z.inv().negeq(); //compute -1/z
      Complex[] trig = z.add(a.mul(0.5f).addeq(0.25f).muleq(Math.PI)).negeq().fsincos(); //compute the sine and cosine of -z-(2a+1)π/4
      Complex[] trig2;
      if(a.isInt()) { trig2 = new Complex[] {zero(), new Complex(a.re%2==0?1:-1)}; }
      else          { trig2 = a.mul(Math.PI).fsincos();                            }   //also compute the sine and cosine of πa
      Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
      int csgn = z.im>=0 ? 1 : -1;         //compute csgn(z/i)
      
      Complex y = pq[0].mul(trig[0]).addeq(pq[1].mul(trig[1])); //compute Y (ignoring the (pi/2*z)^(-1/2) term)
      Complex j = pq[0].mul(trig[1]).subeq(pq[1].mul(trig[0])); //compute J
      Complex root = sqrt(inv.div(HALFPI));                     //compute the square root term
      return new Complex[] {mul(j, trig2[1].add(trig2[0].mulI(csgn)), root),
                            y.mul(trig2[1].sub(trig2[0].mulI(csgn))) .addeq(mul(j, new Complex(0,2*csgn),trig2[1])) .muleq(root)};
      //return  j*(-1)^(+-a)  and  y*(-1)^(-+a) +- j*2icos
    }
    
    //otherwise, we evaluate it normally
    Complex inv = z.inv(); //compute 1/z
    Complex[] trig = z.sub(a.mul(0.5f).addeq(0.25f).muleq(Math.PI)).fsincos(); //compute sine and cosine of z-(2a+1)π/4
    Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
    Complex root = sqrt(inv.div(HALFPI)); //compute the square root term
    return new Complex[] {trig[1].mul(pq[0]).subeq(trig[0].mul(pq[1])).muleq(root),
                          trig[0].mul(pq[0]).addeq(trig[1].mul(pq[1])).muleq(root)};
    //finally, return (cos*P-sin*Q)*√(2/(πz)) and (sin*P+cos*Q)*√(2/(πz))
  }
  
  private static Complex[] besselPQ(Complex a, Complex inv, int stop) { //both supplementary functions used to construct the asymptotic series
    Complex p = zero(), q = zero(); //init both sums to 0
    Complex term = one();           //the term that p or q adds each time
    Complex mul = inv.mulI(0.5d);  //one of the things we multiply by each time
    double prevMult = Mafs.INF;
    for(int n=0;n<=stop;n++) {
      if((n&1)==0) { p.addeq(term); } //for even iterations, add to p
      else         { q.addeq(term); } //for  odd iterations, add to q
      
      Complex multiplier = a.sq().subeq((n+0.5f)*(n+0.5f)).muleq(mul).diveq(n+1); //compute what we must multiply our term by
      if(multiplier.absq()>prevMult && multiplier.absq()>1) { break; } //if our multiplier is bigger than 1, quit the loop
      term.muleq(multiplier);            //otherwise, multiply the term by the mutiplier and go to the next iteration
      
      prevMult = multiplier.absq();
      
      //each iteration, the term = (a+n-1/2)!/((a-n-1/2)!n!) * (inv*i/2)^n
    }
    return new Complex[] {p, q.divI()}; //return p and q (with q divided by i)
  }
  
  //////////////////////////// OTHER //////////////////////////////
  
  
}

public static long gcf(long... inps) { //computes the greatest common factor of a set of inputs
  long inp[] = new long[inps.length];
  System.arraycopy(inps,0,inp,0,inps.length);
  
  for(int n=0;n<inp.length;n++) { if(inp[n]<0) { inp[n] = -inp[n]; } } //first, we perform the trivial step of negating all negative inputs
  
  //throughout this process, we will want all 0s at the end of the array. We will pretend those zeros aren't there and the array is shorter. z is the length of said pretend array
  int z = inp.length;         //initialize z to the length of the array
  z = moveZerosToEnd(inp, z); //move all 0 elements to the end of the array, all while updating z
  
  //now, all 0s are at the end of the array, and z is the length the array would be if we cut out the zeros
  if(z==0) { throw new ArithmeticException("Answer is Infinite"); } //the GCF of an empty array or an array of all 0s would be infinite
  
  //now, we have to divide each element by the greatest power of 2 that divides them all (then multiply back by that at the end)
  int shift = 0; //shift is said power of 2
  long or = 0; for(int n=0;n<z;n++) { or |= inp[n]; } //take the bitwise or of all non-zero elements
  while((or&1)==0)     { or>>>=1; ++shift; } //continually right shift our or & increment our shift until the or is odd
  for(int n=0;n<z;n++) { inp[n]>>>=shift; } //lastly, right shift all elements by said shift
  
  //the next step is that we have to take all even numbers and divide by the largest divisible power of 2. Remember, at least one of these numbers is odd, so the GCF isn't divisible by 2
  for(int n=0;n<z;n++) { while((inp[n]&1)==0) { inp[n]>>>=1; } } //take each element, divide by 2 until odd
  
  
  //now, for the main bulk of the algorithm: we perform a combination of subtracting elements from eachother, dividing elements by 2, and moving 0s to the end until all elements but one are 0
  while(z!=1) { //perform the following steps repeatedly until there's only one non-zero element
    for(int n=0;n<z-1;n++) { //loop through all pairs of sequential elements in the array
      if(inp[n]<inp[n+1]) { long t=inp[n]; inp[n]=inp[n+1]; inp[n+1]=t; } //if the 1st is smaller than the 2nd, swap places
      
      inp[n] = (inp[n]-inp[n+1])>>>1; //replace a with (a-b)/2 (making it smaller w/out changing the GCF)
      if(inp[n]==0) { inp[n]=inp[z-1]; inp[z-1]=0; z--; n--; continue; } //if the element is now 0, move it to the end & restart this iteration
      while((inp[n]&1)==0) { inp[n]>>>=1; } //while this element is even, divide by 2
      if(inp[n]>inp[n+1]) { long t=inp[n]; inp[n]=inp[n+1]; inp[n+1]=t; } //if the 1st is larger than the 2nd, swap places
    }
  }
  
  return inp[0]<<shift; //finally, return the only remaining non-zero element (left shifted by that shift we computed earlier)
}

public static int moveZerosToEnd(long[] inps, int z) { //moves all 0 elements to the end of the array, all indices >= z are 0, we return our new value of z after the elements have been moved
  for(;z>0&&inps[z-1]==0;z--) { } //decrement z until the element before it is non-zero (or until there is no element before it)
  for(int n=0;n<z;n++) { //loop through all inputs before z
    if(inps[n]==0) {     //if 0:
      z--; inps[n]=inps[z]; inps[z]=0; //swap with the last non-zero element and decrement z
      for(;z>0&&inps[z-1]==0;z--) { }  //decrement z until the element before it is non-zero (or until there's no element before it)
    }
  }
  return z; //return our new z
}

/*static String primeFactor(long f) { //computes the prime factorization
  if(f<=0) { return "Can only factor positive integers"; }
  if(f==1) { return "Empty Product"; }
  
  String result = ""; //initialize to empty string
  
  //first, check if 2, 3, 5, or 7 are prime factors
  byte pow = 0; while((f&1)==0) { f>>=1; pow++; } //first 2 (shift right until last digit is 1)
  if(pow!=0) { result += "*2"+(pow==1 ? "" : "^"+pow); }
  pow = 0; while(0x5555555555555555l*(f+1) >= 0x2AAAAAAAAAAAAAABl) { f*=0xAAAAAAAAAAAAAAABl; pow++; } //then 3 (sped up using modular arithmetic)
  if(pow!=0) { result += "*3"+(pow==1 ? "" : "^"+pow); }
  pow = 0; while(0x3333333333333333l*(f+2) >= 0x4CCCCCCCCCCCCCCDl) { f*=0xCCCCCCCCCCCCCCCDl; pow++; } //then 5 (sped up using modular arithmetic)
  if(pow!=0) { result += "*5"+(pow==1 ? "" : "^"+pow); }
  pow = 0; while(0x6DB6DB6DB6DB6DB7l*(f+1)-1 >= 0x5B6DB6DB6DB6DB6Dl) { f*=0x6DB6DB6DB6DB6DB7l; pow++; } //then 7 (sped up using modular arithmetic)
  if(pow!=0) { result += "*7"+(pow==1 ? "" : "^"+pow); }
  
  if(f==1) { return result.substring(1); } //if there are no more factors, we can stop now and just return what we have (without the initial times sign, of course)
  
  //next, we loop through all possible factors between 11 and sqrt(f), ignoring all numbers divisible by 2, 3, 5, or 7. In doing so, we cut out 27/35 of the numbers over that range, and only have to explore 22.9% of those numbers
  long root = (long)Math.floor(Math.sqrt(f)); //compute the square root of f
  byte option = 2; //this represents the 48 possible values n could be mod 210
  for(long n=11;n<=root;) {
    pow = 0; while(f%n==0) { f/=n; pow++; } //count how many times f is divisible by n
    if(pow!=0) { //if non-zero:
      result += "*"+n+(pow==1 ? "" : "^"+pow); //attach this to our prime factorization
      root = (long)Math.floor(Math.sqrt(f));   //compute the square root once again
    }
    
    //now, our next value for n depends on our option:
    switch(option&127) { //switch the option (ignore the sign bit)
      case  0: n+=2; option^=-128; break; //for option  0, we increase by 2 and switch directions
      case 24: n+=4; option^=-128; break; //for option 24, we increase by 4 and switch direcitons
      
      case 2: case 4: case  7: case 10: case 14: case 17: case 23: n+=2; break; //for these options, increase by 2
      case 3: case 5: case  9: case 11: case 16: case 19: case 22: n+=4; break; //for these options, increase by 4
      case 6: case 8: case 12: case 13: case 15: case 18: case 20: n+=6; break; //for these options, increase by 6
      
      case 21: n+= 8; break; //increase by 8
      case  1: n+=10; break; //increase by 10
    }
    if(option<0) { option--; } else { option++; } //If negative, decrease. If positive, increase
  }
  
  if(result.length()==0) { return f+""; } //if there were no prime factors, this number is prime and you should just return the number
  
  if(f!=1) { result += "*"+f; } //if there is still one prime factor left, tack that on at the end
  return result.substring(1);   //finally, remove the initial times sign and then return the result
}*/

static class PrimeFactorization {
  java.util.TreeMap<Long, Integer> factors;
  
  PrimeFactorization(long f) {
    factors = primeFactor(f);
  }
  
  public static java.util.TreeMap<Long, Integer> primeFactor(long f) { //computes the prime factorization (returns an arraylist of longs and their powers
    if(f==0) { return null; } //0: undefined, since 0 can factor out all numbers
    if(f==1) { return new java.util.TreeMap<Long, Integer>(); } //1: empty product
    
    java.util.TreeMap<Long, Integer> factor = new java.util.TreeMap<Long, Integer>(); //initialize prime factorization list
    
    if(f<0) { factor.put(-1l,1); f=-f; }
    
    //first, check if 2, 3, 5, or 7 are prime factors
    int pow = 0; while((f&1)==0) { f>>=1; pow++; } //first 2 (shift right until last digit is 1)
    if(pow!=0) { factor.put(2l,pow); }
    pow = 0; while(0x5555555555555555l*(f+1) >= 0x2AAAAAAAAAAAAAABl) { f*=0xAAAAAAAAAAAAAAABl; pow++; } //then 3 (sped up using modular arithmetic)
    if(pow!=0) { factor.put(3l,pow); }
    pow = 0; while(0x3333333333333333l*(f+2) >= 0x4CCCCCCCCCCCCCCDl) { f*=0xCCCCCCCCCCCCCCCDl; pow++; } //then 5 (sped up using modular arithmetic)
    if(pow!=0) { factor.put(5l,pow); }
    pow = 0; while(0x6DB6DB6DB6DB6DB7l*(f+1)-1 >= 0x5B6DB6DB6DB6DB6Dl) { f*=0x6DB6DB6DB6DB6DB7l; pow++; } //then 7 (sped up using modular arithmetic)
    if(pow!=0) { factor.put(7l,pow); }
    
    if(f==1) { return factor; } //if there are no more factors, we can stop now and just return what we have
    
    //next, we loop through all possible factors between 11 and sqrt(f), ignoring all numbers divisible by 2, 3, 5, or 7. In doing so, we cut out 27/35 of the numbers over that range, and only have to explore 22.9% of those numbers
    long root = (long)Math.floor(Math.sqrt(f)); //compute the square root of f
    byte option = 2; //this represents the 48 possible values n could be mod 210
    for(long n=11;n<=root;) {
      pow = 0; while(f%n==0) { f/=n; pow++; } //count how many times f is divisible by n
      if(pow!=0) { //if non-zero:
        factor.put(n,pow); //attach this to our prime factorization
        root = (long)Math.floor(Math.sqrt(f)); //compute the square root once again (so we know to stop even sooner)
      }
      
      //now, our next value for n depends on our option:
      switch(option&127) { //switch the option (ignore the sign bit)
        case  0: n+=2; option^=-128; break; //for option  0, we increase by 2 and switch directions
        case 24: n+=4; option^=-128; break; //for option 24, we increase by 4 and switch direcitons
        
        case 2: case 4: case  7: case 10: case 14: case 17: case 23: n+=2; break; //for these options, increase by 2
        case 3: case 5: case  9: case 11: case 16: case 19: case 22: n+=4; break; //for these options, increase by 4
        case 6: case 8: case 12: case 13: case 15: case 18: case 20: n+=6; break; //for these options, increase by 6
        
        case 21: n+= 8; break; //increase by 8
        case  1: n+=10; break; //increase by 10
      }
      if(option<0) { option--; } else { option++; } //If negative, decrease. If positive, increase
    }
    
    if(f!=1) { factor.put(f,1); } //whatever's left has to be added to the prime factorization (unless it's 1, which can happen if the largest factor has a multiplicity greater than 1)
    return factor;
  }
  
  public @Override
  String toString() { //outputs the prime factorization as a string
    if(factors==null) { return "0"; }
    
    String result = "";
    boolean init = true;
    for(java.util.Map.Entry<Long,Integer> entry : factors.entrySet()) {
      long prime = entry.getKey();
      int exponent = entry.getValue();
      
      if(!init) { result+="*"; }
      result+=prime;
      if(exponent > 1) { result+="^"+exponent; }
      init = false;
    }
    
    return result;
  }
}

public static long[] bezout(long a, long b) { //Using extended Euclidean algorithm, returns the result of Bezout's identity, ax+by=gcf(a,b), returning an array {x,y,gcf(a,b)}
  long[] prev = {0,a,1,0}; //two arrays, containing (in order) q, r, s, t
  long[] curr = {0,b,0,1};
  long[] temp; //temporary (storage) array
  
  while(curr[1]!=0) {
    prev[0]=prev[1]/curr[1]; //compute quotient
    prev[1]-=prev[0]*curr[1]; //remainder
    prev[2]-=prev[0]*curr[2]; //s
    prev[3]-=prev[0]*curr[3]; //t
    
    temp = curr; curr = prev; prev = temp; //swap temp and curr
  }
  
  //finally, return x, y, and gcf
  if(prev[1]<0) { return new long[] {-prev[2],-prev[3],-prev[1]}; } //if gcf is negative, negate the result
  return                 new long[] { prev[2], prev[3], prev[1]};
}

public static long modInv(long x, long m) { //find the inverse of x mod m
  if((m&(m-1))==0) { //modulo is a power of 2 (there's a faster method):
    if((x&1)==0) { //if not even, cannot invert
      throw new RuntimeException("Cannot find inverse of "+x+" mod "+m+", they aren't coprime (they're both even)");
    }
    long res = 2-x, prod = x*(2-x); //otherwise, we use the Newton-Raphson method. It requires at most 6 iterations
    while(prod!=1) {
      res *= 2-prod;
      prod = x*res;
    }
    return res&(m-1); //return result (but forced to be positive)
  }
  
  long[] b = bezout(x,m); //perform the extended Euclidean algorithm
  if(b[2]!=1l) { throw new RuntimeException("Cannot find inverse of "+x+" mod "+m+", they aren't coprime (gcf="+b[2]+")"); } //not coprime: output error
  return Math.floorMod(b[0],m); //otherwise, return the result (modulo m)
}

public static long totient(long x) { //computes the Euler's totient function
  PrimeFactorization factor = new PrimeFactorization(x); //first, compute its prime factorization
  
  for(java.util.Map.Entry<Long, Integer> entry : factor.factors.entrySet()) { //loop through all the prime factors
    long prime = entry.getKey();
    if(prime!=-1) { x *= 1-1d/prime; }
  }
  return x;
}

static ArrayList<double[]> stirling1 = new ArrayList<double[]>(); //arraylist containing the stirling numbers of the first kind
static ArrayList<double[]> stirling2 = new ArrayList<double[]>(); //arraylist containing the stirling numbers of the second kind

public static double stirling1(int n, int k) { //gets the stirling number of the first kind
  if(k<0 || k>n) { return 0; } //out of bounds: return 0
  for(int r=stirling1.size();r<=n;r++) { //iteratively generate each missing row
    double[] row = new double[r+1]; //initialize row
    
    if(r!=0) { row[0] = 0; } //make 0th element 0
    row[r] = 1;              //make last element 1
    
    for(int j=1;j<r;j++) { //compute the rest of the elements recursively
      row[j] = stirling1.get(r-1)[j-1] + (r-1)*stirling1.get(r-1)[j]; //this is the recurrence relation
    }
    stirling1.add(row); //add the row to the stirling triangle
  }
  return stirling1.get(n)[k]; //return the value here
}

public static double stirling2(int n, int k) { //gets the stirling number of the second kind
  if(k<0 || k>n) { return 0; } //out of bounds: return 0
  for(int r=stirling2.size();r<=n;r++) { //iteratively generate each missing row
    double[] row = new double[r+1]; //initialize row
    
    if(r!=0) { row[0] = 0; } //make 0th element 0
    row[r] = 1;              //make last element 1
    
    for(int j=1;j<r;j++) { //compute the rest of the elements recursively
      row[j] = j*stirling2.get(r-1)[j] + stirling2.get(r-1)[j-1]; //this is the recurrence relation
    }
    stirling2.add(row); //add the row to the stirling triangle
  }
  return stirling2.get(n)[k]; //return the value here
}

/*static long modPow(long a, long b, long m) { //computes a to the b modulo m
  if(a==Long.MIN_VALUE) { long root = modPow(modInv(a,m),0x4000000000000000l,m); return Math.floorMod(root*root,m); } //special case: exponent is minimum integer, raise to the power of -2^62, then square result.
  //NOTE: without the above code, raising a number to the power of -2^63 would result in a stack overflow, since a would be repeatedly negated (to no effect) and z would be repeatedly inverted
  
  if(b<0) { return modPow(modInv(a,m),-b,m); } //a is negative: return (1/z)^(-a)
  //general case:
  long ans = 1;        //return value: a^b (init to 1 in case b==0)
  long ex=b;           //copy of b
  long iter=a%m;       //a ^ (2 ^ (whatever digit we're at))
  boolean inits=false; //true once ans is initialized (to something other than 1)
  
  while(ex!=0) {                               //loop through all b's digits (if b==0, exit loop, return 1)
    if((ex&1)==1) {
      if(inits) { ans = (ans*iter)%m;   } //mult ans by iter ONLY if this digit is 1
      else      { ans=iter; inits=true; } //if ans still = 1, set ans=iter (instead of multiplying by iter)
    }
    ex >>= 1;                               //remove the last digit
    if(ex!=0)   { iter = (iter*iter)%m; } //square the iterator (unless the loop is over)
  }
  
  return Math.floorMod(ans,m); //return the result
}*/

public static long modPow(long a, long b, long m) { //computes a to the b modulo m
  return BigInteger.valueOf(a).modPow(BigInteger.valueOf(b), BigInteger.valueOf(m)).longValue();
}

public static long modMult(long a, long b, long m) { //computes a * b mod m
  return BigInteger.valueOf(a).multiply(BigInteger.valueOf(b)).mod(BigInteger.valueOf(m)).longValue();
}

public static Long discLog_babyGiant(long base, long num, long mod, long phi) {
  
  HashMap<Long,Long> powMap = new HashMap<Long,Long>();
  
  long root1 = (long)Math.round(Math.sqrt(phi));    //the size of the big step
  long root2 = (phi+root1-1)/root1; //the number of big steps in the cycle (rounded up)
  
  //first, we populate the power map with powers
  long bigStep = modPow(base,root1,mod);
  long pow = 1;
  for(long n=0;n<root2;n++) {
    powMap.put(pow,n);
    pow = modMult(pow,bigStep,mod);
  }
  
  long inv = modInv(base,mod);
  for(int n=0;n<root1;n++) {
    Long exp = powMap.get(num);
    if(exp!=null) { return root1*exp+n; }
    
    num = modMult(num,inv,mod);
  }
  
  return null;
}

public static long carmichael(long inp) {
  PrimeFactorization factor = new PrimeFactorization(inp); //compute the prime factorization
  
  BigInteger tot = BigInteger.ONE;
  for(java.util.Map.Entry<Long,Integer> entry : factor.factors.entrySet()) { //loop through all prime factors
    long prime = entry.getKey(), pow = entry.getValue(); //get the prime and the exponent
    
    long term;
    if(prime==-1) { continue; }
    else if(prime==2) {
      if(pow>=3) { term = 1<<(pow-2); }
      else       { term = 1<<(pow-1); }
    }
    else {
      term = BigInteger.valueOf(prime).pow((int)(pow-1)).longValue()*(prime-1);
    }
    
    tot = tot.multiply(BigInteger.valueOf(term)).divide(tot.gcd(BigInteger.valueOf(term)));
    
  }
  
  return tot.longValue();
}
//Since on Android, you can have multiple touch events, but on PC, there's only one, we need a class to store cursors.
//On PC, there's always 1, on Android, it varies. We can customize the code for both, but we'll use cursors to keep things reusable.

public static class Cursor {
  
  ////////////////// ATTRIBUTES ///////////////////
  
  int id = 0;           //The ID of this cursor. Used primarily for compatibility with touch events on Android. Always 0 on PCs w/out multitouch
  
  float x, y;           //x and y position
  float dx, dy, ex, ey; //x and y in the previous draw cycle, and in the previous event. e is ignored on Android due to issues
  
  byte press=0;         //whether each mouse button is pressed. On Android, right & center are ignored
  //as an optimization, the 3 bools were combined into 1 byte, which both optimizes storage & allows us to quickly check if it's in a particular state (i.e. ==0, !=0)
  
  boolean active = true; //when false, this cursor is considered deactivated. The alternative to this would be to simply finalize this object and have it be null, but that might be unsafe
  //TODO figure out if the active boolean ever gets used in practice
  Box select = null;        //the behavior of this cursor and how it interacts with UI elements, characterized by the object it touched when it was most recently pressed. More specifically, that object's class
  boolean seLocked = false; //(select locked)if true, select promotion cannot occur, as the current select is locked (becomes false when we deselect)
  //NOTE Maybe I shouldn't have the select thing here? I mean, it makes perfect sense, but also it conflicts with a general philosophy that the Cursor should act all on its own, regardless of the inclusion of a UI library
  float xi, yi; //initial x and y, the position it was on the last time it was pressed down
  
  ///////////////////// CONSTRUCTORS ////////////////////
  
  Cursor() { }
  
  Cursor(float x_, float y_) { x=dx=ex=x_; y=dy=ey=y_; }
  
  Cursor(int id_, float x_, float y_) { this(x_,y_); id=id_; }
  
  /////////////////// GETTERS ///////////////////////
  
  public int getId() { return id; }
  
  public boolean left  () { return (press&4)==4; }
  public boolean center() { return (press&2)==2; }
  public boolean right () { return (press&1)==1; }
  public boolean allPressed() { return press==7; }
  public boolean anyPressed() { return press!=0; }
  
  public Box getSelect() { return select; }
  
  //////////////// MUTATORS ///////////////////////
  
  public Cursor setId(final int i) { id=i; return this; }
  
  public void updatePos(float mouseX, float mouseY) { ex=x; ey=y; x=mouseX; y=mouseY; } //updates position
  
  public void press(int mouseButton) { switch(mouseButton) {
    case LEFT: press|=4; break; case CENTER: press|=2; break; case RIGHT: press|=1;
  } xi=x; yi=y; }
  
  public void release(int mouseButton) { switch(mouseButton) {
    case LEFT: press&=~4; break; case CENTER: press&=~2; break; case RIGHT: press&=~1;
  } }
  
  public void press  () { press  (LEFT); } //Press/release w/out specifying button.
  public void release() { release(LEFT); } //LEFT is default button
  
  public void setSelect(final Box box) { //sets which box this cursor is selecting
    if(select instanceof Panel) { ((Panel)select).release(this); } //if it was a panel, start a release event
    if(   box instanceof Panel) { ((Panel)   box).press  (this); } //if it is a panel, start a press event
    /*if(box==null && select instanceof Textbox.CaretMover) { //if it was a caret mover, AND we're swapping to null:
      ((Textbox.CaretMover)select).release(this);           //perform the release event on it, allowing us to move the text caret wherever we want
    }*/
    select = box;     //finally, set select
    seLocked = false; //unlock the cursor
  }
  
  ////////////// DEFAULT FUNCTIONS //////////////////
  
  @Override
  public Cursor clone() {
    Cursor result = new Cursor(id,x,y); result.dx=dx; result.dy=dy; result.ex=ex; result.ey=ey; result.press=press;
    result.active=active; result.select=select; result.seLocked=seLocked; result.xi=xi; result.yi=yi;
    return result;
  }
}
static enum Month {
  JANUARY, FEBRUARY, MARCH, APRIL, MAY, JUNE, JULY, AUGUST, SEPTEMBER, OCTOBER, NOVEMBER, DECEMBER;
  public String toString() { String res = name().toLowerCase(); return PApplet.parseChar(res.charAt(0)+'A'-'a')+res.substring(1); } //make it lowercase, then capitalize the 1st letter
  public String threeLetter() { return toString().substring(0,3); }
  public int num() { return ordinal()+1; }
  
  public int days(boolean leap) { switch(this) {
    case FEBRUARY: return leap ? 29 : 28;
    case APRIL: case JUNE: case SEPTEMBER: case NOVEMBER: return 30;
    default: return 31;
  } }
  
  public int daysAccum(boolean leap) { switch(this) { //returns the number of days between the 1st of the month & new years
    case   JANUARY: return            0;
    case  FEBRUARY: return           31;
    case     MARCH: return leap? 60: 59;
    case     APRIL: return leap ?91: 90;
    case       MAY: return leap?121:120;
    case      JUNE: return leap?152:151;
    case      JULY: return leap?182:181;
    case    AUGUST: return leap?213:212;
    case SEPTEMBER: return leap?244:243;
    case   OCTOBER: return leap?274:273;
    case  NOVEMBER: return leap?305:304;
    default       : return leap?335:334;
  } }
  
  public static Month toMonth(int m) { switch(m) {
    case 1: return JANUARY; case 2: return FEBRUARY; case 3: return MARCH; case 4: return APRIL;
    case 5: return MAY; case 6: return JUNE; case 7: return JULY; case 8: return AUGUST;
    case 9: return SEPTEMBER; case 10: return OCTOBER; case 11: return NOVEMBER; case 12: return DECEMBER;
    //default: throw new RuntimeException("There is no month "+m+" (only 1-12 are accepted)");
    default: return null;
  } }
  
  public Month increment() { switch(this) {
    case JANUARY: return FEBRUARY;   case FEBRUARY: return MARCH;   case MARCH: return APRIL;   case APRIL: return MAY;
    case MAY: return JUNE;   case JUNE: return JULY;   case JULY: return AUGUST;   case AUGUST: return SEPTEMBER;
    case SEPTEMBER: return OCTOBER;   case OCTOBER: return NOVEMBER;   case NOVEMBER: return DECEMBER; default: return JANUARY;
  } }
  
  public Month decrement() { switch(this) {
    case JANUARY: return DECEMBER;   case FEBRUARY: return JANUARY;   case MARCH: return FEBRUARY;   case APRIL: return MARCH;
    case MAY: return APRIL;   case JUNE: return MAY;   case JULY: return JUNE;   case AUGUST: return JULY;
    case SEPTEMBER: return AUGUST;   case OCTOBER: return SEPTEMBER;   case NOVEMBER: return OCTOBER; default: return NOVEMBER;
  } }
  
  //list of strings that could be converted into a month (as well as a list of the months they correspond to)
  static String matchers[] = {"January ","Jan ","February ","Feb ","March ","Mar ","April ","Apr ","May ","June ","Jun ","July ","Jul ","August ","Aug ","September ","Sept ","Sep ","October ","Oct ","November ","Nov ","December ","Dec "};
  static Month matchId[] = {JANUARY,JANUARY,FEBRUARY,FEBRUARY,MARCH,MARCH,APRIL,APRIL,MAY,JUNE,JUNE,JULY,JULY,AUGUST,AUGUST,SEPTEMBER,SEPTEMBER,SEPTEMBER,OCTOBER,OCTOBER,NOVEMBER,NOVEMBER,DECEMBER,DECEMBER};
}

static enum Weekday {
  SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY;
  public String toString() { String res = name().toLowerCase(); return PApplet.parseChar(res.charAt(0)+'A'-'a')+res.substring(1); } //make it lowercase, then capitalize the 1st letter
  public String shorten() { switch(this) { case SUNDAY: return "Sun"; case MONDAY: return "Mon"; case TUESDAY: return "Tues"; case WEDNESDAY: return "Wed"; case THURSDAY: return "Thurs"; case FRIDAY: return "Fri"; default: return "Sat"; } }
  
  public int num() { return ordinal(); }
  public static Weekday fromNumber(long num) {
    switch((int)(num%7)) {
      case 0:          return    SUNDAY;
      case 1: case -6: return    MONDAY;
      case 2: case -5: return   TUESDAY;
      case 3: case -4: return WEDNESDAY;
      case 4: case -3: return  THURSDAY;
      case 5: case -2: return    FRIDAY;
      default:         return  SATURDAY;
    }
  }
  public Weekday increment() { switch(this) {
    case SUNDAY: return MONDAY; case MONDAY: return TUESDAY; case TUESDAY: return WEDNESDAY; case WEDNESDAY:
    return THURSDAY; case THURSDAY: return FRIDAY; case FRIDAY: return SATURDAY; default: return SUNDAY;
  } }
  public Weekday decrement() { switch(this) {
    case SUNDAY: return SATURDAY; case MONDAY: return SUNDAY; case TUESDAY: return MONDAY; case WEDNESDAY:
    return TUESDAY; case THURSDAY: return WEDNESDAY; case FRIDAY: return THURSDAY; default: return FRIDAY;
  } }
}



private static class DateCombo { //can be used to represent a date
  
  //ATTRIBUTES
  Month month;
  byte day;
  long year;
  
  //CONSTRUCTORS
  DateCombo(int d, Month m, long y) { day=(byte)d; month=m; year=y; } //date given day, month, year
  DateCombo(Month m, int d, long y) { month=m; day=(byte)d; year=y; } //date given month, day, year
  DateCombo(long a, int b, long c) { switch(Date.format) {
    case 0: day=(byte)a; month = Month.toMonth(b); year = c; break;
    case 1: day=(byte)b; month = Month.toMonth((int)a); year = c; break;
    default: day=(byte)c; month = Month.toMonth((int)a); year = a;
  } }
  
  DateCombo(long d) { //date given number of days since jan 1 0000
    //float approx = d/365.2425; //A full revolution is 365.2425 days. Find how many revolutions fit into this many days
    //the above method is probably faster, but it's also much harder to implement. Gotta do a lot of tricky math
    
    /*long amt1 = floor(d/146097f);      //find how many times 400 years fits into d days
    year = amt1*400; d -= 146097*amt1; //increment our year & decrement our days by that many quadruple centuries
    long amt2 = (d-1)/36524;           //find how many times 100 years fits into the d days left
    if(amt2!=0) { year += amt2*100; d -= 36524*amt2+1; } //increment our year & decrement our days by that many centuries
    long amt3 = (d-(amt2==0?0:1))/1461; //find how many times 4 years fits into the d days left (making sure to account for whether the first year of the century is a leap year)
    if(amt3!=0) { year += amt3*4; d -= 1461*amt3-(amt2==0?0:1); } //increment our year & decrement our days by that many quadruple years
    long amt4 = (d-(amt2==0||amt3!=0?1:0))/365; //find how many times 1 year fits into the d days left (making sure to account for whether the first year is a leap year)
    if(amt4!=0) { year += amt4; d -= 365*amt4+(amt2==0||amt3!=0?1:0); } //increment our year & decrement our days by that many years*/
    
    long amt1 = floor(d/146097f);      //find how many times 400 years fits into d days
    year = amt1*400; d -= 146097*amt1; //increment our year & decrement our days by that many quadruple centuries
    long amt2 = (d-1)/36524;           //find how many times 100 years fits into the d days left
    if(amt2!=0) { year += amt2*100; d -= 36524*amt2+1; } //increment our year & decrement our days by that many centuries
    long amt3 = (d-(amt2==0?0:1))/1461; //find how many times 4 years fits into the d days left (making sure to account for whether the first year of the century is a leap year)
    if(amt3!=0) { year += amt3*4; d -= 1461*amt3; } //increment our year & decrement our days by that many quadruple years
    long amt4 = (d-(amt2==0?1:0))/365; //find how many times 1 year fits into the d days left (making sure to account for whether the first year is a leap year)
    if(amt4!=0) { year += amt4; d -= 365*amt4+(amt2==0?1:0); } //increment our year & decrement our days by that many years
    else { d += (amt2==0||amt3==0?0:1); }
    
    boolean leap = Date.isLeap(year); //find whether this is a leap year
    month = Month.JANUARY;            //initialize month to January
    while(d >= month.days(leap)) { d -= month.days(leap); month = month.increment(); } //as long as the day is larger than the number of days, increment the month and subtract that many days
    day = (byte)(d+1); //set the day of the month
  }
  
  DateCombo(Date d) { this((int)d.day); }
  
  //GETTERS/SETTERS
  public Month getMonth() { return month; }
  public byte  getDay  () { return   day; }
  public long  getYear () { return  year; }
  
  
  //CHECKERS & TESTERS
  public boolean valid() { //whether or not this is a valid date
    return month!=null && day>0 && (day<=28 || day<=month.days(Date.isLeap(year))); //return true if month is valid, day is positive, and not greater than the number of days this month has
  }
  
  public int dayOfYear() { //grabs the number of days since new year's eve last year (1/1=1, 1/2=2, 12/31=365 (or 366), etc.)
    return month.daysAccum(Date.isLeap(year))+day; //take the number of days accumulated over the previous months, then add the day
  }
  
  public long dayFromEpoch() { //finds the number of days since the epoch of january 1, 0000
    long yearAccum = 365*year; //compute the number of days accumulated from each year (ignoring leap days)
    yearAccum += 1+((year-1)>>2)-floor(0.01f*(year-1))+floor(0.0025f*(year-1)); //add up all the leap days
    return yearAccum + dayOfYear() - 1; //return those days + the days since 1/1
  }
  
  //INHERITED METHODS
  
  public @Override
  String toString() {
    switch(Date.format) {
      case 0: return day+" "+month+", "+year;
      case 1: return month+" "+day+", "+year;
      default: return year+" "+month+" "+day;
    }
  }
}

public static class Date {
  //ATTRIBUTES
  long day = 0; //days since the 1/1/0000 epoch
  
  static byte format = 1; //0=D/M/Y, 1=M/D/Y, 2=Y/M/D
  static int timeZone = -4; //the current time zone
  
  Date() { }
  Date(long a, int b, long c) { day = new DateCombo(a,b,c).dayFromEpoch(); }
  Date(Month m, int d, long y) { day = new DateCombo(m,d,y).dayFromEpoch(); }
  Date(int d, Month m, long y) { day = new DateCombo(d,m,y).dayFromEpoch(); }
  Date(DateCombo d) { day = d.dayFromEpoch(); }
  Date(long d) { day = d; }
  
  @Override
  public String toString() { return new DateCombo((int)day)+""; }
  
  @Override
  public boolean equals(final Object obj) {
    return obj instanceof Date && ((Date)obj).day==day;
  }
  
  @Override
  public Date clone() { return new Date(day); }
  
  @Override
  public int hashCode() { return (int)(day ^ day>>>32); }
  
  public static boolean isLeap(long y) { //whether this year is a leap year
    return (y&3)==0 && (y%100!=0 || (y&15)==0); //return true if divisible by 4 AND not divisible by 100 UNLESS it's also divisible by 400 (which would mean it's divisible by 16)
  }
  
  public Date addeq(long d) { day+=d; return this; }
  public Date subeq(long d) { day-=d; return this; }
  public Date add(long d) { return new Date(day+d); }
  public Date sub(long d) { return new Date(day-d); }
  public Date increment() { return new Date(day+1); }
  public Date decrement() { return new Date(day-1); }
  public long sub(Date d) { return day-d.day; }
  
  
  public long   getYear() { return new DateCombo(this).year; }
  public Month getMonth() { return new DateCombo(this).month; }
  public byte    getDom() { return new DateCombo(this).day; }
  
  public static long year() { return new DateCombo(today()).year; }
  
  
  public static Date today() {
    long time = System.currentTimeMillis(); //grab the time in milliseconds from January 1, 1970
    time+=Date.timeZone*3600000l;           //move to the New York time zone
    time/=86400000l;                        //divide by 1000ms * 60s * 60min * 24hr
    return new Date(time+719528);           //add the time between 0 epoch and 1970 epoch, return result
  }
  
  public static Date tomorrow () { return new Date(++today().day); }
  public static Date yesterday() { return new Date(--today().day); }
  
  public static Date    sunday() { return new Date(7*ceil((today().day-1)/7f)+1); }
  public static Date    monday() { return new Date(7*ceil((today().day-2)/7f)+2); }
  public static Date   tuesday() { return new Date(7*ceil((today().day-3)/7f)+3); }
  public static Date wednesday() { return new Date(7*ceil((today().day-4)/7f)+4); }
  public static Date  thursday() { return new Date(7*ceil((today().day-5)/7f)+5); }
  public static Date    friday() { return new Date(7*ceil((today().day-6)/7f)+6); }
  public static Date  saturday() { return new Date(7*ceil(today().day/7f));       }
  
  public static Date newYears(long y) { return new Date(1, Month.JANUARY, y); }
  public static Date valentines(long y) { return new Date(14, Month.FEBRUARY, y); }
  public static Date stPatricks(long y) { return new Date(17, Month.MARCH, y); }
  //static Date easter(long y) { } //NO NO NO NO NO NO NO NO
  public static Date mothersDay(long y) {
    long first = new Date(1, Month.MAY, y).day; //look at the first of May
    return new Date(7*ceil((first-1)/7f)+8);    //return the second sunday during or after that
  }
  public static Date fathersDay(long y) {
    long first = new Date(1, Month.JUNE, y).day; //look at the first of June
    return new Date(7*ceil((first-1)/7f)+15);    //return the third sunday during or after that
  }
  public static Date halloween(long y) { return new Date(31, Month.OCTOBER, y); }
  public static Date thanksgiving(long y) {
    long first = new Date(1, Month.NOVEMBER, y).day; //look at the first of Thursday
    return new Date(7*ceil((first-5)/7f)+26);        //return the 4th thursday during or after that
  }
  public static Date christmas(long y) { return new Date(25, Month.DECEMBER, y); }
  
  public Weekday dayOfWeek() { return Weekday.fromNumber(day-1); } //1/1/0000 was a Saturday
  
  public boolean less(Date d) { return day < d.day; }
  public boolean lessEq(Date d) { return day <= d.day; }
  public boolean greater(Date d) { return day > d.day; }
  public boolean greaterEq(Date d) { return day >= d.day; }
  
  
  public static void setFormat(String f) { switch(f) {
    case "D/M/Y": format=0; break;
    case "M/D/Y": format=1; break;
    case "Y/M/D": format=2; break;
  } }
  
  public static void setTimeZone(int shift) { timeZone = shift; }
}

public static class Time { //class used for representing time (not time of day, but rather amounts of time; hours, minutes, seconds, etc)
  long day; int hour, min, sec;
  
  Time() { }
  Time(long d, int h, int m, int s) { day=d; hour=h; min=m; sec=s; }
  Time(int h, int m, int s) { hour=h; min=m; sec=s; }
  Time(int h, int m) { hour=h; min=m; }
  Time(long s) { day=floor(s/86400f); hour=(int)(s-day*86400)/3600; min=(int)(s-day*86400-hour*3600)/60; sec=(int)(s-day*86400-hour*3600-min*60); }
  
  public long seconds() { return ((day*24+hour)*60+min)*60+sec; }
  public long minutes() { return (day*24+hour)*60+min; }
  public long hours() { return day*24+hour; }
  
  public @Override String toString() {
    if(day<0) { return "-"+neg(); }
    return day+(hour<10?":0":":")+hour+(min<10?":0":":")+min+(sec<10?":0":":")+sec;
  }
  
  public @Override boolean equals(final Object obj) {
    return obj instanceof Time && ((Time)obj).sec==sec && ((Time)obj).min==min && ((Time)obj).hour==hour && ((Time)obj).day==day;
  }
  
  public @Override Time clone() {
    return new Time(day,hour,min,sec);
  }
  
  public @Override int hashCode() {
    return (int)(seconds() ^ seconds()>>>32);
  }
  
  public Time addeq(Time t) {
    sec+=t.sec; if(sec>=60) { sec-=60; min++; }
    min+=t.min; if(min>=60) { min-=60; hour++; }
    hour+=t.hour; if(hour>=24) { hour-=24; day++; }
    day+=t.day;
    return this;
  }
  
  public Time subeq(Time t) {
    sec-=t.sec; if(sec<0) { sec+=60; min--; }
    min-=t.min; if(min<0) { min+=60; hour--; }
    hour-=t.hour; if(hour<0) { hour+=24; day--; }
    day-=t.day;
    return this;
  }
  
  public Time add(Time t) { return clone().addeq(t); }
  public Time sub(Time t) { return clone().subeq(t); }
  
  public Time neg() {
    return new Time(((sec|min|hour)==0?-day:~day),(((sec|min)==0?24:23)-hour)%24,((sec==0?60:59)-min)%60,(60-sec)%60);
  }
  
  public Time muleq(int n) {
    sec*=n; min*=n; hour*=n; day*=n;
    min+=sec/60; hour+=min/60; day+=hour/24;
    sec%=60; min%=60; hour%=24;
    if(sec<0) { sec+=60; min--; } if(min<0) { min+=60; hour--; } if(hour<0) { hour+=24; day--; }
    return this;
  }
  
  public Time mul(int n) { return clone().muleq(n); }
  
  public Time mul(double f) { return new Time(Math.round(seconds()*f)); }
  public Time div(double f) { return new Time(Math.round(seconds()/f)); }
  
  public Time half() { return new Time(day>>1,12*PApplet.parseInt(day&1)+(hour>>1),30*(hour&1)+min>>1,30*(min&1)+(sec>>1)); }
  
  public int compareTo(Time t) {
    if(day==t.day && hour==t.hour && min==t.min && sec==t.sec) { return 0; }
    if(day<t.day || day==t.day && (hour<t.hour || hour==t.hour && (min<t.min || min==t.min && sec<t.sec))) { return -1; }
    return 1;
  }
  
  public boolean notEqual(Time t) { return sec!=t.sec || min!=t.min || hour!=t.hour || day!=t.day; }
  public boolean    less(Time t) { return day<t.day || day==t.day && (hour<t.hour || hour==t.hour && (min<t.min || min==t.min && sec<t.sec)); }
  public boolean greater(Time t) { return day>t.day || day==t.day && (hour>t.hour || hour==t.hour && (min>t.min || min==t.min && sec>t.sec)); }
  public boolean    lessEqu(Time t) { return day<t.day || day==t.day && (hour<t.hour || hour==t.hour && (min<t.min || min==t.min && sec<=t.sec)); }
  public boolean greaterEqu(Time t) { return day>t.day || day==t.day && (hour>t.hour || hour==t.hour && (min>t.min || min==t.min && sec>=t.sec)); }
  
  public double div(Time t) { return (double)(seconds())/t.seconds(); }
}

static class DateTime { //something with both date AND time
  Date date; Time time;
  static boolean military = false;
  
  DateTime() { date = new Date(0); time = new Time(0); }
  
  DateTime(Date d, Time t) { date=d; time=t; }
  DateTime(Date d) { date=d; time=new Time(); }
  DateTime(Time t) { date=new Date(t.day); t.day=0; time=t; }
  
  DateTime(long a, int b, long c, int h, int m, int s) {
    date = new Date(a,b,c); time = new Time(h,m,s);
  }
  
  DateTime(long a, int b, long c, int h, int m, int s, boolean p) {
    date = new Date(a,b,c); time = new Time(h%12+(p?12:0),m,s);
  } //TEST
  
  DateTime(long sec) {
    date = new Date(sec/86400); time = new Time((int)(sec%86400));
  }
  
  @Override public String toString() {
    if(military) { return date+" "+(time+"").substring(2); } //in 24 hour format, we just show the date, and show the time (cutting out the day at the beginning of the time)
    String t = (time.hour==0||time.hour==12 ? 12 : time.hour%12)+(time.min<10?":0":":")+time.min+(time.sec<10?":0":":")+time.sec+(time.hour>11?" PM":" AM"); //grab the time (hour%=12, 0 becomes 12, AM/PM)
    return date+" "+t;
  }
  
  @Override public boolean equals(final Object obj) {
    return obj instanceof DateTime && ((DateTime)obj).date.equals(date) && ((DateTime)obj).time.equals(time);
  }
  
  @Override public DateTime clone() {
    return new DateTime(date.clone(), time.clone());
  }
  
  @Override public int hashCode() {
    return date.hashCode()*31+time.hashCode();
  }
  
  public long seconds() {
    return date.day*86400+time.seconds();
  }
  
  public static DateTime now() {
    long time = System.currentTimeMillis()/1000;
    return new DateTime(time+62167219200l+3600*Date.timeZone);
  }
  
  public DateTime addeq(Time t) {
    time.addeq(t); date.addeq(time.day); time.day=0;
    return this;
  }
  
  public DateTime subeq(Time t) {
    time.subeq(t); date.addeq(time.day); time.day=0;
    return this;
  }
  
  public DateTime add(Time t) { return clone().addeq(t); }
  public DateTime sub(Time t) { return clone().subeq(t); }
  
  public Time sub(DateTime d) {
    long dif1 = date.sub(d.date); //subtract dates
    Time dif2 = time.sub(d.time); //subtract times
    dif2.day += dif1; //increment day counter by change in dates
    return dif2; //return result
  }
  
  public DateTime mean(DateTime d) { //finds the mean between the two dates
    Time midTime = time.add(d.time).half(); //find the mean between the two times
    Date midDate = new Date((date.day+d.date.day)>>1); //find the mean between the two days
    if(((date.day^d.date.day)&1)==1) { midTime.hour+=12; } //if the sum of the days is odd, add 12 hours
    return new DateTime(midDate,midTime);
  }
  
  public Weekday dayOfWeek() { return date.dayOfWeek(); } //day of the week
}
public static enum EntryType { //it's useful to classify entries in an equation into types. Namely, literals, constants, left-associative operators, right-associative operators, left unary operators, right unary operators, left parentheses, right parentheses, left-hand functions, right-hand functions, ???, commas, and unclassified
  NUM, CONST, LASSOP, RASSOP, LUNOP, RUNOP, LPAR, RPAR, LFUNC, COMMA, NONE;
  
  public boolean leftNum () { return this==NUM || this==CONST || this==LUNOP || this==LPAR || this==LFUNC; } //acts like a number on the left: numeral, constant, left unary operator, (, left function
  public boolean rightNum() { return this==NUM || this==CONST || this==RUNOP || this==RPAR;                } //acts like a number on the right: numeral, constant, right unary operator, )
  
  public boolean isMidOperator() { return this==LASSOP || this==RASSOP;                               } //is an operator that goes between two things
  public boolean    isOperator() { return this==LASSOP || this==RASSOP || this==LUNOP || this==RUNOP; } //is an operator (regardless of associativity or if it's unary)
  public boolean    hasLeftPar() { return this==LPAR   || this==LFUNC;                                } //has left parenthesis (thus needs to be closed)
}

public static class Entry {
  String id;      //string identifier
  EntryType type; //entry type
  byte prec;      //operator precedence
  short inps=-1;  //how many inputs it has (unset by default)
  
  MathObj asNum=null; //record the math object as a number (speeds up graphing)
  
  public Entry(String i) {
    id = i;                  //set ID
    type = getType(i);       //get entry type
    prec = getPrecedence(i); //get precedence
    inps = getInps(type);    //get inputs
  }
  
  public Entry(Equation eq) {
    id = "Equation";
    type = EntryType.NUM; prec = 0;
    asNum = new MathObj(eq);
  }
  
  private Entry(String i, EntryType ty, byte pr) {
    id=i; type = ty; prec = pr; //set the id, type, & precision
  }
  
  public Entry setInps(int i) { inps = (short)i; return this; }
  
  @Override
  public Entry clone() {
    return new Entry(id, type, prec);
  }
  
  //@Override
  public boolean equals(Entry e) {
    return id.equals(e.id);
  }
  
  public static EntryType getType(String i) { //infers the entry type from the string identification
    
    boolean isDouble = true; //try to cast to double
    try { Double.parseDouble(i); }
    catch(NumberFormatException e) { isDouble = false; }
    
    if(isDouble) { return EntryType.NUM; } //can be cast to double: numeral type
    if(i.length()==1 && Character.isLetter(i.charAt(0))) { return EntryType.CONST; } //is a letter: constant type
    for(String s : Equation.varList) { if(s.equals(i)) { return EntryType.CONST; } } //is part of the variable list: constant type
    if(!i.equals("(") && i.charAt(i.length()-1)=='(' || i.equals("[") || i.equals("{")) { return EntryType.LFUNC; } //ends in left parenthesis (or is left bracket/curly brace): left function type
    
    for(String m : Month.matchers) { //try to see if this is a date
      if(i.startsWith(m)) { return EntryType.CONST; } //if it begins with a date, it's a "number"
    }
    
    switch(i) {
      case "+": case "-": case "*": case "/": case "//": case "%":
      case "·": case "•": case "×":
      case "&": case "|": case "&&": case "||": case "==": case "!=":
      case "=": case "<": case ">": case "<=": case ">=": case ":":
      case "?:": case "\\": case "_":                                return EntryType.LASSOP; //these are all left associative operators
      case "^": case "?":                                            return EntryType.RASSOP; //^, ? are right associative operators
      case "(":                                                      return EntryType.LPAR;   //(: left parenthesis
      case ")": case "]": case "}":                                  return EntryType.RPAR;   //): right parenthesis
      case "²": case "³": case "!":                                  return EntryType.RUNOP;  //right function type
      case "(-)": case "~":                                          return EntryType.LUNOP;  //left unary operator
      case ",":                                                      return EntryType.COMMA;  //comma
    }
    return EntryType.NONE; //otherwise, you done fucked up
  }
  
  public static byte getPrecedence(String i) { //infers the operator precedence from the string identification
    if(i==null) { return 0; } //special case: return 0
    
    switch(i) {
      case ":=": return 1; //assignment: lowest precedence (not yet implemented)
      case "?": case ":": case "?:": return 2; //ternary: next precedence
      
      //boolean
      case "||": return 3; //OR: lowest precedence
      case "&&": return 4; //AND: next precedence
      
      case "|": return 5; //bitwise OR
      //RIGHT BETWEEN THESE TWO COMES XOR, but currently, XOR is just the caret, which has extremely high precedence
      case "&": return 6; //bitwise AND
      
      //comparisons
      case "=": case "==": case "!=":           return 7; //tests for equality
      case "<": case ">": case "<=": case ">=": return 8; //inequalities
      
      //theoretically, bit shifting operators would go here, but as of now, I have no intention to implement them
      
      //arithmetic
      case "+": case "-":                                 return  9; //lowest precedence: +/-
      case "*": case "/": case "%": case "//": case "\\": return 10; //next precedence: times, divide, modulo, truncated divide, left divide
      case "·": case "•": case "×":                       return 11; //dot and cross product have higher precedence, so that they can be performed before scalar multiplication
      case "(-)": case "~":                               return 12; //negation and other unary operators have higher precedence
      case "^": case "²": case "³": case "!":             return 13; //highest precedence: exponent (and factorial)
      
      case "_":                                           return 14; //subscript operator: even higher precedence
    }
    
    return 0; //for pretty much anything else, precedence doesn't even apply
  }
  
  public static short getInps(EntryType t) { //infers how many inputs it should have from the entry type
    switch(t) {
      case LASSOP: case RASSOP: return 2; //2 input operators have 2 inputs
      case LUNOP: case RUNOP: return 1; //unary operators have 1 input
      case LPAR: case LFUNC: return 1;  //functions START with 1 input
      default: return 0;                //anything else has 0 inputs
    }
  }
  
  public String      getId() { return   id; }
  public EntryType getType() { return type; }
  public int getPrecedence() { return prec; }
  public int   getInputNum() { return inps; }
  
  public boolean leftNum() { return type.leftNum(); } //true if it can be treated like a number on the left
  public boolean rightNum() { return type.rightNum(); } //true if it can be treated like a number on the right
  public boolean isOperator() { return type.isOperator(); } //true if it's an operator (regardless of associativity)
  public boolean hasLeftPar() { return type.hasLeftPar(); } //true if it has a left parenthesis (needs closing)
  
  //Sometimes, entries must cooperate to make the syntax correct, such as the ternary operators, or the NAND or NOR operators chaining together to represent collective NAND/NOR
  //this function checks to see if the given 2 entries are meant to cooperate. If they are, it returns an entry representing their combined efforts. Otherwise, it returns null
  public static Entry cooperate(Entry a, Entry b) {
    if(a.id.equals("?") && b.id.equals(":")) { return new Entry("?:").setInps(3); } //ternary operators have to cooperate
    
    if(a.id.equals("abs(") && b.id.equals("²")) { return new Entry("abs²("); } //abs and ² cooperate to form the absolute square
    
    return null; //everything else: return null
  }
  
  //public static boolean isLetter(char c) { return c>='A' && c<='Z' || c>='a' && c<='z'; }
}
public static class EquatList { //a class for holding the list of equations to be graphed out
  
  ////////////////// ATTRIBUTES ///////////////////
  
  static class EquatField { //class for holding all the things necessary to find our equation
    Panel panel; //the display console
    Textbox typer; //what we type into
    Graphable plot; //the thing this graphs out
    String cancel; //what the current unsaved typer will revert to when/if we press cancel
    
    EquatField(final Panel pn, final Textbox t, final Graphable pl, final String c) { panel=pn; typer=t; plot=pl; cancel=c; }
  }
  
  Mmio mmio; //the mmio system we're apart of
  
  Panel holder2D, holder3D, bigHolder; //a panel for holding the 2D equation list, one for the 3D equation list, and one to hold whichever one is visible, plus all its buttons
  
  ArrayList<EquatField> equats2D = new ArrayList<EquatField>(), //all our 2D equations
                        equats3D = new ArrayList<EquatField>(); //all our 3D equations
  
  //Textbox equatCache; //a pointer to the equation textbox we're currently typing into. When we edit the color, then press enter, we should go back to typing into this textbox.
  EquatField equatCache; //a pointer to the equation that's currently selected.
  //When we edit the color, then press enter, we should go back to editing this equation
  
  Textbox colorSelect; //textbox used to change the selected equation's color
  
  Graph   grapher2D; //the grapher used to graph in 2D
  Graph3D grapher3D; //the grapher used to graph in 3D
  
  byte axisMode = 0; //0=nothing, 1=axes, 2=axes+labels
  ConnectMode connect = ConnectMode.POINT; //how 3D graphs connect their points
  boolean graphDim = false; //graph dimensions (false=2d, true=3d)
  
  float equationHeight; //the height of each equation textbox
  float caretThick;     //how thick the caret is
  float buffX, buffY;   //buffer in the x & y direction
  
  final private ArrayList<Graphable> plots2D = new ArrayList<Graphable>(), plots3D = new ArrayList<Graphable>();
  
  ///////////////////////////////// CONSTRUCTORS ////////////////////////////////////////////
  
  EquatList(final Mmio parent, float x, float y, float w, float h, final Button palette, final float buttHig, final float equatHeight, final float inpBuffX, final float inpBuffY, final float thick) {
    mmio = parent; //set the panel parent
    
    bigHolder = new Panel(x,y,w,h,w,h); //create the panel that holds all this together
    bigHolder.setSurfaceFill(0).setStroke(0xff00FFFF).setParent(parent).setActive(false); //set the fill, stroke, parent, and whether it is currently active (it's not)
    
    equationHeight = equatHeight; //set equation height
    caretThick = thick; //set the caret thickness
    buffX = inpBuffX; buffY = inpBuffY; //set the input buffer
    
    holder2D = new Panel(0,buttHig,w,h-2*buttHig).setDragMode(DragMode.NONE, pcOrMobile ? DragMode.NONE : DragMode.ANDROID).setScrollableY(true); //create the list of 2D equations
    holder2D.setSurfaceFill(0).setStroke(0xff00FFFF).setParent(bigHolder);
    holder2D.setPixPerClickV(2*holder2D.pixPerClickV); //double the vertical scroll rate
    
    holder3D = new Panel(0,buttHig,w,h-2*buttHig).setDragMode(DragMode.NONE, pcOrMobile ? DragMode.NONE : DragMode.ANDROID).setScrollableY(true); //create the list of 3D equations
    holder3D.setSurfaceFill(0).setActive(false).setStroke(0xff00FFFF).setParent(bigHolder);
    holder3D.setPixPerClickV(2*holder3D.pixPerClickV); //double the vertical scroll rate
    
    //next, we have to create all the buttons
    final float buttWid = 0.25f*w; //the width of all buttons
    Button equationAdder  = (Button)new Button(0  *buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Add",0xff00FFFF); //this adds equations
    Button mode2D         = (Button)new Button(    buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("2D" ,0xff00FFFF); //this swaps from 2D to 3D
    Button mode3D         = (Button)new Button(    buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("3D" ,0xff00FFFF).setActive(false); //swaps from 3D to 2D
    Button equationDelete = (Button)new Button(3  *buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Delete",0xff00FFFF);    //deletes currently selected equation
    Button equationUp     = (Button)new Button(2  *buttWid,0,0.5f*buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("  ▲  ",0xff00FFFF); //the up & down buttons are half as wide as the rest
    Button equationDown   = (Button)new Button(2.5f*buttWid,0,0.5f*buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("  ▼  ",0xff00FFFF);
    
    Button equationCanceler  = (Button)new Button(0        ,h-buttHig,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Cancel"  ,0xff00FFFF); //cancels changes
    Button equationVisToggle = (Button)new Button(  buttWid,h-buttHig,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Visible?",0xff00FFFF); //toggles visibility
    Button equationMode      = (Button)new Button(2*buttWid,h-buttHig,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Mode"    ,0xff00FFFF); //sets graphing mode
    
    final float colorSelectSize = 0.035555556f*w;
    colorSelect = (Textbox)new Textbox(3*buttWid,h-buttHig,buttWid,buttHig).setSurfaceFill(0xff001818).setStroke(0xff00FFFF).setParent(bigHolder); //textbox that allows you to change the selected equation's color
    colorSelect.setTextSizeAndAdjust(colorSelectSize); //change the text size
    colorSelect.setOnRelease(new Action() { public void act() { if(equatCache!=null) { //make it so, when you click on the color select box (and an equation is selected):
      mmio.setTyper(colorSelect); //it causes you to select the color select box
    } } });
    
    equationAdder.setOnRelease(new Action() { public void act() {
      addEquation(); //add equation at the specified index
    } });
    
    mode2D.setOnRelease(new Action() { public void act() { changeGraphDims(); updateColorSelector(); } }); //make both buttons change graph dimensions (and reset the color selector)
    mode3D.setOnRelease(new Action() { public void act() { changeGraphDims(); updateColorSelector(); } });
    
    equationUp.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      int ind = getEquatIndex(); //grab index
      swapEquations(ind-1,ind);  //swap this equation w/ the one above
      equatCache.typer.resetBlinker(); //make the caret visible
    } } });
    
    equationDown.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      int ind = getEquatIndex(); //grab index
      swapEquations(ind+1,ind);  //swap this equation w/ the one below
      equatCache.typer.resetBlinker(); //make the caret visible
    } } });
    
    equationDelete.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      deleteEquation(); //delete the current equation
    } } });
    
    equationCanceler.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      cancelEquation(equatCache); //cancel the currently selected equation
      mmio.setTyper(null); equatCache=null; updateColorSelector(); //reset stuffs
    } } });
    
    equationVisToggle.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      if(equatCache.plot.visible ^= true) { //invert the visibility. If it is now visible:
        ungray(equatCache);                 //un-gray out the equation
      }
      else {              //if it is now currently invisible:
        gray(equatCache); //gray out the equation
      }
      saveEquationsToDisk(mmio.app, graphDim); //save changes to disk
    } } });
    
    equationMode.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      equatCache.plot.mode = equatCache.plot.mode.increment(); //switch the current mode to whatever I've decided is the next graphing mode (the loops are {NONE}, {RECT2D,POLAR,PARAMETRIC2D}, and {RECT3D,CYLINDRICAL,SPHERICAL,PARAMETRIC3D})
      
      ctrlPanel.swapGraphMode(equatCache.plot.mode); //correctly update the buttons based on this new graphing mode
      equatCache.panel.text[0].text = equatCache.plot.mode.outVar()+"="; //correctly update the output variable (e.g. y, r, z, v, ρ, etc)
      
      saveEquationsToDisk(mmio.app, graphDim); //save changes to disk
    } } });
  }
  
  ////////////////// GETTERS / SETTERS //////////////////////////
  
  public void setActive(final boolean active) { bigHolder.setActive(active); }
  
  public Panel getHolder(boolean dim) { return      dim ? holder3D : holder2D; } //returns the equation holder for the equations we're looking at
  public Panel getHolder()            { return graphDim ? holder3D : holder2D; } //returns the equation holder for the equations we're using right now
  
  public ArrayList<EquatField> getEquats(boolean dim) { return      dim ? equats3D : equats2D; } //returns the list of equations given the dimension you're looking for
  public ArrayList<EquatField> getEquats()            { return graphDim ? equats3D : equats2D; }
  
  public int getEquatIndex(boolean dim, EquatField field) { //obtains the index of the given field
    return getEquats(dim).indexOf(field); //return the index of the given item within the list
  }
  public int getEquatIndex() { //obtains the index of the currently selected equation
    return getEquatIndex(graphDim, equatCache); //return the index of the equation cache within the current list
  }
  
  public int size(boolean dim) { return      dim ? equats3D.size() : equats2D.size(); }
  public int size()            { return graphDim ? equats3D.size() : equats2D.size(); }
  
  public EquatField get(boolean dim, int ind) { return      dim ? equats3D.get(ind) : equats2D.get(ind); }
  public EquatField get(             int ind) { return graphDim ? equats3D.get(ind) : equats2D.get(ind); }
  
  public ArrayList<Graphable> plots2D() {
    plots2D.clear(); for(EquatField e : equats2D) { plots2D.add(e.plot); } return plots2D;
  }
  
  public ArrayList<Graphable> plots3D() {
    plots3D.clear(); for(EquatField e : equats3D) { plots3D.add(e.plot); } return plots3D;
  }
  
  ////////////////////// UPDATES //////////////////////////////
  
  public void updateColorSelector() { //updates the color selection textbox
    if(equatCache==null) { //if no equations are selected
      colorSelect.clear2();                //clear the color selection box
      colorSelect.setSurfaceFill(0xff001818); //make it dark cyan
    }
    
    else { //otherwise
      int stroke = equatCache.plot.stroke; //grab the stroke of the currently selected equation
      colorSelect.setSurfaceFill(stroke);    //set the background of this textbox to that color
      int contrast = saturate(~stroke);    //find the inverse of that color, then overly saturate it
      colorSelect.setTextColor(contrast);    //set the text color to that
      colorSelect.setCaretColor(contrast);   //set the caret color to that
      String config = ((stroke>>16)&255) + "," + ((stroke>>8)&255) + "," + (stroke&255); //generate the string that shows the red, green, blue
      colorSelect.replace(config); //set the contents of the text field to that
    }
  }
  
  public void updateSubscripts(boolean dim) { //updates all the subscripts in the equation list
    for(int n=0;n<size(dim);n++) {            //loop through said list
      get(dim,n).panel.text[1].text = n+1+""; //update each panel's subscript text
    }
  }
  
  public void updateCheckmarks() { //looks at the currently selected equation, checks if it's different from its original form. Gives it a checkmark iff it's the same
    if(equatCache==null) { return; } //if there is no selected equation, do nothing.
    String mark;
    if(equatCache.typer.getText().equals(equatCache.cancel)) { mark = "✓"; } //strings are the same: set text to checkmark
    else { mark = ""; }                    //otherwise: set it to empty
    equatCache.panel.text[2].text = mark; //set the text right above the equals sign
  }
  
  public void updateSurfaceHeight(boolean dim) { //updates the height of the holder's surface
    if(size(dim)==0) { //special case: there are no equations
      getHolder(dim).setSurfaceH(getHolder(dim).h); //just set it to the height
    } else { //otherwise
      Box secret = get(dim,size(dim)-1).panel; //grab the last box
      getHolder(dim).setSurfaceH(max(getHolder(dim).h, secret.y+secret.h)); //change surface height to either the height of the window, or to the distance to the bottom (whichever's bigger)
    }
  }
  
  public void updateSurfaceHeight() { updateSurfaceHeight(graphDim); } //updates the height of the current holder's surface
  
  ////////////////// UTILITIES ///////////////////////////////
  
  public EquatField buildEquation(boolean dim, int index, float y, int stroke, boolean vis, GraphMode mode, String text) { //builds a panel for us to put our equation in (returns the panel and the inner textbox)
    final Panel pan = (Panel)new Panel(0,y,bigHolder.w,equationHeight).setSurfaceFill(0).setStroke(0xff00FFFF).setParent(getHolder(dim)); //declare new panel for us to put our equation in
    pan.setScrollable(false,false).setDragMode(DragMode.NONE,DragMode.NONE); //make it impossible to scroll or drag
    
    float xOffset = mmio.getTextWidth("y=",Mmio.invTextHeight(equationHeight-2*Mmio.yBuff));
    final Textbox tbox = givePanelEquation(pan, dim, text, xOffset); //give us an equation textbox to type into
    tbox.setMargin(relativeMarginWidth*mmio.w);                      //give us a sizable margin to make it easier to move the caret
    tbox.setHandleParent(getHolder(dim));                            //staple any and all applicable text handles to the equation holder
    
    float offset2 = 0.027272727f*bigHolder.w, offset3 = 0.05f*bigHolder.w, offsetY = 0.048888889f*bigHolder.h, offsetY2 = 0.0f*bigHolder.h; //constants for initialization
    pan.setText(new Text(mode.outVar()+"=",pan.xSpace,tbox.ty,tbox.tSize,0xff00FFFF,LEFT,TOP),             //provide the y= at the beginning
                new Text(index+"",pan.xSpace+offset2,tbox.ty+offsetY,0.45f*tbox.tSize,0xff00FFFF,LEFT,TOP), //as well as a subscript
                new Text("✓",pan.xSpace+offset3,tbox.ty+offsetY2,0.45f*tbox.tSize,0xff008000,LEFT,TOP));    //and a checkmark
    
    Graphable grapher = new Graphable(stroke,new Equation(new ParseList(""))); //load empty graphable
    grapher.setMode(mode); //set its mode
    if(dim) { grapher.setSteps(80); } //to stop this from breaking, set 3D functions to 80 steps TODO remove when graphing is optimized
    
    final EquatField result = new EquatField(pan, tbox, grapher, ""); //create equation field with the correct panel, textbox, graphable, and an empty cancel string
    
    if(!vis) { grapher.setVisible(false); gray(result); }
    
    tbox.setOnRelease(new Action() { public void act() { //set what happens when we click on this textbox
      mmio.setTyper(tbox); equatCache=result; //when we click on an equation textbox, we select it
      updateColorSelector();                  //update the color selection box
      
      ctrlPanel.swapGraphMode(result.plot.mode); //swap our keypad buttons depending on the new mode of this button
    } });
    
    saveEquation(result); //save the equation
    
    return result; //return our result
  }
  
  public Textbox givePanelEquation(Panel pan, boolean dim, String text, float xOffset) { //takes a panel and gives it an equation
    final Textbox tbox = new Textbox(xOffset,0,getHolder(dim).w-xOffset,equationHeight).setCaretColor(0xff00FFFF).setTextColor(0xff00FFFF); //declare textbox for us to type our equation in
    tbox.setSurfaceFill(0).setStroke(false).setParent(pan);
    tbox.setScrollable(pcOrMobile,false).setDragMode(pcOrMobile ? DragMode.NONE : DragMode.ANDROID,DragMode.NONE); //make it move correctly (either pc or mobile)
    tbox.setTextPosAndAdjust(buffX,buffY); tbox.setCaretThick(caretThick); //TODO see if this is messing up our alignment
    
    if(text.length()!=0) { tbox.replace(text); } //input the given text
    
    return tbox; //return result
  }
  
  public static void gray(final EquatField eq) { //grays out equation
    eq.panel.setSurfaceFill(0xff555555); //make the panel gray
    eq.typer.setSurfaceFill(0xff555555); //make the textbox gray
    eq.typer.setTextColor(0xffAAAAAA); eq.typer.setCaretColor(0xffAAAAAA); //make the textbox's text & caret a light gray
    for(Text t : eq.panel.text) { t.fill=0xffAAAAAA; } //make all of the text on the panel light gray
  }
  
  public static void ungray(final EquatField eq) { //un-grays out equation
    eq.panel.setSurfaceFill(0); //make the panel black
    eq.typer.setSurfaceFill(0); //make the textbox black
    eq.typer.setTextColor(0xff00FFFF); eq.typer.setCaretColor(0xff00FFFF); //make the textbox's text & caret cyan
    for(Text t : eq.panel.text) { t.fill=0xff00FFFF; } //make all the text on the panel cyan
    eq.panel.text[2].fill=0xff008000; //except the checkmark, make that dark green
  }
  
  public void saveEquationColor(boolean save) { //updates and saves the color of the equation
    String text = colorSelect.getText(); //grab the text within the color select field
    
    boolean worked = false;
    if(text.startsWith("#")) { //first, check if it's typed with hex codes
      int col = 0; worked = true;
      try { col = 0xFF000000 | unhex(text.substring(1)); }
      catch(NumberFormatException ex) { worked = false; }
      
      if(worked) { equatCache.plot.stroke = col; }
    }
    
    if(!worked) {
      String[] rgb = text.split(",");      //split it up by commas
      
      if(rgb.length==3) { //if there are exactly 3 things separated by commas:
        worked = true;      //try to figure out if they're all valid numbers
        int red=0, green=0, blue=0; //red, green, and blue
        try {
          red = Integer.parseInt(rgb[0]); green = Integer.parseInt(rgb[1]); blue = Integer.parseInt(rgb[2]); //parse all 3 strings into integers
          worked = red==(red&255) && green==(green&255) && blue==(blue&255); //this worked if they're all between 0 and 255
        }
        catch(Exception ex) { worked = false; } //if they were unparseable, this didn't work
        
        if(worked) { //if this worked:
          equatCache.plot.stroke = 0xFF000000 | red<<16 | green<<8 | blue; //parse result into color, set the plot color
        }
      }
    }
    
    mmio.setTyper(equatCache.typer); //go back to typing in the equation box
    updateColorSelector();           //update the color selector
    if(save) { saveEquationsToDisk(mmio.app,graphDim); } //if we want to save, save
  }
  
  ////////////////// FUNCTIONALITY //////////////////////////////
  
  public EquatField addEquation(boolean dim, int index, int stroke, boolean vis, GraphMode mode, String text) {
    float buttY; //We have to figure out the y position of the new plottable equation
    if(index==0) { buttY = 0; } //if this is the first equation, it goes at the top (y=0)
    else { Box secret = get(dim,index-1).panel; buttY = secret.y+secret.h; } //otherwise, select the position right below our "secret box" (the box above this one)
    
    final EquatField equat = buildEquation(dim, index, buttY, stroke,vis,mode,text); //create new equation
    
    getEquats(dim).add(index, equat); //add this equation to our list, at the correct index
    for(int n=index+1;n<size(dim);n++) { //loop through all equations after this one (we need to move them down)
      Box secret = get(dim,n-1).panel; get(dim,n).panel.setY(secret.y+secret.h); //move their y position to right below the box above them
    }
    
    updateSurfaceHeight(dim); //update the height of our surface
    
    updateSubscripts(dim); //update the subscripts for each equation
    
    saveEquationsToDisk(mmio.app,dim); //save our current equation list to disk
    
    return equat; //return result
  }
  
  public void addEquation() { //TODO make me more reusable!!!
    Panel holder = getHolder(); //grab the equation list we're referencing
    
    int index = equatCache==null ? getHolder().numChildren() : getEquatIndex()+1; //first, we have to find the index we want to place this equation at
    //if an equation is selected, we wanna put this right after that. Otherwise, we put this right at the very end
    EquatField equat = addEquation(graphDim, index, 0xffFF8000,true,graphDim?GraphMode.RECT3D:GraphMode.RECT2D,""); //add the equation
    
    mmio.setTyper(equat.typer); equatCache=equat; //select this equation for typing into
    equat.typer.resetBlinker();                   //make the caret visible
    holder.chooseTargetRecursive(0.5f*holder.w,equat.panel.y+holder.ySpace,0.5f*holder.w,equat.panel.y+equat.panel.h-holder.ySpace); //choose a target so that we can see our new equation
    
    ctrlPanel.swapGraphMode(graphDim ? GraphMode.RECT3D : GraphMode.RECT2D); //display the x key (and maybe the y key)
    updateColorSelector(); //update the color selector
  }
  
  public boolean deleteEquation(boolean dim, EquatField eq) { //removes a specific equation
    int ind = getEquatIndex(dim, eq); //find the index of the given equation
    if(ind==-1) { return false; } //if not found, return false
    
    getEquats(dim).remove(ind); //remove equation from the list of equations
    eq.panel.setParent(null);   //estrange from io family (so that it can be deleted)
    
    if(ind!=size(dim)) { //if the index ISN'T the last index (i.e. there are other equations after this one in the list)
      for(int n=size(dim)-1;n>ind;n--) { //loop through all equations after this one BACKWARDS (except the equation RIGHT after this one)
        get(dim,n).panel.setY(get(dim,n-1).panel.y); //set each panel's y position to that of the one before it
      }
      get(dim,ind).panel.setY(eq.panel.y); //move the equation right after the one we deleted to the position of the one we deleted
    }
    
    updateSubscripts(dim); //give every equation the correct subscript
    
    updateSurfaceHeight(dim); //update the given holder panel's surface height
    
    saveEquationsToDisk(mmio.app,dim); //save our current equation list to disk
    
    return true; //return true, since it was successful
  }
  
  public boolean deleteEquation() { //deletes the equation cache (returns false if unsuccessful
    if(equatCache==null) { return false; } //if there is no equation cache, return false since it was unsuccessful
    deleteEquation(graphDim, equatCache); //delete the equation cache from the current equation list
    
    equatCache = null; mmio.setTyper(null); //set the equation cache and the typer to null
    updateColorSelector(); //update the color selection box
    getHolder().chooseTargetRecursive(); //perform targeting to avoid being out of bounds
    
    return true; //return true because it was successful
  }
  
  public boolean swapEquations(final int ind1, final int ind2) { //takes two equations and swaps their indices (returns if it was successful)
    ArrayList<EquatField> equatList = getEquats(); //grab the equation list
    if(ind1<0 || ind2<0 || ind1>=size() || ind2>=size()) { return false; } //if their indices are out of bounds, do nothing & return false
    if(ind1==ind2) { return true; } //if the indices are the same, do nothing & return true
    
    EquatField first = get(ind1), second = get(ind2); //grab both equations
    equatList.set(ind1,second); equatList.set(ind2,first); //swap both equations
    float tempY = first.panel.y; first.panel.y = second.panel.y; second.panel.y = tempY; //swap their y positions
    
    updateSubscripts(graphDim); //update the subscripts
    saveEquationsToDisk(mmio.app,graphDim); //save our current equation list to disk
    
    return true; //return true because it was successful
  }
  
  public void changeGraphDims() { //changes the graph dimensions
    graphDim ^= true; //swap graph dimensions
    
    holder2D.setActive(!graphDim); holder3D.setActive(graphDim); //swap which equation list we can see
    equatCache = null; mmio.setTyper(null); //set our equation cache and typer to null
    
    for(Box b : bigHolder) { //find the 2D and 3D buttons in the equation holder
      if(b.text.length!=0 && b.text[0].getText().equals("2D")) { b.setActive(!graphDim); } //make the 2D button active IFF we're in 2D mode
      if(b.text.length!=0 && b.text[0].getText().equals("3D")) { b.setActive( graphDim); } //make the 3D button active IFF we're in 3D mode
    }
    for(Box b : graphMenu) { //do the same thing for the graph menu
      if(b.text.length!=0 && b.text[0].getText().equals("2D")) { b.setActive(!graphDim); }
      if(b.text.length!=0 && b.text[0].getText().equals("3D")) { b.setActive( graphDim); }
    }
    
    if(grapher2D.visible || grapher3D.visible) { //if either graph is visible:
      grapher2D.setVisible(!graphDim); //make this active IFF in 2D mode
      grapher3D.setVisible( graphDim); //make this active IFF in 3D mode
    }
    
    String axisButton = axisMode==0 ? "Axes" : axisMode==1 ? "Labels" : "None";
    String connectButton = connect==ConnectMode.POINT ? "Points" : connect==ConnectMode.WIREFRAME ? "Wireframe" : "Surface";
    for(Box b : graphMenu) {
      if(b.text[0].getText().equals("Roots")) { ((Button)b).setActive(!graphDim); }
      else if(b.text[0].getText().equals("Inters.")) { ((Button)b).setActive(!graphDim); }
      else if(b.text[0].getText().equals(axisButton)) { ((Button)b).setActive(graphDim); }
      else if(b.text[0].getText().equals(connectButton)) { ((Button)b).setActive(graphDim); }
    }
    
    if(bigHolder.active) { ctrlPanel.swapGraphMode(graphDim ? GraphMode.RECT3D : GraphMode.RECT2D); }
  }
  
  public void cancelEquation(EquatField eq) {
    eq.typer.replace(eq.cancel); //replace text with original text
    eq.panel.text[2].text = "✓"; //give equation a checkmark
  }
  
  public boolean saveEquation(EquatField eq) { //saves equation (returns whether it was successful)
    if(eq==null) { return false; } //special case: null equation, don't save
    
    if(eq.typer.getText().length()==0) { //if the equation is completely empty:
      eq.plot.function = new Equation(new ParseList("")); //set the plot at that index so that it graphs this empty equation
      eq.cancel = "";                                     //set the cancel history at that index so it stores this empty string
    }
    
    else {
      ParseList parse = new ParseList(eq.typer.getText()); //create parselist from typed text
      parse.format(); //format the parselist
      
      Equation equat = new Equation(parse); //format to an equation
      equat.correctAmbiguousSymbols();      //correct ambiguous symbols
      equat.squeezeInTimesSigns();          //squeeze in * signs where applicable
      equat.setUnaryOperators();            //convert + and - to unary operators where appropriate
      
      String valid = equat.validStrings();
      if(!valid.equals("valid"))                              { /*display error message*/ return false; }
      else if(!(valid=equat.    validPars()).equals("valid")) { /*display error message*/ return false; }
      else if(!(valid=equat.leftMeHanging()).equals("valid")) { /*display error message*/ return false; }
      else if(!(valid=equat.  countCommas()).equals("valid")) { /*display error message*/ return false; }
      else {
        equat = equat.shuntingYard(); //convert from infix to postfix
        equat.parseNumbers();         //parse the numbers
        equat.arrangeRecursiveFunctions(); //implement recursive functions
        
        eq.plot.function = equat;       //set the plot to graph this equation
        eq.plot.verify1DParametric();   //check to see if it's a 1D parametric curve
        eq.cancel = eq.typer.getText(); //update the cancel string to the current input
      }
    }
    
    eq.panel.text[2].text = "✓"; //since the equation has been saved, give it a checkmark
    return true; //return true, since the equation has been saved
  }
  
  public boolean saveEquation(boolean save) { //saves the currently selected equation (returns whether it was successful)
    if(saveEquation(equatCache)) { //save the equation cache. if successful:
      mmio.setTyper(null); equatCache=null; //deselect equation
      updateColorSelector();                //update the color select
      if(save) { saveEquationsToDisk(mmio.app,graphDim); } //if asked to save to disk, save to disk
      return true; //return true
    }
    return false; //otherwise, return false
  }
  
  public void clearEquations(boolean dim) {
    for(EquatField eq : getEquats(dim)) { //loop through all equations
      eq.panel.setParent(null); //have their panels estrange (so they get removed by gc)
    }
    getEquats(dim).clear(); //clear the list of equations
    updateSurfaceHeight(dim); //update the equation list panel's surface height
    
    equatCache = null; mmio.setTyper(null); //set the equation cache and the typer to null
    updateColorSelector(); //update the color selection box
    getHolder().chooseTargetRecursive(); //perform targeting to avoid being out of bounds
    
    saveEquationsToDisk(mmio.app,dim); //save changes to disk
  }
  
  public void clearEquations() { clearEquations(graphDim); }
  
  
  //methods to add, move, delete, cancel, toggle visibility, change graph mode, change color
  //methods to save, update subscripts, etc.
}
public static class Equation implements Iterable<Entry> {
  
  ArrayList<Entry> tokens = new ArrayList<Entry>(); //all the entries in the equation
  
  public Equation() { }
  
  public Equation(ParseList p) {
    for(String s : p) {
      tokens.add(new Entry(s)); //add each token
    }
  }
  
  private Equation(ArrayList<Entry> toks) { tokens = toks; } //set each token individually
  
  @Override
  public String toString() {
    String res = "";
    for(Entry s : tokens) { res+=s.getId()+", "; }
    return res;
  }
  
  public int size() { return tokens.size(); }
  public Entry get(int i) { return tokens.get(i); }
  public void add(Entry e) { tokens.add(e); }
  public void add(int i, Entry e) { tokens.add(i,e); }
  public void remove(int i) { tokens.remove(i); }
  
  public boolean isEmpty() { return size()==0 || size()==2 && tokens.get(0).id.equals("(") && tokens.get(1).id.equals(")"); }
  
  @Override
  public Iterator<Entry> iterator() {
    return tokens.iterator();
  }
  
  public void correctAmbiguousSymbols() { //corrects symbols that are ambiguous in meaning (such as ! being used for factorial or logical negation)
    for(int n=1;n<size();n++) { //loop through all entries (except the first)
      Entry curr = get(n), trail = get(n-1); //record current & previous entries
      
      if(curr.getId().equals("!") && !trail.rightNum()) { //if this entry is a !, and the previous entry WASN'T the right of a number:
        tokens.set(n,new Entry("~"));                     //replace the ! with the NOT symbol
      }
    }
  }
  
  public void squeezeInTimesSigns() { //squeezes * signs between adjacent numbers
    for(int n=1;n<size();n++) { //loop through every token (except the initial ( at the beginning)
      Entry curr = get(n), trail = get(n-1); //get the current & previous entries
      
      if(curr.leftNum() && trail.rightNum()) { //2 adjacent numbers:
        tokens.add(n,new Entry("*"));        //squeeze a * sign between them
        ++n;                                 //move 1 right
      }
    }
  }
  
  public void setUnaryOperators() { //changes lone + and - signs to unary operators
    for(int n=1;n<size();n++) { //loop through every token (except the initial ( at the beginning)
      Entry curr = get(n), trail = get(n-1); //record current & previous entries
      if((curr.getId().equals("+") || curr.getId().equals("-")) && !trail.rightNum()) { //if this is a + or -, and the previous token isn't a number:
        if(curr.getId().equals("+")) { tokens.remove(n); --n;          } //+: remove token & go back 1 step TODO see if this is a mistake, i.e. if there are cases where this is syntactically inaccurate
        else                         { tokens.set(n,new Entry("(-)")); } //-: swap minus sign with negation
      }
    }
  }
  
  public String validStrings() {
    for(Entry e : this) {
      if(e.getType()==EntryType.NONE) { return "Error: \""+e.getId()+"\" is not a valid token"; }
    }
    return "valid";
  }
  
  public String validPars() { //checks that all parentheses are closed (returns a message about its validity)
    int parVar = 0; //# of ( minus # of ) (if ever negative, config is invalid)
    for(int n=1;n<size()-1;n++) { //loop through all entries (except the 1st & last)
      Entry e = get(n);
      switch(e.getType()) {
        case LPAR: case LFUNC: ++parVar; break; //left ( or left func: increment
        case RPAR:             --parVar; break; //right ): decrement
        default:
      }
      if(parVar<0) { return "Error: unclosed right parentheses"; } //if parvar is ever negative, configuration is invalid
    }
    return (parVar==0) ? "valid" : "Error: unclosed left parentheses"; //return valid iff # of ( == # of )
  }
  
  public String leftMeHanging() { //tests for an error I call "left me hanging"
    for(int n=1;n<size();n++) { //loop through all entries (except the first)
      Entry curr = get(n), trail = get(n-1); //record current & previous entries
      EntryType first = trail.getType(), second = curr.getType();
      
      if(!first.rightNum() && !second.leftNum()) { //an operator, left unary, left function, (, or comma is followed by an operator, right unary, ), or comma
        if(first.hasLeftPar() && second==EntryType.RPAR) { trail.inps=0; }    //special case: a ( or left function followed by a ): this isn't an error, but rather a function w/ 0 inputs
        else { return "Error: "+trail.getId()+" followed by "+curr.getId(); } //otherwise, return an error message
      }
    }
    return "valid"; //no error encountered: return valid
  }
  
  public String countCommas() { //tests for functions with the wrong number of commas
    Stack<Entry> records = new Stack<Entry>(); //a stack of functions (bottom=outermost, top=innermost)
    for(Entry curr : this) { //loop through all the entries
      
      if(curr.getType().hasLeftPar()) { //if this has a left parenthesis,
        records.push(curr);             //push it onto the stack
      }
      else if(curr.getType()==EntryType.COMMA) { //if it's a comma:
        Entry e = records.peek(); //record the current top of the stack
        e.inps++;                 //increment the number of inputs
        if(e.inps > functionDictionary.minMax.get(e.id)[1]) { return "Error: too many inputs for function "+e.id; } //if too many, return message saying so
      }
      else if(curr.getType()==EntryType.RPAR) { //if this has a right parenthesis,
        Entry e = records.peek(); //record the current top of the stack
        if(e.inps < functionDictionary.minMax.get(e.id)[0]) { return "Error: too few inputs for function "+e.id; } //if too few inputs, return message saying so
        if(!parenthesesMatch(e.id,curr.id)) { return "Error: cannot close \""+e.id+"\" with \""+curr.id+"\""; } //if the parentheses match incorrectly, return a message saying so
        records.pop(); //pop this off the stack
      }
    }
    
    return "valid"; //no error encountered: return valid
  }
  
  private static boolean parenthesesMatch(String a, String b) { //assuming a is a left parenthesis/left function, and b is a right parenthesis (of some kind), this function tells us if b is allowed to close a
    //return a.equals("[") == b.equals("]"); //for now, the only rule is that (a is [) XNOR (b is ])
    switch(a) {
      case "[": return b.equals("]");
      case "{": return b.equals("}");
      default : return b.equals(")");
    }
  }
  
  
  
  public Equation shuntingYard() { //performs the shunting yard algorithm on it (damages input)
    Stack<Entry> opStack = new Stack<Entry>(); //operator stack
    Equation output = new Equation();          //output
    
    while(size()!=0) { //perform the following loop until size is 0
      Entry curr = get(0); //grab first token
      Entry topOp;         //operator on top of stack
      
      switch(curr.getType()) { //each step is determined by the current token type
        case  NUM: case CONST:  output.add(curr); break; //number: move to end of output stack
        case LPAR: case LFUNC: case LUNOP: opStack.add(curr); break; //(, left operator, or left function: push to top of operator stack
        case LASSOP: case RASSOP: /*case LUNOP:*/ case RUNOP: { //operator:
          
          /*   SHUNTING YARD RULE FOR OPERATORS:
          push the top operator to the output stack as long as it hasn't a ( and also either
          ∙ is a right unary operator
          ∙ has greater precedence than the token (from the input stack)
          ∙ has equal precedence to the token and is left associative
          after that, you can push the current token to the operator stack */
          
          topOp = opStack.peek(); //get operator at top of stack
          boolean cooperates = false; //true in the special case that our operator cooperates with one of the operators in the stack
          
          while(!topOp.hasLeftPar() && (topOp.getType()==EntryType.RUNOP || topOp.getPrecedence() > curr.getPrecedence() ||
                topOp.getPrecedence()==curr.getPrecedence() && curr.getType()==EntryType.LASSOP)) { //loop through op stack based on above rules
            
            //first, see if these 2 operators cooperate
            Entry cooperate = Entry.cooperate(topOp,curr);
            if(cooperate!=null) { //if they do:
              opStack.pop(); opStack.push(cooperate); //replace top operator with its cooperation with curr
              cooperates = true; break;               //a cooperation occurred, break from the loop
            }
            
            //otherwise (AKA most of the time):
            output.add(topOp);      //push the top operator to the operator stack
            opStack.pop();          //pop top operator
            topOp = opStack.peek(); //replace top op
          }
          if(!cooperates) { opStack.push(curr); } //finally, push the current operator onto the operator stack (unless the operators cooperated)
        } break;
        case COMMA: { //comma
          while(!opStack.peek().hasLeftPar()) { //pop ops from stack until we find a function
            output.add(opStack.pop()); //push to output stack & pop from op stack
          }
        } break;
        case RPAR: { //right parenthesis
          while(!opStack.peek().hasLeftPar()) { //loop until top op can close the )
            output.add(opStack.pop()); //push to output stack & pop from op stack
          }
          topOp = opStack.pop(); //pop top of operator stack
          if(topOp.getType()==EntryType.LFUNC) { //if the operator was a function:
            output.add(topOp);                   //push it onto the output stack
          }
        } break; //TODO fuse the comma and rpar to keep it dry
        default:
      }
      remove(0); //pop first token
    }
    //println(output); //DEBUG
    return output; //return output
  }
  
  public void parseNumbers() { //parses all the numbers before solving (makes graphing and recursion easier)
    for(Entry entry : this) if(entry.getType()==EntryType.NUM) {
      entry.asNum = new MathObj(entry);
    }
  }
  
  //@return: in the end, we will find that our solve function separates this into n distinct equations. This returns what n is (n is supposed to be 1. If it's not, it's an error)
  public int arrangeRecursiveFunctions() { //this looks at all functions which recursively call other functions, then puts the latter functions into the former function's link
    
    ArrayList<ArrayList<Entry>> groups = new ArrayList<ArrayList<Entry>>(); //arraylist of grouped together entries. Each time we reach a function, we group together that function w/ its inputs
    
    for(int n=0;n<size();n++) { //loop through all entries
      Entry token = tokens.get(n); //grab the current entry
      switch(token.getType()) {
        case NUM: case CONST: { //number or constant:
          ArrayList<Entry> adder = new ArrayList<Entry>(1); adder.add(token); //create new group to add to the list
          groups.add(adder);                                                  //add group to the list
        } break;
        default: { //otherwise: (NOTE: all remaining types that weren't eliminated from previous functions will have their input number initialized)
          int[] linkGuide = recursiveCheck(token.getId()); //get which link needs to go where
          
          int zInd = groups.size()-token.inps; //locate the index of the zeroth input
          
          for(int k=0;k<linkGuide.length;k++) { //loop through all things we have to link to
            
            Equation equat = new Equation(groups.get(zInd+linkGuide[k])); //first, load the entry list at each link index, then convert them into an equation
            
            int ind = tokens.indexOf(equat.get(0)); //find where in the tokens list is the first entry of the equation
            for(int i=0;i<equat.size();i++) { //loop through all entries in the equation
              tokens.remove(ind); n--;        //remove each element, backtrack in the list
            }
            Entry link = new Entry(equat); //create an entry that links to the equation
            tokens.add(ind,link); n++;     //add this equation link to the token list, front track in the list
            ArrayList<Entry> replacement = new ArrayList<Entry>(1); replacement.add(link); //create an arraylist with just 1 element: this link
            groups.set(zInd+linkGuide[k],replacement); //remove this group, replace it with the equation it forms
          }
          //TODO check and see that this still works even if there are multiple links
          
          //zInd = groups.size()-token.inps; //reset the zeroth index
          for(int k=1;k<token.inps;k++) { //loop through all inputs after the 0th
            groups.get(zInd).addAll(groups.get(zInd+1)); //concatenate the next group onto the 0th group
            groups.remove(zInd+1);                       //remove that next group
          }
          
          if(token.inps==0) { //special case: 0 inputs in the function (or all the inputs were removed and made into links)
            ArrayList<Entry> adder = new ArrayList<Entry>(1); groups.add(adder); //create new group to add to the list (since it wasn't created by any of the 0 inputs)
          }
          
          groups.get(zInd).add(token); //concatenate this token onto the 0th group
        }
      }
      /*println();
      for(int k=0;k<groups.size();k++) {
        for(int i=0;i<groups.get(k).size();i++) { print(groups.get(k).get(i).getId()+", "); }
        println();
      }
      println();*/
    }
    //println(this); //DEBUG
    return groups.size(); //return how long this list is in the end
  }
  
  /*String detectVariableScope() { //returns whether or not each variable was declared in this scope
    //TODO this
  }*/
  
  public MathObj solve(HashMap<String, MathObj> mapper) {
    ArrayList<MathObj> out = new ArrayList<MathObj>(); //array of all the mathematical objects we analyze to read this
    
    for(Entry e : this) { //loop through all entries
      switch(e.getType()) { //switch the entry type
        case NUM: out.add(e.asNum.clone()); break; //number ("number"): add the already calculated number to the list
        case CONST: { //constant:
          MathObj vari = mapper.get(e.getId()); //grab the linked variable
          MathObj addMe;                        //variable to add
          if(vari==null) { addMe = new MathObj(e); } //if there is none, try casting it to a math Object
          else           { addMe = vari.clone();   } //otherwise, add the linked variable
          if(addMe.type==MathObj.VarType.NONE) { return new MathObj("Cannot evaluate variable \""+e.getId()+"\""); } //if we get nothing, return an error message
          out.add(addMe); //otherwise, add it to the list
        } break;
        case COMMA:
          println("HOW ARE THERE STILL COMMAS? I THOUGHT I KILLED YOU!!!"); //DEBUG
        break;
        case LASSOP: case RASSOP: case LFUNC: case LUNOP: case RUNOP: { //functions / operators: idk yet
          int ind = 0; long time = 0, dTime = 0, timeInit = 0;
          if(showPerformance) { time = timeInit = System.nanoTime(); }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(out.size()<e.inps) { return new MathObj("BIG ERROR: too many commas / not enough inputs in function "+e.getId()+" ("+out.size()+", "+e.inps+")"); }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          MathObj inp[] = new MathObj[e.inps]; //now, we have to group together all the inputs
          for(int n=0;n<e.inps;n++) { //loop through all inputs
            inp[n] = out.get(n+out.size()-e.inps); //load each input
          }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          //MathFunc function = functionDictionary.find(e.id, inp); //load the function which has the same name as this entry AND has the correct input configuration
          MathFunc[] options = functionDictionary.find(e.id);
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          MathFunc function = FuncList.find(options, inp);
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(function==null) {
            String inpList = inp.length==1 ? "":"inputs "; //create a string listing all the input types
            for(int n=0;n<inp.length;n++) { if(n!=0) { inpList+=", "; } inpList+=inp[n].type; }
            if(inp.length==0) { inpList="empty input set"; }
            return new MathObj("Error: cannot evaluate function \""+e.id+"\" on "+inpList);
          }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          MathObj res;
          try { res = function.lambda.func(mapper, inp); } //evaluate the given function
          catch(Exception ex) { res = new MathObj(ex.getMessage()); } //if there was an error in the evaluation, return an error message telling us what went wrong
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(res.isMessage()) { return res; } //if it gives you an error message, return that message
          
          for(int n=0;n<e.inps;n++) { out.remove(out.size()-1); } //remove all elements that were a part of the input list
          //out.subList(out.size()-e.inps, out.size()).clear();
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          out.add(res); //add the result to the output list
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(showPerformance) { sumTimeSq += (time-timeInit)*(time-timeInit); numTimesRec++; }
        }
      }
    }
    
    if(out.size()!=1) { return new MathObj("Error: for some reason, not everything was evaluated"); }
    return out.get(0);
  }
  
  public boolean checkForVar(String v) { //checks for use of a particular variable within an equation
    for(Entry ent : tokens) { //loop through all entries
      if(ent.id.equals(v)) { return true; } //if we see any of that variable, return true
      /*if(ent.links.length>0 && ent.links[0].tokens.size()>0 && ent.links[0].tokens.get(0).id.equals(v)) { //if the first link is just a direct reference to this variable, it could be an exclusion:
        String id = ent.id; //grab the id
        //if(id.equals("Σ(")||id.equals("Sigma(")||id.equals("Π(")||id.equals("Pi(")||id.equals("plug(")||id.equals("d/dx(")||id.equals("d²/dx²(")||id.equals("limit(")||id.equals("
        if(!id.equals("&&")&&!id.equals("||")&&!id.equals("?:")) { //turns out, it's actually easier to list out the things it can't be
          continue;                                                //if this variable is being directly referenced by this functional, it's an exclusion
        }
      }
      for(Equation eq2 : ent.links) { //loop through any and all linked equations
        if(eq2.checkForVar(v)) { return true; } //if any of the links contain that variable, return true
      }*/
      if(ent.asNum!=null && ent.asNum.isEquation()) { //TODO make it so this excludes when the variable is being reassigned within the equation
        if(ent.asNum.equation.checkForVar(v)) { return true; }
      }
    }
    return false; //if nothing was found, return false
  }
  
  
  
  
  
  //public static String[] funcList = largestToSmallest(new String[] {"(","[","√(","ln(","log(","abs(","arg(","Re(","Im(","conj(","sgn(","abs2(","abs²(","absq(","csgn(","fp(",
  //        "sin(","cos(","tan(","sec(","csc(","cot(","sinh(","cosh(","tanh(","sech(","csch(","coth(",
  //        "sin⁻¹(","cos⁻¹(","tan⁻¹(","sec⁻¹(","csc⁻¹(","cot⁻¹(","sinh⁻¹(","cosh⁻¹(","tanh⁻¹(","sech⁻¹(","csch⁻¹(","coth⁻¹(",
  //        "asin(","acos(","atan(","asec(","acsc(","acot(","asinh(","acosh(","atanh(","asech(","acsch(","acoth(",
  //        "floor(","ceil(","round(","frac(","GCF(","LCM(","Factor(","max(","min(","SqrWave(","SawWave(","TriWave(","rect(","θ(",
  //        "nCr(","nPr(","rand(","randInt(","Γ(","lnΓ(","ψ₀(","ψ0(","ψ(","K-Function(","Barnes-G(","erf(","erfi(","erfc(","erfcx(","FresnelC(","FresnelS(",
  //        "ζ(","η(","RS-θ(","RS-Z(","ξ(", "Li₂(","Li2(","Cl₂(","Cl2(","Li(", "Ein(","Ei(","li(","Si(","Ci(","E₁(","E1(","Aux-f(","Aux-g(",
  //        "EllipticK(","EllipticF(","EllipticE(","EllipticΠ(","EllipticPI(","Σ(","Sigma(","Π(","Pi(","∫(","Integral(","d/dx(","d²/dx²(","d^2/dx^2(","dⁿ/dxⁿ(","plug(","limit(","Secant(","Newton(","Halley(","Euler(","EulerMid(","RK4("/*,"fuck("*/,
  //        "mag(","magSq(","mag²(","dot(","cross(","perp(","pDot(","norm(","unit(","BuildVec(",
  //        "det(","tr(","T(","BuildMat1(","BuildMat2(","eigenvalues(",
  //        "AND(","OR(",
  //        "week(","New_Years(","Valentines(","St_Patricks(","Mothers_Day(","Fathers_Day(","Halloween(","Thanksgiving(","Christmas("});

  public static String[] varList = largestToSmallest(new String[] {"Ans","true","false","today","yesterday","tomorrow","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Catalan","π","pi","e","γ","gamma","i"});
  
  /*public static int minInps(String func) { //minimum number of inputs a function can have
    switch(func) {
      case "GCF(": case "LCM(": case "max(": case "min(": case "[":                                                 return 0; //any # of inputs
      case "rand(": case "randInt(": case "ψ(": case "nCr(": case "nPr(": case "dot(": case "pDot(": case "cross(": return 2; //these take exactly 2 inputs
      case "Li(": case "EllipticF(": case "EllipticE(":                                                             return 1; //can take 1 or 2 inputs
      case "EllipticΠ(": case "EllipticPI(":                                                                        return 2; //can take 2 or 3 inputs
      
      case "plug(": case "BuildVec(":                                                                              return 3; //takes 3 inputs
      case "Σ(": case "Sigma(": case "Π(": case "Pi(": case "AND(": case "OR(": case "Secant(": case "BuildMat2(": return 4; //takes 4 inputs
      case "Halley(": case "BuildMat1(":                                                                           return 5; //takes 5 inputs
      
      case "d/dx(": case "d²/dx²(": case "d^2/dx^2(": case "limit(": return 3; //takes 3-5 inputs
      case "Newton(":                                                return 4; //takes 4-5 inputs
      case "Euler(": case "EulerMid(": case "RK4(":                  return 6; //takes 6-7 inputs
      case "dⁿ/dxⁿ(": case "∫(": case "Integral(":                   return 4; //takes 4-6 inputs
      
      default: return 1; //most functions accept exactly 1 input
    }
  }
  
  public static int maxInps(String func) { //maximum number of inputs a function can have
    switch(func) {
      case "GCF(": case "LCM(": case "max(": case "min(": case "[":                                                 return Integer.MAX_VALUE; //any # of inputs
      case "rand(": case "randInt(": case "ψ(": case "nCr(": case "nPr(": case "dot(": case "pDot(": case "cross(": return 2;                 //these take exactly 2 inputs
      case "Li(": case "EllipticF(": case "EllipticE(":                                                             return 2;                 //can take 1 or 2 inputs
      case "EllipticΠ(": case "EllipticPI(":                                                                        return 2;                 //can take 2 or 3 inputs (should be able to take 3, but that hasn't been programmed in yet)
      
      case "plug(": case "BuildVec(":                                                                              return 3; //takes 3 inputs
      case "Σ(": case "Sigma(": case "Π(": case "Pi(": case "AND(": case "OR(": case "Secant(": case "BuildMat2(": return 4; //takes 4 inputs
      case "Halley(": case "BuildMat1(":                                                                           return 5; //takes 5 inputs
      
      case "d/dx(": case "d²/dx²(": case "d^2/dx^2(": case "limit(": return 5; //takes 3-5 inputs
      case "Newton(":                                                return 5; //takes 4-5 inputs
      case "Euler(": case "EulerMid(": case "RK4(":                  return 7; //takes 6-7 inputs
      case "dⁿ/dxⁿ(": case "∫(": case "Integral(":                   return 6; //takes 4-6 inputs
      
      default: return 1; //most functions accept exactly 1 input
    }
  }*/
  
  //ASSERTION: the outputted array must (MUST) be sorted, least to greatest
  public static int[] recursiveCheck(String func) { //given a function, this'll tell us which indices of its input set corresponds to which link
    switch(func) {
      case "&&": case "||":                                                        return new int[] {1}; //&& and ||: link 0 is input 1 (not input 0)
      case "Σ(": case "Sigma(": case "Π(": case "Pi(": case "AND(": case "OR(":    return new int[] {0,3}; //sum and product: link 0 is input 0, link 1 is input 3 (variable, start, end, equation)
      case "plug(": case "d/dx(": case "d²/dx²(": case "d^2/dx^2(": case "limit(": return new int[] {0,2}; //plug, derivatives: link 0 is input 0, link 1 is input 2 (variable, value, equation [epsilon] [method])
      case "BuildVec(": case "BuildArray(":                                        return new int[] {1,2}; //build vector: link 0 is input 1, link 1 is input 2 (size, variable, equation for each element)
      case "dⁿ/dxⁿ(": case "d^n/dx^n(":                                            return new int[] {1,3}; //n-th derivative: link 0 is input 1, link 1 is input 3 (n, variable, value, equation [epsilon] [method])
      case "∫(": case "Integral(":                                                 return new int[] {0,3}; //integral: link 0 is input 0, link 1 is input 3 (variable, start, end, equation [samples] [method])
      case "Secant(":                                                              return new int[] {0,3}; //Secant method: link 0 is input 0, link 1 is input 3 (variable, x0, x1, equation)
      case "Newton(":                                                              return new int[] {0,2,3}; //Newton's method: link 0 is input 0, link 1 is input 2, link 2 is input 3 (variable, initial, equation, derivative)
      case "Halley(":                                                              return new int[] {0,2,3,4}; //Halley's method: link 0 is input 0, link 1 is input 2, link 2 is input 3, link 3 is input 4 (var, init, equation, derivative, second derivative)
      case "Euler(": case "EulerMid(": case "ExpTrap(": case "RK4(":               return new int[] {0,1,5}; //Euler's & Runge Kutta method: link 0 is input 0, link 1 is input 1, link 2 is input 5 (inp var, out var, init inp, init out, final inp, derivative, [steps])
      case "BuildMat1(":                                                           return new int[] {2,3,4}; //Build matrix (element by element): link 0 is input 2, link 1 is input 3, link 2 is input 4 (height, width, row index, column index, equation)
      case "BuildMat2(":                                                           return new int[] {2,3};   //Build matrix (vector by vector): link 0 is input 2, link 1 is input 3 (height, width, row index, equation)
      
      case "?:": return new int[] {1,2}; //the ternary operator has 2 links: one which is used for true, one which is used for false
      
      default: return new int[] {}; //for most functions, though, there aren't any links
    }
  }
  
  public static String[] largestToSmallest(String[] inp) { //sort strings largest to smallest
    for(int i=1;i<inp.length;i++) { //loop through all elements
      int len = inp[i].length();    //record string length
      for(int j=i;j>0;j--) {        //loop through all strings before this
        if(len>inp[j-1].length()) { String temp = inp[j]; inp[j]=inp[j-1]; inp[j-1]=temp; } //if out of order, swap
        else { break; }             //otherwise, exit j loop
      }
    }
    return inp; //return result
  }
}
public static class MathFunc { //a class for storing math functions
  String name; //the function name
  String inpSeq; //the input sequence, represented as a regex (b,c,v,m,d,M,N = bool, complex, vector, matrix, date, message, none)
  private SimplePattern regex; //the input sequence, compiled as a simplified regex
  Functional lambda; //the math function this actually runs
  
  MathFunc(String n, String i, Functional f) {
    name=n; inpSeq=i; lambda=f;
    regex = new SimplePattern(i);
  }
  
  MathFunc(String n, SimplePattern i, Functional f) {
    name = n; regex = i; lambda = f;
  }
  
  public boolean matches(MathObj[] v) {
    return regex.matches(v);
  }
  
  public boolean matches(byte[] seq) { //does the same thing, but for a preprocessed sequence of bytes
    return regex.matches(seq);
  }
}

public static interface Functional {
  public MathObj func(HashMap<String, MathObj> map, MathObj... inp);
}

public static class FuncList { //a class for storing lists of acceptable math functions, in order
  //ArrayList<MathFunc> list = new ArrayList<MathFunc>(); //list of math functions (sorted in order of their name hashes)
  HashMap<String, MathFunc[]> list = new HashMap<String, MathFunc[]>(); //list of math functions (ordered by their name, functions w/ the same name are put in the same array)
  ArrayList<String> lookup = new ArrayList<String>(); //lookup table for all function names (sorted from greatest to least, ignoring operators)
  HashMap<String, int[]> minMax = new HashMap<String, int[]>(); //maps each function to an array containing the minimum & maximum # of inputs
  
  FuncList() { }
  
  FuncList(MathFunc... fs) { //initializes itself from a list of functions
    for(MathFunc f : fs) { add(f); } //add every function (O(nlog(n)), binary insertion sort)
  }
  
  public int size() { return list.size(); }
  
  public FuncList add(MathFunc f) { //adds f to the list
    MathFunc[] find = list.get(f.name); //see if there's already an entry for this name
    if(find==null) { list.put(f.name, new MathFunc[] {f}); } //if there isn't, add one
    else { //otherwise
      MathFunc[] arr = new MathFunc[find.length+1]; //create a replacement array that's one longer
      System.arraycopy(find,0,arr,0,find.length);   //copy the existing contents onto this array
      arr[find.length] = f;                         //add this one extra element
      list.put(f.name, arr);                        //replace the array with the new array
    }
    
    addLookup(f.name); //add f's name to the lookup table
    updateMinMax(f);   //update the min/max # of inputs for this function
    
    return this; //return result
  }
  
  //boolean remove(MathFunc f) { return list.remove(f); }
  public boolean remove(MathFunc f) { //attempts to remove from the list, returns false if it wasn't even there
    MathFunc[] find = list.get(f.name); //see if there's an entry for this name
    if(find==null) { return false; }    //if there isn't, return false
    if(find.length==1) { //if there's exactly one:
      if(find[0]==f) { list.put(f.name,null); return true; } //if it contains this function, remove the entry & return true
      return false; //otherwise, do nothing & return false
    }
    int ind = -1; //find the index of this function
    for(int n=0;n<find.length;n++) { //loop through all elements
      if(find[n]==f) { ind=n; break; } //the moment we find this function, set the index & quit the loop
    }
    if(ind==-1) { return false; } //if we didn't find this function, return false
    MathFunc[] arr = new MathFunc[find.length-1]; //otherwise, create a replacement array that's one shorter
    System.arraycopy(find,0,arr,0,ind); //copy all elements before this function
    System.arraycopy(find,ind+1,arr,ind,find.length-ind-1); //copy all elements after this function
    return true; //return true, since something was removed
  }
  
  private void addLookup(String k) { //adds a specific key to the lookup table
    //NOTE: keys are sorted from biggest to smallest, tied elements are sorted in alphabetical order
    if(!k.contains("(") && !k.contains("[")) { return; } //if it doesn't contain a left parenthesis or bracket, do nothing
    
    int left = 0, right = lookup.size()-1; //find the left & right bounds
    int middle = (left+right)>>1;          //find the center
    int compare = 1;                       //whether k comes before, at, or after middle
    while(left<=right && (compare=compareLookup(k,lookup.get(middle)))!=0) { //loop until either the left & right bounds are out of order or we find a function w/ the same name
      if(compare<0) { right = middle-1; } //if k comes before the middle, change the right to 1 less than the middle
      else          { left  = middle+1; } //if k comes after the middle, change the left to 1 more than the middle
      middle = (left+right)>>1; //find the center again
    }
    //now, either we found a func w/ this name at index "middle", or left is the index of the element after k, right & middle are the index of the element before k (slight nuance: out of bounds)
    if(compare!=0) { //if there's an identical string at index middle, do nothing. Otherwise...
      lookup.add(middle+1, k); //add this string right after the middle element
    }
  }
  
  private int compareLookup(String a, String b) { //returns which order two strings belong in on the lookup table
    if(a.length()!=b.length()) { return b.length()-a.length(); } //if different lengths, return + if a is smaller, - if a is bigger
    return a.compareTo(b); //otherwise, return their alphabetical order
  }
  
  private void updateMinMax(MathFunc f) { //given an added function, this updates the map of min/max inputs
    int[] fMinMax = f.regex.minMax(); //given the regex for the input sequence, find the minimum & maximum # of inputs
    int[] curr = minMax.get(f.name);  //grab the current min & max for functions of this name
    if(curr==null) { minMax.put(f.name, fMinMax); } //if this entry isn't part of the list yet, add it
    else { //otherwise:
      if(fMinMax[0]<curr[0]) { curr[0]=fMinMax[0]; } //if this can accept fewer inputs, lower the minimum
      if(fMinMax[1]>curr[1]) { curr[1]=fMinMax[1]; } //if this can accept more inputs, raise the maximum
    }
  }
  
  public MathFunc[] find(String name) { //finds all functions w/ a given name. If N/A, returns empty array
    MathFunc[] find = list.get(name); //lookup this name
    return find==null ? new MathFunc[0] : find; //if null, return empty array. Otherwise, return what you found
  }
  
  public static MathFunc find(MathFunc[] funcs, MathObj[] inps) { //given a function name, and a set of inputs, it finds which function to use. If N/A, returns null
    if(funcs.length==0) { return null; } //if there are no options, return null TODO see if this is redundant (I'm pretty damn sure it is)
    
    //byte[] parsed = null;
    for(MathFunc func : funcs) { //loop through all functions that could match this
      //if(parsed==null) { parsed = SimplePattern.parse(inps); }
      if(func.matches(inps)) { return func; } //return the first function whose regex matches the input sequence
    }
    return null; //if none of them accept our inputs, return null
  }
  
  public MathFunc find(String name, MathObj[] inps) { //given a function name, and a set of inputs, it finds which function to use. If N/A, returns null
    return find(find(name), inps); //find all the functions it could be, return what we find
  }
}

public static Functional tempFunc;
public static FuncList functionDictionary = new FuncList( //this is a list of all the functions
  new MathFunc("(",".",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return inp[0]; } }), //identity function
  
  new MathFunc("+","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.add(inp[1].number)); } }), //start with basic binary arithmetic functions
  new MathFunc("-","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sub(inp[1].number)); } }),
  new MathFunc("*","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.mul(inp[1].number)); } }),
  new MathFunc("/","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.div(inp[1].number)); } }),
  new MathFunc("\\","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].number.div(inp[0].number)); } }),
  new MathFunc("%","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.mod(inp[1].number)); } }),
  new MathFunc("^","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.equals(Math.E)) { return new MathObj(inp[1].number.exp()); }
    else                { return new MathObj(inp[0].number.pow(inp[1].number)); }
  } }),
  new MathFunc("//","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.div(inp[1].number).floor()); } }),
  
  /*new MathFunc("=","..",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //next, inequalities
    if(inp[0].type==inp[1].type) { switch(inp[0].type) {
      case COMPLEX: return new MathObj(inp[0].number.equals(inp[1].number));
      case BOOLEAN: return new MathObj(inp[0].bool == inp[1].bool);
      case VECTOR: return new MathObj(inp[0].vector.equals(inp[1].vector));
      case MATRIX: return new MathObj(inp[0].matrix.equals(inp[1].matrix));
      case DATE  : return new MathObj(inp[0].date.equals(inp[1].date));
      case MESSAGE: return new MathObj(inp[0].message.equals(inp[1].message));
      default: return new MathObj(false);
    } }
    else { return new MathObj(false); }
  } }),
  new MathFunc("==","..",tempFunc),
  new MathFunc("!=","..",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].type==inp[1].type) { switch(inp[0].type) {
      case COMPLEX: return new MathObj(!inp[0].number.equals(inp[1].number));
      case BOOLEAN: return new MathObj(inp[0].bool ^ inp[1].bool);
      case VECTOR: return new MathObj(!inp[0].vector.equals(inp[1].vector));
      case MATRIX: return new MathObj(!inp[0].matrix.equals(inp[1].matrix));
      case DATE  : return new MathObj(!inp[0].date.equals(inp[1].date));
      case MESSAGE: return new MathObj(!inp[0].message.equals(inp[1].message));
      default: return new MathObj(true);
    } }
    else { return new MathObj(true); }
  } }),*/
  new MathFunc("=","..",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].equals(inp[1])); } }),
  new MathFunc("==","..",tempFunc),
  new MathFunc("!=","..",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(!inp[0].equals(inp[1])); } }),
  new MathFunc("<" ,"cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re<inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im< inp[1].number.im); } }),
  new MathFunc(">" ,"cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re>inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im> inp[1].number.im); } }),
  new MathFunc("<=","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re<inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im<=inp[1].number.im); } }),
  new MathFunc(">=","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re>inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im>=inp[1].number.im); } }),
  
  new MathFunc("(-)","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.neg()); } }), //then, some important elementary functions
  new MathFunc("√(" ,"c",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sqrt()); } }),
  new MathFunc("sqrt(","c",tempFunc),
  new MathFunc("∛(","c",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cbrt()); } }),
  new MathFunc("cbrt(","c",tempFunc),
  new MathFunc( "ln(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.ln()); } }),
  new MathFunc("log(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx.log10(inp[0].number)); } }),
  new MathFunc(   "²","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sq()); } }),
  new MathFunc(   "³","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cub()); } }),
  
  new MathFunc("fp(",".",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { inp[0].fp=true; return inp[0]; } }), //the full precision function
  
  new MathFunc("ulp(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.ulpMax()); } }), //ulp (unit in last place)
  
  new MathFunc("sin(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sin()); } }), //trig functions
  new MathFunc("cos(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cos()); } }),
  new MathFunc("tan(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.tan()); } }),
  new MathFunc("sec(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sec()); } }),
  new MathFunc("csc(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.csc()); } }),
  new MathFunc("cot(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cot()); } }),
  new MathFunc("sinh(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sinh()); } }),
  new MathFunc("cosh(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cosh()); } }),
  new MathFunc("tanh(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.tanh()); } }),
  new MathFunc("sech(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sech()); } }),
  new MathFunc("csch(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.csch()); } }),
  new MathFunc("coth(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.coth()); } }),
  
  new MathFunc("asin(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asin()); } }), new MathFunc("sin⁻¹(","c",tempFunc), //inverse trig functions
  new MathFunc("acos(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acos()); } }), new MathFunc("cos⁻¹(","c",tempFunc),
  new MathFunc("atan(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.atan()); } }), new MathFunc("tan⁻¹(","c",tempFunc),
  new MathFunc("asec(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asec()); } }), new MathFunc("sec⁻¹(","c",tempFunc),
  new MathFunc("acsc(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acsc()); } }), new MathFunc("csc⁻¹(","c",tempFunc),
  new MathFunc("acot(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acot()); } }), new MathFunc("cot⁻¹(","c",tempFunc),
  new MathFunc("asinh(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asinh()); } }), new MathFunc("sinh⁻¹(","c",tempFunc),
  new MathFunc("acosh(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acosh()); } }), new MathFunc("cosh⁻¹(","c",tempFunc),
  new MathFunc("atanh(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.atanh()); } }), new MathFunc("tanh⁻¹(","c",tempFunc),
  new MathFunc("asech(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asech()); } }), new MathFunc("sech⁻¹(","c",tempFunc),
  new MathFunc("acsch(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acsch()); } }), new MathFunc("csch⁻¹(","c",tempFunc),
  new MathFunc("acoth(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acoth()); } }), new MathFunc("coth⁻¹(","c",tempFunc),
  
  new MathFunc("atan2(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.im==0 && inp[1].number.im==0) { return new MathObj(Math.atan2(inp[1].number.re,inp[0].number.re)); } //both real: return atan2
    if(inp[1].number.equals(0)) { return new MathObj(inp[0].number.re>=0 ? 0 : inp[0].number.im>=0 ? Math.PI : -Math.PI); } //y is 0: return 0 or ±π
    if(inp[0].number.re>=0 && inp[1].number.lazyabs() < Math.scalb(inp[0].number.lazyabs(),-26)) { return new MathObj(inp[1].number.div(inp[0].number)); } //y is really small WRT x: return y/x
    return new MathObj(inp[0].number.add(inp[1].number.mulI()).log().subeq(inp[0].number.sub(inp[1].number.mulI()).log()).muleqI(-0.5f)); //otherwise: return (ln(x+yi)-ln(x-yi))/(2i)
  } }),
  
  new MathFunc("gd(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(Cpx.gd(inp[0].number));
  } }),
  new MathFunc("invGd(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(Cpx.invGd(inp[0].number));
  } }),
  
  new MathFunc("~","b",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(!inp[0].bool); } }), //boolean operators
  new MathFunc("&","bb",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].bool & inp[1].bool); } }),
  new MathFunc("|","bb",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].bool | inp[1].bool); } }),
  new MathFunc("^","bb",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].bool ^ inp[1].bool); } }),
  new MathFunc("&&","be",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[0].bool) { return new MathObj(false); }
    MathObj right = inp[1].equation.solve(map);
    return right.isBool() ? right : new MathObj("Cannot evaluate boolean && "+right.type);
  } }),
  new MathFunc("||","be",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].bool) { return new MathObj(true); }
    MathObj right = inp[1].equation.solve(map);
    return right.isBool() ? right : new MathObj("Cannot evaluate boolean || "+right.type);
  } }),
  new MathFunc("?:","bee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return (inp[0].bool ? inp[1] : inp[2]).equation.solve(map);
  } }),
  
  new MathFunc("[","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //vector functions, starting with vector initialization
    Complex[] arr = new Complex[inp.length]; //load array of appropriate length
    for(int n=0;n<inp.length;n++) { arr[n]=inp[n].number.copy(); } //load each element
    return new MathObj(new CVector(arr)); //return result
  } }),
  new MathFunc("+","vv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.add(inp[1].vector)); } }),
  new MathFunc("-","vv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.sub(inp[1].vector)); } }),
  new MathFunc("*","vc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.mul(inp[1].number)); } }),
  new MathFunc("*","cv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].vector.mul(inp[0].number)); } }),
  new MathFunc("/","vc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.div(inp[1].number)); } }),
  new MathFunc("\\","cv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].vector.div(inp[0].number)); } }),
  new MathFunc("_","vc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[1].number.isNatural() && inp[1].number.re<=inp[0].vector.size()) {
      return new MathObj(inp[0].vector.get((int)(inp[1].number.re)-1));
    }
    return new MathObj("Error: cannot take index "+inp[1].number+" of vector["+inp[0].vector.size()+"]");
  } }),
  new MathFunc("·","vv",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.dot(inp[1].vector)); } }), new MathFunc("•","vv",tempFunc), new MathFunc("dot(","vv",tempFunc),
  new MathFunc("⟂","vv",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.pDot(inp[1].vector)); } }), new MathFunc("pDot(","vv",tempFunc),
  new MathFunc("×","vv",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.cross(inp[1].vector)); } }), new MathFunc("cross(","vv",tempFunc),
  new MathFunc("perp(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.perp()); } }),
  new MathFunc("(-)","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.neg()); } }),
  new MathFunc("mag(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.mag()); } }),
  new MathFunc("mag²(","v",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.magSq()); } }), new MathFunc("magSq(","v",tempFunc),
  new MathFunc("unit(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.unit()); } }),
  new MathFunc("size(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.size()); } }),
  new MathFunc("zero(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isWhole()) { return new MathObj(CVector.zero((int)inp[0].number.re)); }
    return new MathObj("Cannot create zero vector of size "+inp[0].number);
  } }),
  
  
  new MathFunc("[","v*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //matrix functions, starting with matrix initialization
    CVector[] arr = new CVector[inp.length]; //load array of appropriate length
    for(int n=0;n<inp.length;n++) { arr[n]=inp[n].vector.clone(); } //load each element
    return new MathObj(new CMatrix(arr)); //return result
  } }),
  new MathFunc("+","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.add(inp[1].matrix)); } }),
  new MathFunc("+","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.add(inp[1].number)); } }),
  new MathFunc("+","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.add(inp[0].number)); } }),
  new MathFunc("-","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sub(inp[1].matrix)); } }),
  new MathFunc("-","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sub(inp[1].number)); } }),
  new MathFunc("-","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.neg().add(inp[0].number)); } }),
  new MathFunc("*","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.mul(inp[1].number)); } }),
  new MathFunc("*","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.mul(inp[0].number)); } }),
  new MathFunc("*","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.mul(inp[1].matrix)); } }),
  new MathFunc("*","mv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.mul(inp[1].vector)); } }),
  new MathFunc("*","vm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.mulLeft(inp[0].vector)); } }),
  new MathFunc("/","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.div(inp[1].number)); } }),
  new MathFunc("/","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.inv().muleq(inp[0].number)); } }),
  new MathFunc("/","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.rightDivide(inp[1].matrix)); } }),
  new MathFunc("/","vm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.rightDivide(inp[0].vector)); } }),
  new MathFunc("\\","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.leftDivide(inp[1].matrix)); } }),
  new MathFunc("\\","mv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.leftDivide(inp[1].vector)); } }),
  new MathFunc("\\","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.div(inp[0].number)); } }),
  new MathFunc("\\","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.inv().muleq(inp[0].number)); } }),
  new MathFunc("^","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.pow(inp[1].number)); } }),
  new MathFunc("_","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[1].number.isNatural() && inp[1].number.re<=inp[0].matrix.h) {
      return new MathObj(inp[0].matrix.getRow((int)(inp[1].number.re)-1));
    }
    return new MathObj("Error: cannot take index "+inp[1].number+" of "+inp[0].matrix.getDimensions()+" matrix");
  } }),
  new MathFunc("width(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.w); } }),
  new MathFunc("height(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.h); } }),
  new MathFunc("(-)","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.neg()); } }),
  new MathFunc("Identity(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isWhole()) { return new MathObj(CMatrix.identity((int)inp[0].number.re)); }
    return new MathObj("Cannot create "+inp[0].number+"x"+inp[0].number+" identity matrix");
  } }),
  new MathFunc("zero(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isWhole() && inp[1].number.isWhole()) { return new MathObj(new CMatrix((int)inp[0].number.re, (int)inp[1].number.re)); }
    return new MathObj("Cannot create "+inp[0].number+"x"+inp[1].number+" zero matrix");
  } }),
  new MathFunc("T(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.transpose()); } }),
  new MathFunc("tr(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.trace()); } }),
  new MathFunc("det(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.determinant()); } }),
  new MathFunc("eigenvalues(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(new CVector(inp[0].matrix.eigenvalues())); } }),
  new MathFunc("eigenvectors(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(new CMatrix(inp[0].matrix.eigenvectors())); } }),
  new MathFunc("eigenboth(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Object[] both = inp[0].matrix.eigenvalues_and_vectors();
    CVector vals = new CVector((Complex[])both[0]);
    CMatrix vecs = new CMatrix((CVector[])both[1]);
    return new MathObj(new MathObj(vals), new MathObj(vecs));
  } }),
  
  new MathFunc("√(","m",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sqrt()); } }),
  new MathFunc("sqrt(","m",tempFunc),
  new MathFunc("√(","mb*",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    boolean[] varArg = new boolean[inp.length-1]; for(int n=0;n<varArg.length;n++) { varArg[n] = inp[n+1].bool; }
    return new MathObj(inp[0].matrix.sqrt(varArg));
  } }),
  new MathFunc("sqrt(","mb*",tempFunc),
  new MathFunc("^","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.equals(Math.E)) { return new MathObj(inp[1].matrix.exp()); }
    return new MathObj(inp[1].matrix.mul(inp[0].number.log()).exp());
  } }),
  new MathFunc("ln(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.log()); } }),
  new MathFunc("sin(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sin()); } }),
  new MathFunc("cos(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.cos()); } }),
  new MathFunc("sinh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sinh()); } }),
  new MathFunc("cosh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.cosh()); } }),
  new MathFunc("atan(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.atan()); } }),
  new MathFunc("atanh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.atanh()); } }),
  new MathFunc("tan(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.tan()); } }),
  new MathFunc("tanh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.tanh()); } }),
  new MathFunc("sec(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sec()); } }),
  new MathFunc("csc(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.csc()); } }),
  new MathFunc("cot(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.cot()); } }),
  new MathFunc("sech(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sech()); } }),
  new MathFunc("csch(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.csch()); } }),
  new MathFunc("coth(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.coth()); } }),
  new MathFunc("!","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.factorial()); } }),
  new MathFunc("lnΓ(","m",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.loggamma()); } }),
  new MathFunc("lnGamma(","m",tempFunc),
  new MathFunc("Γ(","m",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sub(1).factorial()); } }),
  new MathFunc("Gamma(","m",tempFunc),
  
  
  new MathFunc("{",".*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(inp);
  } }),
  new MathFunc("size(","a",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(inp[0].array.length);
  } }),
  new MathFunc("_","ac",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[1].number.isWhole() && inp[1].number.re<inp[0].array.length) {
      return inp[0].array[(int)inp[1].number.re];
    }
    return new MathObj("Error: cannot take index "+inp[1].number+" of array["+inp[0].array.length+"]");
  } }),
  new MathFunc("find(","a.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    IntList indices = new IntList();
    for(int n=0;n<inp[0].array.length;n++) { //loop through all elements
      if(inp[0].array[n].equals(inp[1])) { //if we find a match:
        indices.append(n); //add this index to the list
      }
    }
    MathObj[] array = new MathObj[indices.size()]; //load a math object array
    for(int n=0;n<array.length;n++) {         //loop through all indices
      array[n] = new MathObj(indices.get(n)); //set each element of the index array
    }
    return new MathObj(array); //return the list of indices
  } }),
  new MathFunc("contains(","a.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    for(MathObj obj : inp[0].array) { //loop through all elements
      if(obj.equals(inp[1])) {
        return new MathObj(true); //if at least one element is equal to this, return true
      }
    }
    return new MathObj(false); //otherwise, return false
  } }),
  new MathFunc("append(","a.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    MathObj[] array = new MathObj[inp[0].array.length+1];
    for(int n=0;n<array.length-1;n++) {
      array[n] = inp[0].array[n];
    }
    array[array.length-1] = inp[1];
    return new MathObj(array);
  } }),
  new MathFunc("remove(","ac",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[1].number.isWhole() || inp[1].number.re>=inp[0].array.length) {
      return new MathObj("Error: cannot remove index "+inp[1].number+" from array["+inp[0].array.length+"]");
    }
    int ind = (int)inp[1].number.re;
    MathObj[] array = new MathObj[inp[0].array.length-1];
    for(int n=0;n<array.length;n++) {
      array[n] = inp[0].array[n<ind ? n : n+1];
    }
    return new MathObj(array);
  } }),
  new MathFunc("concat(","a*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    int len = 0;
    for(int n=0;n<inp.length;n++) { len += inp[n].array.length; }
    MathObj[] array = new MathObj[len]; //create concatenated array
    
    int offset = 0; //the index
    for(MathObj obj1 : inp) { //loop through all arrays
      for(MathObj obj2 : obj1.array) { //loop through all elements of each array
        array[offset++] = obj2; //append each element
      }
    }
    
    return new MathObj(array); //return resulting array
  } }),
  
  new MathFunc("insert(","ac.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[1].number.isWhole() || inp[1].number.re>inp[0].array.length) {
      return new MathObj("Error: cannot add element at index "+inp[1].number+" of array["+inp[0].array.length+"]");
    }
    int ind = (int)inp[1].number.re;
    
    MathObj[] array = new MathObj[inp[0].array.length+1];
    for(int n=0;n<inp[0].array.length;n++) {
      array[n<ind ? n : n+1] = inp[0].array[n];
    }
    array[ind] = inp[2];
    return new MathObj(array);
  } }),
  
  new MathFunc("sublist(","acc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[1].number.isWhole() || !inp[2].number.isWhole() || inp[1].number.re>inp[0].array.length || inp[2].number.re>inp[0].array.length || inp[1].number.re > inp[2].number.re) {
      return new MathObj("Error: cannot sublist array["+inp[0].array.length+"] between indices "+inp[1].number+" and "+inp[2].number);
    }
    
    int ind1 = (int)inp[1].number.re, ind2 = (int)inp[2].number.re;
    
    MathObj[] array = new MathObj[ind2-ind1];
    for(int n=ind1;n<ind2;n++) {
      array[n-ind1] = inp[0].array[n];
    }
    
    return new MathObj(array);
  } }),
  
  new MathFunc("removeRange(","acc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[1].number.isWhole() || !inp[2].number.isWhole() || inp[1].number.re>inp[0].array.length || inp[2].number.re>inp[0].array.length || inp[1].number.re > inp[2].number.re) {
      return new MathObj("Error: cannot remove range between indices "+inp[1].number+" and "+inp[2].number+" from array["+inp[0].array.length+"]");
    }
    
    int ind1 = (int)inp[1].number.re, ind2 = (int)inp[2].number.re;
    
    MathObj[] array = new MathObj[inp[0].array.length-ind2+ind1];
    for(int n=0;n<ind1;n++) {
      array[n] = inp[0].array[n];
    }
    for(int n=ind2;n<inp[0].array.length;n++) {
      array[n-ind2+ind1] = inp[0].array[n];
    }
    
    return new MathObj(array);
  } }),
  
  new MathFunc("splice(","aac",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[2].number.isWhole() || inp[2].number.re>inp[0].array.length) {
      return new MathObj("Error: cannot splice array into index "+inp[2].number+" of array["+inp[0].array.length+"]");
    }
    
    int ind = (int)inp[2].number.re;
    
    MathObj[] array = new MathObj[inp[0].array.length+inp[1].array.length];
    for(int n=0;n<ind;n++) {
      array[n] = inp[0].array[n];
    }
    for(int n=0;n<inp[1].array.length;n++) {
      array[n+ind] = inp[1].array[n];
    }
    for(int n=ind;n<inp[0].array.length;n++) {
      array[n+inp[1].array.length] = inp[0].array[n];
    }
    
    return new MathObj(array);
  } }),
  
  
  
  new MathFunc("+","dc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //date functions
    if(inp[1].number.isInt()) { return new MathObj(inp[0].date.add((long)inp[1].number.re)); }
    return new MathObj("Cannot add non-integer number of days");
  } }),
  new MathFunc("+","cd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(inp[1].date.add((long)inp[0].number.re)); }
    return new MathObj("Cannot add non-integer number of days");
  } }),
  new MathFunc("-","dc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[1].number.isInt()) { return new MathObj(inp[0].date.sub((long)inp[1].number.re)); }
    return new MathObj("Cannot subtract non-integer number of days");
  } }),
  new MathFunc("-","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.sub(inp[1].date)); } }),
  new MathFunc("<","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.less(inp[1].date)); } }),
  new MathFunc(">","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.greater(inp[1].date)); } }),
  new MathFunc("<=","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.lessEq(inp[1].date)); } }),
  new MathFunc(">=","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.greaterEq(inp[1].date)); } }),
  new MathFunc("week(","d",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.dayOfWeek()+""); } }),
  
  new MathFunc("New_Years(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.newYears((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  new MathFunc("Valentines(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.valentines((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  new MathFunc("St_Patricks(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.stPatricks((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  new MathFunc("Mothers_Day(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.mothersDay((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  new MathFunc("Fathers_Day(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.fathersDay((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  new MathFunc("Halloween(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.halloween((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  new MathFunc("Thanksgiving(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.thanksgiving((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  new MathFunc("Christmas(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt()) { return new MathObj(Date.christmas((long)inp[0].number.re)); }
    return new MathObj("Year must be an integer");
  } }),
  
  new MathFunc("Re(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re); } }), //complex number evaluation
  new MathFunc("Im(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.im); } }),
  new MathFunc("Re(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.re()); } }),
  new MathFunc("Im(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.im()); } }),
  new MathFunc("Re(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.re()); } }),
  new MathFunc("Im(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.im()); } }),
  new MathFunc("abs(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.abs()); } }),
  new MathFunc("abs(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.frobeniusMag()); } }),
  new MathFunc("arg(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.arg()); } }),
  new MathFunc("conj(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.conj()); } }),
  new MathFunc("conj(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.conj()); } }),
  new MathFunc("conj(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.conj()); } }),
  new MathFunc("sgn(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sgn()); } }),
  new MathFunc("norm(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.frobeniusUnit()); } }),
  new MathFunc("csgn(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.csgn()); } }),
  new MathFunc("abs2(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.abs2()); } }),
  new MathFunc("abs²(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.absq()); } }), new MathFunc("absq(","c",tempFunc),
  new MathFunc("abs²(","v",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.frobeniusMagSq()); } }), new MathFunc("absq(","v",tempFunc),
  
  new MathFunc("floor(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.floor()); } }), //rounding functions
  new MathFunc("ceil(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.ceil()); } }),
  new MathFunc("round(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.round()); } }),
  new MathFunc("frac(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sub(inp[0].number.floor())); } }),
  
  new MathFunc("θ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re<0?0:inp[0].number.re==0?0.5f:1); } }), //a few piecewise functions
  new MathFunc("U(","c",tempFunc),
  new MathFunc("rect(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.absq()<0.25f?1:(inp[0].number.absq()==0.25f?0.5f:0)); } }),
  
  new MathFunc("!","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.factorial(inp[0].number)); } }), //discrete math functions
  new MathFunc("nPr(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.factorial(inp[0].number).div(Cpx2.factorial(inp[0].number.sub(inp[1].number)))); } }),
  new MathFunc("nCr(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.factorial(inp[0].number).div(Cpx2.factorial(inp[1].number).mul(Cpx2.factorial(inp[0].number.sub(inp[1].number))))); } }),
  new MathFunc("rand(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    double rand = Math.random(); return new MathObj(inp[0].number.add(inp[1].number.sub(inp[0].number).mul(rand)));
  } }),
  new MathFunc("randInt(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[0].number.isReal() || !inp[1].number.isReal()) { return new MathObj("Cannot take random integer over non-real interval"); }
    double range = inp[1].number.re-inp[0].number.re+1;
    return new MathObj(Math.floor(Math.random()*range+inp[0].number.re));
  } }),
  new MathFunc("max(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Complex max = new Complex(Double.NEGATIVE_INFINITY);
    for(MathObj m : inp) {
      if(m.number.re>max.re || m.number.re==max.re && m.number.im>max.im) { max=m.number; }
    }
    return new MathObj(max);
  } }),
  new MathFunc("min(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Complex min = new Complex(Double.POSITIVE_INFINITY);
    for(MathObj m : inp) {
      if(m.number.re<min.re || m.number.re==min.re && m.number.im<min.im) { min=m.number; }
    }
    return new MathObj(min);
  } }),
  
  new MathFunc("stir1(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //Stirling numbers of the first kind
    if(!inp[0].number.isInt() || !inp[1].number.isInt()) { return new MathObj("Stirling numbers only work for integer inputs"); }
    return new MathObj(stirling1((int)(inp[0].number.re), (int)(inp[1].number.re)));
  } }),
  
  new MathFunc("stir2(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //Stirling numbers of the second kind
    if(!inp[0].number.isInt() || !inp[1].number.isInt()) { return new MathObj("Stirling numbers only work for integer inputs"); }
    return new MathObj(stirling2((int)(inp[0].number.re), (int)(inp[1].number.re)));
  } }),
  
  new MathFunc("PolyEval(","c+",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //evalutates polynomial using Horner's method (input, coefficients...)
    if(inp.length==1) { return new MathObj(new Complex()); } //special case: the zero polynomial
    
    Complex result = inp[1].number; //init result to leading coefficient
    for(int n=2;n<inp.length;n++) { //loop through all coefficients (except the leading)
      result.muleq(inp[0].number).addeq(inp[n].number); //multiply by input, add the next coefficient
    }
    return new MathObj(result); //return the result
  } }),
  new MathFunc("PolyRoots(","c+",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //computes & returns the roots of a polynomial, given its coefficients
    int deg = inp.length-1;                  //find the degree
    Complex inv = inp[0].number.inv().neg(); //find the negative reciprocal of the leading coefficient
    
    Complex[][] companion = new Complex[deg][deg]; //construct a 2D array representing the companion matrix
    for(int i=0;i<deg;i++) for(int j=0;j<deg;j++) { //loop through all elements
      if   (j==deg-1) { companion[i][j] = inp[deg-i].number.mul(inv); } //the last column is just each coefficient, negated & divided by the leading coefficient
      else if(i==j+1) { companion[i][j] = new Complex(1);             } //the subdiagonal elements are all 1
      else            { companion[i][j] = new Complex();              } //all other elements are 0
    }
    
    Complex[] roots = new CMatrix(deg,deg,companion).eigenvalues(); //construct a matrix, then compute the eigenvalues
    return new MathObj(new CVector(roots)); //return the array of roots, organized into a vector
  } }),
  
  
  new MathFunc("Γ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.gamma(inp[0].number)); } }), //gamma and related functions
  new MathFunc("Gamma(","c",tempFunc),
  new MathFunc("lnΓ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.loggamma(inp[0].number)); } }),
  new MathFunc("lnGamma(","c",tempFunc),
  new MathFunc("ψ₀(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.digamma(inp[0].number)); } }), new MathFunc("ψ0(","c",tempFunc), new MathFunc("digamma(","c",tempFunc),
  new MathFunc("ψ(","cc",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj>map, MathObj... inp) {
    if(!inp[0].number.isInt()) { return new MathObj("Cannot take ψ with non-integer modulus :("); }
    return new MathObj(Cpx3.polygamma2((int)inp[0].number.re,inp[1].number));
  } }), new MathFunc("polygamma(","cc",tempFunc),
  new MathFunc("K-Function(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.kFunction(inp[0].number,true)); } }),
  new MathFunc("Barnes-G(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.barnesG(inp[0].number)); } }),
  
  new MathFunc("erf(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erf(inp[0].number)); } }), //error and related functions
  new MathFunc("erfi(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erfi(inp[0].number)); } }),
  new MathFunc("erfc(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erfc(inp[0].number)); } }),
  new MathFunc("erfcx(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erfcx(inp[0].number)); } }),
  new MathFunc("FresnelC(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.fresnelC(inp[0].number)); } }),
  new MathFunc("FresnelS(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.fresnelS(inp[0].number)); } }),
  
  new MathFunc("ζ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.zeta(inp[0].number)); } }), //Riemann zeta and related functions
  new MathFunc("zeta(","c",tempFunc),
  new MathFunc("η(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.zeta(inp[0].number).mul(Cpx.sub(1,new Complex(2).pow(Cpx.sub(1,inp[0].number))))); } }),
  new MathFunc("eta(","c",tempFunc),
  new MathFunc("RS-θ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.rsTheta(inp[0].number)); } }),
  new MathFunc("RS-Theta(","c",tempFunc),
  new MathFunc("RS-Z(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.rsZFunction(inp[0].number)); } }),
  new MathFunc("ξ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { Complex num=inp[0].number; return new MathObj(Cpx.mul(num, num.sub(1), Cpx.pow(new Complex(Math.PI),num.mul(-0.5f)), Cpx3.gamma(num.mul(0.5f)), Cpx3.zeta(num)).muleq(0.5f)); } }),
  new MathFunc("Xi(","c",tempFunc),
  
  new MathFunc("Li₂(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.Li2(inp[0].number)); } }), new MathFunc("Li2(","c",tempFunc), //polygamma functions
  new MathFunc("Cl₂(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.Cl2(inp[0].number)); } }), new MathFunc("Cl2(","c",tempFunc),
  new MathFunc("Li(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[0].number.isInt()) { return new MathObj("Cannot take polylogarithm with non-integer modulus :("); }
    return new MathObj(Cpx3.polylog((int)inp[0].number.re,inp[1].number));
  } }),
  
  new MathFunc("Ein(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.ein(inp[0].number)); } }), //TODO this is not correct, actually
  new MathFunc("Ei(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.ein(inp[0].number).addeq(inp[0].number.log())); } }), //exponential integral and related functions
  new MathFunc("li(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { Complex ln=inp[0].number.log(); return new MathObj(Cpx3.ein(ln).addeq(ln.ln())); } }),
  new MathFunc("Li(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { Complex ln=inp[0].number.log(); return new MathObj(Cpx3.ein(ln).add(ln.ln()).subeq(1.0451637801174928d)); } }),
  new MathFunc("Si(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.trigInt(inp[0].number,false)); } }),
  new MathFunc("Ci(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.trigInt(inp[0].number,true).addeq(inp[0].number.ln()).addeq(Mafs.GAMMA)); } }),
  new MathFunc("E₁(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.ein(inp[0].number.neg()).addeq(inp[0].number.ln()).neg()); } }), new MathFunc("E1(","c",tempFunc),
  new MathFunc("Aux-f(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.auxInt(inp[0].number, true)); } }),
  new MathFunc("Aux-g(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.auxInt(inp[0].number,false)); } }),
  
  new MathFunc("EllipticK(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.completeF(inp[0].number)); } }), new MathFunc("EllipticF(","c",tempFunc), //elliptic integrals
  new MathFunc("EllipticE(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.completeE(inp[0].number)); } }),
  new MathFunc("EllipticF(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.incompleteF(inp[0].number,inp[1].number)); } }),
  new MathFunc("EllipticE(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.incompleteE(inp[0].number,inp[1].number)); } }),
  new MathFunc("EllipticΠ(","cc",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.completePI(inp[0].number,inp[1].number)); } }), new MathFunc("EllipticPI(","cc",tempFunc),
  
  new MathFunc("BesselJ(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselJ(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselY(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselY(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselJY(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(new CVector(Cpx3.besselJY(inp[0].number, inp[1].number))); } }),
  new MathFunc("BesselI(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselI(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselK(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselK(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselH1(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselH1(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselH2(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselH2(inp[0].number, inp[1].number)); } }),
  
  new MathFunc("Factor(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //factoring
    Complex num = inp[0].number; //grab input
    if(!num.isInt()) { return new MathObj("Can only factor integers"); } //only accept positive integers
    
    short pow2 = 0; //first, for the sake of normalization to a long, we keep dividing by 2 until we have an odd number
    while(num.re >= 4503599627370496l) { num.re*=0.5f; pow2++; } //repeatedly divide by 2 and increment the power
    
    long val = (long)num.re; //cast to a long
    while(val!=0 && (val&1)==0) { val>>=1; pow2++; } //continue dividing by 2
    
    if(val==1) { //if we reduced to 1
      if(pow2==0) { return new MathObj("Empty Product"); } //if it was 1 all along, it's an empty product
      if(pow2==1) { return new MathObj("2");             } //if it was 2 all along, it's just 2
      return new MathObj("2^"+pow2);                       //otherwise, return 2^pow2
    }
    //String factor = primeFactor(val); //compute the prime factorization
    String factor = new PrimeFactorization(val).toString();
    if(pow2==0) { return new MathObj(factor); }      //if there was no power of 2, just return the factorization
    if(pow2==1) { return new MathObj("2*"+factor); } //if there was just one 2, return 2 * the factorization
    return new MathObj("2^"+pow2+"*"+factor);        //otherwise, return 2^pow2 * the factorization
  } }),
  new MathFunc("GCF(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    long[] ints = new long[inp.length]; //construct an array of all the inputs
    int[] shifts = new int[inp.length]; //this is to store how many times each input was divided by 2 to make it a valid 64-bit int
    for(int n=0;n<inp.length;n++) { //loop through all inputs
      if(inp[n].number.isInt()) { //if the number is an integer:
        while(Math.abs(inp[n].number.re)>Long.MAX_VALUE) { inp[n].number.re*=0.5f; shifts[n]++; } //divide by 2 until it's in bounds
        ints[n] = (long)inp[n].number.re; //cast to a long
      }
      else { return new MathObj("Cannot take GCF of non-integer(s)"); }
    }
    long gcf=0; try { gcf = gcf(ints); } //try taking the GCF
    catch(ArithmeticException ex) { return new MathObj(new Complex(Double.POSITIVE_INFINITY)); } //if infinite, set it to be infinite
    
    int shift = min(shifts); //compute the minimum amount any number had to shift
    return new MathObj(new Complex(gcf).scalbeq(shift)); //set result to the GCF of all our inputs, multiplied by 2^(the smallest power of 2 anything had to multiply by)
  } }),
  new MathFunc("LCM(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //TODO TEST
    long[] ints = new long[inp.length]; //construct an array of all the inputs
    int[] shifts = new int[inp.length]; //this is to store how many times each input was divided by 2 to make it a valid 64-bit int
    for(int n=0;n<inp.length;n++) { //loop through all inputs
      if(inp[n].number.isInt()) { //if the number is an integer:
        while(Math.abs(inp[n].number.re)>Long.MAX_VALUE) { inp[n].number.re*=0.5f; shifts[n]++; } //divide by 2 until it's in bounds
        ints[n] = (long)inp[n].number.re; //cast to a long
      }
      else { return new MathObj("Cannot take LCM of non-integer(s)"); }
    }
    double lcm = 1; //init least common multiple to 1
    int shift2 = max(shifts); //count how many times we had to divide our LCM by 2 just to put it back in bounds
    for(long l : ints) { //loop through all inputs (again)
      if(l==0) { return new MathObj(0); } //if any of the inputs are 0, the LCM is 0
      while(Math.abs(lcm)>Long.MAX_VALUE) { lcm*=0.5f; ++shift2; if((l&1)==0) { l>>=1; } }
      lcm = l*lcm/gcf(l, (long)lcm); //replace the lcm w/ the lcm between itself and each number
    }
    lcm = Math.scalb(lcm,shift2); //multiply back by the correct power of 2
    return new MathObj(lcm); //return result
  } }),
  new MathFunc("modInv(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //TODO TEST
    if(!inp[0].number.isInt() || !inp[1].number.isInt()) { //both inputs must be integers
      return new MathObj("Cannot take inverse of "+inp[0].number+" mod "+inp[1].number+" (must both be integers)");
    }
    return new MathObj(modInv(Math.round(inp[0].number.re),Math.round(inp[1].number.re)));
  } }),
  new MathFunc("totient(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[0].number.isInt()) { //input must be an integer
      return new MathObj("Cannot take Euler's totient of "+inp[0].number+" (must be an integer)");
    }
    return new MathObj(totient(Math.round(inp[0].number.re)));
  } }),
  new MathFunc("modPow(","ccc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[0].number.isInt() || !inp[1].number.isInt() || !inp[2].number.isInt()) { //all 3 inputs must be integers
      return new MathObj("Cannot take "+inp[0].number+"^"+inp[1].number+" mod "+inp[2].number+" (must all be integers)");
    }
    return new MathObj(modPow(Math.round(inp[0].number.re),Math.round(inp[1].number.re),Math.round(inp[2].number.re)));
  } }),
  new MathFunc("discLog(","ccc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[0].number.isInt() || !inp[1].number.isInt() || !inp[2].number.isInt()) { //all 3 inputs must be integers
      return new MathObj("Cannot take log_"+inp[0].number+"("+inp[1].number+") mod "+inp[2].number+" (must all be integers)");
    }
    Long log = discLog_babyGiant((long)inp[0].number.re, (long)inp[1].number.re, (long)inp[2].number.re, carmichael((long)inp[2].number.re));
    if(log==null) { return new MathObj("Logarithm does not exist"); }
    else          { return new MathObj(new Complex(log)); }
  } }),
  new MathFunc("carmichael(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(!inp[0].number.isInt()) { //input must be an integer
      return new MathObj("Cannot take Carmichael's totient of "+inp[0].number+" (must be an integer)");
    }
    return new MathObj(carmichael(Math.round(inp[0].number.re)));
  } }),
  
  
  ////////////// RECURSIVE FUNCTIONS //////////////////////
  
  new MathFunc("plug(","e.e",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //variable, plug in point, equation
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    map2.put(vari, inp[1].clone());     //plug in our plug-in-point
    return inp[2].equation.solve(map2); //solve at that point, return result
  } }),
  
  new MathFunc("BuildVec(","cee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //size, variable, equation
    String vari = inp[1].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[0].number.isWhole()) { //if the size is a whole integer
      int siz = (int)inp[0].number.re;  //record the size of the array
      Complex[] arr = new Complex[siz]; //create array of appropriate length
      for(int n=0;n<siz;n++) {                         //loop through all elements of the array
        map2.put(vari, new MathObj(new Complex(n+1))); //set the variable to our current index
        MathObj term = inp[2].equation.solve(map2);    //solve at this index
        if(term.isNum()) { arr[n] = term.number; }     //if evaluates to number, put that number at this index
        else { return new MathObj("Cannot build vector with element of type "+term.type); } //otherwise, return error message
      }
      return new MathObj(new CVector(arr)); //now that all the elements are created, return the result
    }
    else { return new MathObj("Cannot build vector of size "+inp[0]); } //if not a whole integer, return error message
  } }),
  
  new MathFunc("BuildArray(","cee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //size, variable, equation
    String vari = inp[1].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[0].number.isWhole()) { //if the size is a whole integer
      int siz = (int)inp[0].number.re;  //record the size of the array
      MathObj[] arr = new MathObj[siz]; //create array of appropriate length
      for(int n=0;n<siz;n++) {                         //loop through all elements of the array
        map2.put(vari, new MathObj(new Complex(n)));   //set the variable to our current index
        MathObj term = inp[2].equation.solve(map2);    //solve at this index
        arr[n] = term;                                 //set this element
      }
      return new MathObj(arr); //now that all the elements are created, return the result
    }
    else { return new MathObj("Cannot build array of size "+inp[0]); } //if not a whole integer, return error message
  } }),
  
  new MathFunc("BuildMat1(","cceee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //height, width, row var, column var, scalar equation
    String var1 = inp[2].equation.tokens.get(0).id, var2 = inp[3].equation.tokens.get(0).id; //record the variables that represent the indices
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[1].isNum() && inp[0].number.isWhole() && inp[1].number.isWhole()) { //ensure dimensions are whole integers
      int hig = (int)inp[0].number.re, wid = (int)inp[1].number.re; //record the size of the matrix
      Complex[][] arr = new Complex[hig][wid];        //create array of appropriate size
      for(int i=0;i<hig;i++) for(int j=0;j<wid;j++) { //loop through all elements of the matrix
        map2.put(var1, new MathObj(new Complex(i+1))); //set the row variable
        map2.put(var2, new MathObj(new Complex(j+1))); //set the column variable
        MathObj term = inp[4].equation.solve(map2);    //solve at these indices
        if(term.isNum()) { arr[i][j] = term.number; }  //if evaluates to number, put that number at this index
        else { return new MathObj("Cannot build matrix with element of type "+term.type); } //otherwise, return error message
      }
      return new MathObj(new CMatrix(hig,wid,arr)); //create and return matrix
    }
    else { return new MathObj("Cannot build matrix of size "+inp[0]+"x"+inp[1]); } //if provided dimensions are invalid, return error message
  } }),
  
  new MathFunc("BuildMat2(","ccee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //height, width, row var, vector equation
    String vari = inp[2].equation.tokens.get(0).id; //record the variable that represents the row
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[1].isNum() && inp[0].number.isWhole() && inp[1].number.isWhole()) { //ensure dimensions are whole integers
      int hig = (int)inp[0].number.re, wid = (int)inp[1].number.re; //record the size of the matrix
      CVector[] arr = new CVector[hig];                             //create array of appropriate size
      for(int i=0;i<hig;i++) { //loop through all rows of the matrix
        map2.put(vari, new MathObj(new Complex(i+1))); //set the row variable
        MathObj term = inp[3].equation.solve(map2);    //solve at this index
        if(!term.isVector()) { return new MathObj("Cannot build matrix with rows of type "+term.type); } //if not a vector, return error message
        if(term.vector.size()!=wid) { return new MathObj("Cannot build matrix with inconsistent width"); } //if row size is inconsistent, return error message
        arr[i] = term.vector; //otherwise, set each row
      }
      if(hig==0) { return new MathObj(new CMatrix(0,wid)); } //if height is 0, return 0xw matrix
      else { return new MathObj(new CMatrix(arr)); } //otherwise, construct matrix from vectors
    }
    else { return new MathObj("Cannot build matrix of size "+inp[0]+"x"+inp[1]); } //if provided dimensions are invalid, return error message
  } }),
  
  new MathFunc("Σ(","ecce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number); //find the difference between the upper & lower bound
    if(!cRange.isInt()) { return new MathObj("Cannot perform a sum over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer: yell at us
    int range = (int)cRange.re+1; //cast to an integer
    if(range==0) { return new MathObj(Cpx.zero()); } //empty sum: return 0 (I know that it could also be a 0 vector or 0 matrix, but there's also no good way of figuring that out right now)
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the variable map
    boolean backwards = range<0; range = abs(range); Complex start = backwards ? inp[2].number.add(1) : inp[1].number; //if we're performing a backwards sum, remember that and recompute the range
    MathObj result = new MathObj(); //declare result
    for(int k=0;k<range;k++) {      //loop through all terms
      map2.put(vari,new MathObj(start.add(k)));   //set our variable
      MathObj term = inp[3].equation.solve(map2); //compute the term we add
      if(result.type==MathObj.VarType.NONE) { result = term; } //if sum is empty, initialize result
      else { result.addeq(term); }                             //otherwise, add result
    }
    
    if(backwards) { result.negeq(); } //if backwards, we have to negate the result
    
    return result; //return the result
  } }), new MathFunc("Sigma(","ecce",tempFunc),
  
  new MathFunc("Π(","ecce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id;    //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number); //find the difference between the upper & lower bound
    if(!cRange.isInt()) { return new MathObj("Cannot perform a product over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer: yell at us
    int range = (int)cRange.re+1; //cast to an integer
    if(range==0) { return new MathObj(Cpx.one()); } //empty product: return 1 (I know that it could also be an identity matrix, but there's also no good way of figuring that out right now)
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone();
    boolean backwards = range<0; range = abs(range); Complex start = backwards ? inp[2].number.add(1) : inp[1].number;
    MathObj result = new MathObj();
    for(int k=0;k<range;k++) {
      map2.put(vari,new MathObj(start.add(k)));
      MathObj term = inp[3].equation.solve(map2);
      if(result.type==MathObj.VarType.NONE) { result = term; }
      else if(result.type!=term.type) { return new MathObj("Cannot perform product over terms of different types"); }
      else switch(term.type) {
        case COMPLEX: result.number.muleq(term.number); break;
        case MATRIX : result.matrix = result.matrix.mul(term.matrix); break;
        default     : return new MathObj("Cannot perform product over "+term.type);
      }
    }
    
    if(backwards) { switch(result.type) {
      case COMPLEX: result.number = result.number.inv(); break;
      case MATRIX : result.matrix = result.matrix.inv(); break;
      default     : return new MathObj("Cannot perform product over "+result.type);
    } }
    
    return result; //return the result
  } }), new MathFunc("Pi(","ecce",tempFunc),
  
  new MathFunc("∀(","ecce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number).add(1); //find the difference between the upper & lower bound
    if(!cRange.isWhole()) { return new MathObj("Cannot perform logical disjunction over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer (or negative): yell at us
    int range = (int)cRange.re; //cast to an integer
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone();
    for(int k=0;k<range;k++) {
      map2.put(vari,new MathObj(inp[1].number.add(k)));
      MathObj term = inp[3].equation.solve(map2);
      
      if(!term.isBool()) { return new MathObj("Cannot perform logical disjunction over non-booleans"); } //if non-boolean, return error
      if(!term.bool) { return term; } //if even one term is false, the whole thing is false
    }
    return new MathObj(true); //if none of the terms were false, return true
  } }), new MathFunc("AND(","ecce",tempFunc),
  new MathFunc("∃(","ecce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number).add(1); //find the difference between the upper & lower bound
    if(!cRange.isWhole()) { return new MathObj("Cannot perform logical conjunction over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer (or negative): yell at us
    int range = (int)cRange.re; //cast to an integer
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone();
    for(int k=0;k<range;k++) {
      map2.put(vari,new MathObj(inp[1].number.add(k)));
      MathObj term = inp[3].equation.solve(map2);
      
      if(!term.isBool()) { return new MathObj("Cannot perform logical conjunction over non-booleans"); } //if non-boolean, return error
      if(term.bool) { return term; } //if even one term is true, the whole thing is true
    }
    return new MathObj(false); //if none of the terms were true, return false
  } }), new MathFunc("OR(","ecce",tempFunc),
  
  new MathFunc("d/dx(","ecec?c?",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    Complex input = inp[1].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=4 ? inp[3].number : new Complex(9.765625e-4d); //if we have at least 4 inputs, we've chosen the epsilon. Otherwise, default it to something reasonably small
    int method = 2;     //now we must select the number of units we will step away from the middle. For every one unit we step away, we use 2 more samples. By default, we only take 4 samples
    if(inp.length>=5) { //if we have at least 5 inputs, the 5th one is the method we use
      if(inp[4].number.isNatural()) { method = (int)inp[4].number.re; } //if given a (positive) int, cast to an int and make that our method
      else { return new MathObj("Cannot approximate derivative with a polynomial of non-positive degree"); } //if given a non-positive number, return an error
    }
    
    MathObj result = new MathObj(); //initialize our result to an ambiguous math object, since we don't yet know if our result will be a scalar, vector, etc.
    double coef = -1; //our coefficient for each sample k*epsilon from the center will be (-1)^(k+1)*m!²/(k(m+k)!(m-k)!*epsilon). This will assist us in calculating that, but won't actually be that coefficient
    for(int k=1;k<=method;k++) { //loop through all pairs of samples
      
      coef *= k-method-1; coef /= method+k; //update the coefficient (kind of, this is actually (-1)^(k+1)*m!²/((m+k)!(m-k)!) )
      
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[2].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[2].equation.solve(map2); //solve at x-hk
      y1.subeq(y2);     //subtract the two
      y1.muleq(coef/k); //multiply by our factor
      
      if(result.type==MathObj.VarType.NONE) { result     = y1;  } //if the variable type hasn't been set yet, initialize our result to this difference
      else                                  { result.addeq(y1); } //otherwise, add it to that
    }
    
    result.diveq(epsilon); //divide by epsilon
    return result;         //return result
  } }),
  new MathFunc("d²/dx²(","ecec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    Complex input = inp[1].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=4 ? inp[3].number : new Complex(9.765625e-4d); //if we have at least 4 inputs, we've chosen the epsilon. Otherwise, default it to something reasonably small
    int method = 2;     //now we must select the number of units we will step away from the middle. For every one unit we step away, we use 2 more samples. By default, we only take 5 samples
    if(inp.length>=5) { //if we have at least 5 inputs, the 5th one is the method we use
      if(inp[4].number.isNatural()) { method = (int)inp[4].number.re; } //if given a (positive) int, cast to an int and make that our method
      else { return new MathObj("Cannot approximate 2nd derivative with a polynomial of non-positive degree"); } //if given a non-positive number, return an error
    }
    
    map2.put(vari,new MathObj(input)); MathObj y0 = inp[2].equation.solve(map2); //find the value right at the middle
    
    MathObj result = new MathObj(); //initialize our result to an ambiguous math object, since we don't yet know if our result will be a scalar, vector, etc.
    double coef = -2; //our coefficient for each sample k*epsilon from the center will be 2(-1)^(k+1)*m!²/(k²(m+k)!(m-k)!*epsilon). This will assist us in calculating that, but won't actually be that coefficient
    for(int k=1;k<=method;k++) { //loop through all pairs of samples
      
      coef *= k-method-1; coef /= method+k; //update the coefficient (kind of, this is actually 2(-1)^(k+1)*m!²/((m+k)!(m-k)!) )
      
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[2].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[2].equation.solve(map2); //solve at x-hk
      y1.addeq(y2).subeq(y0.mul(2)).muleq(coef/(k*k)); //compute f(x+hk)-2f(x)+f(x-hk), then multiply by the appropriate coefficient
      
      if(result.type==MathObj.VarType.NONE) { result     = y1;  } //if the variable type hasn't been set yet, initialize our result to this difference
      else                                  { result.addeq(y1); } //otherwise, add it to that
    }
      
    result.diveq(epsilon.sq()); //divide by epsilon²
    return result;              //return result
  } }), new MathFunc("d^2/dx^2(","ecec?c?",tempFunc),
  
  new MathFunc("dⁿ/dxⁿ(","cecec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    int n;
    if(inp[0].number.isInt()) { n = (int)inp[0].number.re; }
    else { return new MathObj("Cannot take "+inp[0].number+"th derivative"); }
    
    String vari = inp[1].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    Complex input = inp[2].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=5 ? inp[4].number : new Complex(/*9.765625E-4D*/Math.scalb(1d,Math.round(-13f/n))); //if we have at least 5 inputs, we've chosen the epsilon.
    int method = ((n+1)>>1)+1; //now we must select the number of units we will step away from the middle. For every one unit we step away, we use 2 more samples. By default, we only take n+2 samples
    if(inp.length>=6) { //if we have at least 6 inputs, the 6th one is the one we use
      if(inp[5].number.isNatural()) { method = (int)inp[5].number.re; } //if given a (positive) int, cast to an int and make that our method
      else { return new MathObj("Cannot approximate nth derivative with a polynomial of non-positive degree"); } //if given a non-positive number, return an error
    }
    
    double[] gen = new double[(n+1)>>1]; //coefficients used to generate the actual coefficients
    for(int p=0;p<gen.length;p++) {
      for(int j=1;j<=2*p+1;j++) {
        gen[p] += ((j&1)==0?1:-1)*stirling1(method+1,j)*stirling1(method+1,2*p+2-j);
      }
      //gen[p] += ((p&1)==1?1:-1)*Mafs.sq(stirling1(method+1,p+1));
    }
    
    double factor1 = Mafs.factorial(n)/Mafs.sq(Mafs.factorial(method));
    double[] coef = new double[method];
    for(int k=1;k<=method;k++) {
      factor1 *= -(method-k+1)/(double)(method+k);
      double factor2 = Mafs.pow(k,-n);
      for(int p=0;p<gen.length;p++) {
        coef[k-1]+=gen[p]*factor2;
        factor2 *= k*k;
      }
      coef[k-1]*=factor1;
    }
    
    MathObj y0 = null;
    if((n&1)==0) {
      map2.put(vari,new MathObj(input));
      y0 = inp[3].equation.solve(map2);
    }
    
    MathObj result = new MathObj();
    for(int k=1;k<=method;k++) {
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[3].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[3].equation.solve(map2); //solve at x-hk
      
      if((n&1)==0) { y1.addeq(y2).subeq(y0.mul(2)).muleq(coef[k-1]); }
      else         { y1.subeq(y2).muleq(coef[k-1]); }
      
      if(result.type==MathObj.VarType.NONE) { result = y1; }
      else { result.addeq(y1); }
    }
    
    return result.diveq(epsilon.pow(n));
  } }), new MathFunc("d^n/dx^n(","cecec?c?",tempFunc),
  
  /*new MathFunc("∫(","eccec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    int samples = 16; //how many smaller sections we'll split our integral into (16 by default)
    if(inp.length>=5) { //if we specify how many sections, set number of sections
      if(inp[4].number.isNatural()) { samples = (int)inp[4].number.re; } //if valid, set the number of sections
      else { return new MathObj("Cannot approximate integral using "+inp[2].number+" samples"); } //otherwise, return error message
    }
    
    int method = 2; //the degree of the polynomial we will use to approximate our integral (0=Riemann sum, 1=trapezoid rule, 2=Simpson's 1/3, etc.). By default we use Simpson's rule to integrate
    if(inp.length>=6) { //if we specify what method we use, use that method
      if(inp[5].number.isWhole()) { method = (int)inp[5].number.re; } //if valid, use that method
      else { return new MathObj("Cannot approximate integral using degree "+inp[3].number+" polynomial"); } //otherwise, return error message
    }
    
    double[] coef; //coefficients for our integral. Depends on the integration method
    switch(method) {
      case 0: coef = new double[] {1,0}; break; //Left-handed Riemann Sum
      case 1: coef = new double[] {0.5,0.5}; break; //Trapezoid rule
      case 2: coef = new double[] {1d/6,4d/6,1d/6}; break; //Simpson's 1/3 rule
      case 3: coef = new double[] {0.125,0.375,0.375,0.125}; break; //Simpson's 3/8 rule
      case 4: coef = new double[] {7d/90,32d/90,12d/90,32d/90,7d/90}; break; //Boole's rule
      case 5: coef = new double[] {19d/288,75d/288,50d/288,50d/288,75d/288,19d/288}; break;
      case 6: coef = new double[] {41d/840,216d/840,27d/840,272d/840,27d/840,216d/840,41d/840}; break;
      case 7: coef = new double[] {751d/17280,3577d/17280,1323d/17280,2989d/17280,2989d/17280,1323d/17280,3577d/17280,751d/17280}; break;
      case 8: coef = new double[] {989d/28350,5888d/28350,-928d/28350,10496d/28350,-4540d/28350,10496d/28350,-928d/28350,5888d/28350,989d/28350}; break;
      case 9: coef = new double[] {2857d/89600,15741d/89600,1080d/89600,19344d/89600,5778d/89600,5778d/89600,19344d/89600,1080d/89600,15741d/89600,2857d/89600}; break;
      case 10: coef = new double[] {16067d/598752,106300d/598752,-48525d/598752,272400d/598752,-260550d/598752,427368d/598752,-260550d/598752,272400d/598752,-48525d/598752,106300d/598752,16067d/598752}; break;
      default: {
        return new MathObj("Okay, you got me, I haven't yet programmed in the ability to numerically integrate with a polynomial of degree 11 or higher.");
      }
    }
    
    MathObj result = new MathObj(); //declare result, initialize to empty math object
    double lerp1 = 1d/samples, lerp2 = method==0 ? lerp1 : lerp1/method;
    for(int n=0;n<samples;n++) {
      for(int k=0;k<coef.length-1;k++) {
        Complex x = inp[1].number.mul(1-lerp1*n-lerp2*k).addeq(inp[2].number.mul(lerp1*n+lerp2*k)); //compute current input value
        map2.put(vari,new MathObj(x)); MathObj y = inp[3].equation.solve(map2);
        
        double coef2 = k==0 ? n==0 ? coef[0] : coef[0]+coef[coef.length-1] : coef[k];
        y.muleq(coef2);
        if(result.type == MathObj.VarType.NONE) { result = y; }
        else                               { result.addeq(y); }
      }
    }
    if(coef[coef.length-1]!=0) { //now, we just have to add the last term
      map2.put(vari,inp[2]); MathObj y = inp[3].equation.solve(map2);
      y.muleq(coef[coef.length-1]);
      result.addeq(y);
    }
    
    //Alright, we've performed the sum. Now, all that's left is to scale it by the correct amount
    Complex scaledRange = inp[2].number.sub(inp[1].number).muleq(lerp1); //compute the range, then divide by the number of samples
    result.muleq(scaledRange); //multiply result by scaled range
    
    return result; //return the result
  } }), new MathFunc("Integral(","eccec?c?",tempFunc)//*/
  
  new MathFunc("∫(","eccec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    int samples = 16; //how many smaller sections we'll split our integral into (16 by default)
    if(inp.length>=5) { //if we specify how many sections, set number of sections
      if(inp[4].number.isNatural()) { samples = (int)inp[4].number.re; } //if valid, set the number of sections
      else { return new MathObj("Cannot approximate integral using "+inp[2].number+" samples"); } //otherwise, return error message
    }
    
    int method = 2; //the degree of the polynomial we will use to approximate our integral (0=Riemann sum, 1=trapezoid rule, 2=Simpson's 1/3, etc.). By default we use Simpson's rule to integrate
    if(inp.length>=6) { //if we specify what method we use, use that method
      if(inp[5].number.isWhole()) { method = (int)inp[5].number.re; } //if valid, use that method
      else { return new MathObj("Cannot approximate integral using degree "+inp[3].number+" polynomial"); } //otherwise, return error message
    }
    
    double[] coef; //coefficients for our integral. Depends on the integration method
    switch(method) {
      case 0: coef = new double[] {1,0}; break; //Left-handed Riemann Sum
      case 1: coef = new double[] {0.5f,0.5f}; break; //Trapezoid rule
      case 2: coef = new double[] {1d/6,4d/6,1d/6}; break; //Simpson's 1/3 rule
      case 3: coef = new double[] {0.125f,0.375f,0.375f,0.125f}; break; //Simpson's 3/8 rule
      case 4: coef = new double[] {7d/90,32d/90,12d/90,32d/90,7d/90}; break; //Boole's rule
      case 5: coef = new double[] {19d/288,75d/288,50d/288,50d/288,75d/288,19d/288}; break;
      case 6: coef = new double[] {41d/840,216d/840,27d/840,272d/840,27d/840,216d/840,41d/840}; break;
      case 7: coef = new double[] {751d/17280,3577d/17280,1323d/17280,2989d/17280,2989d/17280,1323d/17280,3577d/17280,751d/17280}; break;
      case 8: coef = new double[] {989d/28350,5888d/28350,-928d/28350,10496d/28350,-4540d/28350,10496d/28350,-928d/28350,5888d/28350,989d/28350}; break;
      case 9: coef = new double[] {2857d/89600,15741d/89600,1080d/89600,19344d/89600,5778d/89600,5778d/89600,19344d/89600,1080d/89600,15741d/89600,2857d/89600}; break;
      case 10: coef = new double[] {16067d/598752,106300d/598752,-48525d/598752,272400d/598752,-260550d/598752,427368d/598752,-260550d/598752,272400d/598752,-48525d/598752,106300d/598752,16067d/598752}; break;
      default: {
        return new MathObj("Okay, you got me, I haven't yet programmed in the ability to numerically integrate with a polynomial of degree 11 or higher.");
      }
    }
    
    Complex lerp = inp[2].number.sub(inp[1].number).div(samples*(coef.length-1)); //compute the difference between each consecutive piece
    MathObj[] parts = new MathObj[coef.length-1]; //create array of math terms to add up linear combinations of each other
    for(int n=0;n<samples;n++) { //loop through all samples
      for(int k=0;k<parts.length;k++) { //loop through all parts of each sample
        if(n==0&&k==0) { continue; } //skip the far left piece
        
        Complex x = inp[1].number.add(lerp.mul(n*parts.length+k)); //compute the input value
        map2.put(vari,new MathObj(x)); //set the input value
        MathObj y = inp[3].equation.solve(map2); //solve for y given x
        
        if(parts[k]==null) { parts[k] = y; } //if this part is not yet set, initialize it to y
        else          { parts[k].addeq(y); } //otherwise, add y
      }
    }
    for(int k=1;k<parts.length;k++) { parts[k].muleq(coef[k]); } //now, we have to multiply each part by their respective coefficients
    if(parts[0]!=null) { parts[0].muleq(coef[0]+coef[coef.length-1]); } //multiply boundary part by the sum of the left & right coefficients (unless null)
    MathObj sum = null;
    for(int k=0;k<parts.length;k++) { if(parts[k]!=null) { //compute the sum of all the parts (ignoring any null parts)
      if(sum==null) { sum = parts[k];      } //if not initialized, set to this part
      else          { sum.addeq(parts[k]); } //otherwise, add this part
    } }
    
    //now, we just have to add the leftmost & rightmost terms
    if(coef[0]!=0) {
      map2.put(vari,inp[1]); //set the input value
      MathObj y = inp[3].equation.solve(map2).muleq(coef[0]); //solve for y given x, multiply by coefficient
      if(sum==null) { sum = y; } //if not initialized, set to this
      else     { sum.addeq(y); } //otherwise, add this
    }
    if(coef[coef.length-1]!=0) {
      map2.put(vari,inp[2]); //set the input value
      MathObj y = inp[3].equation.solve(map2).muleq(coef[coef.length-1]); //solve for y given x, multiply by coefficient
      if(sum==null) { sum = y; } //if not initialized, set to this
      else     { sum.addeq(y); } //otherwise, add this
    }
    
    sum.muleq(lerp.muleq(parts.length)); //finally, multiply by range / # of samples
    return sum;                          //return result
    
  } }), new MathFunc("Integral(","eccec?c?",tempFunc),
  
  new MathFunc("limit(","ecec?c?",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    Complex input = inp[1].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=4 ? inp[3].number : new Complex(9.765625e-4d); //if we have at least 4 inputs, we've chosen the epsilon. Otherwise, default it to something reasonably small
    int method = 2; //now we must select the number of units we will step away from the middle
    if(inp.length>=5) { //if we have at least 5 inputs, the 4th one is the method we use
      if(inp[4].number.isWhole()) { method = (int)inp[4].number.re; } //if given a (non-negative) int, cast to an int and make that our method
      else { return new MathObj("Cannot approximate limit with a polynomial of non-whole degree"); } //if given a non-whole number, return an error
    }
    
    MathObj result = new MathObj(); //initialize our result to an ambiguous math object, since we don't yet know if our result will be a scalar, vector, etc.
    double coef = -1; //the coefficient of each term, equal to (-1)^(k+1)*m!²/((m+k)!(m-k)!), with m being the method
    for(int k=1;k<=method;k++) { //loop through all the steps we take away from the center
      coef *= k-method-1; coef /= method+k; //update the coefficient
      
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[2].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[2].equation.solve(map2); //solve at x-hk
      
      y1.addeq(y2).muleq(coef); //add them together, multiply by the coefficient
      if(result.type==MathObj.VarType.NONE) { result = y1; } //if not yet initialized, set result to this
      else                             { result.addeq(y1); } //otherwise, add this to our result
    }
    return result; //return our result
  } }),
  
  new MathFunc("Secant(","ecce",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int maxIter = 16; //maximum iterations
    Complex x0 = inp[1].number, x1 = inp[2].number; //grab the first and second guess
    map2.put(vari,inp[1]); MathObj temp = inp[3].equation.solve(map2); //solve at first guess
    if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform secant method on function of type "+temp.type); } //if not a number, return error message
    Complex y0 = temp.number; //record value at first guess
    map2.put(vari,inp[2]); temp = inp[3].equation.solve(map2); //solve at second guess
    if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform secant method on function of type "+temp.type); } //if not a number, return error message
    Complex y1 = temp.number; //record value at second guess
    
    for(int n=0;n<maxIter;n++) { //loop until it's solved or until you run out of iterations
      if(x0.equals(x1) || y1.equals(0)) { break; } //if both guesses equal, or our solution is 0, break from the loop
      Complex newX = (x0.mul(y1).subeq(x1.mul(y0))).diveq(y1.sub(y0)); //compute our next value for x (by drawing a secant line between the last 2 & finding the root)
      x0 = x1; x1 = newX; //update our x values
      map2.put(vari,new MathObj(x1)); temp = inp[3].equation.solve(map2); //solve at this value of x
      if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform secant method on function of type "+temp.type); } //if not a number, return error message
      y0 = y1; y1 = temp.number; //update our y values
    }
    return new MathObj(x1); //return the result
  } }),
  
  new MathFunc("Newton(","ecee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    double err = 0;
    //if(inp.length>=5) { err = inp[4].number.re; }
    
    int maxIter = 16; //maximum iterations
    Complex x = inp[1].number.copy(), y, yp; //x, y, y'
    MathObj temp; //temporary variable
    for(int n=0;n<maxIter;n++) { //loop until it's solved or until you run out of iterations
      map2.put(vari,new MathObj(x)); temp = inp[2].equation.solve(map2); //solve y at x
      if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform Newton's method on function of type "+temp.type); } //if not a number, return error message
      y = temp.number;                  //update y value
      if(y.lazyabs() <= err) { break; } //if close enough, exit loop
      temp = inp[3].equation.solve(map2); //solve y' at x
      if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform Newton's method with derivative of type "+temp.type); } //if not a number, return error message
      yp = temp.number;   //update y' value
      x.subeq(y.div(yp)); //update x using Newton's method
    }
    return new MathObj(x); //return result
  } }),
  
  new MathFunc("Halley(","eceee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].equation.tokens.get(0).id; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    double err = 0;
    //if(inp.length>=5) { err = inp[4].number.re; }
    
    int maxIter = 16;
    Complex x = inp[1].number.copy(), y, yp, ypp;
    MathObj temp;
    for(int n=0;n<maxIter;n++) {
      map2.put(vari,new MathObj(x));
      temp = inp[2].equation.solve(map2); if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform Halley's method on function of type "+temp.type); } //if not a number, return error message
      y = temp.number;                  //update y value
      if(y.lazyabs() <= err) { break; } //if close enough, exit loop
      temp = inp[3].equation.solve(map2); if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform Halley's method with derivative of type "+temp.type); } //if not a number, return error message
      yp = temp.number;
      temp = inp[4].equation.solve(map2); if(temp.type != MathObj.VarType.COMPLEX) { return new MathObj("Cannot perform Halley's method with second derivative of type "+temp.type); } //if not a number, return error message
      ypp = temp.number;
      x.subeq(y.mul(yp).diveq(yp.sq().subeq(y.mul(ypp).muleq(0.5f))));
    }
    return new MathObj(x); //set the result
  } }),
  
  new MathFunc("Euler(","eec.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String inVar = inp[0].equation.tokens.get(0).id, outVar = inp[1].equation.tokens.get(0).id; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 7 or more inputs, the 7th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { return new MathObj("Cannot approximate Euler's method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input each step
    
    Complex x = inp[2].number; //get the initial input
    MathObj y = inp[3];        //and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y); //set the values for our variables
      MathObj k1 = inp[5].equation.solve(map2);           //solve the derivative at this point
      x.addeq(dx); y.addeq(k1.muleq(dx));                 //increase x by dx, increase y by y'*dx
    }
    
    return y; //finally, return our final result
  } }),
  
  new MathFunc("EulerMid(","eec.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String inVar = inp[0].equation.tokens.get(0).id, outVar = inp[1].equation.tokens.get(0).id; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 7 or more inputs, the 7th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { return new MathObj("Cannot approximate midpoint method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input each step
    
    Complex x = inp[2].number; //get the initial input
    MathObj y = inp[3];        //and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y);              //set the values for our variables
      MathObj k1 = inp[5].equation.solve(map2);                        //solve the derivative at this point
      x.addeq(dx.mul(0.5f)); MathObj y2 = y.add(k1.muleq(dx.mul(0.5f))); //increase x by dx/2, increase y by y'*dx/2 (moving us to the midpoint)
      
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2); //set the values for our variables
      MathObj k2 = inp[5].equation.solve(map2);            //solve the derivative at this point
      x.addeq(dx.mul(0.5f)); y.addeq(k2.mul(dx));           //increase x by dx/2 again, increase y by y'(midpoint)*dx
    }
    
    return y; //finally, return our final result
  } }),
  
  new MathFunc("ExpTrap(","eec.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String inVar = inp[0].equation.tokens.get(0).id, outVar = inp[1].equation.tokens.get(0).id; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 7 or more inputs, the 7th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { return new MathObj("Cannot approximate explicit trapezoid method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input each step
    
    Complex x = inp[2].number; //get the initial input
    MathObj y = inp[3];        //and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y);              //set the values for our variables
      MathObj k1 = inp[5].equation.solve(map2);                        //solve the derivative at this point
      x.addeq(dx); MathObj y2 = y.add(k1.mul(dx)); //increase x by dx, increase y by y'*dx (moving us to the endpoint)
      
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2); //set the values for our variables
      MathObj k2 = inp[5].equation.solve(map2);            //solve the derivative at this point
      
      y.addeq(k1.add(k2).mul(dx.mul(0.5f)));           //increase y by (y1'+y2')/2*dx
    }
    
    return y; //finally, return our final result
  } }),
  
  new MathFunc("RK4(","eec.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String inVar = inp[0].equation.tokens.get(0).id, outVar = inp[1].equation.tokens.get(0).id; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 4 or more inputs, the 4th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { return new MathObj("Cannot approximate Runge-Kutta method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input
    
    Complex x = inp[2].number; //get the initial input
    MathObj y = inp[3];        //and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y); //set the values for our valuables
      MathObj k1 = inp[5].equation.solve(map2);           //solve the derivative at this point
      
      x.addeq(dx.mul(0.5f)); MathObj y2 = y.add(k1.mul(dx.mul(0.5f))); //increase x by dx/2, increase y by k1*dx/2
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2);           //set the values for our variables
      MathObj k2 = inp[5].equation.solve(map2);                      //solve the derivative at this point
      
      y2 = y.add(k2.mul(dx.mul(0.5f)));          //increase y by k2*dx/2
      map2.put(outVar,y2);                      //set the values for our variables
      MathObj k3 = inp[5].equation.solve(map2); //solve the derivative at this point
      
      x.addeq(dx.mul(0.5f)); y2 = y.add(k3.mul(dx));        //increase x by dx, increase y by k3*dx
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2); //set the values for our variables
      MathObj k4 = inp[5].equation.solve(map2);            //solve the derivative at this point
      
      y.addeq(k1.add(k2.add(k3).mul(2)).add(k4).muleq(dx.div(6))); //lastly, increase y by dx*(k1+2k2+2k3+k4)/6
    }
    
    return y; //finally, return our result
  } }),
  
  new MathFunc("SetHistoryDepth(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isInt() && inp[0].number.re>5 && inp[0].number.re<=5000) {
      history.changeHistoryDepth((int)inp[0].number.re, true);
      return new MathObj("Done");
    }
    return new MathObj("History depth must be an integer between 6 and 5000");
  } }),
  
  new MathFunc("GetHistoryDepth(","",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(history.entries);
  } })
  
  //null
  //new MathFunc("(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number); } }),
  
  //TODO buildVec, buildMat, d/dx, d2/dx2, integral, limit, Secant, Newton, Halley, Euler, RK4
  //TODO make Equation.funclist just check every item in the function dictionary, make minInps and maxInps just evaluate the regex to figure it out, make recursivecheck just check where in the regex is an e
);


static class SimplePattern { //a class which compactifies & speeds up regex expressions, partially by forbidding certain regex behaviors (only permits certain characters)
  short[] charPat; //shorts describing which of up to 16 chars can be at each point
  short[] min;     //the minimum amount of each char pattern
  short[] max;     //the maximum amount of each char pattern
  int absMin, absMax;
  
  public int size() { return min.length; } //returns the number of entries in this
  
  //used to map characters/variable types to bytes
  static HashMap<Character, Byte> cMatcher = new HashMap<Character, Byte>() {{ put('b',(byte)0); put('c',(byte)1); put('v',(byte)2); put('m',(byte)3); put('d',(byte)4); put('a',(byte)5); put('e',(byte)6); put('M',(byte)7); put('N',(byte)8); }};
  static EnumMap<MathObj.VarType, Byte> vMatcher = new EnumMap<MathObj.VarType, Byte>(MathObj.VarType.class) {{ put(MathObj.VarType.BOOLEAN,(byte)0); put(MathObj.VarType.COMPLEX,(byte)1); put(MathObj.VarType.VECTOR,(byte)2); put(MathObj.VarType.MATRIX,(byte)3); put(MathObj.VarType.DATE,(byte)4); put(MathObj.VarType.ARRAY,(byte)5); put(MathObj.VarType.EQUATION,(byte)6); put(MathObj.VarType.MESSAGE,(byte)7); put(MathObj.VarType.NONE,(byte)8); }};
  
  SimplePattern(String r) { //compiles a regex string into a simple pattern
    ArrayList<Short> cpat = new ArrayList<Short>(), min2 = new ArrayList<Short>(), max2 = new ArrayList<Short>(); //arraylists to store everything
    
    for(int n=0;n<r.length();n++) { //loop through all characters in the string
      switch(r.charAt(n)) { //switch the character at this position
        case '.': cpat.add((short)-1); min2.add((short)1); max2.add((short)1); break; // .: anything, 1 time
        case '*': {
          min2.set(min2.size()-1,(short)0); max2.set(max2.size()-1,Short.MAX_VALUE); //*: the previous entry can happen 0 - inf times
        } break;
        case '+': {
          min2.set(min2.size()-1,(short)1); max2.set(max2.size()-1,Short.MAX_VALUE); //+: the previous entry can happen 1 - inf times
        } break;
        case '?': {
          min2.set(min2.size()-1,(short)0); max2.set(max2.size()-1,(short)1); //?: the previous entry can happen 0 - 1 times
        } break;
        case '[': {
          short putter = 0; //the thing we're going to add to cpat
          boolean negate = false; //whether or not this is going to be negated
          for(n++;r.charAt(n)!=']';n++) { //loop through all characters until we find a right bracket
            if(r.charAt(n)=='^') { negate = true; } //if it has a caret, the whole thing is negated
            else { putter |= gen(r.charAt(n)); } //otherwise, OR this short with our code
          }
          if(negate) { putter ^= -1; } //if we have to negate, negate it all
          cpat.add(putter);                       //add this code to the list
          min2.add((short)1); max2.add((short)1); //give it quantity of 1
        } break;
        case '{': {
          String first = ""; //we have to create the first number in here
          for(n++;r.charAt(n)!='}'&&r.charAt(n)!=',';n++) { //loop through all characters until we find a right curly brace or a comma
            first+=r.charAt(n); //concat each character
          }
          int low = PApplet.parseInt(first); //cast to an integer
          if(r.charAt(n)=='}') { //if there was one number & no comma:
            min2.set(min2.size()-1,(short)low); max2.set(max2.size()-1,(short)low); //set it to the minimum & the maximum
          }
          else if(r.charAt(n+1)=='}') { //if there was one number followed by a single comma
            min2.set(min2.size()-1,(short)low); max2.set(max2.size()-1,Short.MAX_VALUE); //set it to the minimum to it, and the maximum to basically infinity
          }
          else { //if there are 2 numbers separated by a comma:
            String second = ""; //we have to create the second number in here
            for(n++;r.charAt(n)!='}';n++) { //loop through all characters again until we find the right curly brace
              second+=r.charAt(n); //concat each character
            }
            int high = PApplet.parseInt(second); //cast to an integer
            min2.set(min2.size()-1,(short)low); max2.set(max2.size()-1,(short)high); //set the minimum to the first & the maximum to the second
          }
        } break;
        default: {
          cpat.add(gen(r.charAt(n)));             //anything else: put this character here
          min2.add((short)1); max2.add((short)1); //make it happen one time
        }
      }
    }
    
    //now, we just have to simplify. We do this by combining adjacent terms
    for(int n=1;n<cpat.size();n++) { //loop through all entries (except the 0th)
      if(cpat.get(n-1)==cpat.get(n)) { //if two adjacent terms have the same code:
        min2.set(n-1, (short)(min2.get(n-1)+min2.get(n))); //add adjacent minimums
        max2.set(n-1, (short)(max2.get(n-1)+max2.get(n))); //add adjacent maximums
        if(max2.get(n-1)<0) { max2.set(n-1,Short.MAX_VALUE); } //if an overflow occurred, reset to the max value
        cpat.remove(n); min2.remove(n); max2.remove(n); //remove this entry
        n--; //decrement n so we don't skip anything
      }
    }
    
    charPat = new short[cpat.size()]; min = new short[cpat.size()]; max = new short[cpat.size()]; //init the arrays
    for(int n=0;n<cpat.size();n++) { charPat[n]=cpat.get(n); min[n]=min2.get(n); max[n]=max2.get(n); } //copy the contents to the arrays
    
    int[] minMax = minMax();
    absMin = minMax[0]; absMax = minMax[1];
  }
  
  public static byte[] parse(MathObj.VarType[] v) {
    byte[] result = new byte[v.length]; for(int n=0;n<v.length;n++) { result[n] = vMatcher.get(v[n]); } return result;
  }
  
  public static short gen(char c) { return (short)(1<<cMatcher.get(c)); } //generates the short code for this
  public static short gen(MathObj.VarType v) { return (short)(1<<vMatcher.get(v)); } //generates the short code for this
  
  public boolean matches(MathObj[] s) { //returns whether this array of variables matches this simple pattern
    if(s.length<absMin || s.length>absMax) { return false; } //short-circuit: if the expression is too short/too long, immediately return false
    
    int ind2=0; //the index in the string
    for(int ind1=0;ind1<charPat.length;ind1++) { //loop through all indices in the regular expression
      for(int n=0;n<min[ind1];n++) { //loop through the characters that must be consumed
        if(ind2==s.length || (gen(s[ind2].type)&charPat[ind1]) == 0) { return false; } //if this character can't be consumed, return false
        ind2++; //increment the string index
      }
      for(int n=min[ind1];n<max[ind1];n++) { //now, loop through the characters that can be consumed, but don't have to be
        if(ind2==s.length || (gen(s[ind2].type)&charPat[ind1]) == 0) { break; } //if this character can't be consumed, break from the loop
        ind2++; //otherwise, consume it, and increment the string index (note: all quantifiers are greedy. if it can be consumed, it will be consumed)
      }
      /*for(int n=0;n<max[ind1];n++) { //loop through all characters that are to be consumed
        if(ind2==s.length || (gen(s[ind2].type)&charPat[ind1]) == 0) { //this character cannot be consumed if it is out of bounds or it contradicts with the set of characters we're assigned to consume
          if(n<min[ind1]) { return false; } //if we haven't consumed the bare minimum amount of this character, return false (since the expression isn't matched)
          else            { break;        } //if we have consumed enough characters, though, just break and continue to the next consumable
        }
        ++ind2; //if the character can be consumed, however, we "consume" it by just incrementing the index; going to the next character
      }*/
    }
    return ind2==s.length; //if all characters were consumed, return true
  }
  
  public boolean matches(byte[] seq) { //does the same thing, but to a sequence that's been preprocessed into bytes
    if(seq.length<absMin || seq.length>absMax) { return false; } //short-circuit: if the expression is too short/too long, immediately return false
    
    int ind2=0; //the index in the string
    for(int ind1=0;ind1<charPat.length;ind1++) { //loop through all indices in the regular expression
      for(int n=0;n<min[ind1];n++) { //loop through the characters that must be consumed
        if(ind2==seq.length || (1<<seq[ind2]&charPat[ind1]) == 0) { return false; } //if this character can't be consumed, return false
        ind2++; //increment the string index
      }
      for(int n=min[ind1];n<max[ind1];n++) { //now, loop through the characters that can be consumed, but don't have to be
        if(ind2==seq.length || (1<<seq[ind2]&charPat[ind1]) == 0) { break; } //if this character can't be consumed, break from the loop
        ind2++; //otherwise, consume it, and increment the string index (note: all quantifiers are greedy. if it can be consumed, it will be consumed)
      }
    }
    return ind2==seq.length; //if all characters were consumed, return true
  }
  
  public int[] minMax() { //looks at the current regular expression, returns the min & max # of inputs
    int min2 = 0, max2 = 0; //the current minimum & maximum
    for(int n=0;n<size();n++) { //loop through all entries
      min2 += min[n]; //increment the minimum by each minimum
      max2 += max[n]; //increment the maximum by each maximum
    }
    if(max2 >= Short.MAX_VALUE) { max2 = Integer.MAX_VALUE; } //if the computed maximum is above a certain threshold, it is assumed to be infinite
    return new int[] {min2, max2}; //return the result
  }
}
enum ConnectMode { POINT, WIREFRAME, SURFACE }

enum GraphMode {
  RECT2D, POLAR, PARAMETRIC2D, RECT3D, CYLINDRICAL, SPHERICAL, PARAMETRIC3D, NONE;
  
  public int graphDim() { return this==RECT2D || this==POLAR || this==PARAMETRIC2D ? 2 : 3; }
  public int inps() { return graphDim()==2 ? 1 : 2; }
  public int outs() { return this==PARAMETRIC2D ? 2 : this==PARAMETRIC3D ? 3 : 1; }
  
  public String[] inputs() { switch(this) {
    case RECT2D:       return new String[] {"x"};
    case POLAR:        return new String[] {"θ"};
    case PARAMETRIC2D: return new String[] {"t"};
    case RECT3D:       return new String[] {"x","y"};
    case CYLINDRICAL:  return new String[] {"θ","r"};
    case SPHERICAL:    return new String[] {"θ","φ"};
    case PARAMETRIC3D: return new String[] {"t","u"};
    default:           return new String[0];
  } }
  
  public String outVar() { switch(this) {
    case RECT2D: return "y";
    case POLAR:  return "r";
    case PARAMETRIC2D: case PARAMETRIC3D: return "v";
    case RECT3D:       case CYLINDRICAL:  return "z";
    case SPHERICAL: return "ρ";
    default: return null;
  } }
  
  public MathObj.VarType outType() {
    if(this==PARAMETRIC2D || this==PARAMETRIC3D) { return MathObj.VarType.VECTOR; }
    return MathObj.VarType.COMPLEX;
  }
  
  public GraphMode increment() { switch(this) {
    case NONE: return NONE;
    case RECT2D: return POLAR;
    case POLAR: return PARAMETRIC2D;
    case PARAMETRIC2D: return RECT2D;
    case RECT3D: return CYLINDRICAL;
    case CYLINDRICAL: return SPHERICAL;
    case SPHERICAL: return PARAMETRIC3D;
    case PARAMETRIC3D: return RECT3D;
    default: return null;
  } }
}

public static class Graphable { //graphable function
  public int stroke = 0xffFF8000;
  public int strokeWeight = 2;
  public GraphMode mode = GraphMode.RECT2D;
  public boolean visible = true;
  boolean par1D = false; //true in the special case that we're in 3D plotting a parametric curve (as opposed to a parametric surface)
  
  public double start=-Math.PI, end=Math.PI; //TODO make it so this can be a function of our graph position/scale
  public int steps = 1024;
  
  Equation function; //equation to map the input to the output
  
  Graphable(int col, Equation equat) {
    stroke=col;
    function = equat;
  }
  
  public void setVisible(boolean vis) { visible=vis; }
  
  public void setMode(GraphMode m) { mode = m; }
  public void setSteps(int s) { steps = s; }
  
  public void verify1DParametric() { //determines whether it's a 1-D parametric
    if(mode!=GraphMode.PARAMETRIC3D) { par1D = false; } //if not paramtric 3D, we already know it's false
    else { par1D = !function.checkForVar("u"); } //otherwise, check if there are any mentions of the variable "u". If there are, set it to false. If not, set it to true
  }
  
  //public int step = 1; //step size
}

public class Graph { //an object which can graph things out
  
  ////////// ATTRIBUTES //////////////
  
  double origX, origY;    //the pixel position of the origin on the pgraphics object
  double pixPerUnit;      //the number of pixels in a single unit length
  float tickLen=0.066666667f*width; //the length of the tick lines, in pixels
  boolean visible = true; //whether the graph is visible
  
  ///////// CONSTRUCTORS /////////////
  
  Graph() { }
  
  Graph(double x, double y, double s) { origX=x; origY=y; pixPerUnit=s; } //constructor w/ attributes
  
  ////////// GETTERS/SETTERS ////////////////
  
  public Graph setVisible(boolean vis) { visible=vis; return this; }
  
  
  /////////////////// DISPLAY ////////////////////
  
  public void display(PGraphics pgraph, float x, float y, float wid, float hig, ArrayList<Graphable> plots) {
    if(!visible) { return; } //if invisible, quit
    
    drawGridLines(pgraph, x, y, wid, hig);
    
    graph2D(pgraph, x,y,wid,hig,plots);
  }
  
  public void drawGridLines(PGraphics pgraph, float xt, float yt, float wid, float hig) { //sets up the graph by drawing all the gridlines
    //Step 1: Find how far apart each gridline should be
    //First, note the desired behavior. At original scale, each tick mark will be 1 apart. Then, as we zoom out, it'll be 2 apart. Then 5, then 10, then 20, 50, 100, 200, 500, 1000, etc.
    //The rule of thumb is to have their distance be the smallest they can be while still being at least hig/12 pixels apart. Without the above rule, that would make our tick size hig/(12*pixPerUnit) units apart
    
    //Since this is on a base 10 logarithmic scale, a logical first step would be to take the base 10 logarithm of our hypothetical tick size
    double log = Math.log(hig/(12.0f*pixPerUnit))/Math.log(10); //according to our rule, the tick size should be >= 10^log
    double ceil = Math.ceil(log), frac = ceil-log; //record the ceiling of the log, as well as the fractional difference. Our tick size should either be 10^ceil, 1/2*10^ceil, or 1/5*10^ceil.
    String ticAsString;   //to get an EXACT decimal tick size w/out roundoff, we'll compute the tick size as a string then cast to a double
    double splitSize; //we'll also be drawing fainter lines between the ticks, and we also need to compute the distance between those. But they don't need to be as accurate
    int splitPerTick; //number of splitter lines per tick
    if     (frac<Math.log(2)/Math.log(10)) { ticAsString = "1E"+(long)ceil;     splitPerTick = 5; } //0 <= frac < log10(2): 10^ceil
    else if(frac<Math.log(5)/Math.log(10)) { ticAsString = "5E"+(long)(ceil-1); splitPerTick = 5; } //log10(2) <= frac < log10(5): 10^ceil / 2
    else                                   { ticAsString = "2E"+(long)(ceil-1); splitPerTick = 4; } //log10(5) <= frac < 1: 10^ceil / 5
    
    double tickSize = Double.valueOf(ticAsString); //cast string to double, now we have the tick size
    splitSize = tickSize/splitPerTick;             //compute split size
    
    //Step 2: Find where to draw the first & last gridlines. You should overshoot in all directions, so that the splitters between them don't disappear right before the edge of the screen.
    long xStart = (long)Math.floor((xt    -origX)/(pixPerUnit*tickSize)), //which multiple of tickSize to start with in the x direction
         xEnd   = (long)Math.ceil ((xt+wid-origX)/(pixPerUnit*tickSize)), //which multiple to end with
         yStart = (long)Math.floor((origY-yt-hig)/(pixPerUnit*tickSize)), //same in the y direction, but different because up/down are reversed on screens
         yEnd   = (long)Math.ceil ((origY-yt    )/(pixPerUnit*tickSize)); //same in the y direction
    
    //Step 3: Draw the splitter lines between each tick
    pgraph.stroke(24); pgraph.strokeWeight(2); //set the drawing parameters
    for(long x=xStart;x<xEnd;x++) {     //loop through all ticks in the x direction
      for(int n=0;n<splitPerTick;n++) { //draw the 4-5 splitters
        pgraph.line((float)(origX+(x*tickSize+n*splitSize)*pixPerUnit),yt,(float)(origX+(x*tickSize+n*splitSize)*pixPerUnit),yt+hig); //draw the vertical splitter lines
      }
    }
    for(long y=yStart;y<yEnd;y++) {     //now, just do the same thing in the y direction
      for(int n=0;n<splitPerTick;n++) { //draw the 4-5 splitters
        pgraph.line(xt,(float)(origY-(y*tickSize+n*splitSize)*pixPerUnit),xt+wid,(float)(origY-(y*tickSize+n*splitSize)*pixPerUnit)); //draw the horizontal splitter lines
      }
    }
    
    //Step 4: Draw the axes
    pgraph.stroke(255); pgraph.strokeWeight(2); //set the drawing parameters
    pgraph.line(xt,(float)origY,xt+wid,(float)origY); //draw the x-axis
    pgraph.line((float)origX,yt,(float)origX,yt+hig); //draw the y axis
    
    //Step 5: Draw the ticks along each axis
    float xCut=constrain((float)origX,xt,xt+wid), yCut=constrain((float)origY,yt,yt+hig); //the tick marks should be displayed, regardless of if the axes are on screen. Here are their positions on screen
    for(long x=xStart;x<xEnd;x++) { //loop through all ticks in the x direction
      if(x!=0) { pgraph.line((float)(origX+x*tickSize*pixPerUnit),yCut-0.5f*tickLen,(float)(origX+x*tickSize*pixPerUnit),yCut+0.5f*tickLen); } //draw each tick at appropriate lengths
    }
    for(long y=yStart;y<yEnd;y++) { //loop through all ticks in the y direction
      if(y!=0) { pgraph.line(xCut-0.5f*tickLen,(float)(origY-y*tickSize*pixPerUnit),xCut+0.5f*tickLen,(float)(origY-y*tickSize*pixPerUnit)); } //draw each tick at appropriate lengths
    }
    
    //Step 5: Label each tick mark
    boolean topOrBottom = origY>yt+hig-tickLen, leftOrRight = origX>xt+tickLen; //decide on which side of each axis the labels are gonna go
    
    pgraph.textAlign(CENTER,topOrBottom ? BOTTOM : TOP);
    for(long x=xStart;x<xEnd;x++) { //loop through all ticks in the x direction
      if(x==0) { continue; }
      String label = new Complex(x*tickSize).toString(12);
      float sizer = io.getTextWidth(label,20); pgraph.textSize(min(0.044444444f*width,(float)(20*0.9f*tickSize*pixPerUnit/sizer))); //set the textSize so that text does not overlap
      pgraph.text(label,(float)(origX+x*tickSize*pixPerUnit),yCut-(topOrBottom?0.625f:-0.625f)*tickLen);
    }
    
    pgraph.textSize(0.044444444f*width);
    pgraph.textAlign(leftOrRight ? RIGHT : LEFT, CENTER);
    for(long y=yStart;y<yEnd;y++) { //loop through all ticks in the x direction
      if(y==0) { continue; }
      String label = new Complex(y*tickSize).toString(12);
      pgraph.text(label,xCut-(leftOrRight?0.625f:-0.625f)*tickLen,(float)(origY-y*tickSize*pixPerUnit));
    }
  }
  
  public void graph2D(PGraphics pgraph, float xt, float yt, float wid, float hig, ArrayList<Graphable> gr) {
    for(Graphable f : gr) {
      graph2D(pgraph,xt,yt,wid,hig,f);
    }
  }
  
  public void graph2D(PGraphics pgraph, float xt, float yt, float wid, float hig, Graphable f) {
    if(!visible || !f.visible || f.function.isEmpty()) { return; } //if the graph or graphable isn't visible, or the equation is empty, quit
    
    pgraph.stroke(f.stroke); pgraph.strokeWeight(f.strokeWeight); pgraph.noFill(); //set drawing parameters
    
    graph2DFunc(pgraph, xt, yt, wid, hig, f); //use method for plotting it out
  }
  
  public void graph2DFunc(PGraphics pgraph, float xt, float yt, float wid, float hig, Graphable f) { //graphs the given 2D function
    HashMap<String, MathObj> feed = new HashMap<String, MathObj>(); //is fed into the solve function
    boolean works, worked=false; //whether this current point is plottable, whether the previous point was plottable
    boolean curr, prev=false;                                                 //whether we are currently in bounds, whether we were in bounds
    float xCurr=Float.NaN, yCurr=Float.NaN, xPrev=Float.NaN, yPrev=Float.NaN; //the current & previous point we plot/plotted
    
    double stepSize = (f.mode==GraphMode.RECT2D) ? 1d/pixPerUnit : (f.end-f.start)/f.steps; //how much the input increases by each iteration
    int steps = (f.mode==GraphMode.RECT2D) ? round(wid) : f.steps;
    
    double cos=0, sin=0, cosStep=0, sinStep=0; //used only for making polar graphs easier
    if(f.mode==GraphMode.POLAR) { cos=Math.cos(f.start); sin=Math.sin(f.start); cosStep=Math.cos(stepSize); sinStep=Math.sin(stepSize); }
    
    //For the sake of making calculations work, the grapher will pretend that the point right before the loop started and right after it ends are unplottable points.
    //This will force a beginShape to be called in the loop at the first plottable point, and force endshape to be called after the last plottable point. If nothing was plottable & on screen, nothing happens.
    for(int n=0;n<=steps;n++) { //loop through all x values (or whatever the input is)
      
      double inp = (f.mode==GraphMode.RECT2D) ? (xt+n-origX)*stepSize : n*stepSize+f.start; //compute current input
      
      feed.put(f.mode.inputs()[0],new MathObj(new Complex(inp))); //tell the solver to plug in this value for x/θ/t
      
      MathObj out = f.function.solve(feed); //compute the output
      if(out.type == f.mode.outType()) {    //if output type is compatible with graph type:
        if(out.isNum()) { works = out.number.isReal() && Double.isFinite(out.number.re); } //if number, we mark this point as plottable if it's real and finite
        else { works = out.vector.size()==2 && out.vector.isReal() && Double.isFinite(out.vector.get(0).re) && Double.isFinite(out.vector.get(1).re); } //if vector, we mark as plottable if 2D, real, and finite
      }
      else { works = false; } //otherwise, it isn't plottable
      //TODO give slight leeway for numbers with very small imaginary part, adjust algorithm so odd vertical asymptotes don't get connected
      
      if(works) { //if point is plottable:
        switch(f.mode) { //figure out which point we're plotting
          case RECT2D: {
            double y = out.number.re; //find point to plot
            xCurr = xt+n; yCurr = (float)(origY-y*pixPerUnit);
          } break;
          
          case POLAR: {
            double r = out.number.re; //find point to plot
            xCurr = (float)(origX+r*cos*pixPerUnit); yCurr = (float)(origY-r*sin*pixPerUnit);
          } break;
          
          case PARAMETRIC2D: {
            double x = out.vector.get(0).re, y = out.vector.get(1).re;
            xCurr = (float)(origX+x*pixPerUnit); yCurr = (float)(origY-y*pixPerUnit);
          } break;
        }
        
        if(!Float.isFinite(xCurr) && !Float.isNaN(xCurr)) {
          xCurr = xCurr>0 ? Float.MAX_VALUE : -Float.MAX_VALUE;
        }
        if(!Float.isFinite(yCurr) && !Float.isNaN(yCurr)) {
          yCurr = yCurr>0 ? Float.MAX_VALUE : -Float.MAX_VALUE;
        }
      }
      else { xCurr = yCurr = Float.NaN; } //otherwise, set the point to NaN, NaN
      
      //next, figure out whether the current AND previous point are in bounds (if they're not plottable, they're not in bounds either, by way of vacuous truth)
      curr = xCurr>=0 && xCurr<=wid+xt && yCurr>=0 && yCurr<=hig+yt; //calculate whether or not this point is on screen
       
      if(curr && !prev)           { pgraph.beginShape();        } //if the previous point wasn't plotted (either unplottable or off screen), begin shape
      if(curr && worked && !prev) { pgraph.vertex(xPrev,yPrev); } //if the previous point was off screen, and the current point is on screen, plot the previous point to connect the dots
      if(curr || works && prev)   { pgraph.vertex(xCurr,yCurr); } //if the current point is on screen, or the previous point was on screen (to connect the dots), plot this point
      if(!curr && prev)           { pgraph.endShape();          } //if the previous point was on screen, but the current point is unplottable or off screen, end shape
      
      if(f.mode==GraphMode.POLAR) { double cos2 = cos; cos = cos*cosStep - sin*sinStep; sin = cos2*sinStep + sin*cosStep; } //if in polar mode, use this angle addition formula each iteration to avoid using too much trig
      
      xPrev = xCurr; yPrev = yCurr; //set prev to curr
      prev = curr;                  //set prev to curr
      worked = works;               //set worked to works
    }
    if(prev) { pgraph.endShape(); } //if the previous point was in bounds, end connecting the dots
  }
  
  /*
  works  curr  worked  prev  what do
    0      0      0     0      nothing
    0      0      1     0      nothing (it was taken care of)
    0      0      1     1    endShape();
    1      0      0     0      nothing (it'll be taken care of)
    1      0      1     0      nothing (don't connect the asymptotes)
    1      0      1     1    vertex(curr); endShape();
    1      1      0     0    beginShape(); vertex(curr);
    1      1      1     0    beginShape(); vertex(prev); vertex(curr);
    1      1      1     1    vertex(curr);
  
  beginShape(): works && curr && (!worked || !prev)
  vertex(prev): works && curr && worked && !prev
  vertex(curr): works && (curr || worked && prev)
  endShape  (): (!works || !curr) && worked && prev
  
  curr implies works, therefore works && curr is the same as curr
  prev implies worked, therefore worked && prev is the same as prev
  
  beginShape(): curr && !prev
  vertex(prev): curr && worked && !prev
  vertex(curr): curr || works && prev
  endShape  (): !curr && prev
  */
  
  ////////////////// UPDATES /////////////////
  
  public void updateFromTouches(Mmio mmio, float xt, float yt) { //uses MMIO's cursors & mouse wheel to update shift & scale
    if(!visible) { return; } //if not visible, don't interact
    
    ArrayList<Cursor> interact = new ArrayList<Cursor>(); //arraylist of all cursors which are interacting with the graph
    for(Cursor curs : mmio.cursors) { //loop through all cursors
      if(curs.anyPressed() && (curs.getSelect()==null || curs.getSelect() instanceof Mmio)) { interact.add(curs); } //add all cursors which are pressing and are selecting nothing (or selecting the MMIO)
    }
    
    if(interact.size()==1) { //if exactly one cursor is touching it, we only translate:
      origX += interact.get(0).x - interact.get(0).dx; //shift x by delta x
      origY += interact.get(0).y - interact.get(0).dy; //shift y by delta y
    }
    else if(interact.size()==2) { //(Android only) if exactly 2 cursors are touching it, we translate AND scale:
      Cursor c0 = interact.get(0), c1 = interact.get(1); //load both cursors
      
      //1: scale
      float ratio = sqrt((sq(c0.x-c1.x)+sq(c0.y-c1.y))/(sq(c0.dx-c1.dx)+sq(c0.dy-c1.dy))); //compute the ratio between the distance between both cursors before & after
      pixPerUnit *= ratio; //the size of a unit (in pixels) expands by this ratio
      
      //2: translate. This has to be done in steps
      origX-=0.5f*(c0.dx+c1.dx); origY-=0.5f*(c0.dy+c1.dy); //1 un-translate by previous midpoint
      origX*=ratio; origY*=ratio;                         //2 scale up by the scale factor
      origX+=0.5f*(c0.x+c1.x); origY+=0.5f*(c0.y+c1.y);     //3 re-translate by current midpoint
    }
    
    if(mmio.wheelEventX!=0 || mmio.wheelEventY!=0) { //(PC only) if the mousewheel has moved, we translate AND scale:
      Cursor curs = mmio.cursors.get(0); //load the cursor (it's PC, so there's exactly 1 cursor: the mouse)
      
      //1: scale
      float scale = pow(1.1f,-mmio.wheelEventY-2*mmio.wheelEventX); //compute the amount by which we scale up/down
      pixPerUnit *= scale; //the size of a unit (in pixels) expands by this scale factor
      
      //2: translate. This has to be done in steps
      origX-=curs.x; origY-=curs.y; //1 un-translate by mouse position
      origX*=scale; origY*=scale;   //2 scale up by the scale factor
      origX+=curs.x; origY+=curs.y; //3 re-translate by mouse position
    }
  }
}

public class Graph3D extends Graph {
  //something should be noted. For the sake of complying with the general accepted right hand rule, we will be plotting coordinates as such: <x,-z,-y>
  
  ////////// ATTRIBUTES //////////////
  
  double origZ; //the z location of the origin
  PMatrix3D reference =new PMatrix3D(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1), //the matrix we rotate the whole thing by
            referenceT=new PMatrix3D(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1); //its transpose (and also its inverse)
  PGraphics graph; //the pgraphics object used to draw in 3D
  
  ////////// CONSTRUCTORS //////////////
  
  Graph3D() { tickLen = 0.01f*width; }
  
  Graph3D(double x, double y, double z, int w, int h, double s) { origX=x; origY=y; origZ=z; graph = createGraphics(w,h,P3D); pixPerUnit=s; tickLen = 0.01f*width; } //constructor w/ attributes
  
  ////////// GETTERS/SETTERS ////////////////
  
  public Graph3D setVisible(boolean v) { return (Graph3D)super.setVisible(v); }
  
  /////////////////// DISPLAY ////////////////////
  
  public void display(PGraphics pgraph, float x, float y, float wid, float hig, ArrayList<Graphable> plots) {
    if(!visible) { return; } //if invisible, quit
    
    graph.beginDraw();
    graph.background(0);
    graph.perspective(PI/3.0f, PApplet.parseFloat(graph.width)/PApplet.parseFloat(graph.height), 0.01f, 5.0f*sqrt(3)*graph.height);
    graph.translate(0.5f*graph.width,0.5f*graph.height,graph.height*sqrt(3)/2);
    graph.translate(0,0,-200);
    graph.applyMatrix(reference);
    
    drawGridLines(graph);
    
    graph3D(graph, plots, equatList.connect);
    
    graph.endDraw();
    pgraph.image(graph,x,y);
  }
  
  public void drawGridLines(PGraphics pgraph) {
    //Step 1: Find how far apart each gridline should be
    //First, note the desired behavior. At original scale, each tick mark will be 1 apart. Then, as we zoom out, it'll be 2 apart. Then 5, then 10, then 20, 50, 100, 200, 500, 1000, etc.
    //The rule of thumb is to have their distance be the smallest they can be while still being at least 1/8 "pixels" apart. Without the above rule, that would make our tick size 1/(8*pixPerUnit) units apart
    
    //Since this is on a base 10 logarithmic scale, a logical first step would be to take the base 10 logarithm of our hypothetical tick size
    double log = Math.log(1/(8*pixPerUnit))/Math.log(10); //according to our rule, the tick size should be >= 10^log
    double ceil = Math.ceil(log), frac = ceil-log; //record the ceiling of the log, as well as the fractional difference. Our tick size should either be 10^ceil, 1/2*10^ceil, or 1/5*10^ceil.
    String ticAsString;   //to get an EXACT decimal tick size w/out roundoff, we'll compute the tick size as a string then cast to a double
    double splitSize; //we'll also be drawing fainter lines between the ticks, and we also need to compute the distance between those. But they don't need to be as accurate
    int splitPerTick; //number of splitter lines per tick
    if     (frac<Math.log(2)/Math.log(10)) { ticAsString = "1E"+(long)ceil;     splitPerTick = 5; } //0 <= frac < log10(2): 10^ceil
    else if(frac<Math.log(5)/Math.log(10)) { ticAsString = "5E"+(long)(ceil-1); splitPerTick = 5; } //log10(2) <= frac < log10(5): 10^ceil / 2
    else                                   { ticAsString = "2E"+(long)(ceil-1); splitPerTick = 4; } //log10(5) <= frac < 1: 10^ceil / 5
    
    double tickSize = Double.valueOf(ticAsString); //cast string to double, now we have the tick size
    splitSize = tickSize/splitPerTick;             //compute split size
    
    //Step 2: Find where to draw the first & last gridlines. You should overshoot in all directions, so that the splitters between them don't disappear right before the edge of the screen.
    long xStart = (long)Math.ceil((-1-origX)/(pixPerUnit*tickSize)), //which multiple of tickSize to start with in the x direction
         xEnd   = (long)Math.ceil(( 1-origX)/(pixPerUnit*tickSize)), //which multiple to end with
         yStart = (long)Math.ceil((-1-origY)/(pixPerUnit*tickSize)), //same in the y direction, but different because up/down are reversed on screens
         yEnd   = (long)Math.ceil(( 1-origY)/(pixPerUnit*tickSize)), //same in the y direction
         zStart = (long)Math.ceil((-1-origZ)/(pixPerUnit*tickSize)), //same in the z direction
         zEnd   = (long)Math.ceil(( 1-origZ)/(pixPerUnit*tickSize)); //same in the z direction
    
    
    //Step 3: Draw the axes
    if(equatList.axisMode!=0) { //first, make sure we're allowed to display axes (note: tickmarks/labels won't be shown if axes aren't shown)
      pgraph.stroke(255);
      float xCut = constrain((float)origX,-1,1), yCut = constrain((float)origY,-1,1), zCut = constrain((float)origZ,-1,1);
      pgraph.line(-50,-50*zCut,-50*yCut,50,-50*zCut,-50*yCut);
      pgraph.line(50*xCut,-50*zCut,-50,50*xCut,-50*zCut,50);
      pgraph.line(50*xCut,-50,-50*yCut,50*xCut,50,-50*yCut);
      //pgraph.stroke(255); pgraph.noFill(); pgraph.box(100);
      
      //Step 4: Draw the ticks along each axis
      if(equatList.axisMode!=1) { //make sure we're allowed to show ticks & labels
        //PGraphics labelShow = createGraphics(10,10);
        for(long x=xStart;x<xEnd;x++) { //loop through all ticks in the x direction
          if(x!=0) {
            pgraph.line(50*(float)(origX+x*tickSize*pixPerUnit),-50*zCut,-50*yCut-0.5f*tickLen,50*(float)(origX+x*tickSize*pixPerUnit),-50*zCut,-50*yCut+0.5f*tickLen); //draw each tick at appropriate lengths
            
            /*String label = new Complex(x*tickSize).toString(12);
            //float sizer = io.getTextWidth(label,20); pgraph.textSize(10); //set the textSize so that text does not overlap
            //pgraph.text(label,(float)(origX+x*tickSize*pixPerUnit),yCut-(topOrBottom?0.625:-0.625)*tickLen);
            labelShow.beginDraw();
            labelShow.background(0x00FFFFFF);
            labelShow.fill(255); labelShow.text(label,0,0);
            labelShow.endDraw();
            pgraph.image(labelShow,50*(float)(origX+x*tickSize*pixPerUnit),-50*zCut);
            //pgraph.text(label,50*(float)(origX+x*tickSize*pixPerUnit),-50*zCut,-50*yCut);*/
          }
        }
        for(long y=yStart;y<yEnd;y++) { //loop through all ticks in the y direction
          if(y!=0) {
            pgraph.line(50*xCut,-50*zCut-0.5f*tickLen,-50*(float)(origY+y*tickSize*pixPerUnit),50*xCut,-50*zCut+0.5f*tickLen,-50*(float)(origY+y*tickSize*pixPerUnit)); //draw each tick at appropriate lengths
          }
        }
        for(long z=zStart;z<zEnd;z++) { //loop through all ticks in the z direction
          if(z!=0) {
            pgraph.line(50*xCut-0.5f*tickLen,-50*(float)(origZ+z*tickSize*pixPerUnit),-50*zCut,50*xCut+0.5f*tickLen,-50*(float)(origZ+z*tickSize*pixPerUnit),-50*zCut); //draw each tick at appropriate lengths
          }
        }
      }
    }
  }
  
  public void graph3D(PGraphics pgraph, ArrayList<Graphable> plots, ConnectMode mode) {
    if(mode==ConnectMode.SURFACE) { pgraph.lights(); }
    
    for(Graphable f : plots) {
      graph3D(pgraph,f,mode);
    }
    
    /*pgraph.stroke(#FF8000); pgraph.noFill();
    
    double[][] zs = new double[101][101];
    for(int x1=0;x1<=100;x1++) { for(int y1=0;y1<=100;y1++) {
      double x2 = (x1-50)/(50*pixPerUnit)-origX, y2 = (y1-50)/(50*pixPerUnit)-origY;
      zs[x1][y1] = x2*x2-y2*y2;
      //pgraph.point(x1,50*(float)(origZ-z2*pixPerUnit),-y1);
    } }
    
    switch(mode) {
      case 0: {
        for(int x1=0;x1<=100;x1++) { for(int y1=0;y1<=100;y1++) {
          pgraph.point(x1-50,-50*(float)zs[x1][y1],50-y1);
        } }
      } break;
      case 1: {
        for(int x1=0;x1<=100;x1++) { pgraph.beginShape(); for(int y1=0;y1<=100;y1++) {
          pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1);
        } pgraph.endShape(); }
        for(int y1=0;y1<=100;y1++) { pgraph.beginShape(); for(int x1=0;x1<=100;x1++) {
          pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1);
        } pgraph.endShape(); }
      } break;
      case 2: {
        pgraph.fill(#FF8000); pgraph.noStroke();
        for(int x1=0;x1<100;x1+=2) { for(int y1=0;y1<100;y1+=2) {
          pgraph.beginShape(); pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1); pgraph.vertex(x1-48,-50*(float)zs[x1+2][y1],50-y1); pgraph.vertex(x1-48,-50*(float)zs[x1+2][y1+2],48-y1); pgraph.endShape();
          pgraph.beginShape(); pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1); pgraph.vertex(x1-50,-50*(float)zs[x1][y1+2],48-y1); pgraph.vertex(x1-48,-50*(float)zs[x1+2][y1+2],48-y1); pgraph.endShape();
        } }
      } break;
    }*/
  }
  
  public void graph3D(PGraphics pgraph, Graphable f, ConnectMode mode) {
    if(!visible || !f.visible || f.function.isEmpty()) { return; } //if the graph or graphable isn't visible, or the equation is empty, quit
    if(f.par1D && mode==ConnectMode.SURFACE) { mode = ConnectMode.WIREFRAME; } //special case: parametric curves can't have a surface mode, so we instead draw the wireframe (connect the dots)
    
    pgraph.stroke(f.stroke); pgraph.strokeWeight(f.strokeWeight); pgraph.noFill(); //set drawing parameters
    if(mode==ConnectMode.SURFACE) { pgraph.noStroke(); pgraph.fill(f.stroke); } //special case: if in surface mode, fill the triangles, don't draw borders
    
    graph3DFunc(pgraph, f, mode); //use method for plotting it out
    
    /*pgraph.fill(#FF8000); pgraph.stroke(#FF8000);
    
    
    for(float x1=-50;x1<=50;x1++) { for(float y1=-50;y1<=50;y1++) {
      double x2 = x1/(50*pixPerUnit)-origX, y2 = y1/(50*pixPerUnit)-origY;
      double z2 = x2*x2+y2*y2;
      pgraph.point(x1,50*(float)(origZ-z2*pixPerUnit),-y1);
    } }*/
  }
  
  public void graph3DFunc(PGraphics pgraph, Graphable f, ConnectMode mode) {
    HashMap<String, MathObj> feed = new HashMap<String, MathObj>(); //is fed into the solve function
    
    int steps1 = mode==ConnectMode.SURFACE ? f.steps>>1 : f.steps; //number of steps for the first input
    if(f.par1D) { steps1*=10; } //if 1-D parametric, we can use way more steps
    else if(f.mode==GraphMode.PARAMETRIC3D) { steps1>>=1; }
    double start1 = f.mode==GraphMode.RECT3D ? origX-1d/pixPerUnit : f.start; //starting point for the first input
    double end1 = f.mode==GraphMode.RECT3D ? origX+1d/pixPerUnit : f.end;     //ending point for the first input
    double scale1 = (end1-start1)/steps1;       //how far apart each consecutive input is
    
    int steps2 = f.par1D ? 1 : steps1;           //number of steps for the second input
    if(f.mode==GraphMode.PARAMETRIC3D) { steps2>>=1; }
    double start2, end2; //starting & ending point for the second input
    if(f.mode==GraphMode.RECT3D) { start2=origY-1d/pixPerUnit; end2=origY+1d/pixPerUnit; }
    else if(f.mode==GraphMode.CYLINDRICAL) { //in cylindrical, it's a bit tricky:
      double inv = 1d/pixPerUnit;
      end2 = Math.sqrt(Cpx.sq(Math.abs(origX)+inv)+Cpx.sq(Math.abs(origY)+inv)); //ending r: take the farthest out coords from the origin & find its magnitude
      double xPart = origX<inv && origX>-inv ? 0 : Cpx.sq(Math.abs(origX)-inv); //find the smallest x² (if 0 is over the interval, it's 0. Otherwise, it's the closest corner)
      double yPart = origY<inv && origY>-inv ? 0 : Cpx.sq(Math.abs(origY)-inv); //find the smallest y²
      start2 = Math.sqrt(xPart+yPart); //compute the magnitude
    }
    else { start2=f.start; end2=f.end; }
    double scale2 = (end2-start2)/steps2; //how far apart each consecutive input is
    
    double cos1=0,sin1=0,cosStep1=0,sinStep1=0, //used for making cylindrical & spherical graphs easier
           cos2=0,sin2=0,cosStep2=0,sinStep2=0, //used for making spherical graphs easier
           cos2i=0,sin2i=0;                     //used to reinitialize phi when restarting a loop
    if(f.mode==GraphMode.CYLINDRICAL || f.mode==GraphMode.SPHERICAL) { cos1=Math.cos(start1); sin1=Math.sin(start1); cosStep1=Math.cos(scale1); sinStep1=Math.sin(scale1); } //set variables if needed
    if(f.mode==GraphMode.SPHERICAL) { cos2=cos2i=Math.cos(start2); sin2=sin2i=Math.sin(start2); cosStep2=Math.cos(scale2); sinStep2=Math.sin(scale2); } //set variables if needed
    
    //first, we generate our values
    double[][][] points = new double[steps1+1][steps2+1][3]; //create a 2D array of 3D vectors
    for(int m=0;m<=steps1;m++) { //loop through values for the 1st input variable
      double inp1 = start1+scale1*m; //compute 1st input
      feed.put(f.mode.inputs()[0],new MathObj(new Complex(inp1))); //tell the solver to plug in this value for x/θ/t
      for(int n=0;n<=steps2;n++) { //loop through the values for the 2nd input variable
        double inp2 = start2+scale2*n; //compute 2nd input
        feed.put(f.mode.inputs()[1],new MathObj(new Complex(inp2))); //tell the solver to plug in this value for y/r/φ/u
        
        MathObj out = f.function.solve(feed); //compute the output
        switch(f.mode) {
          case RECT3D: {
            points[m][n][0]=inp1; points[m][n][1]=inp2;
            if(out.isNum() && out.number.isReal()) { points[m][n][2]=out.number.re; }
            else { points[m][n][2] = Double.NaN; }
          } break;
          case CYLINDRICAL: {
            points[m][n][0]=inp2*cos1; points[m][n][1]=inp2*sin1;
            if(out.isNum() && out.number.isReal()) { points[m][n][2]=out.number.re; }
            else { points[m][n][2] = Double.NaN; }
          } break;
          case SPHERICAL: {
            if(out.isNum() && out.number.isReal()) { points[m][n][0]=out.number.re*cos1*sin2; points[m][n][1]=out.number.re*sin1*sin2; points[m][n][2]=out.number.re*cos2; }
            else { points[m][n][0]=points[m][n][1]=points[m][n][2]=Double.NaN; }
          } break;
          case PARAMETRIC3D: {
            if(out.isVector() && out.vector.size()==3 && out.vector.isReal()) {
              for(int k=0;k<3;k++) { points[m][n][k]=out.vector.get(k).re; }
            }
            else {
              for(int k=0;k<3;k++) { points[m][n][k]=Double.NaN; }
            }
          } break;
        }
        
        if(f.mode==GraphMode.SPHERICAL) { double cos3 = cos2; cos2 = cos2*cosStep2 - sin2*sinStep2; sin2 = cos3*sinStep2 + sin2*cosStep2; } //if spherical, update phi
      }
      if(f.mode==GraphMode.CYLINDRICAL || f.mode==GraphMode.SPHERICAL) { double cos3 = cos1; cos1 = cos1*cosStep1 - sin1*sinStep1; sin1 = cos3*sinStep1 + sin1*cosStep1; } //if cylindrical/spherical, update theta
      if(f.mode==GraphMode.SPHERICAL) { cos2=cos2i; sin2=sin2i; } //if spherical, reset phi
    }
    
    //next, we actually draw everything out
    switch(mode) { //switch between the 3 graphing modes
      case POINT: { //points mode
        for(int m=0;m<=steps1;m++) for(int n=0;n<=steps2;n++) { //loop through both dimensions
          pgraph.point((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
        }
      } break;
      case WIREFRAME: { //wireframe mode
        for(int m=0;m<=steps1;m++) { pgraph.beginShape(); for(int n=0;n<=steps2;n++) { //loop through both dimensions, being sure to connect the dots
          pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
        } pgraph.endShape(); }
        for(int n=0;n<=steps2;n++) { pgraph.beginShape(); for(int m=0;m<=steps1;m++) { //do the same thing in the other direction
          pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
        } pgraph.endShape(); }
      } break;
      default: { //surface mode
        for(int m=0;m<steps1;m++) for(int n=0;n<steps2;n++) { //loop through both dimensions (ignoring the last points, since they aren't followed by anything)
          boolean canDo = true;
          for(int k=0;k<3;k++) { if(points[m][n][k]!=points[m][n][k] || points[m][n+1][k]!=points[m][n+1][k] || points[m+1][n][k]!=points[m+1][n][k] || points[m+1][n+1][k]!=points[m+1][n+1][k]) { canDo=false; break; } }
          if(canDo) {
            pgraph.beginShape();
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m+1][n][0]), (float)(origZ-50*pixPerUnit*points[m+1][n][2]), (float)(origY-50*pixPerUnit*points[m+1][n][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m+1][n+1][0]), (float)(origZ-50*pixPerUnit*points[m+1][n+1][2]), (float)(origY-50*pixPerUnit*points[m+1][n+1][1]));
            pgraph.endShape(); pgraph.beginShape();
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m+1][n+1][0]), (float)(origZ-50*pixPerUnit*points[m+1][n+1][2]), (float)(origY-50*pixPerUnit*points[m+1][n+1][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n+1][0]), (float)(origZ-50*pixPerUnit*points[m][n+1][2]), (float)(origY-50*pixPerUnit*points[m][n+1][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
            pgraph.endShape();
          }
        }
      } break;
    }
    
    /*
    double stepSize = (f.mode==GraphMode.RECT2D) ? 1d/pixPerUnit : (f.end-f.start)/f.steps; //how much the input increases by each iteration
    int steps = (f.mode==GraphMode.RECT2D) ? round(wid) : f.steps;
    
    double cos=0, sin=0, cosStep=0, sinStep=0; //used only for making polar graphs easier
    if(f.mode==GraphMode.POLAR) { cos=Math.cos(f.start); sin=Math.sin(f.start); cosStep=Math.cos(stepSize); sinStep=Math.sin(stepSize); }
    
    //For the sake of making calculations work, the grapher will pretend that the point right before the loop started and right after it ends are unplottable points.
    //This will force a beginShape to be called in the loop at the first plottable point, and force endshape to be called after the last plottable point. If nothing was plottable & on screen, nothing happens.
    for(int n=0;n<=steps;n++) { //loop through all x values
      
      double inp = (f.mode==GraphMode.RECT2D) ? (xt+n-origX)*stepSize : n*stepSize+f.start; //compute current input
      
      feed.put(f.mode.inputs()[0],new MathObj(new Complex(inp))); //tell the solver to plug in this value for x/θ/t
      
      MathObj out = f.function.solve(feed); //compute the output
      if(out.type == f.mode.outType()) {
        if(out.isNum()) { works = out.number.isReal() && Double.isFinite(out.number.re); }
        else { works = out.vector.size()==2 && out.vector.isReal() && Double.isFinite(out.vector.get(0).re) && Double.isFinite(out.vector.get(1).re); }
      }
      else { works = false; }
      //TODO give slight leeway for numbers with very small imaginary part, adjust algorithm so odd vertical asymptotes don't get connected
      
      if(works) { //if point is plottable:
        switch(f.mode) { //figure out which point we're plotting
          case RECT2D: {
            double y = out.number.re; //find point to plot
            xCurr = xt+n; yCurr = (float)(origY-y*pixPerUnit);
          } break;
          
          case POLAR: {
            double r = out.number.re; //find point to plot
            xCurr = (float)(origX+r*cos*pixPerUnit); yCurr = (float)(origY-r*sin*pixPerUnit);
          } break;
          
          case PARAMETRIC2D: {
            double x = out.vector.get(0).re, y = out.vector.get(1).re;
            xCurr = (float)(origX+x*pixPerUnit); yCurr = (float)(origY-y*pixPerUnit);
          } break;
        }
      }
      else { xCurr = yCurr = Float.NaN; } //otherwise, set the point to NaN, NaN
      
      //next, figure out whether the current AND previous point are in bounds (if they're not plottable, they're not in bounds either, by way of vacuous truth)
      curr = xCurr>=0 && xCurr<=wid+xt && yCurr>=0 && yCurr<=hig+yt; //calculate whether or not this point is on screen
       
      if(curr && !prev)           { pgraph.beginShape();        } //if the previous point wasn't plotted (either unplottable or off screen), begin shape
      if(curr && worked && !prev) { pgraph.vertex(xPrev,yPrev); } //if the previous point was off screen, and the current point is on screen, plot the previous point to connect the dots
      if(curr || works && prev)   { pgraph.vertex(xCurr,yCurr); } //if the current point is on screen, or the previous point was on screen (to connect the dots), plot this point
      if(!curr && prev)           { pgraph.endShape();          } //if the previous point was on screen, but the current point is unplottable or off screen, end shape
      
      if(f.mode==GraphMode.POLAR) { double cos2 = cos; cos = cos*cosStep - sin*sinStep; sin = cos2*sinStep + sin*cosStep; } //if in polar mode, use this angle addition formula each iteration to avoid using too much trig
      
      xPrev = xCurr; yPrev = yCurr; //set prev to curr
      prev = curr;                  //set prev to curr
      worked = works;               //set worked to works
    }
    if(prev) { pgraph.endShape(); } //if the previous point was in bounds, end connecting the dots*/
  }
  
  ////////////////// UPDATES /////////////////
  
  public void updateFromTouches(Mmio mmio, float xt, float yt) { //uses MMIO's cursors & mouse wheel to update shift, scale, and rotation
    if(!visible) { return; } //if not visible, don't interact
    
    ArrayList<Cursor> interact = new ArrayList<Cursor>(); //arraylist of all cursors which are interacting with the graph
    for(Cursor curs : mmio.cursors) { //loop through all cursors
      if(curs.anyPressed() && (curs.getSelect()==null || curs.getSelect() instanceof Mmio)) { interact.add(curs); } //add all cursors which are pressing and are selecting nothing (or selecting the MMIO)
    }
    
    if(interact.size()==1) { //if exactly one cursor is touching it, we only rotate:
      Cursor curs = interact.get(0); //grab the one cursor
      PVector amt=new PVector(curs.x-curs.dx,curs.y-curs.dy,0); //grab the amount by which the cursor moved
      referenceT.rotate(amt.mag()/100,amt.y,-amt.x,0);   //rotate the transpose by however much the mouse moved
      reference=referenceT.get(); reference.transpose(); //set reference equal to its transpose's transpose
    }
    else if(interact.size()==2) { //(Android only) if exactly 2 cursors are touching it, we zoom and translate:
      Cursor c0 = interact.get(0), c1 = interact.get(1); //load both cursors
      
      //1: scale
      float ratio = sqrt((sq(c0.x-c1.x)+sq(c0.y-c1.y))/(sq(c0.dx-c1.dx)+sq(c0.dy-c1.dy))); //compute the ratio between the distance between both cursors before & after
      pixPerUnit *= ratio; //the size of a unit (in pixels) expands by this ratio
      
      /*
      //2: translate. This has to be done in steps
      origX-=0.5*(c0.dx+c1.dx); origY-=0.5*(c0.dy+c1.dy); //1 un-translate by previous midpoint
      origX*=ratio; origY*=ratio;                         //2 scale up by the scale factor
      origX+=0.5*(c0.x+c1.x); origY+=0.5*(c0.y+c1.y);     //3 re-translate by current midpoint
      */
    }
    
    if(mmio.wheelEventX!=0 || mmio.wheelEventY!=0) { //(PC only) if the mousewheel has moved, we translate AND scale (well, for now we just scale):
      Cursor curs = mmio.cursors.get(0); //load the cursor (it's PC, so there's exactly 1 cursor: the mouse)
      
      //1: scale
      float scale = pow(1.1f,-mmio.wheelEventY-2*mmio.wheelEventX); //compute the amount by which we scale up/down
      pixPerUnit *= scale; //the size of a unit (in pixels) expands by this scale factor
      
      /*
      //2: translate. This has to be done in steps
      origX-=curs.x; origY-=curs.y; //1 un-translate by mouse position
      origX*=scale; origY*=scale;   //2 scale up by the scale factor
      origX+=curs.x; origY+=curs.y; //3 re-translate by mouse position
      */
    }
  }
}
class CalcHistory { //class for storing the history of questions & answers
  Textbox[] questions; //carousel array of all the questions that have been asked (newest to oldest)
  Textbox[] answers; //carousel array of all the answers that have been answered
  MathObj[] answerExact; //carousel array of all the answers, but stored as explicit numbers/math objects
  int carousel = 0; //the carousel index: the index at which question 0 (the newest question) is stored
  int entries;      //the number of entries (usually fixed, but can sometimes be changed)
  float boxHeight, textSize; //the height of the boxes, the size of the text
  
  Panel holder; //the panel that holds the history display
  
  CalcHistory(final Panel parent, int ent, int ind, float x, float y, float w, float h, float tboxH, float tSize) { //constructs history, given parent panel, # of entries, carousel index, x,y,width,height, textbox height, and text size
    entries = ent; carousel = ind;    //set the # of entries & the carousel index
    if(entries==-1 || carousel==-1) { //if # of entries or base index isn't specified:
      loadBaseSettingsFromDisk(this, sketchPath("")+dirChar+"saves"+dirChar+"History"); //load it from the file
    }
    
    questions = new Textbox[entries]; answers = new Textbox[entries]; answerExact = new MathObj[entries]; //initialize all 3 arrays
    boxHeight = tboxH; textSize = tSize; //set the height for each textbox, the size of the text
    
    holder = new Panel(x,y,w,h,w,2*tboxH*entries); //create holder panel
    holder.setSurfaceFill(0).setStroke(0xff00FFFF).setParent(parent); //set fill, stroke, and parent
    holder.setScrollY(holder.h-holder.surfaceH); holder.setDragMode(DragMode.NONE,DragMode.ANDROID); //scroll all the way to the bottom, and make it draggable in the vertical direction
    
    for(int n=0;n<entries;n++) { //loop through all entries
      final Textbox question = buildTextbox( 2*(entries-n-1)   *tboxH,  true); //create each question textbox
      final Textbox   answer = buildTextbox((2*(entries-n-1)+1)*tboxH, false); //create each   answer textbox
      
      question.hMode = answer.hMode = Textbox.HighlightMode.NONE; //prevent the question & answer textboxes from having highlight functionality
      
      setQuestion(n,question); //set the question
      setAnswer(n,answer);     //the answer
      answerExact[n] = new MathObj(); //and the exact answer (this one doesn't care about order)
    }
  }
  
  
  //////////////// GETTERS / SETTERS //////////////////////////////////
  
  public Textbox getQuestion(int ind) { //grabs specific question (index 0 means the newest one, indices are cyclical; they loop around)
    return questions[Math.floorMod(ind+carousel, entries)]; //add carousel index, modulo with the # of entries
  }
  public Textbox getAnswer(int ind) { //grabs specific answer (index 0 means the newest one)
    return answers[Math.floorMod(ind+carousel, entries)]; //do the same thing
  }
  public MathObj getAnswerExact(int ind) { //grabs specific explicitly stored answer
    return answerExact[Math.floorMod(ind+carousel, entries)]; //do the same thing
  }
  
  public MathObj getNewestAnswer() { //returns the newest (most recent) answer
    return answerExact[carousel]; //go to the carousel index, return the answer there
  }
  
  private void setQuestion(int ind, Textbox box) { //sets the question box
    questions[Math.floorMod(ind+carousel, entries)] = box;
  }
  
  private void setAnswer(int ind, Textbox box) { //sets the answer box
    answers[Math.floorMod(ind+carousel, entries)] = box;
  }
  
  public void setAnswerExact(int ind, MathObj ans) { //sets explicitly stored answer at specific index
    answerExact[Math.floorMod(ind+carousel, entries)] = ans; //go to adjusted index, set element
  }
  
  public void setVisible(boolean vis) { holder.setActive(vis); } //set whether the history is visible
  
  //////////////////// BASIC MANIPULATION //////////////////////////////
  
  public void addEntry(String quest, String ans, MathObj ans2, boolean save) { //updates the history by adding a new question/answer to the list (thus removing the oldest question/answer)
    int newCarousel = Math.floorMod(carousel-1, entries); //compute what the new carousel index will be
    
    //first, we move all the questions/answers up 2 slots, except the oldest which get put right at the bottom
    float questY = getQuestion(0).y, ansY = getAnswer(0).y; //store the positions of the newest question & answer
    for(int ind = 0; ind != entries-1; ind++) {  //loop through all questions/answers EXCEPT the oldest one
      getQuestion(ind).y = getQuestion(ind+1).y; //move each question to the position of the next highest question
      getAnswer  (ind).y = getAnswer  (ind+1).y; //move each answer   to the position of the next highest answer
    }
    getQuestion(-1).y = questY; //set the position of the oldest question to that of the newest question
    getAnswer  (-1).y =   ansY; //set the position of the oldest   answer to that of the newest   answer
    
    carousel = newCarousel; //now, we set the new carousel index
    
    Textbox ansField = getAnswer(0); //grab the answer field
    ansField.setTextX(Mmio.xBuff);   //correctly align the answer field so it knows what width to be
    getQuestion(0).replace(quest);    //put the question into the now most recent question
    setAnswerContents(ansField, ans); //put the answer into the now most recent answer
    setAnswerExact(0, ans2);          //set the most recent exact answer
    
    if(save) {
      saveUpdateToDisk("saves"+dirChar+"History"); //finally, save this update to the disk
    }
    
    //below is some stuff that's probably more efficient at the cost of being a little less readable
    /*float questY = questions[carousel].y, ansY = answers[carousel].y; //store the positions of the newest question & answer
    for(int ind = carousel; ind != newCarousel; ind++) { //loop through all questions/answers EXCEPT the oldest ones
      if(ind != entries-1) { //assuming we're not about to loop around:
        questions[ind].y = questions[ind+1].y; //move each question to the position of the next oldest question
        answers  [ind].y = answers  [ind+1].y; //move each answer   to the position of the next oldest answer
      }
      else { //otherwise:
        questions[ind].y = questions[0].y; //do the same thing, but now the next oldest is #0
        answers  [ind].y = answers  [0].y;
        ind = -1; //set the index to -1 so it'll loop back around to index 0
      }
    }
    questions[newCarousel].y = questY; //last, set the position of the oldest question
    answers  [newCarousel].y = ansY;   //and the oldest answer, to that of the newest
    
    questions[newCarousel].readInput(new InputCode(new int[] {'C','I',0}, new String[] {quest})); //put the question into the most recent question
    answers  [newCarousel].readInput(new InputCode(new int[] {'C','I',0}, new String[] {  ans})); //put the answer into the most recent answer
    answerExact[newCarousel] = ans2; //set the most recent exact answer
    
    carousel = newCarousel; //lastly, we set the new carousel index*/
  }
  
  public void clearEverything(boolean save) {
    for(int n=0;n<entries;n++) {
      questions[n].clear(false,false,false); //clear every question
      answers  [n].clear(false,false,false); //clear every answer
      answerExact[n] = new MathObj();        //clear every explicit answer
    }
    
    if(save) { saveToDisk("saves"+dirChar+"History"); } //save the fact that history was cleared
  }
  
  public void changeHistoryDepth(int size, boolean save) {
    if(size==entries) { return; } //if this doesn't change the size, do nothing
    
    holder.surfaceH = 2*boxHeight*size; //change the surface height
    
    Textbox[] questions2 = new Textbox[size], //create new question array of the correct size
                answers2 = new Textbox[size]; //and new answer array
    MathObj[] answerExact2 = new MathObj[size]; //and new exact answer array
    
    for(int n=0;n<size && n<entries;n++) { //loop through all entries that can be copied and exist
      questions2[n] = getQuestion(n); //shallow copy over each question
      answers2  [n] = getAnswer  (n); //and each answer
      answerExact2[n] = getAnswerExact(n); //and each exact answer
      
      questions2[n].y = (2*size-2*n-2)*boxHeight; //change the y position of each question
      answers2  [n].y = (2*size-2*n-1)*boxHeight; //change the y position of each answer
    }
    for(int n=entries; n<size; n++) { //loop through all the entries that weren't created (assuming size>entries, otherwise the loop isn't even entered)
      questions2[n] = buildTextbox( 2*(size-n-1)   *boxHeight,  true); //set this question
      answers2  [n] = buildTextbox((2*(size-n-1)+1)*boxHeight, false); //set this answer
      answerExact2[n] = new MathObj();                                 //set this exact answer
    }
    for(int n=size; n<entries; n++) { //loop through all the entries that we have to delete (assuming entries>size, otherwise the loop isn't even entered)
      getQuestion(n).setParent(null); //make each question estrange
      getAnswer  (n).setParent(null); //make each answer estrange
      
      if(save) { //if we plan on saving these changes, we have to delete all unneeded files
        new File(sketchPath()+dirChar+"saves"+dirChar+"History"+dirChar+"question "+n+".txt").delete(); //delete each unneeded question
        new File(sketchPath()+dirChar+"saves"+dirChar+"History"+dirChar+"answer "+n+".txt").delete(); //delete each unneeded answer
        new File(sketchPath()+dirChar+"saves"+dirChar+"History"+dirChar+"answer exact "+n+".txt").delete(); //delete each unneeded exact answer
      }
    }
    
    questions = questions2; //replace the question array
    answers   = answers2;   //replace the answer array
    answerExact = answerExact2; //replace the exact answer array
    carousel = 0; entries = size; //change the # of entries to the specified size, and the carousel index to 0
    
    if(save) { saveToDisk("saves"+dirChar+"History"); } //if we want to save this, we have to save this
  }
  
  //////////////////////// SAVING / LOADING ////////////////////////////
  
  public void saveToDisk(String path) { //saves the entire history to the disk
    for(int n=0;n<entries;n++) {
      saveQuestionToDisk   (n,  questions[n], path);
      saveAnswerToDisk     (n,    answers[n], path);
      saveAnswerExactToDisk(n,answerExact[n], path);
    }
    saveBaseSettingsToDisk(this, path);
  }
  
  public void loadFromDisk(String path) { //loads the entire history from disk
    for(int n=0;n<entries;n++) {
      loadQuestionFromDisk(n, questions[n], path);
      loadAnswerFromDisk  (n,   answers[n], path);
      answerExact[n] = loadAnswerExactFromDisk(n, path);
      //println("Entry "+n+" loaded"); //DEBUG
    }
  }
  
  public void saveUpdateToDisk(String path) { //given that the history was just updated by 1 entry, it saves the update to disk by replacing the oldest entry w/ the newest one & incrementing the carousel index
    saveQuestionToDisk   (carousel,   questions[carousel], path);
    saveAnswerToDisk     (carousel,     answers[carousel], path);
    saveAnswerExactToDisk(carousel, answerExact[carousel], path);
    
    saveBaseSettingsToDisk(this, path);
  }
  
  //////////////////////////// UTILITY FUNCTIONS ///////////////////////
  
  public Textbox buildTextbox(float y, boolean question) { //builds & returns the question/answer textbox that would go at this height
    final Textbox textbox = new Textbox(0,y,holder.w,boxHeight); //create each question textbox
    textbox.setTextColor(0xff00FFFF).setTextSizeAndAdjust(textSize).setSurfaceFill(0xff000000).setStroke(0xff00FFFF); //set the drawing parameters,
    textbox.setScrollable(true,false).setDragMode(DragMode.ANDROID,DragMode.NONE); //the scrolling mode
    textbox.setParent(holder); //the parent panel
    
    final Mmio io = textbox.mmio;
    
    if(question) { //here's the action that gets performed if it's a question:
      textbox.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
        String text = textbox.getText(); //grab the text from the textbox
        if(!text.equals("")) { //if it's not empty:
          io.typer.eraseSelection(); //erase selection (if applicable)
          io.typer.insert(text);     //insert text
        }
      } } });
    }
    else { //here's the action if it's an answer (almost exactly the same)
      textbox.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
        String text = textbox.getText(); //grab the text from the textbox
        if(!text.equals("")) { //if it's not empty:
          io.typer.eraseSelection();     //erase selection (if applicable)
          io.typer.insert("("+text+")"); //insert text (making sure to wrap it in quotes)
        }
      } } });
    }
    
    return textbox; //return result
  }
}

public void setAnswerContents(Textbox answer, String contents) {
  answer.setTextX(Mmio.xBuff); //correctly align the answer field so it knows what width to be
  answer.replace(contents); //replace current contents w/ the new contents
  
  if(answer.w == answer.surfaceW) { //if the answer field isn't too wide to be displayed:
    float shift = answer.getX(answer.size()) - answer.tx; //compute the position of the far right of the text
    answer.setTextX(answer.w-shift-answer.tx);            //shift over its text so that it's right aligned
  }
}
public void interfaceInit(final Mmio io) {
  //Here, we have a bunch of spaghetti code used for initializing the entire user interface. Enjoy/I'm sorry.
  
  io.setSurfaceFill(0x00FFFFFF).setSurfaceDims(width,height).setPos(0,0).setDims(width,height); //initialize the entire surface
  
  //here is where we would load all the memory from storage, if that was implemented
  
  //put special sizing variables here, so they can be changed at a whim
  //final float topHig = 0.055555556*height;
  //final float /*lrBuff = 0.011111111*width, topBuff=0.011111111*height,*/ historyHig = /*0.46666667*height/*0.38888889*height*/0.51666667*height - 0.07462686*width+1/*, inpHig = 0.055555556*height*/;
  final float inpBuffX=0.022222222f*width, inpBuffY=0.0077777778f*height;
  //final float addButtHig=0.05*height;
  //final float equationHeight=0.055555556*height;
  final float thick1=0.0066666667f*width, thick2=0.0022222222f*width, thick3=0.0044444444f*width;
  //final float bottMenHig = 0.044444444*height;
  
  //put special sizing variables here, so they can be changed at a whim
  //widths & heights:
  final float keyButtHig = 0.07f*height;      //keypad button height
  final float queryHig = 0.055555556f*height; //query box height
  final float questAnsHig;                   //the height of every question & answer
  final float equatHig = 0.055555556f*height; //the height of each equation box
  final float equatButtHig = 0.05f*height; //the height of each of the buttons in the equation tab
  final float tabHig = 0.055555556f*height; //the height of the tabs at the top
  final float graphMenuHig = 0.044444444f*height; //the height of the graphing menu at the bottom
  
  //buffers between objects
  final float keyButtHBuff, keyButtVBuff = 0.007f*height; //the space between each keypad button
  final float textBuffX = 0.022222222f*width, textBuffY = 0.01f*height; //the horizontal and vertical buffers between the text and the edge of the buttons
  final float consoleHBuff = 0.011111111f*width; //horizontal buffer between the console and the border
  final float queryToKeypad = 0.011111111f*height; //the vertical buffer between the query box and the keypad
  final float consoleToTabs = 0.011111111f*height; //the vertical buffer between the tabs at the top and the console
  
  Button palette = new Button(0,0,0,0).setFills(0xff001818,0xff003030,0xff006060).setStrokes(0xff008080); //a placeholder button we can steal the palette from
  palette.setStrokeWeight(thick3);
  
  //3 buttons at the top to swap between calculator modes
  Button  calcMode = (Button)new Button(        0,0,width/3,tabHig).setFills(0xff000080,0xff0000FF).setStrokes(0xff8080C0,0xff8080FF).setStrokeWeight(thick1).setParent(io).setText("Calculator",0xff8080FF),
         equatMode = (Button)new Button(  width/3,0,width/3,tabHig).setFills(0xff000080,0xff0000FF).setStrokes(0xff8080C0,0xff8080FF).setStrokeWeight(thick1).setParent(io).setText("Equations",0xff8080FF),
         graphMode = (Button)new Button(2*width/3,0,width/3,tabHig).setFills(0xff000080,0xff0000FF).setStrokes(0xff8080C0,0xff8080FF).setStrokeWeight(thick1).setParent(io).setText("  Graph  ",0xff8080FF);
  
  //This right here is a vertically-scrollable panel that shows the question/answer history.
  float historyHig = height-tabHig-consoleToTabs-queryHig-queryToKeypad-5*keyButtHig-5.5f*keyButtVBuff; //first, compute how tall the history display is
  initializeHistoryDisplay(consoleHBuff, tabHig, consoleToTabs, historyHig, inpBuffX, inpBuffY, thick1, thick2, queryHig); //initialize the display window which shows our history of questions, answers, and mistakes
  
  // Now, we implement the screen that lets us enter all the graphable equations
  
  //initializeEquationList(palette, lrBuff,topHig+topBuff,width-2*lrBuff,historyHig+inpHig, addButtHig, equationHeight, thick2, inpBuffY); //initialize the place where we enter equations to plot
  equatList = new EquatList(io, consoleHBuff,tabHig+consoleToTabs,width-2*consoleHBuff,historyHig+queryHig, palette,equatButtHig,equatHig,thick2,inpBuffY,thick2);
  
  // Now, we implement the keypad that lets us type in all our equations
  
  
  //float buttTop = height-5*keyButtHig-4.5*keyButtVBuff; //compute where the top of the keypad should go
  ////create said keypad
  //keyPad = new Panel(0,buttTop,width,/*height-buttTop*/0.42*height+0.074626866*width, width,/*height-buttTop*/0.42*height+0.074626866*width); keyPad.setSurfaceFill(0).setStroke(false).setParent(io);
  //keyPad.canScrollY = false;
  
  //initializeKeypad(consoleToTabs, palette, thick3); //initialize the keypad we use to type stuff
  
  float buttTop = height-5*keyButtHig-5.5f*keyButtVBuff; //compute where the top of the keypad should go
  
  ctrlPanel = new KeyPanel(0,buttTop,width,5*keyButtHig+5.5f*keyButtVBuff,width,5*keyButtHig+5.5f*keyButtVBuff);
  keyPad = ctrlPanel.panel;
  //keyPad.surfaceFillColor = #FF00FF;
  keyPad.setParent(io);
  
  float keyButtWid = width/6.7f;
  keyButtHBuff = 0.1f*keyButtWid; //temporary
  float rad = 0.25f*keyButtWid;
  
  
  initializeKeypad(palette, keyButtWid, keyButtHig, rad, keyButtHBuff, keyButtVBuff, textBuffX, textBuffY);
  
  
  
  graphMenu = (Panel)new Panel(0,height-graphMenuHig,width,graphMenuHig); graphMenu.setSurfaceFill(false).setStroke(false).setParent(io).setActive(false);
  initializeGraphMenu(palette, graphMenuHig); //initialize the menu at the bottom of our graph that allows us to do stuff (such as trace the graph, find roots, reset position, or swap between 2D/3D mode)
  
  
  
  //now, we tell the 3 buttons at the top what to do
  calcMode.setOnRelease(new Action() { public void act() {
    if(io.typer!=null) { io.typer.buddy.clearHandles(); } //clear any ts handles
    history.setVisible(true);    //make the history box visible
    query.setActive(true);       //make the query box visible
    keyPad.setActive(true);      //make the keypad visible
    ctrlPanel.swapGraphMode(GraphMode.NONE); //set the graphmode to none (no relevant variables)
    equatList.setActive(false);  //make the equation list invisible
    graphMenu.setActive(false);  //make the graph menu invisible
    io.setTyper(query); equatList.equatCache=null; //we now type into the query box, and there is no equation cache
    grapher2D.setVisible(false); //make the 2D graph invisible
    grapher3D.setVisible(false); //make the 3D graph invisible
  } });
  equatMode.setOnRelease(new Action() { public void act() {
    if(io.typer!=null) { io.typer.buddy.clearHandles(); } //clear any ts handles
    history.setVisible(false);    //make the history box invisible
    query.setActive(false);       //make the query box invisible
    keyPad.setActive(true);       //make the keypad visible
    ctrlPanel.swapGraphMode(equatList.graphDim ? GraphMode.RECT3D : GraphMode.RECT2D); //set the graphmode to either 2D or 3D rectangular
    equatList.setActive(true);    //make the equation list visible
    graphMenu.setActive(false);   //make the graph menu invisible
    io.setTyper(null); equatList.equatCache=null; equatList.updateColorSelector(); //we now type into nothing, there is no equation cache, and we have to update the color selector
    grapher2D.setVisible(false);  //make the 2D graph invisible
    grapher3D.setVisible(false);  //make the 3D graph invisible
  } });
  graphMode.setOnRelease(new Action() { public void act() {
    if(io.typer!=null) { io.typer.buddy.clearHandles(); } //clear any ts handles
    history.setVisible(false);    //make the history box invisible
    query.setActive(false);       //make the query box invisible
    keyPad.setActive(false);      //make the keypad invisible
    equatList.setActive(false);   //make the equation list invisible
    graphMenu.setActive(true);    //make the graph menu visible
    io.setTyper(null); equatList.equatCache=null; //we now type into nothing, and there is no equation cache
    grapher2D.setVisible(!equatList.graphDim);    //make the 2D graph visible iff in 2D mode
    grapher3D.setVisible(equatList.graphDim);     //make the 3D graph visible iff in 3D mode
  } });
}

//creates the window for displaying the history
public void initializeHistoryDisplay(final float lrBuff, final float topHig, final float topBuff, final float historyHig, final float inpBuffX, final float inpBuffY, final float thick1, final float thick2, final float inpHig) {
  final float entryHig=0.044444444f*height;    //the height of each question/answer box
  final float historyTextSize = 0.017f*height; //the text size for each entry
  
  history = new CalcHistory(io, -1, -1, lrBuff,topHig+topBuff,width-2*lrBuff,historyHig,entryHig, historyTextSize); //load the history display interface
  history.holder.setPixPerClickV(2*history.holder.pixPerClickV);
  
  query = new Textbox(lrBuff,topHig+topBuff+historyHig,width-2*lrBuff,inpHig).setTextColor(0xff00FFFF).setCaretColor(0xff00FFFF); //now, create the textbox that we actually type into
  query.setSurfaceFill(0).setStroke(0xff00FFFF).setStrokeWeight(thick1).setParent(io); //set its drawing parameters and its parent
  query.setDragMode(pcOrMobile ? DragMode.NONE : DragMode.ANDROID, DragMode.NONE); //set how it's dragged (mobile=only horizontally, pc=none)
  query.setTextPosAndAdjust(inpBuffX,inpBuffY); //set the position of the text within the textbox
  query.setCaretThick(thick2);                  //set the caret thickness
  
  query.setMargin(relativeMarginWidth*width); //give us some more space on the left and right
  
  io.setTyper(query); //set the typer to the query box
}


public void initializeKeypad(final Button palette, float keyButtWid, float keyButtHig, float rad, float keyButtHBuff, float keyButtVBuff, float textBuffX, float textBuffY) { //initializes the keypad
  
  final KeyPad primary_orig = new KeyPad(io,palette,keyButtWid,keyButtHig,rad,keyButtHBuff,keyButtVBuff,textBuffX,textBuffY, //here, we have the main, primary keypad
                          new String[][] {{"◄","►","C","/","*","⌫"},{"(",")","7","8","9","-"},{"√","ln","4","5","6","+"},{"π","e E","1","2","3","↩"},{"▼","2nd","0","0",". i","↩"}}, //this is what each button says
                          new int   [][] {{  3,  3,  6,  4,  4,  3},{  1,  1,  1,  1,  1,  5},{  2,   2,  1,  1,  1,  4},{  1,    1,  1,  1,  1,  0},{  0,    0,  1, -1,    1, -1}}, //these are their functionalities
                          new Object[][] {{LEFT,RIGHT,null,"/","*^",(int)BACKSPACE},{"(",")","7","8","9",'-'},{"√(","ln(","4","5","6","+"},{"π","eE","1","2","3",null},{null,null,"0","0",".i",null}}); //this is what they type/do
  primary_orig.keys[0][2].setFills(0xff180000,0xff300000,0xff600000).setStrokes(0xff800000); primary_orig.keys[0][2].text[0].fill=0xffFF0000; //make the clear key red
  primary_orig.keys[3][5].setFills(0xff001800,0xff003000,0xff006000).setStrokes(0xff008000); primary_orig.keys[3][5].text[0].fill=0xff00FF00; //make the enter key green
  primary_orig.keys[3][5].setOnRelease(new Action() { public void act() { hitEnter(); } });                                    //also make the enter key press enter
  
  Button lPar = primary_orig.keys[1][0]; //Here, we add a little counter to the left parenthesis button, displaying how many left/right brackets we have
  lPar.text = new Text[] {lPar.text[0], new Text("0",0.5f*keyButtWid,0.85f*keyButtHig,lPar.text[0].size*0.4f,lPar.text[0].fill,CENTER,CENTER)}; //add the counter at the bottom
  lPar.text[0].y                    = 0.35f*keyButtHig; //vertically re-align the left parenthesis so that we can see the counter below it
  primary_orig.keys[1][1].text[0].y = 0.35f*keyButtHig; //we also have to vertically re-align the right parenthesis button so that it lines up with the left parenthesis button
  
  primary_orig.keys[4][0].setOnRelease(new Action() { public void act() {
    //openKeyboard();
    
    //if(io.typer==query) {
    //  link("https://www.wolframalpha.com/input?i="+generateURLSuffix(query.getText()));
    //}
  } });
  
  
  final EnumMap<GraphMode, KeyPad> primary = new EnumMap(GraphMode.class); //this right here will store all of the primary keypads, each keyed by which sets of variables we need to show
  
  //Now, we have to create our original keypad, but with different keys for our extra variables:
  primary.put(GraphMode.NONE, primary_orig); //add the primary, original panel
  primary.put(GraphMode.RECT2D      , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π"}, new String[] {"x π"}, new int[] {1}, new Object[] {"xπ"})); //then with the x
  primary.put(GraphMode.POLAR       , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π"}, new String[] {"θ π"}, new int[] {1}, new Object[] {"θπ"})); //the theta
  primary.put(GraphMode.PARAMETRIC2D, primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π"}, new String[] {"t π"}, new int[] {1}, new Object[] {"tπ"})); //the t
  primary.put(GraphMode.RECT3D      , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"x π","y e"}, new int[] {1,1}, new Object[] {"xπ","ye"})); //the x & y
  primary.put(GraphMode.CYLINDRICAL , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"θ π","r e"}, new int[] {1,1}, new Object[] {"θπ","re"})); //the theta & r
  primary.put(GraphMode.SPHERICAL   , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"θ π","φ e"}, new int[] {1,1}, new Object[] {"θπ","φe"})); //the theta & phi
  primary.put(GraphMode.PARAMETRIC3D, primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"t π","u e"}, new int[] {1,1}, new Object[] {"tπ","ue"})); //and the t & u
  
  for(KeyPad pad : primary.values()) if(pad!=primary_orig) { //now, we have to loop through all those keypads and make their variable buttons yellow
    for(int y=0;y<pad.keys.length;y++) for(int x=0;x<pad.keys[y].length;x++) { //loop through all x,y coords
      if(primary_orig.keys[y][x] != pad.keys[y][x]) {                          //if this button is different:
        pad.keys[y][x].setFills(0xff181800,0xff303000,0xff606000).setStrokes(0xff808000);  //make the non-shared buttons yellow
        pad.keys[y][x].text[0].fill = 0xffFFFF00;                                 //make their text yellow, as well
      }
    }
  }
  
  final KeyPad secondary_orig = primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY, //here, we have the secondary key set. It's mostly the same, but with a few things different
                                                      new String[] {"/",   "(",    ")",   "√",  "ln",  "π","e E","2nd"},
                                                      new String[] {"%","Copy","Paste", "sin", "cos","Ans",  ",","1st"}, //Mostly, the buttons on the left get swapped out, as well as the divide button becoming modulo
                                                      new int   [] {  4,     0,      0,     2,     2,    2,    1,    0},
                                                      new Object[] {"%",  null,   null,"sin(","cos(","Ans",   ",",null});
  //make the copy and paste buttons do their jobs
  secondary_orig.keys[1][0].setOnRelease(new Action() { public void act() { if(io.typer!=null) { //TODO remove this once you actually fully implement clipboard accessibility. This will take a lot of time, so no rush...
    String text = io.typer.getText(); //grab the text from the input box
    copyToClipboard(text);            //copy it to the clipboard
  } } });
  secondary_orig.keys[1][1].setOnRelease(new Action() { public void act() { if(io.typer!=null) { //TODO remove this once you actually fully implement clipboard accessibility. This will take a lot of time, so no rush...
    String text = getTextFromClipboard();     //grab the text from the clipboard
    if(text!=null) {
      io.typer.eraseSelection(); //erase highlighted selection (if there is one)
      io.typer.insert(text);     //insert it into the input box
    }
  } } });
  
  final EnumMap<GraphMode, KeyPad> secondary = new EnumMap(GraphMode.class);
  
  //Now, we have to create the same thing, but with extra keys for our extra variables:
  secondary.put(GraphMode.NONE, secondary_orig); //we just created the standard secondary (standard=no graph mode)
  secondary.put(GraphMode.RECT2D      , secondary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"Ans"}, new String[] {"n"}, new int[] {1}, new Object[] {"n"})); //for 2D functions, Ans becomes n
  secondary.put(GraphMode.POLAR       , secondary.get(GraphMode.RECT2D)); //including rectangular, polar, and parametric
  secondary.put(GraphMode.PARAMETRIC2D, secondary.get(GraphMode.RECT2D));
  secondary.put(GraphMode.RECT3D      , secondary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"Ans",","}, new String[] {"n",", E"}, new int[] {1,1}, new Object[] {"n",",E"})); //for 3D functions, Ans becomes n and , becomes ,E
  secondary.put(GraphMode.CYLINDRICAL , secondary.get(GraphMode.RECT3D));
  secondary.put(GraphMode.SPHERICAL   , secondary.get(GraphMode.RECT3D)); //that goes for rectangular, cylindrical, spherical, and parametric
  secondary.put(GraphMode.PARAMETRIC3D, secondary.get(GraphMode.RECT3D));
  
  for(KeyPad pad : secondary.values()) if(pad!=secondary_orig) {
    pad.keys[3][0].setFills(0xff181800,0xff303000,0xff606000).setStrokes(0xff808000); //make the n buttons yellow
    pad.keys[3][0].text[0].fill = 0xffFFFF00;                                //make their text yellow, as well
  }
  
  ctrlPanel.addKeypad(0,0,true,primary);
  ctrlPanel.addKeypad(0,0,false,secondary);
  
  primary_orig.keys[4][1].setOnRelease(new Action() { public void act() { //2nd key
    ctrlPanel.activity.set(0,false); //disable primary
    ctrlPanel.activity.set(1,true);  //enable secondary
    ctrlPanel.deactivate();          //deactivate
    ctrlPanel.activate();            //then reactivate
  } });
  secondary_orig.keys[4][1].setOnRelease(new Action() { public void act() { //1st key
    ctrlPanel.activity.set(1,false); //disable secondary
    ctrlPanel.activity.set(0,true);  //enable primary
    ctrlPanel.deactivate();          //deactivate
    ctrlPanel.activate();            //then reactivate
  } });
  
  ctrlPanel.activate();
  
  ctrlPanel.panel.setDragMode(DragMode.SWIPE,DragMode.NONE); //make the main control panel swipeable
}

//void initializeKeypad(final float topBuff, final Button palette, final float thick3) {
  ////now we do the typing buttons
  ////put special sizing variables here, so they can be changed at a whim
  //float buttWid=width/6.7;
  //float buttBuff=0.1*buttWid, rad=buttWid/4;
  ////float buttHig = (height-inputField.y-inputField.h-2*topBuff-5*buttBuff)/5;
  //float buttHig = 0.07*height;
  ////float buttHig = (height-inputField.y-inputField.h-2*topBuff)/6-buttBuff;
  //final float buttBuffX=0.022222222*width, buttBuffY=0.01*height;
  
  //keyPad.setDragMode(DragMode.SWIPE,DragMode.NONE);
  
  //final String[][] texts = {{"◄","►","C","/","*","⌫"},{"(",")","7","8","9","-"},{"√","ln","4","5","6","+"},{"π","e E","1","2","3","↩"},{"▼","2nd","0",". i"}};
  
  //final Button extraUpButton = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*4,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("▲",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //Button recordDownButton = null;
  
  //for(int y=0;y<5;y++) { for(int x=0;x<texts[y].length;x++) {
  //  float wid = (x==2&&y==4) ? 2*buttWid+buttBuff : buttWid,
  //        shift = (x==3&&y==4) ? buttWid+buttBuff : 0,
  //        hig = (x==5&&y==3) ? 2*buttHig+buttBuff : buttHig;
  //  final Button butt = new Button(buttBuff+(buttWid+buttBuff)*x+shift,(buttHig+buttBuff)*y,wid,hig,rad).setPalette(palette);
  //  butt.setDisp(0.5*buttBuff,0.5*buttBuff,0.5*buttBuff,0.5*buttBuff);
  //  butt.setParent(keyPad).setText(texts[y][x],#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3);
  //  if(butt.text[0].text.equals("C")) { butt.setFills(#180000,#300000,#600000).setStrokes(#800000); butt.text[0].fill=#FF0000; } //these are the only two buttons with a different color (well, not really)
  //  else if(butt.text[0].text.equals("↩")) { butt.setFills(#001800,#003000,#006000).setStrokes(#008000); butt.text[0].fill=#00FF00; }
    
  //  if(butt.text[0].text.equals("(")) {
  //    butt.text = new Text[] {butt.text[0], new Text("0",0.5*wid,0.85*hig,butt.text[0].size*0.4,butt.text[0].fill,CENTER,CENTER)};
  //    butt.text[0].y = 0.35*hig;
  //  }
  //  else if(butt.text[0].text.equals(")")) { butt.text[0].y = 0.35*hig; }
    
  //  if(y==0) {
  //    if(x==0) {
  //      //butt.setOnClick(typeAction(new InputCode(InputCode.LEFT)));
  //      Action lefter = new Action() { public void act() { if(io.typer!=null) {
  //        if(io.ctrlHeld) { io.typer.ctrlLeft();       }
  //        else            { io.typer.moveCursorBy(-1); }
  //      } } };
  //      butt.setOnClick(lefter);
  //      butt.setOnHeld (lefter);
  //    }
  //    else if(x==1) {
  //      //butt.setOnClick(typeAction(new InputCode(InputCode.RIGHT)));
  //      Action righter = new Action() { public void act() { if(io.typer!=null) {
  //        if(io.ctrlHeld) { io.typer.ctrlRight();     }
  //        else            { io.typer.moveCursorBy(1); }
  //      } } };
  //      butt.setOnClick(righter);
  //      butt.setOnHeld (righter);
  //    }
  //    else if(x==2) {
  //      butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //        io.typer.clear2(); //clear
  //        if(butt.pressCount%10==9) { //if you press it 10 times in a row:
  //          if(io.typer==query) { history.clearEverything(true); } //calculator tab: clear history
  //          else if(equatList.equatCache!=null && equatList.equatCache.typer==io.typer) { equatList.clearEquations(); } //equation tab: clear equations
  //        }
  //      } } });
  //    }
  //    else if(x==5) {
  //      Action backspace = new Action() { public void act() { if(io.typer!=null) {
  //        if(io.ctrlHeld) { io.typer.ctrlBackspace(); }
  //        else            { io.typer.backspace(true,true,true); }
  //      } } };
  //      butt.setOnClick(backspace);
  //      butt.setOnHeld(backspace);
  //    }
      
  //    else if(x==3) { butt.setOnRelease(typeAnsPrefix('/')); }
  //    else if(x==4) { butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //      if(io.typer==query && io.typer.size()==0) { io.typer.insert("Ans*"); }
  //      else if((butt.pressCount&1)==1) { io.typer.overtype('^',io.typer.cursor-1); io.typer.adjust(); }
  //      else { io.typer.type('*'); }
  //    } } }); }
  //  }
  //  else if(y==1 && x==5) { butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //    if(io.typer==query && io.typer.size()==1 && io.typer.getText().equals("-")) { io.typer.insert("Ans",0); io.typer.moveCursorTo(4); }
  //    else { io.typer.type('-'); }
  //  } } }); }
  //  else if(y==2 && x<2) { final String str=texts[2][x]+"("; butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //    io.typer.insert(str);
  //  } } }); }
  //  else if(y==2 && x==5) { butt.setOnRelease(typeAnsPrefix('+')); }
  //  else if(y==3 && x==1) { butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //    if((butt.pressCount&1)==1) { io.typer.overtype('E',io.typer.cursor-1); io.typer.adjust(); }
  //    else                       { io.typer.type('e'); }
  //  } } }); }
    
  //  else if(y==3 && x==5) { butt.setOnRelease(new Action() { public void act() { hitEnter(); } }); }
    
  //  //else if(y==4 && x==0) { /*butt.setOnRelease(new Action() { public void act() { openKeyboard(); } });*/ }
  //  else if(y==4 && x==0) { recordDownButton = butt; butt.setOnRelease(new Action() { public void act() {
  //    history.holder.h -= 0.077777778*height;
  //    history.holder.surfaceY -= 0.077777778*height;
  //    query.y -= 0.077777778*height;
  //    keyPad.y -= 0.077777778*height;
  //    butt.setActive(false); extraUpButton.setActive(true);
  //  } }); }
  //  else if(y==4 && x==1) { butt.setOnRelease(new Action() { public void act() {
  //    for(Box b : keyPad) { if(b instanceof Button) {
  //      String txt = b.text[0].getText();
  //      if     (txt.equals("/") || txt.equals("(") || txt.equals(")") || txt.equals("√") || txt.equals("ln") || txt.equals(keypadMode.piButton()) || txt.equals(keypadMode.eButton()) || txt.equals("2nd")) { b.active = false; }
  //      else if(txt.equals("%") || txt.equals("CTRL+V") || txt.equals("CTRL+A+C") || txt.equals("sin") || txt.equals("cos") || txt.equals(keypadMode.ansButton()) || txt.equals(keypadMode.commaButton()) || txt.equals("1st")) { b.active =  true; }
  //    } }
  //  } }); }
  //  else if(y==4 && x==3) { butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //    if((butt.pressCount&1)==1) { io.typer.overtype('i',io.typer.cursor-1); io.typer.adjust(); }
  //    else                       { io.typer.type('.'); }
  //  } } }); }
  //  else { final char chars = texts[y][x].charAt(0); butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //    io.typer.type(chars);
  //  } } }); }
  //} }
  
  //final Button extraDownButton = recordDownButton;
  //extraUpButton.setOnRelease(new Action() { public void act() {
  //  history.holder.h += 0.077777778*height;
  //  history.holder.surfaceY += 0.077777778*height;
  //  query.y += 0.077777778*height;
  //  keyPad.y += 0.077777778*height;
  //  extraDownButton.setActive(true); extraUpButton.setActive(false);
  //} });
  
  ////here are some extra buttons that only appear when the 2nd button is pressed
  //Button butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*3,0,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("%",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(typeAnsPrefix('%'));
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*1,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("CTRL+V",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) { //TODO remove this once you actually fully implement clipboard accessibility. This will take a lot of time, so no rush...
  //  String text = getTextFromClipboard();
  //  if(text!=null) { io.typer.insert(text); }
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*1,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("CTRL+A+C",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) { //TODO remove this once you actually fully implement clipboard accessibility. This will take a lot of time, so no rush...
  //  String text = io.typer.getText();
  //  copyToClipboard(text);
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*2,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("sin",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.insert("sin(");
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*2,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("cos",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.insert("cos(");
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("Ans",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.insert("Ans");
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText(",",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.type(',');
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*4,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText("1st",#00FFFF,12,9).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() {
  //  for(Box b : keyPad) { if(b instanceof Button) {
  //    String txt = b.text[0].getText();
  //    if     (txt.equals("/") || txt.equals("(") || txt.equals(")") || txt.equals("√") || txt.equals("ln") || txt.equals(keypadMode.piButton()) || txt.equals(keypadMode.eButton()) || txt.equals("2nd")) { b.active =  true; }
  //    else if(txt.equals("%") || txt.equals("CTRL+V") || txt.equals("CTRL+A+C") || txt.equals("sin") || txt.equals("cos") || txt.equals(keypadMode.ansButton()) || txt.equals(keypadMode.commaButton()) || txt.equals("1st")) { b.active = false; }
  //  } }
  //} });
  //final Button buttX = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("x π",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttX.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttX.pressCount&1)==1) { io.typer.overtype('π',io.typer.cursor-1); io.typer.adjust(); }
  //  else                        { io.typer.type('x');                                          }
  //} } });
  //final Button buttTheta = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("θ π",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttTheta.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttTheta.pressCount&1)==1) { io.typer.overtype('π',io.typer.cursor-1); io.typer.adjust(); }
  //  else                            { io.typer.type('θ'); }
  //} } });
  //final Button buttT = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("t π",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttT.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttT.pressCount&1)==1) { io.typer.overtype('π',io.typer.cursor-1); io.typer.adjust(); }
  //  else                        { io.typer.type('t'); }
  //} } });
  //final Button buttY = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("y e",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttY.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttY.pressCount&1)==1) { io.typer.overtype('e',io.typer.cursor-1); io.typer.adjust(); }
  //  else                        { io.typer.type('y'); }
  //} } });
  //final Button buttR = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("r e",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttR.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttR.pressCount&1)==1) { io.typer.overtype('e',io.typer.cursor-1); io.typer.adjust(); }
  //  else                        { io.typer.type('r'); }
  //} } });
  //final Button buttPhi = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("φ e",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttPhi.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttPhi.pressCount&1)==1) { io.typer.overtype('e',io.typer.cursor-1); io.typer.adjust(); }
  //  else                          { io.typer.type('φ'); }
  //} } });
  //final Button buttU = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("u e",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttU.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttU.pressCount&1)==1) { io.typer.overtype('e',io.typer.cursor-1); io.typer.adjust(); }
  //  else                        { io.typer.type('u'); }
  //} } });
  //final Button buttE = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setPalette(palette).setParent(keyPad).setText(", E",#00FFFF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //buttE.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  if((buttE.pressCount&1)==1) { io.typer.overtype('E',io.typer.cursor-1); io.typer.adjust(); }
  //  else                        { io.typer.type(','); }
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*3,buttWid,buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("n",#FFFF00,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(false);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.type('n');
  //} } });
  
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*0,(buttHig+buttBuff)*5,buttWid,buttHig,rad).setFills(#180018,#300030,#600060).setStrokes(#800080).setParent(keyPad).setText("▦",#FF00FF,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*5,buttWid,0.5*buttHig,rad).setFills(#303030,#303030,#303030).setStrokes(#808080).setParent(keyPad).setText("SHIFT",#C0C0C0,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  ////butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) { openKeyboard(); } } });
  
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*1,(buttHig+buttBuff)*5+0.5*buttHig,buttWid,0.5*buttHig,rad).setFills(#180018,#300030,#600060).setStrokes(#800080).setParent(keyPad).setText("CTRL",#FF00FF,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt.setOnRelease(new Action() { public void act() { io.ctrlHeld^=true; } });
  
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*2,(buttHig+buttBuff)*5,buttWid,buttHig,rad).setFills(#303030,#303030,#303030).setStrokes(#808080).setParent(keyPad).setText("↶",#C0C0C0,buttBuffX,buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  //
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*3,(buttHig+buttBuff)*5,buttWid,0.5*buttHig,rad).setFills(#303030,#303030,#303030).setStrokes(#808080).setParent(keyPad).setText("↷",#C0C0C0,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  //
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*3,(buttHig+buttBuff)*5+0.5*buttHig,buttWid,0.5*buttHig,rad).setFills(#303030,#303030,#303030).setStrokes(#808080).setParent(keyPad).setText("ALT",#C0C0C0,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  //
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*4,(buttHig+buttBuff)*5,buttWid,0.5*buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("HOME",#FFFF00,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.moveCursorTo(0);
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*4,(buttHig+buttBuff)*5+0.5*buttHig,buttWid,0.5*buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("END",#FFFF00,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.moveCursorTo(io.typer.size());
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*5,(buttHig+buttBuff)*5,buttWid,0.5*buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("INS",#FFFF00,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  //butt.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
  //  io.typer.insert^=true;
  //} } });
  //butt = (Button)new Button(buttBuff+(buttWid+buttBuff)*5,(buttHig+buttBuff)*5+0.5*buttHig,buttWid,0.5*buttHig,rad).setFills(#181800,#303000,#606000).setStrokes(#808000).setParent(keyPad).setText("DEL",#FFFF00,buttBuffX,0.5*buttBuffY).setStrokeWeight(thick3).setActive(true);
  
  //Action deleter = new Action() { public void act() { if(io.typer!=null) { io.typer.delete(); } } };
  //butt.setOnClick(deleter);
  //butt.setOnHeld(deleter);
//}

public void initializeEquationList(final Button palette, final float x, final float y, final float w, final float h, final float addButtHig, final float equationHeight, final float thick2, final float inpBuffY) {
  equatList = new EquatList(io, x,y,w,h, palette,addButtHig,equationHeight,thick2,inpBuffY,thick2);
  
  //new Button(equatHolder.w-addButtWid,0,addButtWid,addButtHig).setPalette(palette).setParent(equatHolder).setText("Edit",#00FFFF);
}

public void initializeGraphMenu(Button palette, float buttHig) {
  int amt = 6; //number of buttons at the bottom
  float buttWid = width/PApplet.parseFloat(amt); //width of each button
  
  Button mode2D = (Button)new Button(0,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("2D",0xff00FFFF);
  Button mode3D = (Button)new Button(0,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("3D",0xff00FFFF).setActive(false);
  Button trace = (Button)new Button(buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Trace",0xff00FFFF);
  Button root = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Roots",0xff00FFFF);
  Button inter = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Inters.",0xff00FFFF);
  Button extreme = (Button)new Button(4*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Max/Min",0xff00FFFF);
  Button reset = (Button)new Button(5*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Reset",0xff00FFFF);
  
  final Button axes = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Axes",0xff00FFFF).setActive(false),
             labels = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Labels",0xff00FFFF).setActive(false),
            nothing = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("None",0xff00FFFF).setActive(false);
  
  final Button point = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Points",0xff00FFFF).setActive(false),
                wire = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Wireframe",0xff00FFFF).setActive(false),
                surf = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Surface",0xff00FFFF).setActive(false);
  
  mode2D.setOnRelease(new Action() { public void act() { equatList.changeGraphDims(); } }); //make both of these buttons change the dimensions
  mode3D.setOnRelease(new Action() { public void act() { equatList.changeGraphDims(); } });
  
  reset.setOnRelease(new Action() { public void act() {
    if(!equatList.graphDim) { //2D graphing mode
      grapher2D.origX = 0.5f*width; grapher2D.origY = 0.5f*height; grapher2D.pixPerUnit = height/12.0f; //reset 2D grapher
    }
    else { //3D graphing mode
      grapher3D.origX = 0; grapher3D.origY = 0; grapher3D.origZ = 0; grapher3D.pixPerUnit = 1;
      grapher3D.reference.reset(); grapher3D.referenceT.reset();
    }
  } });
  
  axes   .setOnRelease(new Action() { public void act() { equatList.axisMode = 1;    axes.setActive(false);  labels.setActive(true); } });
  labels .setOnRelease(new Action() { public void act() { equatList.axisMode = 2;  labels.setActive(false); nothing.setActive(true); } });
  nothing.setOnRelease(new Action() { public void act() { equatList.axisMode = 0; nothing.setActive(false);    axes.setActive(true); } });
  
  point.setOnRelease(new Action() { public void act() { equatList.connect = ConnectMode.WIREFRAME; point.setActive(false);  wire.setActive(true); } });
  wire .setOnRelease(new Action() { public void act() { equatList.connect = ConnectMode.SURFACE;    wire.setActive(false);  surf.setActive(true); } });
  surf .setOnRelease(new Action() { public void act() { equatList.connect = ConnectMode.POINT;      surf.setActive(false); point.setActive(true); } });
}

public void updateParCount() { //updates the on-screen counter for the number of parentheses
  if(keyPad.active) { //if the keypad is visible:
    //first, find out how many open parentheses there are:
    int pars = 0;        //init to 0
    if(io.typer!=null) { //if typer isn't null:
      for(SimpleText t : io.typer.texts) { //loop through all chars in the typer
        if     (t.text=='(' || t.text=='[') { ++pars; } //if ( or [, increment
        else if(t.text==')' || t.text==']') { --pars; } //if ) or ], decrement
      }
    }
    
    //TODO optimize the below statement so that it doesn't have to search for the left parenthesis button every time
    for(Box b : keyPad) { if(b instanceof Button) { //loop through all buttons
      if(b.text[0].text.equals("(")) { //look for left parenthesis button
        if(io.typer==null) { b.text[1].text =      ""; } //if typer is null, make counter invisible
        else               { b.text[1].text = pars+""; } //otherwise, display number of parentheses
      }
    } }
  }
}


public void findAnswer(CalcHistory history) {
  if(io.typer.getText().length()==0) { return; } //empty text: do nothing. I'm serious, do nothing!
  
  ParseList parse = new ParseList(io.typer.getText()); //create parselist from calculator input
  parse.format(); //format the parselist
  
  Equation equat = new Equation(parse); //format to an equation
  equat.correctAmbiguousSymbols();      //correct ambiguous symbols
  equat.squeezeInTimesSigns();          //squeeze in * signs where applicable
  equat.setUnaryOperators();            //convert + and - to unary operators where appropriate
  
  String valid = equat.validStrings();
  if(!valid.equals("valid"))                              { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else if(!(valid=equat.    validPars()).equals("valid")) { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else if(!(valid=equat.leftMeHanging()).equals("valid")) { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else if(!(valid=equat.  countCommas()).equals("valid")) { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else {
    equat = equat.shuntingYard(); //convert from infix to postfix
    equat.parseNumbers();         //parse the numbers
    equat.arrangeRecursiveFunctions(); //implement recursive functions
    
    HashMap<String, MathObj> mapper = new HashMap<String, MathObj>(); //create map of variable names to their values
    
    int ind;
    for(ind=0; ind<history.entries && !history.getAnswerExact(ind).isNormal(); ind++) { } //find the most recent answer that isn't a message or empty
    
    if(ind==history.entries) { mapper.put("Ans",new MathObj(new Complex(Double.NaN))); } //if N/A, set it to NaN
    else                     { mapper.put("Ans", history.getAnswerExact(ind).clone()); } //otherwise, set it to that answer
    
    
    /*time2 = System.currentTimeMillis(); //DEBUG
    while(time2==System.currentTimeMillis()) { }
    time2 = System.currentTimeMillis();
    for(int n=0;n<1000;n++) {
      equat.solve(mapper);
    }
    println("Time for full solve: "+0.001*(System.currentTimeMillis()-time2)+"s"); //DEBUG*/
    
    
    MathObj answer = equat.solve(mapper);
    
    //if(answer.isNum() && answer.number.equals(69)) {  } //TODO make this play the sound "nice" as a joke
    
    history.addEntry(io.typer.getText()+"", answer+"", answer, true);
    
    io.typer.clear2(); io.typer.fixWidth(); io.typer.caret=0; io.typer.setScrollX(0);
  }
  
  history.holder.chooseTarget(history.holder.w/2,Math.nextDown(history.holder.surfaceH-history.holder.ySpace)); //target to the bottom so we can see the answer (next down is used to avoid roundoff-induced targeting errors)
}

public void hitEnter() {
  if(io.typer!=null) {
    if(io.typer==query) {
      findAnswer(history);
    }
    else if(equatList.equatCache!=null && io.typer==equatList.equatCache.typer) {
      equatList.saveEquation(true);
    }
    else if(io.typer==equatList.colorSelect) {
      equatList.saveEquationColor(true);
    }
  }
}

public static int saturate(int inp) {
  float red = ((inp>>16)&255)-127.5f, green = ((inp>>8)&255)-127.5f, blue = (inp&255)-127.5f, ratio;
  if(abs(red)>=abs(green) && abs(red)>=abs(blue)) { ratio = 127.5f/abs(red); }
  else if(abs(green)>=abs(red) && abs(green)>=abs(blue)) { ratio = 127.5f/abs(green); }
  else { ratio = 127.5f/abs(blue); }
  
  red*=ratio; green*=ratio; blue*=ratio;
  return 0xFF000000 | round(red+127.5f)<<16 | round(green+127.5f)<<8 | round(blue+127.5f);
}

public String generateURLSuffix(String query) { //converts a query into the string at the end of a URL
  StringBuilder result = new StringBuilder();
  for(char c : query.toCharArray()) {
    if(c>='A' && c<='Z' || c>='a' && c<='z' || c>='0' && c<='9' || c=='~' || c=='*' || c=='-' || c=='_' || c=='"' || c=='<' || c=='>' || c=='.') {
      result.append(c);
    }
    else if(c==' ') { result.append('+'); }
    else {
      result.append('%');
      int first = (c>>4)&15, second = c&15;
      if(first<10) { result.append((char)(first+'0')); } else { result.append((char)(first-10+'A')); }
      if(second<10) { result.append((char)(second+'0')); } else { result.append((char)(second-10+'A')); }
    }
  }
  
  return result.toString();
}


public static class KeyPanel { //the entire panel of keys, containing several alternate keypads
  Panel panel; //the UI panel that actually holds this stuff together
  
  //ArrayList<KeyPad> keypads = new ArrayList<KeyPad>(); //the individual keypads we display
  
  ArrayList<EnumMap<GraphMode,KeyPad>> keypads = new ArrayList<EnumMap<GraphMode,KeyPad>>(); //the individual keypads we display (keyed by the current graphmode)
  ArrayList<Boolean> activity = new ArrayList<Boolean>(); //whether each keypad is active
  GraphMode mode = GraphMode.NONE; //the graphing mode (determines which variables need to be shown)
  
  KeyPanel(float x, float y, float w, float h, float w2, float h2) {
    panel = new Panel(x,y,w,h,w2,h2);
  }
  
  public void addKeypad(float x, float y, boolean active, final EnumMap<GraphMode,KeyPad> map) {
    keypads.add(map);
    activity.add(active);
    for(KeyPad pad : map.values()) {
      for(Button[] bArr : pad.keys) for(Button b : bArr) if(b.parent!=panel) {
        b.setParent(panel);
        b.x += x; b.y += y;
        b.setActive(false);
      }
    }
  }
  
  public void activate() { //activates all active keypad maps
    for(int n=0;n<activity.size();n++) if(activity.get(n)) {
      for(Button b : keypads.get(n).get(mode)) {
        b.setActive(true);
      }
    }
  }
  
  public void deactivate() { //deactivates all keypad maps (even the active ones)
    for(int n=0;n<activity.size();n++) {
      for(GraphMode gm : GraphMode.values()) {
        for(Button b : keypads.get(n).get(gm)) {
          b.setActive(false);
        }
      }
    }
  }
  
  public void swapGraphMode(GraphMode m) {
    if(m==mode) { return; }
    deactivate();
    mode = m;
    activate();
  }
}



public static class KeyPad implements Iterable<Button> { //a class for storing individual keypads
  Button[][] keys; //the array of keys themselves
  
  KeyPad(Button[][] keys2) {
    keys = keys2;
  }
  
  KeyPad(Button palette, float wid, float hig, float spaceX, float spaceY, float textBuffX, float textBuffY, String[][] texts, Action[][] acts) { //this is the most basic version of the constructor, where the actions are explicitly given
    if(texts.length==0) { keys = new Button[0][]; }
    else { keys = new Button[texts.length][texts[0].length]; }
    
    for(int y=0;y<texts.length;y++) for(int x=0;x<texts[y].length;x++) {
      keys[y][x] = new Button(0.5f*spaceX+(wid+spaceX)*x,spaceY+(hig+spaceY)*y,wid,hig);
      keys[y][x].setPalette(palette);
      keys[y][x].setText(texts[y][x],0xff00FFFF,textBuffX,textBuffY); //TODO remove constant cyan, make it customizable
      keys[y][x].setOnRelease(acts[y][x]);
    }
  }
  
  KeyPad(Mmio io, Button palette, float wid, float hig, float rad, float spaceX, float spaceY, float textBuffX, float textBuffY, String[][] texts, int[][] codes, Object[][] extra) {
    if(texts.length==0) { keys = new Button[0][]; }
    else { keys = new Button[texts.length][texts[0].length]; }
    
    for(int y=0;y<texts.length;y++) for(int x=0;x<texts[y].length;x++) {
      
      if(codes[y][x]==-1) { //this code right here is responsible for making buttons that are bigger than other buttons. Code -1 means "fuse me with another button"
        if(y==0 || !texts[y-1][x].equals(texts[y][x])) { //if the button above isn't the same:
          if(x!=0 && texts[y][x-1].equals(texts[y][x])) { //but the button to the left is,
            keys[y][x] = keys[y][x-1];  //fuse with that button
            keys[y][x].w += wid+spaceX; //increase the width
            for(Text t : keys[y][x].text) { t.x += 0.5f*(wid+spaceX); } //re-center the text
            continue; //skip this iteration
          }
        }
        else { //otherwise,
          keys[y][x] = keys[y-1][x]; //fuse with the button above
          if(x==0 || !texts[y][x-1].equals(texts[y][x])) { //if the button to the left isn't ALSO the same,
            keys[y][x].h += hig+spaceY; //increase the height
            for(Text t : keys[y][x].text) { t.y += 0.5f*(hig+spaceY); } //re-center the text
          }
          continue; //skip this iteration
        }
      }
      
      keys[y][x] = makeButton(io,palette,x,y,wid,hig,rad,spaceX,spaceY,textBuffX,textBuffY,texts[y][x], codes[y][x], extra[y][x]);
    }
  }
  
  public void setActive(boolean active) { //sets whether this keypad is active
    for(Button[] bArr : keys) for(Button b : bArr) { //loop through all buttons
      b.setActive(active); //set whether they're active
    }
  }
  
  @Override
  public Iterator<Button> iterator() { return new Iterator<Button>() { //iterates through all the buttons
    private int x=-1, y=0;
    public boolean hasNext() {
      return y<keys.length-1 || y==keys.length-1 && x<keys[y].length-1;
    }
    public Button next() {
      if(++x == keys[y].length) { x=0; ++y; }
      return keys[y][x];
    }
  }; }
  
  //TODO make this work for keys of different sizes
  //TODO comment
  public KeyPad modClone(float spaceX, float spaceY, float textBuffX, float textBuffY, String[] orig, String[] diff, int[] codes, Object[] extra) { //copies the exact same thing, but with certain buttons changed
    int ind = 0; //the index of the modified button
    
    Button[][] keys2; //the array of buttons for the modified clone
    if(keys.length==0) { keys2 = new Button[0][]; } //SC empty array, make empty array
    else { keys2 = new Button[keys.length][keys[0].length]; } //otherwise, make rectagular array of specific size
    
    for(int y=0;y<keys.length;y++) for(int x=0;x<keys[y].length;x++) { //loop through all elements
      if(ind!=orig.length && keys[y][x].text[0].text.equals(orig[ind])) { //if this is one of the keys we're assigned to modify:
        keys2[y][x] = makeButton(keys[y][x].mmio, keys[y][x], x,y, keys[y][x].w, keys[y][x].h, keys[y][x].r, spaceX, spaceY, textBuffX, textBuffY, diff[ind], codes[ind], extra[ind]); //create a modded clone of the button
        
        ind++; //increment index
      }
      else { keys2[y][x] = keys[y][x]; } //otherwise, carry over the exact same button
    }
    
    return new KeyPad(keys2); //return the resulting keypad
  }
  
  public Button makeButton(Mmio io, Button palette, int x, int y, float wid, float hig, float rad, float spaceX, float spaceY, float textBuffX, float textBuffY, String text, int code, Object extra) {
    final Button butt = new Button(spaceX+(wid+spaceX)*x,spaceY+(hig+spaceY)*y,wid,hig,rad).setPalette(palette);
    butt.setDisp(0.5f*spaceX,0.5f*spaceY,0.5f*spaceX,0.5f*spaceY);
    butt.mmio = io; //TODO make this less fucked
    butt.setText(text,0xff00FFFF,textBuffX,textBuffY); //TODO remove constant cyan, make it customizable
    
    switch(code) {
      case 0: break; //0: unassigned
      case 1: { //1: type character(s)
        butt.setOnRelease(type(io,butt,((String)extra).toCharArray()));
      } break;
      case 2: { //2: type string
        butt.setOnRelease(type(io,(String)extra));
      } break;
      case 3: { //3: perform special functionality:
        Action action = act(io,(Integer)extra);
        butt.setOnClick(action);
        butt.setOnHeld (action);
      } break;
      case 4: { //4: type character(s) with possible Ans prefix
        butt.setOnRelease(typeAnsPrefix(io,butt,((String)extra).toCharArray()));
      } break;
      case 5: { //5: type character with Ans prefix on second tap
        butt.setOnRelease(typeDoubleAnsPrefix(io,butt,(Character)extra));
      } break;
      case 6: { //6: clear
        butt.setOnRelease(clear(io,butt));
      }
    }
    
    return butt;
  }
  
  //String: type it, Integer: do corresponding action (LEFT, RIGHT, BACKSPACE), char array: n-uple tapping, 
  
  public static Action type(final Mmio io, final Button butt, final char... typers) { //this generates an action that types one from a set of characters
    if(typers.length==1) { //one character: just type one character
      return new Action() { public void act() { if(io.typer!=null) {
        io.typer.eraseSelection(); //erase the highlighted selection (if any)
        io.typer.type(typers[0]);  //type the character
      } } };
    }
    if(typers.length==2) { //two characters: alternate between typing those two characters
      return new Action() { public void act() { if(io.typer!=null) {
        io.typer.eraseSelection();
        if((butt.pressCount&1)==0) { io.typer.type(typers[0]);                                         }
        else                       { io.typer.overtype(typers[1],io.typer.caret-1); io.typer.adjust(); }
      } } };
    }
    return new Action() { public void act() { if(io.typer!=null) { //otherwise, we type whichever character corresponds to the number of times we've pressed the button
      io.typer.eraseSelection();
      if(butt.pressCount % typers.length==0) { io.typer.type(typers[0]);                                                                     }
      else                                   { io.typer.overtype(typers[butt.pressCount%typers.length],io.typer.caret-1); io.typer.adjust(); }
    } } };
    
    //the reason 3 cases are dealt separately instead of just having them all default to the third case is for efficiency
    //so that each function call will operate as efficiently as it can (seeing as how it's rare for the # of taps needed to exceed 2)
  }
  
  public static Action type(final Mmio io, final String typer) { //this just types a string right in front of the caret
    return new Action() { public void act() { if(io.typer!=null) {
      io.typer.eraseSelection(); //erase highlighted selection (if any)
      io.typer.insert(typer);    //insert the string
    } } };
  }
  
  public static Action act(final Mmio io, final int action) { //this performs a specified action
    switch(action) {
      case LEFT: return new Action() { public void act() { if(io.typer!=null) { //left
        io.typer.adjustHighlightingForArrows(io.shiftHeld); //perform proper adjustments
        if(io.ctrlHeld) { io.typer.ctrlLeft();      } //either ctrl+left
        else            { io.typer.moveCaretBy(-1); } //or left
        
        if(!io.shiftHeld) { io.typer.buddy.clearHandles(); } //unless shift is held down, remove the ts handles
      } } };
      case RIGHT: return new Action() { public void act() { if(io.typer!=null) { //right
        io.typer.adjustHighlightingForArrows(io.shiftHeld); //perform proper adjustments
        if(io.ctrlHeld) { io.typer.ctrlRight();    } //either ctrl+right
        else            { io.typer.moveCaretBy(1); } //or right
        
        if(!io.shiftHeld) { io.typer.buddy.clearHandles(); } //unless shift is held down, remove the ts handles
      } } };
      case BACKSPACE: return new Action() { public void act() { if(io.typer!=null) { //backspace
        boolean wasHighlighting = io.typer.highlighting && io.typer.caret != io.typer.anchorCaret; //first, record if we're currently highlighting
        
        io.typer.eraseSelection(); //if highlighting, erase the selection
        if(!wasHighlighting) { //if not highlighting
          if(io.ctrlHeld) { io.typer.ctrlBackspace();           } //either ctrl+backspace
          else            { io.typer.backspace(true,true,true); } //or backspace
        }
      } } };
      //case DELETE: return new Action() { public void act() { if(io.typer!=null) { //delete
      //  boolean wasHighlighting = io.typer.highlighting && io.typer.caret != io.typer.anchorCaret; //first, record if we're currently highlighting
      //
      //  io.typer.eraseSelection(); //if highlighting, erase the selection
      //  if(!wasHighlighting) { //if not highlighting
      //    if(io.ctrlHeld) { io.typer.ctrlDelete();           } //either ctrl+delete
      //    else            { io.typer.delete(true,true,true); } //or delete
      //  }
      //} } };
    }
    return null; //other
  }
  
  public static Action typeAnsPrefix(final Mmio io, final Button butt, final char... typers) { //types character, but possibly w/ "Ans" before it if @ the beginning
    if(typers.length==1) { //one character: just type one character
      return new Action() { public void act() { if(io.typer!=null) {
        io.typer.eraseSelection(); //if highlighting, erase the selection
        if(io.typer==query && io.typer.size()==0) { io.typer.insert("Ans"+typers[0]); } //if at the beginning, put Ans before it
        else                                      { io.typer.type(        typers[0]); } //otherwise, just type the character
      } } };
    }
    if(typers.length==2) { //two characters: alternate between typing those two characters
      return new Action() { public void act() { if(io.typer!=null) {
        io.typer.eraseSelection();
        if(io.typer==query && io.typer.size()==0) { io.typer.insert("Ans"+typers[0]);           } //if at the beginning, put Ans before it
        else if((butt.pressCount&1)==0)           { io.typer.type(typers[0]);                   } //otherwise, either type the first character
        else                { io.typer.overtype(typers[1],io.typer.caret-1); io.typer.adjust(); } //or the second
      } } };
    }
    return new Action() { public void act() { if(io.typer!=null) { //otherwise, we type whichever character corresponds to the number of times we've pressed the button
      io.typer.eraseSelection();
      if(io.typer==query && io.typer.size()==0) { io.typer.insert("Ans"+typers[0]); } //the same principle as before applies here
      if(butt.pressCount % typers.length==0)    { io.typer.type(typers[0]);         }
      else                                      { io.typer.overtype(typers[butt.pressCount%typers.length],io.typer.caret-1); io.typer.adjust(); }
    } } };
  }
  
  public static Action typeDoubleAnsPrefix(final Mmio io, final Button butt, final char typer) { //types character, but possibly w/ "Ans" before it if typed twice @ the beginning
    return new Action() { public void act() { if(io.typer!=null) {
      io.typer.eraseSelection(); //if highlighting, erase the selection
      if(io.typer==query && io.typer.size()==1 && (butt.pressCount&1)==1) { io.typer.insert("Ans",0); io.typer.caret+=3; } //if double-tapped & @ the beginning, put Ans before it
      else { io.typer.type(typer); } //otherwise, just type it
    } } };
  }
  
  public static Action clear(final Mmio io, final Button butt) { //clears the text field
    return new Action() { public void act() { if(io.typer!=null) {
      io.typer.clear2(); //clear
      if(butt.pressCount%10==9) { //if you press it 10 times in a row:
        if(io.typer==query) { history.clearEverything(true); } //calculator tab: clear history
        else if(equatList.equatCache!=null && equatList.equatCache.typer==io.typer) { equatList.clearEquations(); } //equation tab: clear equations
      }
    } } };
  }
}
public static class Mmio extends Panel { //the top level parent of all the IO objects in here, and the class solely responsible for all the IO functionality
  
  /////////////////////////// ATTRIBUTES //////////////////////////////
  
  final PApplet app; //the applet this runs in
  
  Textbox typer = null; //which textbox we're typing into, if any
  
  ArrayList<ArrayList<ArrayList<Buffer>>> buffers = new ArrayList<ArrayList<ArrayList<Buffer>>>(); //2D array of arrays of buffers used to buffer items partially off screen
  //each inner array contains buffer objects whose dimensions are powers of 2. The first and second indices of the outermost 2D array determines which power the width & height is of 2
  int buffWid=0, buffHig=0;                   //the width & height of the 2 dimensional array (yes, it must be a rectangular array, not a jagged array)
  long buffTime = System.currentTimeMillis(); //stores the time of the last attempt at buffer garbage collection
  
  ArrayList<Cursor> cursors = new ArrayList<Cursor>(); //all the cursors/touches/mice/pointers on screen
  
  //// specific options and key parameters
  
  int wheelEventX=0, wheelEventY=0; //how many scrolls of the wheel occurred in the last frame, both for horizontal and vertical scrolling
  boolean shiftHeld = false;        //whether shift is being held
  boolean ctrlHeld = false;         //whether control is being held
  
  long garbageWait = 1000; //how long to wait for garbage collection (default is 1 second, to disable, set to Long.MAX_VALUE)
  
  
  //// default preferences
  static float timing1=0.1f, timing2=0.1f, timing3=0.1f; //the preferred timings for buttons
  static float xBuff=5, yBuff=3; //the expected buffer thickness between the walls and the text inside a textbox
  
  //HashMap<Character, Long> keyTracker = new HashMap<Character, Long>(); //used to keep track of when each key was most recently pressed. When it gets released, the time is set to null
  Character keyLast = null;
  Integer keyCodeLast = null;
  Long keyTime = null;
  
  
  ArrayList<Textbox> handleRemovalCache = new ArrayList<Textbox>(); //a cache of textboxes whose handles need to be removed
  
  /////////////////////////// CONSTRUCTORS ///////////////////////////////
  
  Mmio(final PApplet a) {
    app = a; mmio = this;
  }
  
  Mmio(final PApplet a, float x2, float y2, float w2, float h2) {
    super(x2,y2,w2,h2);
    app = a; mmio = this;
  }
  
  ///////////////////////// GETTERS/SETTERS //////////////////////////////
  
  public void setCursorSelect(Cursor curs) { //sets what the cursor is selecting, ASSUMING the cursor was JUST pressed down
    Box box =  this.getCursorSelect(curs); //get the box this cursor is selecting, if any
    curs.setSelect(box);                   //set select to whatever we're pressing
  }
  
  public static void setDefaultButtonTimings(final float a, final float b, final float c) {
    timing1=a; timing2=b; timing3=c;
  }
  
  public static void setDefaultButtonTimings(final float t) { timing1=timing2=timing3 = t; }
  
  public void setTyper(Textbox t) { //sets typer
    if(typer!=null && typer!=t) { //if there's already a typer (other than this):
      typer.anchorCaret = typer.caret; typer.highlighting = false; //equalize the carets, disable highlighting
      typer.buddy.clearHandles(); //clear ts handles
      typer.removeSelectMenu();   //remove select menu
    }
    typer = t; //set typer
  }
  
  
  ///////////////////////// DRAWING/DISPLAY ///////////////////////////////
  
  public void display(PGraphics graph, float buffX, float buffY) {
    if(!active) { return; } //special case: io is inactive, don't display
    
    //first, record all the PGraphics's original drawing parameters
    final boolean fill2 = graph.fill, stroke2 = graph.stroke;
    final int fillColor2 = graph.fillColor, strokeColor2 = graph.strokeColor;
    final float strokeWeight2 = graph.strokeWeight, textSize2 = graph.textSize;
    final int textAlign2 = graph.textAlign, textAlignY2 = graph.textAlignY;
    final int imageMode2 = graph.imageMode;
    
    super.display(graph, buffX, buffY); //next, display
    
    //finally, reset all the PGraphics's original drawing parameters
    graph.fill(fillColor2); if(!fill2) { graph.noFill(); }
    graph.stroke(strokeColor2); graph.strokeWeight(strokeWeight2); if(!stroke2) { graph.noStroke(); }
    graph.textAlign(textAlign2, textAlignY2);
    graph.imageMode(imageMode2);
    if(graph.textSize != textSize2) { graph.textSize(textSize2); }
  }
  
  public void display() { display(app.g,0,0); }
  
  //////////////////////// SELECT PROMOTION //////////////////////
  
  //Here, we have a feature I call "select promotion", whereby, if you select a box (with certain exceptions), then move your mouse enough, your select will be
  //"promoted" to the parent panel. If that panel can't be dragged, you go to that panel's parent. So on and so forth until you reach one that drags or you
  //surpass the mmio and reach null.
  
  public static boolean attemptSelectPromotion(Cursor curs) { //looks at a cursor and goes through the process of seeing if it can select promote, and then potentially does it, returning true if it did
    Box select = curs.getSelect(); //get this box's select
    
    if(select==null || curs.seLocked) { return false; } //if null, or locked, return false
    
    boolean changeX = select instanceof Panel ? ((Panel)select).dragModeX==DragMode.NONE : true, //whether we can promote due to change in x direction
            changeY = select instanceof Panel ? ((Panel)select).dragModeY==DragMode.NONE : true; //whether we can promote due to change in y direction
    if(!changeX && !changeY) { return false; } //if we can't promote due to a change in either direction, then we simply can't promote. return false
    
    Panel promotion = select.parent; //get select's parent
    while(promotion!=null) {         //loop until the promotion is null
      if(promotion.dragModeX!=DragMode.NONE || promotion.dragModeY!=DragMode.NONE) { break; } //if this panel is draggable, break the loop and set this to our promotion
      else                                                  { promotion = promotion.parent; } //otherwise, promote promotion to its parent and let's try this again
    }
    
    if(promotion!=null) { //If there is a valid promotion:
      float distSq = (changeX ? sq(curs.x-curs.xi) : 0) + (changeY ? sq(curs.y-curs.yi) : 0); //measure the square distance we've traveled, measured perpendicular to the direction select can be dragged
      
      if(distSq >= sq(promotion.promoteDist)) { //if we moved enough to merit promotion:
        select.mmio.deselectAllButtons(curs);   //force the cursor to deselect all buttons
        if(select instanceof Panel) { ((Panel)select).setSurfaceV(0,0); } //if we were selecting a panel, set the velocity to 0
        
        curs.setSelect(promotion);          //promote the select
        curs.xi = curs.x; curs.yi = curs.y; //update the cursor's initial position
        return true;                        //return true to identify a promotion occurred
      }
    }
    
    //otherwise, check if select needs to be locked
    if(select instanceof Panel) { //if it's a panel:
      float distSq = (changeX ? 0 : sq(curs.x-curs.xi)) + (changeY ? 0 : sq(curs.y-curs.yi)); //measure the square distance we've traveled, measured parallel to the direction select can be dragged
      if(distSq >= sq(((Panel)select).promoteDist)) { //if the cursor has moved enough:
        curs.seLocked = true; //lock the selection
      }
    }
    return false; //then, return false
  }
  
  
  //////////////////////// UPDATES ///////////////////////////////
  
  /*void updateCursorsAndroid(TouchEvent.Pointer[] touches) {
    int ind = 0; //this represents our index as we iterate through both the touches list & the cursors list
    ArrayList<Cursor> adds = new ArrayList<Cursor>(), //arraylists of the cursors we add,
                      subs = new ArrayList<Cursor>(), //subtract,
                      movs = new ArrayList<Cursor>(); //and move
    
    while(ind<touches.length || ind<cursors.size()) { //loop through both lists until we reach the end of them both
      if(ind==cursors.size() || ind<touches.length && touches[ind].id < cursors.get(ind).id) { //if the touch ID is less than the cursor ID, that means a new touch was added before this cursor. If we're past the end of cursors, a new touch was added at the end
        Cursor curs = new Cursor(touches[ind].x, touches[ind].y).setId(touches[ind].id); //create new cursor to represent that touch
        //curs.press(LEFT);      //make the cursor pressed
        cursors.add(ind,curs); //add it to the list in the correct spot
        adds.add(curs);        //add it to the list of things we added
        ind++;                 //increment the index
      }
      else if(ind==touches.length || ind<cursors.size() && touches[ind].id > cursors.get(ind).id) { //if the touch ID is greater than the cursor ID, or we're past the end of touches, that means this cursor was removed from the touch list.
        subs.add(cursors.get(ind));     //add this cursor to the list of things we removed
        //cursors.get(ind).release(LEFT); //make the cursor released
        cursors.remove(ind);            //remove this cursor from the cursor list
        //don't increment the index, stay in the same place
      }
      else { //same ID:
        if(touches[ind].x != cursors.get(ind).x || touches[ind].y != cursors.get(ind).y) { //first, see if the position has changed
          movs.add(cursors.get(ind));                                 //if so, add this to the list
          cursors.get(ind).updatePos(touches[ind].x, touches[ind].y); //update the position
        }
        ind++; //in any case, increment index, then continue
      }
    }
    
    for(Cursor curs : adds) { //update everything to account for buttons pressed,
      setCursorSelect(curs);
      curs.press(LEFT);
      updateButtons(curs, (byte)1, false);
      
      if(typer!=null && typer.selectMenu!=null && curs.select!=typer.selectMenu && (curs.select==null || curs.select.parent!=typer.selectMenu)) {
        typer.removeSelectMenu(); //if we press something other than the select menu, remove the select menu
      }
    }
    for(Cursor curs : subs) { //to account for buttons released,
      curs.release(LEFT);
      updateButtons(curs, (byte)0, false);
      curs.setSelect(null);
      
      if(typer!=null && typer.hMode==Textbox.HighlightMode.MOBILE && typer.selectMenu==null && typer.highlighting) {
        typer.addSelectMenu(); //if we tap a highlighted mobile textbox, add a select menu
      }
    }
    for(Cursor curs : movs) { //and to account for cursors moved
      attemptSelectPromotion(curs);
      updateButtons(curs, (byte)3, false);
    }
  }*/
  
  public void keyPresser(char key, int keyCode, boolean snap) { //event performed every time a key is pressed
    if(typer!=null) {
      
      //if(keyCode==66 && key==10) { hitEnter(); } else //Android only, since their enter button is fucked
      switch(key) {
        case CODED: switch(keyCode) {
          case LEFT:
            typer.adjustHighlightingForArrows(shiftHeld);
            if(ctrlHeld) { typer.ctrlLeft(); }
            else { typer.moveCaretBy(-1,true,snap,true); }
          break;
          case RIGHT:
            typer.adjustHighlightingForArrows(shiftHeld);
            if(ctrlHeld) { typer.ctrlRight(); }
            else { typer.moveCaretBy( 1,true,snap,true); }
          break;
          case 36: {
            typer.adjustHighlightingForArrows(shiftHeld);
            typer.moveCaretTo(           0,true,snap,true); //home
          } break;
          case 35: {
            typer.adjustHighlightingForArrows(shiftHeld);
            typer.moveCaretTo(typer.size(),true,snap,true); //end
          } break;
          case SHIFT  : break;
          case CONTROL: break;
          
          //case BACKSPACE: { //(Android only) Backspace is a keyCode rather than a key. Also DELETE is the same as BACKSPACE
          //  boolean wasHighlighting = typer.highlighting && typer.caret != typer.anchorCaret; //first, record if we are currently highlighting
          //  
          //  typer.eraseSelection(); //if highlighting, erase the selection
          //  if     (ctrlHeld        ) { typer.ctrlBackspace(true,snap,true); } //ctrl+backspace if ctrl is held
          //  else if(!wasHighlighting) { typer.    backspace(true,snap,true); } //otherwise, if not highlighting, backspace one character
          //} break;
        } break;
        case 0: switch(keyCode) {
          case 2:
            typer.adjustHighlightingForArrows(shiftHeld);
            typer.moveCaretTo(           0,true,snap,true); //home
          break;
          case 3:
            typer.adjustHighlightingForArrows(shiftHeld);
            typer.moveCaretTo(typer.size(),true,snap,true); //end
          break;
        } break;
        
        case    DELETE: {
          boolean wasHighlighting = typer.highlighting && typer.caret != typer.anchorCaret; //first, record if we are currently highlighting
          
          typer.eraseSelection(); //if highlighting, erase the selection
          if     (ctrlHeld        ) { typer.ctrlDelete(true,snap,true); } //ctrl+delete if ctrl is held
          else if(!wasHighlighting) { typer.    delete(true,snap,true); } //otherwise, if not highlighting, delete one character
        } break;
        case BACKSPACE: {
          boolean wasHighlighting = typer.highlighting && typer.caret != typer.anchorCaret; //first, record if we are currently highlighting
          
          typer.eraseSelection(); //if highlighting, erase the selection
          if     (ctrlHeld        ) { typer.ctrlBackspace(true,snap,true); } //ctrl+backspace if ctrl is held
          else if(!wasHighlighting) { typer.    backspace(true,snap,true); } //otherwise, if not highlighting, backspace one character
        } break;
        
        case 'a'-96: { //ctrl+A
          typer.selectAll(snap); //select all
        } break;
        case 'c'-96: if(typer.highlighting) { //ctrl+C
          copyToClipboard(typer.substring(typer.getLeftCaret(), typer.getRightCaret())); //copy the selection to the clipboard
        } break;
        case 'v'-96: { //ctrl+V
          String text = getTextFromClipboard(); //grab the contents from clipboard
          if(text!=null) { //if the contents were valid:
            typer.eraseSelection(); //if highlighting, erase the selection
            typer.insert(text);     //insert the contents from the clipboard
          }
        } break;
        case 'x'-96: if(typer.highlighting) { //ctrl+X
          copyToClipboard(typer.substring(typer.getLeftCaret(), typer.getRightCaret())); //copy the selection to the clipboard
          typer.eraseSelection(); //erase the selection
        } break;
        
        case 'y'-96: break; //ctrl+Y
        case 'z'-96: break; //ctrl+Z
        
        default:
          if(key<='z'-96) { break; } //if it's a CTRL key, don't type that
          
          typer.eraseSelection(); //if it exists, erase the highlighted selection
          
          typer.type(key,true,snap,true); //otherwise, type it
        break;
      }
      
      typer.negateHighlight(); //make sure, if both carets are now in the same place, to un-highlight
      
      typer.buddy.correctHandles(); //correct the handles' orientation
    }
    
    if(key==CODED && keyCode==  SHIFT) { shiftHeld = true; } //if the shift key is held down, shiftHeld becomes true
    if(key==CODED && keyCode==CONTROL) {  ctrlHeld = true; } //if the  ctrl key is held down,  ctrlHeld becomes true
    
    updatePressCount(); //reset all button press counts to 0
  }
  
  public void keyReleaser(char key, int keyCode) { //event performed every time a key is released
    if(key==CODED) { //if coded:
      if     (keyCode==  SHIFT) { shiftHeld=false; } //SHIFT: release shift
      else if(keyCode==CONTROL) {  ctrlHeld=false; } //CTRL : release ctrl
      else if(typer!=null && keyCode==155) { typer.insert^=true; } //insert: change insert setting
    }
    else if(typer!=null && key==0 && keyCode==26) { typer.insert^=true; }
  
    if(keyLast!=null && match(keyLast,key) && keyCodeLast==keyCode) { //if we release the key we're pressing, set it to null
      keyLast = null; keyCodeLast = null; keyTime = null;
    }
    
    updatePressCount(); //reset all button press counts to 0
  }
  
  public void updatePanelScroll(Cursor curs) {
    if(wheelEventX!=0 || wheelEventY!=0) { updatePanelScroll(curs, wheelEventX, wheelEventY); }
  }
  
  public void updateCursorDPos() { //updates the previous draw cycle positions of each cursor
    for(Cursor curs : cursors) {      //loop through all cursors
      curs.dx=curs.x; curs.dy=curs.y; //set previous positions equal to current positions
    }
  }
  
  public void updateButtonHold(long time, long timePrev) { //updates all the buttons being held down
    for(Cursor curs : cursors) { //look through all active cursors
      if(curs.select instanceof Button) { //only focus on the ones that are selecting a button
        Button butt = (Button)curs.select; //cast to a button
        //TODO see why and when butt.cursors.get(curs) could or would ever be null. It's not supposed to be null, but it was, that's why I had to add this extra expression so it wouldn't crash
        //the bug seems to happen when I press a lot of buttons at once.
        if(butt.cursors.get(curs)!=null && butt.cursors.get(curs) && butt.onHeld!=emptyAction) { //if this button is, indeed, being held down (and it does something when held down):
          long timeSince = time-butt.firstActivated-butt.holdTimer, timePrevSince = timePrev-butt.firstActivated-butt.holdTimer; //record the time(s) since we were first allowed to use hold functionality
          if(timeSince > 0 && timeSince/butt.holdFreq != timePrevSince/butt.holdFreq) { //if enough time has passed, and it's been enough time since the last activation:
            butt.onHeld.act(); //perform the designated on-held action
          }
        }
      }
    }
  }
  
  public void removeHandles() { //remove handles from textboxes scheduled to have their handles removed
    while(handleRemovalCache.size()!=0) { //perform the following loop until all the handles are removed
      handleRemovalCache.get(0).buddy.clearHandles(); //remove handles
      handleRemovalCache.remove(0); //remove textbox
    }
  }
  
  public void removeHandlesLater(Textbox tbox) { //schedules for a textbox's handles to be removed later
    handleRemovalCache.add(tbox); //literally just add it to the handle removal cache
  }
  
  ///////////////////// BUFFERS /////////////////////////////////
  
  public void ensureBufferSupport(int x, int y) { //expands buffer dimensions to that it can support an object at the given position
    if(buffHig<=y) { //if unable to support the y position:
      for(ArrayList<ArrayList<Buffer>> buff : buffers) { //loop through all columns
        buff.ensureCapacity(y+1);                                    //ensure capacity
        while(buff.size()<=y) { buff.add(new ArrayList<Buffer>()); } //add elements until it's big enough
      }
      buffHig = y+1; //update buffer height
    }
    while(buffWid<=x) { //if/while unable to support the x position:
      ArrayList<ArrayList<Buffer>> addMe = new ArrayList<ArrayList<Buffer>>(buffHig); //initialize new column
      while(addMe.size()<=buffHig) { addMe.add(new ArrayList<Buffer>()); }            //add elements until it's big enough
      buffers.add(addMe); buffWid++;                                                  //add new column, increment width
    }
  }
  
  public Buffer addBuffer(int x, int y) { //adds new buffer (dimensions 2^x x 2^y) to the list, returns newly added buffer
    ensureBufferSupport(x,y); //expand the dimensions so we can support the new buffer
    Buffer buff = new Buffer(app,1<<x,1<<y); //initialize new buffer
    buffers.get(x).get(y).add(buff);         //add to the arraylist
    return buff;                             //return result
  }
  
  public void bufferGarbageCollect() { //performs a garbage collection algorithm on the buffers
    if(System.currentTimeMillis() >= buffTime+garbageWait) { //if it's been at least a second (or however long this is set to) since our last garbage collect:
      for(ArrayList<ArrayList<Buffer>> buff1 : buffers) for(ArrayList<Buffer> buff2 : buff1) { //loop through 2 dimensional array of buffer lists
        for(int n=0;n<buff2.size();n++) {                       //loop through said lists
          if(!buff2.get(n).wasUsed()) { buff2.remove(n); n--; } //if any of the buffers haven't been used in the past 8 seconds (or however long this is set to), remove them (then decrement so we don't skip)
          else                        { buff2.get(n).step();  } //otherwise, make them step in time
        }
      }
      buffTime+=garbageWait; //lastly, increment the buffer time by 1 second so we know to wait another second (or however long this is set to)
    }
  }
  
  public int getBufferNumber() { //gets number of buffers
    int num = 0;
    for(ArrayList<ArrayList<Buffer>> buff1 : buffers) for(ArrayList<Buffer> buff2 : buff1) { num+=buff2.size(); }
    return num;
  }
  
  public long approxBufferRAM() { //gets approximate RAM used by buffers
    long ram = 0; //init to 0
    for(int x=0;x<buffWid;x++) for(int y=0;y<buffHig;y++) { //loop through the 2 dimensional array
      ram += buffers.get(x).get(y).size() << (x+y+2); //the RAM of each buffer is approximately 4*2^(x+y), because it's 2^x * 2^y pixels * 4 bytes/pixel
    }
    return ram; //return result
  }
  
  ///////////////////// MISC ///////////////////////////////////
  
  /*
  ArrayList<Box> generateRecursiveList() {
    ArrayList<Panel> list1 = new ArrayList<Panel>(); list1.add(this); //list1 will hold this generation
    ArrayList<Panel> list2;                                           //list2 will hold all the (panel) children of this generation
    ArrayList<Box> list3 = new ArrayList<Box>(); list3.add(this);     //list3 will hold everything
    
    while(!list1.isEmpty()) { //loop until this generation is empty
      
      list2 = new ArrayList<Panel>(); //initialize list2
      for(Panel panel : list1) { //loop through all panels in list1
        for(Box box : panel) {   //loop through all boxes in each panel
          list3.add(box);        //add each box to the total list
          if(box instanceof Panel) { list2.add((Panel)box); } //if it's a panel, add it to list2
        }
      }
      list1 = list2; //set list1 equal to list2
    }
    
    return list3; //return the total list
  }*/
  
  public float getTextWidth(String txt, float siz) { //gets the width of a particular string at a particular size, without changing anything
    Buffer buff = loadBuffer(this, (byte)0, (byte)0); //load a 1x1 PGraphics object
    buff.beginDraw();         //begin draw
    buff.graph.textSize(siz); //set text size
    float wid = buff.graph.textWidth(txt); //get the width
    buff.endDraw();   //end draw
    buff.useNt();     //stop using buffer
    return wid;       //return the width
  }
  
  public static float getTextHeight(float siz) { return siz*1.164f+0.902f; } //gets the height of a text of a specific size, assuming there are no "\n"s
  
  public static float invTextHeight(float siz) { return 0.859f*siz-0.775f; } //gets the text size needed for a particular text height
  
  public static float getTextHeight(String txt, float siz) {
    return getTextHeight(siz)*getLines(txt);
  }
  
  public static int getLines(String txt) {
    int lines = 1; for(int n=0;n<txt.length();n++) { if(txt.charAt(n)=='\n') { ++lines; } }
    return lines;
  }
  
  public static boolean isAncestorTo(Panel panel, Box box) { //returns whether the panel is an ancestor to the box
    while(box!=null) { //perform the following loop until the box is null
      if(box==panel) { return true; } //if, at any point, the box is the same as the panel, return true
      box = box.parent;               //each iteration, traverse up the ancestry tree
    }
    return false; //if neither box nor any of its parents were equal to panel, return false
  }
  
  //int[] getTypingCode() { return typer.insert ? InputCode.INSERT : InputCode.OVERTYPE; }
}

/*public static class Pointer {
  public int id;
  public float x, y;
  public float area;
  public float pressure;
}*/
public static class MathObj { //represents any mathematical object we can plug into our equations
  public Complex number=null; //a number
  public boolean bool=false;  //a boolean
  public CVector vector=null; //a vector
  public CMatrix matrix;      //a matrix
  public Date date;           //a date
  public MathObj[] array;     //an array
  public String message="";   //a string (usually error message)
  public VarType type = VarType.NONE; //type of variable
  public Equation equation = null; //an equation
  
  public boolean fp = false; //whether it's displayed at full precision (usually false)
  
  public enum VarType {BOOLEAN,COMPLEX,VECTOR,MATRIX,DATE,ARRAY,EQUATION,MESSAGE,NONE; public String toString() { return name().toLowerCase(); } }
  
  public MathObj()             { type=VarType.NONE; }
  public MathObj(Complex c)    { number=c; type=VarType.COMPLEX; }
  public MathObj(double d)     { number=new Complex(d); type=VarType.COMPLEX; }
  public MathObj(boolean b)    { bool=b; type=VarType.BOOLEAN; }
  public MathObj(String s)     { message=s; type=VarType.MESSAGE; }
  public MathObj(CVector v)    { vector=v; type=VarType.VECTOR; }
  public MathObj(CMatrix m)    { matrix=m; type=VarType.MATRIX; }
  public MathObj(Date d)       { date=d; type=VarType.DATE; }
  public MathObj(Equation e)   { equation=e; type=VarType.EQUATION; }
  public MathObj(MathObj... a) { array=a; type=VarType.ARRAY; }
  
  public MathObj(Entry e) {
    if(e.getType()==EntryType.NUM) { number = Cpx.complex(e.getId()); type=VarType.COMPLEX; }
    else if(e.getType()==EntryType.CONST) {
      switch(e.getId()) {
        case "e": number = new Complex(Math.E);  type=VarType.COMPLEX; break;
        case "i": number = Cpx.i();              type=VarType.COMPLEX; break;
        case "π": case "pi"   : number = new Complex(Math.PI); type=VarType.COMPLEX; break;
        case "γ": case "gamma": number = new Complex(Mafs.GAMMA); type=VarType.COMPLEX; break;
        
        case "Catalan": number = new Complex(0.91596559417721902d); type = VarType.COMPLEX; break;
        
        case  "true": bool= true; type=VarType.BOOLEAN; break;
        case "false": bool=false; type=VarType.BOOLEAN; break;
        
        case "today": date = Date.today(); type=VarType.DATE; break;
        case "yesterday": date = Date.yesterday(); type=VarType.DATE; break;
        case "tomorrow": date = Date.tomorrow(); type=VarType.DATE; break;
        case "Sunday"   : date = Date.   sunday(); type=VarType.DATE; break;
        case "Monday"   : date = Date.   monday(); type=VarType.DATE; break;
        case "Tuesday"  : date = Date.  tuesday(); type=VarType.DATE; break;
        case "Wednesday": date = Date.wednesday(); type=VarType.DATE; break;
        case "Thursday" : date = Date. thursday(); type=VarType.DATE; break;
        case "Friday"   : date = Date.   friday(); type=VarType.DATE; break;
        case "Saturday" : date = Date. saturday(); type=VarType.DATE; break;
      }
      
      if(type==VarType.NONE) { //if we still haven't found it, it might be a date
        String s = e.getId(); //grab the ID
        for(int n=0;n<Month.matchers.length;n++) { //try seeing if this is a date
          if(s.startsWith(Month.matchers[n])) {    //if it starts with a month:
            s = s.substring(Month.matchers[n].length()); //remove the month from the beginning
            int day; long year; //now, we try to find the day and year
            int ind = s.indexOf(", "); //see if there's a comma somewhere there
            if(ind==-1) { day = Integer.parseInt(s); year = Date.year(); } //if no year given, set it to this year
            else { //otherwise:
              day = Integer.parseInt(s.substring(0,ind)); year = Long.parseLong(s.substring(ind+2)); //set the day to the first part, the year to the second part
            }
            date = new Date(Month.matchId[n],day,year); type=VarType.DATE; //finally, load the corresponding date
          }
        }
      }
    }
  }
  
  public MathObj(String s, boolean b) { //TODO whatever you were planning on doing with this
    if     (s.equals( "true")) { bool= true; type=VarType.BOOLEAN; }
    else if(s.equals("false")) { bool=false; type=VarType.BOOLEAN; }
    
    else if(s.equals("Overflow")) { number=new Complex(Double.POSITIVE_INFINITY); type=VarType.COMPLEX; }
    else if(s.equals("Negative Overflow")) { number=new Complex(Double.NEGATIVE_INFINITY); type=VarType.COMPLEX; }
    
    else {
      for(int n=0;n<Month.matchers.length;n++) { //try seeing if this is a date
        if(s.startsWith(Month.matchers[n])) {    //if it starts with a month:
          s = s.substring(Month.matchers[n].length()); //remove the month from the beginning
          int day; long year; //now, we try to find the day and year
          int ind = s.indexOf(", "); //see if there's a comma somewhere there
          if(ind==-1) { day = Integer.parseInt(s); year = Date.year(); } //if no year given, set it to this year
          else { //otherwise:
            day = Integer.parseInt(s.substring(0,ind)); year = Long.parseLong(s.substring(ind+2)); //set the day to the first part, the year to the second part
          }
          date = new Date(Month.matchId[n],day,year); type=VarType.DATE; //finally, load the corresponding date
          return; //quit the constructor
        }
      }
      
      if(type==VarType.NONE) { //if the type still hasn't been chosen yet
        number=Cpx.complex(s); type = (number==null) ? VarType.NONE : VarType.COMPLEX; //try casting to a complex number
      }
    }
  }
  
  public boolean isNum() { return type==VarType.COMPLEX; }
  public boolean isBool() { return type==VarType.BOOLEAN; }
  public boolean isVector() { return type==VarType.VECTOR; }
  public boolean isMatrix() { return type==VarType.MATRIX; }
  public boolean isDate() { return type==VarType.DATE; }
  public boolean isArray() { return type==VarType.ARRAY; }
  public boolean isMessage() { return type==VarType.MESSAGE; }
  public boolean isEquation() { return type==VarType.EQUATION; }
  public boolean isNone() { return type==VarType.NONE; }
  
  public boolean isNormal() { return type!=VarType.NONE && type!=VarType.MESSAGE; }
  
  public void set(MathObj m) {
    bool=m.bool; number=m.number; vector=m.vector; matrix=m.matrix; message=m.message;
    type = m.type;
  }
  
  @Override
  public String toString() {
    String res;
    Complex.omit_Option = !fp;
    int dig = fp ? -1 : 13;
    switch(type) {
      case COMPLEX: res = number.toString(dig); break;
      case BOOLEAN: res = bool+"";              break;
      case VECTOR: res = vector.toString(dig);  break;
      case MATRIX: res = matrix.toString(dig);  break;
      case DATE:   res = date.toString();       break;
      case ARRAY: {
        StringBuilder sb = new StringBuilder("{");
        for(int n=0;n<array.length;n++) {
          if(n!=0) { sb.append(","); }
          sb.append(array[n]);
        }
        res = sb.append("}").toString();
      } break;
      case MESSAGE: res = message;              break;
      default: res = "NULL";
    }
    Complex.omit_Option=true;
    return res;
  }
  
  @Override
  public MathObj clone() {
    switch(type) {
      case COMPLEX: return new MathObj(number.copy());
      case BOOLEAN: return new MathObj(bool);
      case VECTOR: return new MathObj(vector.clone());
      case MATRIX: return new MathObj(matrix.clone());
      case DATE:   return new MathObj(date.clone());
      case ARRAY: { //TODO implement a check/special case for infinite recursion
        MathObj[] copyArr = new MathObj[array.length]; //create a copy array
        for(int n=0;n<array.length;n++) {
          copyArr[n] = array[n].clone(); //clone each individual element
        }
        return new MathObj(copyArr); //return resulting array
      }
      case MESSAGE: return new MathObj(message+"");
      case EQUATION: return new MathObj(equation); //TODO FOR NOW, WE ARE NOT CLONING THE EQUATION. THIS MIGHT CHANGE LATER
      case NONE: return new MathObj();
    }
    return null;
  }
  
  @Override
  public boolean equals(final Object obj) {
    if(obj instanceof MathObj) {
      MathObj m = (MathObj)obj;
      if(type!=m.type) { return false; }
      switch(type) {
        case COMPLEX: return number.equals(m.number);
        case BOOLEAN: return bool == m.bool;
        case VECTOR: return vector.equals(m.vector);
        case MATRIX: return matrix.equals(m.matrix);
        case DATE: return date.equals(m.date);
        case MESSAGE: return message.equals(m.message);
        case ARRAY: {
          if(array.length!=m.array.length) { return false; }
          for(int n=0;n<array.length;n++) {
            if(!array[n].equals(m.array[n])) { return false; }
          }
          return true;
        }
        case EQUATION: return false; //TODO FOR NOW, WE ARE NOT COMPARING EQUATIONS
        case NONE: return true;
      }
    }
    return false;
  }
  
  @Override
  public int hashCode() {
    switch(type) {
      case COMPLEX: return number.hashCode();
      case BOOLEAN: return bool ? 1231 : 1237;
      case VECTOR: return vector.hashCode();
      case MATRIX: return matrix.hashCode();
      case DATE: return date.hashCode();
      case MESSAGE: return message.hashCode();
      case ARRAY: {
        int hash = 3;
        for(MathObj m : array) {
          hash = 31*hash + m.hashCode();
        }
        return hash;
      }
      case EQUATION: return 1371;
      case NONE: return 8197;
    }
    return 8;
  }
  
  public String saveAsString() {
    String result = type.name()+" ";
    while(result.length()<9) { result+=" "; }
    switch(type) {
      case COMPLEX: result+=hex(number); break;
      case BOOLEAN: result+=bool?"1":"0"; break;
      case VECTOR: result+=hex(vector.size())+" "; for(int n=0;n<vector.size();n++) { result+=hex(vector.get(n))+" ";  } break;
      case MATRIX: result+=hex(matrix.h)+" "+hex(matrix.w)+" "; for(int i=1;i<=matrix.h;i++) for(int j=1;j<=matrix.w;j++) { result+=hex(matrix.get(i,j))+" "; } break;
      case DATE: result+=hex(date.day); break;
      case MESSAGE: result+=message; break;
      case ARRAY: {
        result += hex(array.length)+" "; //show the array length
        for(int n=0;n<array.length;n++) { //loop through the array
          if(n!=0) { result+=","; } //separate each entry w/ commas
          result += "("+array[n].saveAsString()+")"; //wrap each entry in parentheses
        }
      } break;
      case EQUATION: throw new RuntimeException("I'm not ready to save an equation to a file!!!");
      case NONE: break;
    }
    return result; //return result
  }
  
  public static MathObj loadFromString(String s) {
    switch(s.substring(0,8)) { //switch between the first 8 characters:
      case "COMPLEX ": {
        return new MathObj(cUnhex(s.substring(9)));
      }
      case "BOOLEAN ": {
        return new MathObj(s.charAt(9)=='1');
      }
      case "VECTOR  ": {
        int size = unhex(s.substring(9,17)); //compute the size of the vector
        Complex[] load = new Complex[size];  //load the vector array
        for(int n=0;n<size;n++) { load[n] = cUnhex(s.substring(18+34*n,50+34*n)); } //load each complex component
        return new MathObj(new CVector(load)); //return resulting vector
      }
      case "MATRIX  ": {
        int h = unhex(s.substring(9,17)), w = unhex(s.substring(18,26)); //find the dimensions of the matrix
        Complex[] load = new Complex[h*w]; //load the matrix array
        for(int n=0;n<h*w;n++) { load[n] = cUnhex(s.substring(27+34*n,59+34*n)); } //load each complex component
        return new MathObj(new CMatrix(h, w, load)); //return resulting matrix
      }
      case "DATE    ": {
        long d = lUnhex(s.substring(9,25));
        return new MathObj(new Date(d));
      }
      case "ARRAY   ": {
        int parCount = 0; //while iteratively evaluating the string, we must keep track of the number of parentheses
        int startInd = -1; //for each entry, we must know where that entry's string starts
        int size = unhex(s.substring(9,17)); //compute the size of the array
        MathObj[] elements = new MathObj[size]; //load the math object array
        int index = 0;
        
        for(int i=18;i<s.length();i++) { //loop through the remaining characters
          if(s.charAt(i)=='(') {
            if(parCount == 0) { startInd=i+1; }
            parCount++;
          }
          else if(s.charAt(i)==')') {
            parCount--;
            if(parCount == 0) {
              elements[index] = loadFromString(s.substring(startInd,i)); //load from the substring from the start index to here
              index++; //increment the index
            }
          }
        }
        
        return new MathObj(elements); //return a math object created from that array
      }
      case "MESSAGE ": {
        return new MathObj(s.substring(9));
      }
      case "EQUATION": {
        throw new RuntimeException("I'm not ready to load an equation from a file!!!");
      }
      default: return new MathObj();
    }
  }
  
  //////////////// ARITHMETIC ////////////////////////
  //(Important for numerical methods, such as integration or Runge Kutta)
  
  public MathObj add(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot add "+type+" to "+m.type); }
    switch(type) {
      case COMPLEX: return new MathObj(number.add(m.number));
      case VECTOR : return new MathObj(vector.add(m.vector));
      case MATRIX : return new MathObj(matrix.add(m.matrix));
      default: throw new RuntimeException("Cannot add "+type+" together");
    }
  }
  
  public MathObj sub(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot subtract "+type+" minus "+m.type); }
    switch(type) {
      case COMPLEX: return new MathObj(number.sub(m.number));
      case VECTOR : return new MathObj(vector.sub(m.vector));
      case MATRIX : return new MathObj(matrix.sub(m.matrix));
      default: throw new RuntimeException("Cannot subtract "+type+" together");
    }
  }
  
  public MathObj addeq(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot add "+type+" to "+m.type); }
    switch(type) {
      case COMPLEX: number.addeq(m.number); break;
      case VECTOR : vector.addeq(m.vector); break;
      case MATRIX : matrix.addeq(m.matrix); break;
      default: throw new RuntimeException("Cannot add "+type+" together");
    }
    return this;
  }
  
  public MathObj subeq(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot subtract "+type+" minus "+m.type); }
    switch(type) {
      case COMPLEX: number.subeq(m.number); break;
      case VECTOR : vector.subeq(m.vector); break;
      case MATRIX : matrix.subeq(m.matrix); break;
      default: throw new RuntimeException("Cannot subtract "+type+" together");
    }
    return this;
  }
  
  public MathObj neg() {
    switch(type) {
      case COMPLEX: return new MathObj(number.neg());
      case VECTOR : return new MathObj(vector.neg());
      case MATRIX : return new MathObj(matrix.neg());
      default: throw new RuntimeException("Cannot negate "+type);
    }
  }
  
  public MathObj negeq() {
    switch(type) {
      case COMPLEX: number.negeq(); break;
      case VECTOR : vector.negeq(); break;
      case MATRIX : matrix.negeq(); break;
      default: throw new RuntimeException("Cannot negate "+type);
    }
    return this;
  }
  
  public MathObj mul(final Complex c) {
    switch(type) {
      case COMPLEX: return new MathObj(number.mul(c));
      case VECTOR : return new MathObj(vector.mul(c));
      case MATRIX : return new MathObj(matrix.mul(c));
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
  }
  
  public MathObj mul(final double d) {
    switch(type) {
      case COMPLEX: return new MathObj(number.mul(d));
      case VECTOR : return new MathObj(vector.mul(d));
      case MATRIX : return new MathObj(matrix.mul(d));
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
  }
  
  public MathObj div(final Complex c) {
    switch(type) {
      case COMPLEX: return new MathObj(number.div(c));
      case VECTOR : return new MathObj(vector.div(c));
      case MATRIX : return new MathObj(matrix.div(c));
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
  }
  
  public MathObj div(final double d) {
    switch(type) {
      case COMPLEX: return new MathObj(number.div(d));
      case VECTOR : return new MathObj(vector.div(d));
      case MATRIX : return new MathObj(matrix.div(d));
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
  }
  
  public MathObj muleq(final Complex c) {
    switch(type) {
      case COMPLEX: number.muleq(c); break;
      case VECTOR : vector.muleq(c); break;
      case MATRIX : matrix.muleq(c); break;
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
    return this;
  }
  
  public MathObj muleq(final double d) {
    switch(type) {
      case COMPLEX: number.muleq(d); break;
      case VECTOR : vector.muleq(d); break;
      case MATRIX : matrix.muleq(d); break;
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
    return this;
  }
  
  public MathObj diveq(final Complex c) {
    switch(type) {
      case COMPLEX: number.diveq(c); break;
      case VECTOR : vector.diveq(c); break;
      case MATRIX : matrix.diveq(c); break;
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
    return this;
  }
  
  public MathObj diveq(final double d) {
    switch(type) {
      case COMPLEX: number.diveq(d); break;
      case VECTOR : vector.diveq(d); break;
      case MATRIX : matrix.diveq(d); break;
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
    return this;
  }
}


public static String hex(long l) { return hex((int)(l>>>32))+hex((int)l); }
public static String hex(double d) { return hex((long)Double.doubleToLongBits(d)); }
public static String hex(Complex c) { return hex(c.re)+" "+hex(c.im); }

public static long lUnhex(String s) { return ((long)unhex(s.substring(0,8)))<<32 | (long)unhex(s.substring(8)) & ((1l<<32)-1); }
public static double dUnhex(String s) { return Double.longBitsToDouble(lUnhex(s)); }
public static Complex cUnhex(String s) { return new Complex(dUnhex(s.substring(0,16)), dUnhex(s.substring(17))); }
/*
Panels are a bit different than other Boxes. A panel is composed of 3 components: the surface, the window, and the children.
The children are all the components (boxes) which are displayed as part of the panel. The surface acts like a table mat to display all the
children. The window acts as a literal window from which you can view part of the surface. The surface is at least as large as the window, and
can be moved (scrolled) around freely. Meanwhile, only the parts of the surface which are visible through the window are actually displayed.

All the attributes inherited from box apply to the window. fill is false by default, but you can set it to true to cover up the surface. Or, if fillColor is partially transparent, you can use it
to give you a tinted window.

There are also some attributes which were created solely for describing the surface. Namely its position WRT the window, its dimensions, and its background fill
*/

public static class Panel extends Box implements Iterable<Box> {
  
  ////////////////////// ATTRIBUTES ////////////////////////
  
  ArrayList<Box> children = new ArrayList<Box>(); //all the boxes nested in this panel
  
  //surface attributes
  float surfaceX=0, surfaceY=0;   //position of surface
  float surfaceW=0, surfaceH=0;   //dimensions of surface
  float surfaceVx=0, surfaceVy=0; //velocity of surface
  boolean surfaceFill=true;       //whether to fill the surface
  int surfaceFillColor;         //fill color of surface
  
  float surfaceXi=0, surfaceYi=0;       //"initial" position of surface, position when a touch was initialized
  ArrayList<Cursor> pointers = new ArrayList<Cursor>(); //arraylist of all the cursors that are dragging around this surface
  //this is called pointers and not cursors because MMIO already has an arraylist called cursors, and it's used for something else. We don't want that to override this
  
  //targeting attributes:
  SurfaceTarget target = null; //the surface position we target towards (null means we aren't targeting right now)
  float xSpace=Mmio.xBuff, ySpace=Mmio.yBuff; //the breathing space we give when something is on the far edge. For targeting purposes, if something is less than xSpace,ySpace from the edge, it's considered too close
  
  //physics attributes
  float airFric = 3; //coefficient of air friction, in Hz
  float kinFric = 0; //coefficient of kinetic friction, multiplied by normal force, in pix/s^2
  float minVel = 2;  //when velocity is below this (in pix/s), we set it to 0
  boolean sliding = false; //true when the panel is uniformly, linearly sliding without any external forces until it hits the edge
  
  //// specific options and key parameters
  
  boolean canScrollX = true, canScrollY = true; //whether you can scroll with the mouse
  
  DragMode dragModeX = DragMode.NONE, dragModeY = DragMode.NONE; //the drag mode for this panel, both in the x and y directions. On PC, dragging usually doesn't exist
  float promoteDist = 12; //how many pixels you have to move your cursor from its initial position to trigger select promotion
  
  float pixPerClickH, pixPerClickV; //how many pixels you move per movement of the mouse wheel (both horizontally & vertically)
  
  ////////////////////// CONSTRUCTORS //////////////////////
  
  Panel() { super(); fill=false; } //by default, you don't fill in the window.
  
  Panel(final float x2, final float y2, final float w2, final float h2, final float w3, final float h3) { super(x2,y2,w2,h2); surfaceX=surfaceY=0; surfaceW=w3; surfaceH=h3; fill=false; initPixPerClick(); } //constructor w/ dimensional parameters
  
  Panel(final float x2, final float y2, final float w2, final float h2) { this(x2,y2,w2,h2,w2,h2); } //constructor w/ fewer dimensional parameters
  
  ////////////////////// GETTERS //////////////////////
  
  public float getSurfaceX() { return surfaceX; } //gets position of surface (in x direction)
  public float getSurfaceY() { return surfaceY; } //gets position of surface (in x direction)
  public float getSurfaceVx() { return surfaceVx; } //gets x velocity of surface
  public float getSurfaceVy() { return surfaceVy; } //gets y velocity of surface
  public float getSurfaceW() { return surfaceW; } //gets width of surface
  public float getSurfaceH() { return surfaceH; } //gets height of surface
  public float getObjSurfaceX() { return getObjX()+surfaceX; } //gets objective position of surface (in x direction)
  public float getObjSurfaceY() { return getObjY()+surfaceY; } //gets objective position of surface (in y direction)
  
  public float getSurfaceXRelTo(Panel p) { return getXRelTo(p)+surfaceX; } //gets relative position of surface (in x direction)
  public float getSurfaceYRelTo(Panel p) { return getYRelTo(p)+surfaceY; } //gets relative position of surface (in y direction)
  
  public boolean canScrollX() { return canScrollX; } //whether or not you can scroll with the mouse in each direction
  public boolean canScrollY() { return canScrollY; }
  
  public Box getChild(final int ind) { return children.get(ind); } //returns child at particular index
  public int numChildren()           { return children.size();   } //returns number of children
  
  ////////////////////// MUTATORS //////////////////////
  
  public Panel setSurfaceW(final float w2) { surfaceW=w2; return this; }
  public Panel setSurfaceH(final float h2) { surfaceH=h2; return this; }
  public Panel setSurfaceDims(final float w2, final float h2) { surfaceW=w2; surfaceH=h2; return this; }
  public Panel setSurfaceV(final float x2, final float y2) { surfaceVx=x2; surfaceVy=y2; return this; }
  
  public Panel setScrollX(final float x2) { surfaceX=x2; return this; }
  public Panel setScrollY(final float y2) { surfaceY=y2; return this; }
  public Panel setScroll(final float x2, final float y2) { surfaceX=x2; surfaceY=y2; return this; }
  
  public Panel setScrollableX(final boolean s) { canScrollX = s; return this; }
  public Panel setScrollableY(final boolean s) { canScrollY = s; return this; }
  public Panel setScrollable(final boolean sx, final boolean sy) { canScrollX = sx; canScrollY = sy; return this; }
  
  public Panel setSurfaceFill(boolean s) { surfaceFill=s; return this; }
  public Panel setSurfaceFill(int s) { surfaceFillColor=s; return this; }
  
  public void shiftSurface(final float x2, final float y2) {
    surfaceX = constrain(surfaceX+x2, w-surfaceW, 0);
    surfaceY = constrain(surfaceY+y2, h-surfaceH, 0);
  }
  
  public Panel setPixPerClickH(final float h) { pixPerClickH = h; return this; } //sets the rate of pixels scrolled per click of the mouse (negative means inverted scrolling)
  public Panel setPixPerClickV(final float v) { pixPerClickV = v; return this; } //we need to be able to set it horizontally and vertically
  public Panel setPixPerClick(final float h, final float v) { pixPerClickH = h; pixPerClickV = v; return this; }
  
  public Panel setDragMode(final DragMode sx, final DragMode sy) { dragModeX = sx; dragModeY = sy; return this; } //sets the dragging mode
  
  ////////////////////// DRAWING/DISPLAY //////////////////////
  
  public void display(PGraphics graph, float buffX, float buffY) {
    
    if(surfaceFill) { graph.fill(surfaceFillColor); } else { graph.noFill(); } //set drawing attributes
    graph.noStroke(); //no stroke, we draw the border afterward
    
    graph.rect(getX()-buffX, getY()-buffY, w, h, r); //draw the surface background, constrained to within the window
    
    for(Box b : this) { if(b.active) {      //loop through all active children
      displayChild(b, graph, buffX, buffY); //display each child
    } }
    
    extraDisplay(graph, buffX, buffY); //run any extra functionality we might want to run
    
    super.display(graph, buffX, buffY); //finally, draw the window over it all
  }
  
  public void extraDisplay(PGraphics graph, float buffX, float buffY) { } //is used by other, derived classes to draw extra stuff
  
  public void displayChild(Box b, PGraphics graph, float buffX, float buffY) { //displays the child
    
    final byte out = outCode(b.getX(),b.getY(),b.w,b.h,w,h); //use compressed cohen-sutherland algorithm to generate 5-bit outcode
    
    if((out&16)!=16) { //skip all boxes that are completely out of bounds
      if(out==0) { b.display(graph, buffX-getX(), buffY-getY()); } //if box is completely in bounds: display it on the same PGraphics object
      else { //otherwise:
        
        if((out&12)==12) { throw new RuntimeException("ERROR: box is clipped left & right. Such behavior is not yet implemented, try to make children smaller than their parents!"); }
        if((out& 3)== 3) { throw new RuntimeException("ERROR: box is clipped up & down. Such behavior is not yet implemented, try to make children smaller than their parents!"); }
        
        float buffWid = ((out&4)==4 ? w : b.getX()+b.w) - ((out&8)==8 ? 0 : b.getX()), //calculate minimum buffer width
              buffHig = ((out&1)==1 ? h : b.getY()+b.h) - ((out&2)==2 ? 0 : b.getY()); //and minimum buffer height
        //this is done by subtracting the position of the right/bottom minus the position of the left/top.
        
        byte px=0, py=0; //the smallest power of 2 whose dimensions can fit this buffered display (both in x & y direction)
        while(buffWid>(1<<px)) { ++px; } while(buffHig>(1<<py)) { ++py; } //continually increment both until they are powers of 2 >= width & height
        //TODO make failsafe for the special case when the required width/height is larger than the largest int
        
        Buffer buff = loadBuffer(mmio, px, py); //Load the smallest buffer of at least size 2^px x 2^py. If none are available, create your own one and add it to the list
        
        float buffX2 = (out&8)==8 ? 0 : (out&4)==4 ? w-buff. width() : b.getX(), //calc x pos of buffer (WRT panel)
              buffY2 = (out&2)==2 ? 0 : (out&1)==1 ? h-buff.height() : b.getY(); //calc y pos of buffer (WRT panel)
        //left outcode = left of buff on left of panel (0), right outcode = right of buff on right of panel (w-buff.width()), no outcode = left of buff on left of box (b.getX())
        //up and down can be done the same w/out loss of generality
        
        // float x3 = b.getX()+((out&4)==4 ? buffWid-buff. width() : b.w-buffWid), //calc x pos of buffer (WRT panel)
        //       y3 = b.getY()+((out&1)==1 ? buffHig-buff.height() : b.h-buffHig); //calc y pos of buffer (WRT panel)
        // This was the code that was originally used. It was replaced for being too unintuitive and, more importantly, having roundoff,
        // but I still keep it as a comment because there's a certain elegance to it.
        
        buff.beginDraw();                      //put buffer in use & begin drawing
        b.display(buff.graph, buffX2, buffY2); //display button onto buffer (buffX2,buffY2 are the pos of the buffer WRT the panel, which according to Box.display, is what they should be)
        //buff.selfTest();                       // DEBUG test to make sure the buffer's actually there
        buff.endDraw();                        //finish drawing buffer
        
        graph.image(buff.graph, buffX2+getX()-buffX, buffY2+getY()-buffY); //display the buffer in the correct location (buffX2,buffY2 + pos of panel WRT graph)
        
        buff.useNt(); //put buffer out of use
      }
    }
  }
  
  public static Buffer loadBuffer(Mmio mmio, byte x, byte y) { //Loads smallest buffer of at least size 2^x x 2^y from mmio. If none are available, it makes one.
    
    boolean best = true; //whether the buffer we use is the smallest possible. If it is, we stamp this buffer once we use it. If not, we don't stamp it because even though we used it, we'd be better off using a smaller buffer
    
    for(int sum=x+y; sum<mmio.buffWid+mmio.buffHig; sum++) { //area = 2^indX * 2^indY = 2^(indX+indY), so we're doing this in ascending order of the sum of the two indices. Loop through all sums
      for(int indX=x; indX<mmio.buffWid; indX++) { //now, we loop through all buffer lists with that area AND which can support this buffer
        int indY = sum-indX;                                   //calculate y index
        if(indY>=mmio.buffHig || indY<y) { continue; }         //if out of bounds, or it can't support our buffer, skip this iteration
        for(Buffer buff2 : mmio.buffers.get(indX).get(indY)) { //loop through the list of buffers
          if(!buff2.isInUse()) { return buff2.setShouldStamp(best); } //the first one we find that isn't in use, that's the one we use (make it stamp only if it's the best)
        }
        best = false; //if the first option wasn't availalbe, then we're no longer using the best option
      }
    }
    //if we didn't find the buffer:
    return mmio.addBuffer(x,y).setShouldStamp(true); //add buffer of new size (make it so it stamps), return result
  }
  
  ////////////////////// UPDATES ///////////////////////////////
  
  
  public boolean updateButtons(Cursor curs, final byte code, boolean selected) { //looks through all visible buttons in a panel and updates accordingly (selected = whether the cursor has already selected something)
    for(Box b : reverse()) { //loop through all the boxes in the panel (in reverse order)
      if(b instanceof Panel) {                                     //if b is a panel: update it
        selected = ((Panel)b).updateButtons(curs, code, selected); //cast to a panel, update all inner buttons, update selected
      }
      else if(b instanceof Button) {                                   //if b is a button: update it
        selected |= ((Button)b).respondToChange(curs, code, selected); //cast to a button, respond to the change, update selected
      }
      else if(b instanceof Textbox.CaretMover) {
        selected |= ((Textbox.CaretMover)b).respondToChange(curs, code, selected); //cast to a caret mover, respond to the change, update selected
      }
      else if(b instanceof Textbox.TSHandle) {
        selected |= ((Textbox.TSHandle)b).respondToChange(curs, code, selected); //cast to a text selection handle, respond to the change, update selected
      }
    }
    return selected; //return whether something is already selected
  }
  
  //NOTE it is assumed when running this function that the cursor is already inside the panel's parent (or that it has no parent)
  public boolean updatePanelScroll(Cursor curs, int eventX, int eventY) { //PC only (return whether an update actually occurred)
    if(!hitboxNoCheck(curs)) { return false; } //if mouse is not in hitbox, skip (no check because this test was already performed on the parent)
    
    for(Box b : this) { //loop through all the boxes in the panel
      if(b instanceof Panel) {
        Panel p = (Panel)b; //cast to a panel
        p.updateButtons(curs, curs.press==0 ? (byte)3 : 2, false); //update buttons given the mouse moved (even though it didn't, the panel moved)
        if(p.updatePanelScroll(curs,eventX,eventY)) { return true; } //if an inner panel got an event, return true so we can immediately leave
      }
    }
    
    shiftSurface(canScrollX ? -eventX*pixPerClickH : 0,
                 canScrollY ? -eventY*pixPerClickV : 0); //move the surface
    
    return canScrollY && eventY!=0 || canScrollX && eventX!=0; //return whether we updated
  }
  
  public void updatePanelDrag() {
    updateDrag(); //update dragging mechanics TODO fix whatever the fuck happens when we drag one panel then drag a panel inside it
    
    for(Box b : this) { //loop through all the boxes in the panel
      if(b instanceof Panel) { ((Panel)b).updatePanelDrag(); } //for each panel, update their panel drags as well
    }
  }
  
  public void updatePhysicsRecursive(float delay) {
    updatePhysics(delay); //update physics
    
    for(Box b : this) { //loop through all boxes in the panel
      if(b instanceof Panel) { ((Panel)b).updatePhysicsRecursive(delay); } //for each panel, update their physics as well
    }
  }
  
  public void updateCaretsRecursive() {
    for(Box b : this) { //loop through all boxes in this panel
      if(b instanceof Panel) { ((Panel)b).updateCaretsRecursive(); } //for each panel, update their textboxes' physics as well
      if(b instanceof Textbox)  { ((Textbox)b).idlyUpdateCarets(); } //for each textbox, idly update their carets
    }
  }
  
  public void deselectAllButtons(Cursor curs) { //removes curs from the cursors list of all buttons in this panel and its children
    for(Box b : this) { //loop through all children
      if     (b instanceof  Panel) { ((Panel)b).deselectAllButtons(curs); } //panel: recursively do this on the inner panels
      else if(b instanceof Button) { ((Button)b).cursors.remove(curs);    } //button: remove from cursor list
    }
  }
  
  public void deselectMobileButtons(boolean mobile) { //does the same thing, but only deselects moving buttons, and also does it for all cursors (mobile = true if 1 or more parent panels are mobile)
    for(Box b : this) { //loop through all children
      if     (b instanceof Panel) { ((Panel)b).deselectMobileButtons(mobile || b.mobile); } //panel: recursively do this on inner panels, mobility becomes true the moment we enter a mobile panel
      else if(b instanceof Button && (mobile || b.mobile)) { ((Button)b).cursors.clear(); } //button: clear the cursor list, but only if the button is moving relative to the cursor
    }
  }
  
  public void targetAllChildren() { //performs moveToTarget on self and all children recursively
    moveToTarget(); //update targeting system
    for(Box b : this) { if(b instanceof Panel) { //loop through all Panel children
      ((Panel)b).targetAllChildren(); //instruct each of them to target themselves and all their children
    } }
  }
  
  public void updatePressCount(Button... buttons) { //resets every child/descendant button's press count to 0 (except the ones fed as parameters)
    for(Box b : this) { //loop through all children
      if     (b instanceof  Panel) { ((Panel)b).updatePressCount(buttons); } //if panel, update its children/descendants
      else if(b instanceof Button) { //if button:
        boolean isExcluded = false; //first, find whether this button should be ignored
        for(Button butt : buttons) { //loop through excluded buttons
          if(butt==b) { isExcluded=true; break; } //if any of them is the same as this button, set flag and escape loop
        }
        if(!isExcluded) { ((Button)b).pressCount = 0; } //if this button is not one of the exclusions, reset its press counter
      }
    }
  }
  
  ////////////////////// SWIPING FUNCTIONALITY ////////////////////
  
  public void press(final Cursor curs) { //responds to cursor press
    if(!hitbox(curs)) { return; } //if cursor not inside, exit TODO see if this is necessary AND see if you can use hitboxNoCheck
    
    if(pointers.size()==0) { //if this panel has no pointers:
      surfaceXi = surfaceX; surfaceYi = surfaceY; //set our initial surface position
    }
    else { //if this panel DOES have pointers:
      //TODO test this
      float meanX = 0, meanY = 0;         //calculate the difference between the previous mean-of-positions and the current mean-of-positions
      for(Cursor c : pointers) {          //loop through all current pointers
        meanX+=c.x-c.xi; meanY+=c.y-c.yi; //add them together
      }
      meanX-=(curs.x-curs.xi)*pointers.size(); meanY-=(curs.y-curs.yi)*pointers.size(); //this calculation has been optimized so we have to do one fewer division
      float inv = 1/(pointers.size()*(pointers.size()+1)); meanX*=inv; meanY*=inv;      //divide both mean differences by the denominator
      
      surfaceXi+=meanX; surfaceYi+=meanY; //add the adjustment
    }
    pointers.add(curs); //in any case, add this cursor to our list of pointers
    
    if(dragModeX!=DragMode.NONE && dragModeY!=DragMode.NONE) { curs.seLocked = true; } //if this panel can be dragged in both directions, lock select
  }
  
  public void release(final Cursor curs) { //responds to cursor release
    if(!pointers.contains(curs)) { return; } //if cursor is not in pointer list, exit TODO see if this is even remotely necessary
    
    if(pointers.size()!=1) { //if this isn't the only pointer:
      //TODO test this
      float meanX = 0, meanY = 0;         //calculate the difference between the previous mean-of-positions and the current mean-of-positions
      for(Cursor c : pointers) {          //loop through all current pointers
        meanX+=c.x-c.xi; meanY+=c.y-c.yi; //add them together
      }
      meanX-=(curs.x-curs.xi)*pointers.size(); meanY-=(curs.y-curs.yi)*pointers.size(); //this calculation has been optimized so we have to do one fewer division
      float inv = 1/(pointers.size()*(pointers.size()-1)); meanX*=inv; meanY*=inv;      //divide both mean differences by the denominator
      
      surfaceXi-=meanX; surfaceYi-=meanY; //subtract the adjustment
    } //otherwise, no adjustments are necessary
    
    pointers.remove(curs); //remove this cursor from our list of pointers
  }
  
  public void updateDrag() { //performs updates once per frames based on dragging functionality
    switch(dragModeX) { //what we do depends on the drag mode
      case NONE: break; //none: never do anything
      case NORMAL: case ANDROID: if(pointers.size()!=0) { //normal/android: only do something if there are pointers
        float mean = 0;                              //first, we compute the mean of all the cursors' positions that are pointed at us (minus their initial positions)
        for(Cursor c : pointers) { mean+=c.x-c.xi; } //add them all up
        mean/=pointers.size();                       //divide by how many there are
        surfaceX = constrain(surfaceXi+mean,w-surfaceW,0); //move the surface to its initial position plus that shift
      } break;
      case IOS: {
        //TODO this
      } break;
      case SWIPE: {
        //TODO this
      } break;
    }
    
    switch(dragModeY) { //what we do depends on the drag mode
      case NONE: break; //none: never do anything
      case NORMAL: case ANDROID: if(pointers.size()!=0) { //normal/android: only do something if there are pointers
        float mean = 0;                              //first, we compute the mean of all the cursors' positions that are pointed at us (minus their initial positions)
        for(Cursor c : pointers) { mean+=c.y-c.yi; } //add them all up
        mean /= pointers.size();                     //divide by how many there are
        surfaceY = constrain(surfaceYi+mean,h-surfaceH,0); //move the surface to its initial position plus that shift
      } break;
      case IOS: {
        //TODO this
      } break;
      case SWIPE: {
        //TODO this
      } break;
    }
  }
  
  public void updatePhysics(float delay) { //updates the physics (delay = how long it's been since the previous frame, in seconds)
    if(pointers.size()!=0) { //if at least one pointer is selecting this panel:
      surfaceVx = surfaceVy = 0; //set velocity to 0
      for(Cursor c : pointers) { surfaceVx += c.x - c.dx; surfaceVy += c.y - c.dy; } //take the sum of the changes in each cursor
      surfaceVx /= delay*pointers.size(); surfaceVy /= delay*pointers.size(); //divide each sum by the change in time * the number of cursors, that's our velocity
    }
    else if(sliding) {
      surfaceX = constrain(surfaceX+delay*surfaceVx, w-surfaceW, 0);
      surfaceY = constrain(surfaceY+delay*surfaceVy, h-surfaceH, 0);
    }
    else { //if no pointers are selecting this panel, we use free form physics to move the panel (unless it's undraggable)
      switch(dragModeX) { //what we do depends on drag mode
        case NONE: case NORMAL: break; //none/normal: do nothing (normal means we only move when selected)
        case ANDROID: if(surfaceVx!=0) { //android: if the velocity isn't 0
          float exp = exp(-airFric*delay);
          surfaceX += -(exp-1)*surfaceVx/airFric;
          surfaceVx *= exp;
          
          if(abs(surfaceVx) < minVel) { //once the velocity gets too low:
            surfaceVx = 0;              //set velocity to 0
          }
          
          if(surfaceX>0 || surfaceX<w-surfaceW) { //if out of bounds:
            surfaceX = constrain(surfaceX, w-surfaceW, 0); //constrain to in bounds
            surfaceVx = 0;                                 //set velocity to 0
          }
        } break;
      }
      switch(dragModeY) { //what we do depends on drag mode
        case NONE: case NORMAL: break; //none/normal: do nothing
        case ANDROID: if(surfaceVy!=0) { //android: if the velocity isn't 0
          float exp = exp(-airFric*delay);
          surfaceY += -(exp-1)*surfaceVy/airFric;
          surfaceVy *= exp;
          
          if(abs(surfaceVy) < minVel) { //once the velocity gets too low:
            surfaceVy = 0;              //set velocity to 0
          }
          
          if(surfaceY>0 || surfaceY<h-surfaceH) { //if out of bounds:
            surfaceY = constrain(surfaceY, h-surfaceH, 0); //constrain to in bounds
            surfaceVy = 0;                                 //set velocity to 0
          }
        } break;
      }
    }
  }
  
  /*
  Code for IOS (which uses kinetic friction):
  
  float exp = exp(-airFric*delay);
  int sgn = sgn(surfaceVx);
  surfaceX += -(exp-1)*(surfaceVx+kinFric*sgn)/airFric - kinFric*sgn*delay;
  surfaceVx = exp*(surfaceVx+kinFric*sgn)-kinFric*sgn;
  
  if(sgn != sgn(surfaceVx)) { //the moment the velocity switches signs:
    surfaceX += (surfaceVx-kinFric*sgn*log(1-abs(surfaceVx)/kinFric))/airFric; //move the surface to where it would be the moment velocity becomes 0
    surfaceVx = 0;                                                             //set velocity to 0
  }
  
  if(surfaceX>0 || surfaceX<w-surfaceW) { //if out of bounds:
    surfaceX = constrain(surfaceX, w-surfaceW, 0); //constrain to in bounds
    surfaceVx = 0;                                 //set velocity to 0
  }
  
  repeat for y
  */
  
  public void freezeV() { surfaceVx = surfaceVy = 0; } //freezes velocity (sets it to 0)
  
  ////////////////////// TARGETING ////////////////////////
  
  public void chooseTarget(float... focus) { //chooses a target, given that all inputted coordinates have to be in focus.
    if((focus.length&1)==1) { throw new IllegalArgumentException("Method chooseTarget cannot accept "+focus.length+" inputs (only even numbers are allowed)"); } //if the inputs aren't formatted correctly, throw a runtime exception
    
    float[] focX = new float[focus.length>>1], focY = new float[focus.length>>1]; //arrange our inputs into two arrays (x and y)
    for(int n=0;n<focX.length;n++) { focX[n]=focus[n<<1]; focY[n]=focus[n<<1|1]; } //fill the arrays with our inputs
    
    /*float lowX = w-surfaceW, highX=0, lowY = h-surfaceH, highY=0; //the lower & upper bounds for where we can target
    for(float f : focX) { //loop through all x values
      lowX  = max( lowX,   Mmio.xBuff-f); //lower bound must be the highest of all lower bounds
      highX = min(highX, w-Mmio.xBuff-f); //upper bound must be the lowest of all upper bounds
    }
    for(float f : focY) { //loop through all y values
      lowY  = max( lowY,   Mmio.yBuff-f); //lower bound must be the highest of all lower bounds
      highY = min(highY, h-Mmio.yBuff-f); //upper bound must be the lowest of all upper bounds
    }
    
    if(highX<lowX) { println("fuck", lowX, highX, surfaceX, constrain(surfaceX,lowX,highX)); } //DEBUG
    
    float xTarget = constrain(surfaceX,lowX,highX), yTarget = constrain(surfaceY,lowY,highY); //choose each target to be either the current position or whichever point is just barely in bounds and is closest to the current pos as possible
    */
    
    float[] targetX = new float[2*focX.length+3]; targetX[0]=surfaceX; targetX[1]=w-surfaceW; targetX[2]=0;
    for(int n=0;n<focX.length;n++) {
      targetX[2*n+3]=xSpace-focX[n]; targetX[2*n+4]=w-xSpace-focX[n];
    }
    float[] targetY = new float[2*focY.length+3]; targetY[0]=surfaceY; targetY[1]=h-surfaceH; targetY[2]=0;
    for(int n=0;n<focY.length;n++) {
      targetY[2*n+3]=ySpace-focY[n]; targetY[2*n+4]=h-ySpace-focY[n];
    }
    targetX = sort(targetX); targetY = sort(targetY);
    float xTarget = targetX[focX.length+1], yTarget = targetY[focY.length+1];
    
    
    setTarget(xTarget, yTarget); //finally, set the target
  }
  
  public void setTarget(float xTarget, float yTarget) { //sets the target
    for(Panel p = this; p!=null; p=p.parent) { //first, we have to loop through this panel and all its parents
      p.freezeV();                             //and freeze them
    }
    
    if(xTarget==surfaceX && yTarget==surfaceY) { target = null; } //if target is right where we are, target is null (no targeting)
    else if(target!=null && xTarget==target.x && yTarget==target.y) { return; } //if target is where it was before, don't change the target
    else {                                                        //otherwise:
      deselectMobileButtons(false); //deselect all child buttons that aren't staying perfectly still
      
      target = new SurfaceTarget(xTarget, yTarget, surfaceX, surfaceY); //set the target
    }
  }
  
  public void chooseTargetRecursive(float... focus) { //recursively chooses a target, both for this panel and its parent panels
    chooseTarget(focus);     //choose a target for this panel
    
    if(parent!=null && mobile) { //and, if we have a parent (and are mobile)
      PVector targ = (target==null) ? new PVector(surfaceX,surfaceY) : new PVector(target.x,target.y); //record the target, accounting for the possibility that there was no target
      
      float focus2[] = new float[focus.length];
      for(int n=0;n<focus.length;n++) { focus2[n]=focus[n] + ((n&1)==0 ? x+targ.x : y+targ.y); }
      parent.chooseTargetRecursive(focus2);
    }
  }
  
  public void moveToTarget() { //moves towards and updates target TODO enable non-recursive targeting (Because, let's say for instance, you update a shitload of boxes at once, and they can't all fit on screen. See the problem?)
    if(target==null) { return; } //if there is no target, skip
    
    long time = System.currentTimeMillis(); //calculate current time
    float progress = (time-target.time)/PApplet.parseFloat(SurfaceTarget.duration); //calculate targeting progress
    
    if(progress>=1) { //if the target time is worn up:
      if(pointers.size()!=0) { //if there are any cursors dragging this panel, we need to shift our initial position:
        if(dragModeX==DragMode.NORMAL || dragModeX==DragMode.ANDROID) { //if we're in normal or android mode, here's how we calculate the initial position:
          //compute where the surface would be if it wasn't constrained by the walls
          float mean=0;                                //first, we compute the mean of all the cursors' positions that are pointed at us (minus their initial positions)
          for(Cursor c : pointers) { mean+=c.x-c.xi; } //add them all up
          mean/=pointers.size();                       //divide by how many there are
          surfaceXi = target.x-mean;                   //now, instead of starting at xi, and having been shifted by mean, it started at target-mean, and was shifted by mean
        }
        if(dragModeY==DragMode.NORMAL || dragModeX==DragMode.ANDROID) { //likewise, we do the same thing in the y direction, but only if appropriate
          float mean=0;
          for(Cursor c : pointers) { mean+=c.y-c.yi; }
          mean/=pointers.size();
          surfaceYi = target.y-mean;
        }
      }
      setScroll(target.x,target.y); //move to the target
      target = null;                //remove the target
    }
    else {
      setScroll(lerp(target.xi,target.x,progress), lerp(target.yi,target.y,progress)); //otherwise, calculate current position w/ a lerp
    }
  }
  
  ////////////////////// CHILDREN /////////////////////////
  
  public void putInBack(Box a) { //puts box in the back
    if(this==a.parent) { children.remove(a); children.add(0,a); } //if this is a's parent, remove a and put it in the back
  }
  
  public void putInFront(Box a) { //puts box in the front
    if(this==a.parent) { children.remove(a); children.add(a); } //if this is a's parent, remove a and put it in the front
  }
  
  public void putAOverB(Box a, Box b) { //puts the first in front of the second
    if(this!=a.parent || this!=b.parent || a==b) { return; }    //only works if they're both distinct children
    int indA = children.indexOf(a), indB = children.indexOf(b); //get indices of a and b
    if(indA < indB) { //if a was already in front of b, do nothing. Otherwise:
      children.remove(indA); children.add(indB,a); //remove a, then put it back in front of b (right where b was before)
    }
  }
  
  public void putABehindB(Box a, Box b) { //puts the first behind the second
    if(this!=a.parent || this!=b.parent || a==b) { return; }    //only works if they're both distinct children
    int indA = children.indexOf(a), indB = children.indexOf(b); //get indices of a and b
    if(indA > indB) { //if a was already behind b, do nothing. Otherwise:
      children.remove(indA); children.add(indB,a); //remove a, then put it back behind b (right where b is now)
    }
  }
  
  public void swapAAndB(Box a, Box b) { //swaps both boxes in positions
    if(this!=a.parent || this!=b.parent || a==b) { return; }    //only works if they're both distinct children
    int indA = children.indexOf(a), indB = children.indexOf(b); //get indices of a and b
    children.set(indA,b); children.set(indB,a);                 //move a into b and b into a
  }
  
  public void moveToIndex(Box a, int ind) { //moves child box to specific position
    if(this!=a.parent || ind<0 || ind>=numChildren()) { return; } //only works if it's this panel's child and index is in bounds
    children.remove(a); children.add(ind,a); //remove child, insert it at index
  }
  
  ////////////////////// OTHER //////////////////////
  
  //NOTE: only use if cursor is in the parent's hitbox, or if there is no parent
  protected Box getCursorSelect(Cursor curs) { //searches through a panel and returns which object this cursor is hovering over
    if(!hitboxNoCheck(curs)) { return null; }  //if cursor is not in hitbox, skip
    if(surfaceVx!=0 && dragModeX!=DragMode.NONE || surfaceVy!=0 && dragModeY!=DragMode.NONE) { return this; } //if this panel is moving, we automatically have to select it (it takes precedence)
    
    for(Box b : reverse()) {   //loop through all the boxes in the panel
      if(b instanceof Panel) { //if b is a panel:
        Box b2 = ((Panel)b).getCursorSelect(curs); //perform this recursively on said panel
        if(b2!=null) { return b2; }                //if b2 isn't null, return it TODO make sure this works with overlapping boxes. I'm pretty sure it does
      }
      else if(b.hitboxNoCheck(curs)) { return b; } //if b isn't a panel, return b iff the cursor is in it's hitbox (nocheck = don't check parent's hitbox, it's redundant)
    }
    
    return this; //if we're in it's hitbox, but not the hitboxes of any of its children, return this panel
  }
  
  public Iterator<Box> iterator() { //to iterate across the panel, just iterate across its children
    return children.iterator();
  }
  
  public Iterable<Box> reverse() { return new Iterable<Box>() { //returns something you can use to iterate over the children in reverse order
    public Iterator<Box> iterator() { return new Iterator<Box>() { //the iterator returns an iterator
      int index = numChildren();                    //initial index is right after the last index
      public boolean hasNext() { return index!=0; } //has next: true if index isn't 0
      public Box next() { index--; return children.get(index); } //next: decrement index and return box at this spot
    }; }
  }; }
  
  public void initPixPerClick() { pixPerClickH = w*0.025f; pixPerClickV = h*0.025f; } //generally, we can init scroll rate as a fraction of the window width/height
}

static class SurfaceTarget { //a class dedicated to the targeting system for targets, implemented to prevent panels from going out of bounds when they change in size and to force us to see important things
  float x, y;   //x and y coordinate of the surface once it reaches its target
  float xi, yi; //x and y coordinates initially, before we started targeting
  long time;    //the UNIX time in ms when the targeting first began. This is here because targeting isn't a sudden jolt, it has to occur over several frames
  static int duration = 120; //the time in ms for the surface to reach its target (same for all targets)
  
  SurfaceTarget(float x2, float y2, float x3, float y3, long time2) { x=x2; y=y2; xi=x3; yi=y3; time=time2; } //constructor w/ all attributes
  
  SurfaceTarget(float x2, float y2, float x3, float y3) { x=x2; y=y2; xi=x3; yi=y3; time=System.currentTimeMillis(); } //constructor w/ xs & ys, and w/ time set to current time
  
  public @Override
  String toString() { return "Target: ("+xi+","+yi+")->("+x+","+y+") from UNIX time "+time; }
}

public static byte outCode(float xin, float yin, float win, float hin, float wout, float hout) { //yields a 5-bit outcode describing how two boxes intersect, assuming (xout,yout)=(0,0)
  return (byte)((xin>wout || yin>hout || xin+win<0 || yin+hin<0 ? 16 : 0) | //bit 1: whether box is completely out of bounds
                                                      (xin<   0 ?  8 : 0) | //bit 2: whether left edge is left of clipping plane
                                                      (xin+win>wout ?  4 : 0) | //bit 3: whether right edge is right of clipping plane
                                                      (yin<   0 ?  2 : 0) | //bit 4: whether top edge is above clipping plane
                                                      (yin+hin>hout ?  1 : 0)); //bit 5: whether bottom edge is below clipping plane
}

static enum DragMode { NONE, NORMAL, ANDROID, IOS, SWIPE };

public static int sgn(float x) { return x==0 ? 0 : x>0 ? 1 : -1; }
//the modes that you can use to drag with your cursor: no dragging, normal (no momentum), android style, iOS style, and swipe between screens (like on a home screen)

///movement modes: PC, Android, iOS, basicSmartphone
public static class ParseList implements Iterable<String> { //a class specifically for taking a list of chars, reorganizing them for parsing reasons, then being converted to an equation
  public ArrayList<String> list = new ArrayList<String>(); //storage of all the strings that'll be parsed into an expression
  
  public ParseList(String inp) { //splits up all the chars and creates a new ParseList
    char[] arr = inp.toCharArray();       //split string into char array
    list.add("(");                        //add a left parenthesis at the beginning
    for(char c : arr) { list.add(c+""); } //cast each char to a string and add to list
    list.add(")");                        //add a right parenthesis at the end
  }
  
  @Override
  public Iterator<String> iterator() {
    return list.iterator();
  }
  
  public String get(int ind) { return list.get(ind); }
  public int size() { return list.size(); }
  
  public void concat(int ind, String str) {
    list.set(ind,list.get(ind)+str);
  }
  
  @Override
  public String toString() {
    String ret = "";
    for(String s : this) { ret+=s+", "; }
    return ret;
  }
  
  public void groupFuncs() { //group together functions
    ArrayList<Integer> parPos = leftParPosList(); //get a list of the positions of all left parentheses
    
    for(String match : functionDictionary.lookup) { //loop through all strings in the list of function names (big to small)
      for(int k=0;k<parPos.size();k++) {    //loop through all left parentheses
        int pos = parPos.get(k);            //record the position in the list
        
        int startPos = pos-match.length()+1; //find the position of the start of the match
        if(startPos>=0) {                    //first make sure it's non-negative
          boolean matches = matchFound(startPos, match); //see if this string is right before this parenthesis
          
          if(matches) { //if it WAS a match
            groupStringOfSize(startPos,match.length()); //group together strings over that range into one string
            
            parPos.remove(k); //remove this parenthesis position
            for(int n=k;n<parPos.size();n++) {
              parPos.set(n,parPos.get(n)-match.length()+1); //shift each position to the right of this left by pos
            }
            k--; //go back 1 step
          }
        }
      }
    }
  }
  
  public void groupVars() { //group together variable names that are multiple characters long
    for(String match : Equation.varList) { //loop through all strings in the list of variable names (big to small)
      for(int k=0;k<=size()-match.length();k++) { //loop through all the strings (exclude parts at the end where this string doesn't fit)
        boolean matches = matchFound(k, match); //see if this string is a match
        
        if(matches) { //if it WAS a match
          groupStringOfSize(k,match.length()); //group together strings over that range into one string
        }
      }
    }
  }
  
  public void groupDates() { //group together dates
    for(String m : Month.matchers) { //loop through all the month strings
      for(int i=0;i<size()-m.length();i++) { //loop through all indices which could possibly contain that month
        if(matchFound(i,m)) { //if this string was found at this position, we now have to look to see if there's a number after it
          int len = m.length(); //record the current length of the string we're grouping together
          String after = get(i+m.length()); if(after.length()==1 && after.charAt(0)>='0' && after.charAt(0)<='9') { len++; } else { continue; } //make sure the next thing is a number. If not, we ignore this
          int ind = i+m.length()+1; //grab the index after that
          if(ind<size()) { //if there's even more after that:
            after = get(ind); if(after.length()==1 && after.charAt(0)>='0' && after.charAt(0)<='9') { len++; ind++; } //see if the next character is also a number. if so, add it to the list
            if(ind+2<size()) { if(get(ind).equals(",") && get(ind+1).equals(" ") && (get(ind+2).equals("-") || get(ind+2).length()==1 && get(ind+2).charAt(0)>='0' && get(ind+2).charAt(0)<='9')) { //next, see if the next 3 characters are comma, space, and a number
              ind+=3; len+=3; //increment the length & index by 3
              while(ind<size() && get(ind).length()==1 && get(ind).charAt(0)>='0' && get(ind).charAt(0)<='9') { ind++; len++; } //repeatedly increment until we run out of numerals or out of characters
            } }
          }
          groupStringOfSize(i,len); //group together the string forming our date
        }
      }
    }
  }
  
  public boolean matchFound(int pos, String match) { //match found for match at pos
    boolean matches = true;             //whether or not this is a match (default to true)
    for(int n=0;n<match.length();n++) { //loop through all strings between
      if(!(match.charAt(n)+"").equals(list.get(n+pos))) { matches=false; break; } //if any of them don't match, matches is false, leave
    }
    return matches; //return whether they match
  }
  
  public void groupStringOfSize(int pos, int siz) { //take a group of siz strings at position pos and group them together
    for(int n=1;n<siz;n++) {         //loop through all strings in that set
      concat(pos,list.get(pos+1)); //concat them onto the first string on the set
      list.remove(pos+1);          //remove each element after they're concatted
    }
  }
  
  public ArrayList<Integer> leftParPosList() { //get a list of the positions of all left parentheses
    ArrayList<Integer> parPos = new ArrayList<Integer>(); //arraylist of the positions of each left parenthesis
    for(int n=0;n<size();n++) {
      if(list.get(n).equals("(")) { parPos.add(n); } //add each index containing a left parenthesis
    }
    return parPos; //return result
  }
  
  public void groupNums() { //group together numeric values
    boolean numb = false; //whether we're building a number
    boolean deci = false; //whether our number has a decimal point (yet)
    boolean expon = false; //whether our number has an exponential E (yet)
    
    for(int n=0;n<list.size();n++) {    //loop through all strings in the list
      if(list.get(n).length()==1) {   //if this string is 1 character long:
        char c = list.get(n).charAt(0); //cast to a char
        if (c >= '0' && c <= '9' || c == '.' || c == 'E') { //if the string is a numeral, decimal pont, or E
          if (numb && !(c == '.' && (deci || expon) || c == 'E' && expon)) { //case 1: we were already combining tokens into a number (and this makes a valid addition to said #)
            concat(n-1,c+"");                      //add this character to the number
            list.remove(n); --n;                   //remove this entry from the list, then go backwards 1
          }
          else {                    //case 2: we need to form a new number from these digits
            numb = true;          //we're now building a number
            deci = expon = false; //both deci & expon are initially false
            if (c == '.' || c == 'E') {
              list.set(n, '0' + list.get(n));
            } //if it's a . or E, put a 0 before it to properly start the number
          }
          //(programmer's note: if someone creates a number with 2 decimal points or E's or whatever, it'll be interpreted as 2 numbers adjacent to each other)
          
          deci  |= c == '.'; //deci is true if we've had at least one decimal point
          expon |= c == 'E';
        } else if ((c == '+' || c == '-') && numb && list.get(n-1).endsWith("E")) { //if this is a + or -, and the previous character was E:
          concat(n-1,c+"0");   //concatenate this symbol onto the number, followed by a 0 in case we stop at this point
          list.remove(n); --n; //remove this entry from the list & go backwards 1
        }
        else {                  //otherwise:
          if(numb && list.get(n-1).endsWith("E")) { //if the previous thing ended with E,
            concat(n-1,"0");                    //concatenate a 0 at the end to make it valid
          }
          numb = false;                           //we're no longer editing numbers
        }
      }
      else if(numb) { //if it's not 1 character long, but we were in number building mode
        if(list.get(n-1).endsWith("E")) { concat(n-1,"0"); } //if it ended with E, put a 0 at the end to make it valid
        numb = false;                                        //we're no longer in number building mode
      }
    }
  }
  
  public void removeSpaces() { //removes all tokens that are just whitespace
    for(int n=0;n<size();n++) {
      if(list.get(n).equals(" ")) { list.remove(n); n--; }
    }
  }
  
  public void groupPlusMinus() { //group together adjacent plus and minuses
    boolean plusMinus = false; //whether we're grouping them together now
    for(int n=0;n<size();n++) { //loop through all items
      if(list.get(n).equals("+") || list.get(n).equals("-")) { //if this item is + or -
        if(plusMinus) {     //if the previous was +/-
          list.set(n-1, (list.get(n-1).equals("+") ^ list.get(n).equals("+")) ? "-" : "+"); //set the previous to either + or -
          list.remove(n); //remove this entry
          n--;            //go backwards 1
        }
        plusMinus = true; //set plusMinus to true
      }
      else { plusMinus = false; } //otherwise, set plusMinus
    }
  }
  
  public void groupOps() { //group together operators when applicable (**=^, //=truncated division)
    boolean times=false, div=false, and=false, or=false, greater=false, less=false, not=false, equals=false; //whether we're grouping *, /, &, |, >, <, !, =
    for(int n=0;n<size();n++) { //loop through all items
      if(list.get(n).equals("*")) { //if this item is *
        if(times) { //if the previous was also *
          list.set(n-1, "^"); //set the previous to a ^
          list.remove(n);     //remove this entry
          n--;                //go backwards 1
        }
        times^=true; //invert times
      }
      else { times=false; } //otherwise, set times to false
      
      if(list.get(n).equals("/")) { //if this item is /
        if(div) { //if the previous was also /
          list.set(n-1, "//"); //set the previous to a //
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        div^=true; //invert div
      }
      else { div=false; } //otherwise, set div to false
      
      if(list.get(n).equals("&")) { //if this item is &
        if(and) { //if the previous was also &
          list.set(n-1, "&&"); //set the previous to an &&
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        and^=true; //invert and
      }
      else { and=false; } //otherwise, set and to false
      
      if(list.get(n).equals("|")) { //if this item is |
        if(or) { //if the previous was also |
          list.set(n-1, "||"); //set the previous to an ||
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        or^=true; //invert and
      }
      else { or=false; } //otherwise, set or to false
      
      if(list.get(n).equals("=")) { //if this item is =
        if(greater) { //if the previous was >:
          list.set(n-1, ">="); //set the previous to >=
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        else if(less) { //if the previous was <:
          list.set(n-1, "<="); //set the previous to <=
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        else if(not) { //if the previous was !:
          list.set(n-1, "!="); //set the previous to !=
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        else if(equals) { //if the previous was =:
          list.set(n-1,"=="); //set the previous to ==
          list.remove(n);     //remove this entry
          n--;                //go backwards 1
        }
        equals^=true;
      }
      else { equals=false; } //otherwise, set equals to false
      
      greater = list.get(n).equals(">"); //set greater to true iff this is >
      less    = list.get(n).equals("<"); //set less to true iff this is <
      not     = list.get(n).equals("!"); //set not to true iff this is !
    }
  }
  
  public void format() { //formats the parselist appropriately
    groupFuncs();     //group together functions
    groupVars();      //group together multi-character variables
    groupDates();     //group together all dates
    groupNums();      //group together numerals
    groupOps ();      //group together combinable operators
    removeSpaces();   //remove all unecessary whitespace
    groupPlusMinus(); //clump together plus and minuses
  }
}
/*import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.Context;
import android.app.Activity;
import android.os.Looper;

import android.content.SharedPreferences;*/

/////////////////////////////////////// SAVING/LOADING HISTORY TO/FROM DISK ///////////////////////////////////////////

public void saveQuestionToDisk(int index, Textbox question, String path) { //saves question to disk
  PrintWriter writer = createWriter(path+dirChar+"question "+index+".txt");
  writer.println(question.getText());
  writer.flush(); writer.close();
}

public void saveAnswerToDisk(int index, Textbox answer, String path) { //saves answer to disk
  PrintWriter writer = createWriter(path+dirChar+"answer "+index+".txt");
  writer.println(answer.getText());
  writer.flush(); writer.close();
}

public void saveAnswerExactToDisk(int index, MathObj answer, String path) { //saves exact answer to disk
  PrintWriter writer = createWriter(path+dirChar+"answer exact "+index+".txt");
  writer.println(answer.saveAsString());
  writer.flush(); writer.close();
}

public void saveBaseSettingsToDisk(CalcHistory history, String path) {
  PrintWriter writer = createWriter(path+dirChar+"base settings.txt");
  writer.println(hex(history.entries));
  writer.println(hex(history.carousel));
  writer.flush(); writer.close();
}


public void loadQuestionFromDisk(int index, Textbox question, String path) {
  BufferedReader reader = createReader(path+dirChar+"question "+index+".txt");
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { line = null; ex.printStackTrace(); }
  question.replace(line); //put that line into the question field
  try { reader.close(); } catch(IOException ex) { ex.printStackTrace(); }
}

public void loadAnswerFromDisk(int index, Textbox answer, String path) {
  BufferedReader reader = createReader(path+dirChar+"answer "+index+".txt");
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { line = null; ex.printStackTrace(); }
  setAnswerContents(answer, line); //put the contents of that answer into the answer field
  try { reader.close(); } catch(IOException ex) { ex.printStackTrace(); }
}

public MathObj loadAnswerExactFromDisk(int index, String path) {
  BufferedReader reader = createReader(path+dirChar+"answer exact "+index+".txt");
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { line = null; ex.printStackTrace(); }
  MathObj answerExact = MathObj.loadFromString(line); //put the contents of that answer into this answer
  try { reader.close(); } catch(IOException ex) { ex.printStackTrace(); }
  return answerExact;
}

public void loadBaseSettingsFromDisk(CalcHistory history, String path) {
  BufferedReader reader = createReader(path+dirChar+"base settings.txt"); //load the file where all the base settings are listed
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { ex.printStackTrace(); line = null; } history. entries = unhex(line); //set the number of questions & answers
  try { line = reader.readLine(); } catch(IOException ex) { ex.printStackTrace(); line = null; } history.carousel = unhex(line); //set the carousel index
  try {        reader.close();    } catch(IOException ex) { ex.printStackTrace(); } //close the reader
}






public static void saveEquationsToDisk(PApplet app, boolean dim) {
  PrintWriter writer = app.createWriter("saves"+dirChar+(dim?"3":"2")+"D Equations.txt"); //open the file we have to write to
  ArrayList<EquatList.EquatField> equats = equatList.getEquats(dim); //load the equation list we have to save
  writer.println(equats.size()); //print the number of equations
  for(EquatList.EquatField eq : equats) { //loop through all equations
    writer.println(hex(eq.plot.stroke)); //print their stroke,
    writer.println(eq.plot.visible);     //their visibility,
    writer.println(eq.plot.mode);        //their graphing mode,
    writer.println(eq.cancel);           //and their text
  }
  writer.flush(); writer.close(); //flush and close the stream
}

public void loadEquations() { loadEquations(false); loadEquations(true); }

public void loadEquations(boolean dim) {
  BufferedReader reader = createReader("saves"+dirChar+(dim?"3":"2")+"D Equations.txt");
  int size;
  try { size = PApplet.parseInt(reader.readLine()); }
  catch(IOException ex) { ex.printStackTrace(); return; }
  
  for(int n=0;n<size;n++) {
    String line1, line2, line3;
    try { line1=reader.readLine(); line2=reader.readLine(); line3=reader.readLine(); }
    catch(IOException ex) { line1=line2=line3=null; ex.printStackTrace(); }
    
    int stroke = unhex(line1); boolean vis = line2.equals("true"); GraphMode mode = GraphMode.valueOf(line3); //grab the first 3 attributes: stroke color, visibility, and graphing mode
    
    String text;
    try { text=reader.readLine(); }
    catch(IOException ex) { text=null; ex.printStackTrace(); }
    
    equatList.addEquation(dim,n, stroke,vis,mode,text);
  }
  try { reader.close(); }
  catch(IOException ex) { ex.printStackTrace(); }
}




///////////////////////////////////////// CLIPBOARD STUFF ///////////////////////////////////

/////// FOR PC ////////////////////////

//This next set of code is dumped from:
//https://forum.processing.org/two/discussion/8950/pasted-image-from-clipboard-is-black
//https://forum.processing.org/two/discussion/17270/why-this-getx-method-is-missing-in-processing-3-1-1

public static Object getFromClipboard(DataFlavor flavor) { //extracts all items of flavor "flavor" from the clipboard, and returns them as an abstract object
  Clipboard clipboard=Toolkit.getDefaultToolkit().getSystemClipboard(); //create an instance of the "Clipboard" class with the contents of the clipboard
  Transferable contents=clipboard.getContents(null);                    //get them onto a "Transferable" object
  Object object=null;                                                   //create an object to dump the contents onto
  
  if(contents!=null && contents.isDataFlavorSupported(flavor)) { //if the contents aren't null, and this data flavor is supported:
    try { object = contents.getTransferData(flavor); } //try getting transferable data
    catch(UnsupportedFlavorException e1) { }           //requested data flavor not supported (unlikely but still possible)
    catch(java.io.IOException e2) { }                  //data no longer available in the requested flavor
  }
  return object; //return the object
}

public static String getTextFromClipboard(){ //this extracts string data from the clipboard (if applicable)
  String text=(String)getFromClipboard(DataFlavor.stringFlavor); //get string flavored data and cast to a string
  return text;                                                   //return the text
}

//And this set is dumped from:
//https://stackoverflow.com/questions/11596368/set-clipboard-contents

public static void copyToClipboard(String text) {
  StringSelection selection = new StringSelection(text);
  Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
  clipboard.setContents(selection, selection);
}





/*String printSupportedDataFlavors() {
  DataFlavor[] avail=Toolkit.getDefaultToolkit().getSystemClipboard().getAvailableDataFlavors();
  StringList formats=new StringList();
  for(DataFlavor f : avail) {
    String edit=f+"";
    edit=edit.substring(edit.indexOf(";")+1);
    edit=edit.substring(0,edit.length()-1);
    if(edit.indexOf(";")!=-1) { edit=edit.substring(0,edit.indexOf(";")); }
    edit=edit.substring("representationclass=".length());
    while(edit.indexOf(".")!=-1) { edit=edit.substring(edit.indexOf(".")+1); }
    
    boolean add = true;
    for(String s : formats) {
      if(edit.equals(s)) { add=false; break; }
    }
    if(add) { formats.append(edit); }
  }
  
  String ret="";
  for(String s : formats) {
    if(!s.equals(formats.get(0))) { ret+=", "; }
    ret+=s;
  }
  return ret;
}*/

public static char directoryCharacter() {
  return System.getProperty("os.name").contains("Windows") ? '\\' : '/';
}
public static class Textbox extends Panel {
  
  ////////////////////// ATTRIBUTES /////////////////////////
  
  //text
  float tx, ty; //x & y of text's top left WRT surface
  float tSize; int tFill; //text size & color
  ArrayList<SimpleText> texts = new ArrayList<SimpleText>(); //the texts themselves
  CaretMover buddy; //invisible box to allow for mouse-based/touch-based text caret placement
  Action releaseAction = emptyAction; //the action that gets performed when you press the buddy
  
  //caret
  int caret = 0;    //the position of the blinking caret
  int cStroke;    //the color of the blinking caret
  float cThick = 1; //the stroke weight of the caret
  long blink;       //the time when the blinking caret was last reset
  boolean insert=true; //true=insert, false=overtype. Inverts every time we hit the "insert" key
  
  //selection
  boolean highlighting = false; //whether we're currently highlighting text
  int anchorCaret = 0; //the position of the other end of the caret, encompassing the selected, highlighted area
  int selectColor = 0xff0000FF; //the color of the highlighted background (blue by default)
  int handleColor = 0xff0000FF; //the color of the text selection handles on mobile (blue by default)
  float leftHighlightBarrier, rightHighlightBarrier; //the "highlight barriers": if you drag your cursor past these barriers while highlighting, it causes the textbox to scroll in that direction
  float highlightDragSpeed = 30; //the speed at which the textbox scrolls on by when your cursor is past said barriers
  
  float handleRad;                  //radius of text handles
  static float defaultHandleRadius; //default handle radius
  Cursor dragCursor = null; //the cursor that is currently dragging the highlighted text selection (if any)
  
  enum HighlightMode { PC, MOBILE, NONE };
  HighlightMode hMode = pcOrMobile ? HighlightMode.PC : HighlightMode.MOBILE;
  SelectMenu selectMenu = null;
  boolean correctHandlesLater = false; //used to correct the handles later, particularly if correcting them now would cause concurrency issues
  
  Panel handleParent = null; //the panel that our text handles will go directly inside of
  
  ///////////////////// CONSTRUCTORS ///////////////////////
  
  Textbox(final float x2, final float y2, final float w2, final float h2) {
    super(x2,y2,w2,h2); //just run the inherited method
    
    tx=Mmio.xBuff; ty=Mmio.yBuff; //then initialize some stuff to their default values
    tSize = Mmio.invTextHeight(h2-2*Mmio.yBuff); //choose a text size with the appropriate height
    
    buddy = new CaretMover(this); //initialize our caret buddy
    
    handleRad = defaultHandleRadius; //set handle radius
    leftHighlightBarrier = 0.1f*w; rightHighlightBarrier = 0.9f*w;
  }
  
  ////////////////// GETTERS / SETTERS //////////////////////
  
  public float getTextHeight() { return tSize*1.164f+0.902f; }
  
  public Textbox setTextX(float x2) {
    tx=x2; xSpace=min(xSpace,tx); fixWidth();
    if(size()!=0) { texts.get(0).x = tx; for(int n=1;n<size();n++) { texts.get(n).x = texts.get(n-1).x+texts.get(n-1).w; } }
    return this;
  }
  public Textbox setTextY(float y2) { ty=y2; ySpace=min(ySpace,ty); return this; }
  public Textbox setTextPos(float x2, float y2) { tx=x2; ty=y2; xSpace=min(xSpace,tx); ySpace=min(ySpace,ty); fixWidth(); return this; }
  public Textbox setTextYAndAdjust(float y2) { ty=y2; ySpace=min(ySpace,ty); tSize=Mmio.invTextHeight(h-2*ty); fixWidth(); return this; }
  public Textbox setTextPosAndAdjust(float x2, float y2) { tx=x2; ty=y2; xSpace=min(xSpace,tx); ySpace=min(ySpace,ty); tSize=Mmio.invTextHeight(h-2*ty); fixWidth(); return this; }
  
  public Textbox setTextColor (int   c) { tFill  =c;  return this; }
  public Textbox setCaretColor(int   c) { cStroke=c;  return this; }
  public Textbox setCaretThick(float wgt) { cThick=wgt; return this; }
  public Textbox setTextSize  (float siz) { tSize=siz;  return this; }
  public Textbox setTextSizeAndAdjust(float siz) { tSize=siz; ty=0.5f*(h-Mmio.getTextHeight(siz)); ySpace=min(ySpace,ty); return this; }
  
  public int getLeftCaret () { return min(caret, anchorCaret); }
  public int getRightCaret() { return max(caret, anchorCaret); }
  
  public Textbox setMargin(float x) { //sets the margin between the text & the left & right (AKA the xSpace)
    xSpace = x;       //set the x space
    setTextX(xSpace); //change the text x
    adjust();         //adjust it
    return this;      //return result
  }
  
  public @Override
  Textbox setW(final float w2) { super.setW(w2); buddy.setW(w2); return this; } //when resizing width, the buddy must be resized as well
  
  public @Override
  Textbox setParent(final Panel p) { super.setParent(p); buddy.mmio=mmio; return this; } //set parent is done differently here because we also have to give our buddy the same mmio as ourselves
  
  public Textbox setOnRelease(final Action act) { releaseAction = act; return this; } //sets the release action
  
  public void setDoubleTapTimeout(int timeout) { buddy.doubleTapTimeout = timeout; } //sets how long we wait before the double tap is done
  public void setHighlightGrabDistance(float dist) { buddy.highlightGrabDistance = dist; } //set how far the mouse cursor can be from the caret in order to move it while text is highlighted
  
  public void setHighlightMode(HighlightMode m) { hMode = m; } //sets how highlighting occurs
  
  public void setHandleParent(Panel p) { //sets the panel our text handles go directly inside of
    if(!Mmio.isAncestorTo(p, this)) { //if this textbox isn't inside of p
      throw new RuntimeException("Cannot assign textbox's handle parent to a cousin or child panel"); //throw an exception
    }
    handleParent = p; //set our handle parent to p
  }
  
  ////////////////// DISPLAY //////////////////////
  
  public @Override
  void extraDisplay(PGraphics graph, float buffX, float buffY) { //displays the text in the textbox
    
    if(highlighting) {
      drawHighlight(graph, buffX, buffY); //if applicable, draw the rectangle where the text is highlighted
    }
    
    graph.fill(tFill); graph.textSize(tSize); graph.textAlign(LEFT,TOP); //set proper drawing parameters
    float yTop = ty+getY()+surfaceY-buffY; //y coord of top of text
    
    if(surfaceX==0 && w==surfaceW) { //if all the text fits on screen:
      for(SimpleText txt : texts) { //loop through all chars in the text
        graph.text(txt+"",txt.x+getX()+surfaceX-buffX,yTop); //display them TODO make sure this actually fucking works, delete me when you're done
      }
    }
    else { //otherwise, use a binary search to find them
      /*int left=0, right=size(); int middle = (left+right)>>1;
      while(true) {
        if(getX(middle)+surfaceX-tx>w) { right = middle-1; }
        else if(getX(middle)+surfaceX-tx<0) { left = middle+1; }
        else { break; }
        middle = (left+right)>>1;
      }
      //and now, left is left of the textbox, right is right of the textbox, and middle is inside the textbox
      int right2=right, left2=middle; //store the right and middle for when we calculate the right bound later
      
      //now, let's calculate the left bound
      right = middle; middle = (left+right)>>1; //shift
      while(left<=right && getX(middle)+surfaceX-tx!=0) { //loop until the bounds are reversed (or until we reach an exact match)
        if(getX(middle)+surfaceX-tx>0) { right = middle-1; } //too far right: make middle the right bound
        else { left = middle+1; }                                 //too far left: make middle the left bound
        middle = (left+right)>>1;                                 //set new middle
      }
      left = middle;
      
      //now, let's calculate the right bound
      middle = (left2+right2)>>1; //center
      while(left2<=right2 && getX(middle)+surfaceX-tx>0) { //loop until the bounds are reversed (or until we reach an exact match)
        if(getX(middle)+surfaceX-tx>0) { right2 = middle-1; } //too far right: make middle the right bound
        else { left2 = middle+1; }                                 //too far left: make middle the left bound
        middle = (left2+right2)>>1;                                //set new middle
      }
      right = middle;*/
      
      //TODO implement a binary search. 3, actually. One for a single index in the visible range, one for the left index, one for the right index
      
      int ind1=-2, ind2=-2;
      for(int i=0;i<=size();i++) {
        if(ind1==-2 && getX(i)+surfaceX>=0) { ind1=i-1; }
        if(ind1!=-2 && ind2==-2 && getX(i)+surfaceX>w) { ind2=i-1; }
      }
      if(ind1==-2) { return; } //temporary fix: if there's no text visible, then we just break out
      if(ind2==-2) { ind2=size(); }
      
      for(int i=ind1+1;i<ind2;i++) {
        graph.text(getText(i)+"",getX(i)+getX()+surfaceX-buffX,yTop); //display them TODO make sure this actually fucking works, delete me when you're done
      }
      
      if(ind1>=0) { //if there's clipped text on the left:
        //create an orphan box on the far left to display the clipped text
        Box special = new Box(getX(ind1)+surfaceX,ty+surfaceY,getW(ind1),getTextHeight()).setFill(0x00FFFFFF).setStroke(false).setText(new Text(getText(ind1)+"",0,0,tSize,tFill,LEFT,TOP));
        displayChild(special,graph,buffX,buffY); //use built-in display function to draw the clipped stuff
        //TODO make it so this can be done without calculating the outcodes. We already know what the outcodes are
      }
      
      if(ind2<size()) { //if there's clipped text on the right:
        //create an orphan box on the far right to display the clipped text
        Box special = new Box(getX(ind2)+surfaceX,ty+surfaceY,getW(ind2),getTextHeight()).setFill(0x00FFFFFF).setStroke(false).setText(new Text(getText(ind2)+"",0,0,tSize,tFill,LEFT,TOP));
        displayChild(special,graph,buffX,buffY); //use built-in display function to draw the clipped stuff
      }
    }
    
    if(this==mmio.typer && (System.currentTimeMillis()-blink & 512) == 0) { //if this is our selected textbox, and our caret is in the correct cycle of blinking:
      drawCaret(graph, buffX, buffY); //draw the caret
    }
  }
  
  public void drawCaret(PGraphics graph, float buffX, float buffY) {
    graph.stroke(cStroke); graph.strokeWeight(cThick); //set drawing parameters for caret
    float xStart = getX(caret)+surfaceX; //find x pos of caret
    if(xStart>=w) { return; } //if it's too far right, we can't draw it
    
    if(!insert) { //if overtype, we draw caret as underline
      float xEnd = (caret==size() ? getX(caret)+0.75f*tSize : getX(caret+1))+surfaceX; //find x pos of right of caret
      if(xEnd>0) { //if the caret is even on screen:
        graph.line(max(xStart,0)+getX()-buffX,ty+getY()+surfaceY+getTextHeight()-buffY, min(xEnd,w)+getX()-buffX,ty+getY()+surfaceY+getTextHeight()-buffY); //draw it, with x constraints for clipping
      }
    }
    else if(xStart>0) { //otherwise, we draw caret as vertical line (again, make sure it's on screen)
      graph.line(xStart+getX()-buffX, ty+getY()+surfaceY-buffY, xStart+getX()-buffX, ty+getY()+surfaceY+getTextHeight()-buffY);
    }
  }
  
  public void drawHighlight(PGraphics graph, float buffX, float buffY) { //draws the highlight rectangle behind the text
    graph.fill(selectColor);
    int leftInd = getLeftCaret(), rightInd = getRightCaret(); //find the left & right of the highlighted selection
    float xStart = getX(leftInd)+surfaceX, xEnd = getX(rightInd)+surfaceX; //find their x coordinates
    if(xStart<w && xEnd>0) { //make sure that at least part of the selection is on screen
      xStart = max(xStart,0)+getX()-buffX; //shift the starting x
      xEnd   = min(xEnd  ,w)+getX()-buffX; //shift the   ending x
      graph.rect(xStart,ty+getY()+surfaceY-buffY, xEnd-xStart,getTextHeight());
    }
  }
  
  /////////////// TYPING (FUNDAMENTAL) //////////////////////
  
  public int size() { return texts.size(); } //number of characters in the text
  
  public float getX(int ind) { //obtain the pixel x-coordinate of the given caret position, relative to surface
    if(size()==0 && ind==0) { return tx; }
    if(ind==size()) { SimpleText s = texts.get(ind-1); return s.x+s.w; }
    return texts.get(ind).x;
  }
  
  public float getW(int ind) { return texts.get(ind).w; } //obtain the pixel width of the character at the given position
  public char getText(int ind) { return texts.get(ind).text; } //obtain the character at the given position
  
  public String getText() { //obtains the contents of the text field as a plain string
    StringBuilder result = new StringBuilder();              //init to blank
    for(SimpleText txt : texts) { result.append(txt.text); } //concat each char
    return result.toString();                                //return result
  }
  
  public String substring(int start, int stop) { //obtains the contents as a substring
    StringBuilder result = new StringBuilder(); //init to blank
    for(int n=start;n<stop;n++) {
      result.append(texts.get(n).text);  //concat each char
    }
    return result.toString();            //return result
  }
  
  ///////TODO replace the above /|\ mechanism with a much more efficient stringbuilder mechanism
  
  public char charAt(int ind) { return texts.get(ind).text; } //obtain the character at the given position
  
  //Each of the following editing functions return the change in width of the text. It can be positive or negative.
  
  public float insert(char text, int pos) { //types (using insert) a character into a certain position
    float w = mmio.getTextWidth(text+"",tSize); //get width of character
    texts.add(pos, new SimpleText(text, getX(pos), w)); //insert the character
    for(int n=pos+1;n<size();n++) { //loop through all characters after this one
      texts.get(n).x += w;          //shift their positions appropriately
    }
    return w;
  }
  
  public float overtype(char text, int pos) { //types (using overtype) a character into a certain position
    float w = mmio.getTextWidth(text+"",tSize); //get width of character
    if(pos==size()) { texts.add(new SimpleText(text, getX(pos), w)); } //if typing at the end, add it to the arraylist as a new entry
    else {                                                             //otherwise:
      float w2 = getW(pos);                               // find the width of the character we're replacing
      texts.set(pos, new SimpleText(text, getX(pos), w)); // replace the character
      for(int n=pos+1;n<size();n++) { //loop through all characters after this one
        texts.get(n).x += w-w2;       //shift their positions appropriately
      }
      return w-w2; //return the change in width
    }
    return w; //return the change in width
  }
  
  public float insert(String text, int pos) { //types (using insert) a string into a certain position
    texts.ensureCapacity(texts.size()+text.length()); //ensure capacity
    
    //first, insert all the characters of text, one by one
    float wTotal = 0; //total width of all characters
    for(int n=0;n<text.length();n++) { //loop through all characters in text
      float w = mmio.getTextWidth(text.charAt(n)+"",tSize);                  //calculate width of each character
      texts.add(pos+n, new SimpleText(text.charAt(n), getX(pos)+wTotal, w)); //insert each character
      wTotal+=w;                                                             //increment total width appropriately
    }
    
    //next, shift all characters after the text appropriately
    for(int n=pos+text.length();n<size();n++) { //loop through all characters after text
      texts.get(n).x += wTotal;                 //shift their positions appropriately
    }
    
    return wTotal; //return how much it changed by
  }
  
  public float remove(int pos) { //removes the character at pos
    if(pos<0 || pos>=size()) { return 0; } //out of range: do nothing, return 0
    
    float w = getW(pos);        //find width of character we're removing
    texts.remove(pos);          //remove said character
    for(int n=pos;n<size();n++) { //loop through all characters after the one we deleted
      texts.get(n).x -= w;        //shift their positions left by the width of that deleted string
    }
    return -w; //return how much it decreased by
  }
  
  public float remove(int pos1, int pos2) { //removes all characters from pos1 (inclusive) to pos2 (exclusive)
    //first, remove all the characters over the range, one by one
    float wTotal = getX(pos2)-getX(pos1); //total width of all removed characters (calculated before, not after)
    for(int n=pos1;n<pos2;n++) { //loop through all elements over the range
      texts.remove(pos1);        //repeatedly remove the first element in the range
    }
    
    for(int n=pos1;n<size();n++) { //loop through all elements after the ones we deleted
      texts.get(n).x -= wTotal;    //shift their positions left by the width of that deleted string
    }
    return -wTotal; //return how much it decreased by
  }
  
  public float clear() { //clear everything
    float wTotal = getX(size())-tx; //first, calculate the width
    texts.clear(); //next, clear the texts
    return -wTotal; //finally, return the change
  }
  
  //////////////////// TYPING (PUBLIC) ////////////////////////////////////
  
  public void restrictCaret() { //forces caret(s) to a valid position
    caret = constrain(caret,0,size());
    anchorCaret = constrain(anchorCaret,0,size());
  }
  
  public void adjust(final boolean target, final boolean snap, final boolean blink) { //performs adjustments, recommended to be executed every time a text editing action is performed
    fixWidth(); //fix the surface to the correct width
    
    if(target) {      //if applicable:
      //chooseTargetRecursive(getX(caret),ty+0.5*getTextHeight()); //adjust targeting system
      chooseTargetRecursive(getX(caret),ty,getX(caret),ty+getTextHeight());                       //adjust targeting system
      if(snap && this.target!=null) { this.target.time-=SurfaceTarget.duration; moveToTarget(); } //if we want to snap to our target, we must snap to our target
    }
    
    if(blink) { resetBlinker(); } //if asked, make the caret visible
  }
  public void adjust() { adjust(true,false,true); } //usually, we want to target, not snap, and make caret visible
  
  public void moveCaretTo(final int pos, final boolean target, final boolean snap, final boolean blink) { //move caret to position
    caret = constrain(pos,0,size());
    adjust(target, snap, blink);
  }
  public void moveCaretTo(final int pos) { moveCaretTo(pos,true,false,true); }
  
  public void moveCaretBy(final int amt, final boolean target, final boolean snap, final boolean blink) { //move caret by amount
    caret = constrain(caret+amt,0,size());
    adjust(target, snap, blink);
  }
  public void moveCaretBy(final int amt) { moveCaretBy(amt,true,false,true); }
  
  public void insert(final char text, final boolean target, final boolean snap, final boolean blink) { //insert character to the right of caret (and move caret)
    insert(text, caret++);
    adjust(target, snap, blink);
  }
  public void insert(final char text) { insert(text,true,false,true); }
  
  public void insert(final String text, final boolean target, final boolean snap, final boolean blink) { //insert string to the right of caret (and move caret)
    insert(text, caret); caret+=text.length();
    adjust(target, snap, blink);
  }
  public void insert(final String text) { insert(text,true,false,true); }
  
  public void overtype(final char text, final boolean target, final boolean snap, final boolean blink) { //overtype character to the right of caret (and move caret)
    overtype(text, caret++);
    adjust(target, snap, blink);
  }
  public void overtype(final char text) { overtype(text,true,false,true); }
  
  public void type(final char text, final boolean target, final boolean snap, final boolean blink) { //either insert or overtype, depending on the mode
    if(insert) { insert(text,caret++); } else { overtype(text, caret++); }
    adjust(target, snap, blink);
  }
  public void type(final char text) { type(text,true,false,true); }
  
  public void delete(final boolean target, final boolean snap, final boolean blink) { //delete character right of caret
    remove(caret);
    adjust(target, snap, blink);
  }
  public void delete() { delete(true,false,true); }
  
  public void backspace(final boolean target, final boolean snap, final boolean blink) { //delete character left of caret (and move caret 1 left)
    if(caret==0) { return; }
    remove(--caret);
    adjust(target, snap, blink);
  }
  public void backspace() { backspace(true,false,true); }
  
  public void clear(final boolean target, final boolean snap, final boolean blink) { //clear entire field
    clear();
    caret = anchorCaret = 0; highlighting = false;
    adjust(target, snap, blink);
    buddy.clearHandles(); //remove any text handles
  }
  public void clear2() { clear(true,true,true); } //this one is different, the default is to snap right into place, to avoid out of bounds
  
  public void replace(final String text) { //replaces the entire contents of typing field with something else (TODO stop it from having graphical bugs, you know, like it being out of bounds)
    clear(); caret = 0; insert(text,0); adjust(false,false,true);
  }
  
  
  public void ctrlLeft(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+left functionality, moving caret to the previous word
    if(caret!=0) { //doesn't work if caret is at beginning
      char seed = charAt(caret-1); //grab char right before caret
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      do { //repeatedly decrement caret
        --caret;
      } while(caret>0 && ident == (Character.isLetterOrDigit(seed=charAt(caret-1)) || seed=='_')); //stop when we reach 0, or when we reach a character which is a letter/number/underscore XOR the orignal was
    }
    adjust(target,snap,blink);
  }
  public void ctrlLeft() { ctrlLeft(true,false,true); }
  
  public void ctrlRight(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+right functionality, moving caret to the next word
    if(caret!=size()) { //doesn't work if caret is at end
      char seed = charAt(caret); //grab char in front of caret
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      do { //repeatedly increment caret
        ++caret;
      } while(caret<size() && ident == (Character.isLetterOrDigit(seed=charAt(caret)) || seed=='_')); //stop when we reach the end, or when we reach a character which is a letter/number/underscore XOR the original was
    }
    adjust(target,snap,blink);
  }
  public void ctrlRight() { ctrlRight(true,false,true); }
  
  public void ctrlBackspace(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+backspace functionality, removing the word to the left of the caret (then moving caret to the left)
    if(caret!=0) { //doesn't work if caret is at beginning
      char seed = charAt(caret-1); //grab char right before caret
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      int caret0 = caret; //record original caret position
      do { //repeatedly decrement caret
        --caret;
      } while(caret>0 && ident == (Character.isLetterOrDigit(seed=charAt(caret-1)) || seed=='_')); //stop when we reach 0, or when we reach a character which is a letter/number/underscore XOR the original was
      remove(caret,caret0); //remove all characters in between both carets
    }
    adjust(target,snap,blink);
  }
  public void ctrlBackspace() { ctrlBackspace(true,false,true); }
  
  public void ctrlDelete(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+delete functionality, removing the word to the right of the caret
    if(caret!=size()) { //doesn't work if caret is at end
      char seed = charAt(caret); //grab char in front of caret
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      int caret2 = caret; //create second fake caret
      do { //repeatedly increment fake caret
        ++caret2;
      } while(caret2<size() && ident == (Character.isLetterOrDigit(seed=charAt(caret2)) || seed=='_')); //stop when we reach the end, or when we reach a character which is a letter/number/underscore XOR the original was
      remove(caret,caret2); //remove all characters in between both carets
    }
    adjust(target,snap,blink);
  }
  public void ctrlDelete() { ctrlDelete(true,false,true); }
  
  public void ctrlShiftBackspace(final boolean target, final boolean snap, final boolean blink) { //performs ctrl+shift+backspace functionality, removing everything to the left of the caret (then moving the caret all the way left)
    remove(0,caret); //remove all characters before the caret
    caret = 0;       //move caret to 0
    adjust(target,snap,blink); //adjust
  }
  
  public void ctrlShiftDelete(final boolean target, final boolean snap, final boolean blink) { //performs ctrl+shift+delete functionality, removing everything to the right of the caret
    remove(caret,size());      //remove all characters after the caret
    adjust(target,snap,blink); //adjust
  }
  
  
  /// INVOLVING HIGHLIGHTING ///
  
  public void adjustHighlightingForArrows(boolean shiftHeld) { //performs functionality that must happen before using keys to move caret
    if(!highlighting && shiftHeld) { //if not highlighting, but holding shift:
      highlighting = true; //start highlighting
      anchorCaret = caret; //set the anchor caret 
    }
    else if(highlighting && !shiftHeld) { //if highlighting, but not holding shift
      highlighting = false;          //stop highlighting
      anchorCaret = caret;           //reset the anchor caret
      mmio.removeHandlesLater(this); //schedule handles to be removed later
    }
  }
  
  public void negateHighlight() {
    if(highlighting && caret == anchorCaret) { //if we changed our selection such that both carets are the same:
      highlighting = false;                    //disable highlighting
    }
  }
  
  public void selectAll(boolean snap) {
    highlighting = true; //start highlighting
    anchorCaret = 0;     //move anchor caret to the beginning
    moveCaretTo(size(),true,snap,true); //move the primary caret to the end
  }
  
  public void eraseSelection() { //erases the highlighted selection
    if(highlighting) {    //if the highlighted selection exists:
      remove(getLeftCaret(),getRightCaret()); //remove everything between the two carets
      moveCaretTo(getLeftCaret()); //move the caret to the left of the two
      restrictCaret();             //restrict both carets to be in bounds
      highlighting = false;        //disable highlighting
    }
    mmio.removeHandlesLater(this); //schedule for this textbox's handles to be removed
  }
  
  public void removeSelectMenu() { if(selectMenu!=null) { //removes select menu if applicable
    selectMenu.setParent(null); selectMenu = null;
  } }
  
  public void addSelectMenu() { if(selectMenu==null) { //adds select menu if there isn't already one
    selectMenu = new SelectMenu(this,caret);
  } }
  
  //TODO see if this is necessary
  public void replaceSelectMenu() { //removes current select menu (if applicable) and adds a new one
    if(selectMenu!=null) { selectMenu.setParent(null); }
    selectMenu = new SelectMenu(this,caret);
  }
  
  
  public void fixWidth() { surfaceW = max(w, xSpace+getX(size())); } //adjust the width to be appropriate
  
  ////////////// MISC /////////////////////
  
  public void resetBlinker() { blink = System.currentTimeMillis(); }
  
  public void idlyUpdateCarets() { //updates the carets while you idly hold the cursor to the far left or far right
    
    if(!sliding) { return; } //don't do anything unless we're sliding
    
    if(buddy.caretCursor != null) {
      int caret2 = buddy.cursorToCaret(buddy.caretCursor.x);        //find what caret position we're hovering over
      if(hMode!=HighlightMode.MOBILE || !highlighting || (caret2!=caret && caret2!=anchorCaret)) { //if we're not on mobile mode, or moving here doesn't cause both carets to be the same (assuming we're highlighted)
        caret = caret2; //set the caret
        resetBlinker(); //reset the blinker
        if(buddy.caretHandle!=null) { buddy.caretHandle.moveToIndex(caret); } //if there's a TS handle, move it to the caret index
      }
    }
    if(buddy.anchorCursor != null) {
      int caret2 = buddy.cursorToCaret(buddy.anchorCursor.x);        //find what caret position we're hovering over
      if(hMode!=HighlightMode.MOBILE || !highlighting || (caret2!=caret && caret2!=anchorCaret)) { //if we're not on mobile mode, or moving here doesn't cause both carets to be the same (assuming we're highlighted)
        anchorCaret = caret2; //set the anchor caret
        resetBlinker();       //reset the blinker
        if(buddy.anchorHandle!=null) { buddy.anchorHandle.moveToIndex(anchorCaret); } //if there's a TS handle, move it to the anchor caret index
      }
    }
  }
  
  public void tryToSlide(final Cursor curs) { //tries to slide, only doing so if it's allowed to
    float sx = getObjX(); //grab the objective x position
    float leftDiff  = sx+ leftHighlightBarrier-curs.x,
          rightDiff = sx+rightHighlightBarrier-curs.x;
    boolean  left =  leftDiff>0 && curs.x < curs.xi; //whether the cursor is far enough left
    boolean right = rightDiff<0 && curs.x > curs.xi; //whether the cursor is far enough right
    
    if(dragCursor == null) { //if there isn't a cursor dragging
      if(left) { //if far enough left
        sliding = true; surfaceVx = highlightDragSpeed*leftDiff; dragCursor = curs; //start sliding to the left (surface moves right), and set the drag cursor
      }
      else if(right) { //if the cursor is far enough right:
        sliding = true; surfaceVx = highlightDragSpeed*rightDiff; dragCursor = curs; //start sliding to the right (surface moves left), and set the drag cursor
      }
    }
    
    else if(dragCursor == curs) { //otherwise, if THIS is the drag cursor:
      if     ( left) { surfaceVx = highlightDragSpeed*leftDiff; } //if left, move left
      else if(right) { surfaceVx = highlightDragSpeed*rightDiff; } //if right, move right
      else { sliding = false; surfaceVx = 0; dragCursor = null; } //if none, turn off surface sliding
    }
    
    resetBlinker(); //stop the caret from blinking
  }
  
  static class CaretMover extends Box { //an invisible box whose hitbox allows us to move the textbox's caret
    
    Textbox buddy; //the parent cast to a textbox
    
    //timing
    long lastTapped = 0;            //when this was last tapped
    float lastTappedX, lastTappedY; //where this was last tapped
    int doubleTapTimeout = 500;     //how many milliseconds can happen between consecutive double taps
    
    float highlightGrabDistance; //how far the cursor can be from the caret to grab it while highlighting
    
    Cursor caretCursor = null; //the cursor currently dragging our active caret
    Cursor anchorCursor = null; //the cursor currently dragging our anchor caret
    
    TSHandle caretHandle = null, anchorHandle = null; //text selection handles for the main caret and the anchor caret
    
    CaretMover(final Textbox t) {
      super(0,t.ty,t.w,t.getTextHeight());
      setFill(false).setStroke(false).setMobile(false).setParent(t);
      //setFill(0x80FF0000); //debug: gives the mover a redish hue to make it visible
      highlightGrabDistance = 0.5f*t.tSize;
      buddy = t;
    }
    
    public void addCaretHandle() { //adds a single caret handle
      caretHandle = new TSHandle(buddy, buddy.caret, CENTER, false); //create a centered handle at the primary caret
    }
    
    public boolean respondToChange(final Cursor curs, final byte code, boolean selected) { //responds to change in the cursor (0=release, 1=press, 2=move, 3=drag) (select iff cursor is already touching something)
      
      boolean hitbox = hitbox(curs); //first, find if the cursor is inside the hitbox
      
      if(hitbox && !selected && code==1) { //if the cursor is in the hitbox, and hasn't already selected something else, and just now started pressing
        switch(buddy.hMode) {
          case PC: { //PC:
            //curs.seLocked = true; //block select promotion
            
            buddy.highlighting = true; //turn highlighting on
            buddy.anchorCaret = buddy.caret = cursorToCaret(curs.x); //move both carets to the cursor
            caretCursor = curs; //set the cursor that drags this caret around
          } break;
          case MOBILE: { //mobile:
            
          } break;
          default: { } break;
        }
        
        mmio.updatePressCount();   //reset the press counter for every button to 0
      }
      
      else if(this==curs.select && code==0) { //if this box was already selected by the cursor, and has just been released:
        switch(buddy.hMode) {
          case NONE: { //no highlighting:
            release(curs); //perform release functionality
          } break;
          case PC: { //PC:
            caretCursor = null; //make the caret cursor null
            buddy.sliding = false; buddy.surfaceVx = 0; //stop sliding
            
            release(curs); //perform release functionality
          } break;
          case MOBILE: { //mobile:
            release(curs); //perform release functionality
            
            boolean wasHighlighting = buddy.highlighting; //record beforehand if we were highlighting
            
            clearHandles(); //remove all handles
            buddy.highlighting = false; //disable highlighting
            
            long time = System.currentTimeMillis();
            //double tapping is deemed to happen if you press twice in a row, both taps fairly close together in both time and proximity
            if(time - lastTapped <= doubleTapTimeout && sq(curs.x-lastTappedX)+sq(curs.y-lastTappedY) < sq(buddy.promoteDist)) { //if we just double tapped:
              if(wasHighlighting || buddy.size()==0) { //if we were already highlighting (or there's nothing to select):
                buddy.anchorCaret = buddy.caret;       //equalize the carets
                
                addCaretHandle(); //add TS handle at caret
                //this is the triple tap functionality, bring up select menu w/out highlighting
              }
              else { //if not yet highlighting:
                processTextTouch(curs); //process the double tap functionality
              }
              
              buddy.addSelectMenu(); //if there isn't already one, add a select menu
            }
            else { //otherwise...
              addCaretHandle(); //add TS handle at caret
            }
            lastTapped = time; //update when and where this was last tapped
            lastTappedX = curs.x; lastTappedY = curs.y;
          } break;
        }
        
        buddy.dragCursor = null; //reset the drag cursor
      }
      
      else if(this==curs.select && caretCursor==curs && code==3) { //if this box was already selected by the cursor, this cursor is the caret cursor, and the cursor is being dragged:
        switch(buddy.hMode) {
          case PC: { //PC:
            buddy.caret = cursorToCaret(curs.x); //move the caret to where the cursor is
            
            buddy.tryToSlide(curs); //try to slide (only works if you're allowed to)
            
            buddy.resetBlinker(); //make the caret visible
          } break;
          default: { } break;
        }
      }
      
      return hitbox; //return whether the cursor is in the hitbox
    }
    
    public void processTextTouch(Cursor curs) { //this processes text being double tapped or pressed and held
      float cursorFromCaretX = curs.x - buddy.getX(buddy.caret) - buddy.getObjSurfaceX(); //find the position of the cursor WRT the caret
      buddy.anchorCaret = cursorFromCaretX > 0 ? buddy.caret+1 : buddy.caret-1; //set the anchor position such that the cursor is between both carets
      buddy.restrictCaret(); //make sure the anchor caret is in bounds
      
      if(buddy.anchorCaret != buddy.caret) { //if the carets are distinct:
        buddy.highlighting = true; //enable highlighting
        
        caretHandle = new TSHandle(buddy, buddy.caret, buddy.caret<buddy.anchorCaret ? LEFT : RIGHT, false);
        anchorHandle = new TSHandle(buddy, buddy.anchorCaret, buddy.caret<buddy.anchorCaret ? RIGHT : LEFT, true);
      }
      else { //if they're in the same position, though:
        addCaretHandle(); //add TS handle at caret
        //basically, if we tap to the left or right of the text, we don't want to select anything, we just wanna bring up the select menu
      }
    }
    
    public void release(Cursor curs) { //performs a release event, allowing the caret to be moved by the mouse
      buddy.caret = cursorToCaret(curs.x); //move the caret to the position the cursor is hovering over
      
      buddy.releaseAction.act(); //perform the specified action
      mmio.updatePressCount();   //reset the press counter for every button to 0
      
      buddy.resetBlinker();      //make the caret visible
    }
    
    public int cursorToCaret(float x) { //finds which caret the given cursor is hovering over (input is the cursor's x position)
      float sx = buddy.getObjSurfaceX(); //get OBJECTIVE surface position
      float objX = buddy.getObjX();      //get objective panel position
      x = constrain(x,objX,objX+w);      //constrain x to be within the boundaries of the panel
      for(int n=0;n<=buddy.size();n++) { //loop through all caret positions
        if((n==0            || sx+buddy.getX(n-1)+0.5f*buddy.getW(n-1)<=x) && //find one such that the previous character is left of the cursor (or there is no previous character)
           (n==buddy.size() || sx+buddy.getX(n  )+0.5f*buddy.getW(n  )> x)) { //and the next character is right of the cursor (or there is no next cursor)
          return n; //return the index that meets those conditions
        }
      }
      throw new RuntimeException("CURSOR FAILED TO SELECT A CARET"); //if, somehow, none of the caret positions meet those conditions, throw an exception
    }
    
    public void clearHandles() { //removes both handles
      if( caretHandle!=null) {  caretHandle.setParent(null);  caretHandle=null; } //TODO: VERY SERIOUS ISSUE, SOMEONE COULD ACCIDENTALLY DRAG AROUND A NULL CURSOR IF THEY USE TWO FINGERS!!!!
      if(anchorHandle!=null) { anchorHandle.setParent(null); anchorHandle=null; }
      buddy.removeSelectMenu(); //make the select menu disappear
    }
    
    public void correctHandles() { if(buddy.hMode==HighlightMode.MOBILE) { //corrects the position, orientation, and configuration of all the text selection handles (only used in mobile mode)
      if(caretHandle!=null) { //if there is a caret handle:
        caretHandle.moveToIndex(buddy.caret); //move it to where it needs to be
        if(!buddy.highlighting) { caretHandle.reorient(CENTER); }                    //if not highlighting, give it a centered orientation
        else { caretHandle.reorient(buddy.caret<buddy.anchorCaret ? LEFT : RIGHT); } //otherwise, make it either left or right, depending on the configuration of the carets
      }
      if(anchorHandle!=null) { //if there is an anchor caret handle:
        anchorHandle.moveToIndex(buddy.anchorCaret); //move it to where it needs to be
        if(!buddy.highlighting) { anchorHandle.setParent(null); anchorHandle=null; }  //if not highlighting, delete it
        else { anchorHandle.reorient(buddy.caret<buddy.anchorCaret ? RIGHT : LEFT); } //otherwise, make it either left or right, depending on the configuration of the carets
      }
      if(buddy.highlighting) {  //if we're highlighting, we might have to add handles
        if(caretHandle==null) { //if there's no caret handle
          caretHandle = new TSHandle(buddy, buddy.caret, buddy.caret<buddy.anchorCaret ? LEFT : RIGHT, false); //add one
        }
        if(anchorHandle==null) { //if there's no anchor handle
          anchorHandle = new TSHandle(buddy, buddy.anchorCaret, buddy.caret<buddy.anchorCaret ? RIGHT : LEFT, true); //add one
        }
      }
    } }
  }
  
  static class TSHandle extends Box { //text selection handle
    int orientation = CENTER; //orienation (left, right, or center)
    boolean anchor = false;   //whether it's an anchor caret
    
    Textbox host; //the host textbox this handle handles text selection for
    //For display purposes, the host isn't necessarily the parent. However, the host must either be the parent or inside the parent
    float xi;     //the position of the cursor relative to the handle at the moment it was first pressed down
    
    TSHandle(float x2, float y2, int ori, float rad) { //simple constructor
      orientation = ori; //set orientation
      y = y2;            //set y position
      setParamsFromOrientation(x2, rad); //set remaining dimensional parameters
    }
    
    TSHandle(final Textbox host_, int caret, int ori, boolean anch) { //constructor from host textbox, caret position, orientation, and whether it's an anchor caret
      host = host_; //set the host
      setParent();  //set the parent
      
      orientation = ori;                  //set orientation
      y = host.ty + host.getTextHeight(); //assign y (relative to the host, at least)
      float x2 = host.getX(caret);        //get the x position
      fillColor = host.handleColor; stroke = false; //set the drawing parameters
      setParamsFromOrientation(x2, host.handleRad); //set the dimensional parameters given the orientation
      anchor = anch;                                //either make it an anchor cursor or don't
    }
    
    private void setParent() { //sets the parent, assuming it already has a host
      if(host.handleParent == null) { //if the handle parent isn't yet assigned:
        host.setHandleParent(host.parent); //default the host's handle parent to the host's own parent
      }
      setParent(host.handleParent); //set the parent to the host's handle parent
    }
    
    public void setParamsFromOrientation(float x2, float rad) { //sets the dimensional parameters, knowing the orientation
      switch(orientation) {
        case LEFT  : x = x2-2*rad; w = 2*rad; h = 2    *rad; break;
        case CENTER: x = x2-rad;   w = 2*rad; h = 2.414f*rad; break;
        case RIGHT : x = x2;       w = 2*rad; h = 2    *rad; break;
      }
    }
    
    public void reorient(int ori) { //changes the orientation
      if(ori==orientation) { return; } //if the orientation is the same, do nothing
      float caretPos = 0;   //first, record the x position of the caret we're pointing to
      switch(orientation) { //this depends on our current orientation
        case LEFT  : caretPos = x+w;     break;
        case CENTER: caretPos = x+0.5f*w; break;
        case RIGHT : caretPos = x;       break;
      }
      orientation = ori; //then, change the orientation
      switch(orientation) { //then, we change the dimensions again depending on the orientation
        case LEFT  : x = caretPos-w; h = w;           break;
        case CENTER: x = caretPos-0.5f*w; h = 1.207f*w; break;
        case RIGHT : x = caretPos; h = w;             break;
      }
    }
    
    public @Override float getX() { return x + host.getSurfaceX() + host.getXRelTo(parent); } //in order to follow our host, but still not be confined to our host's borders, we have to override our x position
    public @Override float getY() { return y + host.getSurfaceY() + host.getYRelTo(parent); } //and y position
    public @Override float getObjX() { return x+host.getObjSurfaceX(); }                      //and objective x position
    public @Override float getObjY() { return y+host.getObjSurfaceY(); }                      //and objective y position
    
    public @Override
    void display(final PGraphics graph, float buffX, float buffY) {
      float xRelToHost = x+host.surfaceX + (orientation==LEFT ? w : orientation==CENTER ? 0.5f*w : 0);
      if(xRelToHost<0 || xRelToHost>host.w) { return; }
      
      float x3 = getX()-buffX, y3 = getY()-buffY; //get location where you should actually draw
      setDrawingParams(graph);                    //set drawing parameters
      switch(orientation) {
        case LEFT  : graph.ellipse(x3+0.5f*w, y3+0.5f  *h, w, h); graph.rect(x3+0.5f*w,y3, 0.5f*w, 0.5f*h); break;
        case CENTER: graph.ellipse(x3+0.5f*w, y3+0.707f*w, w, w); graph.triangle(x3+0.5f*w,y3, x3+0.146f*w,y3+0.354f*w, x3+0.854f*w,y3+0.354f*w); break;
        case RIGHT : graph.ellipse(x3+0.5f*w, y3+0.5f  *h, w, h); graph.rect(x3      ,y3, 0.5f*w, 0.5f*h); break;
      }
    }
    
    public boolean respondToChange(final Cursor curs, final byte code, boolean selected) {
      boolean hitbox = hitbox(curs); //first, find if the cursor is inside the hitbox
      
      if(hitbox && !selected && code == 1) { //if the cursor is in the hitbox, and hasn't already selected something else, and just now started pressing
        curs.seLocked = true; //block select promotion
        
        if(anchor) { host.buddy.anchorCursor = curs; }
        else       { host.buddy. caretCursor = curs; }
        
        //xi = curs.x-
      }
      
      else if(this==curs.select && code == 0) { //if this is what the cursor has selected, and we just released...um...I don't think we actually do anything???
        //OH WAIT, no, we bring up the selection menu above
        host.buddy.correctHandles();
        host.sliding = false; host.surfaceVx = 0;
        
        if(anchor) { host.buddy.anchorCursor = null; }
        else       { host.buddy. caretCursor = null; }
        
        host.dragCursor = null; //reset the drag cursor
      }
      
      else if(this==curs.select && code == 3) { //if this is what the cursor has selected, and said cursor is being dragged around,
        int caret = host.buddy.cursorToCaret(curs.x); //find what caret position we're hovering over
        
        if(!host.highlighting || (caret!=host.caret && caret!=host.anchorCaret)) { //if moving here doesn't cause both carets to be the same (assuming we're highlighted)
          if(anchor) { host.anchorCaret = caret; }
          else       { host.      caret = caret; }
          host.resetBlinker();
          moveToIndex(caret);
          
          //sibling.buddy.correctHandles();
        }
        
        host.tryToSlide(curs); //try to slide (only works if you're allowed to)
      }
      
      return hitbox; //return whether the cursor is in the hitbox
    }
    
    public void moveToIndex(int ind) { //moves the handle to the correct position corresponding to the given caret index
      switch(orientation) {     //how we do this depends on the orientation
        case LEFT  : x = host.getX(ind) -     w; break;
        case CENTER: x = host.getX(ind) - 0.5f*w; break;
        case RIGHT : x = host.getX(ind);         break;
      }
    }
  }
  
  static class SelectMenu extends Panel {
    Textbox host; //the textbox for which this controls text editing
    
    SelectMenu(Textbox host_, int caret) { //builds the selection menu
      host = host_; //set the host
      setParent();  //set the parent
      
      
      //float middle = host.getX(caret)+host.surfaceX+host.x+parent.surfaceX;
      
      w = 0.91f*host.mmio.w; h = 0.14f*host.mmio.w; //set the width and height
      //println(w, h, host.mmio.w, host.mmio.h, parent.w, parent.h);
      
      float middle = host.getX(caret)+host.getSurfaceXRelTo(parent); //find the x position of the caret (relative to the parent)
      
      x = constrain(middle-0.5f*w,0,parent.w-w); //set x such that the center is as close to "middle" as possible, while still being strictly in bounds
      
      y = host.ty-1.2f*h; //place the menu directly above the text
      if(y+host.getYRelTo(parent)<0) { //if the menu is cut off from above:
        y = host.ty+0.2f*h+host.getTextHeight(); //place the menu directly below the text
      }
      
      surfaceW = w; surfaceH = h; fill = false; surfaceFill = true; stroke = false; //set drawing parameters
      surfaceFillColor = 0xff3a3a3d;
      r = 0.049f*w;
      
      setScrollable(false, false);               //make it not scrollable
      setDragMode(DragMode.NONE, DragMode.NONE); //make it not draggable
      
      Button cut       = new Button(0.06f*w,0,0.16f*w,h).setFills(0xff3a3a3d,0xff616164).setStroke(false); cut      .setParent(this); cut      .setText("Cut"       ,0.058f*w,-1);
      Button copy      = new Button(0.22f*w,0,0.20f*w,h).setFills(0xff3a3a3d,0xff616164).setStroke(false); copy     .setParent(this); copy     .setText("Copy"      ,0.058f*w,-1);
      Button paste     = new Button(0.42f*w,0,0.22f*w,h).setFills(0xff3a3a3d,0xff616164).setStroke(false); paste    .setParent(this); paste    .setText("Paste"     ,0.058f*w,-1);
      Button selectAll = new Button(0.63f*w,0,0.31f*w,h).setFills(0xff3a3a3d,0xff616164).setStroke(false); selectAll.setParent(this); selectAll.setText("Select All",0.058f*w,-1);
      //initPixPerClick();
      
      cut.setOnRelease(new Action() { public void act() { //create the cut button
        copyToClipboard(host.substring(host.getLeftCaret(), host.getRightCaret())); //copy the selection to the clipboard
        host.eraseSelection(); //erase the selection
      } });
      copy.setOnRelease(new Action() { public void act() { //create the copy button
        copyToClipboard(host.substring(host.getLeftCaret(), host.getRightCaret())); //copy the selection to the clipboard
        mmio.removeHandlesLater(host); //remove the handles later
      } });
      paste.setOnRelease(new Action() { public void act() { //create the paste button
        String text = getTextFromClipboard(); //grab the contents from clipboard
        if(text!=null) {         //if the contents were valid:
          host.eraseSelection(); //if highlighting, erase the selection
          host.insert(text);     //insert the contents from the clipboard
        }
        host.removeSelectMenu();
        host.correctHandlesLater = true;
      } });
      selectAll.setOnRelease(new Action() { public void act() { //create the select all button
        host.selectAll(false);       //select the whole thing
        host.buddy.correctHandles(); //correct the handle orientation
      } });
    }
    
    private void setParent() { //sets the parent, assuming it already has a host
      if(host.handleParent == null) { //if the handle parent isn't yet assigned:
        host.setHandleParent(host.parent); //default the host's handle parent to the host's own parent
      }
      setParent(host.handleParent); //set the parent to the host's handle parent
    }
    
    public @Override float getX() { return x + host.getXRelTo(parent); } //in order to follow our host, but still not be confined to our host's borders, we have to override our x position
    public @Override float getY() { return y + host.getYRelTo(parent); } //and y position
    public @Override float getObjX() { return x+host.getObjX(); }                      //and objective x position
    public @Override float getObjY() { return y+host.getObjY(); }                      //and objective y position
  }
}

static class SimpleText {
  char text; float x, w; byte properties=0; //the text displayed, position, width, misc properties
  Object misc = null; //finally, an object to hold any miscellaneous stuff we might have
  
  SimpleText() { }
  SimpleText(char t, float x_, float w_) { text=t; x=x_; w=w_; }
  SimpleText(char t, float x_, float w_, byte p) { this(t,x_,w_); properties=p; }
  
  public @Override
  String toString() { return text+""; }
}
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "Calculator_5" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
