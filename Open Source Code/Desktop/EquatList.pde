public static class EquatList { //a class for holding the list of equations to be graphed out
  
  ////////////////// ATTRIBUTES ///////////////////
  
  static class EquatField { //class for holding all the things necessary to find our equation
    Panel panel; //the display console
    Textbox typer; //what we type into
    Graphable plot; //the thing this graphs out
    String cancel; //what the current unsaved typer will revert to when/if we press cancel
    
    EquatField(final Panel pn, final Textbox t, final Graphable pl, final String c) { panel=pn; typer=t; plot=pl; cancel=c; }
  }
  
  Mmio mmio; //the mmio system we're apart of
  
  Panel holder2D, holder3D, bigHolder; //a panel for holding the 2D equation list, one for the 3D equation list, and one to hold whichever one is visible, plus all its buttons
  
  ArrayList<EquatField> equats2D = new ArrayList<EquatField>(), //all our 2D equations
                        equats3D = new ArrayList<EquatField>(); //all our 3D equations
  
  //Textbox equatCache; //a pointer to the equation textbox we're currently typing into. When we edit the color, then press enter, we should go back to typing into this textbox.
  EquatField equatCache; //a pointer to the equation that's currently selected.
  //When we edit the color, then press enter, we should go back to editing this equation
  
  Textbox colorSelect; //textbox used to change the selected equation's color
  
  Graph   grapher2D; //the grapher used to graph in 2D
  Graph3D grapher3D; //the grapher used to graph in 3D
  
  byte axisMode = 0; //0=nothing, 1=axes, 2=axes+labels
  ConnectMode connect = ConnectMode.POINT; //how 3D graphs connect their points
  boolean graphDim = false; //graph dimensions (false=2d, true=3d)
  
  float equationHeight; //the height of each equation textbox
  float cursorThick;    //how thick the cursor is
  float buffX, buffY;   //buffer in the x & y direction
  
  final private ArrayList<Graphable> plots2D = new ArrayList<Graphable>(), plots3D = new ArrayList<Graphable>();
  
  ///////////////////////////////// CONSTRUCTORS ////////////////////////////////////////////
  
  EquatList(final Mmio parent, float x, float y, float w, float h, final Button palette, final float buttHig, final float equatHeight, final float inpBuffX, final float inpBuffY, final float thick) {
    mmio = parent; //set the panel parent
    
    bigHolder = new Panel(x,y,w,h,w,h); //create the panel that holds all this together
    bigHolder.setSurfaceFill(0).setStroke(#00FFFF).setParent(parent).setActive(false); //set the fill, stroke, parent, and whether it is currently active (it's not)
    
    equationHeight = equatHeight; //set equation height
    cursorThick = thick; //set the cursor thickness
    buffX = inpBuffX; buffY = inpBuffY; //set the input buffer
    
    holder2D = new Panel(0,buttHig,w,h-2*buttHig).setDragMode(DragMode.NONE, DragMode.ANDROID).setScrollableY(true); //create the list of 2D equations
    holder2D.setSurfaceFill(0).setStroke(#00FFFF).setParent(bigHolder);
    holder2D.setPixPerClick(20);
    
    holder3D = new Panel(0,buttHig,w,h-2*buttHig).setDragMode(DragMode.NONE, DragMode.ANDROID).setScrollableY(true); //create the list of 3D equations
    holder3D.setSurfaceFill(0).setActive(false).setStroke(#00FFFF).setParent(bigHolder);
    holder3D.setPixPerClick(20);
    
    //next, we have to create all the buttons
    final float buttWid = 0.25*w; //the width of all buttons
    Button equationAdder  = (Button)new Button(0  *buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Add",#00FFFF); //this adds equations
    Button mode2D         = (Button)new Button(    buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("2D" ,#00FFFF); //this swaps from 2D to 3D
    Button mode3D         = (Button)new Button(    buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("3D" ,#00FFFF).setActive(false); //swaps from 3D to 2D
    Button equationDelete = (Button)new Button(3  *buttWid,0,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Delete",#00FFFF);    //deletes currently selected equation
    Button equationUp     = (Button)new Button(2  *buttWid,0,0.5*buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("  ▲  ",#00FFFF); //the up & down buttons are half as wide as the rest
    Button equationDown   = (Button)new Button(2.5*buttWid,0,0.5*buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("  ▼  ",#00FFFF);
    
    Button equationCanceler  = (Button)new Button(0        ,h-buttHig,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Cancel"  ,#00FFFF); //cancels changes
    Button equationVisToggle = (Button)new Button(  buttWid,h-buttHig,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Visible?",#00FFFF); //toggles visibility
    Button equationMode      = (Button)new Button(2*buttWid,h-buttHig,buttWid,buttHig).setPalette(palette).setParent(bigHolder).setText("Mode"    ,#00FFFF); //sets graphing mode
    
    final float colorSelectSize = 0.035555556*w;
    colorSelect = (Textbox)new Textbox(3*buttWid,h-buttHig,buttWid,buttHig).setSurfaceFill(#001818).setStroke(#00FFFF).setParent(bigHolder); //textbox that allows you to change the selected equation's color
    colorSelect.setTextSizeAndAdjust(colorSelectSize); //change the text size
    colorSelect.setOnRelease(new Action() { public void act() { if(equatCache!=null) { //make it so, when you click on the color select box (and an equation is selected):
      mmio.setTyper(colorSelect); //it causes you to select the color select box
    } } });
    
    equationAdder.setOnRelease(new Action() { public void act() {
      addEquation(); //add equation at the specified index
    } });
    
    mode2D.setOnRelease(new Action() { public void act() { changeGraphDims(); updateColorSelector(); } }); //make both buttons change graph dimensions (and reset the color selector)
    mode3D.setOnRelease(new Action() { public void act() { changeGraphDims(); updateColorSelector(); } });
    
    equationUp.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      int ind = getEquatIndex(); //grab index
      swapEquations(ind-1,ind);  //swap this equation w/ the one above
      equatCache.typer.resetBlinker(); //make the cursor visible
    } } });
    
    equationDown.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      int ind = getEquatIndex(); //grab index
      swapEquations(ind+1,ind);  //swap this equation w/ the one below
      equatCache.typer.resetBlinker(); //make the cursor visible
    } } });
    
    equationDelete.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      deleteEquation(); //delete the current equation
    } } });
    
    equationCanceler.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      cancelEquation(equatCache); //cancel the currently selected equation
      mmio.setTyper(null); equatCache=null; updateColorSelector(); //reset stuffs
    } } });
    
    equationVisToggle.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      if(equatCache.plot.visible ^= true) { //invert the visibility. If it is now visible:
        ungray(equatCache);                 //un-gray out the equation
      }
      else {              //if it is now currently invisible:
        gray(equatCache); //gray out the equation
      }
      saveEquationsToDisk(mmio.app, graphDim); //save changes to disk
    } } });
    
    equationMode.setOnRelease(new Action() { public void act() { if(equatCache!=null) {
      equatCache.plot.mode = equatCache.plot.mode.increment(); //switch the current mode to whatever I've decided is the next graphing mode (the loops are {NONE}, {RECT2D,POLAR,PARAMETRIC2D}, and {RECT3D,CYLINDRICAL,SPHERICAL,PARAMETRIC3D})
      
      ctrlPanel.swapGraphMode(equatCache.plot.mode); //correctly update the buttons based on this new graphing mode
      equatCache.panel.text[0].text = equatCache.plot.mode.outVar()+"="; //correctly update the output variable (e.g. y, r, z, v, ρ, etc)
      
      saveEquationsToDisk(mmio.app, graphDim); //save changes to disk
    } } });
  }
  
  ////////////////// GETTERS / SETTERS //////////////////////////
  
  void setActive(final boolean active) { bigHolder.setActive(active); }
  
  Panel getHolder(boolean dim) { return      dim ? holder3D : holder2D; } //returns the equation holder for the equations we're looking at
  Panel getHolder()            { return graphDim ? holder3D : holder2D; } //returns the equation holder for the equations we're using right now
  
  ArrayList<EquatField> getEquats(boolean dim) { return      dim ? equats3D : equats2D; } //returns the list of equations given the dimension you're looking for
  ArrayList<EquatField> getEquats()            { return graphDim ? equats3D : equats2D; }
  
  int getEquatIndex(boolean dim, EquatField field) { //obtains the index of the given field
    return getEquats(dim).indexOf(field); //return the index of the given item within the list
  }
  int getEquatIndex() { //obtains the index of the currently selected equation
    return getEquatIndex(graphDim, equatCache); //return the index of the equation cache within the current list
  }
  
  int size(boolean dim) { return      dim ? equats3D.size() : equats2D.size(); }
  int size()            { return graphDim ? equats3D.size() : equats2D.size(); }
  
  EquatField get(boolean dim, int ind) { return      dim ? equats3D.get(ind) : equats2D.get(ind); }
  EquatField get(             int ind) { return graphDim ? equats3D.get(ind) : equats2D.get(ind); }
  
  ArrayList<Graphable> plots2D() {
    plots2D.clear(); for(EquatField e : equats2D) { plots2D.add(e.plot); } return plots2D;
  }
  
  ArrayList<Graphable> plots3D() {
    plots3D.clear(); for(EquatField e : equats3D) { plots3D.add(e.plot); } return plots3D;
  }
  
  ////////////////////// UPDATES //////////////////////////////
  
  void updateColorSelector() { //updates the color selection textbox
    if(equatCache==null) { //if no equations are selected
      colorSelect.clear2();                //clear the color selection box
      colorSelect.setSurfaceFill(#001818); //make it dark cyan
    }
    
    else { //otherwise
      color stroke = equatCache.plot.stroke; //grab the stroke of the currently selected equation
      colorSelect.setSurfaceFill(stroke);    //set the background of this textbox to that color
      color contrast = saturate(~stroke);    //find the inverse of that color, then overly saturate it
      colorSelect.setTextColor(contrast);    //set the text color to that
      colorSelect.setCursorColor(contrast);  //set the cursor color to that
      String config = ((stroke>>16)&255) + "," + ((stroke>>8)&255) + "," + (stroke&255); //generate the string that shows the red, green, blue
      colorSelect.replace(config); //set the contents of the text field to that
    }
  }
  
  void updateSubscripts(boolean dim) { //updates all the subscripts in the equation list
    for(int n=0;n<size(dim);n++) {            //loop through said list
      get(dim,n).panel.text[1].text = n+1+""; //update each panel's subscript text
    }
  }
  
  void updateCheckmarks() { //looks at the currently selected equation, checks if it's different from its original form. Gives it a checkmark iff it's the same
    if(equatCache==null) { return; } //if there is no selected equation, do nothing.
    String mark;
    if(equatCache.typer.getText().equals(equatCache.cancel)) { mark = "✓"; } //strings are the same: set text to checkmark
    else { mark = ""; }                    //otherwise: set it to empty
    equatCache.panel.text[2].text = mark; //set the text right above the equals sign
  }
  
  void updateSurfaceHeight(boolean dim) { //updates the height of the holder's surface
    if(size(dim)==0) { //special case: there are no equations
      getHolder(dim).setSurfaceH(getHolder(dim).h); //just set it to the height
    } else { //otherwise
      Box secret = get(dim,size(dim)-1).panel; //grab the last box
      getHolder(dim).setSurfaceH(max(getHolder(dim).h, secret.y+secret.h)); //change surface height to either the height of the window, or to the distance to the bottom (whichever's bigger)
    }
  }
  
  void updateSurfaceHeight() { updateSurfaceHeight(graphDim); } //updates the height of the current holder's surface
  
  ////////////////// UTILITIES ///////////////////////////////
  
  EquatField buildEquation(boolean dim, int index, float y, color stroke, boolean vis, GraphMode mode, String text) { //builds a panel for us to put our equation in (returns the panel and the inner textbox)
    final Panel pan = (Panel)new Panel(0,y,bigHolder.w,equationHeight).setSurfaceFill(0).setStroke(#00FFFF).setParent(getHolder(dim)); //declare new panel for us to put our equation in
    pan.setScrollable(false,false).setDragMode(DragMode.NONE,DragMode.NONE); //make it impossible to scroll or drag
    
    float xOffset = mmio.getTextWidth("y=",Mmio.invTextHeight(equationHeight-2*Mmio.yBuff));
    final Textbox tbox = givePanelEquation(pan, dim, text, xOffset); //give us an equation textbox to type into
    tbox.setMargin(relativeMarginWidth*mmio.w);                      //give us a sizable margin to make it easier to move the cursor
    
    float offset2 = 0.027272727*bigHolder.w, offset3 = 0.05*bigHolder.w, offsetY = 0.048888889*bigHolder.h, offsetY2 = 0.0*bigHolder.h; //constants for initialization
    pan.setText(new Text(mode.outVar()+"=",pan.xSpace,tbox.ty,tbox.tSize,#00FFFF,LEFT,TOP),             //provide the y= at the beginning
                new Text(index+"",pan.xSpace+offset2,tbox.ty+offsetY,0.45*tbox.tSize,#00FFFF,LEFT,TOP), //as well as a subscript
                new Text("✓",pan.xSpace+offset3,tbox.ty+offsetY2,0.45*tbox.tSize,#008000,LEFT,TOP));    //and a checkmark
    
    Graphable grapher = new Graphable(stroke,new Equation(new ParseList(""))); //load empty graphable
    grapher.setMode(mode); //set its mode
    if(dim) { grapher.setSteps(80); } //to stop this from breaking, set 3D functions to 80 steps TODO remove when graphing is optimized
    
    final EquatField result = new EquatField(pan, tbox, grapher, ""); //create equation field with the correct panel, textbox, graphable, and an empty cancel string
    
    if(!vis) { grapher.setVisible(false); gray(result); }
    
    tbox.setOnRelease(new Action() { public void act() { //set what happens when we click on this textbox
      mmio.setTyper(tbox); equatCache=result; //when we click on an equation textbox, we select it
      updateColorSelector();                  //update the color selection box
      
      ctrlPanel.swapGraphMode(result.plot.mode); //swap our keypad buttons depending on the new mode of this button
    } });
    
    saveEquation(result); //save the equation
    
    return result; //return our result
  }
  
  Textbox givePanelEquation(Panel pan, boolean dim, String text, float xOffset) { //takes a panel and gives it an equation
    final Textbox tbox = new Textbox(xOffset,0,getHolder(dim).w-xOffset,equationHeight).setCursorColor(#00FFFF).setTextColor(#00FFFF); //declare textbox for us to type our equation in
    tbox.setSurfaceFill(0).setStroke(false).setParent(pan); tbox.setScrollable(false,false).setDragMode(DragMode.ANDROID,DragMode.NONE); //make it move like a mobile phone
    tbox.setTextPosAndAdjust(buffX,buffY); tbox.setCursorThick(cursorThick); //TODO see if this is messing up our alignment
    
    if(text.length()!=0) { tbox.replace(text); } //input the given text
    
    return tbox; //return result
  }
  
  static void gray(final EquatField eq) { //grays out equation
    eq.panel.setSurfaceFill(#555555); //make the panel gray
    eq.typer.setSurfaceFill(#555555); //make the textbox gray
    eq.typer.setTextColor(#AAAAAA); eq.typer.setCursorColor(#AAAAAA); //make the textbox's text & cursor a light gray
    for(Text t : eq.panel.text) { t.fill=#AAAAAA; } //make all of the text on the panel light gray
  }
  
  static void ungray(final EquatField eq) { //un-grays out equation
    eq.panel.setSurfaceFill(0); //make the panel black
    eq.typer.setSurfaceFill(0); //make the textbox black
    eq.typer.setTextColor(#00FFFF); eq.typer.setCursorColor(#00FFFF); //make the textbox's text & cursor cyan
    for(Text t : eq.panel.text) { t.fill=#00FFFF; } //make all the text on the panel cyan
    eq.panel.text[2].fill=#008000; //except the checkmark, make that dark green
  }
  
  void saveEquationColor(boolean save) { //updates and saves the color of the equation
    String text = colorSelect.getText(); //grab the text within the color select field
    
    boolean worked = false;
    if(text.startsWith("#")) { //first, check if it's typed with hex codes
      int col = 0; worked = true;
      try { col = 0xFF000000 | unhex(text.substring(1)); }
      catch(NumberFormatException ex) { worked = false; }
      
      if(worked) { equatCache.plot.stroke = col; }
    }
    
    if(!worked) {
      String[] rgb = text.split(",");      //split it up by commas
      
      if(rgb.length==3) { //if there are exactly 3 things separated by commas:
        worked = true;      //try to figure out if they're all valid numbers
        int red=0, green=0, blue=0; //red, green, and blue
        try {
          red = Integer.parseInt(rgb[0]); green = Integer.parseInt(rgb[1]); blue = Integer.parseInt(rgb[2]); //parse all 3 strings into integers
          worked = red==(red&255) && green==(green&255) && blue==(blue&255); //this worked if they're all between 0 and 255
        }
        catch(Exception ex) { worked = false; } //if they were unparseable, this didn't work
        
        if(worked) { //if this worked:
          equatCache.plot.stroke = 0xFF000000 | red<<16 | green<<8 | blue; //parse result into color, set the plot color
        }
      }
    }
    
    mmio.setTyper(equatCache.typer); //go back to typing in the equation box
    updateColorSelector();           //update the color selector
    if(save) { saveEquationsToDisk(mmio.app,graphDim); } //if we want to save, save
  }
  
  ////////////////// FUNCTIONALITY //////////////////////////////
  
  EquatField addEquation(boolean dim, int index, color stroke, boolean vis, GraphMode mode, String text) {
    float buttY; //We have to figure out the y position of the new plottable equation
    if(index==0) { buttY = 0; } //if this is the first equation, it goes at the top (y=0)
    else { Box secret = get(dim,index-1).panel; buttY = secret.y+secret.h; } //otherwise, select the position right below our "secret box" (the box above this one)
    
    final EquatField equat = buildEquation(dim, index, buttY, stroke,vis,mode,text); //create new equation
    
    getEquats(dim).add(index, equat); //add this equation to our list, at the correct index
    for(int n=index+1;n<size(dim);n++) { //loop through all equations after this one (we need to move them down)
      Box secret = get(dim,n-1).panel; get(dim,n).panel.setY(secret.y+secret.h); //move their y position to right below the box above them
    }
    
    updateSurfaceHeight(dim); //update the height of our surface
    
    updateSubscripts(dim); //update the subscripts for each equation
    
    saveEquationsToDisk(mmio.app,dim); //save our current equation list to disk
    
    return equat; //return result
  }
  
  void addEquation() { //TODO make me more reusable!!!
    Panel holder = getHolder(); //grab the equation list we're referencing
    
    int index = equatCache==null ? getHolder().numChildren() : getEquatIndex()+1; //first, we have to find the index we want to place this equation at
    //if an equation is selected, we wanna put this right after that. Otherwise, we put this right at the very end
    EquatField equat = addEquation(graphDim, index, #FF8000,true,graphDim?GraphMode.RECT3D:GraphMode.RECT2D,""); //add the equation
    
    mmio.setTyper(equat.typer); equatCache=equat; //select this equation for typing into
    equat.typer.resetBlinker();                   //make the cursor visible
    holder.chooseTargetRecursive(0.5*holder.w,equat.panel.y+holder.ySpace,0.5*holder.w,equat.panel.y+equat.panel.h-holder.ySpace); //choose a target so that we can see our new equation
    
    ctrlPanel.swapGraphMode(graphDim ? GraphMode.RECT3D : GraphMode.RECT2D); //display the x key (and maybe the y key)
    updateColorSelector(); //update the color selector
  }
  
  boolean deleteEquation(boolean dim, EquatField eq) { //removes a specific equation
    int ind = getEquatIndex(dim, eq); //find the index of the given equation
    if(ind==-1) { return false; } //if not found, return false
    
    getEquats(dim).remove(ind); //remove equation from the list of equations
    eq.panel.setParent(null);   //estrange from io family (so that it can be deleted)
    
    if(ind!=size(dim)) { //if the index ISN'T the last index (i.e. there are other equations after this one in the list)
      for(int n=size(dim)-1;n>ind;n--) { //loop through all equations after this one BACKWARDS (except the equation RIGHT after this one)
        get(dim,n).panel.setY(get(dim,n-1).panel.y); //set each panel's y position to that of the one before it
      }
      get(dim,ind).panel.setY(eq.panel.y); //move the equation right after the one we deleted to the position of the one we deleted
    }
    
    updateSubscripts(dim); //give every equation the correct subscript
    
    updateSurfaceHeight(dim); //update the given holder panel's surface height
    
    saveEquationsToDisk(mmio.app,dim); //save our current equation list to disk
    
    return true; //return true, since it was successful
  }
  
  boolean deleteEquation() { //deletes the equation cache (returns false if unsuccessful
    if(equatCache==null) { return false; } //if there is no equation cache, return false since it was unsuccessful
    deleteEquation(graphDim, equatCache); //delete the equation cache from the current equation list
    
    equatCache = null; mmio.setTyper(null); //set the equation cache and the typer to null
    updateColorSelector(); //update the color selection box
    getHolder().chooseTargetRecursive(); //perform targeting to avoid being out of bounds
    
    return true; //return true because it was successful
  }
  
  boolean swapEquations(final int ind1, final int ind2) { //takes two equations and swaps their indices (returns if it was successful)
    ArrayList<EquatField> equatList = getEquats(); //grab the equation list
    if(ind1<0 || ind2<0 || ind1>=size() || ind2>=size()) { return false; } //if their indices are out of bounds, do nothing & return false
    if(ind1==ind2) { return true; } //if the indices are the same, do nothing & return true
    
    EquatField first = get(ind1), second = get(ind2); //grab both equations
    equatList.set(ind1,second); equatList.set(ind2,first); //swap both equations
    float tempY = first.panel.y; first.panel.y = second.panel.y; second.panel.y = tempY; //swap their y positions
    
    updateSubscripts(graphDim); //update the subscripts
    saveEquationsToDisk(mmio.app,graphDim); //save our current equation list to disk
    
    return true; //return true because it was successful
  }
  
  void changeGraphDims() { //changes the graph dimensions
    graphDim ^= true; //swap graph dimensions
    
    holder2D.setActive(!graphDim); holder3D.setActive(graphDim); //swap which equation list we can see
    equatCache = null; mmio.setTyper(null); //set our equation cache and typer to null
    
    for(Box b : bigHolder) { //find the 2D and 3D buttons in the equation holder
      if(b.text.length!=0 && b.text[0].getText().equals("2D")) { b.setActive(!graphDim); } //make the 2D button active IFF we're in 2D mode
      if(b.text.length!=0 && b.text[0].getText().equals("3D")) { b.setActive( graphDim); } //make the 3D button active IFF we're in 3D mode
    }
    for(Box b : graphMenu) { //do the same thing for the graph menu
      if(b.text.length!=0 && b.text[0].getText().equals("2D")) { b.setActive(!graphDim); }
      if(b.text.length!=0 && b.text[0].getText().equals("3D")) { b.setActive( graphDim); }
    }
    
    if(grapher2D.visible || grapher3D.visible) { //if either graph is visible:
      grapher2D.setVisible(!graphDim); //make this active IFF in 2D mode
      grapher3D.setVisible( graphDim); //make this active IFF in 3D mode
    }
    
    String axisButton = axisMode==0 ? "Axes" : axisMode==1 ? "Labels" : "None";
    String connectButton = connect==ConnectMode.POINT ? "Points" : connect==ConnectMode.WIREFRAME ? "Wireframe" : "Surface";
    for(Box b : graphMenu) {
      if(b.text[0].getText().equals("Roots")) { ((Button)b).setActive(!graphDim); }
      else if(b.text[0].getText().equals("Inters.")) { ((Button)b).setActive(!graphDim); }
      else if(b.text[0].getText().equals(axisButton)) { ((Button)b).setActive(graphDim); }
      else if(b.text[0].getText().equals(connectButton)) { ((Button)b).setActive(graphDim); }
    }
    
    if(bigHolder.active) { ctrlPanel.swapGraphMode(graphDim ? GraphMode.RECT3D : GraphMode.RECT2D); }
  }
  
  void cancelEquation(EquatField eq) {
    eq.typer.replace(eq.cancel); //replace text with original text
    eq.panel.text[2].text = "✓"; //give equation a checkmark
  }
  
  boolean saveEquation(EquatField eq) { //saves equation (returns whether it was successful)
    if(eq==null) { return false; } //special case: null equation, don't save
    
    if(eq.typer.getText().length()==0) { //if the equation is completely empty:
      eq.plot.function = new Equation(new ParseList("")); //set the plot at that index so that it graphs this empty equation
      eq.cancel = "";                                     //set the cancel history at that index so it stores this empty string
    }
    
    else {
      ParseList parse = new ParseList(eq.typer.getText()); //create parselist from typed text
      parse.format(); //format the parselist
      
      Equation equat = new Equation(parse); //format to an equation
      equat.correctAmbiguousSymbols();      //correct ambiguous symbols
      equat.squeezeInTimesSigns();          //squeeze in * signs where applicable
      equat.setUnaryOperators();            //convert + and - to unary operators where appropriate
      
      String valid = equat.validStrings();
      if(!valid.equals("valid"))                              { /*display error message*/ return false; }
      else if(!(valid=equat.    validPars()).equals("valid")) { /*display error message*/ return false; }
      else if(!(valid=equat.leftMeHanging()).equals("valid")) { /*display error message*/ return false; }
      else if(!(valid=equat.  countCommas()).equals("valid")) { /*display error message*/ return false; }
      else {
        equat = equat.shuntingYard(); //convert from infix to postfix
        equat.parseNumbers();         //parse the numbers
        equat.arrangeRecursiveFunctions(); //implement recursive functions
        
        eq.plot.function = equat;       //set the plot to graph this equation
        eq.plot.verify1DParametric();   //check to see if it's a 1D parametric curve
        eq.cancel = eq.typer.getText(); //update the cancel string to the current input
      }
    }
    
    eq.panel.text[2].text = "✓"; //since the equation has been saved, give it a checkmark
    return true; //return true, since the equation has been saved
  }
  
  boolean saveEquation(boolean save) { //saves the currently selected equation (returns whether it was successful)
    if(saveEquation(equatCache)) { //save the equation cache. if successful:
      mmio.setTyper(null); equatCache=null; //deselect equation
      updateColorSelector();                //update the color select
      if(save) { saveEquationsToDisk(mmio.app,graphDim); } //if asked to save to disk, save to disk
      return true; //return true
    }
    return false; //otherwise, return false
  }
  
  void clearEquations(boolean dim) {
    for(EquatField eq : getEquats(dim)) { //loop through all equations
      eq.panel.setParent(null); //have their panels estrange (so they get removed by gc)
    }
    getEquats(dim).clear(); //clear the list of equations
    updateSurfaceHeight(dim); //update the equation list panel's surface height
    
    equatCache = null; mmio.setTyper(null); //set the equation cache and the typer to null
    updateColorSelector(); //update the color selection box
    getHolder().chooseTargetRecursive(); //perform targeting to avoid being out of bounds
    
    saveEquationsToDisk(mmio.app,dim); //save changes to disk
  }
  
  void clearEquations() { clearEquations(graphDim); }
  
  
  //methods to add, move, delete, cancel, toggle visibility, change graph mode, change color
  //methods to save, update subscripts, etc.
}
