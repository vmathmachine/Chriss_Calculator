public static enum EntryType { //it's useful to classify entries in an equation into types. Namely, literals, constants, left-associative operators, right-associative operators, left unary operators, right unary operators, left parentheses, right parentheses, left-hand functions, right-hand functions, ???, commas, and unclassified
  NUM, CONST, LASSOP, RASSOP, LUNOP, RUNOP, LPAR, RPAR, LFUNC, COMMA, NONE;
  
  boolean leftNum () { return this==NUM || this==CONST || this==LUNOP || this==LPAR || this==LFUNC; } //acts like a number on the left: numeral, constant, left unary operator, (, left function
  boolean rightNum() { return this==NUM || this==CONST || this==RUNOP || this==RPAR;                } //acts like a number on the right: numeral, constant, right unary operator, )
  
  boolean isMidOperator() { return this==LASSOP || this==RASSOP;                               } //is an operator that goes between two things
  boolean    isOperator() { return this==LASSOP || this==RASSOP || this==LUNOP || this==RUNOP; } //is an operator (regardless of associativity or if it's unary)
  boolean    hasLeftPar() { return this==LPAR   || this==LFUNC;                                } //has left parenthesis (thus needs to be closed)
}

public static class Entry {
  String id;      //string identifier
  EntryType type; //entry type
  byte prec;      //operator precedence
  short inps=-1;  //how many inputs it has (unset by default)
  
  MathObj asNum=null; //record the math object as a number (speeds up graphing)
  
  public Entry(String i) {
    id = i;                  //set ID
    type = getType(i);       //get entry type
    prec = getPrecedence(i); //get precedence
    inps = getInps(type);    //get inputs
  }
  
  public Entry(Equation eq) {
    id = "Equation";
    type = EntryType.NUM; prec = 0;
    asNum = new MathObj(eq);
  }
  
  private Entry(String i, EntryType ty, byte pr) {
    id=i; type = ty; prec = pr; //set the id, type, & precision
  }
  
  Entry setInps(int i) { inps = (short)i; return this; }
  
  @Override
  public Entry clone() {
    return new Entry(id, type, prec);
  }
  
  //@Override
  public boolean equals(Entry e) {
    return id.equals(e.id);
  }
  
  String showFormattedId() { //some operators/functions are wrapped in __ (so that the compiler can differentiate different versions), and this prints them out without the __s
    int leftInd = 0, rightInd = id.length(); //we're going to use these indices to slice off the opening and closing __s (if any)
    if(id.length()>=2 && id.charAt(0)=='_' && id.charAt(1)=='_') { //if it starts with 2 underscores:
      leftInd=2;
      while(leftInd<id.length() && id.charAt(leftInd)=='_') { //set our left index to the first index of a non-underscore
        leftInd++;
      }
    }
    if(id.length()>=2 && id.charAt(rightInd-1)=='_' && id.charAt(rightInd-2)=='_') { //if it ends with 2 underscores:
      rightInd-=2;
      while(rightInd>=0 && id.charAt(rightInd-1)=='_') { //set our right index to the index right after the last non-underscore
        rightInd--;
      }
    }
    
    if(leftInd==0 && rightInd==id.length()) { return id; } //if not wrapped in __s, just return the ID as is
    
    if(leftInd >= rightInd) { return ""; } //special case: if the ID is composed entirely of underscores, return empty string
    
    return id.substring(leftInd, rightInd); //otherwise, return the string, but with the underscores removed
  }
  
  public static EntryType getType(String i) { //infers the entry type from the string identification
    
    boolean isDouble = true; //try to cast to double
    try { Double.parseDouble(i); }
    catch(NumberFormatException e) { isDouble = false; }
    
    if(isDouble) { return EntryType.NUM; } //can be cast to double: numeral type
    if(i.length()==1 && Character.isLetter(i.charAt(0))) { return EntryType.CONST; } //is a letter: constant type
    for(String s : Equation.varList) { if(s.equals(i)) { return EntryType.CONST; } } //is part of the variable list: constant type
    if(!i.equals("(") && i.charAt(i.length()-1)=='(' || i.equals("[") || i.equals("{")) { return EntryType.LFUNC; } //ends in left parenthesis (or is left bracket/curly brace): left function type
    
    for(String m : Month.matchers) { //try to see if this is a date
      if(i.startsWith(m)) { return EntryType.CONST; } //if it begins with a date, it's a "number"
    }
    
    switch(i) {
      case "+": case "-": case "*": case "/": case "//": case "%":
      case "·": case "•": case "×":
      case "&": case "|": case "&&": case "||": case "==": case "!=":
      case "=": case "<": case ">": case "<=": case ">=": case ":":
      case ";":
      case "?:": case "\\": case "_":                                return EntryType.LASSOP;    //these are all left associative operators
      case "^": case "?": case ":=":                                 return EntryType.RASSOP;    //^, ?, := are right associative operators
      case "(":                                                      return EntryType.LPAR;      //(: left parenthesis
      case ")": case "]": case "}":                                  return EntryType.RPAR;      //): right parenthesis
      case "²": case "³": case "!":                                  return EntryType.RUNOP;     //right function type
      case "__-__": case "__!__": case "~":                          return EntryType.LUNOP;   //left unary operator
      case ",":                                                      return EntryType.COMMA;     //comma
    }
    return EntryType.NONE; //otherwise, you done fucked up
  }
  
  public static byte getPrecedence(String i) { //infers the operator precedence from the string identification
    if(i==null) { return 0; } //special case: return 0
    
    switch(i) {
      case ";": return 1; //semicolons & other statement separators: absolute lowest possible precedence
      
      case ":=": return 2; //assignment: lowest precedence
      case "?": case ":": case "?:": return 3; //ternary: next precedence
      
      //boolean
      case "||": return 4; //OR: lowest precedence
      case "&&": return 5; //AND: next precedence
      
      case "|": return 6; //bitwise OR
      //RIGHT BETWEEN THESE TWO COMES XOR, but currently, XOR is just the caret, which has extremely high precedence
      case "&": return 7; //bitwise AND
      
      //comparisons
      case "=": case "==": case "!=":           return 8; //tests for equality
      case "<": case ">": case "<=": case ">=": return 9; //inequalities
      
      //theoretically, bit shifting operators would go here, but as of now, I have no intention to implement them
      
      //arithmetic
      case "+": case "-":                                 return 10; //lowest precedence: +/-
      case "*": case "/": case "%": case "//": case "\\": return 11; //next precedence: times, divide, modulo, truncated divide, left divide
      case "·": case "•": case "×":                       return 12; //dot and cross product have higher precedence, so that they can be performed before scalar multiplication
      case "__-__": case "__!__": case "~":               return 13; //negation and other unary operators have higher precedence
      case "^": case "²": case "³": case "!":             return 14; //highest precedence: exponent (and factorial)
      
      case "_":                                           return 15; //subscript operator: even higher precedence
    }
    
    return 0; //for pretty much anything else, precedence doesn't even apply
  }
  
  public static short getInps(EntryType t) { //infers how many inputs it should have from the entry type
    switch(t) {
      case LASSOP: case RASSOP: return 2; //2 input operators have 2 inputs
      case LUNOP: case RUNOP: return 1; //unary operators have 1 input
      case LPAR: case LFUNC: return 1;  //functions START with 1 input
      default: return 0;                //anything else has 0 inputs
    }
  }
  
  public String      getId() { return   id; }
  public EntryType getType() { return type; }
  public int getPrecedence() { return prec; }
  public int   getInputNum() { return inps; }
  
  public boolean leftNum() { return type.leftNum(); } //true if it can be treated like a number on the left
  public boolean rightNum() { return type.rightNum(); } //true if it can be treated like a number on the right
  public boolean isOperator() { return type.isOperator(); } //true if it's an operator (regardless of associativity)
  public boolean hasLeftPar() { return type.hasLeftPar(); } //true if it has a left parenthesis (needs closing)
  
  //Sometimes, entries must cooperate to make the syntax correct, such as the ternary operators, or the NAND or NOR operators chaining together to represent collective NAND/NOR
  //this function checks to see if the given 2 entries are meant to cooperate. If they are, it returns an entry representing their combined efforts. Otherwise, it returns null
  public static Entry cooperate(Entry a, Entry b) {
    if(a.id.equals("?") && b.id.equals(":")) { return new Entry("?:").setInps(3); } //ternary operators have to cooperate
    
    if(a.id.equals("abs(") && b.id.equals("²")) { return new Entry("abs²("); } //abs and ² cooperate to form the absolute square
    
    return null; //everything else: return null
  }
  
  //public static boolean isLetter(char c) { return c>='A' && c<='Z' || c>='a' && c<='z'; }
}
