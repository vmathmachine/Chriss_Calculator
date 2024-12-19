public static class Equation implements Iterable<Entry> {
  
  ArrayList<Entry> tokens = new ArrayList<Entry>(); //all the entries in the equation
  
  public Equation() { }
  
  public Equation(ParseList p) {
    for(String s : p) {
      tokens.add(new Entry(s)); //add each token
    }
  }
  
  private Equation(ArrayList<Entry> toks) { tokens = toks; } //set each token individually
  
  @Override
  public String toString() {
    String res = "";
    //for(Entry s : tokens) { res+=s.getId()+", "; }
    for(Entry s : tokens) {
      res += s.getId();
      if(s.getId().equals("Equation")) { res += "("+s.asNum.equation+")"; }
      res += ", ";
    }
    return res;
  }
  
  public int size() { return tokens.size(); }
  public Entry get(int i) { return tokens.get(i); }
  public void add(Entry e) { tokens.add(e); }
  public void add(int i, Entry e) { tokens.add(i,e); }
  public void remove(int i) { tokens.remove(i); }
  
  boolean isEmpty() { return size()==0 || size()==2 && tokens.get(0).id.equals("(") && tokens.get(1).id.equals(")"); }
  
  @Override
  public Iterator<Entry> iterator() {
    return tokens.iterator();
  }
  
  public void correctAmbiguousSymbols() { //corrects symbols that are ambiguous in meaning (such as ! being used for factorial or logical negation)
    for(int n=1;n<size();n++) { //loop through all entries (except the first)
      Entry curr = get(n), trail = get(n-1); //record current & previous entries
      
      if(curr.getId().equals("!") && !trail.rightNum()) { //if this entry is a !, and the previous entry WASN'T the right of a number:
        tokens.set(n,new Entry("__!__"));                 //replace the ! with the NOT symbol
      }
    }
  }
  
  public void squeezeInTimesSigns() { //squeezes * signs between adjacent numbers
    for(int n=1;n<size();n++) { //loop through every token (except the initial ( at the beginning)
      Entry curr = get(n), trail = get(n-1); //get the current & previous entries
      
      if(curr.leftNum() && trail.rightNum()) { //2 adjacent numbers:
        tokens.add(n,new Entry("*"));        //squeeze a * sign between them
        ++n;                                 //move 1 right
      }
    }
  }
  
  public void setUnaryOperators() { //changes lone + and - signs to unary operators
    for(int n=1;n<size();n++) { //loop through every token (except the initial ( at the beginning)
      Entry curr = get(n), trail = get(n-1); //record current & previous entries
      if((curr.getId().equals("+") || curr.getId().equals("-")) && !trail.rightNum()) { //if this is a + or -, and the previous token isn't a number:
        if(curr.getId().equals("+")) { tokens.remove(n); --n;            } //+: remove token & go back 1 step TODO see if this is a mistake, i.e. if there are cases where this is syntactically inaccurate
        else                         { tokens.set(n,new Entry("__-__")); } //-: swap minus sign with negation
      }
    }
  }
  
  public String validStrings() {
    for(Entry e : this) {
      if(e.getType()==EntryType.NONE) { return "Error: \""+e.getId()+"\" is not a valid token"; }
    }
    return "valid";
  }
  
  public String validPars() { //checks that all parentheses are closed (returns a message about its validity)
    int parVar = 0; //# of ( minus # of ) (if ever negative, config is invalid)
    for(int n=1;n<size()-1;n++) { //loop through all entries (except the 1st & last)
      Entry e = get(n);
      switch(e.getType()) {
        case LPAR: case LFUNC: ++parVar; break; //left ( or left func: increment
        case RPAR:             --parVar; break; //right ): decrement
        default:
      }
      if(parVar<0) { return "Error: unclosed right parentheses"; } //if parvar is ever negative, configuration is invalid
    }
    return (parVar==0) ? "valid" : "Error: unclosed left parentheses"; //return valid iff # of ( == # of )
  }
  
  public String leftMeHanging() { //tests for an error I call "left me hanging"
    for(int n=1;n<size();n++) { //loop through all entries (except the first)
      Entry curr = get(n), trail = get(n-1); //record current & previous entries
      EntryType first = trail.getType(), second = curr.getType();
      
      if(!first.rightNum() && !second.leftNum()) { //an operator, left unary, left function, (, or comma is followed by an operator, right unary, ), or comma
        if(first.hasLeftPar() && second==EntryType.RPAR) { trail.inps=0; }    //special case: a ( or left function followed by a ): this isn't an error, but rather a function w/ 0 inputs
        else { return "Error: "+trail.getId()+" followed by "+curr.getId(); } //otherwise, return an error message
      }
    }
    return "valid"; //no error encountered: return valid
  }
  
  public String countCommas() { //tests for functions with the wrong number of commas
    Stack<Entry> records = new Stack<Entry>(); //a stack of functions (bottom=outermost, top=innermost)
    for(Entry curr : this) { //loop through all the entries
      
      if(curr.getType().hasLeftPar()) { //if this has a left parenthesis,
        records.push(curr);             //push it onto the stack
      }
      else if(curr.getType()==EntryType.COMMA) { //if it's a comma:
        Entry e = records.peek(); //record the current top of the stack
        e.inps++;                 //increment the number of inputs
        if(e.inps > functionDictionary.minMax.get(e.id)[1]) { return "Error: too many inputs for function "+e.id; } //if too many inputs, return message saying so
      }
      else if(curr.getType()==EntryType.RPAR) { //if this has a right parenthesis,
        Entry e = records.peek(); //record the current top of the stack
        if(e.inps < functionDictionary.minMax.get(e.id)[0]) { return "Error: too few inputs for function "+e.id; } //if too few inputs, return message saying so
        if(!parenthesesMatch(e.id,curr.id)) { return "Error: cannot close \""+e.id+"\" with \""+curr.id+"\""; } //if the parentheses match incorrectly, return a message saying so
        records.pop(); //pop this off the stack
      }
    }
    
    return "valid"; //no error encountered: return valid
  }
  
  private static boolean parenthesesMatch(String a, String b) { //assuming a is a left parenthesis/left function, and b is a right parenthesis (of some kind), this function tells us if b is allowed to close a
    //return a.equals("[") == b.equals("]"); //for now, the only rule is that (a is [) XNOR (b is ])
    switch(a) {
      case "[": return b.equals("]");
      case "{": return b.equals("}");
      default : return b.equals(")");
    }
  }
  
  
  
  public Equation shuntingYard() { //performs the shunting yard algorithm on it (damages input)
    Stack<Entry> opStack = new Stack<Entry>(); //operator stack
    Equation output = new Equation();          //output
    
    while(size()!=0) { //perform the following loop until size is 0
      Entry curr = get(0); //grab first token
      Entry topOp;         //operator on top of stack
      
      switch(curr.getType()) { //each step is determined by the current token type
        case  NUM: case CONST:  output.add(curr); break; //number: move to end of output stack
        case LPAR: case LFUNC: case LUNOP: opStack.add(curr); break; //(, left operator, or left function: push to top of operator stack
        case LASSOP: case RASSOP: /*case LUNOP:*/ case RUNOP: { //operator:
          
          /*   SHUNTING YARD RULE FOR OPERATORS:
          push the top operator to the output stack as long as it hasn't a ( and also either
          ∙ is a right unary operator
          ∙ has greater precedence than the token (from the input stack)
          ∙ has equal precedence to the token and is left associative
          after that, you can push the current token to the operator stack */
          
          topOp = opStack.peek(); //get operator at top of stack
          boolean cooperates = false; //true in the special case that our operator cooperates with one of the operators in the stack
          
          while(!topOp.hasLeftPar() && (topOp.getType()==EntryType.RUNOP || topOp.getPrecedence() > curr.getPrecedence() ||
                topOp.getPrecedence()==curr.getPrecedence() && curr.getType()==EntryType.LASSOP)) { //loop through op stack based on above rules
            
            //first, see if these 2 operators cooperate
            Entry cooperate = Entry.cooperate(topOp,curr);
            if(cooperate!=null) { //if they do:
              opStack.pop(); opStack.push(cooperate); //replace top operator with its cooperation with curr
              cooperates = true; break;               //a cooperation occurred, break from the loop
            }
            
            //otherwise (AKA most of the time):
            output.add(topOp);      //push the top operator to the operator stack
            opStack.pop();          //pop top operator
            topOp = opStack.peek(); //replace top op
          }
          if(!cooperates) { opStack.push(curr); } //finally, push the current operator onto the operator stack (unless the operators cooperated)
        } break;
        case COMMA: { //comma
          while(!opStack.peek().hasLeftPar()) { //pop ops from stack until we find a function
            output.add(opStack.pop()); //push to output stack & pop from op stack
          }
        } break;
        case RPAR: { //right parenthesis
          while(!opStack.peek().hasLeftPar()) { //loop until top op can close the )
            output.add(opStack.pop()); //push to output stack & pop from op stack
          }
          topOp = opStack.pop(); //pop top of operator stack
          if(topOp.getType()==EntryType.LFUNC) { //if the operator was a function:
            output.add(topOp);                   //push it onto the output stack
          }
        } break; //TODO fuse the comma and rpar to keep it dry
        default:
      }
      remove(0); //pop first token
    }
    //println(output); //DEBUG
    return output; //return output
  }
  
  void parseNumbers() { //parses all the numbers before solving (makes graphing and recursion easier)
    for(Entry entry : this) if(entry.getType()==EntryType.NUM) {
      entry.asNum = new MathObj(entry);
    }
  }
  
  //@return: in the end, we will find that our solve function separates this into n distinct equations. This returns what n is (n is supposed to be 1. If it's not, it's an error)
  public int arrangeRecursiveFunctions() { //this looks at all functions which recursively call other functions, then puts the latter functions into the former function's link
    
    ArrayList<ArrayList<Entry>> groups = new ArrayList<ArrayList<Entry>>(); //arraylist of grouped together entries. Each time we reach a function, we group together that function w/ its inputs
    
    for(int n=0;n<size();n++) { //loop through all entries
      Entry token = tokens.get(n); //grab the current entry
      switch(token.getType()) {
        case NUM: case CONST: { //number or constant:
          ArrayList<Entry> adder = new ArrayList<Entry>(1); adder.add(token); //create new group to add to the list
          groups.add(adder);                                                  //add group to the list
        } break;
        default: { //otherwise: (NOTE: all remaining types that weren't eliminated from previous functions will have their input number initialized)
          int[] linkGuide = recursiveCheck(token.getId()); //get which link needs to go where
          
          int zInd = groups.size()-token.inps; //locate the index of the zeroth input
          
          for(int k=0;k<linkGuide.length;k++) { //loop through all things we have to link to
            
            Equation equat = new Equation(groups.get(zInd+linkGuide[k])); //first, load the entry list at each link index, then convert them into an equation
            
            int ind = tokens.indexOf(equat.get(0)); //find where in the tokens list is the first entry of the equation
            for(int i=0;i<equat.size();i++) { //loop through all entries in the equation
              tokens.remove(ind); n--;        //remove each element, backtrack in the list
            }
            Entry link = new Entry(equat); //create an entry that links to the equation
            tokens.add(ind,link); n++;     //add this equation link to the token list, front track in the list
            ArrayList<Entry> replacement = new ArrayList<Entry>(1); replacement.add(link); //create an arraylist with just 1 element: this link
            groups.set(zInd+linkGuide[k],replacement); //remove this group, replace it with the equation it forms
          }
          //TODO check and see that this still works even if there are multiple links
          
          //zInd = groups.size()-token.inps; //reset the zeroth index
          for(int k=1;k<token.inps;k++) { //loop through all inputs after the 0th
            groups.get(zInd).addAll(groups.get(zInd+1)); //concatenate the next group onto the 0th group
            groups.remove(zInd+1);                       //remove that next group
          }
          
          if(token.inps==0) { //special case: 0 inputs in the function (or all the inputs were removed and made into links)
            ArrayList<Entry> adder = new ArrayList<Entry>(1); groups.add(adder); //create new group to add to the list (since it wasn't created by any of the 0 inputs)
          }
          
          groups.get(zInd).add(token); //concatenate this token onto the 0th group
        }
      }
      /*println();
      for(int k=0;k<groups.size();k++) {
        for(int i=0;i<groups.get(k).size();i++) { print(groups.get(k).get(i).getId()+", "); }
        println();
      }
      println();*/
    }
    //println(this); //DEBUG
    return groups.size(); //return how long this list is in the end
  }
  
  /*String detectVariableScope() { //returns whether or not each variable was declared in this scope
    //TODO this
  }*/
  
  public MathObj solve(HashMap<String, MathObj> mapper) throws CalculationException {
    ArrayList<MathObj> out = new ArrayList<MathObj>(); //array of all the mathematical objects we analyze to read this
    
    for(Entry e : this) { //loop through all entries
      switch(e.getType()) { //switch the entry type
        case NUM: out.add(e.asNum.clone()); break; //number ("number"): add the already calculated number to the list
        case CONST: { //constant:
          MathObj addMe; //variable to add
          
          addMe = new MathObj(e); //try casting e to a math object
          if(addMe.type==MathObj.VarType.NONE) {  //if that doesn't work,
            addMe = new MathObj(true, e.getId()); //set it to represent the variable
          }
          
          //if(vari==null) { addMe = new MathObj(e); } //if there is none, try casting it to a math Object
          //else           { addMe = vari.clone();   } //otherwise, add the linked variable
          if(addMe.type==MathObj.VarType.NONE) { throw new CalculationException("Cannot evaluate variable \""+e.getId()+"\""); } //if we get nothing, throw an error message
          out.add(addMe); //otherwise, add it to the list
        } break;
        case COMMA:
          println("HOW ARE THERE STILL COMMAS? I THOUGHT I KILLED YOU!!!"); //DEBUG
        break;
        case LASSOP: case RASSOP: case LFUNC: case LUNOP: case RUNOP: { //functions / operators: idk yet
          int ind = 0; long time = 0, dTime = 0, timeInit = 0;
          if(showPerformance) { time = timeInit = System.nanoTime(); }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(out.size()<e.inps) { throw new CalculationException("BIG ERROR: too many commas / not enough inputs in function "+e.getId()+" ("+out.size()+", "+e.inps+")"); }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          MathObj inp[] = new MathObj[e.inps]; //now, we have to group together all the inputs
          for(int n=0;n<e.inps;n++) { //loop through all inputs
            inp[n] = out.get(n+out.size()-e.inps); //load each input
          }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          //MathFunc function = functionDictionary.find(e.id, inp); //load the function which has the same name as this entry AND has the correct input configuration
          MathFunc[] options = functionDictionary.find(e.id);
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          MathFunc function = FuncList.find(options, inp, mapper);
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(function==null) {
            String inpList = inp.length==1 ? "":"inputs "; //create a string listing all the input types
            for(int n=0;n<inp.length;n++) { if(n!=0) { inpList+=", "; } inpList+=inp[n].type; }
            if(inp.length==0) { inpList="empty input set"; }
            throw new CalculationException("Error: cannot evaluate function \""+e.showFormattedId()+"\" on "+inpList);
          }
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          //MathObj res;
          //try { res = function.lambda.func(mapper, inp); } //evaluate the given function
          //catch(Exception ex) { res = new MathObj(ex.getMessage()); } //if there was an error in the evaluation, return an error message telling us what went wrong
          //TODO make this only catch the exceptions that were supposed to be caught (I think???)
          
          MathObj res = function.lambda.func(mapper, inp); //evaluate the given function
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(res.isMessage()) { return res; } //if it gives you an error message, return that message
          
          for(int n=0;n<e.inps;n++) { out.remove(out.size()-1); } //remove all elements that were a part of the input list
          //out.subList(out.size()-e.inps, out.size()).clear();
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          out.add(res); //add the result to the output list
          
          if(showPerformance) { dTime = System.nanoTime()-time; timeRec[ind] += dTime; timeRecSq[ind] += dTime*dTime; time += dTime; ++ind; }
          
          if(showPerformance) { sumTimeSq += (time-timeInit)*(time-timeInit); numTimesRec++; }
        }
      }
    }
    
    if(out.size()!=1) { throw new CalculationException("Error: for some reason, not everything was evaluated"); }
    
    if(out.get(0).isVariable()) { //if it's a variable
      MathObj vari = mapper.get(out.get(0).variable); //dereference it
      if(vari==null) { } //I don't really know what to do here?
      else { return vari; }
    }
    return out.get(0); //otherwise, return the math object itself
  }
  
  boolean checkForVar(String v) { //checks for use of a particular variable within an equation
    for(Entry ent : tokens) { //loop through all entries
      if(ent.id.equals(v)) { return true; } //if we see any of that variable, return true
      /*if(ent.links.length>0 && ent.links[0].tokens.size()>0 && ent.links[0].tokens.get(0).id.equals(v)) { //if the first link is just a direct reference to this variable, it could be an exclusion:
        String id = ent.id; //grab the id
        //if(id.equals("Σ(")||id.equals("Sigma(")||id.equals("Π(")||id.equals("Pi(")||id.equals("plug(")||id.equals("d/dx(")||id.equals("d²/dx²(")||id.equals("limit(")||id.equals("
        if(!id.equals("&&")&&!id.equals("||")&&!id.equals("?:")) { //turns out, it's actually easier to list out the things it can't be
          continue;                                                //if this variable is being directly referenced by this functional, it's an exclusion
        }
      }
      for(Equation eq2 : ent.links) { //loop through any and all linked equations
        if(eq2.checkForVar(v)) { return true; } //if any of the links contain that variable, return true
      }*/
      if(ent.asNum!=null && ent.asNum.isEquation()) { //TODO make it so this excludes when the variable is being reassigned within the equation
        if(ent.asNum.equation.checkForVar(v)) { return true; }
      }
    }
    return false; //if nothing was found, return false
  }
  
  
  
  
  
  //public static String[] funcList = largestToSmallest(new String[] {"(","[","√(","ln(","log(","abs(","arg(","Re(","Im(","conj(","sgn(","abs2(","abs²(","absq(","csgn(","fp(",
  //        "sin(","cos(","tan(","sec(","csc(","cot(","sinh(","cosh(","tanh(","sech(","csch(","coth(",
  //        "sin⁻¹(","cos⁻¹(","tan⁻¹(","sec⁻¹(","csc⁻¹(","cot⁻¹(","sinh⁻¹(","cosh⁻¹(","tanh⁻¹(","sech⁻¹(","csch⁻¹(","coth⁻¹(",
  //        "asin(","acos(","atan(","asec(","acsc(","acot(","asinh(","acosh(","atanh(","asech(","acsch(","acoth(",
  //        "floor(","ceil(","round(","frac(","GCF(","LCM(","Factor(","max(","min(","SqrWave(","SawWave(","TriWave(","rect(","θ(",
  //        "nCr(","nPr(","rand(","randInt(","Γ(","lnΓ(","ψ₀(","ψ0(","ψ(","K-Function(","Barnes-G(","erf(","erfi(","erfc(","erfcx(","FresnelC(","FresnelS(",
  //        "ζ(","η(","RS-θ(","RS-Z(","ξ(", "Li₂(","Li2(","Cl₂(","Cl2(","Li(", "Ein(","Ei(","li(","Si(","Ci(","E₁(","E1(","Aux-f(","Aux-g(",
  //        "EllipticK(","EllipticF(","EllipticE(","EllipticΠ(","EllipticPI(","Σ(","Sigma(","Π(","Pi(","∫(","Integral(","d/dx(","d²/dx²(","d^2/dx^2(","dⁿ/dxⁿ(","plug(","limit(","Secant(","Newton(","Halley(","Euler(","EulerMid(","RK4("/*,"fuck("*/,
  //        "mag(","magSq(","mag²(","dot(","cross(","perp(","pDot(","norm(","unit(","BuildVec(",
  //        "det(","tr(","T(","BuildMat1(","BuildMat2(","eigenvalues(",
  //        "AND(","OR(",
  //        "week(","New_Years(","Valentines(","St_Patricks(","Mothers_Day(","Fathers_Day(","Halloween(","Thanksgiving(","Christmas("});

  public static String[] varList = largestToSmallest(new String[] {"Ans","true","false","today","yesterday","tomorrow","Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Catalan","π","pi","e","γ","gamma","i"});
  
  /*public static int minInps(String func) { //minimum number of inputs a function can have
    switch(func) {
      case "GCF(": case "LCM(": case "max(": case "min(": case "[":                                                 return 0; //any # of inputs
      case "rand(": case "randInt(": case "ψ(": case "nCr(": case "nPr(": case "dot(": case "pDot(": case "cross(": return 2; //these take exactly 2 inputs
      case "Li(": case "EllipticF(": case "EllipticE(":                                                             return 1; //can take 1 or 2 inputs
      case "EllipticΠ(": case "EllipticPI(":                                                                        return 2; //can take 2 or 3 inputs
      
      case "plug(": case "BuildVec(":                                                                              return 3; //takes 3 inputs
      case "Σ(": case "Sigma(": case "Π(": case "Pi(": case "AND(": case "OR(": case "Secant(": case "BuildMat2(": return 4; //takes 4 inputs
      case "Halley(": case "BuildMat1(":                                                                           return 5; //takes 5 inputs
      
      case "d/dx(": case "d²/dx²(": case "d^2/dx^2(": case "limit(": return 3; //takes 3-5 inputs
      case "Newton(":                                                return 4; //takes 4-5 inputs
      case "Euler(": case "EulerMid(": case "RK4(":                  return 6; //takes 6-7 inputs
      case "dⁿ/dxⁿ(": case "∫(": case "Integral(":                   return 4; //takes 4-6 inputs
      
      default: return 1; //most functions accept exactly 1 input
    }
  }
  
  public static int maxInps(String func) { //maximum number of inputs a function can have
    switch(func) {
      case "GCF(": case "LCM(": case "max(": case "min(": case "[":                                                 return Integer.MAX_VALUE; //any # of inputs
      case "rand(": case "randInt(": case "ψ(": case "nCr(": case "nPr(": case "dot(": case "pDot(": case "cross(": return 2;                 //these take exactly 2 inputs
      case "Li(": case "EllipticF(": case "EllipticE(":                                                             return 2;                 //can take 1 or 2 inputs
      case "EllipticΠ(": case "EllipticPI(":                                                                        return 2;                 //can take 2 or 3 inputs (should be able to take 3, but that hasn't been programmed in yet)
      
      case "plug(": case "BuildVec(":                                                                              return 3; //takes 3 inputs
      case "Σ(": case "Sigma(": case "Π(": case "Pi(": case "AND(": case "OR(": case "Secant(": case "BuildMat2(": return 4; //takes 4 inputs
      case "Halley(": case "BuildMat1(":                                                                           return 5; //takes 5 inputs
      
      case "d/dx(": case "d²/dx²(": case "d^2/dx^2(": case "limit(": return 5; //takes 3-5 inputs
      case "Newton(":                                                return 5; //takes 4-5 inputs
      case "Euler(": case "EulerMid(": case "RK4(":                  return 7; //takes 6-7 inputs
      case "dⁿ/dxⁿ(": case "∫(": case "Integral(":                   return 6; //takes 4-6 inputs
      
      default: return 1; //most functions accept exactly 1 input
    }
  }*/
  
  //ASSERTION: the outputted array must (MUST) be sorted, least to greatest
  public static int[] recursiveCheck(String func) { //given a function, this'll tell us which indices of its input set corresponds to which link
    switch(func) {
      case "&&": case "||":                                                        return new int[] {1}; //&& and ||: link 0 is input 1 (not input 0)
      case "Σ(": case "Sigma(": case "Π(": case "Pi(": case "AND(": case "OR(":    return new int[] {3}; //sum and product: link 0 is input 3 (variable, start, end, equation)
      case "plug(": case "d/dx(": case "d²/dx²(": case "d^2/dx^2(": case "limit(": return new int[] {2}; //plug, derivatives, limit: link 0 is input 2 (variable, value, equation [epsilon] [method])
      case "BuildVec(": case "BuildArray(":                                        return new int[] {2}; //build vector/array: link 0 is input 2 (size, variable, equation for each element)
      case "dⁿ/dxⁿ(": case "d^n/dx^n(":                                            return new int[] {3}; //n-th derivative: link 0 is input 3 (n, variable, value, equation [epsilon] [method])
      case "∫(": case "Integral(":                                                 return new int[] {3}; //integral: link 0 is input 3 (variable, start, end, equation [samples] [method])
      case "Secant(":                                                              return new int[] {3}; //Secant method: link 0 is input 3 (variable, x0, x1, equation)
      case "Newton(":                                                              return new int[] {2,3}; //Newton's method: link 0 is input 2, link 1 is input 3 (variable, initial, equation, derivative)
      case "Halley(":                                                              return new int[] {2,3,4}; //Halley's method: link 0 is input 2, link 1 is input 3, link 2 is input 4 (var, init, equation, derivative, second derivative)
      case "Euler(": case "EulerMid(": case "ExpTrap(": case "RK4(":               return new int[] {5}; //Euler's & Runge Kutta method: link 0 is input 5 (inp var, out var, init inp, init out, final inp, derivative, [steps])
      case "BuildMat1(":                                                           return new int[] {4}; //Build matrix (element by element): link 0 is input 4 (height, width, row index, column index, equation)
      case "BuildMat2(":                                                           return new int[] {3}; //Build matrix (vector by vector): link 0 is input 3 (height, width, row index, equation)
      
      case "scope(": return new int[] {0};
      case "while(": case "do(": return new int[] {0,1};
      case "for(": return new int[] {3};
      
      case "?:": return new int[] {1,2}; //the ternary operator has 2 links: one which is used for true, one which is used for false
      
      default: return new int[] {}; //for most functions, though, there aren't any links
    }
  }
  
  public static String[] largestToSmallest(String[] inp) { //sort strings largest to smallest
    for(int i=1;i<inp.length;i++) { //loop through all elements
      int len = inp[i].length();    //record string length
      for(int j=i;j>0;j--) {        //loop through all strings before this
        if(len>inp[j-1].length()) { String temp = inp[j]; inp[j]=inp[j-1]; inp[j-1]=temp; } //if out of order, swap
        else { break; }             //otherwise, exit j loop
      }
    }
    return inp; //return result
  }
}

static class CalculationException extends Exception {
  CalculationException(String s) {
    super(s);
  }
}
