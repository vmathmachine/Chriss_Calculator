public static class ParseList implements Iterable<String> { //a class specifically for taking a list of chars, reorganizing them for parsing reasons, then being converted to an equation
  public ArrayList<String> list = new ArrayList<String>(); //storage of all the strings that'll be parsed into an expression
  
  public ParseList(String inp) { //splits up all the chars and creates a new ParseList
    char[] arr = inp.toCharArray();       //split string into char array
    list.add("(");                        //add a left parenthesis at the beginning
    for(char c : arr) { list.add(c+""); } //cast each char to a string and add to list
    list.add(")");                        //add a right parenthesis at the end
  }
  
  @Override
  public Iterator<String> iterator() {
    return list.iterator();
  }
  
  public String get(int ind) { return list.get(ind); }
  public int size() { return list.size(); }
  
  public void concat(int ind, String str) {
    list.set(ind,list.get(ind)+str);
  }
  
  @Override
  public String toString() {
    String ret = "";
    for(String s : this) { ret+=s+", "; }
    return ret;
  }
  
  public void groupFuncs() { //group together functions
    ArrayList<Integer> parPos = leftParPosList(); //get a list of the positions of all left parentheses
    
    for(String match : functionDictionary.lookup) { //loop through all strings in the list of function names (big to small)
      for(int k=0;k<parPos.size();k++) {    //loop through all left parentheses
        int pos = parPos.get(k);            //record the position in the list
        
        int startPos = pos-match.length()+1; //find the position of the start of the match
        if(startPos>=0) {                    //first make sure it's non-negative
          boolean matches = matchFound(startPos, match); //see if this string is right before this parenthesis
          
          if(matches) { //if it WAS a match
            groupStringOfSize(startPos,match.length()); //group together strings over that range into one string
            
            parPos.remove(k); //remove this parenthesis position
            for(int n=k;n<parPos.size();n++) {
              parPos.set(n,parPos.get(n)-match.length()+1); //shift each position to the right of this left by pos
            }
            k--; //go back 1 step
          }
        }
      }
    }
  }
  
  public void groupVars() { //group together variable names that are multiple characters long
    for(String match : Equation.varList) { //loop through all strings in the list of variable names (big to small)
      for(int k=0;k<=size()-match.length();k++) { //loop through all the strings (exclude parts at the end where this string doesn't fit)
        boolean matches = matchFound(k, match); //see if this string is a match
        
        if(matches) { //if it WAS a match
          groupStringOfSize(k,match.length()); //group together strings over that range into one string
        }
      }
    }
  }
  
  public void groupDates() { //group together dates
    for(String m : Month.matchers) { //loop through all the month strings
      for(int i=0;i<size()-m.length();i++) { //loop through all indices which could possibly contain that month
        if(matchFound(i,m)) { //if this string was found at this position, we now have to look to see if there's a number after it
          int len = m.length(); //record the current length of the string we're grouping together
          String after = get(i+m.length()); if(after.length()==1 && after.charAt(0)>='0' && after.charAt(0)<='9') { len++; } else { continue; } //make sure the next thing is a number. If not, we ignore this
          int ind = i+m.length()+1; //grab the index after that
          if(ind<size()) { //if there's even more after that:
            after = get(ind); if(after.length()==1 && after.charAt(0)>='0' && after.charAt(0)<='9') { len++; ind++; } //see if the next character is also a number. if so, add it to the list
            if(ind+2<size()) { if(get(ind).equals(",") && get(ind+1).equals(" ") && (get(ind+2).equals("-") || get(ind+2).length()==1 && get(ind+2).charAt(0)>='0' && get(ind+2).charAt(0)<='9')) { //next, see if the next 3 characters are comma, space, and a number
              ind+=3; len+=3; //increment the length & index by 3
              while(ind<size() && get(ind).length()==1 && get(ind).charAt(0)>='0' && get(ind).charAt(0)<='9') { ind++; len++; } //repeatedly increment until we run out of numerals or out of characters
            } }
          }
          groupStringOfSize(i,len); //group together the string forming our date
        }
      }
    }
  }
  
  boolean matchFound(int pos, String match) { //match found for match at pos
    boolean matches = true;             //whether or not this is a match (default to true)
    for(int n=0;n<match.length();n++) { //loop through all strings between
      if(!(match.charAt(n)+"").equals(list.get(n+pos))) { matches=false; break; } //if any of them don't match, matches is false, leave
    }
    return matches; //return whether they match
  }
  
  void groupStringOfSize(int pos, int siz) { //take a group of siz strings at position pos and group them together
    for(int n=1;n<siz;n++) {         //loop through all strings in that set
      concat(pos,list.get(pos+1)); //concat them onto the first string on the set
      list.remove(pos+1);          //remove each element after they're concatted
    }
  }
  
  ArrayList<Integer> leftParPosList() { //get a list of the positions of all left parentheses
    ArrayList<Integer> parPos = new ArrayList<Integer>(); //arraylist of the positions of each left parenthesis
    for(int n=0;n<size();n++) {
      if(list.get(n).equals("(")) { parPos.add(n); } //add each index containing a left parenthesis
    }
    return parPos; //return result
  }
  
  public void groupNums() { //group together numeric values
    boolean numb = false; //whether we're building a number
    boolean deci = false; //whether our number has a decimal point (yet)
    boolean expon = false; //whether our number has an exponential E (yet)
    
    for(int n=0;n<list.size();n++) {    //loop through all strings in the list
      if(list.get(n).length()==1) {   //if this string is 1 character long:
        char c = list.get(n).charAt(0); //cast to a char
        if (c >= '0' && c <= '9' || c == '.' || c == 'E') { //if the string is a numeral, decimal pont, or E
          if (numb && !(c == '.' && (deci || expon) || c == 'E' && expon)) { //case 1: we were already combining tokens into a number (and this makes a valid addition to said #)
            concat(n-1,c+"");                      //add this character to the number
            list.remove(n); --n;                   //remove this entry from the list, then go backwards 1
          }
          else {                    //case 2: we need to form a new number from these digits
            numb = true;          //we're now building a number
            deci = expon = false; //both deci & expon are initially false
            if (c == '.' || c == 'E') {
              list.set(n, '0' + list.get(n));
            } //if it's a . or E, put a 0 before it to properly start the number
          }
          //(programmer's note: if someone creates a number with 2 decimal points or E's or whatever, it'll be interpreted as 2 numbers adjacent to each other)
          
          deci  |= c == '.'; //deci is true if we've had at least one decimal point
          expon |= c == 'E';
        } else if ((c == '+' || c == '-') && numb && list.get(n-1).endsWith("E")) { //if this is a + or -, and the previous character was E:
          concat(n-1,c+"0");   //concatenate this symbol onto the number, followed by a 0 in case we stop at this point
          list.remove(n); --n; //remove this entry from the list & go backwards 1
        }
        else {                  //otherwise:
          if(numb && list.get(n-1).endsWith("E")) { //if the previous thing ended with E,
            concat(n-1,"0");                    //concatenate a 0 at the end to make it valid
          }
          numb = false;                           //we're no longer editing numbers
        }
      }
      else if(numb) { //if it's not 1 character long, but we were in number building mode
        if(list.get(n-1).endsWith("E")) { concat(n-1,"0"); } //if it ended with E, put a 0 at the end to make it valid
        numb = false;                                        //we're no longer in number building mode
      }
    }
  }
  
  public void removeSpaces() { //removes all tokens that are just whitespace
    for(int n=0;n<size();n++) {
      if(list.get(n).equals(" ") || list.get(n).equals("\t") || list.get(n).equals("\n")) { list.remove(n); n--; }
    }
  }
  
  public void groupPlusMinus() { //group together adjacent plus and minuses
    boolean plusMinus = false; //whether we're grouping them together now
    for(int n=0;n<size();n++) { //loop through all items
      if(list.get(n).equals("+") || list.get(n).equals("-")) { //if this item is + or -
        if(plusMinus) {     //if the previous was +/-
          list.set(n-1, (list.get(n-1).equals("+") ^ list.get(n).equals("+")) ? "-" : "+"); //set the previous to either + or -
          list.remove(n); //remove this entry
          n--;            //go backwards 1
        }
        plusMinus = true; //set plusMinus to true
      }
      else { plusMinus = false; } //otherwise, set plusMinus
    }
  }
  
  public void groupOps() { //group together operators when applicable (**=^, //=truncated division)
    boolean times=false, div=false, and=false, or=false, greater=false, less=false, not=false, equals=false, colon=false; //whether we're grouping *, /, &, |, >, <, !, =, :
    for(int n=0;n<size();n++) { //loop through all items
      if(list.get(n).equals("*")) { //if this item is *
        if(times) { //if the previous was also *
          list.set(n-1, "^"); //set the previous to a ^
          list.remove(n);     //remove this entry
          n--;                //go backwards 1
        }
        times^=true; //invert times
      }
      else { times=false; } //otherwise, set times to false
      
      if(list.get(n).equals("/")) { //if this item is /
        if(div) { //if the previous was also /
          list.set(n-1, "//"); //set the previous to a //
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        div^=true; //invert div
      }
      else { div=false; } //otherwise, set div to false
      
      if(list.get(n).equals("&")) { //if this item is &
        if(and) { //if the previous was also &
          list.set(n-1, "&&"); //set the previous to an &&
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        and^=true; //invert and
      }
      else { and=false; } //otherwise, set and to false
      
      if(list.get(n).equals("|")) { //if this item is |
        if(or) { //if the previous was also |
          list.set(n-1, "||"); //set the previous to an ||
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        or^=true; //invert and
      }
      else { or=false; } //otherwise, set or to false
      
      if(list.get(n).equals("=")) { //if this item is =
        if(greater) { //if the previous was >:
          list.set(n-1, ">="); //set the previous to >=
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        else if(less) { //if the previous was <:
          list.set(n-1, "<="); //set the previous to <=
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        else if(not) { //if the previous was !:
          list.set(n-1, "!="); //set the previous to !=
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        else if(colon) { //if the previous was : :
          list.set(n-1, ":="); //set the previous to :=
          list.remove(n);      //remove this entry
          n--;                 //go backwards 1
        }
        else if(equals) { //if the previous was =:
          list.set(n-1,"=="); //set the previous to ==
          list.remove(n);     //remove this entry
          n--;                //go backwards 1
        }
        equals^=true;
      }
      else { equals=false; } //otherwise, set equals to false
      
      greater = list.get(n).equals(">"); //set greater to true iff this is >
      less    = list.get(n).equals("<"); //set less to true iff this is <
      not     = list.get(n).equals("!"); //set not to true iff this is !
      colon   = list.get(n).equals(":"); //set colon to true iff this is :
    }
  }
  
  public void format() { //formats the parselist appropriately
    groupFuncs();     //group together functions
    groupVars();      //group together multi-character variables
    groupDates();     //group together all dates
    groupNums();      //group together numerals
    groupOps ();      //group together combinable operators
    removeSpaces();   //remove all unecessary whitespace
    groupPlusMinus(); //clump together plus and minuses
  }
}
