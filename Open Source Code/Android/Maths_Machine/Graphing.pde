enum ConnectMode { POINT, WIREFRAME, SURFACE }

enum GraphMode {
  RECT2D, POLAR, PARAMETRIC2D, RECT3D, CYLINDRICAL, SPHERICAL, PARAMETRIC3D, NONE;
  
  int graphDim() { return this==RECT2D || this==POLAR || this==PARAMETRIC2D ? 2 : 3; }
  int inps() { return graphDim()==2 ? 1 : 2; }
  int outs() { return this==PARAMETRIC2D ? 2 : this==PARAMETRIC3D ? 3 : 1; }
  
  String[] inputs() { switch(this) {
    case RECT2D:       return new String[] {"x"};
    case POLAR:        return new String[] {"θ"};
    case PARAMETRIC2D: return new String[] {"t"};
    case RECT3D:       return new String[] {"x","y"};
    case CYLINDRICAL:  return new String[] {"θ","r"};
    case SPHERICAL:    return new String[] {"θ","φ"};
    case PARAMETRIC3D: return new String[] {"t","u"};
    default:           return new String[0];
  } }
  
  String outVar() { switch(this) {
    case RECT2D: return "y";
    case POLAR:  return "r";
    case PARAMETRIC2D: case PARAMETRIC3D: return "v";
    case RECT3D:       case CYLINDRICAL:  return "z";
    case SPHERICAL: return "ρ";
    default: return null;
  } }
  
  MathObj.VarType outType() {
    if(this==PARAMETRIC2D || this==PARAMETRIC3D) { return MathObj.VarType.VECTOR; }
    return MathObj.VarType.COMPLEX;
  }
  
  GraphMode increment() { switch(this) {
    case NONE: return NONE;
    case RECT2D: return POLAR;
    case POLAR: return PARAMETRIC2D;
    case PARAMETRIC2D: return RECT2D;
    case RECT3D: return CYLINDRICAL;
    case CYLINDRICAL: return SPHERICAL;
    case SPHERICAL: return PARAMETRIC3D;
    case PARAMETRIC3D: return RECT3D;
    default: return null;
  } }
}

public static class Graphable { //graphable function
  public color stroke = #FF8000;
  public int strokeWeight = 2;
  public GraphMode mode = GraphMode.RECT2D;
  public boolean visible = true;
  boolean par1D = false; //true in the special case that we're in 3D plotting a parametric curve (as opposed to a parametric surface)
  
  public double start=-Math.PI, end=Math.PI; //TODO make it so this can be a function of our graph position/scale
  public int steps = 1024;
  
  Equation function; //equation to map the input to the output
  
  Graphable(color col, Equation equat) {
    stroke=col;
    function = equat;
  }
  
  void setVisible(boolean vis) { visible=vis; }
  
  void setMode(GraphMode m) { mode = m; }
  void setSteps(int s) { steps = s; }
  
  void verify1DParametric() { //determines whether it's a 1-D parametric
    if(mode!=GraphMode.PARAMETRIC3D) { par1D = false; } //if not paramtric 3D, we already know it's false
    else { par1D = !function.checkForVar("u"); } //otherwise, check if there are any mentions of the variable "u". If there are, set it to false. If not, set it to true
  }
  
  //public int step = 1; //step size
}

public class Graph { //an object which can graph things out
  
  ////////// ATTRIBUTES //////////////
  
  double origX, origY;    //the pixel position of the origin on the pgraphics object
  double pixPerUnit;      //the number of pixels in a single unit length
  float tickLen=0.066666667*width; //the length of the tick lines, in pixels
  boolean visible = true; //whether the graph is visible
  
  ///////// CONSTRUCTORS /////////////
  
  Graph() { }
  
  Graph(double x, double y, double s) { origX=x; origY=y; pixPerUnit=s; } //constructor w/ attributes
  
  ////////// GETTERS/SETTERS ////////////////
  
  Graph setVisible(boolean vis) { visible=vis; return this; }
  
  
  /////////////////// DISPLAY ////////////////////
  
  void display(PGraphics pgraph, float x, float y, float wid, float hig, ArrayList<Graphable> plots) {
    if(!visible) { return; } //if invisible, quit
    
    drawGridLines(pgraph, x, y, wid, hig);
    
    graph2D(pgraph, x,y,wid,hig,plots);
  }
  
  void drawGridLines(PGraphics pgraph, float xt, float yt, float wid, float hig) { //sets up the graph by drawing all the gridlines
    //Step 1: Find how far apart each gridline should be
    //First, note the desired behavior. At original scale, each tick mark will be 1 apart. Then, as we zoom out, it'll be 2 apart. Then 5, then 10, then 20, 50, 100, 200, 500, 1000, etc.
    //The rule of thumb is to have their distance be the smallest they can be while still being at least hig/12 pixels apart. Without the above rule, that would make our tick size hig/(12*pixPerUnit) units apart
    
    //Since this is on a base 10 logarithmic scale, a logical first step would be to take the base 10 logarithm of our hypothetical tick size
    double log = Math.log(hig/(12.0*pixPerUnit))/Math.log(10); //according to our rule, the tick size should be >= 10^log
    double ceil = Math.ceil(log), frac = ceil-log; //record the ceiling of the log, as well as the fractional difference. Our tick size should either be 10^ceil, 1/2*10^ceil, or 1/5*10^ceil.
    String ticAsString;   //to get an EXACT decimal tick size w/out roundoff, we'll compute the tick size as a string then cast to a double
    double splitSize; //we'll also be drawing fainter lines between the ticks, and we also need to compute the distance between those. But they don't need to be as accurate
    int splitPerTick; //number of splitter lines per tick
    if     (frac<Math.log(2)/Math.log(10)) { ticAsString = "1E"+(long)ceil;     splitPerTick = 5; } //0 <= frac < log10(2): 10^ceil
    else if(frac<Math.log(5)/Math.log(10)) { ticAsString = "5E"+(long)(ceil-1); splitPerTick = 5; } //log10(2) <= frac < log10(5): 10^ceil / 2
    else                                   { ticAsString = "2E"+(long)(ceil-1); splitPerTick = 4; } //log10(5) <= frac < 1: 10^ceil / 5
    
    double tickSize = Double.valueOf(ticAsString); //cast string to double, now we have the tick size
    splitSize = tickSize/splitPerTick;             //compute split size
    
    //Step 2: Find where to draw the first & last gridlines. You should overshoot in all directions, so that the splitters between them don't disappear right before the edge of the screen.
    long xStart = (long)Math.floor((xt    -origX)/(pixPerUnit*tickSize)), //which multiple of tickSize to start with in the x direction
         xEnd   = (long)Math.ceil ((xt+wid-origX)/(pixPerUnit*tickSize)), //which multiple to end with
         yStart = (long)Math.floor((origY-yt-hig)/(pixPerUnit*tickSize)), //same in the y direction, but different because up/down are reversed on screens
         yEnd   = (long)Math.ceil ((origY-yt    )/(pixPerUnit*tickSize)); //same in the y direction
    
    //Step 3: Draw the splitter lines between each tick
    pgraph.stroke(24); pgraph.strokeWeight(2); //set the drawing parameters
    for(long x=xStart;x<xEnd;x++) {     //loop through all ticks in the x direction
      for(int n=0;n<splitPerTick;n++) { //draw the 4-5 splitters
        pgraph.line((float)(origX+(x*tickSize+n*splitSize)*pixPerUnit),yt,(float)(origX+(x*tickSize+n*splitSize)*pixPerUnit),yt+hig); //draw the vertical splitter lines
      }
    }
    for(long y=yStart;y<yEnd;y++) {     //now, just do the same thing in the y direction
      for(int n=0;n<splitPerTick;n++) { //draw the 4-5 splitters
        pgraph.line(xt,(float)(origY-(y*tickSize+n*splitSize)*pixPerUnit),xt+wid,(float)(origY-(y*tickSize+n*splitSize)*pixPerUnit)); //draw the horizontal splitter lines
      }
    }
    
    //Step 4: Draw the axes
    pgraph.stroke(255); pgraph.strokeWeight(2); //set the drawing parameters
    pgraph.line(xt,(float)origY,xt+wid,(float)origY); //draw the x-axis
    pgraph.line((float)origX,yt,(float)origX,yt+hig); //draw the y axis
    
    //Step 5: Draw the ticks along each axis
    float xCut=constrain((float)origX,xt,xt+wid), yCut=constrain((float)origY,yt,yt+hig); //the tick marks should be displayed, regardless of if the axes are on screen. Here are their positions on screen
    for(long x=xStart;x<xEnd;x++) { //loop through all ticks in the x direction
      if(x!=0) { pgraph.line((float)(origX+x*tickSize*pixPerUnit),yCut-0.5*tickLen,(float)(origX+x*tickSize*pixPerUnit),yCut+0.5*tickLen); } //draw each tick at appropriate lengths
    }
    for(long y=yStart;y<yEnd;y++) { //loop through all ticks in the y direction
      if(y!=0) { pgraph.line(xCut-0.5*tickLen,(float)(origY-y*tickSize*pixPerUnit),xCut+0.5*tickLen,(float)(origY-y*tickSize*pixPerUnit)); } //draw each tick at appropriate lengths
    }
    
    //Step 5: Label each tick mark
    boolean topOrBottom = origY>yt+hig-tickLen, leftOrRight = origX>xt+tickLen; //decide on which side of each axis the labels are gonna go
    
    pgraph.textAlign(CENTER,topOrBottom ? BOTTOM : TOP);
    for(long x=xStart;x<xEnd;x++) { //loop through all ticks in the x direction
      if(x==0) { continue; }
      String label = new Complex(x*tickSize).toString(12);
      float sizer = io.getTextWidth(label,20); pgraph.textSize(min(0.044444444*width,(float)(20*0.9*tickSize*pixPerUnit/sizer))); //set the textSize so that text does not overlap
      pgraph.text(label,(float)(origX+x*tickSize*pixPerUnit),yCut-(topOrBottom?0.625:-0.625)*tickLen);
    }
    
    pgraph.textSize(0.044444444*width);
    pgraph.textAlign(leftOrRight ? RIGHT : LEFT, CENTER);
    for(long y=yStart;y<yEnd;y++) { //loop through all ticks in the x direction
      if(y==0) { continue; }
      String label = new Complex(y*tickSize).toString(12);
      pgraph.text(label,xCut-(leftOrRight?0.625:-0.625)*tickLen,(float)(origY-y*tickSize*pixPerUnit));
    }
  }
  
  void graph2D(PGraphics pgraph, float xt, float yt, float wid, float hig, ArrayList<Graphable> gr) {
    for(Graphable f : gr) {
      graph2D(pgraph,xt,yt,wid,hig,f);
    }
  }
  
  void graph2D(PGraphics pgraph, float xt, float yt, float wid, float hig, Graphable f) {
    if(!visible || !f.visible || f.function.isEmpty()) { return; } //if the graph or graphable isn't visible, or the equation is empty, quit
    
    pgraph.stroke(f.stroke); pgraph.strokeWeight(f.strokeWeight); pgraph.noFill(); //set drawing parameters
    
    graph2DFunc(pgraph, xt, yt, wid, hig, f); //use method for plotting it out
  }
  
  void graph2DFunc(PGraphics pgraph, float xt, float yt, float wid, float hig, Graphable f) { //graphs the given 2D function
    HashMap<String, MathObj> feed = new HashMap<String, MathObj>(); //is fed into the solve function
    boolean works, worked=false; //whether this current point is plottable, whether the previous point was plottable
    boolean curr, prev=false;                                                 //whether we are currently in bounds, whether we were in bounds
    float xCurr=Float.NaN, yCurr=Float.NaN, xPrev=Float.NaN, yPrev=Float.NaN; //the current & previous point we plot/plotted
    
    double stepSize = (f.mode==GraphMode.RECT2D) ? 1d/pixPerUnit : (f.end-f.start)/f.steps; //how much the input increases by each iteration
    int steps = (f.mode==GraphMode.RECT2D) ? round(wid) : f.steps;
    
    double cos=0, sin=0, cosStep=0, sinStep=0; //used only for making polar graphs easier
    if(f.mode==GraphMode.POLAR) { cos=Math.cos(f.start); sin=Math.sin(f.start); cosStep=Math.cos(stepSize); sinStep=Math.sin(stepSize); }
    
    //For the sake of making calculations work, the grapher will pretend that the point right before the loop started and right after it ends are unplottable points.
    //This will force a beginShape to be called in the loop at the first plottable point, and force endshape to be called after the last plottable point. If nothing was plottable & on screen, nothing happens.
    for(int n=0;n<=steps;n++) { //loop through all x values (or whatever the input is)
      
      double inp = (f.mode==GraphMode.RECT2D) ? (xt+n-origX)*stepSize : n*stepSize+f.start; //compute current input
      
      feed.put(f.mode.inputs()[0],new MathObj(new Complex(inp))); //tell the solver to plug in this value for x/θ/t
      
      MathObj out;
      try {
        out = f.function.solve(feed); //compute the output
        if(out.type == f.mode.outType()) {    //if output type is compatible with graph type:
          if(out.isNum()) { works = out.number.isReal() && Double.isFinite(out.number.re); } //if number, we mark this point as plottable if it's real and finite
          else { works = out.vector.size()==2 && out.vector.isReal() && Double.isFinite(out.vector.get(0).re) && Double.isFinite(out.vector.get(1).re); } //if vector, we mark as plottable if 2D, real, and finite
        }
        else { works = false; } //otherwise, it isn't plottable
        //TODO give slight leeway for numbers with very small imaginary part, adjust algorithm so odd vertical asymptotes don't get connected
      }
      catch(CalculationException ex) {
        works = false;
        out = new MathObj();
      }
      
      if(works) { //if point is plottable:
        switch(f.mode) { //figure out which point we're plotting
          case RECT2D: {
            double y = out.number.re; //find point to plot
            xCurr = xt+n; yCurr = (float)(origY-y*pixPerUnit);
          } break;
          
          case POLAR: {
            double r = out.number.re; //find point to plot
            xCurr = (float)(origX+r*cos*pixPerUnit); yCurr = (float)(origY-r*sin*pixPerUnit);
          } break;
          
          case PARAMETRIC2D: {
            double x = out.vector.get(0).re, y = out.vector.get(1).re;
            xCurr = (float)(origX+x*pixPerUnit); yCurr = (float)(origY-y*pixPerUnit);
          } break;
        }
        
        if(!Float.isFinite(xCurr) && !Float.isNaN(xCurr)) {
          xCurr = xCurr>0 ? 8.5070587e37 : -8.5070587e37;
        }
        if(!Float.isFinite(yCurr) && !Float.isNaN(yCurr)) {
          yCurr = yCurr>0 ? 8.5070587e37 : -8.5070587e37; //For some reason, in the android renderer, any value greater than or equal to 2^126 will fail to render. So we set this to the next smallest value
        }
      }
      else { xCurr = yCurr = Float.NaN; } //otherwise, set the point to NaN, NaN
      
      //next, figure out whether the current AND previous point are in bounds (if they're not plottable, they're not in bounds either, by way of vacuous truth)
      curr = xCurr>=0 && xCurr<=wid+xt && yCurr>=0 && yCurr<=hig+yt; //calculate whether or not this point is on screen
       
      if(curr && !prev)           { pgraph.beginShape();        } //if the previous point wasn't plotted (either unplottable or off screen), begin shape
      if(curr && worked && !prev) { pgraph.vertex(xPrev,yPrev); } //if the previous point was off screen, and the current point is on screen, plot the previous point to connect the dots
      if(curr || works && prev)   { pgraph.vertex(xCurr,yCurr); } //if the current point is on screen, or the previous point was on screen (to connect the dots), plot this point
      if(!curr && prev)           { pgraph.endShape();          } //if the previous point was on screen, but the current point is unplottable or off screen, end shape
      
      if(f.mode==GraphMode.POLAR) { double cos2 = cos; cos = cos*cosStep - sin*sinStep; sin = cos2*sinStep + sin*cosStep; } //if in polar mode, use this angle addition formula each iteration to avoid using too much trig
      
      xPrev = xCurr; yPrev = yCurr; //set prev to curr
      prev = curr;                  //set prev to curr
      worked = works;               //set worked to works
    }
    if(prev) { pgraph.endShape(); } //if the previous point was in bounds, end connecting the dots
  }
  
  /*
  works  curr  worked  prev  what do
    0      0      0     0      nothing
    0      0      1     0      nothing (it was taken care of)
    0      0      1     1    endShape();
    1      0      0     0      nothing (it'll be taken care of)
    1      0      1     0      nothing (don't connect the asymptotes)
    1      0      1     1    vertex(curr); endShape();
    1      1      0     0    beginShape(); vertex(curr);
    1      1      1     0    beginShape(); vertex(prev); vertex(curr);
    1      1      1     1    vertex(curr);
  
  beginShape(): works && curr && (!worked || !prev)
  vertex(prev): works && curr && worked && !prev
  vertex(curr): works && (curr || worked && prev)
  endShape  (): (!works || !curr) && worked && prev
  
  curr implies works, therefore works && curr is the same as curr
  prev implies worked, therefore worked && prev is the same as prev
  
  beginShape(): curr && !prev
  vertex(prev): curr && worked && !prev
  vertex(curr): curr || works && prev
  endShape  (): !curr && prev
  */
  
  ////////////////// UPDATES /////////////////
  
  void updateFromTouches(Mmio mmio, float xt, float yt) { //uses MMIO's cursors & mouse wheel to update shift & scale
    if(!visible) { return; } //if not visible, don't interact
    
    ArrayList<Cursor> interact = new ArrayList<Cursor>(); //arraylist of all cursors which are interacting with the graph
    for(UICursor curs : mmio.cursors) { //loop through all cursors
      if(curs.anyPressed() && (curs.getSelect()==null || curs.getSelect() instanceof Mmio)) { interact.add(curs); } //add all cursors which are pressing and are selecting nothing (or selecting the MMIO)
    }
    
    if(interact.size()==1) { //if exactly one cursor is touching it, we only translate:
      origX += interact.get(0).x - interact.get(0).dx; //shift x by delta x
      origY += interact.get(0).y - interact.get(0).dy; //shift y by delta y
    }
    else if(interact.size()==2) { //(Android only) if exactly 2 cursors are touching it, we translate AND scale:
      Cursor c0 = interact.get(0), c1 = interact.get(1); //load both cursors
      
      //1: scale
      float ratio = sqrt((sq(c0.x-c1.x)+sq(c0.y-c1.y))/(sq(c0.dx-c1.dx)+sq(c0.dy-c1.dy))); //compute the ratio between the distance between both cursors before & after
      pixPerUnit *= ratio; //the size of a unit (in pixels) expands by this ratio
      
      //2: translate. This has to be done in steps
      origX-=0.5*(c0.dx+c1.dx); origY-=0.5*(c0.dy+c1.dy); //1 un-translate by previous midpoint
      origX*=ratio; origY*=ratio;                         //2 scale up by the scale factor
      origX+=0.5*(c0.x+c1.x); origY+=0.5*(c0.y+c1.y);     //3 re-translate by current midpoint
    }
    
    if(mmio.wheelEventX!=0 || mmio.wheelEventY!=0) { //(PC only) if the mousewheel has moved, we translate AND scale:
      Cursor curs = mmio.cursors.get(0); //load the cursor (it's PC, so there's exactly 1 cursor: the mouse)
      
      //1: scale
      float scale = pow(1.1,-mmio.wheelEventY-2*mmio.wheelEventX); //compute the amount by which we scale up/down
      pixPerUnit *= scale; //the size of a unit (in pixels) expands by this scale factor
      
      //2: translate. This has to be done in steps
      origX-=curs.x; origY-=curs.y; //1 un-translate by mouse position
      origX*=scale; origY*=scale;   //2 scale up by the scale factor
      origX+=curs.x; origY+=curs.y; //3 re-translate by mouse position
    }
  }
}

public class Graph3D extends Graph {
  //Something should be noted. For the sake of complying with the general accepted right hand rule, we will be plotting coordinates as such: <x,-z,-y>
  
  ////////// ATTRIBUTES //////////////
  
  double origZ; //the z location of the origin
  PMatrix3D reference =new PMatrix3D(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1), //the matrix we rotate the whole thing by
            referenceT=new PMatrix3D(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1); //its transpose (and also its inverse)
  PGraphics graph; //the pgraphics object used to draw in 3D
  
  ////////// CONSTRUCTORS //////////////
  
  Graph3D() { tickLen = 0.01*width; }
  
  Graph3D(double x, double y, double z, int w, int h, double s) { origX=x; origY=y; origZ=z; graph = createGraphics(w,h,P3D); pixPerUnit=s; tickLen = 0.01*width; } //constructor w/ attributes
  
  ////////// GETTERS/SETTERS ////////////////
  
  Graph3D setVisible(boolean v) { return (Graph3D)super.setVisible(v); }
  
  /////////////////// DISPLAY ////////////////////
  
  void display(PGraphics pgraph, float x, float y, float wid, float hig, ArrayList<Graphable> plots) {
    if(!visible) { return; } //if invisible, quit
    
    graph.beginDraw();
    graph.background(0);
    graph.perspective(PI/3.0, float(graph.width)/float(graph.height), 0.01, 5.0*sqrt(3)*graph.height);
    graph.translate(0.5*graph.width,0.5*graph.height,graph.height*sqrt(3)/2);
    graph.translate(0,0,-200);
    graph.applyMatrix(reference);
    
    drawGridLines(graph);
    
    graph3D(graph, plots, equatList.connect);
    
    graph.endDraw();
    pgraph.image(graph,x,y);
    
    drawLabels(pgraph,x,y);
  }
  
  void drawGridLines(PGraphics pgraph) {
    //Step 1: Find how far apart each gridline should be
    //First, note the desired behavior. At original scale, each tick mark will be 1 apart. Then, as we zoom out, it'll be 2 apart. Then 5, then 10, then 20, 50, 100, 200, 500, 1000, etc.
    //The rule of thumb is to have their distance be the smallest they can be while still being at least 1/8 "pixels" apart. Without the above rule, that would make our tick size 1/(8*pixPerUnit) units apart
    
    //Since this is on a base 10 logarithmic scale, a logical first step would be to take the base 10 logarithm of our hypothetical tick size
    double log = Math.log(1/(8*pixPerUnit))/Math.log(10); //according to our rule, the tick size should be >= 10^log
    double ceil = Math.ceil(log), frac = ceil-log; //record the ceiling of the log, as well as the fractional difference. Our tick size should either be 10^ceil, 1/2*10^ceil, or 1/5*10^ceil.
    String ticAsString;   //to get an EXACT decimal tick size w/out roundoff, we'll compute the tick size as a string then cast to a double
    double splitSize; //we'll also be drawing fainter lines between the ticks, and we also need to compute the distance between those. But they don't need to be as accurate
    int splitPerTick; //number of splitter lines per tick
    if     (frac<Math.log(2)/Math.log(10)) { ticAsString = "1E"+(long)ceil;     splitPerTick = 5; } //0 <= frac < log10(2): 10^ceil
    else if(frac<Math.log(5)/Math.log(10)) { ticAsString = "5E"+(long)(ceil-1); splitPerTick = 5; } //log10(2) <= frac < log10(5): 10^ceil / 2
    else                                   { ticAsString = "2E"+(long)(ceil-1); splitPerTick = 4; } //log10(5) <= frac < 1: 10^ceil / 5
    
    double tickSize = Double.valueOf(ticAsString); //cast string to double, now we have the tick size
    splitSize = tickSize/splitPerTick;             //compute split size
    
    //Step 2: Find where to draw the first & last gridlines. You should overshoot in all directions, so that the splitters between them don't disappear right before the edge of the screen.
    long xStart = (long)Math.ceil((-1-origX)/(pixPerUnit*tickSize)), //which multiple of tickSize to start with in the x direction
         xEnd   = (long)Math.ceil(( 1-origX)/(pixPerUnit*tickSize)), //which multiple to end with
         yStart = (long)Math.ceil((-1-origY)/(pixPerUnit*tickSize)), //same in the y direction, but different because up/down are reversed on screens
         yEnd   = (long)Math.ceil(( 1-origY)/(pixPerUnit*tickSize)), //same in the y direction
         zStart = (long)Math.ceil((-1-origZ)/(pixPerUnit*tickSize)), //same in the z direction
         zEnd   = (long)Math.ceil(( 1-origZ)/(pixPerUnit*tickSize)); //same in the z direction
    
    
    //Step 3: Draw the axes
    if(equatList.axisMode!=0) { //first, make sure we're allowed to display axes (note: tickmarks/labels won't be shown if axes aren't shown)
      pgraph.stroke(255);
      float xCut = constrain((float)origX,-1,1), yCut = constrain((float)origY,-1,1), zCut = constrain((float)origZ,-1,1);
      pgraph.line(-50,-50*zCut,-50*yCut,50,-50*zCut,-50*yCut);
      pgraph.line(50*xCut,-50*zCut,-50,50*xCut,-50*zCut,50);
      pgraph.line(50*xCut,-50,-50*yCut,50*xCut,50,-50*yCut);
      //pgraph.stroke(255); pgraph.noFill(); pgraph.box(100);
      
      //Step 4: Draw the ticks along each axis
      if(equatList.axisMode!=1) { //make sure we're allowed to show ticks & labels
        for(long x=xStart;x<xEnd;x++) { //loop through all ticks in the x direction
          if(x!=0) {
            pgraph.line(50*(float)(origX+x*tickSize*pixPerUnit),-50*zCut,-50*yCut-0.5*tickLen,50*(float)(origX+x*tickSize*pixPerUnit),-50*zCut,-50*yCut+0.5*tickLen); //draw each tick at appropriate lengths
          }
        }
        for(long y=yStart;y<yEnd;y++) { //loop through all ticks in the y direction
          if(y!=0) {
            pgraph.line(50*xCut,-50*zCut-0.5*tickLen,-50*(float)(origY+y*tickSize*pixPerUnit),50*xCut,-50*zCut+0.5*tickLen,-50*(float)(origY+y*tickSize*pixPerUnit)); //draw each tick at appropriate lengths
          }
        }
        for(long z=zStart;z<zEnd;z++) { //loop through all ticks in the z direction
          if(z!=0) {
            pgraph.line(50*xCut-0.5*tickLen,-50*(float)(origZ+z*tickSize*pixPerUnit),-50*zCut,50*xCut+0.5*tickLen,-50*(float)(origZ+z*tickSize*pixPerUnit),-50*yCut); //draw each tick at appropriate lengths
          }
        }
      }
    }
  }
  
  void drawLabels(PGraphics pgraph, float xShift, float yShift) {
    if(equatList.axisMode==2) {
      //Since this is on a base 10 logarithmic scale, a logical first step would be to take the base 10 logarithm of our hypothetical tick size
      double log = Math.log(1/(8*pixPerUnit))/Math.log(10); //according to our rule, the tick size should be >= 10^log
      double ceil = Math.ceil(log), frac = ceil-log; //record the ceiling of the log, as well as the fractional difference. Our tick size should either be 10^ceil, 1/2*10^ceil, or 1/5*10^ceil.
      String ticAsString;   //to get an EXACT decimal tick size w/out roundoff, we'll compute the tick size as a string then cast to a double
      double splitSize; //we'll also be drawing fainter lines between the ticks, and we also need to compute the distance between those. But they don't need to be as accurate
      int splitPerTick; //number of splitter lines per tick
      if     (frac<Math.log(2)/Math.log(10)) { ticAsString = "1E"+(long)ceil;     splitPerTick = 5; } //0 <= frac < log10(2): 10^ceil
      else if(frac<Math.log(5)/Math.log(10)) { ticAsString = "5E"+(long)(ceil-1); splitPerTick = 5; } //log10(2) <= frac < log10(5): 10^ceil / 2
      else                                   { ticAsString = "2E"+(long)(ceil-1); splitPerTick = 4; } //log10(5) <= frac < 1: 10^ceil / 5
      
      double tickSize = Double.valueOf(ticAsString); //cast string to double, now we have the tick size
      splitSize = tickSize/splitPerTick;             //compute split size
    
      //Step 2: Find where to draw the first & last gridlines. You should overshoot in all directions, so that the splitters between them don't disappear right before the edge of the screen.
      long xStart = (long)Math.ceil((-1-origX)/(pixPerUnit*tickSize)), //which multiple of tickSize to start with in the x direction
           xEnd   = (long)Math.ceil(( 1-origX)/(pixPerUnit*tickSize)), //which multiple to end with
           yStart = (long)Math.ceil((-1-origY)/(pixPerUnit*tickSize)), //same in the y direction, but different because up/down are reversed on screens
           yEnd   = (long)Math.ceil(( 1-origY)/(pixPerUnit*tickSize)), //same in the y direction
           zStart = (long)Math.ceil((-1-origZ)/(pixPerUnit*tickSize)), //same in the z direction
           zEnd   = (long)Math.ceil(( 1-origZ)/(pixPerUnit*tickSize)); //same in the z direction
      
      float xCut = constrain((float)origX,-1,1), yCut = constrain((float)origY,-1,1), zCut = constrain((float)origZ,-1,1);
      pgraph.stroke(255);
      float weight = pgraph.strokeWeight; pgraph.strokeWeight(5);
      
      pgraph.textSize(0.05*width); pgraph.textAlign(CENTER,CENTER); pgraph.fill(-1);
      
      for(long x=xStart;x<xEnd;x++) { //loop through all ticks in the x direction
        if(x!=0) {
          String label = new Complex(x*tickSize).toString(12);
          drawText(pgraph, label, 50*(float)(origX+x*tickSize*pixPerUnit),-50*zCut,-50*yCut-tickLen, xShift, yShift, tickSize);
        }
      }
      for(long y=yStart;y<yEnd;y++) { //loop through all ticks in the y direction
        if(y!=0) {
          String label = new Complex(y*tickSize).toString(12);
          drawText(pgraph, label, 50*xCut,-50*zCut-tickLen,-50*(float)(origY+y*tickSize*pixPerUnit), xShift, yShift, tickSize);
        }
      }
      for(long z=zStart;z<zEnd;z++) { //loop through all ticks in the z direction
        if(z!=0) {
          String label = new Complex(z*tickSize).toString(12);
          drawText(pgraph, label, 50*xCut+tickLen,-50*(float)(origZ+z*tickSize*pixPerUnit),-50*yCut, xShift, yShift, tickSize);
        }
      }
      
      pgraph.fill(#ff0000); drawText(pgraph, "x", 55,-50*zCut,-50*yCut, xShift, yShift, tickSize);
      pgraph.fill(#00ff00); drawText(pgraph, "y", 50*xCut,-50*zCut,-55, xShift, yShift, tickSize);
      pgraph.fill(#0000ff); drawText(pgraph, "z", 50*xCut,-55,-50*yCut, xShift, yShift, tickSize);
      
      pgraph.strokeWeight(weight);
    }
  }
  
  void drawText(PGraphics pgraph, String text, float x, float y, float z, float xShift, float yShift, double tickSize) {
    PVector adjusted = new PVector(); reference.mult(new PVector(x,y,z), adjusted);
    float inv = -graph.height*sqrt(3)/2/(adjusted.z-200);
    pgraph.text(text, inv*adjusted.x+0.5*graph.width+xShift, inv*adjusted.y+0.5*graph.height+yShift);
  }
  
  void graph3D(PGraphics pgraph, ArrayList<Graphable> plots, ConnectMode mode) {
    if(mode==ConnectMode.SURFACE) { pgraph.lights(); }
    
    for(Graphable f : plots) {
      graph3D(pgraph,f,mode);
    }
    
    /*pgraph.stroke(#FF8000); pgraph.noFill();
    
    double[][] zs = new double[101][101];
    for(int x1=0;x1<=100;x1++) { for(int y1=0;y1<=100;y1++) {
      double x2 = (x1-50)/(50*pixPerUnit)-origX, y2 = (y1-50)/(50*pixPerUnit)-origY;
      zs[x1][y1] = x2*x2-y2*y2;
      //pgraph.point(x1,50*(float)(origZ-z2*pixPerUnit),-y1);
    } }
    
    switch(mode) {
      case 0: {
        for(int x1=0;x1<=100;x1++) { for(int y1=0;y1<=100;y1++) {
          pgraph.point(x1-50,-50*(float)zs[x1][y1],50-y1);
        } }
      } break;
      case 1: {
        for(int x1=0;x1<=100;x1++) { pgraph.beginShape(); for(int y1=0;y1<=100;y1++) {
          pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1);
        } pgraph.endShape(); }
        for(int y1=0;y1<=100;y1++) { pgraph.beginShape(); for(int x1=0;x1<=100;x1++) {
          pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1);
        } pgraph.endShape(); }
      } break;
      case 2: {
        pgraph.fill(#FF8000); pgraph.noStroke();
        for(int x1=0;x1<100;x1+=2) { for(int y1=0;y1<100;y1+=2) {
          pgraph.beginShape(); pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1); pgraph.vertex(x1-48,-50*(float)zs[x1+2][y1],50-y1); pgraph.vertex(x1-48,-50*(float)zs[x1+2][y1+2],48-y1); pgraph.endShape();
          pgraph.beginShape(); pgraph.vertex(x1-50,-50*(float)zs[x1][y1],50-y1); pgraph.vertex(x1-50,-50*(float)zs[x1][y1+2],48-y1); pgraph.vertex(x1-48,-50*(float)zs[x1+2][y1+2],48-y1); pgraph.endShape();
        } }
      } break;
    }*/
  }
  
  void graph3D(PGraphics pgraph, Graphable f, ConnectMode mode) {
    if(!visible || !f.visible || f.function.isEmpty()) { return; } //if the graph or graphable isn't visible, or the equation is empty, quit
    if(f.par1D && mode==ConnectMode.SURFACE) { mode = ConnectMode.WIREFRAME; } //special case: parametric curves can't have a surface mode, so we instead draw the wireframe (connect the dots)
    
    pgraph.stroke(f.stroke); pgraph.strokeWeight(f.strokeWeight); pgraph.noFill(); //set drawing parameters
    if(mode==ConnectMode.SURFACE) { pgraph.noStroke(); pgraph.fill(f.stroke); } //special case: if in surface mode, fill the triangles, don't draw borders
    
    graph3DFunc(pgraph, f, mode); //use method for plotting it out
    
    /*pgraph.fill(#FF8000); pgraph.stroke(#FF8000);
    
    
    for(float x1=-50;x1<=50;x1++) { for(float y1=-50;y1<=50;y1++) {
      double x2 = x1/(50*pixPerUnit)-origX, y2 = y1/(50*pixPerUnit)-origY;
      double z2 = x2*x2+y2*y2;
      pgraph.point(x1,50*(float)(origZ-z2*pixPerUnit),-y1);
    } }*/
  }
  
  void graph3DFunc(PGraphics pgraph, Graphable f, ConnectMode mode) {
    HashMap<String, MathObj> feed = new HashMap<String, MathObj>(); //is fed into the solve function
    
    int steps1 = mode==ConnectMode.SURFACE ? f.steps>>1 : f.steps; //number of steps for the first input
    if(f.par1D) { steps1*=10; } //if 1-D parametric, we can use way more steps
    else if(f.mode==GraphMode.PARAMETRIC3D) { steps1>>=1; }
    double start1 = f.mode==GraphMode.RECT3D ? origX-1d/pixPerUnit : f.start; //starting point for the first input
    double end1 = f.mode==GraphMode.RECT3D ? origX+1d/pixPerUnit : f.end;     //ending point for the first input
    double scale1 = (end1-start1)/steps1;       //how far apart each consecutive input is
    
    int steps2 = f.par1D ? 1 : steps1;           //number of steps for the second input
    if(f.mode==GraphMode.PARAMETRIC3D) { steps2>>=1; }
    double start2, end2; //starting & ending point for the second input
    if(f.mode==GraphMode.RECT3D) { start2=origY-1d/pixPerUnit; end2=origY+1d/pixPerUnit; }
    else if(f.mode==GraphMode.CYLINDRICAL) { //in cylindrical, it's a bit tricky:
      double inv = 1d/pixPerUnit;
      end2 = Math.sqrt(Cpx.sq(Math.abs(origX)+inv)+Cpx.sq(Math.abs(origY)+inv)); //ending r: take the farthest out coords from the origin & find its magnitude
      double xPart = origX<inv && origX>-inv ? 0 : Cpx.sq(Math.abs(origX)-inv); //find the smallest x² (if 0 is over the interval, it's 0. Otherwise, it's the closest corner)
      double yPart = origY<inv && origY>-inv ? 0 : Cpx.sq(Math.abs(origY)-inv); //find the smallest y²
      start2 = Math.sqrt(xPart+yPart); //compute the magnitude
    }
    else { start2=f.start; end2=f.end; }
    double scale2 = (end2-start2)/steps2; //how far apart each consecutive input is
    
    double cos1=0,sin1=0,cosStep1=0,sinStep1=0, //used for making cylindrical & spherical graphs easier
           cos2=0,sin2=0,cosStep2=0,sinStep2=0, //used for making spherical graphs easier
           cos2i=0,sin2i=0;                     //used to reinitialize phi when restarting a loop
    if(f.mode==GraphMode.CYLINDRICAL || f.mode==GraphMode.SPHERICAL) { cos1=Math.cos(start1); sin1=Math.sin(start1); cosStep1=Math.cos(scale1); sinStep1=Math.sin(scale1); } //set variables if needed
    if(f.mode==GraphMode.SPHERICAL) { cos2=cos2i=Math.cos(start2); sin2=sin2i=Math.sin(start2); cosStep2=Math.cos(scale2); sinStep2=Math.sin(scale2); } //set variables if needed
    
    //first, we generate our values
    double[][][] points = new double[steps1+1][steps2+1][3]; //create a 2D array of 3D vectors
    for(int m=0;m<=steps1;m++) { //loop through values for the 1st input variable
      double inp1 = start1+scale1*m; //compute 1st input
      feed.put(f.mode.inputs()[0],new MathObj(new Complex(inp1))); //tell the solver to plug in this value for x/θ/t
      for(int n=0;n<=steps2;n++) { //loop through the values for the 2nd input variable
        double inp2 = start2+scale2*n; //compute 2nd input
        feed.put(f.mode.inputs()[1],new MathObj(new Complex(inp2))); //tell the solver to plug in this value for y/r/φ/u
        
        MathObj out;
        try {
          out = f.function.solve(feed); //compute the output
        }
        catch(CalculationException ex) {
          out = new MathObj();
        }
        //TODO see why on earth this try catch tree looks so much different than the one for plot 2D???
        
        switch(f.mode) {
          case RECT3D: {
            points[m][n][0]=inp1; points[m][n][1]=inp2;
            if(out.isNum() && out.number.isReal()) { points[m][n][2]=out.number.re; }
            else { points[m][n][2] = Double.NaN; }
          } break;
          case CYLINDRICAL: {
            points[m][n][0]=inp2*cos1; points[m][n][1]=inp2*sin1;
            if(out.isNum() && out.number.isReal()) { points[m][n][2]=out.number.re; }
            else { points[m][n][2] = Double.NaN; }
          } break;
          case SPHERICAL: {
            if(out.isNum() && out.number.isReal()) { points[m][n][0]=out.number.re*cos1*sin2; points[m][n][1]=out.number.re*sin1*sin2; points[m][n][2]=out.number.re*cos2; }
            else { points[m][n][0]=points[m][n][1]=points[m][n][2]=Double.NaN; }
          } break;
          case PARAMETRIC3D: {
            if(out.isVector() && out.vector.size()==3 && out.vector.isReal()) {
              for(int k=0;k<3;k++) { points[m][n][k]=out.vector.get(k).re; }
            }
            else {
              for(int k=0;k<3;k++) { points[m][n][k]=Double.NaN; }
            }
          } break;
        }
        
        if(f.mode==GraphMode.SPHERICAL) { double cos3 = cos2; cos2 = cos2*cosStep2 - sin2*sinStep2; sin2 = cos3*sinStep2 + sin2*cosStep2; } //if spherical, update phi
      }
      if(f.mode==GraphMode.CYLINDRICAL || f.mode==GraphMode.SPHERICAL) { double cos3 = cos1; cos1 = cos1*cosStep1 - sin1*sinStep1; sin1 = cos3*sinStep1 + sin1*cosStep1; } //if cylindrical/spherical, update theta
      if(f.mode==GraphMode.SPHERICAL) { cos2=cos2i; sin2=sin2i; } //if spherical, reset phi
    }
    
    //next, we actually draw everything out
    switch(mode) { //switch between the 3 graphing modes
      case POINT: { //points mode
        for(int m=0;m<=steps1;m++) for(int n=0;n<=steps2;n++) { //loop through both dimensions
          pgraph.point((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
        }
      } break;
      case WIREFRAME: { //wireframe mode
        for(int m=0;m<=steps1;m++) { pgraph.beginShape(); for(int n=0;n<=steps2;n++) { //loop through both dimensions, being sure to connect the dots
          pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
        } pgraph.endShape(); }
        for(int n=0;n<=steps2;n++) { pgraph.beginShape(); for(int m=0;m<=steps1;m++) { //do the same thing in the other direction
          pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
        } pgraph.endShape(); }
      } break;
      default: { //surface mode
        for(int m=0;m<steps1;m++) for(int n=0;n<steps2;n++) { //loop through both dimensions (ignoring the last points, since they aren't followed by anything)
          boolean canDo = true;
          for(int k=0;k<3;k++) { if(points[m][n][k]!=points[m][n][k] || points[m][n+1][k]!=points[m][n+1][k] || points[m+1][n][k]!=points[m+1][n][k] || points[m+1][n+1][k]!=points[m+1][n+1][k]) { canDo=false; break; } }
          if(canDo) {
            pgraph.beginShape();
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m+1][n][0]), (float)(origZ-50*pixPerUnit*points[m+1][n][2]), (float)(origY-50*pixPerUnit*points[m+1][n][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m+1][n+1][0]), (float)(origZ-50*pixPerUnit*points[m+1][n+1][2]), (float)(origY-50*pixPerUnit*points[m+1][n+1][1]));
            pgraph.endShape(); pgraph.beginShape();
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m+1][n+1][0]), (float)(origZ-50*pixPerUnit*points[m+1][n+1][2]), (float)(origY-50*pixPerUnit*points[m+1][n+1][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n+1][0]), (float)(origZ-50*pixPerUnit*points[m][n+1][2]), (float)(origY-50*pixPerUnit*points[m][n+1][1]));
            pgraph.vertex((float)(origX+50*pixPerUnit*points[m][n][0]), (float)(origZ-50*pixPerUnit*points[m][n][2]), (float)(origY-50*pixPerUnit*points[m][n][1]));
            pgraph.endShape();
          }
        }
      } break;
    }
    
    /*
    double stepSize = (f.mode==GraphMode.RECT2D) ? 1d/pixPerUnit : (f.end-f.start)/f.steps; //how much the input increases by each iteration
    int steps = (f.mode==GraphMode.RECT2D) ? round(wid) : f.steps;
    
    double cos=0, sin=0, cosStep=0, sinStep=0; //used only for making polar graphs easier
    if(f.mode==GraphMode.POLAR) { cos=Math.cos(f.start); sin=Math.sin(f.start); cosStep=Math.cos(stepSize); sinStep=Math.sin(stepSize); }
    
    //For the sake of making calculations work, the grapher will pretend that the point right before the loop started and right after it ends are unplottable points.
    //This will force a beginShape to be called in the loop at the first plottable point, and force endshape to be called after the last plottable point. If nothing was plottable & on screen, nothing happens.
    for(int n=0;n<=steps;n++) { //loop through all x values
      
      double inp = (f.mode==GraphMode.RECT2D) ? (xt+n-origX)*stepSize : n*stepSize+f.start; //compute current input
      
      feed.put(f.mode.inputs()[0],new MathObj(new Complex(inp))); //tell the solver to plug in this value for x/θ/t
      
      MathObj out = f.function.solve(feed); //compute the output
      if(out.type == f.mode.outType()) {
        if(out.isNum()) { works = out.number.isReal() && Double.isFinite(out.number.re); }
        else { works = out.vector.size()==2 && out.vector.isReal() && Double.isFinite(out.vector.get(0).re) && Double.isFinite(out.vector.get(1).re); }
      }
      else { works = false; }
      //TODO give slight leeway for numbers with very small imaginary part, adjust algorithm so odd vertical asymptotes don't get connected
      
      if(works) { //if point is plottable:
        switch(f.mode) { //figure out which point we're plotting
          case RECT2D: {
            double y = out.number.re; //find point to plot
            xCurr = xt+n; yCurr = (float)(origY-y*pixPerUnit);
          } break;
          
          case POLAR: {
            double r = out.number.re; //find point to plot
            xCurr = (float)(origX+r*cos*pixPerUnit); yCurr = (float)(origY-r*sin*pixPerUnit);
          } break;
          
          case PARAMETRIC2D: {
            double x = out.vector.get(0).re, y = out.vector.get(1).re;
            xCurr = (float)(origX+x*pixPerUnit); yCurr = (float)(origY-y*pixPerUnit);
          } break;
        }
      }
      else { xCurr = yCurr = Float.NaN; } //otherwise, set the point to NaN, NaN
      
      //next, figure out whether the current AND previous point are in bounds (if they're not plottable, they're not in bounds either, by way of vacuous truth)
      curr = xCurr>=0 && xCurr<=wid+xt && yCurr>=0 && yCurr<=hig+yt; //calculate whether or not this point is on screen
       
      if(curr && !prev)           { pgraph.beginShape();        } //if the previous point wasn't plotted (either unplottable or off screen), begin shape
      if(curr && worked && !prev) { pgraph.vertex(xPrev,yPrev); } //if the previous point was off screen, and the current point is on screen, plot the previous point to connect the dots
      if(curr || works && prev)   { pgraph.vertex(xCurr,yCurr); } //if the current point is on screen, or the previous point was on screen (to connect the dots), plot this point
      if(!curr && prev)           { pgraph.endShape();          } //if the previous point was on screen, but the current point is unplottable or off screen, end shape
      
      if(f.mode==GraphMode.POLAR) { double cos2 = cos; cos = cos*cosStep - sin*sinStep; sin = cos2*sinStep + sin*cosStep; } //if in polar mode, use this angle addition formula each iteration to avoid using too much trig
      
      xPrev = xCurr; yPrev = yCurr; //set prev to curr
      prev = curr;                  //set prev to curr
      worked = works;               //set worked to works
    }
    if(prev) { pgraph.endShape(); } //if the previous point was in bounds, end connecting the dots*/
  }
  
  ////////////////// UPDATES /////////////////
  
  void updateFromTouches(Mmio mmio, float xt, float yt) { //uses MMIO's cursors & mouse wheel to update shift, scale, and rotation
    if(!visible) { return; } //if not visible, don't interact
    
    ArrayList<Cursor> interact = new ArrayList<Cursor>(); //arraylist of all cursors which are interacting with the graph
    for(UICursor curs : mmio.cursors) { //loop through all cursors
      if(curs.anyPressed() && (curs.getSelect()==null || curs.getSelect() instanceof Mmio)) { interact.add(curs); } //add all cursors which are pressing and are selecting nothing (or selecting the MMIO)
    }
    
    if(interact.size()==1) { //if exactly one cursor is touching it, we only rotate:
      Cursor curs = interact.get(0); //grab the one cursor
      PVector amt=new PVector(curs.x-curs.dx,curs.y-curs.dy,0); //grab the amount by which the cursor moved
      referenceT.rotate(amt.mag()/200,amt.y,-amt.x,0);   //rotate the transpose by however much the mouse moved
      reference=referenceT.get(); reference.transpose(); //set reference equal to its transpose's transpose
    }
    else if(interact.size()==2) { //(Android only) if exactly 2 cursors are touching it, we zoom and translate:
      Cursor c0 = interact.get(0), c1 = interact.get(1); //load both cursors
      
      //1: scale
      float ratio = sqrt((sq(c0.x-c1.x)+sq(c0.y-c1.y))/(sq(c0.dx-c1.dx)+sq(c0.dy-c1.dy))); //compute the ratio between the distance between both cursors before & after
      pixPerUnit *= ratio; //the size of a unit (in pixels) expands by this ratio
      
      /*
      //2: translate. This has to be done in steps
      origX-=0.5*(c0.dx+c1.dx); origY-=0.5*(c0.dy+c1.dy); //1 un-translate by previous midpoint
      origX*=ratio; origY*=ratio;                         //2 scale up by the scale factor
      origX+=0.5*(c0.x+c1.x); origY+=0.5*(c0.y+c1.y);     //3 re-translate by current midpoint
      */
    }
    
    if(mmio.wheelEventX!=0 || mmio.wheelEventY!=0) { //(PC only) if the mousewheel has moved, we translate AND scale (well, for now we just scale):
      Cursor curs = mmio.cursors.get(0); //load the cursor (it's PC, so there's exactly 1 cursor: the mouse)
      
      //1: scale
      float scale = pow(1.1,-mmio.wheelEventY-2*mmio.wheelEventX); //compute the amount by which we scale up/down
      pixPerUnit *= scale; //the size of a unit (in pixels) expands by this scale factor
      
      /*
      //2: translate. This has to be done in steps
      origX-=curs.x; origY-=curs.y; //1 un-translate by mouse position
      origX*=scale; origY*=scale;   //2 scale up by the scale factor
      origX+=curs.x; origY+=curs.y; //3 re-translate by mouse position
      */
    }
  }
}
