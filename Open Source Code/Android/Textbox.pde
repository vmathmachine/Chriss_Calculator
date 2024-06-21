public static class Textbox extends Panel {
  
  ////////////////////// ATTRIBUTES /////////////////////////
  
  //text
  float tx, ty; //x & y of text's top left WRT surface
  float tSize; color tFill; //text size & color
  ArrayList<SimpleText> texts = new ArrayList<SimpleText>(); //the texts themselves
  CursorMover buddy; //invisible box to allow for mouse-based/touch-based text cursor placement
  Action releaseAction = emptyAction; //the action that gets performed when you press the buddy, along with 
  
  //cursor
  int cursor = 0; //the position of the blinking cursor
  color cStroke;  //the color of the blinking cursor
  float cThick = 1; //the stroke weight of the cursor
  long blink;       //the time when the blinking cursor was last reset
  boolean insert=true; //true=insert, false=overtype. Inverts every time we hit the "insert" key
  
  ///////////////////// CONSTRUCTORS ///////////////////////
  
  Textbox(final float x2, final float y2, final float w2, final float h2) {
    super(x2,y2,w2,h2); //just run the inherited method
    
    tx=Mmio.xBuff; ty=Mmio.yBuff; //then initialize some stuff to their default values
    tSize = Mmio.invTextHeight(h2-2*Mmio.yBuff); //choose a text size with the appropriate height
    
    buddy = new CursorMover(this); //initialize our cursor buddy
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
  
  Textbox setTextColor  (color   c) { tFill=c; return this; }
  Textbox setCursorColor(color   c) { cStroke=c; return this; }
  Textbox setCursorThick(float wgt) { cThick=wgt; return this; }
  Textbox setTextSize   (float siz) { tSize=siz; return this; }
  Textbox setTextSizeAndAdjust(float siz) { tSize=siz; ty=0.5*(h-Mmio.getTextHeight(siz)); ySpace=min(ySpace,ty); return this; }
  
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
  
  ////////////////// DISPLAY //////////////////////
  
  @Override
  void extraDisplay(PGraphics graph, float buffX, float buffY) { //displays the text in the textbox
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
    
    if(this==mmio.typer && (System.currentTimeMillis()-blink & 512) == 0) { //if this is our selected textbox, and our cursor is in the correct cycle of blinking:
      drawCursor(graph, buffX, buffY); //draw the cursor
    }
  }
  
  void drawCursor(PGraphics graph, float buffX, float buffY) {
    graph.stroke(cStroke); graph.strokeWeight(cThick); //set drawing parameters for cursor
    float xStart = getX(cursor)+surfaceX; //find x pos of cursor
    if(xStart>=w) { return; } //if it's too far right, we can't draw it
    
    if(!insert) { //if overtype, we draw cursor as underline
      float xEnd = (cursor==size() ? getX(cursor)+0.75*tSize : getX(cursor+1))+surfaceX; //find x pos of right of cursor
      if(xEnd>0) { //if the cursor is even on screen:
        graph.line(max(xStart,0)+getX()-buffX,ty+getY()+surfaceY+getTextHeight()-buffY, min(xEnd,w)+getX()-buffX,ty+getY()+surfaceY+getTextHeight()-buffY); //draw it, with x constraints for clipping
      }
    }
    else if(xStart>0) { //otherwise, we draw cursor as vertical line (again, make sure it's on screen)
      graph.line(xStart+getX()-buffX, ty+getY()+surfaceY-buffY, xStart+getX()-buffX, ty+getY()+surfaceY+getTextHeight()-buffY);
    }
  }
  
  /////////////// TYPING (FUNDAMENTAL) //////////////////////
  
  int size() { return texts.size(); } //number of characters in the text
  
  float getX(int ind) { //obtain the pixel x-coordinate of the given cursor position, relative to surface
    if(size()==0 && ind==0) { return tx; }
    if(ind==size()) { SimpleText s = texts.get(ind-1); return s.x+s.w; }
    return texts.get(ind).x;
  }
  
  float getW(int ind) { return texts.get(ind).w; } //obtain the pixel width of the character at the given position
  char getText(int ind) { return texts.get(ind).text; } //obtain the character at the given position
  
  String getText() { //obtains the contents of the text field as a plain string
    String result = "";                          //init to blank
    for(SimpleText txt : texts) { result+=txt; } //concat each char
    return result;                               //return result
  }
  
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
  
  void restrictCursor() { cursor = constrain(cursor,0,size()); }
  
  void adjust(final boolean target, final boolean snap, final boolean blink) { //performs adjustments, recommended to be executed every time a text editing action is performed
    fixWidth(); //fix the surface to the correct width
    
    if(target) {      //if applicable:
      //chooseTargetRecursive(getX(cursor),ty+0.5*getTextHeight()); //adjust targeting system
      chooseTargetRecursive(getX(cursor),ty,getX(cursor),ty+getTextHeight());                     //adjust targeting system
      if(snap && this.target!=null) { this.target.time-=SurfaceTarget.duration; moveToTarget(); } //if we want to snap to our target, we must snap to our target
    }
    
    if(blink) { resetBlinker(); } //if asked, make the cursor visible
  }
  void adjust() { adjust(true,false,true); } //usually, we want to target, not snap, and make cursor visible
  
  void moveCursorTo(final int pos, final boolean target, final boolean snap, final boolean blink) { //move cursor to position
    cursor = constrain(pos,0,size());
    adjust(target, snap, blink);
  }
  void moveCursorTo(final int pos) { moveCursorTo(pos,true,false,true); }
  
  void moveCursorBy(final int amt, final boolean target, final boolean snap, final boolean blink) { //move cursor by amount
    cursor = constrain(cursor+amt,0,size());
    adjust(target, snap, blink);
  }
  void moveCursorBy(final int amt) { moveCursorBy(amt,true,false,true); }
  
  void insert(final char text, final boolean target, final boolean snap, final boolean blink) { //insert character to the right of cursor (and move cursor)
    insert(text, cursor++);
    adjust(target, snap, blink);
  }
  void insert(final char text) { insert(text,true,false,true); }
  
  void insert(final String text, final boolean target, final boolean snap, final boolean blink) { //insert string to the right of cursor (and move cursor)
    insert(text, cursor); cursor+=text.length();
    adjust(target, snap, blink);
  }
  void insert(final String text) { insert(text,true,false,true); }
  
  void overtype(final char text, final boolean target, final boolean snap, final boolean blink) { //overtype character to the right of cursor (and move cursor)
    overtype(text, cursor++);
    adjust(target, snap, blink);
  }
  void overtype(final char text) { overtype(text,true,false,true); }
  
  void type(final char text, final boolean target, final boolean snap, final boolean blink) { //either insert or overtype, depending on the mode
    if(insert) { insert(text,cursor++); } else { overtype(text, cursor++); }
    adjust(target, snap, blink);
  }
  void type(final char text) { type(text,true,false,true); }
  
  void delete(final boolean target, final boolean snap, final boolean blink) { //delete character right of cursor
    remove(cursor);
    adjust(target, snap, blink);
  }
  void delete() { delete(true,false,true); }
  
  void backspace(final boolean target, final boolean snap, final boolean blink) { //delete character left of cursor (and move cursor 1 left)
    if(cursor==0) { return; }
    remove(--cursor);
    adjust(target, snap, blink);
  }
  void backspace() { backspace(true,false,true); }
  
  void clear(final boolean target, final boolean snap, final boolean blink) { //clear entire field
    clear(); cursor = 0;
    adjust(target, snap, blink);
  }
  void clear2() { clear(true,true,true); } //this one is different, the default is to snap right into place, to avoid out of bounds
  
  void replace(final String text) { //replaces the entire contents of typing field with something else (TODO stop it from having graphical bugs, you know, like it being out of bounds)
    clear(); cursor = 0; insert(text,0); adjust(false,false,true);
  }
  
  
  void ctrlLeft(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+left functionality, moving cursor to the previous word
    if(cursor!=0) { //doesn't work if cursor is at beginning
      char seed = charAt(cursor-1); //grab char right before cursor
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      do { //repeatedly decrement cursor
        --cursor;
      } while(cursor>0 && ident == (Character.isLetterOrDigit(seed=charAt(cursor-1)) || seed=='_')); //stop when we reach 0, or when we reach a character which is a letter/number/underscore XOR the orignal was
    }
    adjust(target,snap,blink);
  }
  void ctrlLeft() { ctrlLeft(true,false,true); }
  
  void ctrlRight(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+right functionality, moving cursor to the next word
    if(cursor!=size()) { //doesn't work if cursor is at end
      char seed = charAt(cursor); //grab char in front of cursor
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      do { //repeatedly increment cursor
        ++cursor;
      } while(cursor<size() && ident == (Character.isLetterOrDigit(seed=charAt(cursor)) || seed=='_')); //stop when we reach the end, or when we reach a character which is a letter/number/underscore XOR the original was
    }
    adjust(target,snap,blink);
  }
  void ctrlRight() { ctrlRight(true,false,true); }
  
  void ctrlBackspace(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+backspace functionality, removing the word to the left of the cursor (then moving cursor to the left)
    if(cursor!=0) { //doesn't work if cursor is at beginning
      char seed = charAt(cursor-1); //grab char right before cursor
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      int cursor0 = cursor; //record original cursor position
      do { //repeatedly decrement cursor
        --cursor;
      } while(cursor>0 && ident == (Character.isLetterOrDigit(seed=charAt(cursor-1)) || seed=='_')); //stop when we reach 0, or when we reach a character which is a letter/number/underscore XOR the original was
      remove(cursor,cursor0); //remove all characters in between both cursors
    }
    adjust(target,snap,blink);
  }
  void ctrlBackspace() { ctrlBackspace(true,false,true); }
  
  void ctrlDelete(final boolean target, final boolean snap, final boolean blink) { //performs the ctrl+delete functionality, removing the word to the right of the cursor
    if(cursor!=size()) { //doesn't work if cursor is at end
      char seed = charAt(cursor); //grab char in front of cursor
      boolean ident = Character.isLetterOrDigit(seed) || seed=='_'; //figure out beforehand whether this char is a letter/number/underscore
      int cursor2 = cursor; //create second fake cursor
      do { //repeatedly increment fake cursor
        ++cursor2;
      } while(cursor2<size() && ident == (Character.isLetterOrDigit(seed=charAt(cursor2)) || seed=='_')); //stop when we reach the end, or when we reach a character which is a letter/number/underscore XOR the original was
      remove(cursor,cursor2); //remove all characters in between both cursors
    }
    adjust(target,snap,blink);
  }
  void ctrlDelete() { ctrlDelete(true,false,true); }
  
  void ctrlShiftBackspace(final boolean target, final boolean snap, final boolean blink) { //performs ctrl+shift+backspace functionality, removing everything to the left of the cursor (then moving the cursor all the way left)
    remove(0,cursor); //remove all characters before the cursor
    cursor = 0; //move cursor to 0
    adjust(target,snap,blink); //adjust
  }
  
  void ctrlShiftDelete(final boolean target, final boolean snap, final boolean blink) { //performs ctrl+shift+delete functionality, removing everything to the right of the cursor
    remove(cursor,size()); //remove all characters after the cursor
    adjust(target,snap,blink); //adjust
  }
  
  
  
  /*void readInput(final InputCode inp, final boolean target, final boolean snap) {
    final Textbox ref = this;
    final int[] ints = {0,1,2,3,4,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    String[] strings = new String[inp.strings.length]; arrayCopy(inp.strings, strings);
    char[] chars = new char[inp.chars.length]; arrayCopy(inp.chars, chars);
    int[] inst = inp.instructions;
    
    class IntGetter { int get(int ind) { if(ind==-1) { return -1; } if(ind==-2) { return cursor; } if(ind==-3) { return ref.size(); } if(ind==-4) { return cursor<0||cursor>=size()?0:texts.get(cursor).text; } return ints[ind]; } }
    IntGetter i = new IntGetter(); //this is so that we can still grab variables that wouldn't be accessible otherwise. Namely, cursor position, text length, char at cursor, and, just for convenience, -1
    
    for(int n=0;n<inp.instructions.length;) {
      switch(inst[n]) {
        case 'M': cursor = i.get(inst[n+1]);         n+=2; break; //move to position
        case 'S': cursor += inst[n+1];               n+=2; break; //shift by amount
        case 'I': insert(strings[inst[n+1]],cursor); n+=2; break; //insert string
        case 'i': insert(chars[inst[n+1]],cursor);   n+=2; break; //insert character
        case 'o': overtype(chars[inst[n+1]],cursor); n+=2; break; //overtype character
        
        case 'D': remove(cursor);      n++; break; //delete character
        case 'C': clear(); cursor = 0; n++; break; //clear
        
        case 'g': n=inst[n+1]; break; //GOTO line
        case 'G': n = (i.get(inst[n+1])!=0) ? inst[n+2] : n+3; break; //if something == true, GOTO line. Otherwise, go to next line
        
         //these last parts are just to make this whole shpiel Turing complete. Because might as well, right?
        case '=': ints[inst[n+1]]=inst[n+2]; n+=3; break; //assign variable to constant
        case '$': switch(inst[n+3]) {                     //assign variable to operation between 1-2 variables
          case '.': ints[inst[n+1]] = i.get(inst[n+2]);   n+=4; break; //one parameter operations (. = do nothing)
          case '!': ints[inst[n+1]] = i.get(inst[n+2])^1; n+=4; break;
          case '~': ints[inst[n+1]] = ~i.get(inst[n+2]);  n+=4; break;
          
          case '=': ints[inst[n+1]] = (i.get(inst[n+2])==i.get(inst[n+4])) ? 1 : 0; n+=5; break; //two parameter boolean operations
          case '<': ints[inst[n+1]] = (i.get(inst[n+2])< i.get(inst[n+4])) ? 1 : 0; n+=5; break;
          case '>': ints[inst[n+1]] = (i.get(inst[n+2])> i.get(inst[n+4])) ? 1 : 0; n+=5; break;
          
          case '+': ints[inst[n+1]] = i.get(inst[n+2]) + i.get(inst[n+4]); n+=5; break; //two parameter math operations
          case '-': ints[inst[n+1]] = i.get(inst[n+2]) - i.get(inst[n+4]); n+=5; break;
          case '*': ints[inst[n+1]] = i.get(inst[n+2]) * i.get(inst[n+4]); n+=5; break;
          case '/': ints[inst[n+1]] = i.get(inst[n+2]) / i.get(inst[n+4]); n+=5; break;
          case '%': ints[inst[n+1]] = i.get(inst[n+2]) % i.get(inst[n+4]); n+=5; break;
          case '&': ints[inst[n+1]] = i.get(inst[n+2]) & i.get(inst[n+4]); n+=5; break; //two parameter bitwise operations
          case '|': ints[inst[n+1]] = i.get(inst[n+2]) | i.get(inst[n+4]); n+=5; break;
          case '^': ints[inst[n+1]] = i.get(inst[n+2]) ^ i.get(inst[n+4]); n+=5; break;
        } break;
      }
    }
    restrictCursor(); //force cursor to be in bounds
    fixWidth();       //correct the width
    if(target) {      //if applicable:
      //chooseTargetRecursive(getX(cursor),ty+0.5*getTextHeight()); //adjust targeting system
      chooseTargetRecursive(getX(cursor),ty,getX(cursor),ty+getTextHeight()); //adjust targeting system
      if(snap && this.target!=null) { this.target.time-=SurfaceTarget.duration; moveToTarget(); } //if we want to snap to our target, we must snap to our target
    }
    
    resetBlinker(); //text edit means we must make cursor visible
  }*/
  
  //void readInput(final InputCode inp) { readInput(inp, true, false); }
  
  //void readInput(int[] instruct) { readInput(new InputCode(instruct)); }
  //void readInput(int[] instruct, char[] charss) { readInput(new InputCode(instruct, charss)); }
  //void readInput(int[] instruct, String[] stringss) { readInput(new InputCode(instruct, stringss)); }
  //void readInput(int[] instruct, char[] charss, String[] stringss) { readInput(new InputCode(instruct, charss, stringss)); }
  
  void fixWidth() { surfaceW = max(w, xSpace+getX(size())); }
  
  ////////////// MISC /////////////////////
  
  void resetBlinker() { blink = System.currentTimeMillis(); }
  
  static class CursorMover extends Box {
    Textbox buddy; //the parent cast to a textbox
    
    CursorMover(final Textbox t) {
      super(0,t.ty,t.w,t.getTextHeight());
      setFill(false).setStroke(false).setMobile(false).setParent(t);
      //setFill(0x80FF0000); //debug: gives the mover a redish hue to make it visible
      buddy = t;
    }
    
    void release(Cursor curs) { //performs a release event, allowing the cursor to be moved by the mouse
      float sx = parent.getObjSurfaceX(); //get OBJECTIVE surface position
      boolean changed = false;            //record whether we actually changed (for debugging purposes)
      for(int n=0;n<=buddy.size();n++) {
        if((n==0 || sx+buddy.getX(n-1)+0.5*buddy.getW(n-1)<=curs.x) && (n==buddy.size() || sx+buddy.getX(n)+0.5*buddy.getW(n)>curs.x)) {
          buddy.cursor = n; changed = true; break;
        }
      }
      buddy.releaseAction.act(); //perform the specified action
      mmio.updatePressCount();   //reset the press counter for every button to 0
      
      if(!changed) { throw new RuntimeException("CURSOR FAILED TO SELECT"); }
      buddy.resetBlinker(); //make the cursor visible
    }
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

/*static class InputCode {
  //cheat sheet: M=move cursor to i[$1], S=shift cursor by $1, I=insert string at s[$1] at cursor, i=insert char at c[$1] at cursor, o=overtype char at c[$1] at cursor,
  // D=delete char at cursor, C=clear text, g=goto $1, G=if i[$1]==1, GOTO $2, = = Assign i[$1]=$2, $=Assign i[$1]=i[$2] $3 [i[$4]], where $3 can be +-* /&|^% =<> ~!.
  
  String[] strings = new String[0];
  char[] chars = new char[0];
  
  int[] instructions;
  
  InputCode(int[] instruct) { instructions=instruct; }
  InputCode(int[] instruct, char[] charss) { instructions=instruct; chars=charss; }
  InputCode(int[] instruct, String[] stringss) { instructions=instruct; strings=stringss; }
  InputCode(int[] instruct, char[] charss, String[] stringss) { instructions=instruct; chars=charss; strings=stringss; }
  
  final static int[] LEFT  = {'S',-1}, RIGHT = {'S',1}, HOME = {'M',0}, END = {'M',-3}, DELETE = {'D'}, BACKSPACE = {'S',-1,'D'},
                     INSERT = {'i',0,'S',1}, OVERTYPE = {'o',0,'S',1}, CLEAR = {'C'};
}*/

//an example of things you can do with this system:

/*CTRLLEFT = {'S',-1,'=',5,'A'-1,'=',6,'Z'+1,'=',7,'a'-1,'=',8,'z'+1,'=',9,'0'-1,'=',10,'9'+1,
              '$',11,-4,'>',5,'$',12,-4,'<',6,'$',11,11,'&',12,'$',12,-4,'>',7,'$',13,-4,'<',8,'$',12,12,'&',13,'$',11,11,'|',12,'$',12,-4,'>',9,'$',13,-4,'<',10,'$',12,12,'&',13,'$',11,11,'|',12,
              'G',11,80,'g',1000,'S',-1,
              '$',11,-4,'>',5,'$',12,-4,'<',6,'$',11,11,'&',12,'$',12,-4,'>',7,'$',13,-4,'<',8,'$',12,12,'&',13,'$',11,11,'|',12,'$',12,-4,'>',9,'$',13,-4,'<',10,'$',12,12,'&',13,'$',11,11,'|',12,
              'G',11,80,'S',1};
It moves left when you 
*/
