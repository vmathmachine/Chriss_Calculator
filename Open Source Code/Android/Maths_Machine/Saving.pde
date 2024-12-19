/*import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Intent;
import android.content.Context;
import android.app.Activity;
import android.os.Looper;

import android.content.SharedPreferences;*/

int carouselIndex; //the index at which question 0 is saved onto the disk
static SharedPreferences sharedPref; //the shared preferences object

void androidInitSharedPreferences() { //initializes shared preferences object
  sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
}

////////////////////// CUSTOM VARIABLE SAVING / LOADING FUNCTIONALITY /////////////////////////////////

static void putDouble(SharedPreferences.Editor editor, String name, double dub) { //puts a double in disk with a key name
  editor.putLong(name,Double.doubleToLongBits(dub)); //convert to 64 bit number, store it away
}

static void putComplex(SharedPreferences.Editor editor, String name, Complex comp) { //puts a complex in disk with a key name
  putDouble(editor,name+" re",comp.re); //put away the real part
  putDouble(editor,name+" im",comp.im); //put away the imaginary part
}
static void removeComplex(SharedPreferences.Editor editor, String name) { //removes a complex from disk, given the key name
  editor.remove(name+" re"); //remove the real part
  editor.remove(name+" im"); //remove the imaginary part
}

static double getDouble(SharedPreferences pref, String name, double dub) { //grabs a double from disk, given the key name
  return Double.longBitsToDouble(pref.getLong(name,Double.doubleToLongBits(dub))); //grab the long at that position, convert its 64 bits to a double
}

static Complex getComplex(SharedPreferences pref, String name, Complex comp) { //grabs a complex from disk, given the key name
  return new Complex(getDouble(pref,name+" re",comp.re),getDouble(pref,name+" im",comp.im)); //grab the doubles at both positions, create complex number from real & imaginary parts
}

static void putMathObj(SharedPreferences pref, SharedPreferences.Editor editor, String name, MathObj obj) { //puts a math object in disk w/ a key name
  removeMathObj(pref, editor, name); //first, remove what's already there
  
  editor.putString(name+" type",obj.type.name()); //now, put away the type
  switch(obj.type) {                              //now, what we do next depends on the object type
    case BOOLEAN: editor.putBoolean(name+" bool", obj.bool); break;      //boolean: store boolean
    case COMPLEX: putComplex(editor,name+" complex", obj.number); break; //complex: store complex
    case VECTOR: { //vector:
      editor.putInt(name+" size",obj.vector.size()); //store the length
      for(int n=0;n<obj.vector.size();n++) { putComplex(editor,name+" ["+n+"]",obj.vector.get(n)); } //store each complex component, keying with the index
    } break;
    case MATRIX: { //matrix:
      editor.putInt(name+" h",obj.matrix.h); editor.putInt(name+" w",obj.matrix.w); //store the height & width
      for(int i=1;i<=obj.matrix.h;i++) for(int j=1;j<=obj.matrix.w;j++) { //loop through all components
        putComplex(editor,name+" ["+i+"]["+j+"]",obj.matrix.get(i,j)); //store each component, keying with the indices
      }
    } break;
    case DATE: editor.putLong(name+" date",obj.date.day); break; //date: store the days since epoch
    case VARIABLE: editor.putString(name+" variable",obj.variable); break; //variable: store the variable name
    case ARRAY: { //array:
      editor.putInt(name+" size",obj.array.length); //store the length
      for(int n=0;n<obj.array.length;n++) { //loop through each component
        putMathObj(pref, editor, name+" array ["+n+"]", obj.array[n]); //save each component
      }
    } break;
    case EQUATION: throw new RuntimeException("AAAAAAH! I CAN'T SAVE EQUATIONS YET!"); //equation: AAAAAAAAAAHHH!!!
    case MESSAGE: editor.putString(name+" message",obj.message); break; //message: store the message
    case NONE: break; //none: save nothing (just knowing the type is enough)
  }
}

static void removeMathObj(SharedPreferences pref, SharedPreferences.Editor editor, String name) { //removes the math object stored at a particular location
  String typeString = pref.getString(name+" type",""); //first, find the type
  if(typeString.equals("")) { return; }                //if we found nothing, there's nothing to remove (return)
  
  switch(typeString) { //switch the type
    case "BOOLEAN": editor.remove(name+" bool"); break; //boolean: remove the boolean
    case "COMPLEX": removeComplex(editor, name+" complex"); break; //complex: remove the complex number
    case "VECTOR": { //vector:
      int size = pref.getInt(name+" size",0); //find the size
      editor.remove(name+" size");            //remove the size
      for(int n=0;n<size;n++) { removeComplex(editor, name+" ["+n+"]"); } //loop through & remove all elements
    } break;
    case "MATRIX": { //matrix:
      int h = pref.getInt(name+" h",0), w = pref.getInt(name+" w",0); //find the height & width
      editor.remove(name+" h"); editor.remove(name+" w");             //remove the height & width
      for(int i=1;i<=h;i++) for(int j=1;j<=w;j++) { removeComplex(editor, name+" ["+i+"]["+j+"]"); } //loop through & remove all elements
    } break;
    case "DATE": editor.remove(name+" date"); break; //date: remove the stored day
    case "VARIABLE": editor.remove(name+" variable"); break; //variable: remove the stored variable
    case "ARRAY": { //array:
      int len = pref.getInt(name+" size",0); //find the length
      editor.remove(name+" size");           //remove the length
      for(int i=0;i<len;i++) { removeMathObj(pref, editor, name+" array ["+i+"]"); } //remove each individual element
    } break;
    case "EQUATION": throw new RuntimeException("AAAAAAAAAAH! I CAN'T SAVE EQUATIONS YET!"); //equation: AAAAAAAAAAAAHHH!!!
    case "MESSAGE": editor.remove(name+" message"); break; //message: remove the message
    case "NONE": break; //none: do nothing
  }
  
  editor.remove(name+" type"); //remove what remains of this stored entity
}

static MathObj getMathObj(SharedPreferences pref, String name) { //obtains the math object, given the keyed name
  String typeString = pref.getString(name+" type",""); //find the type
  if(typeString.equals("")) { return new MathObj(); } //if there's nothing here, return the empty math object
  
  switch(typeString) { //switch the type
    case "BOOLEAN": return new MathObj(pref.getBoolean(name+" bool",false));           //boolean: return that bool
    case "COMPLEX": return new MathObj(getComplex(pref,name+" complex",new Complex())); //complex: return that complex
    case "VECTOR": { //vector:
      Complex[] arr = new Complex[pref.getInt(name+" size",0)]; //find the size, generate array to store all elements
      for(int n=0;n<arr.length;n++) { arr[n] = getComplex(pref,name+" ["+n+"]",new Complex()); } //loop through array, load & set each element
      return new MathObj(new CVector(arr)); //return vector loaded from that array
    }
    case "MATRIX": { //matrix:
      int h = pref.getInt(name+" h",0), w = pref.getInt(name+" w",0); //find the height & width
      Complex[] arr = new Complex[h*w]; //generate array to store all elements
      for(int i=0;i<h;i++) for(int j=0;j<w;j++) { arr[i*w+j] = getComplex(pref,name+" ["+(i+1)+"]["+(j+1)+"]",new Complex()); } //loop through array, load & set each element
      return new MathObj(new CMatrix(h, w, arr)); //load matrix from dimensions & elements, return resulting math object
    }
    case "DATE": return new MathObj(new Date(pref.getLong(name+" date",0))); //date: return that date
    case "VARIABLE": return new MathObj(true, pref.getString(name+" variable","")); //variable: return that variable
    case "ARRAY": { //array:
      int len = pref.getInt(name+" size",0); //find the length
      MathObj[] arr = new MathObj[len]; //generate array to store all elements
      for(int i=0;i<len;i++) { arr[i] = getMathObj(pref, name+" array ["+i+"]"); } //loop through array, load and set each element
      return new MathObj(arr); //return math object containing that array
    }
    case "EQUATION": throw new RuntimeException("AAAAAAAAAAH! I CAN'T SAVE EQUATIONS YET!"); //equation: AAAAAAAAAAAAAAAHHH!!!
    case "MESSAGE": return new MathObj(false, pref.getString(name+" message","")); //message: return that message
    default: return new MathObj(); //otherwise, return empty math object
  }
}

/////////////////////////////////////// SAVING/LOADING HISTORY TO/FROM DISK ///////////////////////////////////////////

void saveQuestionToDisk(int index, Textbox question, SharedPreferences.Editor editor) { //saves question to disk
  editor.putString("History question "+index, question.getText()); //just save it as a string
}

void saveAnswerToDisk(int index, Textbox answer, SharedPreferences.Editor editor) { //saves answer to disk
  editor.putString("History answer "+index, answer.getText()); //just save it as a string
}

void saveAnswerExactToDisk(int index, MathObj answer, SharedPreferences.Editor editor) { //saves exact answer to disk
  putMathObj(sharedPref, editor, "History answer exact "+index, answer); //save it using that other function I made
}

void saveBaseSettingsToDisk(CalcHistory history, SharedPreferences.Editor editor) {
  editor.putInt("History entries", history.entries);
  editor.putInt("History carousel", history.carousel);
}


void loadQuestionFromDisk(int index, Textbox question) {
  String text = sharedPref.getString("History question "+index, ""); //grab the text at this index
  question.replace(text); //put that text into the question field
}

void loadAnswerFromDisk(int index, Textbox answer) {
  String text = sharedPref.getString("History answer "+index, ""); //grab the text at this index
  setAnswerContents(answer, text); //put the contents of that answer into the answer field
}

MathObj loadAnswerExactFromDisk(int index) {
  return getMathObj(sharedPref, "History answer exact "+index);
}

void loadBaseSettingsFromDisk(CalcHistory history) {
  history.entries = sharedPref.getInt("History entries", 128);
  history.carousel = sharedPref.getInt("History carousel", 0);
}


/////////////////////// SAVING/LOADING NEW VARIABLE ASSIGNMENTS TO/FROM DISK ////////////////////////////

static void saveVariablesToDisk(SharedPreferences pref, String[] keys, HashMap<String, MathObj> map) {
  SharedPreferences.Editor editor = pref.edit();
  
  saveVarsToDisk(pref, editor, keys, map);
  
  editor.apply();
}

static void saveVarsToDisk(SharedPreferences pref, SharedPreferences.Editor editor, String[] keys, HashMap<String, MathObj> map) {
  //first, we remove all the variables (yeah, I know it's inefficient, we'll worry about that later)
  for(int n=0;n<keys.length;n++) {
    editor.remove("Var key "+n);
    removeMathObj(pref, editor, "Var val "+n);
  }
  
  //next, we have to add the variables back
  int ind = 0;
  for(Map.Entry<String, MathObj> entry : map.entrySet()) {
    editor.putString("Var key "+ind, entry.getKey());
    putMathObj(pref, editor, "Var val "+ind, entry.getValue());
    ind++;
  }
  
  editor.putInt("Var length", map.size()); //replace the saved number of variables
}

static HashMap<String, MathObj> loadVariablesFromDisk(SharedPreferences pref) {
  HashMap<String, MathObj> map = new HashMap<String, MathObj>();
  
  //first, we find the number of variables stored
  int numVars = pref.getInt("Var length", 0); //get the number of saved variables
  
  for(int n=0;n<numVars;n++) {
    String key = pref.getString("Var key "+n, ""); //grab each key
    MathObj val = getMathObj(pref, "Var val "+n);  //and value
    
    map.put(key, val); //map each key to each value
  }
  
  return map;
}




/*void saveHistoryEntry() { //saves the most recent history entry
  //SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
  
  SharedPreferences.Editor editor = sharedPref.edit();
  
  editor.putString("History "+carouselIndex, ((Textbox)historyShow.getChild(historyShow.numChildren()-2)).getText());
  editor.putString("History "+(carouselIndex+1), ((Textbox)historyShow.getChild(historyShow.numChildren()-1)).getText());
  putMathObj(sharedPref, editor, "Answer "+(carouselIndex>>1), answers.get(answers.size()-1));
  
  carouselIndex = (carouselIndex+2) % historyShow.numChildren();
  editor.putInt("Carousel Index", carouselIndex);
  
  //editor.commit(); //????????
  editor.apply();
}

void clearHistoryFromDisk() { //deletes the history
  //SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
  SharedPreferences.Editor editor = sharedPref.edit();
  
  for(int n=0;n<historyShow.numChildren();n++) {
    editor.putString("History "+n, "");
    if((n&1)==0) { putMathObj(sharedPref, editor, "Answer "+(n>>1), new MathObj()); }
  }
  //editor.commit(); //??????
  editor.apply();
}

void saveHistory() {
  //SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
  SharedPreferences.Editor editor = sharedPref.edit();
  
  int ind = carouselIndex;
  for(Box b : historyShow) {
    editor.putString("History "+ind, ((Textbox)b).getText());
    ind = (ind+1) % historyShow.numChildren();
  }
  editor.apply();
}*/

static void saveEquationsToDisk(boolean dim) {
  String prefix = dim ? "3D Equation " : "2D Equation ";
  SharedPreferences.Editor editor = sharedPref.edit();
  
  ArrayList<EquatList.EquatField> equats = equatList.getEquats(dim); //load the equation list we have to save
  
  editor.putInt(prefix+"Number", equats.size()); //write the number of equations
  for(int n=0;n<equats.size();n++) { //loop through all the equations
    editor.putInt(prefix+n+" stroke", equats.get(n).plot.stroke);   //save their stroke,
    editor.putBoolean(prefix+n+" vis", equats.get(n).plot.visible); //their visibility,
    editor.putString(prefix+n+" mode", equats.get(n).plot.mode+""); //their graphing mode,
    editor.putString(prefix+n, equats.get(n).cancel);               //and their text
  }
  
  editor.apply(); //apply changes
}

/*void loadHistory() {
  //SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
  
  carouselIndex = sharedPref.getInt("Carousel Index", historyShow.numChildren()-2);
  //println(carouselIndex); //DEBUG
  
  int ind=carouselIndex;
  boolean ans = false;
  for(Box b : historyShow) {
    String historyVal = sharedPref.getString("History "+ind, "");
    
    Textbox t = (Textbox)b;
    t.setTextX(Mmio.xBuff);
    t.readInput(new int[] {'C','I',0}, new String[] {historyVal});
    if(ans && t.w == t.surfaceW) {
      float shift = t.getX(t.size()) - t.tx; //compute the position of the far right of the text
      t.setTextX(t.w-shift-t.tx);
    }
    ans ^= true;
    
    ind = (ind+1) % historyShow.numChildren();
  }
  
  for(int n=0;n<answers.size();n++) {
    ind = (n + (carouselIndex>>1)) % answers.size();
    MathObj answ = getMathObj(sharedPref, "Answer "+ind);
    
    answers.set(n, answ);
  }
}*/

void loadEquations() { loadEquations(false); loadEquations(true); }

void loadEquations(boolean dim) {
  //SharedPreferences sharedPref = getActivity().getPreferences(Context.MODE_PRIVATE);
  String prefix = dim ? "3D Equation " : "2D Equation ";
  int size = sharedPref.getInt(prefix+"Number", 0);
  
  for(int n=0;n<size;n++) {
    
    color stroke = sharedPref.getInt(prefix+n+" stroke", #FF8000); //grab the stroke
    boolean vis = sharedPref.getBoolean(prefix+n+" vis", true);    //grab the visibility
    GraphMode mode = GraphMode.valueOf(sharedPref.getString(prefix+n+" mode","RECT2D")); //grab the graphing mode
    
    String text = sharedPref.getString(prefix+n, "");
    
    equatList.addEquation(dim,n, stroke,vis,mode,text);
  }
}




///////////////////////////////////////// CLIPBOARD STUFF ///////////////////////////////////

/////// FOR PC ////////////////////////

//This next set of code is dumped from:
//https://forum.processing.org/two/discussion/8950/pasted-image-from-clipboard-is-black
//https://forum.processing.org/two/discussion/17270/why-this-getx-method-is-missing-in-processing-3-1-1

/*static Object getFromClipboard(DataFlavor flavor) { //extracts all items of flavor "flavor" from the clipboard, and returns them as an abstract object
  Clipboard clipboard=Toolkit.getDefaultToolkit().getSystemClipboard(); //create an instance of the "Clipboard" class with the contents of the clipboard
  Transferable contents=clipboard.getContents(null);                    //get them onto a "Transferable" object
  Object object=null;                                                   //create an object to dump the contents onto
  
  if(contents!=null && contents.isDataFlavorSupported(flavor)) { //if the contents aren't null, and this data flavor is supported:
    try { object = contents.getTransferData(flavor); } //try getting transferable data
    catch(UnsupportedFlavorException e1) { }           //requested data flavor not supported (unlikely but still possible)
    catch(java.io.IOException e2) { }                  //data no longer available in the requested flavor
  }
  return object; //return the object
}*/

/*static String getTextFromClipboard(){ //this extracts string data from the clipboard (if applicable)
  String text=(String)getFromClipboard(DataFlavor.stringFlavor); //get string flavored data and cast to a string
  return text;                                                   //return the text
}*/

//And this set is dumped from:
//https://stackoverflow.com/questions/11596368/set-clipboard-contents

/*static void copyToClipboard(String text) {
  StringSelection selection = new StringSelection(text);
  Clipboard clipboard = Toolkit.getDefaultToolkit().getSystemClipboard();
  clipboard.setContents(selection, selection);
}*/

///////////////////// FOR ANDROID //////////////////////////

//The following code is dumped from:
//https://discourse.processing.org/t/i-need-to-find-these-libraries/20484
//Credit to user @noel

static Activity activity;
static Context context;
static ClipboardManager clipboard;

public static void androidInitClipboard(final PApplet app) {
  activity = app.getActivity();
  context = activity.getApplicationContext();
  Looper.prepare();
  clipboard = (ClipboardManager)context.getSystemService(Context.CLIPBOARD_SERVICE);
}

static String getTextFromClipboard(){ //this extracts string data from the clipboard (if applicable)
  ClipData clip = clipboard.getPrimaryClip(); //load the primary clip
  if(clip==null) { return null; }             //if null, return null
  CharSequence cs = clip.getItemAt(0).getText(); //grab the text from the clipboard
  return String.valueOf(cs);                  //cast to a string and return result
}

static void copyToClipboard(String text) {
  ClipData clip = ClipData.newPlainText("text", text); //cast string of text into clipdata object
  clipboard.setPrimaryClip(clip);                      //set that as our primary clipboard data
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
