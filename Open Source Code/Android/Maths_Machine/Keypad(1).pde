import java.util.EnumMap;

public static class KeyPanel { //the entire panel of keys, containing several alternate keypads
  Panel panel; //the UI panel that actually holds this stuff together
  
  //ArrayList<KeyPad> keypads = new ArrayList<KeyPad>(); //the individual keypads we display
  
  ArrayList<EnumMap<GraphMode,KeyPad>> keypads = new ArrayList<EnumMap<GraphMode,KeyPad>>(); //the individual keypads we display (keyed by the current graphmode)
  ArrayList<Boolean> activity = new ArrayList<Boolean>(); //whether each keypad is active
  GraphMode mode = GraphMode.NONE; //the graphing mode (determines which variables need to be shown)
  
  KeyPanel(float x, float y, float w, float h, float w2, float h2) {
    panel = new Panel(x,y,w,h,w2,h2);
  }
  
  void addKeypad(float x, float y, boolean active, final EnumMap<GraphMode,KeyPad> map) {
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
  
  void activate() { //activates all active keypad maps
    for(int n=0;n<activity.size();n++) if(activity.get(n)) {
      for(Button b : keypads.get(n).get(mode)) {
        b.setActive(true);
      }
    }
  }
  
  void deactivate() { //deactivates all keypad maps (even the active ones)
    for(int n=0;n<activity.size();n++) {
      for(GraphMode gm : GraphMode.values()) {
        for(Button b : keypads.get(n).get(gm)) {
          b.setActive(false);
        }
      }
    }
  }
  
  void swapGraphMode(GraphMode m) {
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
      keys[y][x] = new Button(0.5*spaceX+(wid+spaceX)*x,spaceY+(hig+spaceY)*y,wid,hig);
      keys[y][x].setPalette(palette);
      keys[y][x].setText(texts[y][x],#00FFFF,textBuffX,textBuffY); //TODO remove constant cyan, make it customizable
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
            for(Text t : keys[y][x].text) { t.x += 0.5*(wid+spaceX); } //re-center the text
            continue; //skip this iteration
          }
        }
        else { //otherwise,
          keys[y][x] = keys[y-1][x]; //fuse with the button above
          if(x==0 || !texts[y][x-1].equals(texts[y][x])) { //if the button to the left isn't ALSO the same,
            keys[y][x].h += hig+spaceY; //increase the height
            for(Text t : keys[y][x].text) { t.y += 0.5*(hig+spaceY); } //re-center the text
          }
          continue; //skip this iteration
        }
      }
      
      keys[y][x] = makeButton(io,palette,x,y,wid,hig,rad,spaceX,spaceY,textBuffX,textBuffY,texts[y][x], codes[y][x], extra[y][x]);
    }
  }
  
  void setActive(boolean active) { //sets whether this keypad is active
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
  KeyPad modClone(float spaceX, float spaceY, float textBuffX, float textBuffY, String[] orig, String[] diff, int[] codes, Object[] extra) { //copies the exact same thing, but with certain buttons changed
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
  
  Button makeButton(Mmio io, Button palette, int x, int y, float wid, float hig, float rad, float spaceX, float spaceY, float textBuffX, float textBuffY, String text, int code, Object extra) {
    final Button butt = new Button(spaceX+(wid+spaceX)*x,spaceY+(hig+spaceY)*y,wid,hig,rad).setPalette(palette);
    butt.setDisp(0.5*spaceX,0.5*spaceY,0.5*spaceX,0.5*spaceY);
    butt.mmio = io; //TODO make this less fucked
    butt.setText(text,#00FFFF,textBuffX,textBuffY); //TODO remove constant cyan, make it customizable
    
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
  
  static Action type(final Mmio io, final Button butt, final char... typers) { //this generates an action that types one from a set of characters
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
  
  static Action type(final Mmio io, final String typer) { //this just types a string right in front of the caret
    return new Action() { public void act() { if(io.typer!=null) {
      io.typer.eraseSelection(); //erase highlighted selection (if any)
      io.typer.insert(typer);    //insert the string
    } } };
  }
  
  static Action act(final Mmio io, final int action) { //this performs a specified action
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
  
  static Action typeAnsPrefix(final Mmio io, final Button butt, final char... typers) { //types character, but possibly w/ "Ans" before it if @ the beginning
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
  
  static Action typeDoubleAnsPrefix(final Mmio io, final Button butt, final char typer) { //types character, but possibly w/ "Ans" before it if typed twice @ the beginning
    return new Action() { public void act() { if(io.typer!=null) {
      io.typer.eraseSelection(); //if highlighting, erase the selection
      if(io.typer==query && io.typer.size()==1 && (butt.pressCount&1)==1) { io.typer.insert("Ans",0); io.typer.caret+=3; } //if double-tapped & @ the beginning, put Ans before it
      else { io.typer.type(typer); } //otherwise, just type it
    } } };
  }
  
  static Action clear(final Mmio io, final Button butt) { //clears the text field
    return new Action() { public void act() { if(io.typer!=null) {
      io.typer.clear2(); //clear
      if(butt.pressCount%10==9) { //if you press it 10 times in a row:
        if(io.typer==query) { history.clearEverything(true); } //calculator tab: clear history
        else if(equatList.equatCache!=null && equatList.equatCache.typer==io.typer) { equatList.clearEquations(); } //equation tab: clear equations
      }
    } } };
  }
}
