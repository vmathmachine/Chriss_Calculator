public static class Textbox extends Panel {
  
  ////////////////////// ATTRIBUTES /////////////////////////
  
  //text
  float tx, ty; //x & y of text's top left WRT surface
  float tSize; color tFill; //text size & color
  ArrayList<SimpleText> texts = new ArrayList<SimpleText>(); //the texts themselves
  CaretMover buddy; //invisible box to allow for mouse-based/touch-based text caret placement
  Action releaseAction = emptyAction; //the action that gets performed when you press the buddy
  
  //caret
  int caret = 0;    //the position of the blinking caret
  color cStroke;    //the color of the blinking caret
  float cThick = 1; //the stroke weight of the caret
  long blink;       //the time when the blinking caret was last reset
  boolean insert=true; //true=insert, false=overtype. Inverts every time we hit the "insert" key
  
  //selection
  boolean highlighting = false; //whether we're currently highlighting text
  int anchorCaret = 0; //the position of the other end of the caret, encompassing the selected, highlighted area
  color selectColor = #0000FF; //the color of the highlighted background (blue by default)
  color handleColor = #0000FF; //the color of the text selection handles on mobile (blue by default)
  float leftHighlightBarrier, rightHighlightBarrier; //the "highlight barriers": if you drag your cursor past these barriers while highlighting, it causes the textbox to scroll in that direction
  float highlightDragSpeed = 30; //the speed at which the textbox scrolls on by when your cursor is past said barriers
  
  float handleRad;                  //radius of text handles
  static float defaultHandleRadius; //default handle radius
  Cursor dragCursor = null; //the cursor that is currently dragging the highlighted text selection (if any)
  
  enum HighlightMode { PC, MOBILE, NONE };
  HighlightMode hMode = pcOrMobile ? HighlightMode.PC : HighlightMode.MOBILE;
  SelectMenu selectMenu = null;
  
  Panel handleParent = null; //the panel that our text handles will go directly inside of
  
  ///////////////////// CONSTRUCTORS ///////////////////////
  
  Textbox(final float x2, final float y2, final float w2, final float h2) {
    super(x2,y2,w2,h2); //just run the inherited method
    
    tx=Mmio.xBuff; ty=Mmio.yBuff; //then initialize some stuff to their default values
    tSize = Mmio.invTextHeight(h2-2*Mmio.yBuff); //choose a text size with the appropriate height
    
    buddy = new CaretMover(this); //initialize our caret buddy
    
    handleRad = defaultHandleRadius; //set handle radius
    leftHighlightBarrier = 0.1*w; rightHighlightBarrier = 0.9*w;
  }
  
  ////////////////// GETTERS / SETTERS //////////////////////
  
  float getTextHeight() { return tSize*1.164+0.902; }
  
  Textbox setTextX(float x2) {
    tx=x2; xSpace=min(xSpace,tx); fixWidth();
    if(size()!=0) { texts.get(0).x = tx; for(int n=1;n<size();n++) { texts.get(n).x = texts.get(n-1).x+texts.get(n-1).w; } }
    return this;
  }
  Textbox setTextY(float y2) { ty=y2; ySpace=min(ySpace,ty); return this; }
  Textbox setTextPos(float x2, float y2) { tx=x2; ty=y2; xSpace=min(xSpace,tx); ySpace=min(ySpace,ty); fixWidth(); return this; }
  Textbox setTextYAndAdjust(float y2) { ty=y2; ySpace=min(ySpace,ty); tSize=Mmio.invTextHeight(h-2*ty); fixWidth(); return this; }
  Textbox setTextPosAndAdjust(float x2, float y2) { tx=x2; ty=y2; xSpace=min(xSpace,tx); ySpace=min(ySpace,ty); tSize=Mmio.invTextHeight(h-2*ty); fixWidth(); return this; }
  
  Textbox setTextColor (color   c) { tFill  =c;  return this; }
  Textbox setCaretColor(color   c) { cStroke=c;  return this; }
  Textbox setCaretThick(float wgt) { cThick=wgt; return this; }
  Textbox setTextSize  (float siz) { tSize=siz;  return this; }
  Textbox setTextSizeAndAdjust(float siz) { tSize=siz; ty=0.5*(h-Mmio.getTextHeight(siz)); ySpace=min(ySpace,ty); return this; }
  
  int getLeftCaret () { return min(caret, anchorCaret); }
  int getRightCaret() { return max(caret, anchorCaret); }
  
  Textbox setMargin(float x) { //sets the margin between the text & the left & right (AKA the xSpace)
    xSpace = x;       //set the x space
    setTextX(xSpace); //change the text x
    adjust();         //adjust it
    return this;      //return result
  }
  
  @Override
  Textbox setW(final float w2) { super.setW(w2); buddy.setW(w2); return this; } //when resizing width, the buddy must be resized as well
  
  @Override
  Textbox setParent(final Panel p) { super.setParent(p); buddy.mmio=mmio; return this; } //set parent is done differently here because we also have to give our buddy the same mmio as ourselves
  
  Textbox setOnRelease(final Action act) { releaseAction = act; return this; } //sets the release action
  
  void setDoubleTapTimeout(int timeout) { buddy.doubleTapTimeout = timeout; } //sets how long we wait before the double tap is done
  void setHighlightGrabDistance(float dist) { buddy.highlightGrabDistance = dist; } //set how far the mouse cursor can be from the caret in order to move it while text is highlighted
  
  void setHighlightMode(HighlightMode m) { hMode = m; } //sets how highlighting occurs
  
  void setHandleParent(Panel p) { //sets the panel our text handles go directly inside of
    if(!Mmio.isAncestorTo(p, this)) { //if this textbox isn't inside of p
      throw new RuntimeException("Cannot assign textbox's handle parent to a cousin or child panel"); //throw an exception
    }
    handleParent = p; //set our handle parent to p
  }
  
  ////////////////// DISPLAY //////////////////////
  
  @Override
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
  
  void drawCaret(PGraphics graph, float buffX, float buffY) {
    graph.stroke(cStroke); graph.strokeWeight(cThick); //set drawing parameters for caret
    float xStart = getX(caret)+surfaceX; //find x pos of caret
    if(xStart>=w) { return; } //if it's too far right, we can't draw it
    
    if(!insert) { //if overtype, we draw caret as underline
      float xEnd = (caret==size() ? getX(caret)+0.75*tSize : getX(caret+1))+surfaceX; //find x pos of right of caret
      if(xEnd>0) { //if the caret is even on screen:
        graph.line(max(xStart,0)+getX()-buffX,ty+getY()+surfaceY+getTextHeight()-buffY, min(xEnd,w)+getX()-buffX,ty+getY()+surfaceY+getTextHeight()-buffY); //draw it, with x constraints for clipping
      }
    }
    else if(xStart>0) { //otherwise, we draw caret as vertical line (again, make sure it's on screen)
      graph.line(xStart+getX()-buffX, ty+getY()+surfaceY-buffY, xStart+getX()-buffX, ty+getY()+surfaceY+getTextHeight()-buffY);
    }
  }
  
  void drawHighlight(PGraphics graph, float buffX, float buffY) { //draws the highlight rectangle behind the text
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
  
  int size() { return texts.size(); } //number of characters in the text
  
  float getX(int ind) { //obtain the pixel x-coordinate of the given caret position, relative to surface
    if(size()==0 && ind==0) { return tx; }
    if(ind==size()) { SimpleText s = texts.get(ind-1); return s.x+s.w; }
    return texts.get(ind).x;
  }
  
  float getW(int ind) { return texts.get(ind).w; } //obtain the pixel width of the character at the given position
  char getText(int ind) { return texts.get(ind).text; } //obtain the character at the given position
  
  String getText() { //obtains the contents of the text field as a plain string
    StringBuilder result = new StringBuilder();              //init to blank
    for(SimpleText txt : texts) { result.append(txt.text); } //concat each char
    return result.toString();                                //return result
  }
  
  String substring(int start, int stop) { //obtains the contents as a substring
    StringBuilder result = new StringBuilder(); //init to blank
    for(int n=start;n<stop;n++) {
      result.append(texts.get(n).text);  //concat each char
    }
    return result.toString();            //return result
  }
  
  ///////TODO replace the above /|\ mechanism with a much more efficient stringbuilder mechanism
  
  char charAt(int ind) { return texts.get(ind).text; } //obtain the character at the given position
  
  //Each of the following editing functions return the change in width of the text. It can be positive or negative.
  
  float insert(char text, int pos) { //types (using insert) a character into a certain position
    float w = mmio.getTextWidth(text+"",tSize); //get width of character
    texts.add(pos, new SimpleText(text, getX(pos), w)); //insert the character
    for(int n=pos+1;n<size();n++) { //loop through all characters after this one
      texts.get(n).x += w;          //shift their positions appropriately
    }
    return w;
  }
  
  float overtype(char text, int pos) { //types (using overtype) a character into a certain position
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
  
  float insert(String text, int pos) { //types (using insert) a string into a certain position
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
  
  float remove(int pos) { //removes the character at pos
    if(pos<0 || pos>=size()) { return 0; } //out of range: do nothing, return 0
    
    float w = getW(pos);        //find width of character we're removing
    texts.remove(pos);          //remove said character
    for(int n=pos;n<size();n++) { //loop through all characters after the one we deleted
      texts.get(n).x -= w;        //shift their positions left by the width of that deleted string
    }
    return -w; //return how much it decreased by
  }
  
  float remove(int pos1, int pos2) { //removes all characters from pos1 (inclusive) to pos2 (exclusive)
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
  
  float clear() { //clear everything
    float wTotal = getX(size())-tx; //first, calculate the width
    texts.clear(); //next, clear the texts
    return -wTotal; //finally, return the change
  }
  
  //////////////////// TYPING (PUBLIC) ////////////////////////////////////
  
  void restrictCaret() { //forces caret(s) to a valid position
    caret       = constrain(      caret,0,size());
    anchorCaret = constrain(anchorCaret,0,size());
  }
  
  void adjust(final boolean target, final boolean snap, final boolean blink) { //performs adjustments, recommended to be executed every time a text editing action is performed
    fixWidth(); //fix the surface to the correct width
    
    if(target) {      //if applicable:
      //chooseTargetRecursive(getX(caret),ty+0.5*getTextHeight()); //adjust targeting system
      chooseTargetRecursive(getX(caret),ty,getX(caret),ty+getTextHeight());                       //adjust targeting system
      if(snap && this.target!=null) { this.target.time-=SurfaceTarget.duration; moveToTarget(); } //if we want to snap to our target, we must snap to our target
    }
    
    if(blink) { resetBlinker(); } //if asked, make the caret visible
  }
  void adjust() { adjust(true,false,true); } //usually, we want to target, not snap, and make caret visible
  
  void moveCaretTo(final int pos, final boolean target, final boolean snap, final boolean blink) { //move caret to position
    caret = constrain(pos,0,size());
    adjust(target, snap, blink);
  }
  void moveCaretTo(final int pos) { moveCaretTo(pos,true,false,true); }
  
  void moveCaretBy(final int amt, final boolean target, final boolean snap, final boolean blink) { //move caret by amount
    caret = constrain(caret+amt,0,size());
    adjust(target, snap, blink);
  }
  void moveCaretBy(final int amt) { moveCaretBy(amt,true,false,true); }
  
  void insert(final char text, final boolean target, final boolean snap, final boolean blink) { //insert character to the right of caret (and move caret)
    insert(text, caret++);
    adjust(target, snap, blink);
  }
  void insert(final char text) { insert(text,true,false,true); }
  
  void insert(final String text, final boolean target, final boolean snap, final boolean blink) { //insert string to the right of caret (and move caret)
    insert(text, caret); caret+=text.length();
    adjust(target, snap, blink);
  }
  void insert(final String text) { insert(text,true,false,true); }
  
  void overtype(final char text, final boolean target, final boolean snap, final boolean blink) { //overtype character to the right of caret (and move caret)
    overtype(text, caret++);
    adjust(target, snap, blink);
  }
  void overtype(final char text) { overtype(text,true,false,true); }
  
  void type(final char text, final boolean target, final boolean snap, final boolean blink) { //either insert or overtype, depending on the mode
    if(insert) { insert(text,caret++); } else { overtype(text, caret++); }
    adjust(target, snap, blink);
  }
  void type(final char text) { type(text,true,false,true); }
  
  void delete(final boolean target, final boolean snap, final boolean blink) { //delete character right of caret
    remove(caret);
    adjust(target, snap, blink);
  }
  void delete() { delete(true,false,true); }
  
  void backspace(final boolean target, final boolean snap, final boolean blink) { //delete character left of caret (and move caret 1 left)
    if(caret==0) { return; }
    remove(--caret);
    adjust(target, snap, blink);
  }
  void backspace() { backspace(true,false,true); }
  
  void clear(final boolean target, final boolean snap, final boolean blink) { //clear entire field
    clear();
    caret = anchorCaret = 0; highlighting = false;
    adjust(target, snap, blink);
    buddy.clearHandles(); //remove any text handles
  }
  void clear2() { clear(true,true,true); } //this one is different, the default is to snap right into place, to avoid out of bounds
  
  void replace(final String text) { //replaces the entire contents of typing field with something else (TODO stop it from having graphical bugs, you know, like it being out of bounds)
    clear(); caret = 0; insert(text,0); adjust(false,false,true);
  }
  
  
  void ctrlLeft(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+left functionality, moving caret to the previous word
    if(caret!=0) { //doesn't work if caret is at beginning
      char seed = charAt(caret-1); //grab char right before caret
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      do { //repeatedly decrement caret
        --caret;
      } while(caret>0 && ident == (Character.isLetterOrDigit(seed=charAt(caret-1)) || seed=='_')); //stop when we reach 0, or when we reach a character which is a letter/number/underscore XOR the orignal was
    }
    adjust(target,snap,blink);
  }
  void ctrlLeft() { ctrlLeft(true,false,true); }
  
  void ctrlRight(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+right functionality, moving caret to the next word
    if(caret!=size()) { //doesn't work if caret is at end
      char seed = charAt(caret); //grab char in front of caret
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      do { //repeatedly increment caret
        ++caret;
      } while(caret<size() && ident == (Character.isLetterOrDigit(seed=charAt(caret)) || seed=='_')); //stop when we reach the end, or when we reach a character which is a letter/number/underscore XOR the original was
    }
    adjust(target,snap,blink);
  }
  void ctrlRight() { ctrlRight(true,false,true); }
  
  void ctrlBackspace(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+backspace functionality, removing the word to the left of the caret (then moving caret to the left)
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
  void ctrlBackspace() { ctrlBackspace(true,false,true); }
  
  void ctrlDelete(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+delete functionality, removing the word to the right of the caret
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
  void ctrlDelete() { ctrlDelete(true,false,true); }
  
  void ctrlShiftBackspace(final boolean target, final boolean snap, final boolean blink) { //performs ctrl+shift+backspace functionality, removing everything to the left of the caret (then moving the caret all the way left)
    remove(0,caret); //remove all characters before the caret
    caret = 0;       //move caret to 0
    adjust(target,snap,blink); //adjust
  }
  
  void ctrlShiftDelete(final boolean target, final boolean snap, final boolean blink) { //performs ctrl+shift+delete functionality, removing everything to the right of the caret
    remove(caret,size());      //remove all characters after the caret
    adjust(target,snap,blink); //adjust
  }
  
  
  /// INVOLVING HIGHLIGHTING ///
  
  void adjustHighlightingForArrows(boolean shiftHeld) { //performs functionality that must happen before using keys to move caret
    if(!highlighting && shiftHeld) { //if not highlighting, but holding shift:
      highlighting = true; //start highlighting
      equalizeCarets();    //set both carets to be equal
    }
    else if(highlighting && !shiftHeld) { //if highlighting, but not holding shift
      highlighting = false;       //stop highlighting
      equalizeCarets();           //set both carets to be equal
      buddy.removeHandlesLater(); //schedule handles to be removed later
    }
    else if(hasOneHandle() && !shiftHeld) { //if it has exactly one handle, and we're not holding shift
      buddy.removeHandlesLater(); //schedule handle to be removed later
    }
  }
  
  void equalizeCarets() { anchorCaret = caret; } //sets both carets to be equal
  
  void negateHighlight() {
    if(highlighting && caret == anchorCaret) { //if we changed our selection such that both carets are the same:
      highlighting = false;                    //disable highlighting
    }
  }
  
  void selectAll(boolean snap) {
    highlighting = true; //start highlighting
    anchorCaret = 0;     //move anchor caret to the beginning
    moveCaretTo(size(),true,snap,true); //move the primary caret to the end
  }
  
  void eraseSelection(boolean removeHandles) { //erases the highlighted selection
    if(highlighting) {    //if the highlighted selection exists:
      remove(getLeftCaret(),getRightCaret()); //remove everything between the two carets
      moveCaretTo(getLeftCaret()); //move the caret to the left of the two
      restrictCaret();             //restrict both carets to be in bounds
      highlighting = false;        //disable highlighting
    }
    if(removeHandles) { buddy.removeHandlesLater(); } //if asked, schedule for this textbox's handles to be removed
  }
  
  void removeSelectMenu() { if(selectMenu!=null) { //removes select menu if applicable
    selectMenu.setParent(null); selectMenu = null;
  } }
  
  void addSelectMenu() { if(selectMenu==null) { //adds select menu if there isn't already one
    selectMenu = new SelectMenu(this,caret);
  } }
  
  //TODO see if this is necessary
  void replaceSelectMenu() { //removes current select menu (if applicable) and adds a new one
    if(selectMenu!=null) { selectMenu.setParent(null); }
    selectMenu = new SelectMenu(this,caret);
  }
  
  
  void fixWidth() { surfaceW = max(w, xSpace+getX(size())); } //adjust the width to be appropriate
  
  ////////////// MISC /////////////////////
  
  void resetBlinker() { blink = System.currentTimeMillis(); }
  
  void idlyUpdateCarets() { //updates the carets while you idly hold the cursor to the far left or far right, or while pressing & holding a textbox
    
    if(hMode == HighlightMode.MOBILE) { //if in mobile mode
      final UICursor holder = buddy.getHoldCursor(); //find what cursor (if any) is holding down on our buddy
      if(holder!=null && !buddy.holdSelecting &&
         System.currentTimeMillis()-buddy.lastPressed > buddy.holdTime &&
         sq(holder.x-buddy.lastPressedX)+sq(holder.y-buddy.lastPressedY) < sq(promoteDist)) { //if a cursor is holding down on us, and is close enough to initial pos, and enough time has passed
        
        mmio.addPendingPostOperation(new Runnable() { public void run() { //add a pending operation to deselect & reselect text
          int caretBefore = caret;
          caret = buddy.cursorToCaret(holder.x); //move the caret to the position the cursor is hovering over
          boolean hadOneHandle = caret == caretBefore && hasOneHandle(); //for the sake of selection, determine whether there was a TS handle at this exact cursor position
          //If there was, or if we're highlighting, we'll place a text handle. Otherwise, we won't
          buddy.clearHandles(); //clear the handles to give us a clean slate
          buddy.processTextTouch(holder, hadOneHandle); //perform the designated code for highlighting
          addSelectMenu(); //add the select menu
          resetBlinker();  //make the blinking caret visible
          
          holder.setSelect(buddy.caretHandle); //make it so, if we keep holding, we can drag the handles
          buddy.caretCursor = holder;          //set our caret cursor to the holder
          
          buddy.holdSelecting = true; //set the flag so that we're holding down to select
        } });
      }
      
      if(hasOneHandle() && buddy.handleTimeExpired()) { //if we only have one handle, and enough time has passed since creation of that handle,
        buddy.removeHandlesLater(); //remove that handle
      }
    }
    
    
    if(!sliding) { return; } //don't do anything else unless we're sliding
    
    if(buddy.caretCursor != null) {
      int caret2 = buddy.cursorToCaret(buddy.caretCursor.x);        //find what caret position we're hovering over
      if(hMode!=HighlightMode.MOBILE || !highlighting || (caret2!=caret && caret2!=anchorCaret)) { //if we're not on mobile mode, or moving here doesn't cause both carets to be the same (assuming we're highlighted)
        caret = caret2; //set the caret
        resetBlinker(); //reset the blinker
        if(buddy.caretHandle!=null) { buddy.caretHandle.moveToIndex(caret); } //if there's a TS handle, move it to the caret index
      }
    }
    if(buddy.anchorCursor != null) {
      int caret2 = buddy.cursorToCaret(buddy.anchorCursor.x);       //find what caret position we're hovering over
      if(hMode!=HighlightMode.MOBILE || !highlighting || (caret2!=caret && caret2!=anchorCaret)) { //if we're not on mobile mode, or moving here doesn't cause both carets to be the same (assuming we're highlighted)
        anchorCaret = caret2; //set the anchor caret
        resetBlinker();       //reset the blinker
        if(buddy.anchorHandle!=null) { buddy.anchorHandle.moveToIndex(anchorCaret); } //if there's a TS handle, move it to the anchor caret index
      }
    }
    
  }
  
  boolean hasOneHandle() { return buddy.caretHandle!=null && buddy.anchorHandle==null; } //returns true if there's one centered handle
  
  boolean hasOneActiveHandle() { return hasOneHandle() && buddy.caretCursor!=null; } //returns true if there's one centered handle & we're dragging it around
  
  
  void tryToSlide(final Cursor curs) { //tries to slide, only doing so if it's allowed to
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
    long lastPressed = 0;             //when this was last pressed
    float lastPressedX, lastPressedY; //where this was last pressed
    long  lastReleased = 0;             //when this was last released
    float lastReleasedX, lastReleasedY; //where this was last released
    int doubleTapTimeout = 500;         //how many milliseconds can happen between consecutive double taps
    int holdTime = 350;                 //how many milliseconds you have to press down on a selection to highlight it
    boolean holdSelecting = false; //whether it's currently being pressed-and-held for the sake of selection
    
    long handleTime = 0;              //the time when a centered handle was last created
    int centeredHandleTimeout = 5000; //how long before we delete a centered handle
    boolean timeoutOverride = false;  //when this is true, the handle cannot time out because it is being interacted with
    
    void resetHandleTime() { handleTime = System.currentTimeMillis(); }
    boolean handleTimeExpired() { return !timeoutOverride && System.currentTimeMillis()-handleTime >= centeredHandleTimeout; }
    
    float highlightGrabDistance; //how far the cursor can be from the caret to grab it while highlighting
    
    UICursor  caretCursor = null; //the cursor currently dragging our active caret
    UICursor anchorCursor = null; //the cursor currently dragging our anchor caret
    
    private UICursor holdCursor = null; //the cursor currently holding down on the textbox
    
    public UICursor getHoldCursor() {
      return (holdCursor == null || holdCursor.select != this || holdCursor.press == 0) ? null : holdCursor;
      
      //the reason for this function is because we cannot instruct the system to unhold the hold cursor any time it must occur without deeply interweaving that mechanism into the master level code
      //instead, we just set the hold cursor only when it starts pressing us, but decide to ignore it if it's not pressing us
    }
    
    TSHandle caretHandle = null, anchorHandle = null; //text selection handles for the main caret and the anchor caret
    
    CaretMover(final Textbox t) {
      super(0,t.ty,t.w,t.getTextHeight());
      setFill(false).setStroke(false).setMobile(false).setParent(t);
      //setFill(0x80FF0000); //debug: gives the mover a redish hue to make it visible
      highlightGrabDistance = 0.5*t.tSize;
      buddy = t;
    }
    
    void addMiddleCaretHandle() { //adds a single caret handle that's centered
      caretHandle = new TSHandle(buddy, buddy.caret, CENTER, false); //create a centered handle at the primary caret
      resetHandleTime(); //record the time of creation
    }
    
    void addUncenteredCaretHandle() { //adds a single handle at the caret that's not centered
      caretHandle = new TSHandle(buddy, buddy.caret, buddy.caret<buddy.anchorCaret ? LEFT : RIGHT, false);
    }
    
    void addUncenteredAnchorHandle() { //adds a single candle at the anchor caret that's not centered
      anchorHandle = new TSHandle(buddy, buddy.anchorCaret, buddy.caret<buddy.anchorCaret ? RIGHT : LEFT, true);
    }
    
    boolean respondToChange(final UICursor curs, final byte code, boolean selected) { //responds to change in the cursor (0=release, 1=press, 2=move, 3=drag) (select iff cursor is already touching something)
      
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
            
            holdCursor = curs;
            
            lastPressed = System.currentTimeMillis(); //update when and where this was last pressed
            lastPressedX = curs.x; lastPressedY = curs.y;
          } break;
          default: { } break;
        }
        
        mmio.updatePressCount();   //reset the press counter for every button to 0
      }
      
      else if(code==0) { //if this has just been released:
        if(holdSelecting) { holdSelecting = false; } //disable hold selecting
        
        else if(this==curs.select) { switch(buddy.hMode) { //make sure box was already selected by the cursor, then what we do next depends on the highlighting mode
          case NONE: { //no highlighting:
            release(curs); //perform release functionality
          } break;
          case PC: { //PC:
            caretCursor = null; //make the caret cursor null
            buddy.sliding = false; buddy.surfaceVx = 0; //stop sliding
            
            release(curs); //perform release functionality
          } break;
          case MOBILE: { //mobile: //TODO encapsulate these cases into their own functions
            release(curs); //perform release functionality
            
            boolean wasHighlighting = buddy.highlighting; //record beforehand if we were highlighting
            
            clearHandles();             //remove all handles
            buddy.highlighting = false; //disable highlighting
            
            long time = System.currentTimeMillis();
            //double tapping is deemed to happen if you press twice in a row, both taps fairly close together in both time and proximity
            if(time - lastReleased <= doubleTapTimeout && sq(curs.x-lastReleasedX)+sq(curs.y-lastReleasedY) < sq(buddy.promoteDist)) { //if we just double tapped:
              if(wasHighlighting || buddy.size()==0) { //if we were already highlighting (or there's nothing to select):
                buddy.equalizeCarets(); //equalize the carets
                
                addMiddleCaretHandle(); //add TS handle at caret
                //this is the triple tap functionality, bring up select menu w/out highlighting
              }
              else { //if not yet highlighting:
                processTextTouch(curs, true); //process the double tap functionality
              }
              
              buddy.addSelectMenu(); //if there isn't already one, add a select menu
            }
            else { //otherwise...
              addMiddleCaretHandle(); //add TS handle at caret
            }
            
            lastReleased = time; //update when and where this was last released
            lastReleasedX = curs.x; lastReleasedY = curs.y;
          } break;
        } }
        
        buddy.dragCursor = null; //reset the drag cursor
      }
      
      else if(this==curs.select && caretCursor==curs && code==3) { //if this box was already selected by the cursor, this cursor is the caret cursor, and the cursor is being dragged:
        switch(buddy.hMode) {
          case PC: { //PC:
            buddy.caret = cursorToCaret(curs.x); //move the caret to where the cursor is
            
            buddy.highlighting = true; //because we dragged the mouse while selecting this textbox, we are highlighting
            
            buddy.tryToSlide(curs); //try to slide (only works if you're allowed to)
            
            buddy.resetBlinker(); //make the caret visible
          } break;
          default: { } break;
        }
      }
      
      return hitbox; //return whether the cursor is in the hitbox
    }
    
    void processTextTouch(Cursor curs, boolean hadOneHandle) { //this processes text being double tapped or pressed and held
      float cursorFromCaretX = curs.x - buddy.getX(buddy.caret) - buddy.getObjSurfaceX(); //find the position of the cursor WRT the caret
      buddy.anchorCaret = cursorFromCaretX > 0 ? buddy.caret+1 : buddy.caret-1; //set the anchor position such that the cursor is between both carets
      buddy.restrictCaret(); //make sure the anchor caret is in bounds
      
      if(buddy.anchorCaret != buddy.caret) { //if the carets are distinct:
        buddy.highlighting = true; //enable highlighting
        
        addUncenteredCaretHandle();
        addUncenteredAnchorHandle();
      }
      else if(hadOneHandle) { //if they're in the same position, though, and there used to be a handle before we stripped it away:
        addMiddleCaretHandle(); //add TS handle at caret
        //basically, if we tap to the left or right of the text, we don't want to select anything, we just wanna bring up the select menu
      }
    }
    
    void release(Cursor curs) { //performs a release event, allowing the caret to be moved by the mouse
      buddy.caret = cursorToCaret(curs.x); //move the caret to the position the cursor is hovering over
      
      buddy.releaseAction.act(); //perform the specified action
      mmio.updatePressCount();   //reset the press counter for every button to 0
      
      buddy.resetBlinker();      //make the caret visible
    }
    
    int cursorToCaret(float x) { //finds which caret the given cursor is hovering over (input is the cursor's x position)
      float sx = buddy.getObjSurfaceX(); //get OBJECTIVE surface position
      float objX = buddy.getObjX();      //get objective panel position
      x = constrain(x,objX,objX+w);      //constrain x to be within the boundaries of the panel
      for(int n=0;n<=buddy.size();n++) { //loop through all caret positions
        if((n==0            || sx+buddy.getX(n-1)+0.5*buddy.getW(n-1)<=x) && //find one such that the previous character is left of the cursor (or there is no previous character)
           (n==buddy.size() || sx+buddy.getX(n  )+0.5*buddy.getW(n  )> x)) { //and the next character is right of the cursor (or there is no next cursor)
          return n; //return the index that meets those conditions
        }
      }
      throw new RuntimeException("CURSOR FAILED TO SELECT A CARET"); //if, somehow, none of the caret positions meet those conditions, throw an exception
    }
    
    void clearHandles() { //removes both handles
      if( caretHandle!=null) { //if there's a caret handle:
        caretHandle.setParent(null); //delete it from the UI tree
        caretHandle = null;          //delete this handle
      }
      if(anchorHandle!=null) { //if there's an anchor handle:
        anchorHandle.setParent(null); //delete it from the UI tree
        anchorHandle = null;          //delete this handle
      }
      
      if(caretCursor!=null) {      //remove any caret cursors
        caretCursor.setSelect(null); caretCursor = null; //deselect it, and nullify it
      }
      if(anchorCursor!=null) {     //remove any anchor cursors
        anchorCursor.setSelect(null); anchorCursor = null; //deselect it, and nullify it
      }
      
      buddy.dragCursor = null; //if there is a cursor dragging around this highlighted text, decommission it
      buddy.removeSelectMenu(); //make the select menu disappear
    }
    
    void removeHandlesLater() { //schedules for the handles to be removed later
      mmio.addPendingPostOperation(new Runnable() { public void run() { //add a new pending operation
        clearHandles();                                             //that clears the handles
      } });
    }
    
    void correctHandles() { if(buddy.hMode==HighlightMode.MOBILE) { //corrects the position, orientation, and configuration of all the text selection handles (only used in mobile mode)
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
          addUncenteredCaretHandle(); //add one
        }
        if(anchorHandle==null) { //if there's no anchor handle
          addUncenteredAnchorHandle(); //add one
        }
      }
    } }
    
    void correctHandlesLater() { if(buddy.hMode==HighlightMode.MOBILE) { //adds a pending operation that corrects the handles later
      mmio.addPendingPostOperation(new Runnable() { public void run() {
        correctHandles();
      } });
    } }
    
    void moveCaretLater(final int caret) {
      mmio.addPendingPostOperation(new Runnable() { public void run() {
        buddy.caret = caret;
      } });
    }
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
    
    void setParamsFromOrientation(float x2, float rad) { //sets the dimensional parameters, knowing the orientation
      switch(orientation) {
        case LEFT  : x = x2-2*rad; w = 2*rad; h = 2    *rad; break;
        case CENTER: x = x2-rad;   w = 2*rad; h = 2.414*rad; break;
        case RIGHT : x = x2;       w = 2*rad; h = 2    *rad; break;
      }
    }
    
    void reorient(int ori) { //changes the orientation
      if(ori==orientation) { return; } //if the orientation is the same, do nothing
      float caretPos = 0;   //first, record the x position of the caret we're pointing to
      switch(orientation) { //this depends on our current orientation
        case LEFT  : caretPos = x+w;     break;
        case CENTER: caretPos = x+0.5*w; break;
        case RIGHT : caretPos = x;       break;
      }
      orientation = ori; //then, change the orientation
      switch(orientation) { //then, we change the dimensions again depending on the orientation
        case LEFT  : x = caretPos-w; h = w;           break;
        case CENTER: x = caretPos-0.5*w; h = 1.207*w; break;
        case RIGHT : x = caretPos; h = w;             break;
      }
      if(orientation == CENTER) { host.buddy.resetHandleTime(); } //if we changed it to be centered, reset the handle time
    }
    
    @Override float getX() { return x + host.getSurfaceX() + host.getXRelTo(parent); } //in order to follow our host, but still not be confined to our host's borders, we have to override our x position
    @Override float getY() { return y + host.getSurfaceY() + host.getYRelTo(parent); } //and y position
    @Override float getObjX() { return x+host.getObjSurfaceX(); }                      //and objective x position
    @Override float getObjY() { return y+host.getObjSurfaceY(); }                      //and objective y position
    
    @Override
    void display(final PGraphics graph, float buffX, float buffY) {
      float xRelToHost = x+host.surfaceX + (orientation==LEFT ? w : orientation==CENTER ? 0.5*w : 0);
      if(xRelToHost<0 || xRelToHost>host.w) { return; }
      
      float x3 = getX()-buffX, y3 = getY()-buffY; //get location where you should actually draw
      setDrawingParams(graph);                    //set drawing parameters
      switch(orientation) {
        case LEFT  : graph.ellipse(x3+0.5*w, y3+0.5  *h, w, h); graph.rect(x3+0.5*w,y3, 0.5*w, 0.5*h); break;
        case CENTER: graph.ellipse(x3+0.5*w, y3+0.707*w, w, w); graph.triangle(x3+0.5*w,y3, x3+0.146*w,y3+0.354*w, x3+0.854*w,y3+0.354*w); break;
        case RIGHT : graph.ellipse(x3+0.5*w, y3+0.5  *h, w, h); graph.rect(x3      ,y3, 0.5*w, 0.5*h); break;
      }
    }
    
    boolean respondToChange(final UICursor curs, final byte code, boolean selected) { //TODO figure out if all of this is correct, and if so then clean it up
      boolean hitbox = hitbox(curs); //first, find if the cursor is inside the hitbox
      
      if(hitbox && !selected && code == 1) { //if the cursor is in the hitbox, and hasn't already selected something else, and just now started pressing
        curs.seLocked = true; //block select promotion
        
        if(anchor) { host.buddy.anchorCursor = curs; }
        else       { host.buddy. caretCursor = curs; }
        
        if(orientation == CENTER) {
          host.buddy.timeoutOverride = true; //if a centered handle is being interacted with, prevent it from disappearing
        }
      }
      
      else if(this==curs.select && code == 0) { //if this is what the cursor has selected, and we just released...um...I don't think we actually do anything???
        //OH WAIT, no, we bring up the selection menu above
        host.buddy.correctHandles();
        host.sliding = false; host.surfaceVx = 0;
        
        if(anchor) { host.buddy.anchorCursor = null; }
        else       { host.buddy. caretCursor = null; }
        
        host.dragCursor = null; //reset the drag cursor
        
        if(orientation == CENTER) {
          host.buddy.timeoutOverride = false; //if a centered handle is no longer being interacted with, it is allowed to disappear
          host.buddy.resetHandleTime();       //but reset its timer
        }
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
    
    void moveToIndex(int ind) { //moves the handle to the correct position corresponding to the given caret index
      switch(orientation) {     //how we do this depends on the orientation
        case LEFT  : x = host.getX(ind) -     w; break;
        case CENTER: x = host.getX(ind) - 0.5*w; break;
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
      
      w = 0.91*host.mmio.w; h = 0.14*host.mmio.w; //set the width and height
      //println(w, h, host.mmio.w, host.mmio.h, parent.w, parent.h);
      
      float middle = host.getX(caret)+host.getSurfaceXRelTo(parent); //find the x position of the caret (relative to the parent)
      
      x = constrain(middle-0.5*w,0,parent.w-w); //set x such that the center is as close to "middle" as possible, while still being strictly in bounds
      
      y = host.ty-1.2*h; //place the menu directly above the text
      if(y+host.getYRelTo(parent)<0) { //if the menu is cut off from above:
        y = host.ty+0.2*h+host.getTextHeight(); //place the menu directly below the text
      }
      
      surfaceW = w; surfaceH = h; fill = false; surfaceFill = true; stroke = false; //set drawing parameters
      surfaceFillColor = #3a3a3d;
      r = 0.049*w;
      
      setScrollable(false, false);               //make it not scrollable
      setDragMode(DragMode.NONE, DragMode.NONE); //make it not draggable
      
      Button cut       = new Button(0.06*w,0,0.16*w,h).setFills(#3a3a3d,#616164).setStroke(false); cut      .setParent(this); cut      .setText("Cut"       ,0.058*w,-1);
      Button copy      = new Button(0.22*w,0,0.20*w,h).setFills(#3a3a3d,#616164).setStroke(false); copy     .setParent(this); copy     .setText("Copy"      ,0.058*w,-1);
      Button paste     = new Button(0.42*w,0,0.22*w,h).setFills(#3a3a3d,#616164).setStroke(false); paste    .setParent(this); paste    .setText("Paste"     ,0.058*w,-1);
      Button selectAll = new Button(0.63*w,0,0.31*w,h).setFills(#3a3a3d,#616164).setStroke(false); selectAll.setParent(this); selectAll.setText("Select All",0.058*w,-1);
      //initPixPerClick();
      
      cut.setOnRelease(new Action() { public void act() { //create the cut button
        copyToClipboard(host.substring(host.getLeftCaret(), host.getRightCaret())); //copy the selection to the clipboard
        host.eraseSelection(!host.hasOneActiveHandle()); //erase the selection
      } });
      copy.setOnRelease(new Action() { public void act() { //create the copy button
        copyToClipboard(host.substring(host.getLeftCaret(), host.getRightCaret())); //copy the selection to the clipboard
        host.buddy.removeHandlesLater(); //remove the handles later
      } });
      paste.setOnRelease(new Action() { public void act() { //create the paste button
        String text = getTextFromClipboard(); //grab the contents from clipboard
        if(text!=null) {         //if the contents were valid:
          host.eraseSelection(!host.hasOneActiveHandle()); //if highlighting, erase the selection
          host.insert(text);     //insert the contents from the clipboard
        }
        host.removeSelectMenu();
        host.buddy.correctHandlesLater();
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
    
    @Override float getX() { return x + host.getXRelTo(parent); } //in order to follow our host, but still not be confined to our host's borders, we have to override our x position
    @Override float getY() { return y + host.getYRelTo(parent); } //and y position
    @Override float getObjX() { return x+host.getObjX(); }                      //and objective x position
    @Override float getObjY() { return y+host.getObjY(); }                      //and objective y position
  }
}

static class SimpleText {
  char text; float x, w; byte properties=0; //the text displayed, position, width, misc properties
  Object misc = null; //finally, an object to hold any miscellaneous stuff we might have
  
  SimpleText() { }
  SimpleText(char t, float x_, float w_) { text=t; x=x_; w=w_; }
  SimpleText(char t, float x_, float w_, byte p) { this(t,x_,w_); properties=p; }
  
  @Override
  String toString() { return text+""; }
}
