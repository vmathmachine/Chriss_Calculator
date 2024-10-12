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
  float xi, yi; //initial x and y, the position it was on the last time it was pressed down
  
  ///////////////////// CONSTRUCTORS ////////////////////
  
  Cursor() { }
  
  Cursor(float x_, float y_) { x=dx=ex=x_; y=dy=ey=y_; }
  
  Cursor(int id_, float x_, float y_) { this(x_,y_); id=id_; }
  
  /////////////////// GETTERS ///////////////////////
  
  int getId() { return id; }
  
  boolean left  () { return (press&4)==4; }
  boolean center() { return (press&2)==2; }
  boolean right () { return (press&1)==1; }
  boolean allPressed() { return press==7; }
  boolean anyPressed() { return press!=0; }
  
  //////////////// MUTATORS ///////////////////////
  
  Cursor setId(final int i) { id=i; return this; }
  
  void updatePos(float mouseX, float mouseY) { ex=x; ey=y; x=mouseX; y=mouseY; } //updates position
  
  void press(int mouseButton) { switch(mouseButton) {
    case LEFT: press|=4; break; case CENTER: press|=2; break; case RIGHT: press|=1;
  } xi=x; yi=y; }
  
  void release(int mouseButton) { switch(mouseButton) {
    case LEFT: press&=~4; break; case CENTER: press&=~2; break; case RIGHT: press&=~1;
  } }
  
  void press  () { press  (LEFT); } //Press/release w/out specifying button.
  void release() { release(LEFT); } //LEFT is default button
  void move() { }
  void drag() { }
  
  ////////////// DEFAULT FUNCTIONS //////////////////
  
  @Override
  public Cursor clone() {
    Cursor result = new Cursor(id,x,y); result.dx=dx; result.dy=dy; result.ex=ex; result.ey=ey; result.press=press;
    result.active=active; result.xi=xi; result.yi=yi;
    return result;
  }
}

public static class UICursor extends Cursor { //the Cursor, adapted to also be integrated into the UI
  
  Box select = null;        //the behavior of this cursor and how it interacts with UI elements, characterized by the object it touched when it was most recently pressed. More specifically, that object's class
  boolean seLocked = false; //(select locked)if true, select promotion cannot occur, as the current select is locked (becomes false when we deselect)
  
  Mmio mmio; //the UI module this is associated with
  
  UICursor(Mmio io) { super(); mmio=io; }
  
  UICursor(Mmio io, float x_, float y_) { super(x_,y_); mmio=io; }
  
  UICursor(Mmio io, int id_, float x_, float y_) { super(id_, x_,y_); mmio=io; }
  
  void setSelect(final Box box) { //sets which box this cursor is selecting
    if(select instanceof Panel) { ((Panel)select).release(this); } //if it was a panel, start a release event
    if(   box instanceof Panel) { ((Panel)   box).press  (this); } //if it is a panel, start a press event
    /*if(box==null && select instanceof Textbox.CaretMover) { //if it was a caret mover, AND we're swapping to null:
      ((Textbox.CaretMover)select).release(this);           //perform the release event on it, allowing us to move the text caret wherever we want
    }*/
    select = box;     //finally, set select
    seLocked = false; //unlock the cursor
  }
  
  Box getSelect() { return select; }
  
  void setSelectQuietly(final Box box) { //sets the box w/out pressing or releasing
    select = box;
    seLocked = false;
  }
  
  @Override public UICursor clone() {
    UICursor result = new UICursor(mmio,id,x,y); result.dx=dx; result.dy=dy; result.ex=ex; result.ey=ey; result.press=press;
    result.active=active; result.select=select; result.seLocked=seLocked; result.xi=xi; result.yi=yi;
    return result;
  }
  
  @Override public void press(int mouseButton) { //override the press functionality
    if(press==0) { //if the cursor was previously not pressed
      mmio.setCursorSelect(this); //set the cursor select to whatever it's selecting
    }
    super.press(mouseButton); //press the correct button
    
    mmio.updateButtons(this, (byte)1, false); //update the buttons, with code 1 for pressing
    
    if(mmio.typer!=null && mmio.typer.selectMenu!=null && select!=mmio.typer.selectMenu && (select==null || select.parent!=mmio.typer.selectMenu)) {
      mmio.typer.removeSelectMenu(); //if there's a typer with a select menu, the cursor isn't selecting it, and the cursor isn't selecting a button on it, remove the select menu
    }
  }
  
  @Override public void release(int mouseButton) { //override the release functionality
    super.release(mouseButton); //release the correct button
    
    mmio.updateButtons(this, (byte)0, false); //update the buttons, with code 0 for releasing
    //TODO make this compatible with multiple mouse buttons being pressed & released
    
    if(press==0) {     //if not pressing anymore
      setSelect(null); //set select for the just-released cursor to null
    }
    
    if(mmio.typer!=null && mmio.typer.hMode==Textbox.HighlightMode.MOBILE && mmio.typer.selectMenu==null && mmio.typer.highlighting) {
      mmio.typer.addSelectMenu(); //if there's a typer that's highlighting (on mobile), but has no select menu, give it a select menu
    }
  }
  
  @Override public void move() {
    mmio.updateButtons(this, (byte)2, false); //update the buttons, with code 2 for moving
  }
  
  @Override public void drag() {
    Mmio.attemptSelectPromotion(this);        //attempt select promotion
    mmio.updateButtons(this, (byte)3, false); //update the buttons, with code 3 for dragging
  }
}

public static class CursorList<C extends Cursor> implements Iterable<C> { //a class for storing cursors
  HashMap<Integer, C> cursors = new HashMap<Integer, C>(); //index each cursor by their IDs
  
  CursorList() { } //initialized to be empty
  
  @Override
  public Iterator<C> iterator() { return new Iterator() { //this iterator basically iterates through the hashmap but ignores the IDs
    private Iterator<Map.Entry<Integer,C>> iter = cursors.entrySet().iterator(); //iterator for the hashmap
    @Override public C next() {
      return iter.next().getValue(); //iterate the iterator & return the cursor
    }
    @Override public boolean hasNext() {
      return iter.hasNext(); //next exists iff it exists for iter
    }
  }; }
  
  boolean has(int id) { return cursors.containsKey(id); } //whether it has this particular ID
  
  void add(C cursor) { cursors.put(cursor.id, cursor); } //adds a cursor to the list
  void remove(C cursor) { cursors.remove(cursor.id); }   //removes a cursor from the list
  
  C get(int id) { return cursors.get(id); } //grabs the cursor with the given ID
  
  int size() { return cursors.size(); }
}

public static class CursorAction { //a pending cursor action (addition or removal of a cursor)
  Cursor cursor; //the cursor to add or remove
  byte type;     //0=remove, 1=add
  float x, y;    //the position at which this was released (if it was released)
  
  CursorAction(Cursor c, byte ty) {
    cursor = c; type=ty;
  }
  
  CursorAction setPos(float x_, float y_) { x=x_; y=y_; return this; }
  
  void execute(CursorList cursors) {
    switch(type) {
      case 0: { //release
        cursors.remove(cursor); //remove the cursor from the list
        cursor.release(LEFT); //perform on-released functionality
      } break;
      case 1: { //press
        cursor.press(LEFT);  //perform on-pressed functionality
        cursors.add(cursor); //add the cursor to the list
      } break;
    }
  }
}

public static class CursorActionQueue { //a queue of pending cursor actions
   
   CursorList<?> cursors; //a link to the current list of cursors
   
   private HashMap<Integer, Object[]> postUpdate = new HashMap<Integer, Object[]>(); //list of all the cursors that will exist once we've executed the queue of actions (mapping IDs to the Cursors and what position we expect them to be in)
   
   ArrayList<CursorAction> queue = new ArrayList<CursorAction>(); //queue of all the actions that will be performed
   
   Mmio mmio;
   
   Semaphore semaphore = new Semaphore(1);
   
   void acquire() {
     try { semaphore.acquire(); }
     catch(InterruptedException ex) { Thread.currentThread().interrupt(); }
   }
   void release() { semaphore.release(); }
   
   
   CursorActionQueue(final CursorList cursors_, final Mmio io) {
     cursors = cursors_; //set the current cursor list
     mmio = io;
     
     for(Cursor cursor : cursors) { //loop through all cursors to set our initial state
       postUpdate.put(cursor.id, new Object[] {cursor, cursor.x, cursor.y}); //map each ID to the corresponding cursor and initial position
     }
   }
   
   void addUpdates(final TouchEvent.Pointer[] touches) {
     
     //now, first, we see if there are any IDs that are in touches but not in postUpdate:
     for(TouchEvent.Pointer touch : touches) { //loop through all touches
       if(!postUpdate.containsKey(touch.id)) { //whichever ones aren't part of the existing cursor list
         addPress(touch.id, touch.x, touch.y); //add a corresponding press event
       }
     }
     
     //next, we see if there are any IDs that are in postUpdate but not in touches
     LinkedList<Object[]> releaseList = new LinkedList<Object[]>(); //we have to add them to a list and THEN act on them (to avoid concurrency issues)
     for(Map.Entry<Integer,Object[]> entry : postUpdate.entrySet()) { //loop through all entries
       int id = entry.getKey(); //grab the id
       boolean found = false;   //whether we find the ID
       for(TouchEvent.Pointer touch : touches) {   //now see if that ID shows up anywhere
         if(touch.id==id) { found = true; break; } //if it does, set flag & break
       }
       if(!found) { //if not found,
         releaseList.add(entry.getValue()); //add this to the list of things that need to be released
       }
     }
     
     for(Object[] obj : releaseList) { //now, loop through all the things we agreed to release
       addRelease((Cursor)obj[0], (Float)obj[1], (Float)obj[2]); //add a release operation for all of them
     }
   }
   
   void clear() { queue.clear(); } //clears the queue
   
   void performUpdates(TouchEvent.Pointer[] touches) { //take all the pending updates we created and apply them
     
     for(CursorAction action : queue) { //loop through all the pending actions in order
       action.execute(cursors);         //execute each action
     }
     clear(); //clear the queue
     
     for(TouchEvent.Pointer touch : touches) {
       
       Cursor cursor = cursors.get(touch.id);
       if(cursor==null) { println("fuck"); continue; } //HACK (temporary)
       if(cursor.x!=touch.x || cursor.y!=touch.y) {
         cursor.drag();
         cursor.updatePos(touch.x,touch.y);
       }
     }
   }
   
   boolean addPress(int id, float x, float y) {
     if(postUpdate.containsKey(id)) { println("well someone messed up (in addPress)"); return false; } //if this ID is already contained, return false
     
     UICursor toAdd = new UICursor(mmio, id, x,y); //create a cursor to add
     queue.add(new CursorAction(toAdd, (byte)1)); //add the press action to the queue
     
     postUpdate.put(id, new Object[] {toAdd, x,y}); //and map this ID to the cursor and its coordinates
     
     return true; //return true to indicate success
   }
   
   boolean addRelease(Cursor cursor, float x, float y) {
     if(!postUpdate.containsKey(cursor.id)) { println("well someone messed up (in addRelease)"); return false; } //if this ID isn't contained already, return false
     
     queue.add(new CursorAction(cursor, (byte)0)); //add the release action to the queue
     
     postUpdate.remove(cursor.id); //remove this cursor
     
     return true; //return true
   }
}
