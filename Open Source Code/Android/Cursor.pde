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
  
  int getId() { return id; }
  
  boolean left  () { return (press&4)==4; }
  boolean center() { return (press&2)==2; }
  boolean right () { return (press&1)==1; }
  boolean allPressed() { return press==7; }
  boolean anyPressed() { return press!=0; }
  
  Box getSelect() { return select; }
  
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
  
  void setSelect(final Box box) { //sets which box this cursor is selecting
    if(select instanceof Panel) { ((Panel)select).release(this); } //if it was a panel, start a release event
    if(   box instanceof Panel) { ((Panel)   box).press  (this); } //if it is a panel, start a press event
    if(box==null && select instanceof Textbox.CursorMover) { //if it was a cursor mover, AND we're swapping to null:
      ((Textbox.CursorMover)select).release(this);           //perform the release event on it, allowing us to move the text cursor wherever we want
    }
    select = box;     //finally, set select
    seLocked = false; //unlock the cursor (not yet, I wanna see the glitch)
  }
  
  ////////////// DEFAULT FUNCTIONS //////////////////
  
  @Override
  public Cursor clone() {
    Cursor result = new Cursor(id,x,y); result.dx=dx; result.dy=dy; result.ex=ex; result.ey=ey; result.press=press;
    result.active=active; result.select=select; result.seLocked=seLocked; result.xi=xi; result.yi=yi;
    return result;
  }
}
