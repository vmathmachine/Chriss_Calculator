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

/*import java.awt.datatransfer.Clipboard;
import java.awt.datatransfer.StringSelection;
import java.awt.datatransfer.Transferable;
import java.awt.datatransfer.DataFlavor;
import java.awt.datatransfer.UnsupportedFlavorException;
import java.awt.Toolkit;*/

import android.app.Activity;
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
}

Mmio io;

long time = 0, timePrev = 0;
int frameCount2;
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

//PGraphics defDrawer; //pgraphics object to display using the default engine

PGraphics mainCanvas, altCanvas;
boolean isMainCanvas = false;
boolean draw2Active=false; //boolean to store whether draw2 is active
byte keyPressedActive=0; //byte to store how many instances of keyPressed are active

static char dirChar = '/';

final static float relativeMarginWidth = 0.037;

static boolean pcOrMobile = false; //true means pc, false means mobile (determines how the interface gets initialized)
//TODO make something a little less...odd...than the above solution

static long frame1 = 0, frame2 = 0;

static java.util.Random random;

void settings() {
  
  DisplayMetrics displayMetrics = Resources.getSystem().getDisplayMetrics();
  size(displayMetrics.widthPixels, displayMetrics.heightPixels, P2D);
  
  noSmooth();
}

void setup() {
  //size(1080,2115,P2D);
  
  //fullScreen(P2D, 1);
    
  /*DisplayMetrics displayMetrics = new DisplayMetrics();
  getActivity().getWindowManager().getDefaultDisplay().getMetrics(displayMetrics);
  println("Width: "+displayMetrics.widthPixels);
  println("Height: "+displayMetrics.heightPixels);*/
  
  //surface.setResizable(true);
  //windowResizable(true);
  //surface.setSize(displayMetrics.widthPixels, displayMetrics.heightPixels);
  
  random = new java.util.Random();
  
  Textbox.defaultHandleRadius = 0.023*width;
  
  io = new Mmio(this);
  //io.cursors.add(new UICursor(mouseX,mouseY)); //PC only
  androidInitClipboard(this);     //Android only
  androidInitSharedPreferences(); //Android only
  interfaceInit(io);
  
  grapher2D = new Graph(width/2.0,height/2.0,height/12.0).setVisible(false);
  grapher3D = new Graph3D(0,0,0,width,(int)(0.9*height),1).setVisible(false);
  
  equatList.grapher2D = grapher2D;
  equatList.grapher3D = grapher3D;
  
  if(saveWorks) { //if saving works
    history.loadFromDisk(); //load the history from the disk
    loadEquations(); //load graphs from disk
  }
  
  //init = System.currentTimeMillis();
  
  time = timePrev = System.currentTimeMillis();
  //Complex.omit_Option = false;
  
  //defDrawer = createGraphics(width,height);
  
  mainCanvas = createGraphics(width,height); altCanvas = createGraphics(width,height);
  mainCanvas.beginDraw(); mainCanvas.clear(); mainCanvas.endDraw();
  altCanvas.beginDraw(); altCanvas.clear(); altCanvas.endDraw();
  
  thread("looper");
}

void draw() {
  try {
    background(0);
    
    PGraphics canvas = isMainCanvas ? altCanvas : mainCanvas; //choose which canvas to display (choose whichever one isn't being edited right now)
    if(canvas.width==width && canvas.height==height) {   //HACK sometimes, the screen will briefly change dimensions (usually when locking your phone). If you attempt to draw the image to the screen, an exception is thrown and the app crashes
      background(isMainCanvas ? altCanvas : mainCanvas); //display the already loaded buffer
    }
    else { println("Error: canvas has dimensions "+canvas.width+"x"+canvas.height+", main graphics has dimensions "+width+"x"+height); } //when the error happens, document it, but don't let it crash the app
    
    grapher3D.display(g,0,0.055555556*height,width,0.9*height,equatList.plots3D()); //display 3d graph (TODO stop it from jittering. You know that's going to become a problem, but it's not one I can fix right now)
    
    io.wheelEventX = io.wheelEventY = 0; //update mousewheel positions
    io.updateCursorDPos();               //update previous draw positions (ALWAYS DO THIS AT THE END)
  }
  catch(RuntimeException ex) { //if an exception occurs
    copyToClipboard(getUsefulInfo(ex)); //copy the exception details to the clipboard
    throw ex; //throw exception
  }
}

void draw2(final PGraphics pg) {
  try {
    time = System.currentTimeMillis(); //record current time
    
    io.performPendingPreOperations(); //perform all pending pre-operations that need to be executed before the rest
    
    io.targetAllChildren(); //perform the targeting algorithm on all boxes
    
    //io.updateCursorsAndroid(touches); //Android only, records all changes in the touches[] array and updates accordingly
    io.cursorActions.acquire();
    TouchEvent.Pointer[] currTouches = touches;
    io.cursorActions.addUpdates(currTouches);
    io.cursorActions.performUpdates(currTouches);
    io.cursorActions.release();
    
    io.updateButtonHold(time, timePrev); //update the buttons that are being held down
    //io.updatePanelScroll(io.cursors.get(0)); //PC only, records all updates in the mouseWheel and updates accordingly
    io.updatePanelDrag();       //update the act of cursor(s) dragging panel(s)
    io.updateCaretsRecursive(); //update the caret positions (if we're dragging them)
    io.updatePhysicsRecursive(0.001*(time - timePrev));
    
    io.performPendingPostOperations(); //perform all pending post-operations that could not be executed before
    
    
    
    grapher2D.updateFromTouches(io,0,0.055555556*height); //update both graphs based on our interactions with the screen
    grapher3D.updateFromTouches(io,0,0.055555556*height);
    
    updateParCount();             //update the display field for the number of parentheses
    equatList.updateCheckmarks(); //update the checkmarks for each equation
    
    grapher2D.display(pg,0,0.055555556*height,width,0.9*height,equatList.plots2D()); //display 2d graph
    
    io.display(pg,0,0); //display user interface
    
    io.bufferGarbageCollect(); //garbage collect unused buffers
    timePrev = time;           //update time
    
    //if(frameCount%30 == 1) { println(frameRate, frameCount); } //DEBUG
    if(showPerformance && frameCount%30 == 1) { //DEBUG
      float rate = 30000f/(System.currentTimeMillis()-timeLastFrame);
      println("\nFramerate: "+rate+", frame count: "+frameCount);
      println("Time Record: ");
      long total=0; for(long n:timeRec) { total+=n; }
      float mean = (float)total/numTimesRec; float vari = (float)sumTimeSq/numTimesRec - mean*mean;
      String rec="Total time (ns): "+mean+" (+-"+sqrt(vari/numTimesRec)+")"; println(rec);
      rec="Times (ns): "; for(long n:timeRec) { rec+=(float)n/numTimesRec+"\t"; } println(rec);
      rec="Percentages: "; for(long n:timeRec) { rec+=n*100f/total+"\t"; } println(rec);
      rec="Dev of Percent: "; for(int n=0;n<timeRec.length;n++) { rec+=100f*sqrt(timeRecSq[n]-(float)(timeRec[n]*timeRec[n])/total)/total+"\t"; } println(rec);
      timeLastFrame = System.currentTimeMillis();
    }
    
    //if(frameCount >= 600) { throw new RuntimeException("This is just a test. 600 frames have occurred."); } //DEBUG
  }
  catch(RuntimeException ex) { //if an exception occurs
    copyToClipboard(getUsefulInfo(ex)); //copy the exception details to the clipboard
    throw ex; //throw exception
  }
}

void looper() {
  final PGraphics main = mainCanvas, alt = altCanvas; //grab the main and alternate canvases
  frameCount2 = 1;
  timeLastFrame = System.currentTimeMillis();
  
  while(true) {
    draw2Active=true; //draw2 is practically already active
    final PGraphics pg = isMainCanvas ? main : alt; //whichever buffer was used last time, use the other buffer
    final int fc = frameCount;                      //record frame count at the beginning
    
    pg.beginDraw();   //start drawing
    pg.background(0); //clear canvas
    
    draw2(pg);         //perform the draw2 function
    draw2Active=false; //draw2 is no longer active
    
    pg.endDraw(); //finish drawing
    
    isMainCanvas ^= true; //swap canvases
    
    while(fc==frameCount || keyPressedActive!=0) { delay(1); } //delay next iteration until next frame count (if key is being pressed, wait for them to be done)
    frameCount2++;
    
    if(frameCount2%30==0) {
      frame1 = frame2; frame2 = System.currentTimeMillis();
    }
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


/*void mouseWheel(MouseEvent event) {
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
}*/

void touchStarted() {
  io.cursorActions.acquire();
  io.cursorActions.addUpdates(touches);
  io.cursorActions.release();
}

void touchEnded() {
  io.cursorActions.acquire();
  io.cursorActions.addUpdates(touches);
  io.cursorActions.release();
}

void touchMoved() {
  io.cursorActions.acquire();
  io.cursorActions.addUpdates(touches);
  io.cursorActions.release();
}

void keyPressed() {
  while(draw2Active) { delay(1); } //wait until draw2 isn't active
  keyPressedActive++;              //increment the number of active keypressed processes
  if(io.typer!=null) {
    if(keyCode==66 && key==10) { hitEnter(); } //if we press enter, hit enter
    else { io.keyPresser(key, keyCode, true); }
  }
  
  if(key==CODED && keyCode==  SHIFT) { io.shiftHeld = true; } //if the shift key is held down, shiftHeld becomes true
  //if(key==CODED && keyCode==CONTROL) { io.ctrlHeld = true; } //if the ctrl key is held down, ctrlHeld becomes true
  
  keyPressedActive--; //decrement the number of active keyPressed processes
  
  //println("Key event:", key, int(key), keyCode);
}

void keyReleased() {
  io.keyReleaser(key, keyCode);
}






/*Action typeAnsPrefix(final char inp) { return new Action() { public void act() { if(io.typer!=null) {
  if(io.typer==query && io.typer.size()==0) { io.typer.insert("Ans"+inp); }
  else { io.typer.type(inp); }
} } }; }*/
