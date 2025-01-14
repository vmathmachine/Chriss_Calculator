import vsync.*;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Stack;
import java.util.Queue;
import java.util.List;
import java.util.LinkedList;
import java.util.Map;
import java.util.EnumMap;
import java.util.concurrent.Semaphore;
//import processing.sound.*;
import complexnumbers.*;

import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.Toolkit;

/*import android.app.Activity;
import android.view.WindowManager;
import android.view.View;
import android.os.*;
import android.util.DisplayMetrics;
import android.content.res.Resources;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.Context;
import android.app.Activity;
import android.os.Looper;

import android.content.SharedPreferences;

Activity act;
View decorView;
int uiOptions;

@Override
public void onCreate(Bundle savedInstanceState) { //here, we make it so that the status bar always displays at the top while using the app
  super.onCreate(savedInstanceState);
  act = this.getActivity();
  uiOptions = View.SYSTEM_UI_FLAG_VISIBLE;
  decorView = act.getWindow().getDecorView();
  act.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
  decorView.setSystemUiVisibility(uiOptions);
}*/

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

final static float relativeMarginWidth = 0.037;

static boolean pcOrMobile = true; //true means pc, false means mobile (determines how the interface gets initialized)
//TODO make something a little less...odd...than the above solution

//static PApplet testApplet;

static PFont roboto;
static PFont lucida;
static PFont openSans;

static java.util.Random random;

void settings() {
  System.setProperty("jogl.disable.openglcore", "false"); //get the thing to work properly
  
  //size(450,900,P2D);
  size(round(0.4167*displayHeight), round(0.8333*displayHeight), P2D);
  PJOGL.setIcon("icon-192.png");
}

void setup() {
  //size(450,900,P2D);
  
  dirChar = directoryCharacter();
  
  surface.setLocation((displayWidth-width)>>1, (displayHeight-height)>>1);
  surface.setTitle("Math's Machine");
  
  //testApplet = this;
  
  //roboto = createFont("fonts"+dirChar+"Roboto"+dirChar+"Roboto-Regular.ttf",20);
  lucida = createFont("fonts"+dirChar+"Lucida_Grande"+dirChar+"LucidaSans2.ttf",20);
  //openSans = createFont("fonts"+dirChar+"Open_Sans"+dirChar+"static"+dirChar+"OpenSans-Light.ttf",20);
  
  random = new java.util.Random();
  
  Textbox.defaultHandleRadius = 0.023*width;
  
  io = new Mmio(this);
  io.font = lucida;
  io.cursors.add(new UICursor(io,mouseX,mouseY)); //PC only
  //androidInitClipboard(this);     //Android only
  //androidInitSharedPreferences(); //Android only
  interfaceInit(io);
  
  grapher2D = new Graph(width/2.0,height/2.0,height/12.0).setVisible(false);
  grapher3D = new Graph3D(0,0,0,width,(int)(0.9*height),1).setVisible(false);
  
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

void draw() {
  try {
    background(0);
    time = System.currentTimeMillis();
    
    if(io.keyLast!=null && time-io.keyTime>500 && (time-io.keyTime)%30 < (timePrev-io.keyTime)%30) { //if needed, update the keys we press and hold
      io.keyPresser(io.keyLast, io.keyCodeLast, true);
    }
    
    io.performPendingPreOperations(); //perform all pending pre-operations that need to be executed before the rest
    
    io.targetAllChildren(); //perform the targeting algorithm on all boxes
    //io.updateCursorsAndroid(touches); //Android only, records all changes in the touches[] array and updates accordingly
    io.updateButtonHold(time, timePrev); //update the buttons that are being held down
    io.updatePanelScroll(io.cursors.get(0)); //PC only, records all updates in the mouseWheel and updates accordingly
    io.updatePanelDrag();       //update the act of cursor(s) dragging panel(s)
    io.updateCaretsRecursive(); //update the caret positions (if we're dragging them)
    io.updatePhysicsRecursive(0.001*(time - timePrev));
    
    io.performPendingPostOperations(); //perform all pending post-operations that could not be executed before
    
    
    grapher2D.updateFromTouches(io,0,0.055555556*height); //update both graphs based on our interactions with the screen
    grapher3D.updateFromTouches(io,0,0.055555556*height);
    
    updateParCount();             //update the display field for the number of parentheses
    equatList.updateCheckmarks(); //update the checkmarks for each equation
    
    defDrawer.beginDraw(); //begin drawing
    defDrawer.background(0); //set background to 0
    defDrawer.textFont(io.font);
    
    grapher2D.display(defDrawer,0,0.055555556*height,width,0.9*height,equatList.plots2D()); //display 2d graph
    
    io.display(defDrawer,0,0); //display user interface
    
    defDrawer.endDraw();   //finish drawing
    background(defDrawer); //display results
    
    grapher3D.display(g,0,0.055555556*height,width,0.9*height,equatList.plots3D()); //display 3d graph
    
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
  catch(RuntimeException ex) { //if an exception occurs
    copyToClipboard(getUsefulInfo(ex)); //copy the exception details to the clipboard
    //throw ex; //throw exception
    exit();
  }
}

static String getUsefulInfo(Exception ex) { //obtain useful information about an exception when it is thrown
  String info = ex.getClass().getSimpleName()+": "+ex.getMessage(); //initialize the message with the exception type and the message
  StackTraceElement[] stack = ex.getStackTrace(); //obtain the stack trace
  for(StackTraceElement e : stack) { //loop through all elements
    info += "\t"+e;                  //append each stack trace element, indented and separated by endlines
  }
  return info; //return result
}


void mouseWheel(MouseEvent event) {
  if(io.shiftHeld) { io.wheelEventX = event.getCount(); }
  else             { io.wheelEventY = event.getCount(); }
}

void mousePressed() {
  UICursor curs = io.cursors.get(0); //PC: there's only one cursor
  
  curs.press(mouseButton); //press the correct button
}

void mouseReleased() {
  UICursor curs = io.cursors.get(0); //PC: there's only one cursor
  
  curs.release(mouseButton); //release the correct button
}

void mouseMoved() {
  UICursor curs = io.cursors.get(0); //PC: there's only one cursor
  curs.updatePos(mouseX,mouseY);   //change the cursor position
  
  curs.move();
}

void mouseDragged() {
  UICursor curs = io.cursors.get(0); //PC: there's only one cursor
  curs.updatePos(mouseX,mouseY);   //change the cursor position
  
  curs.drag(); //perform dragging functionality
}

void keyPressed() {
  if(io.keyLast==null || io.keyLast!=key || io.keyCodeLast!=keyCode) {
    io.keyLast=key; io.keyCodeLast=keyCode; io.keyTime=System.currentTimeMillis();
    if(key==ENTER || key==RETURN) { hitEnter(); io.updatePressCount(); } //if we hit enter/return: perform the hit enter functionality, then reset all the press counts
    else { io.keyPresser(key, keyCode, false); } //otherwise, use the built-in key presser
  }
  
  if(key==CODED && keyCode==  SHIFT) { io.shiftHeld = true; } //if the shift key is held down, shiftHeld becomes true
  if(key==CODED && keyCode==CONTROL) { io.ctrlHeld  = true; } //if the ctrl key is held down, ctrlHeld becomes true
  
  //println("Key event:", key, int(key), keyCode);
}

void keyReleased() {
  io.keyReleaser(key, keyCode);
}

static boolean match(char a, char b, int a2, int b2) { //returns true if they're the same key, just with/without shift/ctrl held down
  if(a==b && (a!=CODED || a2==b2)) { return true; } //if they're the same, return true
  
  if(a>='a'-96 && a<='z'-96) { int diff=b-a; return diff==96 || diff==64; } //if a is CTRL-ed: return true if b is capital or lowercase a w/out the CTRL
  if(b>='a'-96 && b<='z'-96) { int diff=a-b; return diff==96 || diff==64; } //if b is CTRL-ed: return true if a is capital or lowercase b w/out the CTRL
  if(a>='A' && a<='Z') { return b-a == 32; } //if a is a capital letter: return true if b is lowercase a
  if(b>='A' && b<='Z') { return a-b == 32; } //if b is a capital letter: return true if a is lowercase b
  
  if(a==CODED && (a2==b || a2==b-32)) { return true; } //if a is CTRL-ed: return true if b is capital or lowercase a w/out the CTRL
  if(b==CODED && (a==b2 || a-32==b2)) { return true; } //if b is CTRL-ed: return true if a is capital or lowercase b w/out the CTRL
  
  //now, we have to check symbols
  String part1 = "`1234567890-=[]\\;',./", part2 = "~!@#$%^&*()_+{}|:\"<>?"; //make a string of lowercase symbols and one of uppercase symbols
  int indA = (part1+part2).indexOf(a), indB = (part2+part1).indexOf(b);      //find where each char is in part1+part2 and part2+part1
  return indA==indB && indA!=-1; //return true iff they are shift complements of each other
}





/*Action typeAnsPrefix(final char inp) { return new Action() { public void act() { if(io.typer!=null) {
  if(io.typer==query && io.typer.size()==0) { io.typer.insert("Ans"+inp); }
  else { io.typer.type(inp); }
} } }; }*/
