void interfaceInit(final Mmio io) {
  //Here, we have a bunch of spaghetti code used for initializing the entire user interface. Enjoy/I'm sorry.
  
  io.setSurfaceFill(0x00FFFFFF).setSurfaceDims(width,height).setPos(0,0).setDims(width,height); //initialize the entire surface
  
  //here is where we would load all the memory from storage, if that was implemented
  
  //put special sizing variables here, so they can be changed at a whim
  //final float topHig = 0.055555556*height;
  //final float /*lrBuff = 0.011111111*width, topBuff=0.011111111*height,*/ historyHig = /*0.46666667*height/*0.38888889*height*/0.51666667*height - 0.07462686*width+1/*, inpHig = 0.055555556*height*/;
  final float inpBuffX=0.022222222*width, inpBuffY=0.0077777778*height;
  //final float addButtHig=0.05*height;
  //final float equationHeight=0.055555556*height;
  final float thick1=0.0066666667*width, thick2=0.0022222222*width, thick3=0.0044444444*width;
  //final float bottMenHig = 0.044444444*height;
  
  //put special sizing variables here, so they can be changed at a whim
  //widths & heights:
  final float keyButtHig = 0.07*height;      //keypad button height
  final float queryHig = 0.055555556*height; //query box height
  final float questAnsHig;                   //the height of every question & answer
  final float equatHig = 0.055555556*height; //the height of each equation box
  final float equatButtHig = 0.05*height; //the height of each of the buttons in the equation tab
  final float tabHig = 0.055555556*height; //the height of the tabs at the top
  final float graphMenuHig = 0.044444444*height; //the height of the graphing menu at the bottom
  
  //buffers between objects
  final float keyButtHBuff, keyButtVBuff = 0.007*height; //the space between each keypad button
  final float textBuffX = 0.022222222*width, textBuffY = 0.01*height; //the horizontal and vertical buffers between the text and the edge of the buttons
  final float consoleHBuff = 0.011111111*width; //horizontal buffer between the console and the border
  final float queryToKeypad = 0.011111111*height; //the vertical buffer between the query box and the keypad
  final float consoleToTabs = 0.011111111*height; //the vertical buffer between the tabs at the top and the console
  
  Button palette = new Button(0,0,0,0).setFills(#001818,#003030,#006060).setStrokes(#008080); //a placeholder button we can steal the palette from
  palette.setStrokeWeight(thick3);
  
  //3 buttons at the top to swap between calculator modes
  Button  calcMode = (Button)new Button(        0,0,width/3,tabHig).setFills(#000080,#0000FF).setStrokes(#8080C0,#8080FF).setStrokeWeight(thick1).setParent(io).setText("Calculator",#8080FF),
         equatMode = (Button)new Button(  width/3,0,width/3,tabHig).setFills(#000080,#0000FF).setStrokes(#8080C0,#8080FF).setStrokeWeight(thick1).setParent(io).setText("Equations",#8080FF),
         graphMode = (Button)new Button(2*width/3,0,width/3,tabHig).setFills(#000080,#0000FF).setStrokes(#8080C0,#8080FF).setStrokeWeight(thick1).setParent(io).setText("  Graph  ",#8080FF);
  
  //This right here is a vertically-scrollable panel that shows the question/answer history.
  float historyHig = height-tabHig-consoleToTabs-queryHig-queryToKeypad-5*keyButtHig-5.5*keyButtVBuff; //first, compute how tall the history display is
  initializeHistoryDisplay(consoleHBuff, tabHig, consoleToTabs, historyHig, inpBuffX, inpBuffY, thick1, thick2, queryHig); //initialize the display window which shows our history of questions, answers, and mistakes
  
  // Now, we implement the screen that lets us enter all the graphable equations
  
  //initializeEquationList(palette, lrBuff,topHig+topBuff,width-2*lrBuff,historyHig+inpHig, addButtHig, equationHeight, thick2, inpBuffY); //initialize the place where we enter equations to plot
  equatList = new EquatList(io, consoleHBuff,tabHig+consoleToTabs,width-2*consoleHBuff,historyHig+queryHig, palette,equatButtHig,equatHig,thick2,inpBuffY,thick2);
  
  // Now, we implement the keypad that lets us type in all our equations
  
  
  //float buttTop = height-5*keyButtHig-4.5*keyButtVBuff; //compute where the top of the keypad should go
  ////create said keypad
  //keyPad = new Panel(0,buttTop,width,/*height-buttTop*/0.42*height+0.074626866*width, width,/*height-buttTop*/0.42*height+0.074626866*width); keyPad.setSurfaceFill(0).setStroke(false).setParent(io);
  //keyPad.canScrollY = false;
  
  //initializeKeypad(consoleToTabs, palette, thick3); //initialize the keypad we use to type stuff
  
  float buttTop = height-5*keyButtHig-5.5*keyButtVBuff; //compute where the top of the keypad should go
  
  ctrlPanel = new KeyPanel(0,buttTop,width,5*keyButtHig+5.5*keyButtVBuff,width,5*keyButtHig+5.5*keyButtVBuff);
  keyPad = ctrlPanel.panel;
  //keyPad.surfaceFillColor = #FF00FF;
  keyPad.setParent(io);
  
  float keyButtWid = width/6.7;
  keyButtHBuff = 0.1*keyButtWid; //temporary
  float rad = 0.25*keyButtWid;
  
  
  initializeKeypad(palette, keyButtWid, keyButtHig, rad, keyButtHBuff, keyButtVBuff, textBuffX, textBuffY);
  
  
  
  graphMenu = (Panel)new Panel(0,height-graphMenuHig,width,graphMenuHig); graphMenu.setSurfaceFill(false).setStroke(false).setParent(io).setActive(false);
  initializeGraphMenu(palette, graphMenuHig); //initialize the menu at the bottom of our graph that allows us to do stuff (such as trace the graph, find roots, reset position, or swap between 2D/3D mode)
  
  
  
  //now, we tell the 3 buttons at the top what to do
  calcMode.setOnRelease(new Action() { public void act() {
    history.setVisible(true);    //make the history box visible
    query.setActive(true);       //make the query box visible
    keyPad.setActive(true);      //make the keypad visible
    ctrlPanel.swapGraphMode(GraphMode.NONE); //set the graphmode to none (no relevant variables)
    equatList.setActive(false);  //make the equation list invisible
    graphMenu.setActive(false);  //make the graph menu invisible
    io.setTyper(query); equatList.equatCache=null; //we now type into the query box, and there is no equation cache
    grapher2D.setVisible(false); //make the 2D graph invisible
    grapher3D.setVisible(false); //make the 3D graph invisible
  } });
  equatMode.setOnRelease(new Action() { public void act() {
    history.setVisible(false);    //make the history box invisible
    query.setActive(false);       //make the query box invisible
    keyPad.setActive(true);       //make the keypad visible
    ctrlPanel.swapGraphMode(equatList.graphDim ? GraphMode.RECT3D : GraphMode.RECT2D); //set the graphmode to either 2D or 3D rectangular
    equatList.setActive(true);    //make the equation list visible
    graphMenu.setActive(false);   //make the graph menu invisible
    io.setTyper(null); equatList.equatCache=null; equatList.updateColorSelector(); //we now type into nothing, there is no equation cache, and we have to update the color selector
    grapher2D.setVisible(false);  //make the 2D graph invisible
    grapher3D.setVisible(false);  //make the 3D graph invisible
  } });
  graphMode.setOnRelease(new Action() { public void act() {
    history.setVisible(false);    //make the history box invisible
    query.setActive(false);       //make the query box invisible
    keyPad.setActive(false);      //make the keypad invisible
    equatList.setActive(false);   //make the equation list invisible
    graphMenu.setActive(true);    //make the graph menu visible
    io.setTyper(null); equatList.equatCache=null; //we now type into nothing, and there is no equation cache
    grapher2D.setVisible(!equatList.graphDim);    //make the 2D graph visible iff in 2D mode
    grapher3D.setVisible(equatList.graphDim);     //make the 3D graph visible iff in 3D mode
  } });
}

//creates the window for displaying the history
void initializeHistoryDisplay(final float lrBuff, final float topHig, final float topBuff, final float historyHig, final float inpBuffX, final float inpBuffY, final float thick1, final float thick2, final float inpHig) {
  final float entryHig=0.044444444*height;    //the height of each question/answer box
  final float historyTextSize = 0.017*height; //the text size for each entry
  
  history = new CalcHistory(io, -1, -1, lrBuff,topHig+topBuff,width-2*lrBuff,historyHig,entryHig, historyTextSize); //load the history display interface
  
  query = new Textbox(lrBuff,topHig+topBuff+historyHig,width-2*lrBuff,inpHig).setTextColor(#00FFFF).setCursorColor(#00FFFF); //now, create the textbox that we actually type into
  query.setSurfaceFill(0).setStroke(#00FFFF).setStrokeWeight(thick1).setParent(io); //set its drawing parameters and its parent
  query.setDragMode(DragMode.ANDROID, DragMode.NONE); //set how it's dragged (hint: only horizontally)
  query.setTextPosAndAdjust(inpBuffX,inpBuffY); //set the position of the text within the textbox
  query.setCursorThick(thick2);                 //set the cursor thickness
  
  query.setMargin(relativeMarginWidth*width); //give us some more space on the left and right
  
  io.setTyper(query); //set the typer to the query box
}

void initializeKeypad(final Button palette, float keyButtWid, float keyButtHig, float rad, float keyButtHBuff, float keyButtVBuff, float textBuffX, float textBuffY) { //initializes the keypad
  
  final KeyPad primary_orig = new KeyPad(io,palette,keyButtWid,keyButtHig,rad,keyButtHBuff,keyButtVBuff,textBuffX,textBuffY, //here, we have the main, primary keypad
                          new String[][] {{"◄","►","C","/","*","⌫"},{"(",")","7","8","9","-"},{"√","ln","4","5","6","+"},{"π","e E","1","2","3","↩"},{"▼","2nd","0","0",". i","↩"}}, //this is what each button says
                          new int   [][] {{  3,  3,  6,  4,  4,  3},{  1,  1,  1,  1,  1,  5},{  2,   2,  1,  1,  1,  4},{  1,    1,  1,  1,  1,  0},{  0,    0,  1, -1,    1, -1}}, //these are their functionalities
                          new Object[][] {{LEFT,RIGHT,null,"/","*^",(int)BACKSPACE},{"(",")","7","8","9",'-'},{"√(","ln(","4","5","6","+"},{"π","eE","1","2","3",null},{null,null,"0","0",".i",null}}); //this is what they type/do
  primary_orig.keys[0][2].setFills(#180000,#300000,#600000).setStrokes(#800000); primary_orig.keys[0][2].text[0].fill=#FF0000; //make the clear key red
  primary_orig.keys[3][5].setFills(#001800,#003000,#006000).setStrokes(#008000); primary_orig.keys[3][5].text[0].fill=#00FF00; //make the enter key green
  primary_orig.keys[3][5].setOnRelease(new Action() { public void act() { hitEnter(); } });                                    //also make the enter key press enter
  
  Button lPar = primary_orig.keys[1][0]; //Here, we add a little counter to the left parenthesis button, displaying how many left/right brackets we have
  lPar.text = new Text[] {lPar.text[0], new Text("0",0.5*keyButtWid,0.85*keyButtHig,lPar.text[0].size*0.4,lPar.text[0].fill,CENTER,CENTER)}; //add the counter at the bottom
  lPar.text[0].y                    = 0.35*keyButtHig; //vertically re-align the left parenthesis so that we can see the counter below it
  primary_orig.keys[1][1].text[0].y = 0.35*keyButtHig; //we also have to vertically re-align the right parenthesis button so that it lines up with the left parenthesis button
  
  primary_orig.keys[4][0].setOnRelease(new Action() { public void act() {
    openKeyboard();
  } });
  
  
  final EnumMap<GraphMode, KeyPad> primary = new EnumMap(GraphMode.class); //this right here will store all of the primary keypads, each keyed by which sets of variables we need to show
  
  //Now, we have to create our original keypad, but with different keys for our extra variables:
  primary.put(GraphMode.NONE, primary_orig); //add the primary, original panel
  primary.put(GraphMode.RECT2D      , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π"}, new String[] {"x π"}, new int[] {1}, new Object[] {"xπ"})); //then with the x
  primary.put(GraphMode.POLAR       , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π"}, new String[] {"θ π"}, new int[] {1}, new Object[] {"θπ"})); //the theta
  primary.put(GraphMode.PARAMETRIC2D, primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π"}, new String[] {"t π"}, new int[] {1}, new Object[] {"tπ"})); //the t
  primary.put(GraphMode.RECT3D      , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"x π","y e"}, new int[] {1,1}, new Object[] {"xπ","ye"})); //the x & y
  primary.put(GraphMode.CYLINDRICAL , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"θ π","r e"}, new int[] {1,1}, new Object[] {"θπ","re"})); //the theta & r
  primary.put(GraphMode.SPHERICAL   , primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"θ π","φ e"}, new int[] {1,1}, new Object[] {"θπ","φe"})); //the theta & phi
  primary.put(GraphMode.PARAMETRIC3D, primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"π","e E"}, new String[] {"t π","u e"}, new int[] {1,1}, new Object[] {"tπ","ue"})); //and the t & u
  
  for(KeyPad pad : primary.values()) if(pad!=primary_orig) { //now, we have to loop through all those keypads and make their variable buttons yellow
    for(int y=0;y<pad.keys.length;y++) for(int x=0;x<pad.keys[y].length;x++) { //loop through all x,y coords
      if(primary_orig.keys[y][x] != pad.keys[y][x]) {                          //if this button is different:
        pad.keys[y][x].setFills(#181800,#303000,#606000).setStrokes(#808000);  //make the non-shared buttons yellow
        pad.keys[y][x].text[0].fill = #FFFF00;                                 //make their text yellow, as well
      }
    }
  }
  
  final KeyPad secondary_orig = primary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY, //here, we have the secondary key set. It's mostly the same, but with a few things different
                                                      new String[] {"/",   "(",    ")",   "√",  "ln",  "π","e E","2nd"},
                                                      new String[] {"%","Copy","Paste", "sin", "cos","Ans",  ",","1st"}, //Mostly, the buttons on the left get swapped out, as well as the divide button becoming modulo
                                                      new int   [] {  4,     0,      0,     2,     2,    2,    1,    0},
                                                      new Object[] {"%",  null,   null,"sin(","cos(","Ans",   ",",null});
  //make the copy and paste buttons do their jobs
  secondary_orig.keys[1][0].setOnRelease(new Action() { public void act() { if(io.typer!=null) { //TODO remove this once you actually fully implement clipboard accessibility. This will take a lot of time, so no rush...
    String text = io.typer.getText(); //grab the text from the input box
    copyToClipboard(text);            //copy it to the clipboard
  } } });
  secondary_orig.keys[1][1].setOnRelease(new Action() { public void act() { if(io.typer!=null) { //TODO remove this once you actually fully implement clipboard accessibility. This will take a lot of time, so no rush...
    String text = getTextFromClipboard();     //grab the text from the clipboard
    if(text!=null) { io.typer.insert(text); } //insert it into the input box
  } } });
  
  final EnumMap<GraphMode, KeyPad> secondary = new EnumMap(GraphMode.class);
  
  //Now, we have to create the same thing, but with extra keys for our extra variables:
  secondary.put(GraphMode.NONE, secondary_orig); //we just created the standard secondary (standard=no graph mode)
  secondary.put(GraphMode.RECT2D      , secondary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"Ans"}, new String[] {"n"}, new int[] {1}, new Object[] {"n"})); //for 2D functions, Ans becomes n
  secondary.put(GraphMode.POLAR       , secondary.get(GraphMode.RECT2D)); //including rectangular, polar, and parametric
  secondary.put(GraphMode.PARAMETRIC2D, secondary.get(GraphMode.RECT2D));
  secondary.put(GraphMode.RECT3D      , secondary_orig.modClone(keyButtHBuff,keyButtVBuff,textBuffX,textBuffY,new String[] {"Ans",","}, new String[] {"n",", E"}, new int[] {1,1}, new Object[] {"n",",E"})); //for 3D functions, Ans becomes n and , becomes ,E
  secondary.put(GraphMode.CYLINDRICAL , secondary.get(GraphMode.RECT3D));
  secondary.put(GraphMode.SPHERICAL   , secondary.get(GraphMode.RECT3D)); //that goes for rectangular, cylindrical, spherical, and parametric
  secondary.put(GraphMode.PARAMETRIC3D, secondary.get(GraphMode.RECT3D));
  
  for(KeyPad pad : secondary.values()) if(pad!=secondary_orig) {
    pad.keys[3][0].setFills(#181800,#303000,#606000).setStrokes(#808000); //make the n buttons yellow
    pad.keys[3][0].text[0].fill = #FFFF00;                                //make their text yellow, as well
  }
  
  ctrlPanel.addKeypad(0,0,true,primary);
  ctrlPanel.addKeypad(0,0,false,secondary);
  
  primary_orig.keys[4][1].setOnRelease(new Action() { public void act() { //2nd key
    ctrlPanel.activity.set(0,false); //disable primary
    ctrlPanel.activity.set(1,true);  //enable secondary
    ctrlPanel.deactivate();          //deactivate
    ctrlPanel.activate();            //then reactivate
  } });
  secondary_orig.keys[4][1].setOnRelease(new Action() { public void act() { //1st key
    ctrlPanel.activity.set(1,false); //disable secondary
    ctrlPanel.activity.set(0,true);  //enable primary
    ctrlPanel.deactivate();          //deactivate
    ctrlPanel.activate();            //then reactivate
  } });
  
  ctrlPanel.activate();
  
  ctrlPanel.panel.setDragMode(DragMode.SWIPE,DragMode.NONE); //make the main control panel swipeable
  ctrlPanel.panel.promoteDist = 80; //make it somewhat hard to swipe, though
}

void initializeEquationList(final Button palette, final float x, final float y, final float w, final float h, final float addButtHig, final float equationHeight, final float thick2, final float inpBuffY) {
  equatList = new EquatList(io, x,y,w,h, palette,addButtHig,equationHeight,thick2,inpBuffY,thick2);
  
  //new Button(equatHolder.w-addButtWid,0,addButtWid,addButtHig).setPalette(palette).setParent(equatHolder).setText("Edit",#00FFFF);
}

void initializeGraphMenu(Button palette, float buttHig) {
  int amt = 6; //number of buttons at the bottom
  float buttWid = width/float(amt); //width of each button
  
  Button mode2D = (Button)new Button(0,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("2D",#00FFFF);
  Button mode3D = (Button)new Button(0,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("3D",#00FFFF).setActive(false);
  Button trace = (Button)new Button(buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Trace",#00FFFF);
  Button root = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Roots",#00FFFF);
  Button inter = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Inters.",#00FFFF);
  Button extreme = (Button)new Button(4*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Max/Min",#00FFFF);
  Button reset = (Button)new Button(5*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Reset",#00FFFF);
  
  final Button axes = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Axes",#00FFFF).setActive(false),
             labels = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Labels",#00FFFF).setActive(false),
            nothing = (Button)new Button(2*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("None",#00FFFF).setActive(false);
  
  final Button point = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Points",#00FFFF).setActive(false),
                wire = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Wireframe",#00FFFF).setActive(false),
                surf = (Button)new Button(3*buttWid,0,buttWid,buttHig).setPalette(palette).setParent(graphMenu).setText("Surface",#00FFFF).setActive(false);
  
  mode2D.setOnRelease(new Action() { public void act() { equatList.changeGraphDims(); } }); //make both of these buttons change the dimensions
  mode3D.setOnRelease(new Action() { public void act() { equatList.changeGraphDims(); } });
  
  reset.setOnRelease(new Action() { public void act() {
    if(!equatList.graphDim) { //2D graphing mode
      grapher2D.origX = 0.5*width; grapher2D.origY = 0.5*height; grapher2D.pixPerUnit = height/12.0; //reset 2D grapher
    }
    else { //3D graphing mode
      grapher3D.origX = 0; grapher3D.origY = 0; grapher3D.origZ = 0; grapher3D.pixPerUnit = 1;
      grapher3D.reference.reset(); grapher3D.referenceT.reset();
    }
  } });
  
  axes   .setOnRelease(new Action() { public void act() { equatList.axisMode = 1;    axes.setActive(false);  labels.setActive(true); } });
  labels .setOnRelease(new Action() { public void act() { equatList.axisMode = 2;  labels.setActive(false); nothing.setActive(true); } });
  nothing.setOnRelease(new Action() { public void act() { equatList.axisMode = 0; nothing.setActive(false);    axes.setActive(true); } });
  
  point.setOnRelease(new Action() { public void act() { equatList.connect = ConnectMode.WIREFRAME; point.setActive(false);  wire.setActive(true); } });
  wire .setOnRelease(new Action() { public void act() { equatList.connect = ConnectMode.SURFACE;    wire.setActive(false);  surf.setActive(true); } });
  surf .setOnRelease(new Action() { public void act() { equatList.connect = ConnectMode.POINT;      surf.setActive(false); point.setActive(true); } });
}

void updateParCount() { //updates the on-screen counter for the number of parentheses
  if(keyPad.active) { //if the keypad is visible:
    //first, find out how many open parentheses there are:
    int pars = 0;        //init to 0
    if(io.typer!=null) { //if typer isn't null:
      for(SimpleText t : io.typer.texts) { //loop through all chars in the typer
        if     (t.text=='(' || t.text=='[') { ++pars; } //if ( or [, increment
        else if(t.text==')' || t.text==']') { --pars; } //if ) or ], decrement
      }
    }
    
    //TODO optimize the below statement so that it doesn't have to search for the left parenthesis button every time
    for(Box b : keyPad) { if(b instanceof Button) { //loop through all buttons
      if(b.text[0].text.equals("(")) { //look for left parenthesis button
        if(io.typer==null) { b.text[1].text =      ""; } //if typer is null, make counter invisible
        else               { b.text[1].text = pars+""; } //otherwise, display number of parentheses
      }
    } }
  }
}


void findAnswer(CalcHistory history) {
  if(io.typer.getText().length()==0) { return; } //empty text: do nothing. I'm serious, do nothing!
  
  ParseList parse = new ParseList(io.typer.getText()); //create parselist from calculator input
  parse.format(); //format the parselist
  
  Equation equat = new Equation(parse); //format to an equation
  equat.correctAmbiguousSymbols();      //correct ambiguous symbols
  equat.squeezeInTimesSigns();          //squeeze in * signs where applicable
  equat.setUnaryOperators();            //convert + and - to unary operators where appropriate
  
  String valid = equat.validStrings();
  if(!valid.equals("valid"))                              { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else if(!(valid=equat.    validPars()).equals("valid")) { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else if(!(valid=equat.leftMeHanging()).equals("valid")) { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else if(!(valid=equat.  countCommas()).equals("valid")) { history.addEntry(io.typer.getText()+"", valid, new MathObj(valid), true); }
  else {
    equat = equat.shuntingYard(); //convert from infix to postfix
    equat.parseNumbers();         //parse the numbers
    equat.arrangeRecursiveFunctions(); //implement recursive functions
    
    HashMap<String, MathObj> mapper = new HashMap<String, MathObj>(); //create map of variable names to their values
    
    int ind;
    for(ind=0; ind<history.entries && !history.getAnswerExact(ind).isNormal(); ind++) { } //find the most recent answer that isn't a message or empty
    
    if(ind==history.entries) { mapper.put("Ans",new MathObj(new Complex(Double.NaN))); } //if N/A, set it to NaN
    else                     { mapper.put("Ans", history.getAnswerExact(ind).clone()); } //otherwise, set it to that answer
    
    
    /*time2 = System.currentTimeMillis(); //DEBUG
    while(time2==System.currentTimeMillis()) { }
    time2 = System.currentTimeMillis();
    for(int n=0;n<1000;n++) {
      equat.solve(mapper);
    }
    println("Time for full solve: "+0.001*(System.currentTimeMillis()-time2)+"s"); //DEBUG*/
    
    
    MathObj answer = equat.solve(mapper);
    
    //if(answer.isNum() && answer.number.equals(69)) {  } //TODO make this play the sound "nice" as a joke
    
    history.addEntry(io.typer.getText()+"", answer+"", answer, true);
    
    io.typer.clear(); io.typer.fixWidth(); io.typer.cursor=0; io.typer.setScrollX(0);
  }
  
  history.holder.chooseTarget(history.holder.w/2,Math.nextDown(history.holder.surfaceH-history.holder.ySpace)); //target to the bottom so we can see the answer (next down is used to avoid roundoff induced targeting errors)
}

void hitEnter() {
  if(io.typer!=null) {
    if(io.typer==query) {
      findAnswer(history);
    }
    else if(equatList.equatCache!=null && io.typer==equatList.equatCache.typer) {
      equatList.saveEquation(true);
    }
    else if(io.typer==equatList.colorSelect) {
      equatList.saveEquationColor(true);
    }
  }
}

static color saturate(color inp) {
  float red = ((inp>>16)&255)-127.5, green = ((inp>>8)&255)-127.5, blue = (inp&255)-127.5, ratio;
  if(abs(red)>=abs(green) && abs(red)>=abs(blue)) { ratio = 127.5/abs(red); }
  else if(abs(green)>=abs(red) && abs(green)>=abs(blue)) { ratio = 127.5/abs(green); }
  else { ratio = 127.5/abs(blue); }
  
  red*=ratio; green*=ratio; blue*=ratio;
  return 0xFF000000 | round(red+127.5)<<16 | round(green+127.5)<<8 | round(blue+127.5);
}
