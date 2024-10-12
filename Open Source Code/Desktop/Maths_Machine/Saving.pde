/*import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.Context;
import android.app.Activity;
import android.os.Looper;

import android.content.SharedPreferences;*/

/////////////////////////////////////// SAVING/LOADING HISTORY TO/FROM DISK ///////////////////////////////////////////

void saveQuestionToDisk(int index, Textbox question, String path) { //saves question to disk
  PrintWriter writer = createWriter(path+dirChar+"question "+index+".txt");
  writer.println(question.getText());
  writer.flush(); writer.close();
}

void saveAnswerToDisk(int index, Textbox answer, String path) { //saves answer to disk
  PrintWriter writer = createWriter(path+dirChar+"answer "+index+".txt");
  writer.println(answer.getText());
  writer.flush(); writer.close();
}

void saveAnswerExactToDisk(int index, MathObj answer, String path) { //saves exact answer to disk
  PrintWriter writer = createWriter(path+dirChar+"answer exact "+index+".txt");
  writer.println(answer.saveAsString());
  writer.flush(); writer.close();
}

void saveBaseSettingsToDisk(CalcHistory history, String path) {
  PrintWriter writer = createWriter(path+dirChar+"base settings.txt");
  writer.println(hex(history.entries));
  writer.println(hex(history.carousel));
  writer.flush(); writer.close();
}


void loadQuestionFromDisk(int index, Textbox question, String path) {
  BufferedReader reader = createReader(path+dirChar+"question "+index+".txt");
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { line = null; ex.printStackTrace(); }
  question.replace(line); //put that line into the question field
  try { reader.close(); } catch(IOException ex) { ex.printStackTrace(); }
}

void loadAnswerFromDisk(int index, Textbox answer, String path) {
  BufferedReader reader = createReader(path+dirChar+"answer "+index+".txt");
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { line = null; ex.printStackTrace(); }
  setAnswerContents(answer, line); //put the contents of that answer into the answer field
  try { reader.close(); } catch(IOException ex) { ex.printStackTrace(); }
}

MathObj loadAnswerExactFromDisk(int index, String path) {
  BufferedReader reader = createReader(path+dirChar+"answer exact "+index+".txt");
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { line = null; ex.printStackTrace(); }
  MathObj answerExact = MathObj.loadFromString(line); //put the contents of that answer into this answer
  try { reader.close(); } catch(IOException ex) { ex.printStackTrace(); }
  return answerExact;
}

void loadBaseSettingsFromDisk(CalcHistory history, String path) {
  BufferedReader reader = createReader(path+dirChar+"base settings.txt"); //load the file where all the base settings are listed
  String line;
  try { line = reader.readLine(); } catch(IOException ex) { ex.printStackTrace(); line = null; } history. entries = unhex(line); //set the number of questions & answers
  try { line = reader.readLine(); } catch(IOException ex) { ex.printStackTrace(); line = null; } history.carousel = unhex(line); //set the carousel index
  try {        reader.close();    } catch(IOException ex) { ex.printStackTrace(); } //close the reader
}






static void saveEquationsToDisk(PApplet app, boolean dim) {
  PrintWriter writer = app.createWriter("saves"+dirChar+(dim?"3":"2")+"D Equations.txt"); //open the file we have to write to
  ArrayList<EquatList.EquatField> equats = equatList.getEquats(dim); //load the equation list we have to save
  writer.println(equats.size()); //print the number of equations
  for(EquatList.EquatField eq : equats) { //loop through all equations
    writer.println(hex(eq.plot.stroke)); //print their stroke,
    writer.println(eq.plot.visible);     //their visibility,
    writer.println(eq.plot.mode);        //their graphing mode,
    writer.println(eq.cancel);           //and their text
  }
  writer.flush(); writer.close(); //flush and close the stream
}

void loadEquations() { loadEquations(false); loadEquations(true); }

void loadEquations(boolean dim) {
  BufferedReader reader = createReader("saves"+dirChar+(dim?"3":"2")+"D Equations.txt");
  int size;
  try { size = int(reader.readLine()); }
  catch(IOException ex) { ex.printStackTrace(); return; }
  
  for(int n=0;n<size;n++) {
    String line1, line2, line3;
    try { line1=reader.readLine(); line2=reader.readLine(); line3=reader.readLine(); }
    catch(IOException ex) { line1=line2=line3=null; ex.printStackTrace(); }
    
    color stroke = unhex(line1); boolean vis = line2.equals("true"); GraphMode mode = GraphMode.valueOf(line3); //grab the first 3 attributes: stroke color, visibility, and graphing mode
    
    String text;
    try { text=reader.readLine(); }
    catch(IOException ex) { text=null; ex.printStackTrace(); }
    
    equatList.addEquation(dim,n, stroke,vis,mode,text);
  }
  try { reader.close(); }
  catch(IOException ex) { ex.printStackTrace(); }
}




///////////////////////////////////////// CLIPBOARD STUFF ///////////////////////////////////

/////// FOR PC ////////////////////////

//This next set of code is dumped from:
//https://forum.processing.org/two/discussion/8950/pasted-image-from-clipboard-is-black
//https://forum.processing.org/two/discussion/17270/why-this-getx-method-is-missing-in-processing-3-1-1

static Object getFromClipboard(DataFlavor flavor) { //extracts all items of flavor "flavor" from the clipboard, and returns them as an abstract object
  Clipboard clipboard=Toolkit.getDefaultToolkit().getSystemClipboard(); //create an instance of the "Clipboard" class with the contents of the clipboard
  Transferable contents=clipboard.getContents(null);                    //get them onto a "Transferable" object
  Object object=null;                                                   //create an object to dump the contents onto
  
  if(contents!=null && contents.isDataFlavorSupported(flavor)) { //if the contents aren't null, and this data flavor is supported:
    try { object = contents.getTransferData(flavor); } //try getting transferable data
    catch(UnsupportedFlavorException e1) { }           //requested data flavor not supported (unlikely but still possible)
    catch(java.io.IOException e2) { }                  //data no longer available in the requested flavor
  }
  return object; //return the object
}

static String getTextFromClipboard(){ //this extracts string data from the clipboard (if applicable)
  String text=(String)getFromClipboard(DataFlavor.stringFlavor); //get string flavored data and cast to a string
  return text;                                                   //return the text
}

//And this set is dumped from:
//https://stackoverflow.com/questions/11596368/set-clipboard-contents

static void copyToClipboard(String text) {
  StringSelection selection = new StringSelection(text);
  Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
  clipboard.setContents(selection, selection);
}





/*String printSupportedDataFlavors() {
  DataFlavor[] avail=Toolkit.getDefaultToolkit().getSystemClipboard().getAvailableDataFlavors();
  StringList formats=new StringList();
  for(DataFlavor f : avail) {
    String edit=f+"";
    edit=edit.substring(edit.indexOf(";")+1);
    edit=edit.substring(0,edit.length()-1);
    if(edit.indexOf(";")!=-1) { edit=edit.substring(0,edit.indexOf(";")); }
    edit=edit.substring("representationclass=".length());
    while(edit.indexOf(".")!=-1) { edit=edit.substring(edit.indexOf(".")+1); }
    
    boolean add = true;
    for(String s : formats) {
      if(edit.equals(s)) { add=false; break; }
    }
    if(add) { formats.append(edit); }
  }
  
  String ret="";
  for(String s : formats) {
    if(!s.equals(formats.get(0))) { ret+=", "; }
    ret+=s;
  }
  return ret;
}*/

public static char directoryCharacter() {
  return System.getProperty("os.name").contains("Windows") ? '\\' : '/';
}
