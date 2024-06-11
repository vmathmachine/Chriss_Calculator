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
          selectOnRelease=true ; //if true, button only registers release if it was selected when you released it (if false, moving your mouse out of the hitbox won't deselect it)
  
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
  
  Button setFills  (final color a, final color b, final color c) { progress.  fill.put(State.DEAD,a); progress.  fill.put(State.HOVER,b); progress.  fill.put(State.PRESS,c); return this; }
  Button setStrokes(final color a, final color b, final color c) { progress.stroke.put(State.DEAD,a); progress.stroke.put(State.HOVER,b); progress.stroke.put(State.PRESS,c); return this; }
  Button setTimings(final float a, final float b, final float c) { progress.duration.put(State.DEAD,round(1000*a)); progress.duration.put(State.HOVER,round(1000*b)); progress.duration.put(State.PRESS,round(1000*c)); return this; }
  
  Button setFills  (final color a, final color c) { progress.  fill.put(State.DEAD,a); progress.  fill.put(State.HOVER,lerpColor(a,c,0.5,RGB)); progress.  fill.put(State.PRESS,c); return this; }
  Button setStrokes(final color a, final color c) { progress.stroke.put(State.DEAD,a); progress.stroke.put(State.HOVER,lerpColor(a,c,0.5,RGB)); progress.stroke.put(State.PRESS,c); return this; }
  
  Button setFills  (final color a) { progress.  fill.put(State.DEAD,a); progress.  fill.put(State.HOVER,a); progress.  fill.put(State.PRESS,a); return this; }
  Button setStrokes(final color a) { progress.stroke.put(State.DEAD,a); progress.stroke.put(State.HOVER,a); progress.stroke.put(State.PRESS,a); return this; }
  
  Button setStroke(final boolean s) { super.setStroke(s); if(!stroke) { setStrokes(0,0,0); } return this; }
  
  Button setOnClick(final Action act) { onPress=act; return this; } //sets the behavior when clicked
  Button setOnRelease(final Action act) { onRelease=act; return this; } //sets the behavior when released
  Button setOnHeld(final Action act, final float... hold) { //sets the behavior when held down for a certain amount of time
    onHeld=act; //set hold down behavior
    if(hold.length>0) { holdTimer=round(1000*hold[0]); } //if specified, set how long it has to be held down
    return this; //return result
  }
  
  Button setPalette(final Button b) { //sets the color palette to be a perfect match of the inputted button
    progress.fill   = (HashMap<State,Integer>)b.progress.  fill.clone(); //clone the fill values
    progress.stroke = (HashMap<State,Integer>)b.progress.stroke.clone(); //clone the stroke values
    stroke = b.stroke;             //set whether it even has a stroke
    strokeWeight = b.strokeWeight; //set its stroke weight
    return this;                   //return result
  }
  
  Button setOnClickListener(final Action act) { return setOnClick(act); } //does the same thing as setOnClick, but given a different name for ease of use for those comfortable with android studio
  
  Button disable() { progress.curr = State.DISABLED; return this; }
  Button  enable() { progress.curr = State.DEAD;     return this; }
  
  ///////////////////////// DRAWING/DISPLAY /////////////////////////
  
  void setDrawingParams(final PGraphics graph) {
    graph.fill(progress.getFill());
    if(stroke) { graph.strokeWeight(strokeWeight); graph.stroke(progress.getStroke()); } else { graph.noStroke(); }
  }
  
  
  //////////////////////// REACTORS ////////////////////////////////
  
  //returns whether the cursor is in its hitbox
  boolean respondToChange(final Cursor curs, final byte code, boolean selected) { //responds to change in the cursor (code tells us what kind of change. 0=release, 1=press, 2=move, 3=drag) (select tells us if the cursor is already touching something)
    if(progress.curr==State.DISABLED) { return false; } //if disabled, do nothing
    
    boolean hitbox = hitbox(curs); //record whether the cursor is in this button
    
    if(cursors.get(curs) == null) { //if this cursor ISN'T pressing the button:
      if(hitbox && !selected) { //first, make sure the cursor is in the hitbox AND hasn't already selected something else
        if(code==1) {              //if the cursor just pressed:
          cursors.put(curs, true); //push this cursor to the list, with hold being true
          onPress.act();           //perform the onPress event
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
    
    //TODO implement the press & hold feature
    //TODO make it so different mouse buttons can do different things
    return hitbox;
  }
  //potential brainbending glitch: what happens if you do something with a button, then it disappears? Like, you scroll away and can no longer see it?
  
  
  void updateProgressor() { //updates the click progressor
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

interface Action { void act(); }

static Action emptyAction = new Action() { public void act() { } }; //empty action

//Action typeAction(final InputCode inp) { return new Action() { public void act() { if(io.typer!=null) { io.typer.readInput(inp); } } }; }



static class ClickProgressor { //a class specifically dedicated to measuring and tracking the progress of the color change in a button
  
  /////////////////// ATTRIBUTES //////////////////////////
  
  State curr=State.DEAD; //current state
  long lastEvent;   //time of last event in milliseconds
  color lastFill;   //the color it was at the start of this
  color lastStroke; //same, but for stroke
  
  HashMap<State,Integer>     fill = new HashMap<State,Integer>(4); //the fill colors when not pressed, hovered over, and pressed
  HashMap<State,Integer>   stroke = new HashMap<State,Integer>(4); //the stroke colors when not pressed, hovered over, and pressed
  HashMap<State,Integer> duration = new HashMap<State,Integer>(4); //the time it takes to fully switch to a particular state
  
  //////////////////// CONSTRUCTORS //////////////////////
  
  ClickProgressor() {  }
  //TODO make this more privatized, if appropriate
  
  //////////////////// GETTERS ////////////////////////////
  
  private color getColor(color lastColor, HashMap<State, Integer> colorMap) {
    if(duration.get(curr)==0) { return colorMap.get(curr); } //if transition is instantaneous, return the current color
    
    long time = System.currentTimeMillis();                      //find the current time
    float progress = (time-lastEvent)/(float)duration.get(curr); //divide the time passed by the total time it takes
    progress = constrain(progress,0,1);                          //constrain to the range 0-1
    
    return lerpColor(lastColor,colorMap.get(curr),progress,RGB); //return the lerping between the two colors
  }
  
  color getFill() { return getColor(lastFill, fill); } //gets current fill
  
  color getStroke() { return getColor(lastStroke, stroke); } //gets current stroke
  
  //////////////////// PROGRESSION ///////////////////////
  
  void update(final State state) { //initiates a new event & updates accordingly
    if(state==curr) { return; } //if this state is exactly the same as the old state, DO NOTHING
    
    lastFill = getFill(); lastStroke = getStroke(); //update the initial stroke and fill
    lastEvent = System.currentTimeMillis();         //set the time of the event
    curr = state;                                   //lastly, update the state
  }
}
