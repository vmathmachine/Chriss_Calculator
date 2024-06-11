static class Buffer {
  
  ////////////// ATTRIBUTES /////////////////////////
  
  PGraphics graph;        //PGraphics object to load pixels onto
  boolean inUse   =false; //whether it's currently in use
  boolean canWrite=false; //whether the PGraphics is writeable
  byte usage=0;           //a record of whether is was used in the last 8 garbage collection cycles
  
  byte shouldStamp=1;     //time dependent attribute, used to label the buffer while being used to determine if it should be stamped. 1=yes, 0=no
  //when being used to display something that literally could not use a smaller buffer, we stamp it. Otherwise, we don't stamp it, since we'd be better off using a smaller buffer
  
  //////////////// CONSTRUCTORS //////////////////////
  
  Buffer(PApplet app, int w, int h) {
    graph = app.createGraphics(w,h); //load graphics buffer
  }
  
  ///////////////// GETTERS ////////////////////////
  
  PGraphics getGraphics() { return graph; }
  boolean isInUse() { return inUse; }
  byte getUsage() { return usage; }
  int width() { return graph.width; }
  int height() { return graph.height; }
  
  boolean wasUsed() { return usage!=0; } //returns whether it was used in the past 8 seconds
  
  /////////////// SETTERS ///////////////////////////
  
  void stamp() { usage|=1; } //stamps to show it's been used
  void step() { usage<<=1; } //takes 1 step: shift bits of usage recorder
  
  Buffer setShouldStamp(boolean b) { shouldStamp = b?(byte)1:0; return this; } //sets whether it should be stamped, returns self
  
  void use() { inUse=true; usage|=shouldStamp; } //sets that it's in use
  void beginDraw() { inUse=canWrite=true; usage|=shouldStamp; graph.beginDraw(); graph.clear();
    //graph.loadPixels(); java.util.Arrays.fill(graph.pixels, 0x00FFFFFF); graph.updatePixels(); //for Android and Processing 2.0, since the clear function doesn't quite work
  } //sets that it's in use AND starts editing PGraphics object (starting with clearing the background completely)
  void endDraw()   { canWrite=false; graph.endDraw();  } //stops editing PGraphics object
  void useNt() { inUse=false; } //sets that it's no longer in use (usen't)
  
  
  ////////////////// TESTING ///////////////////////////
  
  void selfTest() { graph.noFill(); graph.strokeWeight(3); graph.stroke(#FF00FF); graph.rect(0,0,graph.width,graph.height); } //test to make sure the buffer's actually there
}
