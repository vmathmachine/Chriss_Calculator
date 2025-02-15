public static class MathFunc { //a class for storing math functions
  String name; //the function name
  String inpSeq; //the input sequence, represented as a regex (b,c,v,m,d,M,N = bool, complex, vector, matrix, date, message, none)
  private SimplePattern regex; //the input sequence, compiled as a simplified regex
  Functional lambda; //the math function this actually runs
  
  MathFunc(String n, String i, Functional f) {
    name=n; inpSeq=i; lambda=f;
    regex = new SimplePattern(i);
  }
  
  MathFunc(String n, SimplePattern i, Functional f) {
    name = n; regex = i; lambda = f;
  }
  
  boolean matches(MathObj[] v, HashMap<String, MathObj> mapper) {
    return regex.matches(v, mapper);
  }
  
  boolean matches(byte[] seq) { //does the same thing, but for a preprocessed sequence of bytes
    return regex.matches(seq);
  }
}

public static interface Functional {
  public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException;
}

public static class FuncList { //a class for storing lists of acceptable math functions, in order
  //ArrayList<MathFunc> list = new ArrayList<MathFunc>(); //list of math functions (sorted in order of their name hashes)
  HashMap<String, MathFunc[]> list = new HashMap<String, MathFunc[]>(); //list of math functions (ordered by their name, functions w/ the same name are put in the same array)
  ArrayList<String> lookup = new ArrayList<String>(); //lookup table for all function names (sorted from greatest to least, ignoring operators)
  HashMap<String, int[]> minMax = new HashMap<String, int[]>(); //maps each function to an array containing the minimum & maximum # of inputs
  
  FuncList() { }
  
  FuncList(MathFunc... fs) { //initializes itself from a list of functions
    for(MathFunc f : fs) { add(f); } //add every function (O(nlog(n)), binary insertion sort)
  }
  
  int size() { return list.size(); }
  
  FuncList add(MathFunc f) { //adds f to the list
    MathFunc[] find = list.get(f.name); //see if there's already an entry for this name
    if(find==null) { list.put(f.name, new MathFunc[] {f}); } //if there isn't, add one
    else { //otherwise
      MathFunc[] arr = new MathFunc[find.length+1]; //create a replacement array that's one longer
      System.arraycopy(find,0,arr,0,find.length);   //copy the existing contents onto this array
      arr[find.length] = f;                         //add this one extra element
      list.put(f.name, arr);                        //replace the array with the new array
    }
    
    addLookup(f.name); //add f's name to the lookup table
    updateMinMax(f);   //update the min/max # of inputs for this function
    
    return this; //return result
  }
  
  //boolean remove(MathFunc f) { return list.remove(f); }
  boolean remove(MathFunc f) { //attempts to remove from the list, returns false if it wasn't even there
    MathFunc[] find = list.get(f.name); //see if there's an entry for this name
    if(find==null) { return false; }    //if there isn't, return false
    if(find.length==1) { //if there's exactly one:
      if(find[0]==f) { list.put(f.name,null); return true; } //if it contains this function, remove the entry & return true
      return false; //otherwise, do nothing & return false
    }
    int ind = -1; //find the index of this function
    for(int n=0;n<find.length;n++) { //loop through all elements
      if(find[n]==f) { ind=n; break; } //the moment we find this function, set the index & quit the loop
    }
    if(ind==-1) { return false; } //if we didn't find this function, return false
    MathFunc[] arr = new MathFunc[find.length-1]; //otherwise, create a replacement array that's one shorter
    System.arraycopy(find,0,arr,0,ind); //copy all elements before this function
    System.arraycopy(find,ind+1,arr,ind,find.length-ind-1); //copy all elements after this function
    return true; //return true, since something was removed
  }
  
  private void addLookup(String k) { //adds a specific key to the lookup table
    //NOTE: keys are sorted from biggest to smallest, tied elements are sorted in alphabetical order
    if(!k.contains("(") && !k.contains("[")) { return; } //if it doesn't contain a left parenthesis or bracket, do nothing
    
    int left = 0, right = lookup.size()-1; //find the left & right bounds
    int middle = (left+right)>>1;          //find the center
    int compare = 1;                       //whether k comes before, at, or after middle
    while(left<=right && (compare=compareLookup(k,lookup.get(middle)))!=0) { //loop until either the left & right bounds are out of order or we find a function w/ the same name
      if(compare<0) { right = middle-1; } //if k comes before the middle, change the right to 1 less than the middle
      else          { left  = middle+1; } //if k comes after the middle, change the left to 1 more than the middle
      middle = (left+right)>>1; //find the center again
    }
    //now, either we found a func w/ this name at index "middle", or left is the index of the element after k, right & middle are the index of the element before k (slight nuance: out of bounds)
    if(compare!=0) { //if there's an identical string at index middle, do nothing. Otherwise...
      lookup.add(middle+1, k); //add this string right after the middle element
    }
  }
  
  private int compareLookup(String a, String b) { //returns which order two strings belong in on the lookup table
    if(a.length()!=b.length()) { return b.length()-a.length(); } //if different lengths, return + if a is smaller, - if a is bigger
    return a.compareTo(b); //otherwise, return their alphabetical order
  }
  
  private void updateMinMax(MathFunc f) { //given an added function, this updates the map of min/max inputs
    int[] fMinMax = f.regex.minMax(); //given the regex for the input sequence, find the minimum & maximum # of inputs
    int[] curr = minMax.get(f.name);  //grab the current min & max for functions of this name
    if(curr==null) { minMax.put(f.name, fMinMax); } //if this entry isn't part of the list yet, add it
    else { //otherwise:
      if(fMinMax[0]<curr[0]) { curr[0]=fMinMax[0]; } //if this can accept fewer inputs, lower the minimum
      if(fMinMax[1]>curr[1]) { curr[1]=fMinMax[1]; } //if this can accept more inputs, raise the maximum
    }
  }
  
  MathFunc[] find(String name) { //finds all functions w/ a given name. If N/A, returns empty array
    MathFunc[] find = list.get(name); //lookup this name
    return find==null ? new MathFunc[0] : find; //if null, return empty array. Otherwise, return what you found
  }
  
  static MathFunc find(MathFunc[] funcs, MathObj[] inps, HashMap<String, MathObj> mapper) { //given a function name, and a set of inputs, it finds which function to use. If N/A, returns null
    if(funcs.length==0) { return null; } //if there are no options, return null TODO see if this is redundant (I'm pretty damn sure it is)
    
    //byte[] parsed = null;
    MathObj[] inpCopy = new MathObj[inps.length]; //a copy of the input list
    for(MathFunc func : funcs) { //loop through all functions that could match this
      //if(parsed==null) { parsed = SimplePattern.parse(inps); }
      //if(func.matches(inps, mapper)) { return func; } //return the first function whose regex matches the input sequence
      
      System.arraycopy(inps,0, inpCopy,0,inps.length); //copy over the input list
      if(func.matches(inpCopy, mapper)) { //find the first function whose regex matches the input sequence
        System.arraycopy(inpCopy,0, inps,0,inps.length); //since this is a match, copy back the (potentially) altered inputs
        return func; //return the function
      }
    }
    return null; //if none of them accept our inputs, return null
  }
  
  MathFunc find(String name, MathObj[] inps, HashMap<String, MathObj> mapper) { //given a function name, and a set of inputs, it finds which function to use. If N/A, returns null
    return find(find(name), inps, mapper); //find all the functions it could be, return what we find
  }
}

public static Functional tempFunc;
public static FuncList functionDictionary = new FuncList( //this is a list of all the functions
  new MathFunc("(",".",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return inp[0]; } }), //identity function
  
  new MathFunc("+","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.add(inp[1].number)); } }), //start with basic binary arithmetic functions
  new MathFunc("-","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sub(inp[1].number)); } }),
  new MathFunc("*","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.mul(inp[1].number)); } }),
  new MathFunc("/","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.div(inp[1].number)); } }),
  new MathFunc("\\","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].number.div(inp[0].number)); } }),
  new MathFunc("%","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.mod(inp[1].number)); } }),
  new MathFunc("^","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.equals(Math.E)) { return new MathObj(inp[1].number.exp()); }
    else                { return new MathObj(inp[0].number.pow(inp[1].number)); }
  } }),
  new MathFunc("//","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.div(inp[1].number).floor()); } }),
  
  
  new MathFunc(";","..",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return inp[1]; } }), //semicolon: separates two statements (return the second one)
  
  /*new MathFunc("=","..",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //next, inequalities
    if(inp[0].type==inp[1].type) { switch(inp[0].type) {
      case COMPLEX: return new MathObj(inp[0].number.equals(inp[1].number));
      case BOOLEAN: return new MathObj(inp[0].bool == inp[1].bool);
      case VECTOR: return new MathObj(inp[0].vector.equals(inp[1].vector));
      case MATRIX: return new MathObj(inp[0].matrix.equals(inp[1].matrix));
      case DATE  : return new MathObj(inp[0].date.equals(inp[1].date));
      case MESSAGE: return new MathObj(inp[0].message.equals(inp[1].message));
      default: return new MathObj(false);
    } }
    else { return new MathObj(false); }
  } }),
  new MathFunc("==","..",tempFunc),
  new MathFunc("!=","..",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].type==inp[1].type) { switch(inp[0].type) {
      case COMPLEX: return new MathObj(!inp[0].number.equals(inp[1].number));
      case BOOLEAN: return new MathObj(inp[0].bool ^ inp[1].bool);
      case VECTOR: return new MathObj(!inp[0].vector.equals(inp[1].vector));
      case MATRIX: return new MathObj(!inp[0].matrix.equals(inp[1].matrix));
      case DATE  : return new MathObj(!inp[0].date.equals(inp[1].date));
      case MESSAGE: return new MathObj(!inp[0].message.equals(inp[1].message));
      default: return new MathObj(true);
    } }
    else { return new MathObj(true); }
  } }),*/
  new MathFunc("=","..",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].passByValue(map).equals(inp[1].passByValue(map))); } }),
  new MathFunc("==","..",tempFunc),
  new MathFunc("!=","..",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(!inp[0].passByValue(map).equals(inp[1].passByValue(map))); } }),
  new MathFunc("<" ,"cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re<inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im< inp[1].number.im); } }),
  new MathFunc(">" ,"cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re>inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im> inp[1].number.im); } }),
  new MathFunc("<=","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re<inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im<=inp[1].number.im); } }),
  new MathFunc(">=","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re>inp[1].number.re || inp[0].number.re==inp[1].number.re && inp[0].number.im>=inp[1].number.im); } }),
  
  new MathFunc(":=","V.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    MathObj value = inp[1].passByValue(map);
    map.put(inp[0].variable, value);
    return value;
  } }),
  new MathFunc("unset(","V",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    map.remove(inp[0].variable);
    return new MathObj();
  } }),
  new MathFunc("showAllVars(","",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    MathObj[] vars = new MathObj[map.size()];
    int ind = 0;
    for(Map.Entry<String, MathObj> iter : map.entrySet()) {
      vars[ind++] = new MathObj(false, iter.getKey());
    }
    return new MathObj(vars);
  } }),
  
  new MathFunc("__-__","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.neg()); } }), //then, some important elementary functions
  new MathFunc("√(" ,"c",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sqrt()); } }),
  new MathFunc("sqrt(","c",tempFunc),
  new MathFunc("∛(","c",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cbrt()); } }),
  new MathFunc("cbrt(","c",tempFunc),
  new MathFunc( "ln(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.ln()); } }),
  new MathFunc("log(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx.log10(inp[0].number)); } }),
  new MathFunc(   "²","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sq()); } }),
  new MathFunc(   "³","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cub()); } }),
  
  new MathFunc("fp(",".",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { inp[0].fp=true; return inp[0]; } }), //the full precision function
  
  new MathFunc("ulp(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.ulpMax()); } }), //ulp (unit in last place)
  new MathFunc("ulp(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.ulpMax()); } }),
  new MathFunc("ulp(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.ulpMax()); } }),
  
  new MathFunc("sin(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sin()); } }), //trig functions
  new MathFunc("cos(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cos()); } }),
  new MathFunc("tan(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.tan()); } }),
  new MathFunc("sec(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sec()); } }),
  new MathFunc("csc(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.csc()); } }),
  new MathFunc("cot(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cot()); } }),
  new MathFunc("sinh(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sinh()); } }),
  new MathFunc("cosh(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.cosh()); } }),
  new MathFunc("tanh(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.tanh()); } }),
  new MathFunc("sech(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sech()); } }),
  new MathFunc("csch(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.csch()); } }),
  new MathFunc("coth(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.coth()); } }),
  
  new MathFunc("asin(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asin()); } }), new MathFunc("sin⁻¹(","c",tempFunc), //inverse trig functions
  new MathFunc("acos(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acos()); } }), new MathFunc("cos⁻¹(","c",tempFunc),
  new MathFunc("atan(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.atan()); } }), new MathFunc("tan⁻¹(","c",tempFunc),
  new MathFunc("asec(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asec()); } }), new MathFunc("sec⁻¹(","c",tempFunc),
  new MathFunc("acsc(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acsc()); } }), new MathFunc("csc⁻¹(","c",tempFunc),
  new MathFunc("acot(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acot()); } }), new MathFunc("cot⁻¹(","c",tempFunc),
  new MathFunc("asinh(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asinh()); } }), new MathFunc("sinh⁻¹(","c",tempFunc),
  new MathFunc("acosh(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acosh()); } }), new MathFunc("cosh⁻¹(","c",tempFunc),
  new MathFunc("atanh(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.atanh()); } }), new MathFunc("tanh⁻¹(","c",tempFunc),
  new MathFunc("asech(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.asech()); } }), new MathFunc("sech⁻¹(","c",tempFunc),
  new MathFunc("acsch(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acsch()); } }), new MathFunc("csch⁻¹(","c",tempFunc),
  new MathFunc("acoth(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.acoth()); } }), new MathFunc("coth⁻¹(","c",tempFunc),
  
  new MathFunc("atan2(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.im==0 && inp[1].number.im==0) { return new MathObj(Math.atan2(inp[1].number.re,inp[0].number.re)); } //both real: return atan2
    if(inp[1].number.equals(0)) { return new MathObj(inp[0].number.re>=0 ? 0 : inp[0].number.im>=0 ? Math.PI : -Math.PI); } //y is 0: return 0 or ±π
    if(inp[0].number.re>=0 && inp[1].number.lazyabs() < Math.scalb(inp[0].number.lazyabs(),-26)) { return new MathObj(inp[1].number.div(inp[0].number)); } //y is really small WRT x: return y/x
    return new MathObj(inp[0].number.add(inp[1].number.mulI()).log().subeq(inp[0].number.sub(inp[1].number.mulI()).log()).muleqI(-0.5)); //otherwise: return (ln(x+yi)-ln(x-yi))/(2i)
  } }),
  
  new MathFunc("gd(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(Cpx.gd(inp[0].number));
  } }),
  new MathFunc("invGd(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(Cpx.invGd(inp[0].number));
  } }),
  new MathFunc("gd⁻¹(","c",tempFunc),
  
  
  new MathFunc("~","b",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(!inp[0].bool); } }), //boolean operators
  new MathFunc("__!__","b",tempFunc),
  new MathFunc("&","bb",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].bool & inp[1].bool); } }),
  new MathFunc("|","bb",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].bool | inp[1].bool); } }),
  new MathFunc("^","bb",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].bool ^ inp[1].bool); } }),
  new MathFunc("&&","be",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].bool) { return new MathObj(false); }
    MathObj right = inp[1].equation.solve(map);
    //return right.isBool() ? right : new MathObj("Cannot evaluate boolean && "+right.type);
    if(right.isBool()) { return right; }
    else { throw new CalculationException("Cannot evaluate boolean && "+right.type); }
  } }),
  new MathFunc("||","be",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].bool) { return new MathObj(true); }
    MathObj right = inp[1].equation.solve(map);
    //return right.isBool() ? right : new MathObj("Cannot evaluate boolean || "+right.type);
    if(right.isBool()) { return right; }
    else { throw new CalculationException("Cannot evaluate boolean || "+right.type); }
  } }),
  new MathFunc("?:","bee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    return (inp[0].bool ? inp[1] : inp[2]).equation.solve(map);
  } }),
  
  new MathFunc("[","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //vector functions, starting with vector initialization
    Complex[] arr = new Complex[inp.length]; //load array of appropriate length
    for(int n=0;n<inp.length;n++) { arr[n]=inp[n].number.copy(); } //load each element
    return new MathObj(new CVector(arr)); //return result
  } }),
  new MathFunc("+","vv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.add(inp[1].vector)); } }),
  new MathFunc("-","vv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.sub(inp[1].vector)); } }),
  new MathFunc("*","vc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.mul(inp[1].number)); } }),
  new MathFunc("*","cv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].vector.mul(inp[0].number)); } }),
  new MathFunc("/","vc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.div(inp[1].number)); } }),
  new MathFunc("\\","cv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].vector.div(inp[0].number)); } }),
  new MathFunc("_","vc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[1].number.isNatural() && inp[1].number.re<=inp[0].vector.size()) {
      return new MathObj(inp[0].vector.get((int)(inp[1].number.re)-1));
    }
    throw new CalculationException("Error: cannot take index "+inp[1].number+" of vector["+inp[0].vector.size()+"]");
  } }),
  new MathFunc("·","vv",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.dot(inp[1].vector)); } }), new MathFunc("•","vv",tempFunc), new MathFunc("dot(","vv",tempFunc),
  new MathFunc("⟂","vv",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.pDot(inp[1].vector)); } }), new MathFunc("pDot(","vv",tempFunc),
  new MathFunc("×","vv",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.cross(inp[1].vector)); } }), new MathFunc("cross(","vv",tempFunc),
  new MathFunc("perp(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.perp()); } }),
  new MathFunc("__-__","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.neg()); } }),
  new MathFunc("mag(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.mag()); } }),
  new MathFunc("mag²(","v",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.magSq()); } }), new MathFunc("magSq(","v",tempFunc),
  new MathFunc("unit(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.unit()); } }),
  new MathFunc("size(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.size()); } }),
  new MathFunc("zero(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isWhole()) { return new MathObj(CVector.zero((int)inp[0].number.re)); }
    throw new CalculationException("Cannot create zero vector of size "+inp[0].number);
  } }),
  
  
  new MathFunc("[","v*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //matrix functions, starting with matrix initialization
    CVector[] arr = new CVector[inp.length]; //load array of appropriate length
    for(int n=0;n<inp.length;n++) { arr[n]=inp[n].vector.clone(); } //load each element
    return new MathObj(new CMatrix(arr)); //return result
  } }),
  new MathFunc("+","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.add(inp[1].matrix)); } }),
  new MathFunc("+","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.add(inp[1].number)); } }),
  new MathFunc("+","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.add(inp[0].number)); } }),
  new MathFunc("-","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sub(inp[1].matrix)); } }),
  new MathFunc("-","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sub(inp[1].number)); } }),
  new MathFunc("-","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.neg().add(inp[0].number)); } }),
  new MathFunc("*","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.mul(inp[1].number)); } }),
  new MathFunc("*","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.mul(inp[0].number)); } }),
  new MathFunc("*","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.mul(inp[1].matrix)); } }),
  new MathFunc("*","mv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.mul(inp[1].vector)); } }),
  new MathFunc("*","vm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.mulLeft(inp[0].vector)); } }),
  new MathFunc("/","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.div(inp[1].number)); } }),
  new MathFunc("/","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.inv().muleq(inp[0].number)); } }),
  new MathFunc("/","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.rightDivide(inp[1].matrix)); } }),
  new MathFunc("/","vm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.rightDivide(inp[0].vector)); } }),
  new MathFunc("\\","mm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.leftDivide(inp[1].matrix)); } }),
  new MathFunc("\\","mv",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.leftDivide(inp[1].vector)); } }),
  new MathFunc("\\","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[1].matrix.div(inp[0].number)); } }),
  new MathFunc("\\","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.inv().muleq(inp[0].number)); } }),
  new MathFunc("^","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.pow(inp[1].number)); } }),
  new MathFunc("_","mc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[1].number.isNatural() && inp[1].number.re<=inp[0].matrix.h) {
      return new MathObj(inp[0].matrix.getRow((int)(inp[1].number.re)-1));
    }
    throw new CalculationException("Error: cannot take index "+inp[1].number+" of "+inp[0].matrix.getDimensions()+" matrix");
  } }),
  new MathFunc("width(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.w); } }),
  new MathFunc("height(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.h); } }),
  new MathFunc("__-__","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.neg()); } }),
  new MathFunc("Identity(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isWhole()) { return new MathObj(CMatrix.identity((int)inp[0].number.re)); }
    throw new CalculationException("Cannot create "+inp[0].number+"x"+inp[0].number+" identity matrix");
  } }),
  new MathFunc("zero(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isWhole() && inp[1].number.isWhole()) { return new MathObj(new CMatrix((int)inp[0].number.re, (int)inp[1].number.re)); }
    throw new CalculationException("Cannot create "+inp[0].number+"x"+inp[1].number+" zero matrix");
  } }),
  new MathFunc("T(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.transpose()); } }),
  new MathFunc("tr(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.trace()); } }),
  new MathFunc("det(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.determinant()); } }),
  new MathFunc("eigenvalues(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Complex[] eigenvalues = inp[0].matrix.eigenvalues(); //get the eigenvalues
    MathObj[] arr = new MathObj[eigenvalues.length];
    for(int n=0;n<eigenvalues.length;n++) { arr[n] = new MathObj(eigenvalues[n]); }
    return new MathObj(arr);
  } }),
  new MathFunc("eigenvectors(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    CVector[] eigenvectors = inp[0].matrix.eigenvectors();
    MathObj[] arr = new MathObj[eigenvectors.length];
    for(int n=0;n<eigenvectors.length;n++) { arr[n] = new MathObj(eigenvectors[n]); }
    return new MathObj(arr);
  } }),
  new MathFunc("leigenvectors(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    CVector[] eigenvectors = inp[0].matrix.transpose().eigenvectors();
    MathObj[] arr = new MathObj[eigenvectors.length];
    for(int n=0;n<eigenvectors.length;n++) { arr[n] = new MathObj(eigenvectors[n]); }
    return new MathObj(arr);
  } }),
  new MathFunc("eigenboth(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Object[] both = inp[0].matrix.eigenvalues_and_vectors();
    MathObj[] vals = new MathObj[((Complex[])both[0]).length];
    MathObj[] vecs = new MathObj[((CVector[])both[1]).length];
    for(int n=0;n<vals.length;n++) {
      vals[n] = new MathObj(((Complex[])both[0])[n]);
      vecs[n] = new MathObj(((CVector[])both[1])[n]);
    }
    return new MathObj(new MathObj(vals), new MathObj(vecs));
  } }),
  new MathFunc("eigencolumns(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    CVector[] eigenvectors = inp[0].matrix.eigenvectors();
    if(eigenvectors.length==0) { return new MathObj(new CMatrix(0,0)); }
    return new MathObj(new CMatrix(eigenvectors).transpose());
  } }),
  new MathFunc("eigenrows(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    CVector[] eigenvectors = inp[0].matrix.transpose().eigenvectors();
    if(eigenvectors.length==0) { return new MathObj(new CMatrix(0,0)); }
    return new MathObj(new CMatrix(eigenvectors));
  } }),
  new MathFunc("eigenvalDiag(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Complex[] eigenvalues = inp[0].matrix.eigenvalues();
    CMatrix matrix = CMatrix.zero(inp[0].matrix.h,inp[0].matrix.w);
    for(int n=0;n<eigenvalues.length;n++) {
      matrix.set(n+1,n+1,eigenvalues[n]);
    }
    return new MathObj(matrix);
  } }),
  
  new MathFunc("column(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    CMatrix matrix = CMatrix.zero(inp[0].vector.size(),1);
    for(int n=0;n<inp[0].vector.size();n++) { matrix.set(n+1,1,inp[0].vector.get(n+1).copy()); }
    return new MathObj(matrix);
  } }),
  new MathFunc("row(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    CMatrix matrix = CMatrix.zero(1,inp[0].vector.size());
    for(int n=0;n<inp[0].vector.size();n++) { matrix.set(1,n+1,inp[0].vector.get(n+1).copy()); }
    return new MathObj(matrix);
  } }),
  new MathFunc("diag(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    CMatrix matrix = CMatrix.zero(inp[0].vector.size(),inp[0].vector.size());
    for(int n=0;n<inp[0].vector.size();n++) {
      matrix.set(n+1,n+1,inp[0].vector.get(n+1).copy());
    }
    return new MathObj(matrix);
  } }),
  
  new MathFunc("√(","m",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sqrt()); } }),
  new MathFunc("sqrt(","m",tempFunc),
  new MathFunc("√(","mb*",tempFunc = new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    boolean[] varArg = new boolean[inp.length-1]; for(int n=0;n<varArg.length;n++) { varArg[n] = inp[n+1].bool; }
    return new MathObj(inp[0].matrix.sqrt(varArg));
  } }),
  new MathFunc("sqrt(","mb*",tempFunc),
  new MathFunc("^","cm",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.equals(Math.E)) { return new MathObj(inp[1].matrix.exp()); }
    return new MathObj(inp[1].matrix.mul(inp[0].number.log()).exp());
  } }),
  new MathFunc("ln(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.log()); } }),
  new MathFunc("sin(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sin()); } }),
  new MathFunc("cos(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.cos()); } }),
  new MathFunc("sinh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sinh()); } }),
  new MathFunc("cosh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.cosh()); } }),
  new MathFunc("atan(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.atan()); } }),
  new MathFunc("atanh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.atanh()); } }),
  new MathFunc("tan(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.tan()); } }),
  new MathFunc("tanh(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.tanh()); } }),
  new MathFunc("sec(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sec()); } }),
  new MathFunc("csc(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.csc()); } }),
  new MathFunc("cot(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.cot()); } }),
  new MathFunc("sech(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sech()); } }),
  new MathFunc("csch(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.csch()); } }),
  new MathFunc("coth(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.coth()); } }),
  new MathFunc("!","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.factorial()); } }),
  new MathFunc("lnΓ(","m",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.loggamma()); } }),
  new MathFunc("lnGamma(","m",tempFunc),
  new MathFunc("Γ(","m",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.sub(1).factorial()); } }),
  new MathFunc("Gamma(","m",tempFunc),
  
  
  new MathFunc("{",".*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    MathObj[] arr = new MathObj[inp.length];
    for(int n=0;n<arr.length;n++) { arr[n] = inp[n].passByValue(map); }
    return new MathObj(arr);
  } }),
  new MathFunc("size(","a",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(inp[0].array.length);
  } }),
  new MathFunc("_","ac",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[1].number.isWhole() && inp[1].number.re<inp[0].array.length) {
      return inp[0].array[(int)inp[1].number.re];
    }
    throw new CalculationException("Error: cannot take index "+inp[1].number+" of array["+inp[0].array.length+"]");
  } }),
  new MathFunc("find(","a.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    IntList indices = new IntList();
    for(int n=0;n<inp[0].array.length;n++) { //loop through all elements
      if(inp[0].array[n].equals(inp[1].passByValue(map))) { //if we find a match:
        indices.append(n); //add this index to the list
      }
    }
    MathObj[] array = new MathObj[indices.size()]; //load a math object array
    for(int n=0;n<array.length;n++) {         //loop through all indices
      array[n] = new MathObj(indices.get(n)); //set each element of the index array
    }
    return new MathObj(array); //return the list of indices
  } }),
  new MathFunc("contains(","a.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    for(MathObj obj : inp[0].array) { //loop through all elements
      if(obj.equals(inp[1].passByValue(map))) {
        return new MathObj(true); //if at least one element is equal to this, return true
      }
    }
    return new MathObj(false); //otherwise, return false
  } }),
  new MathFunc("append(","a.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    MathObj[] array = new MathObj[inp[0].array.length+1];
    for(int n=0;n<array.length-1;n++) {
      array[n] = inp[0].array[n];
    }
    array[array.length-1] = inp[1].passByValue(map);
    return new MathObj(array);
  } }),
  new MathFunc("remove(","ac",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[1].number.isWhole() || inp[1].number.re>=inp[0].array.length) {
      throw new CalculationException("Error: cannot remove index "+inp[1].number+" from array["+inp[0].array.length+"]");
    }
    int ind = (int)inp[1].number.re;
    MathObj[] array = new MathObj[inp[0].array.length-1];
    for(int n=0;n<array.length;n++) {
      array[n] = inp[0].array[n<ind ? n : n+1];
    }
    return new MathObj(array);
  } }),
  new MathFunc("concat(","a*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    int len = 0;
    for(int n=0;n<inp.length;n++) { len += inp[n].array.length; }
    MathObj[] array = new MathObj[len]; //create concatenated array
    
    int offset = 0; //the index
    for(MathObj obj1 : inp) { //loop through all arrays
      for(MathObj obj2 : obj1.array) { //loop through all elements of each array
        array[offset++] = obj2; //append each element
      }
    }
    
    return new MathObj(array); //return resulting array
  } }),
  
  new MathFunc("insert(","ac.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[1].number.isWhole() || inp[1].number.re>inp[0].array.length) {
      throw new CalculationException("Error: cannot add element at index "+inp[1].number+" of array["+inp[0].array.length+"]");
    }
    int ind = (int)inp[1].number.re;
    
    MathObj[] array = new MathObj[inp[0].array.length+1];
    for(int n=0;n<inp[0].array.length;n++) {
      array[n<ind ? n : n+1] = inp[0].array[n];
    }
    array[ind] = inp[2].passByValue(map);
    return new MathObj(array);
  } }),
  
  new MathFunc("sublist(","acc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[1].number.isWhole() || !inp[2].number.isWhole() || inp[1].number.re>inp[0].array.length || inp[2].number.re>inp[0].array.length || inp[1].number.re > inp[2].number.re) {
      throw new CalculationException("Error: cannot sublist array["+inp[0].array.length+"] between indices "+inp[1].number+" and "+inp[2].number);
    }
    
    int ind1 = (int)inp[1].number.re, ind2 = (int)inp[2].number.re;
    
    MathObj[] array = new MathObj[ind2-ind1];
    for(int n=ind1;n<ind2;n++) {
      array[n-ind1] = inp[0].array[n];
    }
    
    return new MathObj(array);
  } }),
  
  new MathFunc("removeRange(","acc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[1].number.isWhole() || !inp[2].number.isWhole() || inp[1].number.re>inp[0].array.length || inp[2].number.re>inp[0].array.length || inp[1].number.re > inp[2].number.re) {
      throw new CalculationException("Error: cannot remove range between indices "+inp[1].number+" and "+inp[2].number+" from array["+inp[0].array.length+"]");
    }
    
    int ind1 = (int)inp[1].number.re, ind2 = (int)inp[2].number.re;
    
    MathObj[] array = new MathObj[inp[0].array.length-ind2+ind1];
    for(int n=0;n<ind1;n++) {
      array[n] = inp[0].array[n];
    }
    for(int n=ind2;n<inp[0].array.length;n++) {
      array[n-ind2+ind1] = inp[0].array[n];
    }
    
    return new MathObj(array);
  } }),
  
  new MathFunc("splice(","aac",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[2].number.isWhole() || inp[2].number.re>inp[0].array.length) {
      throw new CalculationException("Error: cannot splice array into index "+inp[2].number+" of array["+inp[0].array.length+"]");
    }
    
    int ind = (int)inp[2].number.re;
    
    MathObj[] array = new MathObj[inp[0].array.length+inp[1].array.length];
    for(int n=0;n<ind;n++) {
      array[n] = inp[0].array[n];
    }
    for(int n=0;n<inp[1].array.length;n++) {
      array[n+ind] = inp[1].array[n];
    }
    for(int n=ind;n<inp[0].array.length;n++) {
      array[n+inp[1].array.length] = inp[0].array[n];
    }
    
    return new MathObj(array);
  } }),
  
  new MathFunc("replace(","ac.",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[1].number.isWhole() || inp[1].number.re>=inp[0].array.length) {
      throw new CalculationException("Error: cannot set element at index "+inp[1].number+" of array["+inp[0].array.length+"]");
    }
    
    int ind = (int)inp[1].number.re;
    
    MathObj[] array = new MathObj[inp[0].array.length];
    System.arraycopy(inp[0].array,0, array,0, array.length);
    array[ind] = inp[2].passByValue(map);
    
    return new MathObj(array);
  } }),
  
  
  
  new MathFunc("+","dc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //date functions
    if(inp[1].number.isInt()) { return new MathObj(inp[0].date.add((long)inp[1].number.re)); }
    throw new CalculationException("Cannot add non-integer number of days");
  } }),
  new MathFunc("+","cd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(inp[1].date.add((long)inp[0].number.re)); }
    throw new CalculationException("Cannot add non-integer number of days");
  } }),
  new MathFunc("-","dc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[1].number.isInt()) { return new MathObj(inp[0].date.sub((long)inp[1].number.re)); }
    throw new CalculationException("Cannot subtract non-integer number of days");
  } }),
  new MathFunc("-","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.sub(inp[1].date)); } }),
  new MathFunc("<","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.less(inp[1].date)); } }),
  new MathFunc(">","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.greater(inp[1].date)); } }),
  new MathFunc("<=","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.lessEq(inp[1].date)); } }),
  new MathFunc(">=","dd",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].date.greaterEq(inp[1].date)); } }),
  new MathFunc("week(","d",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(false, inp[0].date.dayOfWeek()+""); } }),
  
  new MathFunc("New_Years(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.newYears((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  new MathFunc("Valentines(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.valentines((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  new MathFunc("St_Patricks(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.stPatricks((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  new MathFunc("Mothers_Day(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.mothersDay((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  new MathFunc("Fathers_Day(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.fathersDay((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  new MathFunc("Halloween(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.halloween((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  new MathFunc("Thanksgiving(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.thanksgiving((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  new MathFunc("Christmas(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt()) { return new MathObj(Date.christmas((long)inp[0].number.re)); }
    throw new CalculationException("Year must be an integer");
  } }),
  
  new MathFunc("Re(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re); } }), //complex number evaluation
  new MathFunc("Im(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.im); } }),
  new MathFunc("Re(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.re()); } }),
  new MathFunc("Im(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.im()); } }),
  new MathFunc("Re(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.re()); } }),
  new MathFunc("Im(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.im()); } }),
  new MathFunc("abs(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.abs()); } }),
  new MathFunc("abs(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.frobeniusMag()); } }),
  new MathFunc("arg(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.arg()); } }),
  new MathFunc("conj(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.conj()); } }),
  new MathFunc("conj(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.conj()); } }),
  new MathFunc("conj(","m",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].matrix.conj()); } }),
  new MathFunc("sgn(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sgn()); } }),
  new MathFunc("norm(","v",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.frobeniusUnit()); } }),
  new MathFunc("csgn(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.csgn()); } }),
  new MathFunc("abs2(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.abs2()); } }),
  new MathFunc("abs²(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.absq()); } }), new MathFunc("absq(","c",tempFunc),
  new MathFunc("abs²(","v",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].vector.frobeniusMagSq()); } }), new MathFunc("absq(","v",tempFunc),
  
  new MathFunc("floor(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.floor()); } }), //rounding functions
  new MathFunc("ceil(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.ceil()); } }),
  new MathFunc("round(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.round()); } }),
  new MathFunc("frac(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.sub(inp[0].number.floor())); } }),
  
  new MathFunc("θ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.re<0?0:inp[0].number.re==0?0.5:1); } }), //a few piecewise functions
  new MathFunc("U(","c",tempFunc),
  new MathFunc("rect(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number.absq()<0.25?1:(inp[0].number.absq()==0.25?0.5:0)); } }),
  
  new MathFunc("!","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.factorial(inp[0].number)); } }), //discrete math functions
  new MathFunc("nPr(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.factorial(inp[0].number).div(Cpx2.factorial(inp[0].number.sub(inp[1].number)))); } }),
  new MathFunc("nCr(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    if(inp[0].number.isWhole() && inp[1].number.isInt()) {
      int n = (int)inp[0].number.re, r = (int)inp[1].number.re;
      if(r<0 || r>n) { return new MathObj(new Complex()); }
      double ncr = 1d;
      for(int k=1;k<=r && k<=n-r;k++) {
        ncr*=(n-k+1d)/k;
      }
      return new MathObj(new Complex(ncr));
    }
    return new MathObj(Cpx2.factorial(inp[0].number).div(Cpx2.factorial(inp[1].number).mul(Cpx2.factorial(inp[0].number.sub(inp[1].number)))));
  } }),
  new MathFunc("rand(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    double rand = Math.random(); return new MathObj(inp[0].number.add(inp[1].number.sub(inp[0].number).mul(rand)));
  } }),
  new MathFunc("randInt(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isReal() || !inp[1].number.isReal()) { throw new CalculationException("Cannot take random integer over non-real interval"); }
    double range = inp[1].number.re-inp[0].number.re+1;
    return new MathObj(Math.floor(Math.random()*range+inp[0].number.re));
  } }),
  new MathFunc("randNorm(","",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(new Complex(random.nextGaussian()));
  } }),
  new MathFunc("randNorm(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(inp[1].number.mul(random.nextGaussian()).addeq(inp[0].number));
  } }),
  new MathFunc("max(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Complex max = new Complex(Double.NEGATIVE_INFINITY);
    for(MathObj m : inp) {
      if(m.number.re>max.re || m.number.re==max.re && m.number.im>max.im) { max=m.number; }
    }
    return new MathObj(max);
  } }),
  new MathFunc("min(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    Complex min = new Complex(Double.POSITIVE_INFINITY);
    for(MathObj m : inp) {
      if(m.number.re<min.re || m.number.re==min.re && m.number.im<min.im) { min=m.number; }
    }
    return new MathObj(min);
  } }),
  
  new MathFunc("stir1(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //Stirling numbers of the first kind
    if(!inp[0].number.isInt() || !inp[1].number.isInt()) { throw new CalculationException("Stirling numbers only work for integer inputs"); }
    return new MathObj(stirling1((int)(inp[0].number.re), (int)(inp[1].number.re)));
  } }),
  
  new MathFunc("stir2(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //Stirling numbers of the second kind
    if(!inp[0].number.isInt() || !inp[1].number.isInt()) { throw new CalculationException("Stirling numbers only work for integer inputs"); }
    return new MathObj(stirling2((int)(inp[0].number.re), (int)(inp[1].number.re)));
  } }),
  
  new MathFunc("PolyEval(","c+",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //evalutates polynomial using Horner's method (input, coefficients...)
    if(inp.length==1) { return new MathObj(new Complex()); } //special case: the zero polynomial
    
    Complex result = inp[1].number; //init result to leading coefficient
    for(int n=2;n<inp.length;n++) { //loop through all coefficients (except the leading)
      result.muleq(inp[0].number).addeq(inp[n].number); //multiply by input, add the next coefficient
    }
    return new MathObj(result); //return the result
  } }),
  new MathFunc("PolyRoots(","c+",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { //computes & returns the roots of a polynomial, given its coefficients
    int deg = inp.length-1;                  //find the degree
    Complex inv = inp[0].number.inv().neg(); //find the negative reciprocal of the leading coefficient
    
    Complex[][] companion = new Complex[deg][deg]; //construct a 2D array representing the companion matrix
    for(int i=0;i<deg;i++) for(int j=0;j<deg;j++) { //loop through all elements
      if   (j==deg-1) { companion[i][j] = inp[deg-i].number.mul(inv); } //the last column is just each coefficient, negated & divided by the leading coefficient
      else if(i==j+1) { companion[i][j] = new Complex(1);             } //the subdiagonal elements are all 1
      else            { companion[i][j] = new Complex();              } //all other elements are 0
    }
    
    Complex[] roots = new CMatrix(deg,deg,companion).eigenvalues(); //construct a matrix, then compute the eigenvalues
    return new MathObj(new CVector(roots)); //return the array of roots, organized into a vector
  } }),
  
  
  new MathFunc("Γ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.gamma(inp[0].number)); } }), //gamma and related functions
  new MathFunc("Gamma(","c",tempFunc),
  new MathFunc("lnΓ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.loggamma(inp[0].number)); } }),
  new MathFunc("lnGamma(","c",tempFunc),
  new MathFunc("ψ₀(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.digamma(inp[0].number)); } }), new MathFunc("ψ0(","c",tempFunc), new MathFunc("digamma(","c",tempFunc),
  new MathFunc("ψ(","cc",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj>map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isInt()) { throw new CalculationException("Cannot take ψ with non-integer modulus :("); }
    return new MathObj(Cpx3.polygamma2((int)inp[0].number.re,inp[1].number));
  } }), new MathFunc("polygamma(","cc",tempFunc),
  new MathFunc("K-Function(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.kFunction(inp[0].number,true)); } }),
  new MathFunc("Barnes-G(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.barnesG(inp[0].number)); } }),
  
  new MathFunc("erf(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erf(inp[0].number)); } }), //error and related functions
  new MathFunc("erfi(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erfi(inp[0].number)); } }),
  new MathFunc("erfc(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erfc(inp[0].number)); } }),
  new MathFunc("erfcx(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.erfcx(inp[0].number)); } }),
  new MathFunc("FresnelC(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.fresnelC(inp[0].number)); } }),
  new MathFunc("FresnelS(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx2.fresnelS(inp[0].number)); } }),
  new MathFunc("invErf(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.invErf(inp[0].number)); } }),
  new MathFunc("invErfc(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.invErfc(inp[0].number)); } }),
  new MathFunc("invErfi(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.invErfi(inp[0].number)); } }),
  
  new MathFunc("ζ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.zeta(inp[0].number)); } }), //Riemann zeta and related functions
  new MathFunc("zeta(","c",tempFunc),
  new MathFunc("η(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.zeta(inp[0].number).mul(Cpx.sub(1,new Complex(2).pow(Cpx.sub(1,inp[0].number))))); } }),
  new MathFunc("eta(","c",tempFunc),
  new MathFunc("RS-θ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.rsTheta(inp[0].number)); } }),
  new MathFunc("RS-Theta(","c",tempFunc),
  new MathFunc("RS-Z(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.rsZFunction(inp[0].number)); } }),
  new MathFunc("ξ(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { Complex num=inp[0].number; return new MathObj(Cpx.mul(num, num.sub(1), Cpx.pow(new Complex(Math.PI),num.mul(-0.5)), Cpx3.gamma(num.mul(0.5)), Cpx3.zeta(num)).muleq(0.5)); } }),
  new MathFunc("Xi(","c",tempFunc),
  
  new MathFunc("Li₂(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.Li2(inp[0].number)); } }), new MathFunc("Li2(","c",tempFunc), //polygamma functions
  new MathFunc("Cl₂(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.Cl2(inp[0].number)); } }), new MathFunc("Cl2(","c",tempFunc),
  new MathFunc("Li(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isInt()) { throw new CalculationException("Cannot take polylogarithm with non-integer modulus :("); }
    return new MathObj(Cpx3.polylog((int)inp[0].number.re,inp[1].number));
  } }),
  new MathFunc("Cl(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isInt()) { throw new CalculationException("Cannot take Clausen function with non-integer modulus :("); }
    return new MathObj(Cpx3.Cl((int)inp[0].number.re,inp[1].number));
  } }),
  
  new MathFunc("Ein(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.ein(inp[0].number)); } }), //TODO this is not correct, actually
  new MathFunc("Ei(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.ein(inp[0].number).addeq(inp[0].number.log())); } }), //exponential integral and related functions
  new MathFunc("li(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { Complex ln=inp[0].number.log(); return new MathObj(Cpx3.ein(ln).addeq(ln.ln())); } }),
  new MathFunc("Li(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { Complex ln=inp[0].number.log(); return new MathObj(Cpx3.ein(ln).add(ln.ln()).subeq(1.0451637801174928D)); } }),
  new MathFunc("Si(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.trigInt(inp[0].number,false)); } }),
  new MathFunc("Ci(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.trigInt(inp[0].number,true).addeq(inp[0].number.ln()).addeq(Mafs.GAMMA)); } }),
  new MathFunc("E₁(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.ein(inp[0].number.neg()).addeq(inp[0].number.ln()).neg()); } }), new MathFunc("E1(","c",tempFunc),
  new MathFunc("Aux-f(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.auxInt(inp[0].number, true)); } }),
  new MathFunc("Aux-g(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.auxInt(inp[0].number,false)); } }),
  
  new MathFunc("EllipticK(","c",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.completeF(inp[0].number)); } }), new MathFunc("EllipticF(","c",tempFunc), //elliptic integrals
  new MathFunc("EllipticE(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.completeE(inp[0].number)); } }),
  new MathFunc("EllipticF(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.incompleteF(inp[0].number,inp[1].number)); } }),
  new MathFunc("EllipticE(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.incompleteE(inp[0].number,inp[1].number)); } }),
  new MathFunc("EllipticΠ(","cc",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.completePI(inp[0].number,inp[1].number)); } }), new MathFunc("EllipticPI(","cc",tempFunc),
  
  new MathFunc("BesselJ(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselJ(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselY(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselY(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselJY(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(new CVector(Cpx3.besselJY(inp[0].number, inp[1].number))); } }),
  new MathFunc("BesselI(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselI(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselK(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselK(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselH1(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselH1(inp[0].number, inp[1].number)); } }),
  new MathFunc("BesselH2(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(Cpx3.besselH2(inp[0].number, inp[1].number)); } }),
  
  new MathFunc("Factor(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //factoring
    Complex num = inp[0].number; //grab input
    if(!num.isInt()) { throw new CalculationException("Can only factor integers"); } //only accept positive integers
    
    short pow2 = 0; //first, for the sake of normalization to a long, we keep dividing by 2 until we have an odd number
    while(num.re >= 4503599627370496l) { num.re*=0.5; pow2++; } //repeatedly divide by 2 and increment the power
    
    long val = (long)num.re; //cast to a long
    while(val!=0 && (val&1)==0) { val>>=1; pow2++; } //continue dividing by 2
    
    if(val==1) { //if we reduced to 1
      if(pow2==0) { return new MathObj(false, "Empty Product"); } //if it was 1 all along, it's an empty product
      if(pow2==1) { return new MathObj(false, "2");             } //if it was 2 all along, it's just 2
      return new MathObj(false, "2^"+pow2);                       //otherwise, return 2^pow2
    }
    //String factor = primeFactor(val); //compute the prime factorization
    String factor = new PrimeFactorization(val).toString();
    if(pow2==0) { return new MathObj(false, factor); }      //if there was no power of 2, just return the factorization
    if(pow2==1) { return new MathObj(false, "2*"+factor); } //if there was just one 2, return 2 * the factorization
    return new MathObj(false, "2^"+pow2+"*"+factor);        //otherwise, return 2^pow2 * the factorization
  } }),
  new MathFunc("GCF(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    long[] ints = new long[inp.length]; //construct an array of all the inputs
    int[] shifts = new int[inp.length]; //this is to store how many times each input was divided by 2 to make it a valid 64-bit int
    for(int n=0;n<inp.length;n++) { //loop through all inputs
      if(inp[n].number.isInt()) { //if the number is an integer:
        while(Math.abs(inp[n].number.re)>Long.MAX_VALUE) { inp[n].number.re*=0.5; shifts[n]++; } //divide by 2 until it's in bounds
        ints[n] = (long)inp[n].number.re; //cast to a long
      }
      else { throw new CalculationException("Cannot take GCF of non-integer(s)"); }
    }
    long gcf=0; try { gcf = gcf(ints); } //try taking the GCF
    catch(ArithmeticException ex) { return new MathObj(new Complex(Double.POSITIVE_INFINITY)); } //if infinite, set it to be infinite
    
    int shift = min(shifts); //compute the minimum amount any number had to shift
    return new MathObj(new Complex(gcf).scalbeq(shift)); //set result to the GCF of all our inputs, multiplied by 2^(the smallest power of 2 anything had to multiply by)
  } }),
  new MathFunc("LCM(","c*",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //TODO TEST
    long[] ints = new long[inp.length]; //construct an array of all the inputs
    int[] shifts = new int[inp.length]; //this is to store how many times each input was divided by 2 to make it a valid 64-bit int
    for(int n=0;n<inp.length;n++) { //loop through all inputs
      if(inp[n].number.isInt()) { //if the number is an integer:
        while(Math.abs(inp[n].number.re)>Long.MAX_VALUE) { inp[n].number.re*=0.5; shifts[n]++; } //divide by 2 until it's in bounds
        ints[n] = (long)inp[n].number.re; //cast to a long
      }
      else { throw new CalculationException("Cannot take LCM of non-integer(s)"); }
    }
    double lcm = 1; //init least common multiple to 1
    int shift2 = max(shifts); //count how many times we had to divide our LCM by 2 just to put it back in bounds
    for(long l : ints) { //loop through all inputs (again)
      if(l==0) { return new MathObj(0); } //if any of the inputs are 0, the LCM is 0
      while(Math.abs(lcm)>Long.MAX_VALUE) { lcm*=0.5; ++shift2; if((l&1)==0) { l>>=1; } }
      lcm = l*lcm/gcf(l, (long)lcm); //replace the lcm w/ the lcm between itself and each number
    }
    lcm = Math.scalb(lcm,shift2); //multiply back by the correct power of 2
    return new MathObj(lcm); //return result
  } }),
  new MathFunc("modInv(","cc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //TODO TEST
    if(!inp[0].number.isInt() || !inp[1].number.isInt()) { //both inputs must be integers
      throw new CalculationException("Cannot take inverse of "+inp[0].number+" mod "+inp[1].number+" (must both be integers)");
    }
    return new MathObj(modInv(Math.round(inp[0].number.re),Math.round(inp[1].number.re)));
  } }),
  new MathFunc("totient(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isInt()) { //input must be an integer
      throw new CalculationException("Cannot take Euler's totient of "+inp[0].number+" (must be an integer)");
    }
    return new MathObj(totient(Math.round(inp[0].number.re)));
  } }),
  new MathFunc("modPow(","ccc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isInt() || !inp[1].number.isInt() || !inp[2].number.isInt()) { //all 3 inputs must be integers
      throw new CalculationException("Cannot take "+inp[0].number+"^"+inp[1].number+" mod "+inp[2].number+" (must all be integers)");
    }
    return new MathObj(modPow(Math.round(inp[0].number.re),Math.round(inp[1].number.re),Math.round(inp[2].number.re)));
  } }),
  new MathFunc("discLog(","ccc",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isInt() || !inp[1].number.isInt() || !inp[2].number.isInt()) { //all 3 inputs must be integers
      throw new CalculationException("Cannot take log_"+inp[0].number+"("+inp[1].number+") mod "+inp[2].number+" (must all be integers)");
    }
    Long log = discLog_babyGiant((long)inp[0].number.re, (long)inp[1].number.re, (long)inp[2].number.re, carmichael((long)inp[2].number.re));
    if(log==null) { throw new CalculationException("Logarithm does not exist"); }
    else          { return new MathObj(new Complex(log)); }
  } }),
  new MathFunc("carmichael(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(!inp[0].number.isInt()) { //input must be an integer
      throw new CalculationException("Cannot take Carmichael's totient of "+inp[0].number+" (must be an integer)");
    }
    return new MathObj(carmichael(Math.round(inp[0].number.re)));
  } }),
  
  new MathFunc("toMixed(","cc?",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    double err = 9.5367431640625e-7d;
    if(inp.length==2) {
      if(inp[1].number.im!=0) { throw new CalculationException("Cannot convert to mixed number using non-real epsilon "+inp[1]); }
      err = inp[1].number.re;
    }
    
    long[] realPart = toMixed(inp[0].number.re, err);
    long[] imagPart = toMixed(inp[0].number.im, err);
    
    String stringOut = complexMixedString(inp[0].number, realPart, imagPart, err);
    
    return new MathObj(false, stringOut);
  } }),
  
  new MathFunc("toFrac(","cc?",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    double err = 9.5367431640625e-7d;
    if(inp.length==2) {
      if(inp[1].number.im!=0) { throw new CalculationException("Cannot convert to mixed number using non-real epsilon "+inp[1]); }
      err = inp[1].number.re;
    }
    
    long[] realPart = toMixed(inp[0].number.re, err); realPart[1] += realPart[0]*realPart[2]; realPart[0]=0;
    long[] imagPart = toMixed(inp[0].number.im, err); imagPart[1] += imagPart[0]*imagPart[2]; imagPart[0]=0;
    
    String stringOut = complexMixedString(inp[0].number, realPart, imagPart, err);
    
    return new MathObj(false, stringOut);
  } }),
  
  
  ////////////// RECURSIVE FUNCTIONS //////////////////////
  
  new MathFunc("plug(","V.e",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //variable, plug in point, equation
    String vari = inp[0].variable;
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    map2.put(vari, inp[1].passByValue(map).clone()); //plug in our plug-in-point
    MathObj result = inp[2].equation.solve(map2);                         //solve at that point
    transferVariables(map2, map, vari); //transfer over changes made in this scope
    return result;
  } }),
  
  new MathFunc("scope(","e",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //evaluates & returns the inside expression, but evaluated in another scope
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    MathObj result = inp[0].equation.solve(map2); //solve
    transferVariables(map2, map); //transfer over changes made in this scope
    return result;
  } }),
  
  new MathFunc("while(","ee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //condition, expression
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    while(inp[0].equation.solve(map2).bool) {
      inp[1].equation.solve(map2);
    }
    transferVariables(map2, map); //transfer over changes made in this scope
    return new MathObj();
  } }),
  
  new MathFunc("do(","ee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //condition, expression
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    do {
      inp[1].equation.solve(map2);
    } while(inp[0].equation.solve(map2).bool);
    transferVariables(map2, map); //transfer over changes made in this scope
    return new MathObj();
  } }),
  
  new MathFunc("for(","Vcce",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //variable, lower bound, upper bound, expression
    String vari = inp[0].variable; //record the variable we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    Complex cRange = inp[2].number.sub(inp[1].number).addeq(1); //find the difference between the upper & lower bound (plus 1)
    if(!cRange.isWhole()) { throw new CalculationException("Cannot perform a for loop over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-whole: yell at us
    int range = (int)cRange.re; //cast to an integer
    
    for(int i=0;i<range;i++) { //loop over the range
      map2.put(vari, new MathObj(inp[1].number.add(i))); //set our iterating variable each time
      inp[3].equation.solve(map2); //evaluate the expression
    }
    transferVariables(map2, map, vari); //transfer over changes made in this scope
    return new MathObj();
  } }),
  
  new MathFunc("BuildVec(","cVe",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //size, variable, equation
    String vari = inp[1].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[0].number.isWhole()) { //if the size is a whole integer
      int siz = (int)inp[0].number.re;  //record the size of the array
      Complex[] arr = new Complex[siz]; //create array of appropriate length
      for(int n=0;n<siz;n++) {                         //loop through all elements of the array
        map2.put(vari, new MathObj(new Complex(n+1))); //set the variable to our current index
        MathObj term = inp[2].equation.solve(map2);    //solve at this index
        if(term.isNum()) { arr[n] = term.number; }     //if evaluates to number, put that number at this index
        else { throw new CalculationException("Cannot build vector with element of type "+term.type); } //otherwise, return error message
      }
      return new MathObj(new CVector(arr)); //now that all the elements are created, return the result
    }
    else { throw new CalculationException("Cannot build vector of size "+inp[0]); } //if not a whole integer, return error message
  } }),
  
  new MathFunc("BuildArray(","cVe",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //size, variable, equation
    String vari = inp[1].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[0].number.isWhole()) { //if the size is a whole integer
      int siz = (int)inp[0].number.re;  //record the size of the array
      MathObj[] arr = new MathObj[siz]; //create array of appropriate length
      for(int n=0;n<siz;n++) {                         //loop through all elements of the array
        map2.put(vari, new MathObj(new Complex(n)));   //set the variable to our current index
        MathObj term = inp[2].equation.solve(map2);    //solve at this index
        arr[n] = term;                                 //set this element
      }
      return new MathObj(arr); //now that all the elements are created, return the result
    }
    else { throw new CalculationException("Cannot build array of size "+inp[0]); } //if not a whole integer, return error message
  } }),
  
  new MathFunc("BuildMat1(","ccVVe",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //height, width, row var, column var, scalar equation
    String var1 = inp[2].variable, var2 = inp[3].variable; //record the variables that represent the indices
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[1].isNum() && inp[0].number.isWhole() && inp[1].number.isWhole()) { //ensure dimensions are whole integers
      int hig = (int)inp[0].number.re, wid = (int)inp[1].number.re; //record the size of the matrix
      Complex[][] arr = new Complex[hig][wid];        //create array of appropriate size
      for(int i=0;i<hig;i++) for(int j=0;j<wid;j++) { //loop through all elements of the matrix
        map2.put(var1, new MathObj(new Complex(i+1))); //set the row variable
        map2.put(var2, new MathObj(new Complex(j+1))); //set the column variable
        MathObj term = inp[4].equation.solve(map2);    //solve at these indices
        if(term.isNum()) { arr[i][j] = term.number; }  //if evaluates to number, put that number at this index
        else { throw new CalculationException("Cannot build matrix with element of type "+term.type); } //otherwise, return error message
      }
      return new MathObj(new CMatrix(hig,wid,arr)); //create and return matrix
    }
    else { throw new CalculationException("Cannot build matrix of size "+inp[0]+"x"+inp[1]); } //if provided dimensions are invalid, return error message
  } }),
  
  new MathFunc("BuildMat2(","ccVe",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException { //height, width, row var, vector equation
    String vari = inp[2].variable; //record the variable that represents the row
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    if(inp[0].isNum() && inp[1].isNum() && inp[0].number.isWhole() && inp[1].number.isWhole()) { //ensure dimensions are whole integers
      int hig = (int)inp[0].number.re, wid = (int)inp[1].number.re; //record the size of the matrix
      CVector[] arr = new CVector[hig];                             //create array of appropriate size
      for(int i=0;i<hig;i++) { //loop through all rows of the matrix
        map2.put(vari, new MathObj(new Complex(i+1))); //set the row variable
        MathObj term = inp[3].equation.solve(map2);    //solve at this index
        if(!term.isVector()) { throw new CalculationException("Cannot build matrix with rows of type "+term.type); } //if not a vector, return error message
        if(term.vector.size()!=wid) { throw new CalculationException("Cannot build matrix with inconsistent width"); } //if row size is inconsistent, return error message
        arr[i] = term.vector; //otherwise, set each row
      }
      if(hig==0) { return new MathObj(new CMatrix(0,wid)); } //if height is 0, return 0xw matrix
      else { return new MathObj(new CMatrix(arr)); } //otherwise, construct matrix from vectors
    }
    else { throw new CalculationException("Cannot build matrix of size "+inp[0]+"x"+inp[1]); } //if provided dimensions are invalid, return error message
  } }),
  
  new MathFunc("Σ(","Vcce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number); //find the difference between the upper & lower bound
    if(!cRange.isInt()) { throw new CalculationException("Cannot perform a sum over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer: yell at us
    int range = (int)cRange.re+1; //cast to an integer
    if(range==0) { return new MathObj(Cpx.zero()); } //empty sum: return 0 (I know that it could also be a 0 vector or 0 matrix, but there's also no good way of figuring that out right now)
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the variable map
    boolean backwards = range<0; range = abs(range); Complex start = backwards ? inp[2].number.add(1) : inp[1].number; //if we're performing a backwards sum, remember that and recompute the range
    MathObj result = new MathObj(); //declare result
    for(int k=0;k<range;k++) {      //loop through all terms
      map2.put(vari,new MathObj(start.add(k)));   //set our variable
      MathObj term = inp[3].equation.solve(map2); //compute the term we add
      if(result.type==MathObj.VarType.NONE) { result = term.clone(); } //if sum is empty, initialize result
      else { result.addeq(term); }                                     //otherwise, add result
    }
    
    if(backwards) { result.negeq(); } //if backwards, we have to negate the result
    
    return result; //return the result
  } }), new MathFunc("Sigma(","Vcce",tempFunc),
  
  new MathFunc("Π(","Vcce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable;    //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number); //find the difference between the upper & lower bound
    if(!cRange.isInt()) { throw new CalculationException("Cannot perform a product over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer: yell at us
    int range = (int)cRange.re+1; //cast to an integer
    if(range==0) { return new MathObj(Cpx.one()); } //empty product: return 1 (I know that it could also be an identity matrix, but there's also no good way of figuring that out right now)
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone();
    boolean backwards = range<0; range = abs(range); Complex start = backwards ? inp[2].number.add(1) : inp[1].number;
    MathObj result = new MathObj();
    for(int k=0;k<range;k++) {
      map2.put(vari,new MathObj(start.add(k)));
      MathObj term = inp[3].equation.solve(map2);
      if(result.type==MathObj.VarType.NONE) { result = term.clone(); }
      else if(result.type!=term.type) { throw new CalculationException("Cannot perform product over terms of different types"); }
      else switch(term.type) {
        case COMPLEX: result.number.muleq(term.number); break;
        case MATRIX : result.matrix = result.matrix.mul(term.matrix); break;
        default     : throw new CalculationException("Cannot perform product over "+term.type);
      }
    }
    
    if(backwards) { switch(result.type) {
      case COMPLEX: result.number = result.number.inv(); break;
      case MATRIX : result.matrix = result.matrix.inv(); break;
      default     : throw new CalculationException("Cannot perform product over "+result.type);
    } }
    
    return result; //return the result
  } }), new MathFunc("Pi(","Vcce",tempFunc),
  
  new MathFunc("∀(","Vcce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number).add(1); //find the difference between the upper & lower bound
    if(!cRange.isWhole()) { throw new CalculationException("Cannot perform logical disjunction over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer (or negative): yell at us
    int range = (int)cRange.re; //cast to an integer
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone();
    for(int k=0;k<range;k++) {
      map2.put(vari,new MathObj(inp[1].number.add(k)));
      MathObj term = inp[3].equation.solve(map2);
      
      if(!term.isBool()) { throw new CalculationException("Cannot perform logical disjunction over non-booleans"); } //if non-boolean, return error
      if(!term.bool) { return term; } //if even one term is false, the whole thing is false
    }
    return new MathObj(true); //if none of the terms were false, return true
  } }), new MathFunc("AND(","Vcce",tempFunc),
  new MathFunc("∃(","Vcce",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    Complex cRange = inp[2].number.sub(inp[1].number).add(1); //find the difference between the upper & lower bound
    if(!cRange.isWhole()) { throw new CalculationException("Cannot perform logical conjunction over the range ["+inp[1].number+","+inp[2].number+"]"); } //if non-integer (or negative): yell at us
    int range = (int)cRange.re; //cast to an integer
    
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone();
    for(int k=0;k<range;k++) {
      map2.put(vari,new MathObj(inp[1].number.add(k)));
      MathObj term = inp[3].equation.solve(map2);
      
      if(!term.isBool()) { throw new CalculationException("Cannot perform logical conjunction over non-booleans"); } //if non-boolean, return error
      if(term.bool) { return term; } //if even one term is true, the whole thing is true
    }
    return new MathObj(false); //if none of the terms were true, return false
  } }), new MathFunc("OR(","Vcce",tempFunc),
  
  new MathFunc("d/dx(","Vcec?c?",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    Complex input = inp[1].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=4 ? inp[3].number : new Complex(9.765625E-4D); //if we have at least 4 inputs, we've chosen the epsilon. Otherwise, default it to something reasonably small
    int method = 2;     //now we must select the number of units we will step away from the middle. For every one unit we step away, we use 2 more samples. By default, we only take 4 samples
    if(inp.length>=5) { //if we have at least 5 inputs, the 5th one is the method we use
      if(inp[4].number.isNatural()) { method = (int)inp[4].number.re; } //if given a (positive) int, cast to an int and make that our method
      else { throw new CalculationException("Cannot approximate derivative with a polynomial of non-positive degree"); } //if given a non-positive number, return an error
    }
    
    MathObj result = new MathObj(); //initialize our result to an ambiguous math object, since we don't yet know if our result will be a scalar, vector, etc.
    double coef = -1; //our coefficient for each sample k*epsilon from the center will be (-1)^(k+1)*m!²/(k(m+k)!(m-k)!*epsilon). This will assist us in calculating that, but won't actually be that coefficient
    for(int k=1;k<=method;k++) { //loop through all pairs of samples
      
      coef *= k-method-1; coef /= method+k; //update the coefficient (kind of, this is actually (-1)^(k+1)*m!²/((m+k)!(m-k)!) )
      
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[2].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[2].equation.solve(map2); //solve at x-hk
      y1.subeq(y2);     //subtract the two
      y1.muleq(coef/k); //multiply by our factor
      
      if(result.type==MathObj.VarType.NONE) { result     = y1;  } //if the variable type hasn't been set yet, initialize our result to this difference
      else                                  { result.addeq(y1); } //otherwise, add it to that
    }
    
    result.diveq(epsilon); //divide by epsilon
    return result;         //return result
  } }),
  new MathFunc("d²/dx²(","Vcec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    Complex input = inp[1].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=4 ? inp[3].number : new Complex(9.765625E-4D); //if we have at least 4 inputs, we've chosen the epsilon. Otherwise, default it to something reasonably small
    int method = 2;     //now we must select the number of units we will step away from the middle. For every one unit we step away, we use 2 more samples. By default, we only take 5 samples
    if(inp.length>=5) { //if we have at least 5 inputs, the 5th one is the method we use
      if(inp[4].number.isNatural()) { method = (int)inp[4].number.re; } //if given a (positive) int, cast to an int and make that our method
      else { throw new CalculationException("Cannot approximate 2nd derivative with a polynomial of non-positive degree"); } //if given a non-positive number, return an error
    }
    
    map2.put(vari,new MathObj(input)); MathObj y0 = inp[2].equation.solve(map2); //find the value right at the middle
    
    MathObj result = new MathObj(); //initialize our result to an ambiguous math object, since we don't yet know if our result will be a scalar, vector, etc.
    double coef = -2; //our coefficient for each sample k*epsilon from the center will be 2(-1)^(k+1)*m!²/(k²(m+k)!(m-k)!*epsilon). This will assist us in calculating that, but won't actually be that coefficient
    for(int k=1;k<=method;k++) { //loop through all pairs of samples
      
      coef *= k-method-1; coef /= method+k; //update the coefficient (kind of, this is actually 2(-1)^(k+1)*m!²/((m+k)!(m-k)!) )
      
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[2].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[2].equation.solve(map2); //solve at x-hk
      y1.addeq(y2).subeq(y0.mul(2)).muleq(coef/(k*k)); //compute f(x+hk)-2f(x)+f(x-hk), then multiply by the appropriate coefficient
      
      if(result.type==MathObj.VarType.NONE) { result     = y1;  } //if the variable type hasn't been set yet, initialize our result to this difference
      else                                  { result.addeq(y1); } //otherwise, add it to that
    }
      
    result.diveq(epsilon.sq()); //divide by epsilon²
    return result;              //return result
  } }), new MathFunc("d^2/dx^2(","Vcec?c?",tempFunc),
  
  new MathFunc("dⁿ/dxⁿ(","cVcec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    int n;
    if(inp[0].number.isInt()) { n = (int)inp[0].number.re; }
    else { throw new CalculationException("Cannot take "+inp[0].number+"th derivative"); }
    
    String vari = inp[1].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    Complex input = inp[2].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=5 ? inp[4].number : new Complex(/*9.765625E-4D*/Math.scalb(1d,Math.round(-13f/n))); //if we have at least 5 inputs, we've chosen the epsilon.
    int method = ((n+1)>>1)+1; //now we must select the number of units we will step away from the middle. For every one unit we step away, we use 2 more samples. By default, we only take n+2 samples
    if(inp.length>=6) { //if we have at least 6 inputs, the 6th one is the one we use
      if(inp[5].number.isNatural()) { method = (int)inp[5].number.re; } //if given a (positive) int, cast to an int and make that our method
      else { throw new CalculationException("Cannot approximate nth derivative with a polynomial of non-positive degree"); } //if given a non-positive number, return an error
    }
    
    double[] gen = new double[(n+1)>>1]; //coefficients used to generate the actual coefficients
    for(int p=0;p<gen.length;p++) {
      for(int j=1;j<=2*p+1;j++) {
        gen[p] += ((j&1)==0?1:-1)*stirling1(method+1,j)*stirling1(method+1,2*p+2-j);
      }
      //gen[p] += ((p&1)==1?1:-1)*Mafs.sq(stirling1(method+1,p+1));
    }
    
    double factor1 = Mafs.factorial(n)/Mafs.sq(Mafs.factorial(method));
    double[] coef = new double[method];
    for(int k=1;k<=method;k++) {
      factor1 *= -(method-k+1)/(double)(method+k);
      double factor2 = Mafs.pow(k,-n);
      for(int p=0;p<gen.length;p++) {
        coef[k-1]+=gen[p]*factor2;
        factor2 *= k*k;
      }
      coef[k-1]*=factor1;
    }
    
    MathObj y0 = null;
    if((n&1)==0) {
      map2.put(vari,new MathObj(input));
      y0 = inp[3].equation.solve(map2);
    }
    
    MathObj result = new MathObj();
    for(int k=1;k<=method;k++) {
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[3].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[3].equation.solve(map2); //solve at x-hk
      
      if((n&1)==0) { y1.addeq(y2).subeq(y0.mul(2)).muleq(coef[k-1]); }
      else         { y1.subeq(y2).muleq(coef[k-1]); }
      
      if(result.type==MathObj.VarType.NONE) { result = y1; }
      else { result.addeq(y1); }
    }
    
    return result.diveq(epsilon.pow(n));
  } }), new MathFunc("d^n/dx^n(","cVcec?c?",tempFunc),
  
  /*new MathFunc("∫(","Vccec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    int samples = 16; //how many smaller sections we'll split our integral into (16 by default)
    if(inp.length>=5) { //if we specify how many sections, set number of sections
      if(inp[4].number.isNatural()) { samples = (int)inp[4].number.re; } //if valid, set the number of sections
      else { return new MathObj("Cannot approximate integral using "+inp[2].number+" samples"); } //otherwise, return error message
    }
    
    int method = 2; //the degree of the polynomial we will use to approximate our integral (0=Riemann sum, 1=trapezoid rule, 2=Simpson's 1/3, etc.). By default we use Simpson's rule to integrate
    if(inp.length>=6) { //if we specify what method we use, use that method
      if(inp[5].number.isWhole()) { method = (int)inp[5].number.re; } //if valid, use that method
      else { return new MathObj("Cannot approximate integral using degree "+inp[3].number+" polynomial"); } //otherwise, return error message
    }
    
    double[] coef; //coefficients for our integral. Depends on the integration method
    switch(method) {
      case 0: coef = new double[] {1,0}; break; //Left-handed Riemann Sum
      case 1: coef = new double[] {0.5,0.5}; break; //Trapezoid rule
      case 2: coef = new double[] {1d/6,4d/6,1d/6}; break; //Simpson's 1/3 rule
      case 3: coef = new double[] {0.125,0.375,0.375,0.125}; break; //Simpson's 3/8 rule
      case 4: coef = new double[] {7d/90,32d/90,12d/90,32d/90,7d/90}; break; //Boole's rule
      case 5: coef = new double[] {19d/288,75d/288,50d/288,50d/288,75d/288,19d/288}; break;
      case 6: coef = new double[] {41d/840,216d/840,27d/840,272d/840,27d/840,216d/840,41d/840}; break;
      case 7: coef = new double[] {751d/17280,3577d/17280,1323d/17280,2989d/17280,2989d/17280,1323d/17280,3577d/17280,751d/17280}; break;
      case 8: coef = new double[] {989d/28350,5888d/28350,-928d/28350,10496d/28350,-4540d/28350,10496d/28350,-928d/28350,5888d/28350,989d/28350}; break;
      case 9: coef = new double[] {2857d/89600,15741d/89600,1080d/89600,19344d/89600,5778d/89600,5778d/89600,19344d/89600,1080d/89600,15741d/89600,2857d/89600}; break;
      case 10: coef = new double[] {16067d/598752,106300d/598752,-48525d/598752,272400d/598752,-260550d/598752,427368d/598752,-260550d/598752,272400d/598752,-48525d/598752,106300d/598752,16067d/598752}; break;
      default: {
        return new MathObj("Okay, you got me, I haven't yet programmed in the ability to numerically integrate with a polynomial of degree 11 or higher.");
      }
    }
    
    MathObj result = new MathObj(); //declare result, initialize to empty math object
    double lerp1 = 1d/samples, lerp2 = method==0 ? lerp1 : lerp1/method;
    for(int n=0;n<samples;n++) {
      for(int k=0;k<coef.length-1;k++) {
        Complex x = inp[1].number.mul(1-lerp1*n-lerp2*k).addeq(inp[2].number.mul(lerp1*n+lerp2*k)); //compute current input value
        map2.put(vari,new MathObj(x)); MathObj y = inp[3].equation.solve(map2);
        
        double coef2 = k==0 ? n==0 ? coef[0] : coef[0]+coef[coef.length-1] : coef[k];
        y.muleq(coef2);
        if(result.type == MathObj.VarType.NONE) { result = y; }
        else                               { result.addeq(y); }
      }
    }
    if(coef[coef.length-1]!=0) { //now, we just have to add the last term
      map2.put(vari,inp[2]); MathObj y = inp[3].equation.solve(map2);
      y.muleq(coef[coef.length-1]);
      result.addeq(y);
    }
    
    //Alright, we've performed the sum. Now, all that's left is to scale it by the correct amount
    Complex scaledRange = inp[2].number.sub(inp[1].number).muleq(lerp1); //compute the range, then divide by the number of samples
    result.muleq(scaledRange); //multiply result by scaled range
    
    return result; //return the result
  } }), new MathFunc("Integral(","Vccec?c?",tempFunc)//*/
  
  new MathFunc("∫(","Vccec?c?",tempFunc=new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the mapper
    
    int samples = 16; //how many smaller sections we'll split our integral into (16 by default)
    if(inp.length>=5) { //if we specify how many sections, set number of sections
      if(inp[4].number.isNatural()) { samples = (int)inp[4].number.re; } //if valid, set the number of sections
      else { throw new CalculationException("Cannot approximate integral using "+inp[2].number+" samples"); } //otherwise, return error message
    }
    
    int method = 2; //the degree of the polynomial we will use to approximate our integral (0=Riemann sum, 1=trapezoid rule, 2=Simpson's 1/3, etc.). By default we use Simpson's rule to integrate
    if(inp.length>=6) { //if we specify what method we use, use that method
      if(inp[5].number.isWhole()) { method = (int)inp[5].number.re; } //if valid, use that method
      else { throw new CalculationException("Cannot approximate integral using degree "+inp[3].number+" polynomial"); } //otherwise, return error message
    }
    
    double[] coef; //coefficients for our integral. Depends on the integration method
    switch(method) {
      case 0: coef = new double[] {1,0}; break; //Left-handed Riemann Sum
      case 1: coef = new double[] {0.5,0.5}; break; //Trapezoid rule
      case 2: coef = new double[] {1d/6,4d/6,1d/6}; break; //Simpson's 1/3 rule
      case 3: coef = new double[] {0.125,0.375,0.375,0.125}; break; //Simpson's 3/8 rule
      case 4: coef = new double[] {7d/90,32d/90,12d/90,32d/90,7d/90}; break; //Boole's rule
      case 5: coef = new double[] {19d/288,75d/288,50d/288,50d/288,75d/288,19d/288}; break;
      case 6: coef = new double[] {41d/840,216d/840,27d/840,272d/840,27d/840,216d/840,41d/840}; break;
      case 7: coef = new double[] {751d/17280,3577d/17280,1323d/17280,2989d/17280,2989d/17280,1323d/17280,3577d/17280,751d/17280}; break;
      case 8: coef = new double[] {989d/28350,5888d/28350,-928d/28350,10496d/28350,-4540d/28350,10496d/28350,-928d/28350,5888d/28350,989d/28350}; break;
      case 9: coef = new double[] {2857d/89600,15741d/89600,1080d/89600,19344d/89600,5778d/89600,5778d/89600,19344d/89600,1080d/89600,15741d/89600,2857d/89600}; break;
      case 10: coef = new double[] {16067d/598752,106300d/598752,-48525d/598752,272400d/598752,-260550d/598752,427368d/598752,-260550d/598752,272400d/598752,-48525d/598752,106300d/598752,16067d/598752}; break;
      default: {
        throw new CalculationException("Okay, you got me, I haven't yet programmed in the ability to numerically integrate with a polynomial of degree 11 or higher.");
      }
    }
    
    Complex lerp = inp[2].number.sub(inp[1].number).div(samples*(coef.length-1)); //compute the difference between each consecutive piece
    MathObj[] parts = new MathObj[coef.length-1]; //create array of math terms to add up linear combinations of each other
    for(int n=0;n<samples;n++) { //loop through all samples
      for(int k=0;k<parts.length;k++) { //loop through all parts of each sample
        if(n==0&&k==0) { continue; } //skip the far left piece
        
        Complex x = inp[1].number.add(lerp.mul(n*parts.length+k)); //compute the input value
        map2.put(vari,new MathObj(x)); //set the input value
        MathObj y = inp[3].equation.solve(map2); //solve for y given x
        
        if(parts[k]==null) { parts[k] = y; } //if this part is not yet set, initialize it to y
        else          { parts[k].addeq(y); } //otherwise, add y
      }
    }
    for(int k=1;k<parts.length;k++) { parts[k].muleq(coef[k]); } //now, we have to multiply each part by their respective coefficients
    if(parts[0]!=null) { parts[0].muleq(coef[0]+coef[coef.length-1]); } //multiply boundary part by the sum of the left & right coefficients (unless null)
    MathObj sum = null;
    for(int k=0;k<parts.length;k++) { if(parts[k]!=null) { //compute the sum of all the parts (ignoring any null parts)
      if(sum==null) { sum = parts[k];      } //if not initialized, set to this part
      else          { sum.addeq(parts[k]); } //otherwise, add this part
    } }
    
    //now, we just have to add the leftmost & rightmost terms
    if(coef[0]!=0) {
      map2.put(vari,inp[1]); //set the input value
      MathObj y = inp[3].equation.solve(map2).muleq(coef[0]); //solve for y given x, multiply by coefficient
      if(sum==null) { sum = y; } //if not initialized, set to this
      else     { sum.addeq(y); } //otherwise, add this
    }
    if(coef[coef.length-1]!=0) {
      map2.put(vari,inp[2]); //set the input value
      MathObj y = inp[3].equation.solve(map2).muleq(coef[coef.length-1]); //solve for y given x, multiply by coefficient
      if(sum==null) { sum = y; } //if not initialized, set to this
      else     { sum.addeq(y); } //otherwise, add this
    }
    
    sum.muleq(lerp.muleq(parts.length)); //finally, multiply by range / # of samples
    return sum;                          //return result
    
  } }), new MathFunc("Integral(","Vccec?c?",tempFunc),
  
  new MathFunc("limit(","Vcec?c?",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    Complex input = inp[1].number; //grab the value we're evaluating at
    Complex epsilon = inp.length>=4 ? inp[3].number : new Complex(9.765625E-4D); //if we have at least 4 inputs, we've chosen the epsilon. Otherwise, default it to something reasonably small
    int method = 2; //now we must select the number of units we will step away from the middle
    if(inp.length>=5) { //if we have at least 5 inputs, the 4th one is the method we use
      if(inp[4].number.isWhole()) { method = (int)inp[4].number.re; } //if given a (non-negative) int, cast to an int and make that our method
      else { throw new CalculationException("Cannot approximate limit with a polynomial of non-whole degree"); } //if given a non-whole number, return an error
    }
    
    MathObj result = new MathObj(); //initialize our result to an ambiguous math object, since we don't yet know if our result will be a scalar, vector, etc.
    double coef = -1; //the coefficient of each term, equal to (-1)^(k+1)*m!²/((m+k)!(m-k)!), with m being the method
    for(int k=1;k<=method;k++) { //loop through all the steps we take away from the center
      coef *= k-method-1; coef /= method+k; //update the coefficient
      
      map2.put(vari,new MathObj(input.add(epsilon.mul(k))));
      MathObj y1 = inp[2].equation.solve(map2); //solve at x+hk
      map2.put(vari,new MathObj(input.sub(epsilon.mul(k))));
      MathObj y2 = inp[2].equation.solve(map2); //solve at x-hk
      
      y1.addeq(y2).muleq(coef); //add them together, multiply by the coefficient
      if(result.type==MathObj.VarType.NONE) { result = y1; } //if not yet initialized, set result to this
      else                             { result.addeq(y1); } //otherwise, add this to our result
    }
    return result; //return our result
  } }),
  
  new MathFunc("Secant(","Vcce",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int maxIter = 16; //maximum iterations
    Complex x0 = inp[1].number, x1 = inp[2].number; //grab the first and second guess
    map2.put(vari,inp[1]); MathObj temp = inp[3].equation.solve(map2); //solve at first guess
    if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform secant method on function of type "+temp.type); } //if not a number, return error message
    Complex y0 = temp.number; //record value at first guess
    map2.put(vari,inp[2]); temp = inp[3].equation.solve(map2); //solve at second guess
    if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform secant method on function of type "+temp.type); } //if not a number, return error message
    Complex y1 = temp.number; //record value at second guess
    
    for(int n=0;n<maxIter;n++) { //loop until it's solved or until you run out of iterations
      if(x0.equals(x1) || y1.equals(0)) { break; } //if both guesses equal, or our solution is 0, break from the loop
      Complex newX = (x0.mul(y1).subeq(x1.mul(y0))).diveq(y1.sub(y0)); //compute our next value for x (by drawing a secant line between the last 2 & finding the root)
      x0 = x1; x1 = newX; //update our x values
      map2.put(vari,new MathObj(x1)); temp = inp[3].equation.solve(map2); //solve at this value of x
      if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform secant method on function of type "+temp.type); } //if not a number, return error message
      y0 = y1; y1 = temp.number; //update our y values
    }
    return new MathObj(x1); //return the result
  } }),
  
  new MathFunc("Newton(","Vcee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    double err = 0;
    //if(inp.length>=5) { err = inp[4].number.re; }
    
    int maxIter = 16; //maximum iterations
    Complex x = inp[1].number.copy(), y, yp; //x, y, y'
    MathObj temp; //temporary variable
    for(int n=0;n<maxIter;n++) { //loop until it's solved or until you run out of iterations
      map2.put(vari,new MathObj(x)); temp = inp[2].equation.solve(map2); //solve y at x
      if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform Newton's method on function of type "+temp.type); } //if not a number, return error message
      y = temp.number;                  //update y value
      if(y.lazyabs() <= err) { break; } //if close enough, exit loop
      temp = inp[3].equation.solve(map2); //solve y' at x
      if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform Newton's method with derivative of type "+temp.type); } //if not a number, return error message
      yp = temp.number;   //update y' value
      x.subeq(y.div(yp)); //update x using Newton's method
    }
    return new MathObj(x); //return result
  } }),
  
  new MathFunc("Halley(","Vceee",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String vari = inp[0].variable; //record the variable we're plugging into
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    double err = 0;
    //if(inp.length>=5) { err = inp[4].number.re; }
    
    int maxIter = 16;
    Complex x = inp[1].number.copy(), y, yp, ypp;
    MathObj temp;
    for(int n=0;n<maxIter;n++) {
      map2.put(vari,new MathObj(x));
      temp = inp[2].equation.solve(map2); if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform Halley's method on function of type "+temp.type); } //if not a number, return error message
      y = temp.number;                  //update y value
      if(y.lazyabs() <= err) { break; } //if close enough, exit loop
      temp = inp[3].equation.solve(map2); if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform Halley's method with derivative of type "+temp.type); } //if not a number, return error message
      yp = temp.number;
      temp = inp[4].equation.solve(map2); if(temp.type != MathObj.VarType.COMPLEX) { throw new CalculationException("Cannot perform Halley's method with second derivative of type "+temp.type); } //if not a number, return error message
      ypp = temp.number;
      x.subeq(y.mul(yp).diveq(yp.sq().subeq(y.mul(ypp).muleq(0.5))));
    }
    return new MathObj(x); //set the result
  } }),
  
  new MathFunc("Euler(","VVc.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String inVar = inp[0].variable, outVar = inp[1].variable; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 7 or more inputs, the 7th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { throw new CalculationException("Cannot approximate Euler's method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input each step
    
    Complex x = inp[2].number;           //get the initial input
    MathObj y = inp[3].passByValue(map); //and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y); //set the values for our variables
      MathObj k1 = inp[5].equation.solve(map2);           //solve the derivative at this point
      x.addeq(dx); y.addeq(k1.muleq(dx));                 //increase x by dx, increase y by y'*dx
    }
    
    return y; //finally, return our final result
  } }),
  
  new MathFunc("EulerMid(","VVc.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String inVar = inp[0].variable, outVar = inp[1].variable; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 7 or more inputs, the 7th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { throw new CalculationException("Cannot approximate midpoint method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input each step
    
    Complex x = inp[2].number;           //get the initial input
    MathObj y = inp[3].passByValue(map); //and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y);              //set the values for our variables
      MathObj k1 = inp[5].equation.solve(map2);                        //solve the derivative at this point
      x.addeq(dx.mul(0.5)); MathObj y2 = y.add(k1.muleq(dx.mul(0.5))); //increase x by dx/2, increase y by y'*dx/2 (moving us to the midpoint)
      
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2); //set the values for our variables
      MathObj k2 = inp[5].equation.solve(map2);            //solve the derivative at this point
      x.addeq(dx.mul(0.5)); y.addeq(k2.mul(dx));           //increase x by dx/2 again, increase y by y'(midpoint)*dx
    }
    
    return y; //finally, return our final result
  } }),
  
  new MathFunc("ExpTrap(","VVc.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String inVar = inp[0].variable, outVar = inp[1].variable; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 7 or more inputs, the 7th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { throw new CalculationException("Cannot approximate explicit trapezoid method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input each step
    
    Complex x = inp[2].number;          //get the initial input
    MathObj y = inp[3].passByValue(map);//and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y);              //set the values for our variables
      MathObj k1 = inp[5].equation.solve(map2);                        //solve the derivative at this point
      x.addeq(dx); MathObj y2 = y.add(k1.mul(dx)); //increase x by dx, increase y by y'*dx (moving us to the endpoint)
      
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2); //set the values for our variables
      MathObj k2 = inp[5].equation.solve(map2);            //solve the derivative at this point
      
      y.addeq(k1.add(k2).mul(dx.mul(0.5)));           //increase y by (y1'+y2')/2*dx
    }
    
    return y; //finally, return our final result
  } }),
  
  new MathFunc("RK4(","VVc.cec?", new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    String inVar = inp[0].variable, outVar = inp[1].variable; //record the variables we're using
    HashMap<String, MathObj> map2 = (HashMap<String,MathObj>)map.clone(); //clone the map
    
    int samples = 16; //by default, we take 16 samples
    if(inp.length>=7) { //if there are 4 or more inputs, the 4th specifies the number of samples
      if(inp[6].number.isNatural()) { samples = (int)inp[6].number.re; } //if a positive integer, set the number of samples
      else { throw new CalculationException("Cannot approximate Runge-Kutta method using "+inp[6].number+" samples"); } //otherwise, return an error
    }
    Complex dx = inp[4].number.sub(inp[2].number).diveq(samples); //compute the change in the input
    
    Complex x = inp[2].number;          //get the initial input
    MathObj y = inp[3].passByValue(map);//and output
    for(int n=0;n<samples;n++) { //loop through all samples
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y); //set the values for our valuables
      MathObj k1 = inp[5].equation.solve(map2);           //solve the derivative at this point
      
      x.addeq(dx.mul(0.5)); MathObj y2 = y.add(k1.mul(dx.mul(0.5))); //increase x by dx/2, increase y by k1*dx/2
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2);           //set the values for our variables
      MathObj k2 = inp[5].equation.solve(map2);                      //solve the derivative at this point
      
      y2 = y.add(k2.mul(dx.mul(0.5)));          //increase y by k2*dx/2
      map2.put(outVar,y2);                      //set the values for our variables
      MathObj k3 = inp[5].equation.solve(map2); //solve the derivative at this point
      
      x.addeq(dx.mul(0.5)); y2 = y.add(k3.mul(dx));        //increase x by dx, increase y by k3*dx
      map2.put(inVar,new MathObj(x)); map2.put(outVar,y2); //set the values for our variables
      MathObj k4 = inp[5].equation.solve(map2);            //solve the derivative at this point
      
      y.addeq(k1.add(k2.add(k3).mul(2)).add(k4).muleq(dx.div(6))); //lastly, increase y by dx*(k1+2k2+2k3+k4)/6
    }
    
    return y; //finally, return our result
  } }),
  
  new MathFunc("SetHistoryDepth(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) throws CalculationException {
    if(inp[0].number.isInt() && inp[0].number.re>5 && inp[0].number.re<=5000) {
      history.changeHistoryDepth((int)inp[0].number.re, true);
      return new MathObj(false, "Done");
    }
    throw new CalculationException("History depth must be an integer between 6 and 5000");
  } }),
  
  new MathFunc("GetHistoryDepth(","",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(history.entries);
  } }),
  
  new MathFunc("GetFrameRate(","",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) {
    return new MathObj(30000f/(frame2-frame1));
  } })
  
  //null
  //new MathFunc("(","c",new Functional() { public MathObj func(HashMap<String, MathObj> map, MathObj... inp) { return new MathObj(inp[0].number); } }),
  
  //TODO buildVec, buildMat, d/dx, d2/dx2, integral, limit, Secant, Newton, Halley, Euler, RK4
  //TODO make Equation.funclist just check every item in the function dictionary, make minInps and maxInps just evaluate the regex to figure it out, make recursivecheck just check where in the regex is an e
);


static class SimplePattern { //a class which compactifies & speeds up regex expressions, partially by forbidding certain regex behaviors (only permits certain characters)
  short[] charPat; //shorts describing which of up to 16 chars can be at each point
  short[] min;     //the minimum amount of each char pattern
  short[] max;     //the maximum amount of each char pattern
  int absMin, absMax;
  
  int size() { return min.length; } //returns the number of entries in this
  
  //used to map characters/variable types to bytes
  static HashMap<Character, Byte> cMatcher = new HashMap<Character, Byte>() {{ put('b',(byte)0); put('c',(byte)1); put('v',(byte)2); put('m',(byte)3); put('d',(byte)4); put('a',(byte)5); put('e',(byte)6); put('M',(byte)7); put('N',(byte)8); put('V',(byte)9); }};
  static EnumMap<MathObj.VarType, Byte> vMatcher = new EnumMap<MathObj.VarType, Byte>(MathObj.VarType.class) {{ put(MathObj.VarType.BOOLEAN,(byte)0); put(MathObj.VarType.COMPLEX,(byte)1); put(MathObj.VarType.VECTOR,(byte)2); put(MathObj.VarType.MATRIX,(byte)3); put(MathObj.VarType.DATE,(byte)4); put(MathObj.VarType.ARRAY,(byte)5); put(MathObj.VarType.EQUATION,(byte)6); put(MathObj.VarType.MESSAGE,(byte)7); put(MathObj.VarType.NONE,(byte)8); put(MathObj.VarType.VARIABLE,(byte)9); }};
  
  SimplePattern(String r) { //compiles a regex string into a simple pattern
    ArrayList<Short> cpat = new ArrayList<Short>(), min2 = new ArrayList<Short>(), max2 = new ArrayList<Short>(); //arraylists to store everything
    
    for(int n=0;n<r.length();n++) { //loop through all characters in the string
      switch(r.charAt(n)) { //switch the character at this position
        case '.': cpat.add((short)-1); min2.add((short)1); max2.add((short)1); break; // .: anything, 1 time
        case '*': {
          min2.set(min2.size()-1,(short)0); max2.set(max2.size()-1,Short.MAX_VALUE); //*: the previous entry can happen 0 - inf times
        } break;
        case '+': {
          min2.set(min2.size()-1,(short)1); max2.set(max2.size()-1,Short.MAX_VALUE); //+: the previous entry can happen 1 - inf times
        } break;
        case '?': {
          min2.set(min2.size()-1,(short)0); max2.set(max2.size()-1,(short)1); //?: the previous entry can happen 0 - 1 times
        } break;
        case '[': {
          short putter = 0; //the thing we're going to add to cpat
          boolean negate = false; //whether or not this is going to be negated
          for(n++;r.charAt(n)!=']';n++) { //loop through all characters until we find a right bracket
            if(r.charAt(n)=='^') { negate = true; } //if it has a caret, the whole thing is negated
            else { putter |= gen(r.charAt(n)); } //otherwise, OR this short with our code
          }
          if(negate) { putter ^= -1; } //if we have to negate, negate it all
          cpat.add(putter);                       //add this code to the list
          min2.add((short)1); max2.add((short)1); //give it quantity of 1
        } break;
        case '{': {
          String first = ""; //we have to create the first number in here
          for(n++;r.charAt(n)!='}'&&r.charAt(n)!=',';n++) { //loop through all characters until we find a right curly brace or a comma
            first+=r.charAt(n); //concat each character
          }
          int low = int(first); //cast to an integer
          if(r.charAt(n)=='}') { //if there was one number & no comma:
            min2.set(min2.size()-1,(short)low); max2.set(max2.size()-1,(short)low); //set it to the minimum & the maximum
          }
          else if(r.charAt(n+1)=='}') { //if there was one number followed by a single comma
            min2.set(min2.size()-1,(short)low); max2.set(max2.size()-1,Short.MAX_VALUE); //set it to the minimum to it, and the maximum to basically infinity
          }
          else { //if there are 2 numbers separated by a comma:
            String second = ""; //we have to create the second number in here
            for(n++;r.charAt(n)!='}';n++) { //loop through all characters again until we find the right curly brace
              second+=r.charAt(n); //concat each character
            }
            int high = int(second); //cast to an integer
            min2.set(min2.size()-1,(short)low); max2.set(max2.size()-1,(short)high); //set the minimum to the first & the maximum to the second
          }
        } break;
        default: {
          cpat.add(gen(r.charAt(n)));             //anything else: put this character here
          min2.add((short)1); max2.add((short)1); //make it happen one time
        }
      }
    }
    
    //now, we just have to simplify. We do this by combining adjacent terms
    for(int n=1;n<cpat.size();n++) { //loop through all entries (except the 0th)
      if(cpat.get(n-1)==cpat.get(n)) { //if two adjacent terms have the same code:
        min2.set(n-1, (short)(min2.get(n-1)+min2.get(n))); //add adjacent minimums
        max2.set(n-1, (short)(max2.get(n-1)+max2.get(n))); //add adjacent maximums
        if(max2.get(n-1)<0) { max2.set(n-1,Short.MAX_VALUE); } //if an overflow occurred, reset to the max value
        cpat.remove(n); min2.remove(n); max2.remove(n); //remove this entry
        n--; //decrement n so we don't skip anything
      }
    }
    
    charPat = new short[cpat.size()]; min = new short[cpat.size()]; max = new short[cpat.size()]; //init the arrays
    for(int n=0;n<cpat.size();n++) { charPat[n]=cpat.get(n); min[n]=min2.get(n); max[n]=max2.get(n); } //copy the contents to the arrays
    
    int[] minMax = minMax();
    absMin = minMax[0]; absMax = minMax[1];
  }
  
  static byte[] parse(MathObj.VarType[] v) {
    byte[] result = new byte[v.length]; for(int n=0;n<v.length;n++) { result[n] = vMatcher.get(v[n]); } return result;
  }
  
  static short gen(char c) { return (short)(1<<cMatcher.get(c)); } //generates the short code for this
  static short gen(MathObj.VarType v) { return (short)(1<<vMatcher.get(v)); } //generates the short code for this
  
  boolean matches(MathObj[] s, HashMap<String, MathObj> mapper) { //returns whether this array of variables matches this simple pattern
    if(s.length<absMin || s.length>absMax) { return false; } //short-circuit: if the expression is too short/too long, immediately return false
    
    int ind2=0; //the index in the string
    for(int ind1=0;ind1<charPat.length;ind1++) { //loop through all indices in the regular expression
      for(int n=0;n<min[ind1];n++) { //loop through the characters that must be consumed
        
        if(ind2==s.length) { return false; } //if at the end, then this character can no longer be consumed, so return false
        if((gen(s[ind2].type)&charPat[ind1]) == 0) {   //if this character can't be consumed:
          if(!s[ind2].isVariable()) { return false; }  //if not a variable, then that's that, return false
          else { //otherwise, try dereferencing it once and see if that works
            s[ind2] = mapper.get(s[ind2].variable);    //dereference
            if(s[ind2]==null || (gen(s[ind2].type)&charPat[ind1]) == 0) { //if this character still can't be consumed, though, return false
              return false;
            }
          }
        }
        //if(ind2==s.length || (gen(s[ind2].type)&charPat[ind1]) == 0) { return false; } //if this character can't be consumed, return false
        ind2++; //increment the string index
      }
      for(int n=min[ind1];n<max[ind1];n++) { //now, loop through the characters that can be consumed, but don't have to be
        //if(ind2==s.length || (gen(s[ind2].type)&charPat[ind1]) == 0) { break; } //if this character can't be consumed, break from the loop
        if(ind2==s.length) { break; } //if at the end, then this character can no longer be consumed, so break from the loop
        if((gen(s[ind2].type)&charPat[ind1]) == 0) { //if this character can't be consumed:
          if(!s[ind2].isVariable()) { break; } //if not a variable, then that's that, break out of the loop
          else {
            MathObj deref = mapper.get(s[ind2].variable); //dereference
            if(deref==null || (gen(deref.type)&charPat[ind1]) == 0) { //if this still can't be consumed, though, break from the loop
              break;
            }
            else {
              s[ind2] = deref; //if it can be consumed, though, then make sure to change this variable to its value
            }
          }
        }
        
        ind2++; //otherwise, consume it, and increment the string index (note: all quantifiers are greedy. if it can be consumed, it will be consumed)
      }
      /*for(int n=0;n<max[ind1];n++) { //loop through all characters that are to be consumed
        if(ind2==s.length || (gen(s[ind2].type)&charPat[ind1]) == 0) { //this character cannot be consumed if it is out of bounds or it contradicts with the set of characters we're assigned to consume
          if(n<min[ind1]) { return false; } //if we haven't consumed the bare minimum amount of this character, return false (since the expression isn't matched)
          else            { break;        } //if we have consumed enough characters, though, just break and continue to the next consumable
        }
        ++ind2; //if the character can be consumed, however, we "consume" it by just incrementing the index; going to the next character
      }*/
    }
    return ind2==s.length; //if all characters were consumed, return true
  }
  
  boolean matches(byte[] seq) { //does the same thing, but to a sequence that's been preprocessed into bytes
    if(seq.length<absMin || seq.length>absMax) { return false; } //short-circuit: if the expression is too short/too long, immediately return false
    
    int ind2=0; //the index in the string
    for(int ind1=0;ind1<charPat.length;ind1++) { //loop through all indices in the regular expression
      for(int n=0;n<min[ind1];n++) { //loop through the characters that must be consumed
        if(ind2==seq.length || (1<<seq[ind2]&charPat[ind1]) == 0) { return false; } //if this character can't be consumed, return false
        ind2++; //increment the string index
      }
      for(int n=min[ind1];n<max[ind1];n++) { //now, loop through the characters that can be consumed, but don't have to be
        if(ind2==seq.length || (1<<seq[ind2]&charPat[ind1]) == 0) { break; } //if this character can't be consumed, break from the loop
        ind2++; //otherwise, consume it, and increment the string index (note: all quantifiers are greedy. if it can be consumed, it will be consumed)
      }
    }
    return ind2==seq.length; //if all characters were consumed, return true
  }
  
  int[] minMax() { //looks at the current regular expression, returns the min & max # of inputs
    int min2 = 0, max2 = 0; //the current minimum & maximum
    for(int n=0;n<size();n++) { //loop through all entries
      min2 += min[n]; //increment the minimum by each minimum
      max2 += max[n]; //increment the maximum by each maximum
    }
    if(max2 >= Short.MAX_VALUE) { max2 = Integer.MAX_VALUE; } //if the computed maximum is above a certain threshold, it is assumed to be infinite
    return new int[] {min2, max2}; //return the result
  }
}




static void transferVariables(HashMap<String, MathObj> from, HashMap<String, MathObj> to, String... exclude) { //this is used to keep changes made in one scope persistent in an outer scope
  //NOTE: If you ever plan on implementing threads into this calculator (key word: if), then this function might become obsolete, and you might instead want to have something that simply keeps different scopes synchronized
  
  for(Map.Entry<String,MathObj> iter : from.entrySet()) { //loop through all variables from the "from" scope
    
    if(!to.containsKey(iter.getKey())) { //if this variable wasn't declared in the "to" scope
      continue; //skip this entry
    }
    
    boolean skip = false; //now, see if this is part of the list of variables to exclude
    for(String ex : exclude) {
      if(ex.equals(iter.getKey())) {
        skip = true; break; //if it is, then we skip this
      }
    }
    if(skip) { continue; }
    
    to.put(iter.getKey(), iter.getValue()); //otherwise, transfer over the new value
  }
}
