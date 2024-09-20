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
  color surfaceFillColor;         //fill color of surface
  
  float surfaceXi=0, surfaceYi=0;       //"initial" position of surface, position when a touch was initialized
  ArrayList<Cursor> pointers = new ArrayList<Cursor>(); //arraylist of all the cursors that are dragging around this surface
  //this is called pointers and not cursors because MMIO already has an arraylist called cursors, and it's used for something else. We don't want that to override this
  
  //targeting attributes:
  SurfaceTarget target = null; //the surface position we target towards (null means we aren't targeting right now)
  float xSpace=Mmio.xBuff, ySpace=Mmio.yBuff; //the breathing space we give when something is on the far edge. For targeting purposes, if something is less than xSpace,ySpace from the edge, it's considered too close
  
  //physics attributes
  float airFric = 3; //coefficient of air friction, in Hz
  float kinFric = 0; //coefficient of kinetic friction, multiplied by normal force, in pix/s^2
  float minVel = 20;  //when velocity is below this (in pix/s), we set it to 0
  boolean sliding = false; //true when the panel is uniformly, linearly sliding without any external forces until it hits the edge
  
  //// specific options and key parameters
  
  boolean canScrollX = true, canScrollY = true; //whether you can scroll with the mouse
  
  DragMode dragModeX = DragMode.NONE, dragModeY = DragMode.NONE; //the drag mode for this panel, both in the x and y directions. On PC, dragging usually doesn't exist
  float promoteDist = 25; //how many pixels you have to move your cursor from its initial position to trigger select promotion
  
  float pixPerClickH, pixPerClickV; //how many pixels you move per movement of the mouse wheel (both horizontally & vertically)
  
  ////////////////////// CONSTRUCTORS //////////////////////
  
  Panel() { super(); fill=false; } //by default, you don't fill in the window.
  
  Panel(final float x2, final float y2, final float w2, final float h2, final float w3, final float h3) { super(x2,y2,w2,h2); surfaceX=surfaceY=0; surfaceW=w3; surfaceH=h3; fill=false; initPixPerClick(); } //constructor w/ dimensional parameters
  
  Panel(final float x2, final float y2, final float w2, final float h2) { this(x2,y2,w2,h2,w2,h2); } //constructor w/ fewer dimensional parameters
  
  ////////////////////// GETTERS //////////////////////
  
  float getSurfaceX() { return surfaceX; } //gets position of surface (in x direction)
  float getSurfaceY() { return surfaceY; } //gets position of surface (in x direction)
  float getSurfaceVx() { return surfaceVx; } //gets x velocity of surface
  float getSurfaceVy() { return surfaceVy; } //gets y velocity of surface
  float getSurfaceW() { return surfaceW; } //gets width of surface
  float getSurfaceH() { return surfaceH; } //gets height of surface
  float getObjSurfaceX() { return getObjX()+surfaceX; } //gets objective position of surface (in x direction)
  float getObjSurfaceY() { return getObjY()+surfaceY; } //gets objective position of surface (in y direction)
  
  float getSurfaceXRelTo(Panel p) { return getXRelTo(p)+surfaceX; } //gets relative position of surface (in x direction)
  float getSurfaceYRelTo(Panel p) { return getYRelTo(p)+surfaceY; } //gets relative position of surface (in y direction)
  
  boolean canScrollX() { return canScrollX; } //whether or not you can scroll with the mouse in each direction
  boolean canScrollY() { return canScrollY; }
  
  Box getChild(final int ind) { return children.get(ind); } //returns child at particular index
  int numChildren()           { return children.size();   } //returns number of children
  
  ////////////////////// MUTATORS //////////////////////
  
  Panel setSurfaceW(final float w2) { surfaceW=w2; return this; }
  Panel setSurfaceH(final float h2) { surfaceH=h2; return this; }
  Panel setSurfaceDims(final float w2, final float h2) { surfaceW=w2; surfaceH=h2; return this; }
  Panel setSurfaceV(final float x2, final float y2) { surfaceVx=x2; surfaceVy=y2; return this; }
  
  Panel setScrollX(final float x2) { surfaceX=x2; return this; }
  Panel setScrollY(final float y2) { surfaceY=y2; return this; }
  Panel setScroll(final float x2, final float y2) { surfaceX=x2; surfaceY=y2; return this; }
  
  Panel setScrollableX(final boolean s) { canScrollX = s; return this; }
  Panel setScrollableY(final boolean s) { canScrollY = s; return this; }
  Panel setScrollable(final boolean sx, final boolean sy) { canScrollX = sx; canScrollY = sy; return this; }
  
  Panel setSurfaceFill(boolean s) { surfaceFill=s; return this; }
  Panel setSurfaceFill(color s) { surfaceFillColor=s; return this; }
  
  void shiftSurface(final float x2, final float y2) {
    surfaceX = constrain(surfaceX+x2, w-surfaceW, 0);
    surfaceY = constrain(surfaceY+y2, h-surfaceH, 0);
  }
  
  Panel setPixPerClickH(final float h) { pixPerClickH = h; return this; } //sets the rate of pixels scrolled per click of the mouse (negative means inverted scrolling)
  Panel setPixPerClickV(final float v) { pixPerClickV = v; return this; } //we need to be able to set it horizontally and vertically
  Panel setPixPerClick(final float h, final float v) { pixPerClickH = h; pixPerClickV = v; return this; }
  
  Panel setDragMode(final DragMode sx, final DragMode sy) { dragModeX = sx; dragModeY = sy; return this; } //sets the dragging mode
  
  ////////////////////// DRAWING/DISPLAY //////////////////////
  
  void display(PGraphics graph, float buffX, float buffY) {
    
    if(surfaceFill) { graph.fill(surfaceFillColor); } else { graph.noFill(); } //set drawing attributes
    graph.noStroke(); //no stroke, we draw the border afterward
    
    graph.rect(getX()-buffX, getY()-buffY, w, h, r); //draw the surface background, constrained to within the window
    
    for(Box b : this) { if(b.active) {      //loop through all active children
      displayChild(b, graph, buffX, buffY); //display each child
    } }
    
    extraDisplay(graph, buffX, buffY); //run any extra functionality we might want to run
    
    super.display(graph, buffX, buffY); //finally, draw the window over it all
  }
  
  void extraDisplay(PGraphics graph, float buffX, float buffY) { } //is used by other, derived classes to draw extra stuff
  
  void displayChild(Box b, PGraphics graph, float buffX, float buffY) { //displays the child
    
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
  
  static Buffer loadBuffer(Mmio mmio, byte x, byte y) { //Loads smallest buffer of at least size 2^x x 2^y from mmio. If none are available, it makes one.
    
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
  
  
  boolean updateButtons(Cursor curs, final byte code, boolean selected) { //looks through all visible buttons in a panel and updates accordingly (selected = whether the cursor has already selected something)
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
  boolean updatePanelScroll(Cursor curs, int eventX, int eventY) { //PC only (return whether an update actually occurred)
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
  
  void updatePanelDrag() {
    updateDrag(); //update dragging mechanics TODO fix whatever the fuck happens when we drag one panel then drag a panel inside it
    
    for(Box b : this) { //loop through all the boxes in the panel
      if(b instanceof Panel) { ((Panel)b).updatePanelDrag(); } //for each panel, update their panel drags as well
    }
  }
  
  void updatePhysicsRecursive(float delay) {
    updatePhysics(delay); //update physics
    
    for(Box b : this) { //loop through all boxes in the panel
      if(b instanceof Panel) { ((Panel)b).updatePhysicsRecursive(delay); } //for each panel, update their physics as well
    }
  }
  
  void updateCaretsRecursive() {
    for(Box b : this) { //loop through all boxes in this panel
      if(b instanceof Panel) { ((Panel)b).updateCaretsRecursive(); } //for each panel, update their textboxes' physics as well
      if(b instanceof Textbox)  { ((Textbox)b).idlyUpdateCarets(); } //for each textbox, idly update their carets
    }
  }
  
  void deselectAllButtons(Cursor curs) { //removes curs from the cursors list of all buttons in this panel and its children
    for(Box b : this) { //loop through all children
      if     (b instanceof  Panel) { ((Panel)b).deselectAllButtons(curs); } //panel: recursively do this on the inner panels
      else if(b instanceof Button) { ((Button)b).cursors.remove(curs);    } //button: remove from cursor list
    }
  }
  
  void deselectMobileButtons(boolean mobile) { //does the same thing, but only deselects moving buttons, and also does it for all cursors (mobile = true if 1 or more parent panels are mobile)
    for(Box b : this) { //loop through all children
      if     (b instanceof Panel) { ((Panel)b).deselectMobileButtons(mobile || b.mobile); } //panel: recursively do this on inner panels, mobility becomes true the moment we enter a mobile panel
      else if(b instanceof Button && (mobile || b.mobile)) { ((Button)b).cursors.clear(); } //button: clear the cursor list, but only if the button is moving relative to the cursor
    }
  }
  
  void targetAllChildren() { //performs moveToTarget on self and all children recursively
    moveToTarget(); //update targeting system
    for(Box b : this) { if(b instanceof Panel) { //loop through all Panel children
      ((Panel)b).targetAllChildren(); //instruct each of them to target themselves and all their children
    } }
  }
  
  void updatePressCount(Button... buttons) { //resets every child/descendant button's press count to 0 (except the ones fed as parameters)
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
  
  void press(final Cursor curs) { //responds to cursor press
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
  
  void release(final Cursor curs) { //responds to cursor release
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
  
  void updateDrag() { //performs updates once per frames based on dragging functionality
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
  
  void updatePhysics(float delay) { //updates the physics (delay = how long it's been since the previous frame, in seconds)
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
  
  void freezeV() { surfaceVx = surfaceVy = 0; } //freezes velocity (sets it to 0)
  
  ////////////////////// TARGETING ////////////////////////
  
  void chooseTarget(float... focus) { //chooses a target, given that all inputted coordinates have to be in focus.
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
  
  void setTarget(float xTarget, float yTarget) { //sets the target
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
  
  void chooseTargetRecursive(float... focus) { //recursively chooses a target, both for this panel and its parent panels
    chooseTarget(focus);     //choose a target for this panel
    
    if(parent!=null && mobile) { //and, if we have a parent (and are mobile)
      PVector targ = (target==null) ? new PVector(surfaceX,surfaceY) : new PVector(target.x,target.y); //record the target, accounting for the possibility that there was no target
      
      float focus2[] = new float[focus.length];
      for(int n=0;n<focus.length;n++) { focus2[n]=focus[n] + ((n&1)==0 ? x+targ.x : y+targ.y); }
      parent.chooseTargetRecursive(focus2);
    }
  }
  
  void moveToTarget() { //moves towards and updates target TODO enable non-recursive targeting (Because, let's say for instance, you update a shitload of boxes at once, and they can't all fit on screen. See the problem?)
    if(target==null) { return; } //if there is no target, skip
    
    long time = System.currentTimeMillis(); //calculate current time
    float progress = (time-target.time)/float(SurfaceTarget.duration); //calculate targeting progress
    
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
  
  void putInBack(Box a) { //puts box in the back
    if(this==a.parent) { children.remove(a); children.add(0,a); } //if this is a's parent, remove a and put it in the back
  }
  
  void putInFront(Box a) { //puts box in the front
    if(this==a.parent) { children.remove(a); children.add(a); } //if this is a's parent, remove a and put it in the front
  }
  
  void putAOverB(Box a, Box b) { //puts the first in front of the second
    if(this!=a.parent || this!=b.parent || a==b) { return; }    //only works if they're both distinct children
    int indA = children.indexOf(a), indB = children.indexOf(b); //get indices of a and b
    if(indA < indB) { //if a was already in front of b, do nothing. Otherwise:
      children.remove(indA); children.add(indB,a); //remove a, then put it back in front of b (right where b was before)
    }
  }
  
  void putABehindB(Box a, Box b) { //puts the first behind the second
    if(this!=a.parent || this!=b.parent || a==b) { return; }    //only works if they're both distinct children
    int indA = children.indexOf(a), indB = children.indexOf(b); //get indices of a and b
    if(indA > indB) { //if a was already behind b, do nothing. Otherwise:
      children.remove(indA); children.add(indB,a); //remove a, then put it back behind b (right where b is now)
    }
  }
  
  void swapAAndB(Box a, Box b) { //swaps both boxes in positions
    if(this!=a.parent || this!=b.parent || a==b) { return; }    //only works if they're both distinct children
    int indA = children.indexOf(a), indB = children.indexOf(b); //get indices of a and b
    children.set(indA,b); children.set(indB,a);                 //move a into b and b into a
  }
  
  void moveToIndex(Box a, int ind) { //moves child box to specific position
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
  
  Iterable<Box> reverse() { return new Iterable<Box>() { //returns something you can use to iterate over the children in reverse order
    public Iterator<Box> iterator() { return new Iterator<Box>() { //the iterator returns an iterator
      int index = numChildren();                    //initial index is right after the last index
      public boolean hasNext() { return index!=0; } //has next: true if index isn't 0
      public Box next() { index--; return children.get(index); } //next: decrement index and return box at this spot
    }; }
  }; }
  
  void initPixPerClick() { pixPerClickH = w*0.025; pixPerClickV = h*0.025; } //generally, we can init scroll rate as a fraction of the window width/height
}

static class SurfaceTarget { //a class dedicated to the targeting system for targets, implemented to prevent panels from going out of bounds when they change in size and to force us to see important things
  float x, y;   //x and y coordinate of the surface once it reaches its target
  float xi, yi; //x and y coordinates initially, before we started targeting
  long time;    //the UNIX time in ms when the targeting first began. This is here because targeting isn't a sudden jolt, it has to occur over several frames
  static int duration = 120; //the time in ms for the surface to reach its target (same for all targets)
  
  SurfaceTarget(float x2, float y2, float x3, float y3, long time2) { x=x2; y=y2; xi=x3; yi=y3; time=time2; } //constructor w/ all attributes
  
  SurfaceTarget(float x2, float y2, float x3, float y3) { x=x2; y=y2; xi=x3; yi=y3; time=System.currentTimeMillis(); } //constructor w/ xs & ys, and w/ time set to current time
  
  @Override
  String toString() { return "Target: ("+xi+","+yi+")->("+x+","+y+") from UNIX time "+time; }
}

static byte outCode(float xin, float yin, float win, float hin, float wout, float hout) { //yields a 5-bit outcode describing how two boxes intersect, assuming (xout,yout)=(0,0)
  return (byte)((xin>wout || yin>hout || xin+win<0 || yin+hin<0 ? 16 : 0) | //bit 1: whether box is completely out of bounds
                                                      (xin<   0 ?  8 : 0) | //bit 2: whether left edge is left of clipping plane
                                                      (xin+win>wout ?  4 : 0) | //bit 3: whether right edge is right of clipping plane
                                                      (yin<   0 ?  2 : 0) | //bit 4: whether top edge is above clipping plane
                                                      (yin+hin>hout ?  1 : 0)); //bit 5: whether bottom edge is below clipping plane
}

static enum DragMode { NONE, NORMAL, ANDROID, IOS, SWIPE };

static int sgn(float x) { return x==0 ? 0 : x>0 ? 1 : -1; }
//the modes that you can use to drag with your cursor: no dragging, normal (no momentum), android style, iOS style, and swipe between screens (like on a home screen)

///movement modes: PC, Android, iOS, basicSmartphone
