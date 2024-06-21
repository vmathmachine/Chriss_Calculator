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
  static float timing1=0.03, timing2=0.03, timing3=0.03; //the preferred timings for buttons
  static float xBuff=10, yBuff=5; //the expected buffer thickness between the walls and the text inside a textbox
  
  
  
  /////////////////////////// CONSTRUCTORS ///////////////////////////////
  
  Mmio(final PApplet a) {
    app = a; mmio = this;
  }
  
  Mmio(final PApplet a, float x2, float y2, float w2, float h2) {
    super(x2,y2,w2,h2);
    app = a; mmio = this;
  }
  
  ///////////////////////// GETTERS/SETTERS //////////////////////////////
  
  void setCursorSelect(Cursor curs) { //sets what the cursor is selecting, ASSUMING the cursor was JUST pressed down
    Box box =  this.getCursorSelect(curs); //get the box this cursor is selecting, if any
    curs.setSelect(box);                   //set select to whatever we're pressing
  }
  
  static void setDefaultButtonTimings(final float a, final float b, final float c) {
    timing1=a; timing2=b; timing3=c;
  }
  
  static void setDefaultButtonTimings(final float t) { timing1=timing2=timing3 = t; }
  
  void setTyper(Textbox t) { //sets typer
    typer = t;
  }
  
  
  ///////////////////////// DRAWING/DISPLAY ///////////////////////////////
  
  void display(PGraphics graph, float buffX, float buffY) {
    if(!active) { return; } //special case: io is inactive, don't display
    
    //first, record all the PGraphics's original drawing parameters
    final boolean fill2 = graph.fill, stroke2 = graph.stroke;
    final color fillColor2 = graph.fillColor, strokeColor2 = graph.strokeColor;
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
  
  void display() { display(app.g,0,0); }
  
  //////////////////////// SELECT PROMOTION //////////////////////
  
  //here, we have a feature I call "select promotion", whereby, if you select a box (with certain exceptions), then move your mouse enough, your select will be
  //"promoted" to the parent panel. If that panel can't be dragged, you go to that panel's parent. So on and so forth until you reach one that drags or you
  //surpass the mmio and reach null.
  
  static boolean attemptSelectPromotion(Cursor curs) { //looks at a cursor and goes through the process of seeing if it can select promote and then potentially doing it, returning true if it did
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
        select.mmio.deselectAllButtons(curs); //force the cursor to deselect all buttons
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
  
  void updateCursorsAndroid(TouchEvent.Pointer[] touches) {
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
    }
    for(Cursor curs : subs) { //to account for buttons released,
      curs.release(LEFT);
      updateButtons(curs, (byte)0, false);
      curs.setSelect(null);
    }
    for(Cursor curs : movs) { //and to account for cursors moved
      attemptSelectPromotion(curs);
      updateButtons(curs, (byte)3, false);
    }
  }
  
  void keyPresser(char key, int keyCode, boolean snap) { //event performed every time a key is pressed
    if(typer!=null) {
      //if(keyCode==66 && key==10) { hitEnter(); } else //Android only, since their enter button is fucked
      switch(key) {
        case CODED: switch(keyCode) {
          case LEFT:
            if(ctrlHeld) { typer.ctrlLeft(); }
            else { typer.moveCursorBy(-1,true,snap,true); }
          break;
          case RIGHT:
            if(ctrlHeld) { typer.ctrlRight(); }
            else { typer.moveCursorBy(1,true,snap,true); }
          break;
          case 36: typer.moveCursorTo(0,true,snap,true); break; //home
          case 35: typer.moveCursorTo(typer.size(),true,snap,true); break; //end
          
          case BACKSPACE: { //(Android only) Backspace is a keyCode rather than a key. Also DELETE is the same as BACKSPACE
            if(ctrlHeld) { typer.ctrlBackspace(true,snap,true); }
            else         { typer.backspace(true,snap,true); }
          } break;
        } break;
        //case 0: switch(keyCode) {
        //  case 2: typer.moveCursorTo(0,true,snap,true); break;
        //  case 3: typer.moveCursorTo(typer.size(),true,snap,true); break;
        //} break;
        
        //case    DELETE: {
        //  if(ctrlHeld) { typer.ctrlDelete(true,snap,true); }
        //  else         { typer.delete(true,snap,true); }
        //} break;
        //case BACKSPACE: {
        //  if(ctrlHeld) { typer.ctrlBackspace(true,snap,true); }
        //  else         { typer.backspace(true,snap,true); }
        //} break;
        
        case 'a'-96: break; //ctrl+A
        case 'c'-96: break; //ctrl+C
        case 'v'-96: { //ctrl+V
          String text = getTextFromClipboard();
          if(text!=null) { typer.insert(text); }
        } break;
        case 'x'-96: break; //ctrl+X
        case 'y'-96: break; //ctrl+Y
        case 'z'-96: break; //ctrl+Z
        
        default:
          if(key<='z'-96) { break; } //if it's a CTRL key, don't type that
          
          typer.type(key,true,snap,true); //otherwise, type it
        break;
      }
    }
    
    if(key==CODED && keyCode==  SHIFT) { shiftHeld = true; } //if the shift key is held down, shiftHeld becomes true
    //if(key==CODED && keyCode==CONTROL) {  ctrlHeld = true; } //if the  ctrl key is held down,  ctrlHeld becomes true
    
    updatePressCount(); //reset all button press counts to 0
  }
  
  void keyReleaser(char key, int keyCode) { //event performed every time a key is released
    if(key==CODED) { //if coded:
      if     (keyCode==  SHIFT) { shiftHeld=false; } //SHIFT: release shift
      //else if(keyCode==CONTROL) {  ctrlHeld=false; } //CTRL : release ctrl
      else if(typer!=null && keyCode==155) { typer.insert^=true; } //insert: change insert setting
    }
    else if(typer!=null && key==0 && keyCode==26) { typer.insert^=true; }
    
    updatePressCount(); //reset all button press counts to 0
  }
  
  void updatePanelScroll(Cursor curs) {
    if(wheelEventX!=0 || wheelEventY!=0) { updatePanelScroll(curs, wheelEventX, wheelEventY); }
  }
  
  void updateCursorDPos() { //updates the previous draw cycle positions of each cursor
    for(Cursor curs : cursors) {      //loop through all cursors
      curs.dx=curs.x; curs.dy=curs.y; //set previous positions equal to current positions
    }
  }
  
  void updateButtonHold(long time, long timePrev) { //updates all the buttons being held down
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
  
  ///////////////////// BUFFERS /////////////////////////////////
  
  void ensureBufferSupport(int x, int y) { //expands buffer dimensions to that it can support an object at the given position
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
  
  Buffer addBuffer(int x, int y) { //adds new buffer (dimensions 2^x x 2^y) to the list, returns newly added buffer
    ensureBufferSupport(x,y); //expand the dimensions so we can support the new buffer
    Buffer buff = new Buffer(app,1<<x,1<<y); //initialize new buffer
    buffers.get(x).get(y).add(buff);         //add to the arraylist
    return buff;                             //return result
  }
  
  void bufferGarbageCollect() { //performs a garbage collection algorithm on the buffers
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
  
  int getBufferNumber() { //gets number of buffers
    int num = 0;
    for(ArrayList<ArrayList<Buffer>> buff1 : buffers) for(ArrayList<Buffer> buff2 : buff1) { num+=buff2.size(); }
    return num;
  }
  
  long approxBufferRAM() { //gets approximate RAM used by buffers
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
  
  float getTextWidth(String txt, float siz) { //gets the width of a particular string at a particular size, without changing anything
    Buffer buff = loadBuffer(this, (byte)0, (byte)0); //load a 1x1 PGraphics object
    buff.beginDraw();         //begin draw
    buff.graph.textSize(siz); //set text size
    float wid = buff.graph.textWidth(txt); //get the width
    buff.endDraw();   //end draw
    buff.useNt();     //stop using buffer
    return wid;       //return the width
  }
  
  static float getTextHeight(float siz) { return siz*1.164+0.902; } //gets the height of a text of a specific size, assuming there are no "\n"s
  
  static float invTextHeight(float siz) { return 0.859*siz-0.775; } //gets the text size needed for a particular text height
  
  static float getTextHeight(String txt, float siz) {
    return getTextHeight(siz)*getLines(txt);
  }
  
  static int getLines(String txt) {
    int lines = 1; for(int n=0;n<txt.length();n++) { if(txt.charAt(n)=='\n') { ++lines; } }
    return lines;
  }
  
  //int[] getTypingCode() { return typer.insert ? InputCode.INSERT : InputCode.OVERTYPE; }
}

/*public static class Pointer {
  public int id;
  public float x, y;
  public float area;
  public float pressure;
}*/