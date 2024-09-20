public static class MathObj { //represents any mathematical object we can plug into our equations
  public Complex number=null; //a number
  public boolean bool=false;  //a boolean
  public CVector vector=null; //a vector
  public CMatrix matrix;      //a matrix
  public Date date;           //a date
  public MathObj[] array;     //an array
  public String message="";   //a string (usually error message)
  public VarType type = VarType.NONE; //type of variable
  public Equation equation = null; //an equation
  
  public boolean fp = false; //whether it's displayed at full precision (usually false)
  
  public enum VarType {BOOLEAN,COMPLEX,VECTOR,MATRIX,DATE,ARRAY,EQUATION,MESSAGE,NONE; String toString() { return name().toLowerCase(); } }
  
  public MathObj()             { type=VarType.NONE; }
  public MathObj(Complex c)    { number=c; type=VarType.COMPLEX; }
  public MathObj(double d)     { number=new Complex(d); type=VarType.COMPLEX; }
  public MathObj(boolean b)    { bool=b; type=VarType.BOOLEAN; }
  public MathObj(String s)     { message=s; type=VarType.MESSAGE; }
  public MathObj(CVector v)    { vector=v; type=VarType.VECTOR; }
  public MathObj(CMatrix m)    { matrix=m; type=VarType.MATRIX; }
  public MathObj(Date d)       { date=d; type=VarType.DATE; }
  public MathObj(Equation e)   { equation=e; type=VarType.EQUATION; }
  public MathObj(MathObj... a) { array=a; type=VarType.ARRAY; }
  
  public MathObj(Entry e) {
    if(e.getType()==EntryType.NUM) { number = Cpx.complex(e.getId()); type=VarType.COMPLEX; }
    else if(e.getType()==EntryType.CONST) {
      switch(e.getId()) {
        case "e": number = new Complex(Math.E);  type=VarType.COMPLEX; break;
        case "i": number = Cpx.i();              type=VarType.COMPLEX; break;
        case "π": case "pi"   : number = new Complex(Math.PI); type=VarType.COMPLEX; break;
        case "γ": case "gamma": number = new Complex(Mafs.GAMMA); type=VarType.COMPLEX; break;
        
        case "Catalan": number = new Complex(0.91596559417721902d); type = VarType.COMPLEX; break;
        
        case  "true": bool= true; type=VarType.BOOLEAN; break;
        case "false": bool=false; type=VarType.BOOLEAN; break;
        
        case "today": date = Date.today(); type=VarType.DATE; break;
        case "yesterday": date = Date.yesterday(); type=VarType.DATE; break;
        case "tomorrow": date = Date.tomorrow(); type=VarType.DATE; break;
        case "Sunday"   : date = Date.   sunday(); type=VarType.DATE; break;
        case "Monday"   : date = Date.   monday(); type=VarType.DATE; break;
        case "Tuesday"  : date = Date.  tuesday(); type=VarType.DATE; break;
        case "Wednesday": date = Date.wednesday(); type=VarType.DATE; break;
        case "Thursday" : date = Date. thursday(); type=VarType.DATE; break;
        case "Friday"   : date = Date.   friday(); type=VarType.DATE; break;
        case "Saturday" : date = Date. saturday(); type=VarType.DATE; break;
      }
      
      if(type==VarType.NONE) { //if we still haven't found it, it might be a date
        String s = e.getId(); //grab the ID
        for(int n=0;n<Month.matchers.length;n++) { //try seeing if this is a date
          if(s.startsWith(Month.matchers[n])) {    //if it starts with a month:
            s = s.substring(Month.matchers[n].length()); //remove the month from the beginning
            int day; long year; //now, we try to find the day and year
            int ind = s.indexOf(", "); //see if there's a comma somewhere there
            if(ind==-1) { day = Integer.parseInt(s); year = Date.year(); } //if no year given, set it to this year
            else { //otherwise:
              day = Integer.parseInt(s.substring(0,ind)); year = Long.parseLong(s.substring(ind+2)); //set the day to the first part, the year to the second part
            }
            date = new Date(Month.matchId[n],day,year); type=VarType.DATE; //finally, load the corresponding date
          }
        }
      }
    }
  }
  
  public MathObj(String s, boolean b) { //TODO whatever you were planning on doing with this
    if     (s.equals( "true")) { bool= true; type=VarType.BOOLEAN; }
    else if(s.equals("false")) { bool=false; type=VarType.BOOLEAN; }
    
    else if(s.equals("Overflow")) { number=new Complex(Double.POSITIVE_INFINITY); type=VarType.COMPLEX; }
    else if(s.equals("Negative Overflow")) { number=new Complex(Double.NEGATIVE_INFINITY); type=VarType.COMPLEX; }
    
    else {
      for(int n=0;n<Month.matchers.length;n++) { //try seeing if this is a date
        if(s.startsWith(Month.matchers[n])) {    //if it starts with a month:
          s = s.substring(Month.matchers[n].length()); //remove the month from the beginning
          int day; long year; //now, we try to find the day and year
          int ind = s.indexOf(", "); //see if there's a comma somewhere there
          if(ind==-1) { day = Integer.parseInt(s); year = Date.year(); } //if no year given, set it to this year
          else { //otherwise:
            day = Integer.parseInt(s.substring(0,ind)); year = Long.parseLong(s.substring(ind+2)); //set the day to the first part, the year to the second part
          }
          date = new Date(Month.matchId[n],day,year); type=VarType.DATE; //finally, load the corresponding date
          return; //quit the constructor
        }
      }
      
      if(type==VarType.NONE) { //if the type still hasn't been chosen yet
        number=Cpx.complex(s); type = (number==null) ? VarType.NONE : VarType.COMPLEX; //try casting to a complex number
      }
    }
  }
  
  boolean isNum() { return type==VarType.COMPLEX; }
  boolean isBool() { return type==VarType.BOOLEAN; }
  boolean isVector() { return type==VarType.VECTOR; }
  boolean isMatrix() { return type==VarType.MATRIX; }
  boolean isDate() { return type==VarType.DATE; }
  boolean isArray() { return type==VarType.ARRAY; }
  boolean isMessage() { return type==VarType.MESSAGE; }
  boolean isEquation() { return type==VarType.EQUATION; }
  boolean isNone() { return type==VarType.NONE; }
  
  boolean isNormal() { return type!=VarType.NONE && type!=VarType.MESSAGE; }
  
  void set(MathObj m) {
    bool=m.bool; number=m.number; vector=m.vector; matrix=m.matrix; message=m.message;
    type = m.type;
  }
  
  @Override
  public String toString() {
    String res;
    Complex.omit_Option = !fp;
    int dig = fp ? -1 : 13;
    switch(type) {
      case COMPLEX: res = number.toString(dig); break;
      case BOOLEAN: res = bool+"";              break;
      case VECTOR: res = vector.toString(dig);  break;
      case MATRIX: res = matrix.toString(dig);  break;
      case DATE:   res = date.toString();       break;
      case ARRAY: {
        StringBuilder sb = new StringBuilder("{");
        for(int n=0;n<array.length;n++) {
          if(n!=0) { sb.append(","); }
          sb.append(array[n]);
        }
        res = sb.append("}").toString();
      } break;
      case MESSAGE: res = message;              break;
      default: res = "NULL";
    }
    Complex.omit_Option=true;
    return res;
  }
  
  @Override
  public MathObj clone() {
    switch(type) {
      case COMPLEX: return new MathObj(number.copy());
      case BOOLEAN: return new MathObj(bool);
      case VECTOR: return new MathObj(vector.clone());
      case MATRIX: return new MathObj(matrix.clone());
      case DATE:   return new MathObj(date.clone());
      case ARRAY: { //TODO implement a check/special case for infinite recursion
        MathObj[] copyArr = new MathObj[array.length]; //create a copy array
        for(int n=0;n<array.length;n++) {
          copyArr[n] = array[n].clone(); //clone each individual element
        }
        return new MathObj(copyArr); //return resulting array
      }
      case MESSAGE: return new MathObj(message+"");
      case EQUATION: return new MathObj(equation); //TODO FOR NOW, WE ARE NOT CLONING THE EQUATION. THIS MIGHT CHANGE LATER
      case NONE: return new MathObj();
    }
    return null;
  }
  
  @Override
  public boolean equals(final Object obj) {
    if(obj instanceof MathObj) {
      MathObj m = (MathObj)obj;
      if(type!=m.type) { return false; }
      switch(type) {
        case COMPLEX: return number.equals(m.number);
        case BOOLEAN: return bool == m.bool;
        case VECTOR: return vector.equals(m.vector);
        case MATRIX: return matrix.equals(m.matrix);
        case DATE: return date.equals(m.date);
        case MESSAGE: return message.equals(m.message);
        case ARRAY: {
          if(array.length!=m.array.length) { return false; }
          for(int n=0;n<array.length;n++) {
            if(!array[n].equals(m.array[n])) { return false; }
          }
          return true;
        }
        case EQUATION: return false; //TODO FOR NOW, WE ARE NOT COMPARING EQUATIONS
        case NONE: return true;
      }
    }
    return false;
  }
  
  @Override
  public int hashCode() {
    switch(type) {
      case COMPLEX: return number.hashCode();
      case BOOLEAN: return bool ? 1231 : 1237;
      case VECTOR: return vector.hashCode();
      case MATRIX: return matrix.hashCode();
      case DATE: return date.hashCode();
      case MESSAGE: return message.hashCode();
      case ARRAY: {
        int hash = 3;
        for(MathObj m : array) {
          hash = 31*hash + m.hashCode();
        }
        return hash;
      }
      case EQUATION: return 1371;
      case NONE: return 8197;
    }
    return 8;
  }
  
  public String saveAsString() {
    String result = type.name()+" ";
    while(result.length()<9) { result+=" "; }
    switch(type) {
      case COMPLEX: result+=hex(number); break;
      case BOOLEAN: result+=bool?"1":"0"; break;
      case VECTOR: result+=hex(vector.size())+" "; for(int n=0;n<vector.size();n++) { result+=hex(vector.get(n))+" ";  } break;
      case MATRIX: result+=hex(matrix.h)+" "+hex(matrix.w)+" "; for(int i=1;i<=matrix.h;i++) for(int j=1;j<=matrix.w;j++) { result+=hex(matrix.get(i,j))+" "; } break;
      case DATE: result+=hex(date.day); break;
      case MESSAGE: result+=message; break;
      case ARRAY: {
        result += hex(array.length)+" "; //show the array length
        for(int n=0;n<array.length;n++) { //loop through the array
          if(n!=0) { result+=","; } //separate each entry w/ commas
          result += "("+array[n].saveAsString()+")"; //wrap each entry in parentheses
        }
      } break;
      case EQUATION: throw new RuntimeException("I'm not ready to save an equation to a file!!!");
      case NONE: break;
    }
    return result; //return result
  }
  
  public static MathObj loadFromString(String s) {
    switch(s.substring(0,8)) { //switch between the first 8 characters:
      case "COMPLEX ": {
        return new MathObj(cUnhex(s.substring(9)));
      }
      case "BOOLEAN ": {
        return new MathObj(s.charAt(9)=='1');
      }
      case "VECTOR  ": {
        int size = unhex(s.substring(9,17)); //compute the size of the vector
        Complex[] load = new Complex[size];  //load the vector array
        for(int n=0;n<size;n++) { load[n] = cUnhex(s.substring(18+34*n,50+34*n)); } //load each complex component
        return new MathObj(new CVector(load)); //return resulting vector
      }
      case "MATRIX  ": {
        int h = unhex(s.substring(9,17)), w = unhex(s.substring(18,26)); //find the dimensions of the matrix
        Complex[] load = new Complex[h*w]; //load the matrix array
        for(int n=0;n<h*w;n++) { load[n] = cUnhex(s.substring(27+34*n,59+34*n)); } //load each complex component
        return new MathObj(new CMatrix(h, w, load)); //return resulting matrix
      }
      case "DATE    ": {
        long d = lUnhex(s.substring(9,25));
        return new MathObj(new Date(d));
      }
      case "ARRAY   ": {
        int parCount = 0; //while iteratively evaluating the string, we must keep track of the number of parentheses
        int startInd = -1; //for each entry, we must know where that entry's string starts
        int size = unhex(s.substring(9,17)); //compute the size of the array
        MathObj[] elements = new MathObj[size]; //load the math object array
        int index = 0;
        
        for(int i=18;i<s.length();i++) { //loop through the remaining characters
          if(s.charAt(i)=='(') {
            if(parCount == 0) { startInd=i+1; }
            parCount++;
          }
          else if(s.charAt(i)==')') {
            parCount--;
            if(parCount == 0) {
              elements[index] = loadFromString(s.substring(startInd,i)); //load from the substring from the start index to here
              index++; //increment the index
            }
          }
        }
        
        return new MathObj(elements); //return a math object created from that array
      }
      case "MESSAGE ": {
        return new MathObj(s.substring(9));
      }
      case "EQUATION": {
        throw new RuntimeException("I'm not ready to load an equation from a file!!!");
      }
      default: return new MathObj();
    }
  }
  
  //////////////// ARITHMETIC ////////////////////////
  //(Important for numerical methods, such as integration or Runge Kutta)
  
  public MathObj add(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot add "+type+" to "+m.type); }
    switch(type) {
      case COMPLEX: return new MathObj(number.add(m.number));
      case VECTOR : return new MathObj(vector.add(m.vector));
      case MATRIX : return new MathObj(matrix.add(m.matrix));
      default: throw new RuntimeException("Cannot add "+type+" together");
    }
  }
  
  public MathObj sub(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot subtract "+type+" minus "+m.type); }
    switch(type) {
      case COMPLEX: return new MathObj(number.sub(m.number));
      case VECTOR : return new MathObj(vector.sub(m.vector));
      case MATRIX : return new MathObj(matrix.sub(m.matrix));
      default: throw new RuntimeException("Cannot subtract "+type+" together");
    }
  }
  
  public MathObj addeq(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot add "+type+" to "+m.type); }
    switch(type) {
      case COMPLEX: number.addeq(m.number); break;
      case VECTOR : vector.addeq(m.vector); break;
      case MATRIX : matrix.addeq(m.matrix); break;
      default: throw new RuntimeException("Cannot add "+type+" together");
    }
    return this;
  }
  
  public MathObj subeq(final MathObj m) {
    if(type!=m.type) { throw new RuntimeException("Cannot subtract "+type+" minus "+m.type); }
    switch(type) {
      case COMPLEX: number.subeq(m.number); break;
      case VECTOR : vector.subeq(m.vector); break;
      case MATRIX : matrix.subeq(m.matrix); break;
      default: throw new RuntimeException("Cannot subtract "+type+" together");
    }
    return this;
  }
  
  public MathObj neg() {
    switch(type) {
      case COMPLEX: return new MathObj(number.neg());
      case VECTOR : return new MathObj(vector.neg());
      case MATRIX : return new MathObj(matrix.neg());
      default: throw new RuntimeException("Cannot negate "+type);
    }
  }
  
  public MathObj negeq() {
    switch(type) {
      case COMPLEX: number.negeq(); break;
      case VECTOR : vector.negeq(); break;
      case MATRIX : matrix.negeq(); break;
      default: throw new RuntimeException("Cannot negate "+type);
    }
    return this;
  }
  
  public MathObj mul(final Complex c) {
    switch(type) {
      case COMPLEX: return new MathObj(number.mul(c));
      case VECTOR : return new MathObj(vector.mul(c));
      case MATRIX : return new MathObj(matrix.mul(c));
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
  }
  
  public MathObj mul(final double d) {
    switch(type) {
      case COMPLEX: return new MathObj(number.mul(d));
      case VECTOR : return new MathObj(vector.mul(d));
      case MATRIX : return new MathObj(matrix.mul(d));
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
  }
  
  public MathObj div(final Complex c) {
    switch(type) {
      case COMPLEX: return new MathObj(number.div(c));
      case VECTOR : return new MathObj(vector.div(c));
      case MATRIX : return new MathObj(matrix.div(c));
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
  }
  
  public MathObj div(final double d) {
    switch(type) {
      case COMPLEX: return new MathObj(number.div(d));
      case VECTOR : return new MathObj(vector.div(d));
      case MATRIX : return new MathObj(matrix.div(d));
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
  }
  
  public MathObj muleq(final Complex c) {
    switch(type) {
      case COMPLEX: number.muleq(c); break;
      case VECTOR : vector.muleq(c); break;
      case MATRIX : matrix.muleq(c); break;
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
    return this;
  }
  
  public MathObj muleq(final double d) {
    switch(type) {
      case COMPLEX: number.muleq(d); break;
      case VECTOR : vector.muleq(d); break;
      case MATRIX : matrix.muleq(d); break;
      default: throw new RuntimeException("Cannot multiply "+type+" by scalar");
    }
    return this;
  }
  
  public MathObj diveq(final Complex c) {
    switch(type) {
      case COMPLEX: number.diveq(c); break;
      case VECTOR : vector.diveq(c); break;
      case MATRIX : matrix.diveq(c); break;
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
    return this;
  }
  
  public MathObj diveq(final double d) {
    switch(type) {
      case COMPLEX: number.diveq(d); break;
      case VECTOR : vector.diveq(d); break;
      case MATRIX : matrix.diveq(d); break;
      default: throw new RuntimeException("Cannot divide "+type+" by scalar");
    }
    return this;
  }
}


static String hex(long l) { return hex((int)(l>>>32))+hex((int)l); }
static String hex(double d) { return hex((long)Double.doubleToLongBits(d)); }
static String hex(Complex c) { return hex(c.re)+" "+hex(c.im); }

static long lUnhex(String s) { return ((long)unhex(s.substring(0,8)))<<32 | (long)unhex(s.substring(8)) & ((1l<<32)-1); }
static double dUnhex(String s) { return Double.longBitsToDouble(lUnhex(s)); }
static Complex cUnhex(String s) { return new Complex(dUnhex(s.substring(0,16)), dUnhex(s.substring(17))); }
