class CalcHistory { //class for storing the history of questions & answers
  Textbox[] questions; //carousel array of all the questions that have been asked (newest to oldest)
  Textbox[] answers; //carousel array of all the answers that have been answered
  MathObj[] answerExact; //carousel array of all the answers, but stored as explicit numbers/math objects
  int carousel = 0; //the carousel index: the index at which question 0 (the newest question) is stored
  int entries;      //the number of entries (usually fixed, but can sometimes be changed)
  float boxHeight, textSize; //the height of the boxes, the size of the text
  
  Panel holder; //the panel that holds the history display
  
  
  HashMap<String, MathObj> varStore = new HashMap<String, MathObj>(); //list of all variables with a stored value
  //TODO think about if this even belongs here?
  
  CalcHistory(final Panel parent, int ent, int ind, float x, float y, float w, float h, float tboxH, float tSize) { //constructs history, given parent panel, # of entries, carousel index, x,y,width,height, textbox height, and text size
    entries = ent; carousel = ind;    //set the # of entries & the carousel index
    if(entries==-1 || carousel==-1) { //if # of entries or base index isn't specified:
      loadBaseSettingsFromDisk(this, sketchPath("")+dirChar+"saves"+dirChar+"History"); //load it from the file
    }
    
    questions = new Textbox[entries]; answers = new Textbox[entries]; answerExact = new MathObj[entries]; //initialize all 3 arrays
    boxHeight = tboxH; textSize = tSize; //set the height for each textbox, the size of the text
    
    holder = new Panel(x,y,w,h,w,2*tboxH*entries); //create holder panel
    holder.setSurfaceFill(0).setStroke(#00FFFF).setParent(parent); //set fill, stroke, and parent
    holder.setScrollY(holder.h-holder.surfaceH); holder.setDragMode(DragMode.NONE,DragMode.ANDROID); //scroll all the way to the bottom, and make it draggable in the vertical direction
    
    for(int n=0;n<entries;n++) { //loop through all entries
      final Textbox question = buildTextbox( 2*(entries-n-1)   *tboxH,  true); //create each question textbox
      final Textbox   answer = buildTextbox((2*(entries-n-1)+1)*tboxH, false); //create each   answer textbox
      
      question.hMode = answer.hMode = Textbox.HighlightMode.NONE; //prevent the question & answer textboxes from having highlight functionality
      
      setQuestion(n,question); //set the question
      setAnswer(n,answer);     //the answer
      answerExact[n] = new MathObj(); //and the exact answer (this one doesn't care about order)
    }
  }
  
  
  //////////////// GETTERS / SETTERS //////////////////////////////////
  
  Textbox getQuestion(int ind) { //grabs specific question (index 0 means the newest one, indices are cyclical; they loop around)
    return questions[Math.floorMod(ind+carousel, entries)]; //add carousel index, modulo with the # of entries
  }
  Textbox getAnswer(int ind) { //grabs specific answer (index 0 means the newest one)
    return answers[Math.floorMod(ind+carousel, entries)]; //do the same thing
  }
  MathObj getAnswerExact(int ind) { //grabs specific explicitly stored answer
    return answerExact[Math.floorMod(ind+carousel, entries)]; //do the same thing
  }
  
  MathObj getNewestAnswer() { //returns the newest (most recent) answer
    return answerExact[carousel]; //go to the carousel index, return the answer there
  }
  
  private void setQuestion(int ind, Textbox box) { //sets the question box
    questions[Math.floorMod(ind+carousel, entries)] = box;
  }
  
  private void setAnswer(int ind, Textbox box) { //sets the answer box
    answers[Math.floorMod(ind+carousel, entries)] = box;
  }
  
  void setAnswerExact(int ind, MathObj ans) { //sets explicitly stored answer at specific index
    answerExact[Math.floorMod(ind+carousel, entries)] = ans; //go to adjusted index, set element
  }
  
  void setVisible(boolean vis) { holder.setActive(vis); } //set whether the history is visible
  
  //////////////////// BASIC MANIPULATION //////////////////////////////
  
  void addEntry(String quest, String ans, MathObj ans2, boolean save) { //updates the history by adding a new question/answer to the list (thus removing the oldest question/answer)
    int newCarousel = Math.floorMod(carousel-1, entries); //compute what the new carousel index will be
    
    //first, we move all the questions/answers up 2 slots, except the oldest which get put right at the bottom
    float questY = getQuestion(0).y, ansY = getAnswer(0).y; //store the positions of the newest question & answer
    for(int ind = 0; ind != entries-1; ind++) {  //loop through all questions/answers EXCEPT the oldest one
      getQuestion(ind).y = getQuestion(ind+1).y; //move each question to the position of the next highest question
      getAnswer  (ind).y = getAnswer  (ind+1).y; //move each answer   to the position of the next highest answer
    }
    getQuestion(-1).y = questY; //set the position of the oldest question to that of the newest question
    getAnswer  (-1).y =   ansY; //set the position of the oldest   answer to that of the newest   answer
    
    carousel = newCarousel; //now, we set the new carousel index
    
    Textbox ansField = getAnswer(0); //grab the answer field
    ansField.setTextX(Mmio.xBuff);   //correctly align the answer field so it knows what width to be
    getQuestion(0).replace(quest);    //put the question into the now most recent question
    setAnswerContents(ansField, ans); //put the answer into the now most recent answer
    setAnswerExact(0, ans2);          //set the most recent exact answer
    
    if(save) {
      saveUpdateToDisk("saves"+dirChar+"History"); //finally, save this update to the disk
    }
    
    //below is some stuff that's probably more efficient at the cost of being a little less readable
    /*float questY = questions[carousel].y, ansY = answers[carousel].y; //store the positions of the newest question & answer
    for(int ind = carousel; ind != newCarousel; ind++) { //loop through all questions/answers EXCEPT the oldest ones
      if(ind != entries-1) { //assuming we're not about to loop around:
        questions[ind].y = questions[ind+1].y; //move each question to the position of the next oldest question
        answers  [ind].y = answers  [ind+1].y; //move each answer   to the position of the next oldest answer
      }
      else { //otherwise:
        questions[ind].y = questions[0].y; //do the same thing, but now the next oldest is #0
        answers  [ind].y = answers  [0].y;
        ind = -1; //set the index to -1 so it'll loop back around to index 0
      }
    }
    questions[newCarousel].y = questY; //last, set the position of the oldest question
    answers  [newCarousel].y = ansY;   //and the oldest answer, to that of the newest
    
    questions[newCarousel].readInput(new InputCode(new int[] {'C','I',0}, new String[] {quest})); //put the question into the most recent question
    answers  [newCarousel].readInput(new InputCode(new int[] {'C','I',0}, new String[] {  ans})); //put the answer into the most recent answer
    answerExact[newCarousel] = ans2; //set the most recent exact answer
    
    carousel = newCarousel; //lastly, we set the new carousel index*/
  }
  
  void clearEverything(boolean save) {
    for(int n=0;n<entries;n++) {
      questions[n].clear(false,false,false); //clear every question
      answers  [n].clear(false,false,false); //clear every answer
      answerExact[n] = new MathObj();        //clear every explicit answer
    }
    
    if(save) { saveToDisk("saves"+dirChar+"History"); } //save the fact that history was cleared
  }
  
  void changeHistoryDepth(int size, boolean save) {
    if(size==entries) { return; } //if this doesn't change the size, do nothing
    
    holder.surfaceH = 2*boxHeight*size; //change the surface height
    
    Textbox[] questions2 = new Textbox[size], //create new question array of the correct size
                answers2 = new Textbox[size]; //and new answer array
    MathObj[] answerExact2 = new MathObj[size]; //and new exact answer array
    
    for(int n=0;n<size && n<entries;n++) { //loop through all entries that can be copied and exist
      questions2[n] = getQuestion(n); //shallow copy over each question
      answers2  [n] = getAnswer  (n); //and each answer
      answerExact2[n] = getAnswerExact(n); //and each exact answer
      
      questions2[n].y = (2*size-2*n-2)*boxHeight; //change the y position of each question
      answers2  [n].y = (2*size-2*n-1)*boxHeight; //change the y position of each answer
    }
    for(int n=entries; n<size; n++) { //loop through all the entries that weren't created (assuming size>entries, otherwise the loop isn't even entered)
      questions2[n] = buildTextbox( 2*(size-n-1)   *boxHeight,  true); //set this question
      answers2  [n] = buildTextbox((2*(size-n-1)+1)*boxHeight, false); //set this answer
      answerExact2[n] = new MathObj();                                 //set this exact answer
    }
    for(int n=size; n<entries; n++) { //loop through all the entries that we have to delete (assuming entries>size, otherwise the loop isn't even entered)
      getQuestion(n).setParent(null); //make each question estrange
      getAnswer  (n).setParent(null); //make each answer estrange
      
      if(save) { //if we plan on saving these changes, we have to delete all unneeded files
        new File(sketchPath()+dirChar+"saves"+dirChar+"History"+dirChar+"question "+n+".txt").delete(); //delete each unneeded question
        new File(sketchPath()+dirChar+"saves"+dirChar+"History"+dirChar+"answer "+n+".txt").delete(); //delete each unneeded answer
        new File(sketchPath()+dirChar+"saves"+dirChar+"History"+dirChar+"answer exact "+n+".txt").delete(); //delete each unneeded exact answer
      }
    }
    
    questions = questions2; //replace the question array
    answers   = answers2;   //replace the answer array
    answerExact = answerExact2; //replace the exact answer array
    carousel = 0; entries = size; //change the # of entries to the specified size, and the carousel index to 0
    
    if(save) { saveToDisk("saves"+dirChar+"History"); } //if we want to save this, we have to save this
  }
  
  //////////////////////// SAVING / LOADING ////////////////////////////
  
  void saveToDisk(String path) { //saves the entire history to the disk
    for(int n=0;n<entries;n++) {
      saveQuestionToDisk   (n,  questions[n], path);
      saveAnswerToDisk     (n,    answers[n], path);
      saveAnswerExactToDisk(n,answerExact[n], path);
    }
    saveBaseSettingsToDisk(this, path);
  }
  
  void loadFromDisk(String path) { //loads the entire history from disk
    for(int n=0;n<entries;n++) {
      loadQuestionFromDisk(n, questions[n], path);
      loadAnswerFromDisk  (n,   answers[n], path);
      answerExact[n] = loadAnswerExactFromDisk(n, path);
      //println("Entry "+n+" loaded"); //DEBUG
    }
  }
  
  void saveUpdateToDisk(String path) { //given that the history was just updated by 1 entry, it saves the update to disk by replacing the oldest entry w/ the newest one & incrementing the carousel index
    saveQuestionToDisk   (carousel,   questions[carousel], path);
    saveAnswerToDisk     (carousel,     answers[carousel], path);
    saveAnswerExactToDisk(carousel, answerExact[carousel], path);
    
    saveBaseSettingsToDisk(this, path);
  }
  
  //////////////////////////// UTILITY FUNCTIONS ///////////////////////
  
  Textbox buildTextbox(float y, boolean question) { //builds & returns the question/answer textbox that would go at this height
    final Textbox textbox = new Textbox(0,y,holder.w,boxHeight); //create each question textbox
    textbox.setTextColor(#00FFFF).setTextSizeAndAdjust(textSize).setSurfaceFill(#000000).setStroke(#00FFFF); //set the drawing parameters,
    textbox.setScrollable(true,false).setDragMode(DragMode.ANDROID,DragMode.NONE); //the scrolling mode
    textbox.setParent(holder); //the parent panel
    
    final Mmio io = textbox.mmio;
    
    if(question) { //here's the action that gets performed if it's a question:
      textbox.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
        String text = textbox.getText(); //grab the text from the textbox
        if(!text.equals("")) { //if it's not empty:
          io.typer.eraseSelection(true); //erase selection (if applicable)
          io.typer.insert(text);         //insert text
        }
      } } });
    }
    else { //here's the action if it's an answer (almost exactly the same)
      textbox.setOnRelease(new Action() { public void act() { if(io.typer!=null) {
        String text = textbox.getText(); //grab the text from the textbox
        if(!text.equals("")) { //if it's not empty:
          io.typer.eraseSelection(true); //erase selection (if applicable)
          io.typer.insert("("+text+")"); //insert text (making sure to wrap it in quotes)
        }
      } } });
    }
    
    return textbox; //return result
  }
}

void setAnswerContents(Textbox answer, String contents) {
  answer.setTextX(Mmio.xBuff); //correctly align the answer field so it knows what width to be
  answer.replace(contents); //replace current contents w/ the new contents
  
  if(answer.w == answer.surfaceW) { //if the answer field isn't too wide to be displayed:
    float shift = answer.getX(answer.size()) - answer.tx; //compute the position of the far right of the text
    answer.setTextX(answer.w-shift-answer.tx);            //shift over its text so that it's right aligned
  }
}
