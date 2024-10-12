public static class CMatrix { //Complex Matrix
  
  //////////////// ATTRIBUTES ///////////////////
  int h, w;             //the dimensions
  Complex[][] elements; //an array of all elements
  //NOTE: Dimensions are important. Especially w, as it allows us to know the width of the matrix, even if the height is 0
  
  /////////////// CONSTRUCTORS ////////////////////
  
  CMatrix() { h=w=0; elements = new Complex[0][0]; } //creates 0x0 matrix
  
  CMatrix(int h_, int w_, Complex... c) { //creates matrix given dimensions and complex elements
    if(h_<0||w_<0)      { throw new NegativeArraySizeException("Cannot instantiate "+h_+"x"+w_+" matrix");                  } //negative size: throw exception
    if(c.length!=h_*w_) { throw new RuntimeException("Cannot instantiate "+h_+"x"+w_+" matrix with "+c.length+" elements"); } //wrong number of elements: throw exception
    h=h_; w=w_; elements = new Complex[h][w];   //set dimensions & initialize element array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      if(c[i*w+j]==null) { throw new NullPointerException("Matrix cannot have null elements"); } //if any elements are null, throw exception
      elements[i][j] = c[i*w+j]; //set each element
    }
  }
  
  CMatrix(int h_, int w_, double... d) { //creates matrix given dimensions and real elements
    if(h_<0||w_<0)      { throw new NegativeArraySizeException("Cannot instantiate "+h_+"x"+w_+" matrix");                  } //negative size: throw exception
    if(d.length!=h_*w_) { throw new RuntimeException("Cannot instantiate "+h_+"x"+w_+" matrix with "+d.length+" elements"); } //wrong number of elements: throw exception
    h=h_; w=w_; elements = new Complex[h][w];   //set dimensions & initialize element array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j] = new Complex(d[i*w+j]);   //set each element
    }
  }
  
  CMatrix(int h_, int w_) { //creates hxw zero matrix
    h=h_; w=w_; elements = new Complex[h][w]; //set dimensions & init element array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { elements[i][j] = Cpx.zero(); } //set each element to 0
  }
  
  CMatrix(CVector... v) { //loads matrix from array of rows
    if(v.length==0) { throw new MatrixSizeException("Ambiguous Dimensions: Cannot determine width of 0x??? matrix"); }
    h=v.length; w=v[0].size();    //set dimensions
    elements = new Complex[h][w]; //load array
    for(int i=0;i<h;i++) { //loop through all rows
      if(v[i]==null)     { throw new NullPointerException("Matrix cannot have null rows"); }
      if(v[i].size()!=w) { throw new MatrixSizeException("Cannot create jagged matrix"); }
      for(int j=0;j<w;j++) {                 //loop through all columns
        elements[i][j] = v[i].get(j).copy(); //set each element (deep copying)
      }
    }
  }
  
  private CMatrix(int h_, int w_, Complex[][] c) {
    h=h_; w=w_; elements = c; //set dimensions and elements
  }
  
  //////////////// INHERITED METHODS ///////////////////////
  
  @Override
  public boolean equals(final Object obj) {
    if(!(obj instanceof CMatrix)) { return false; } //only matrices can equal
    CMatrix comp = (CMatrix)obj;                    //cast to CMatrix
    if(comp.h!=h || comp.w!=w) { return false; }    //if dimensions don't match, they're not equal
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {     //loop through all elements
      if(!elements[i][j].equals(comp.elements[i][j])) { return false; } //if any don't equal, return false
    }
    return true; //if all conditions have been met, both matrices are equal
  }
  
  @Override
  public int hashCode() { //an equals method demands a consistent hashcode method
    int hash = w^h; //init to width XOR height
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {
      hash = 31*hash+elements[i][j].hashCode(); //repeatedly mult by 31 & add each element's hashcode
    }
    return hash; //return result
  }
  
  @Override
  public CMatrix clone() { //form deep copy of matrix
    Complex[][] inst = new Complex[h][w];       //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].clone();      //clone each element
    }
    return new CMatrix(h, w, inst); //create and return new cloned matrix
  }
  
  public String toString(int dig) { //cast to a string given a specified number of digits of precision
    double threshold = 0; //how small something has to be to be rounded down to 0
    if(Complex.omit_Option) { //if we omit small parts, the threshold is non-zero
      double biggest = biggest(); //find the biggest element
      threshold = Math.min(1e-11d*biggest, 1e-12d); //set our threshold to either 10^-12, or 10^-11*biggest element
    }
    
    StringBuilder res = new StringBuilder("["); //initialize to opening left bracket
    for(int i=0;i<h;i++) {   //loop through all rows
      res.append("[");       //start each row with left bracket
      for(int j=0;j<w;j++) { //loop through all columns
        if(elements[i][j].lazyabs()<threshold) { res.append("0"); } //if this element is below our threshold, round down to 0
        else { res.append(elements[i][j].toString(dig)); } //concatenate each individual element, outputted to the given amount of precision
        if(j!=w-1) { res.append(","); }                    //put a comma after all entries but the last
      }
      res.append("]");                //end each row with a right bracket
      if(i!=h-1) { res.append(","); } //put a comma after all rows but the last
    }
    return res.append("]").toString(); //close with right bracket, return result
  }
  
  @Override
  public String toString() { return toString(-1); } //default toString: output result to maximum precision
  
  ////////////////// GETTERS/SETTERS /////////////////////////
  
  Complex get(int i, int j) { return elements[i-1][j-1]; }
  int width () { return w; }
  int height() { return h; }
  String getDimensions() { return h+"x"+w; }
  
  CVector getRow(int i) {
    Complex[] c = new Complex[w]; //load array
    for(int j=0;j<w;j++) { c[j] = elements[i][j]; } //set each element
    return new CVector(c); //return result
  }
  
  void set(int i, int j, Complex c) {
    if(c==null) { throw new RuntimeException("Cannot give matrix null elements"); }
    elements[i-1][j-1] = c;
  }
  
  ///////////////// OBSCURE YET REALLY USEFUL FUNCTIONS ////////////////////
  
  double biggest() { //largest lazy absolute value of all elements
    double max = 0; //init to 0
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      max = Math.max(max, b.lazyabs());              //find the maximum lazy abs
    }
    return max; //return result
  }
  
  double ulpMax() {
    double ulp = Double.MIN_VALUE;
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {
      ulp = Double.max(ulp, elements[i][j].ulpMax());
    }
    return ulp;
  }
  
  double ulpMin() {
    double ulp = Double.MIN_VALUE;
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {
      ulp = Double.min(ulp, elements[i][j].ulpMin());
    }
    return ulp;
  }
  
  ///////////////// REALLY BASIC FUNCTIONS ////////////////////
  
  boolean isSquare() { return w==h; }
  boolean isColumn() { return w==1; }
  boolean isRow   () { return h==1; }
  boolean sameDims(CMatrix m) { return w==m.w && h==m.h; }
  
  boolean isReal() {
    for(Complex[] a : elements) for(Complex b : a) { if(b.im!=0) { return false; } } //if even one element isn't real, return false
    return true; //otherwise, return true
  }
  boolean isInf() {
    for(Complex[] a : elements) for(Complex b : a) { if(b.isInf()) { return true; } } //if even one element is infinite, return true
    return false; //otherwise, return false
  }
  boolean isNaN() {
    for(Complex[] a : elements) for(Complex b : a) { if(b.isNaN()) { return true; } } //if even one element is NaN, return true
    return false; //otherwise, return false
  }
  
  static CMatrix zero(int h_, int w_) { return new CMatrix(h_, w_); }
  static CMatrix identity(int dim) {
    Complex[][] inst = new Complex[dim][dim]; //instantiate square matrix
    for(int i=0;i<dim;i++) for(int j=0;j<dim;j++) { //loop through all elements
      inst[i][j] = i==j ? Cpx.one() : Cpx.zero();   //set them to 1 if diagonal, 0 otherwise
    }
    return new CMatrix(dim,dim,inst); //create identity matrix & return result
  }
  
  ///////////////// BASIC FUNCTIONS ///////////////////////
  
  CMatrix transpose() { //returns the transpose
    Complex[][] inst = new Complex[w][h]; //load transpose array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[j][i] = elements[i][j].copy();       //set each element (while swapping indices)
    }
    return new CMatrix(w,h,inst); //create and return new transposed matrix
  }
  
  CMatrix negeq() { //negate-equals
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.negeq(); //negate each element
    }
    return this; //return result
  }
  CMatrix neg() { //returns the matrix negated
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].neg();        //negate each element
    }
    return new CMatrix(h,w,inst); //create and return new negated matrix
  }
  
  CMatrix muleqI() { //multiply-equals by i
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.muleqI(); //multiply each element by i
    }
    return this; //return result
  }
  CMatrix mulI() { //returns the matrix multiplied by i
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mulI();       //multiply each element by i
    }
    return new CMatrix(h,w,inst); //create and return matrix multiplied by i
  }
  
  CMatrix diveqI() { //divide-equals by i
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.diveqI(); //divide each element by i
    }
    return this; //return result
  }
  CMatrix divI() { //returns the matrix divided by i
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].divI();       //divide each element by i
    }
    return new CMatrix(h,w,inst); //create and return matrix divided by i
  }
  
  CMatrix conjeq() { //complex-conjugate-equals
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      b.conjeq(); //conjugate each element
    }
    return this; //return result
  }
  CMatrix conj() { //returns the complex conjugate
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].conj(); //conjugate each element
    }
    return new CMatrix(h, w, inst); //create and return new conjugated matrix
  }
  
  CMatrix re() { //returns the real part of the matrix
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = new Complex(elements[i][j].re); //take the real part of each element
    }
    return new CMatrix(h, w, inst); //create and return new real-ed matrix
  }
  
  CMatrix im() { //returns the imaginary part of the matrix
    Complex[][] inst = new Complex[h][w]; //instantiate new array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = new Complex(elements[i][j].im); //take the imaginary part of each element
    }
    return new CMatrix(h, w, inst); //create and return new imaginari-ed matrix
  }
  
  CMatrix herm() { //returns the hermitian (conjugate transpose)
    Complex[][] inst = new Complex[w][h]; //load transpose array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[j][i] = elements[i][j].conj(); //conjugate each element (while swapping indices)
    }
    return new CMatrix(w, h, inst); //create and return new conjugate-transposed matrix
  }
  
  ////////////////////// ARITHMETIC ////////////////////////
  
  CMatrix addeq(final CMatrix m) { //add-equals two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot add "+getDimensions()+" + "+m.getDimensions()); } //if dimensions don't match, throw exception
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      elements[i][j].addeq(m.elements[i][j]); //add matching elements
    }
    return this; //return result
  }
  
  CMatrix subeq(final CMatrix m) { //subtract-equals two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot subtract "+getDimensions()+" - "+m.getDimensions()); } //if dimensions don't match, throw exception
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      elements[i][j].subeq(m.elements[i][j]); //subtract matching elements
    }
    return this; //return result
  }
  
  CMatrix muleq(final Complex c) { //multiply-equals matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot multiply matrix by null"); } //if null, throw exception
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j].muleq(c); //multiply each element by scalar
    }
    return this; //return result
  }
  CMatrix muleq(final double d) { //multiply-equals by real scalar
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j].muleq(d); //multiply each element by scalar
    }
    return this; //return result
  }
  CMatrix muleqI(final double d) { //multiply-equals by imaginary scalar
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      elements[i][j].muleqI(d); //multiply each element by scalar
    }
    return this; //return result
  }
  
  CMatrix diveq(final Complex c) { //divide-equals matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot divide matrix by null"); } //if null, throw exception
    return muleq(c.inv()); //multiply-equals by the reciprocal of c
  }
  CMatrix diveq(final double d) { //divide-equals matrix by real scalar
    return muleq(1d/d);           //multiply-equals by the reciprocal of d
  }
  CMatrix diveqI(final double d) { //divide-equals matrix by imaginary scalar
    return muleqI(-1d/d);          //multiply-equals by the reciprical of di
  }
  
  
  
  CMatrix add(final CMatrix m) { //add two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot add "+getDimensions()+" + "+m.getDimensions()); } //if dimensions don't match, throw exception
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = elements[i][j].add(m.elements[i][j]); //add matching elements
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  CMatrix sub(final CMatrix m) { //subtract two matrices
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot subtract "+getDimensions()+" - "+m.getDimensions()); } //if dimensions don't match, throw exception
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = elements[i][j].sub(m.elements[i][j]); //subtract matching elements
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  CMatrix mul(final Complex c) { //multiply matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot multiply matrix by null"); } //if null, throw exception
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mul(c); //multiply each element by scalar
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  CMatrix mul(final double d) { //multiply matrix by real scalar
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mul(d); //multiply each element by scalar
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  CMatrix mulI(final double d) { //multiply matrix by imaginary scalar
    Complex[][] inst = new Complex[h][w]; //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = elements[i][j].mulI(d); //multiply each element by imaginary scalar
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  CMatrix div(final Complex c) { //divide matrix by scalar
    if(c==null) { throw new IllegalArgumentException("Cannot divide matrix by null"); } //if null, throw exception
    return mul(c.inv()); //multiply by reciprocal of c
  }
  CMatrix div(final double d) { //divide matrix by real scalar
    return mul(1d/d); //multiply by reciprocal of d
  }
  CMatrix divI(final double d) { //divide matrix by imaginary scalar
    return mulI(-1d/d); //multiply by reciprocal of di
  }
  
  
  CMatrix mul(final CMatrix m) { //returns the product of two matrices
    if(w!=m.h) { throw new MatrixSizeException("Cannot multiply "+getDimensions()+" by "+m.getDimensions()); } //if width of first doesn't match height of second, throw exception
    Complex[][] inst = new Complex[h][m.w]; //instantiate array (dimensions are height of first x width of second)
    for(int i=0;i<h;i++) for(int j=0;j<m.w;j++) { //loop through all elements
      inst[i][j] = new Complex(); //initialize each element to 0
      for(int k=0;k<w;k++) {      //compute each element via a dot product of the first matrix's row w/ the second matrix's column
        inst[i][j].addeq( elements[i][k].mul(m.elements[k][j]) ); //add each element-wise product
      }
    }
    return new CMatrix(h,m.w,inst); //return resulting matrix
  }
  
  CVector mul(final CVector v) { //returns the matrix multiplied by a column vector
    if(w!=v.size()) { throw new MatrixSizeException("Cannot multiply "+getDimensions()+" matrix by vector of size "+v.size()); } //if the width doesn't match the dimension, throw exception
    Complex[] inst = new Complex[h]; //instantiate array (height = height)
    for(int i=0;i<h;i++) { //loop through all elements
      inst[i] = new Complex(); //initialize each element to 0
      for(int j=0;j<w;j++) {   //compute each element via a dot product of the matrix's row w/ this vector
        inst[i].addeq(elements[i][j].mul(v.elements[j])); //add each element-wise product
      }
    }
    return new CVector(inst); //create & return the resulting vector
  }
  
  CVector mulLeft(final CVector v) { //returns a row vector multiplied by this matrix
    if(h!=v.size()) { throw new MatrixSizeException("Cannot multiply vector of size "+v.size()+" by "+getDimensions()+" matrix"); } //if the height doesn't match the dimensions, throw exception
    Complex[] inst = new Complex[w]; //instantiate array (width = width)
    for(int j=0;j<w;j++) { //loop through all elements
      inst[j] = new Complex(); //initialize each element to 0
      for(int i=0;i<h;i++) {   //compute each element via a dot product of the vector with the matrix's column
        inst[j].addeq(elements[i][j].mul(v.elements[i])); //add each element-wise product
      }
    }
    return new CVector(inst); //create & return the resulting vector
  }
  
  CMatrix addeq(final Complex s) { //add-equals a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    for(int n=0;n<h;n++) { elements[n][n].addeq(s); } //add our scalar to each diagonal entry
    return this; //return result
  }
  
  CMatrix subeq(final Complex s) { //subtract-equals a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    for(int n=0;n<h;n++) { elements[n][n].subeq(s); } //subtract our scalar from each diagonal entry
    return this; //return result
  }
  
  CMatrix add(final Complex s) { //add a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    Complex[][] inst = new Complex[h][w];       //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = i==j ? elements[i][j].add(s) : elements[i][j].clone(); //set each element, being sure to add the scalar to diagonal entries
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  CMatrix sub(final Complex s) { //subtract a scalar times the identity
    if(h!=w) { throw new RuntimeException("Cannot add an identity to a non-square matrix"); } //if non-square, throw an exception
    Complex[][] inst = new Complex[h][w];       //instantiate array
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through each element
      inst[i][j] = i==j ? elements[i][j].sub(s) : elements[i][j].clone(); //set each element, being sure to subtract the scalar from diagonal entries
    }
    return new CMatrix(h,w,inst); //create and return resulting matrix
  }
  
  CMatrix addeq(final double s) { return addeq(new Complex(s)); }
  CMatrix subeq(final double s) { return subeq(new Complex(s)); }
  CMatrix add(final double s) { return add(new Complex(s)); }
  CMatrix sub(final double s) { return sub(new Complex(s)); }
  
  //////////////////// MATRIX FUNCTIONS /////////////////////////////////
  
  Complex trace() { //returns the trace
    if(h!=w) { throw new IllegalArgumentException("Cannot take trace of "+getDimensions()+" (must be square)"); } //if not square, throw exception
    Complex trace = new Complex();                        //initialize trace to 0
    for(int n=0;n<h;n++) { trace.addeq(elements[n][n]); } //add up each diagonal element
    return trace;                                         //return result
  }
  
  Complex determinant() { //returns the determinant
    if(h!=w) { throw new IllegalArgumentException("Cannot take determinant of "+getDimensions()+" (must be square)"); } //if not square, throw exception
    switch(h) { //switch the dimensions
      case 0: return Cpx.one();             //0x0: determinant is 1
      case 1: return elements[0][0].copy(); //1x1: determinant is the only element
      case 2: return elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])); //2x2: ad-bc
      case 3: return get(1,1).mul(get(2,2).mul(get(3,3)).subeq(get(2,3).mul(get(3,2)))) .addeq( //3x3: Rule of Saurus
                     get(1,2).mul(get(2,3).mul(get(3,1)).subeq(get(2,1).mul(get(3,3))))).addeq(
                     get(1,3).mul(get(2,1).mul(get(3,2)).subeq(get(2,2).mul(get(3,1)))));
      //default: throw new RuntimeException("Determinants have not yet been implemented for matrices of size "+getDimensions());
      default: { //4x4 and onward:
        CMatrix echelon = clone(); //clone the matrix
        Complex factor = echelon.rowEchelon(); //put in upper row echelon, record what the determinant multiplied by
        for(int n=0;n<h;n++) { if(echelon.elements[n][n].equals(0)) { return Cpx.one(); } } //if any of the diagonal elements are 0, the determinant is 0
        return factor; //otherwise, return the factor
      }
    }
  }
  
  Complex frobenius(final CMatrix m) { //takes the frobenius product (very similar to the dot product)
    if(h!=m.h || w!=m.w) { throw new MatrixSizeException("Cannot take Frobenius product between "+getDimensions()+" and "+m.getDimensions()); } //if different dimensions, throw exception
    Complex prod = new Complex(); //initialize product to 0
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      prod.addeq(elements[i][j].conj().mul(m.elements[i][j])); //add together each element-wise product (with this being conjugated, I guess)
    }
    return prod; //return result
  }
  
  double frobeniusSq() { //takes the square frobenius norm
    double prod = 0; //initialize product to 0
    for(Complex[] a : elements) for(Complex b : a) { //loop through all elements
      prod+=b.absq();                                //add together the absolute square of each element
    }
    return prod;
  }
  
  double frobenius() { //takes the frobenius norm
    return Math.sqrt(frobeniusSq());
  }
  
  //////////////////// MATRIX SOLVING ////////////////////////////////////
  
  private static class Fusion { int ind; boolean bool; Fusion(int a, boolean b) { ind=a; bool=b; } }
  
  private static boolean lazyCompare(Complex[] a, Complex[] b, int column) { //compares two rows, finds which one has the larger or earlier leading term, column is where to start. Returns true if the second is bigger, false otherwise
    for(int i=column;i<a.length;i++) { //loop through all elements
      if(!a[i].equals(0) || !b[i].equals(0)) { //if at least one element isn't 0:
        return b[i].lazyabs()>a[i].lazyabs();  //return true if b is larger, false otherwise
      }
    }
    return false; //if they're both full of 0s, return false (index is right after the end)
  }
  
  private static int leadingNonzeroIndex(Complex[] a, int column) { //locates the leading non-zero index (column is the smallest index it could be)
    for(int i=column;i<a.length;i++) { //loop through all elements
      if(!a[i].equals(0)) { return i; } //return the index of the first non-zero element
    }
    return a.length; //if none were found, return the element right after the end
  }
  
  private Fusion swapWithLargerRow(int row, int column) { //takes this row, looks for a row with a larger leading element. If found, it swaps the two rows (column is the first element to check) (returns the index of leading element & whether swap occurred)
    int bestRow = row;         //the index of the largest row
    for(int i=row+1;i<h;i++) { //loop through all rows after this one
      boolean comp = lazyCompare(elements[bestRow],elements[i],column); //compare this row with the current best row
      if(comp) { bestRow = i; }                                         //if this row is better, it's now the current best row
    }
    int ind = leadingNonzeroIndex(elements[bestRow], column); //find the location of the first non-zero
    if(bestRow==row) { //if the current row is the best row:
      return new Fusion(ind, false); //return the index as well as false (to indicate there was no swapping)
    }
    else { //otherwise:
      Complex[] temp = elements[row]; elements[row] = elements[bestRow]; elements[bestRow] = temp; //swap the two rows
      return new Fusion(ind, true); //return the index as well as true (to indicate there was swapping)
    }
  }
  
  private Complex rowEchelon() { //reduces matrix to upper row echelon, while also swapping rows for the sake of roundoff, dividing rows so their leading term is 1 for the sake of roundoff, and also returns the ratio between the determinant before & after this transformation
    int column = 0;             //the index of the first element on the current row that is not guaranteed to be 0
    Complex factor = Cpx.one(); //the number our determinant divided by by through all these transformations
    for(int row=0;row<h;row++) { //loop through all rows
      
      //first, make sure our row has the largest leading term
      Fusion fuse = swapWithLargerRow(row, column); //try to swap with the largest row
      column = fuse.ind;                            //update the value of column
      if(fuse.bool) { factor.negeq(); }             //if a swap occurred, negate the factor
      if(column==w) { return factor; }              //if the column is out of bounds, the rest of the rows are all 0s and there's nothing left to do
      
      //next, divide this row by the leading term
      factor.muleq(elements[row][column]); //multiply our factor by the leading term (since that's what this row is going to divide by)
      Complex inv = column==w-1 ? new Complex() : elements[row][column].inv(); //compute the reciprocal of the leading term (unless we're at the end, then we don't need to)
      elements[row][column] = Cpx.one(); //now, we multiply each element in this row by this inverse. Except the leading term, we can just set that to 1
      for(int j=column+1;j<w;j++) {     //loop through all elements to the right of the leading one
        elements[row][j].muleq(inv);   //multiply them all by that inverse
      }
      
      //then, we subtract a multiple of this row from each row after it, causing their leading term to be 0
      for(int i=row+1;i<h;i++) {
        Complex lead = elements[i][column]; //record the leading term
        elements[i][column] = Cpx.zero();   //now, we subtract the row-th row times lead from this row, element by element. This one can be shortcutted, however, since we can just set it to 0
        for(int j=column+1;j<w;j++) {       //loop through all elements to the right of the leading one
          elements[i][j].subeq(elements[row][j].mul(lead)); //subtract the corresponding element from row row, multiplied by the leading term
        }
      }
      
      //finally, just increment the column number
      column++; //we can do this, because we know the column-th element of all rows after row is 0, and now row is incrementing
    }
    
    return factor; //lastly, we just return the factor
  }
  
  void reduceRowEchelon() { //takes row echelon matrix and converts to reduced row echelon (backsolving)
    for(int row=h-1;row>=0;row--) { //loop through all rows backwards
      int column = leadingNonzeroIndex(elements[row], row); //find the first non-zero index
      if(column==w) { continue; }                       //if out of bounds, go to the next iteration (on the previous row)
      if(!elements[row][column].equals(1)) { throw new RuntimeException("Why the fuck is the leading term "+elements[row][column]+"?"); } //TEST
      for(int i=0;i<row;i++) {              //loop through all rows before this one
        Complex lead = elements[i][column]; //grab the element on this row, above the leading term of row row
        elements[i][column] = Cpx.zero();   //now, we subtract row row * lead from this row. We can partially shortcut by just setting this term to 0, then doing that to the rest of them
        for(int j=column+1;j<w;j++) {       //loop through all columns after that one
          elements[i][j].subeq(elements[row][j].mul(lead)); //subtract the same element from row row, but scaled by lead
        }
      }
    }
  }
  
  CMatrix augment(CMatrix m) { //returns the result of augmenting this matrix with another
    if(h!=m.h) { throw new MatrixSizeException("Cannot augment "+getDimensions()+" with "+m.getDimensions()); }
    Complex[][] aug = new Complex[h][w+m.w]; //instantiate new augmented matrix
    for(int i=0;i<h;i++) { //loop through all rows
      for(int j=0;j<w;j++) { aug[i][j] = elements[i][j].clone(); } //copy over these elements
      for(int j=0;j<m.w;j++) { aug[i][j+w] = m.elements[i][j].clone(); } //copy over the elements from the other matrix
    }
    return new CMatrix(h,w+m.w,aug); //construct and return the new augmented matrix
  }
  
  CMatrix augment(CVector v) { //returns the result of augmenting this matrix with a vector
    if(h!=v.size()) { throw new MatrixSizeException("Cannot augment "+getDimensions()+" with vector of size "+v.size()); }
    Complex[][] aug = new Complex[h][w+1]; //instantiate new augmented matrix
    for(int i=0;i<h;i++) { //loop through all rows
      for(int j=0;j<w;j++) { aug[i][j] = elements[i][j].clone(); } //copy over these elements
      aug[i][w] = v.elements[i].clone(); //copy over the elements from the vector
    }
    return new CMatrix(h,w+1,aug); //construct & return the new augmented matrix
  }
  
  CMatrix leftDivide(CMatrix m) { //computes this^-1 * m
    if(h!=w) { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(w!=m.h) { throw new MatrixSizeException("Cannot perform "+getDimensions()+" \\ "+m.getDimensions()); } //if dimensions don't match, throw exception
    
    if(h==0) { return new CMatrix(0,m.w); } //0x0 matrix: return 0x(m.w) matrix
    if(h==1) { return m.div(elements[0][0]); } //1x1 matrix: return m / the only element
    if(h==2) { //2x2 matrix: Cramer's rule
      Complex[][] inst = new Complex[2][m.w];       //instantiate array of complex numbers
      Complex factor = elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])).inv(); //compute 1 / the determinant
      for(int j=0;j<m.w;j++) { //loop through all columns
        inst[0][j] = elements[1][1].mul(m.elements[0][j]).subeq(elements[0][1].mul(m.elements[1][j])).muleq(factor); //compute one element
        inst[1][j] = elements[0][0].mul(m.elements[1][j]).subeq(elements[1][0].mul(m.elements[0][j])).muleq(factor); //compute the other element
      }
      return new CMatrix(2,m.w,inst); //construct & return the resulting matrix
    }
    //otherwise, we have to solve by Gaussian elimination
    
    CMatrix aug = augment(m); //first, augment this with the matrix m
    aug.rowEchelon();         //convert into upper row echelon
    if(aug.elements[h-1][h-1].equals(0)) { //if at least one diagonal element is 0:
      //The matrix is uninvertible. Now we just have to figure out if there are 0 solutions or infinite solutions
      for(int i=h-1;i>=0;i--) { //loop through all rows backwards, stop when we reach one with a non-zero diagonal
        if(!aug.elements[i][i].equals(0)) { throw new RuntimeException("Cannot invert matrix: Infinite Solutions"); } //if all the degenerate rows were filled with 0s, we have infinite solutions
        for(int j=i+1;j<w;j++) { if(!aug.elements[i][j].equals(0)) { throw new RuntimeException("Cannot invert matrix: No Solutions"); } } //otherwise, if at least one element in a degenerate row contains a non-zero, there are no solutions
      }
    }
    aug.reduceRowEchelon(); //otherwise, reduce the row echelon
    
    Complex[][] inst = new Complex[h][m.w]; //instantiate new array for the resulting matrix
    for(int i=0;i<h;i++) for(int j=0;j<m.w;j++) { //loop through all elements
      inst[i][j] = aug.elements[i][j+w];          //set each element (cutting out the part augmented to the left)
    }
    return new CMatrix(h,m.w,inst); //construct resulting matrix & return result
  }
  
  CMatrix rightDivide(CMatrix m) { //computes this * m^-1
    if(m.h!=m.w) { throw new MatrixSizeException("Cannot invert "+m.getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(w!=m.h) { throw new MatrixSizeException("Cannot perform "+getDimensions()+" / "+m.getDimensions()); } //if dimensions don't match, throw exception
    if(w==0) { return new CMatrix(0,w); } //special case: 0x0 matrix, return 0xw matrix
    
    return m.transpose().leftDivide(transpose()).transpose(); //now, just transpose them both, perform left division, and transpose back
  }
  //TODO TEST
  
  CMatrix inv() { //computes the inverse
    if(h!=w) { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    
    if(h==0) { return new CMatrix(0,0); } //0x0 matrix: return 0x0 matrix
    if(h==1) { if(elements[0][0].equals(0)) { throw new RuntimeException("Matrix is uninvertible"); } return new CMatrix(1,1,elements[0][0].inv()); } //1x1 matrix: return 1 / the only element
    if(h==2) { //2x2 matrix: Cramer's rule
      Complex factor = elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])).inv(); //compute 1 / the determinant
      if(factor.isInf() || factor.isNaN()) { throw new RuntimeException("Matrix is uninvertible"); }       //if overflow: throw exception
      return new CMatrix(2,2, new Complex[][] {{elements[1][1].copy(),elements[0][1].neg()}, {elements[1][0].neg(), elements[0][0].copy()}}).muleq(factor); //return the adjugate over the determinant
    }
    //otherwise, we have to solve by Gaussian elimination
    
    CMatrix aug = augment(CMatrix.identity(h)); //augment with an identity matrix
    aug.rowEchelon();                           //convert into upper row echelon
    if(aug.elements[h-1][h-1].equals(0)) { //if at least one diagonal element is 0:
      throw new RuntimeException("Matrix is uninvertible"); //throw exception
    }
    aug.reduceRowEchelon(); //otherwise, reduce the row echelon
    
    Complex[][] inst = new Complex[h][w]; //instantiate new array for the resulting matrix
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { //loop through all elements
      inst[i][j] = aug.elements[i][j+w];        //set each element (cutting out the part augmented to the left)
    }
    CMatrix inv = new CMatrix(h,w,inst); //construct the resulting matrix
    
    CMatrix adjust = inv.mul(this).mul(inv); //compute a Newton-Raphson adjustment
    inv.muleq(2).subeq(adjust);              //perform the adjustment
    return inv;                              //return result
    
    //return new CMatrix(h,w,inst); //construct resulting matrix & return result
  }
  
  CVector leftDivide(CVector v) { //computes this^-1 * v
    if(h!=w)        { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(w!=v.size()) { throw new MatrixSizeException("Cannot perform "+getDimensions()+" \\ vector of size "+v.size()); } //if dimensions don't match, throw exception
    
    if(h==0) { return new CVector(); } //0x0 matrix: return 0D vector
    if(h==1) { return v.div(elements[0][0]); } //1x1 matrix: return v / the only element
    if(h==2) { //2x2 matrix: Cramer's rule
      Complex factor = elements[0][0].mul(elements[1][1]).subeq(elements[0][1].mul(elements[1][0])).inv(); //compute 1 / the determinant
      Complex x = elements[1][1].mul(v.elements[0]).subeq(elements[0][1].mul(v.elements[1])).muleq(factor); //compute x
      Complex y = elements[0][0].mul(v.elements[1]).subeq(elements[1][0].mul(v.elements[0])).muleq(factor); //compute y
      return new CVector(x,y); //construct & return the resulting matrix
    }
    //otherwise, we have to solve by Gaussian elimination
    
    CMatrix aug = augment(v); //first, augment this with the matrix m
    aug.rowEchelon();         //convert into upper row echelon
    if(aug.elements[h-1][h-1].equals(0)) { //if at least one diagonal element is 0:
      //The matrix is uninvertible. Now we just have to figure out if there are 0 solutions or infinite solutions
      for(int i=h-1;i>=0;i--) { //loop through all rows backwards, stop when we reach one with a non-zero diagonal
        if(!aug.elements[i][i].equals(0)) { throw new RuntimeException("Cannot invert matrix: Infinite Solutions"); } //if all the degenerate rows were filled with 0s, we have infinite solutions
        for(int j=i+1;j<w;j++) { if(!aug.elements[i][j].equals(0)) { throw new RuntimeException("Cannot invert matrix: No Solutions"); } } //otherwise, if at least one element in a degenerate row contains a non-zero, there are no solutions
      }
    }
    aug.reduceRowEchelon(); //otherwise, reduce the row echelon
    
    Complex[] inst = new Complex[h]; //instantiate new array for the resulting vector
    for(int i=0;i<h;i++) {           //loop through all elements
      inst[i] = aug.elements[i][w];  //set each element (cutting out everything but the last column)
    }
    return new CVector(inst); //construct resulting vector & return result
  }
  
  CVector rightDivide(CVector v) { //computes v * this^-1
    if(h!=w) { throw new MatrixSizeException("Cannot invert "+getDimensions()+" (only works for square matrices)"); } //if not square, throw exception
    if(h!=v.size()) { throw new MatrixSizeException("Cannot perform vector["+v.size()+"] / "+getDimensions()); } //if dimensions don't match, throw exception
    if(v.size()==0) { return new CVector(); } //special case: 0x0 matrix, return 0-D vector
    
    return transpose().leftDivide(v); //now, just transpose this, then perform left division. Surprisingly, yes, it is exactly that simple
  }
  
  ///////////////////////////////////////// EIGENVALUES / EIGENVECTORS /////////////////////////////////////////////////////
  
  public CMatrix upperHessenberg() { //computes & returns the upper hessenberg form
    if(h!=w) { throw new MatrixSizeException("Cannot put "+getDimensions()+" into upper Hessenberg form (must be square)"); } //if not square, throw exception
    
    CMatrix clone = clone();      //clone the matrix
    clone.putInUpperHessenberg(); //put the clone into upper Hessenberg
    return clone;                 //return result
  }
  
  private void putInUpperHessenberg() { //puts matrix into upper Hessenberg (ASSUMING that it's square)
    if(h<3) { return; } //if 0x0, 1x1, or 2x2, there is no subdiagonal, it's already in upper Hessenberg, you can quit
    
    for(int p=0;p<h-2;p++) { //loop through all but the last 2 columns, recursively making each column's subdiagonal all 0s w/out changing the eigenvalues
      //first, construct the Householder vector
      Complex[] vector = new Complex[h-p-1]; //initialize vector to use as base for Householder transformation
      double magSq = 0;                      //this will be used to compute the frobenius norm at the same time we initialize all elements of the vector
      for(int i=p+1;i<h;i++) {                 //loop through all elements of the Householder vector
        vector[i-p-1] = elements[i][p].copy(); //set each element (copying for safety)
        magSq += vector[i-p-1].absq();         //compute the sum of the absolute square of each element
      }
      if(magSq==vector[0].absq()) { continue; } //special case: the Householder vector is 0 or points in the x direction: the subdiagonal is all 0s, there's no more work to be done here
      //now, we have to shift the vector in the x direction by a given amount. First, compute that amount.
      Complex change = (vector[0].equals(0) ? Cpx.one() : vector[0].sgn()).muleq(Math.sqrt(magSq)); //it's the frobenius norm times either the signum of element 0 or times 1
      vector[0].addeq(change);  //add that change
      
      //next, construct the Householder matrix
      magSq += 2*vector[0].re*change.re+2*vector[0].im*change.im-change.absq(); //first, adjust the frobenius square, accounting for the vector now being adjusted
      double factor = 2d/magSq; //compute twice the reciprocal of the frobenius square (makes things easier in a bit)
      Complex[][] matrix = new Complex[h-p-1][h-p-1];     //initialize its dimensions
      for(int i=0;i<h-p-1;i++) for(int j=0;j<h-p-1;j++) { //loop through all elements
        if(i==j) { matrix[i][j] = new Complex(1-vector[i].absq()*factor); } //if i==j, set it to 1-2|v_i|^2/||v||^2
        else { matrix[i][j] = vector[i].mul(vector[j].conj()).muleq(-factor); } //otherwise, set it to -2v_iconj(v_j)/||v||^2    
      }
      CMatrix householder = new CMatrix(h-p-1,h-p-1,matrix); //use 2D array to construct Householder matrix
      //println(matrix[0][0], matrix[0][1], matrix[1][0], matrix[1][1]);
      
      
      //now, we just have to replace our whole matrix A with H*A*H, where H is a slightly altered version of the matrix above.
      //Altered i.e. We expanded its dimensions to the up/left until it was the same size as A, then put an identity matrix on the top left
      //To do this, we consider 4 quadrants of A. The top left quadrant does not change. The top right quadrant multiplies on the right by H.
      //The bottom left quadrant multiplies on the left by H (which can be shortcutted). The bottom right is multiplied on the left AND right by H.
      
      //First, the bottom left:
      elements[p+1][p] = change.neg(); //a shortcut: the rightmost column vector multiplies by the householder (causing it to point in the x direction), and every other vector was already 0 and won't change after multiplication
      for(int n=p+2;n<h;n++) { elements[n][p] = Cpx.zero(); } //since it's an x vector, the first element isn't 0, the rest are 0
      
      //Next, multiply the top & bottom right by the householder (A*H):
      Complex[][] copy = new Complex[h][w-p-1];         //create the matrix we use to generate the product
      copy2DArray(elements, 0,p+1, copy, 0,0, h,w-p-1); //copy the right 2 quadrants into the copy matrix
      CMatrix product = new CMatrix(h,w-p-1,copy).mul(householder); //right multiply by householder
      copy2DArray(product.elements, 0,0, elements, 0,p+1, h,w-p-1); //copy the product back into this matrix, but only the top right quadrant
      
      //Finally, left multiply the bottom right by the householder (H*A):
      copy = new Complex[h-p-1][w-p-1];                             //create the matrix we use to generate the last product
      copy2DArray(product.elements, p+1,0, copy, 0,0, h-p-1,w-p-1); //copy the bottom right quadrant into this copy matrix
      product = householder.mul(new CMatrix(h-p-1,w-p-1,copy));     //left multiply by householder
      copy2DArray(product.elements, 0,0, elements, p+1,p+1, h-p-1,w-p-1); //copy the product back into this matrix
    }
  }
  
  private CMatrix[] qrDecomposeHessy() { //performs QR decomposition (PRE-REQUISITE: MUST BE IN UPPER HESSENBERG)
    CMatrix qTotal = identity(h); //load the Q in QR decomposition (which is initialized to an identity matrix)
    
    for(int p=0;p<h-1;p++) { //loop through all iterations of this
      Complex[] vector = new Complex[] {elements[p][p].copy(), elements[p+1][p].copy()};            //load our householder vector
      double magSq = vector[0].absq()+vector[1].absq();                                             //compute the vector's frobenius square
      Complex change = (vector[0].equals(0) ? Cpx.one() : vector[0].sgn()).muleq(Math.sqrt(magSq)); //compute how much the vector's x coord must change by
      vector[0].addeq(change);                   //shift our x position by that much
      magSq = vector[0].absq()+vector[1].absq(); //recompute the frobenius square
      
      double factor = -2d/magSq; //compute this useful factor
      Complex[][] q = new Complex[][] {{new Complex(1+factor*vector[0].absq()),vector[0].mul(vector[1].conj()).muleq(factor)}, {vector[0].conj().mul(vector[1]).muleq(factor),new Complex(1+factor*vector[1].absq())}};
      //compute the above 2x2 matrix. We'll now be left multiplying rows p and p+1 by the above matrix
      
      //now, we have to left multiply this matrix by the above matrix (with the implication that it's being shoved into an identity at position p,p)
      elements[p][p] = change.neg(); elements[p+1][p] = Cpx.zero(); //left multiply first non-zero vector by q, resulting in an x vector
      for(int j=p+1;j<w;j++) { //loop through all columns to the right of that column, and left multiply them by q
        Complex temp = q[0][0].mul(elements[p][j]).addeq(q[0][1].mul(elements[p+1][j]));     //compute the x value (without setting)
        elements[p+1][j] = q[1][0].mul(elements[p][j]).addeq(q[1][1].mul(elements[p+1][j])); //compute the y value (with setting)
        elements[p][j] = temp;                                                               //set the x value
      }
      
      //lastly, we right multiply our total q with our 2x2 q. Specifically, we'll be multiplying columns p and p+1 by that 2x2 matrix (ignoring stuff below p+1, since that's all 0)
      //row p+1 is a y vector, all rows before that are x vectors, all rows after that are 0
      for(int i=0;i<=p;i++) { //loop through all rows before p+1
        qTotal.elements[i][p+1] = q[0][1].mul(qTotal.elements[i][p]); //compute and set the second value
        qTotal.elements[i][p].muleq(q[0][0]);                         //compute and set the first value
      }
      qTotal.elements[p+1][p] = q[1][0].mul(qTotal.elements[p+1][p+1]); //compute and set the first value of row p+1
      qTotal.elements[p+1][p+1].muleq(q[1][1]);                         //compute and set the second value of row p+1
    }
    return new CMatrix[] {qTotal,this}; //return Q and R
  }
  
  private static Complex[] eigenvalues2x2(Complex[][] mat) { //finds the eigenvalues of the given 2x2 matrix
    Complex ht = mat[0][0].lazyabs()>=9.97920154767359906D ? mat[0][0].scalb(-1).addeq(mat[1][1].scalb(-1)) : mat[0][0].add(mat[1][1]).scalbeq(-1); //compute the half trace (never overflows)
    Complex dt = mat[0][0].mul(mat[1][1]).subeq(mat[0][1].mul(mat[1][0]));                                                                          //compute the determinant (might overflow)
    if(dt.isInf() || dt.isNaN()) { //if infinite or NaN:
      ht.scalbeq(-512); dt = mat[0][0].scalb(-512).mul(mat[1][1].scalb(-512)).subeq(mat[0][1].scalb(-512).mul(mat[1][0].scalb(-512))); //divide half trace by 2^512, determinant by 2^1024
      Complex[] eig = solveQuad(ht, dt);        //solve the quadratic
      eig[0].scalbeq(512); eig[1].scalbeq(512); //multiply both by 2^512
      return eig;                               //return result
    }
    if(ht.sq().subeq(dt).lazyabs()==Double.POSITIVE_INFINITY) { //if discriminant overflows:
      ht.scalbeq(-512); dt.scalbeq(-1024); //scale down half trace by 2^512, determinant by 2^1024
      Complex[] eig = solveQuad(ht, dt);   //solve the quadratic
      eig[0].scalbeq(512); eig[1].scalbeq(512); //multiply both by 2^512
      return eig;                               //return result
    }
    if(ht.sq().equals(0) && !ht.equals(0) && dt.equals(0) && mat[0][1].lazyabs()<1 && mat[1][0].lazyabs()<1) { //if the components are all too small:
      ht.scalbeq(512); dt = mat[0][0].scalb(512).mul(mat[1][1].scalb(512)).subeq(mat[0][1].scalb(512).mul(mat[1][0].scalb(512))); //multiply half trace by 2^512, determinant by 2^1024
      Complex[] eig = solveQuad(ht,dt);           //solve the quadratic
      eig[0].scalbeq(-512); eig[1].scalbeq(-512); //divide both by 2^512
      return eig;                                 //return result
    }
    return solveQuad(ht,dt); //default: just use the quadratic formula
  }
  
  private static Complex[] solveQuad(Complex ht, Complex dt) { //solve quadratic 2x2 eigenvalues given half trace and determinant
    if(ht.absq()>2.5E5*dt.lazyabs()) { //trace² is much larger than determinant:
      ht.scalbeq(1); Complex inv = ht.inv(); //Quadratic formula will fail due to roundoff. Instead, compute approximation. First, find trace, find 1/trace
      Complex eig1 = dt.mul(inv.sq()).addeq(1).muleq(dt).muleq(inv); //smallest eigenvalue ~= |M|/Tr(M)+|M|²/Tr(M)³
      return new Complex[] {eig1, ht.subeq(eig1)}; //the other eigenvalue will be Tr(M)-(smallest). Return them both
    }
    //otherwise, use the standard formula
    Complex root = ht.sq().subeq(dt).sqrt(); //compute √(ht²-dt) (square root of discriminant)
    return new Complex[] {ht.add(root), ht.sub(root)}; //compute & return ht±√(ht²-dt)
  }
  
  /*private static Complex[] eigenvalues2x2(Complex[][] mat) { //finds the eigenvalues of the given 2x2 matrix
    Complex trace = mat[0][0].add(mat[1][1]); //compute trace
    Complex det   = mat[0][0].mul(mat[1][1]).subeq(mat[0][1].mul(mat[1][0])); //compute determinant
    
    Complex eigen1;
    if(trace.absq()>1E6*det.lazyabs()) { //trace² is much larger than determinant:
      Complex inv = trace.inv();         //quadratic formula will fail due to roundoff
      eigen1=det.mul(inv.sq()).add(1).muleq(det).muleq(inv); //smallest eigenvalue ~= |M|/Tr(M)+|M|²/Tr(M)^3
    }
    else {                               //otherwise:
      eigen1=trace.add(trace.sq().subeq(det.mul(4)).sqrt()).muleq(0.5); //use the quadratic formula
    }
    
    return new Complex[] {eigen1, trace.subeq(eigen1)}; //the sum of both eigenvalues is the trace, so we already know the other one. return both eigenvalues
  }*/
  
  /*private static Complex[] eigenvalues2x2(Complex[][] mat) { //finds the eigenvalues of the given 2x2 matrix
    if(mat[0][0].isInf() || mat[0][1].isInf() || mat[1][0].isInf() || mat[1][1].isInf()) { } //TODO deal with that
    Complex ht = mat[0][0].add(mat[1][1]).muleq(0.5); //compute half trace
    if(ht.isInf()) { ht = mat[0][0].mul(0.5).add(mat[1][1].mul(0.5)); } //if it overflows, try computing it another way
    Complex dt = mat[0][0].mul(mat[1][1]).subeq(mat[0][1].mul(mat[1][0])); //compute determinant
    
    boolean overflow = dt.isInf();
    if(overflow) { ht.scalbeq(-511); dt = mat[0][0].scalb(-511).mul(mat[1][1].scalb(-511)).subeq(mat[0][1].scalb(-511).mul(mat[1][0].scalb(-511))); } //determinant overflows: scale back
    else if(ht.lazyabs()>1.375e154d) { overflow=true; ht.scalbeq(-511); dt.scalbeq(-1022); } //trace squared overflows: scale back
    
    Complex diff = ht.sq().subeq(dt); //compute discriminant of quadratic
    boolean adj = diff.isInf();
    if(adj) { diff = ht.mul(0.5).sq().subeq(dt.mul(0.25)); }
    
    
  }*/
  
  private Complex[] getEigenvalues() { //obtains & returns eigenvalues, all while editing the original matrix
    Complex[] eigen = new Complex[h]; //initialize eigenvalue array
    
    putInUpperHessenberg(); //convert this matrix to upper hessenberg
    int iter = 0;
    while(h>1) { //perform the following until we only have 1 (or 0) rows left
      
      if(elements[h-1][w-2].lazyabs() <= elements[h-1][w-1].ulpMax()*8) { //if the lowest subdiagonal element is practically 0:
        eigen[h-1] = elements[h-1][w-1]; //set one of the eigenvalues to the bottom-right eigenvalue
        
        Complex[][] replace = new Complex[h-1][w-1];      //begin shrinking the matrix by 1
        copy2DArray(elements, 0,0, replace,0,0, h-1,w-1); //copy the elements over to the replace matrix
        elements = replace; h--; w--;                     //replace the elements array, decrement dimensions
        
        continue; //start the iteration all over (to make sure height is at least 1)
      }
      
      //otherwise, we have to perform the QR algorithm repeatedly until the lowest subdiagonal is 0
      Complex scalar; //this is what we will subtract to speed up the QR algorithm
      Complex[] vals = eigenvalues2x2(new Complex[][] {{elements[h-2][w-2],elements[h-2][w-1]},{elements[h-1][w-2],elements[h-1][w-1]}}); //compute the eigenvalues of the bottom right 2x2 submatrix
      
      if(vals[0].sub(elements[h-1][w-1]).lazyabs() <= vals[1].sub(elements[h-1][w-1]).lazyabs()) { scalar = vals[0]; } //set our scalar to whichever eigenvalue is closest to the bottom right element
      else                                                                                       { scalar = vals[1]; }
      
      CMatrix[] qr = subeq(scalar).qrDecomposeHessy(); //subtract the scalar, then QR decompose (note: this matrix will be in upper hessenberg)
      elements = mul(qr[0]).elements;                  //replace this (which is Q*R) with R*Q
      addeq(scalar);                                   //add back the scalar
      iter++;
    }
    
    if(h==1) { eigen[0] = elements[0][0]; } //lastly, grab the final eigenvalue from this now 1x1 matrix
    
    return eigen; //and now, finally, return the eigenvalues
  }
  
  public Complex[] eigenvalues() { //computes the eigenvalues
    if(h!=w) { throw new RuntimeException("Cannot compute eigenvalues for "+getDimensions()+" (only works for square matrices)"); } //if not square, throw an exception
    
    if(h==0) { return new Complex[0]; } //0x0: return empty array
    if(h==1) { return new Complex[] {elements[0][0].copy()}; } //1x1: return the only element
    if(h==2) { return eigenvalues2x2(elements); } //2x2: use quadratic formula
    
    Complex[] eig = clone().getEigenvalues(); //otherwise, use the QR algorithm to compute the eigenvalues, being sure to clone this matrix so nothing is overwritten
    //then, run 1 iteration of Newton's method to make things slightly more accurate
    for(Complex c : eig) { //loop through all eigenvalues
      try { CMatrix inv = sub(c).inv(); c.addeq(inv.trace().inv()); } //lambda += 1/Tr((M-lambda*I)^-1)
      catch(RuntimeException ex) { }                                  //if (M-lambda*I) is uninvertible, this eigenvalue does NOT need adjusting
    }
    //now, finally, we have to group together identical eigenvalues
    for(int n=0;n<h;) { //loop through the eigenvalue array
      int mult = 1; //multiplicity of this eigenvalue
      while(n+mult<h && eig[n].equals(eig[n+mult])) { mult++; } //for each identical eigenvalue right after this one, increment multiplicity (also, make sure to stop before going out of bounds)
      for(int k=n+mult+1;k<h;k++) {   //loop through all eigenvalues after the group of identical eigenvalues (also skip the one that was obviously different)
        if(eig[n].equals(eig[k])) { //if both eigenvalues are the same
          Complex temp = eig[n+mult]; eig[n+mult] = eig[k]; eig[k] = temp; ++mult; //swap both indices, increment multiplicity
        }
      }
      n+=mult; //increment the index by the multiplicity
    }
    
    return eig; //return result
    //return clone().getEigenvalues(); //otherwise, use the QR algorithm to compute the eigenvalues, being sure to clone this matrix so nothing is overwritten
  }
  
  private CVector[] eigenvectorsGivenEigenvalues(Complex[] vals) { //computes the eigenvectors given the eigenvalues
    CVector[] vec = new CVector[h]; //initialize vector array
    for(int n=0;n<h;) {             //loop through all eigenvalues/vectors
      int mult = 1; //first, find the multiplicity of this eigenvalue
      for(int k=n+1;k<h && vals[n].equals(vals[k]);k++) { ++mult; } //increment multiplicity until we reach the end or find an eigenvalue that's different
      
      CMatrix rref = sub(vals[n]);      //subtract each eigenvalue to create a degenerate matrix
      rref.rowEchelon();                //put into upper row echelon
      rref.elements[h-1][w-1].set(0);   //make the bottom right element 0
      rref.reduceRowEchelon();          //put it into reduced row echelon form (rref)
      
      //next, we have to rearrange our rows so that each row either has a leading 1 in the diagonal element or is empty (i.e. all 0)
      int dim = 0; //at the same time, we will also calculate the dimension of our eigenspace (which is equal to the number of rows which are all 0s)
      boolean pivot[] = new boolean[h]; //this array will tell us which rows will and won't be used as pivot points for our eigenspace (true=will, false=won't)
      
      for(int i=0;i<h;i++) { //loop through all rows
        if(!rref.elements[i][i].equals(1)) { //if the diagonal element isn't 1:
          Complex[] temp = rref.elements[h-1]; //grab the last row (which is empty
          for(int i2=h-1;i2>i;i2--) { //loop through all rows backwards
            rref.elements[i2] = rref.elements[i2-1]; //replace each row w/ the previous row
          }
          rref.elements[i] = temp; //replace this row with that empty row at the end
          
          pivot[i] = true; //this row can and will be used as a pivot 
          ++dim;           //increment the eigenspace dimension
        }
      }
      
      Complex[][] vecs = new Complex[dim][h]; //create array of arrays, each of which will be used to initialize vectors
      
      int ind = 0; //the index in our vecs array
      for(int i=0;i<h;i++) if(pivot[i]) { //loop through all rows in our rref matrix (skip the non-pivots)
        //set the corresponding vector equal to the negative of column i, but with the diagonal element set to 1
        for(int j=0;j<i;j++) { vecs[ind][j] = rref.elements[j][i].negeq(); } //set the elements above this to the negative of the corresponding elements
        vecs[ind][i] = Cpx.one(); //set the diagonal element to 1
        for(int j=i+1;j<h;j++) { vecs[ind][j] = rref.elements[j][i]; } //set the elements below to the corresponding elements (which are all 0, but let's save space :) )
        ++ind; //increment the index
      }
      
      for(int n2=0;n2<dim;n2++) { //now, we have to loop through all the basis vectors we're going to insert
        vec[n+n2] = new CVector(vecs[n2]).frobeniusUnit(); //set each vector (making sure to normalize it)
      }
      
      for(int n2=dim;n2<mult;n2++) { //lastly, we have to insert the redundant eigenvectors (this happens if the multiplicity exceeds the eigenspace dimension)
        vec[n+n2] = vec[n+dim-1].clone(); //fill it with the last vector
      }
      
      n+=mult; //increment n by the multiplicity of this eigenvalue
    }
    return vec; //return result
  }
  
  CVector[] eigenvectors() {
    if(h!=w) { throw new RuntimeException("Cannot compute eigenvectors for "+getDimensions()+" (only works for square matrices)"); } //if not square, throw an exception
    
    if(h==0) { return new CVector[0]; } //0x0: return empty array
    if(h==1) { return new CVector[] {new CVector(1)}; } //1x1: return single vector [1]
    
    return eigenvectorsGivenEigenvalues(eigenvalues()); //default: grab the eigenvalues, use those to compute the eigenvectors
  }
  
  Object[] eigenvalues_and_vectors() {
    Complex[] val = eigenvalues();
    CVector[] vec = eigenvectorsGivenEigenvalues(eigenvalues());
    return new Object[] {val, vec};
  }
  
  ///////////////////////////////////////// POWERS, LOGARITHMS, AND OTHER IMPORTANT FUNCTIONS //////////////////////////////////////
  
  CMatrix sq() { return mul(this); } //square
  CMatrix cub() { return mul(sq()); } //cube
  
  CMatrix pow(int a) { //raise to an integer power (using exponentiation by squaring)
    if(a==1) { return clone(); }
    
    if(!isSquare()) { throw new RuntimeException("Cannot raise "+getDimensions()+" ^ "+a+" (it's not a square)"); }
    
    if(a<0) { return inv().pow(-a); } //a is negative: return inverse ^ -a
    
    CMatrix ans=CMatrix.identity(h); //return value: M^a (init to Identity in case a==0)
    int ex=a;                        //copy of a
    CMatrix iter=clone();            //M ^ (2 ^ (whatever digit we're at))
    boolean inits=false;             //true once ans is initialized (to something other than 1)
    
    while(ex!=0) {                               //loop through all a's digits (if a==0, exit loop, return 1)
      if((ex&1)==1) {
        if(inits) { ans = ans.mul(iter);    } //mult ans by iter ONLY if this digit is 1
        else      { ans = iter; inits=true; } //if ans still = Identity, set ans=iter (instead of multiplying by iter)
      }
      ex >>= 1;                             //remove the last digit
      if(ex!=0) { iter = iter.sq(); }       //square the iterator (unless the loop is over)
    }
    
    return ans; //return the result
  }
  
  CMatrix pow(double a) {
    if((int)a==a) { return pow((int)a); }
    if(!isSquare()) { throw new RuntimeException("Cannot raise "+getDimensions()+" ^ "+a+" (it's not a square)"); }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? vals[i].pow(a) : new Complex(); }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  CMatrix pow(Complex a) {
    if(a.isReal()) { return pow(a.re); }
    if(!isSquare()) { throw new RuntimeException("Cannot raise "+getDimensions()+" ^ "+a+" (it's not a square)"); }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? vals[i].pow(a) : new Complex(); }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  CMatrix sqrt(boolean... b) {
    if(!isSquare()) { throw new RuntimeException("Cannot square root "+getDimensions()+" (it's not a square)"); }
    if(b.length!=h) { throw new RuntimeException(getDimensions()+" square root requires "+h+" parameters"); }
    
    if(h==0) { return new CMatrix(0,0); }
    if(h==1) { return new CMatrix(1,1,b[0] ? elements[0][0].sqrt() : elements[0][0].sqrt().negeq()); }
    if(h==2) {
      Complex[] vals = eigenvalues2x2(elements);
      Complex l1 = b[0] ? vals[0].sqrt() : vals[0].sqrt().negeq(), l2 = b[1] ? vals[1].sqrt() : vals[1].sqrt().negeq();
      return add(l1.mul(l2)).diveq(l1.add(l2));
    }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) { vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? (b[i] ? vals[i].sqrt() : vals[i].sqrt().negeq()) : new Complex(); }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  private CMatrix evaluateFunction(String name, MatFunc f) {
    if(!isSquare()) { throw new RuntimeException("Cannot evaluate"+name+" on "+getDimensions()+" (it's not a square)"); }
    
    Complex[] vals = eigenvalues();
    CVector[] vecs = eigenvectorsGivenEigenvalues(vals);
    
    Complex[][] vArr = new Complex[h][w];
    Complex[][] lArr = new Complex[h][w];
    for(int i=0;i<h;i++) for(int j=0;j<w;j++) {
      vArr[i][j] = vecs[j].elements[i]; lArr[i][j] = i==j ? f.func(0,vals[i]) : new Complex();
    }
    CMatrix vMat = new CMatrix(h,w, vArr), lMat = new CMatrix(h,w, lArr);
    
    return vMat.mul(lMat).rightDivide(vMat);
  }
  
  final static MatFunc sqrt = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.sqrt(); }
    double coef = 1; for(int k=0;k<n;k++) { coef*=0.5-k; } return inp.pow(0.5-n).muleq(coef);
  } },
  exp = new MatFunc() { public Complex func(int n, Complex inp) { return inp.exp(); } },
  log = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.log(); }
    double coef = 1; for(int k=1;k<n;k++) { coef*=-k; } return inp.pow(-n).muleq(coef);
  } },
  sin = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? (n&2)==0 ? inp.sin() : inp.sin().negeq() : (n&2)==0 ? inp.cos() : inp.cos().negeq(); } },
  cos = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? (n&2)==0 ? inp.cos() : inp.cos().negeq() : (n&2)!=0 ? inp.sin() : inp.sin().negeq(); } },
  sinh = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? inp.sinh() : inp.cosh(); } },
  cosh = new MatFunc() { public Complex func(int n, Complex inp) { return (n&1)==0 ? inp.cosh() : inp.sinh(); } },
  atan = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.atan(); }
    Complex term = inp.addI(1).pow(-n).subeq(inp.subI(1).pow(-n)).muleq(0.5*Mafs.factorial(n-1));
    if((n&1)==0) { term.diveqI(); } else { term.muleqI(); }
    return term;
  } },
  atanh = new MatFunc() { public Complex func(int n, Complex inp) {
    if(n==0) { return inp.atanh(); }
    Complex term = inp.sub(1).pow(-n).subeq(inp.add(1).pow(-n)).muleq(0.5*Mafs.factorial(n-1));
    if((n&1)==1) { term.negeq(); }
    return term;
  } },
  loggamma = new MatFunc() { public Complex func(int n, Complex inp) { return Cpx2.polygamma(n-1,inp); } };
  
  CMatrix sqrt() {
    if(!isSquare()) { throw new RuntimeException("Cannot square root "+getDimensions()+" (it's not a square)"); }
    if(h==0) { return new CMatrix(0,0); }
    if(h==1) { return new CMatrix(1,1, elements[0][0].sqrt()); }
    if(h==2) {
      Complex[] vals = eigenvalues2x2(elements);
      Complex l1 = vals[0].sqrt(), l2 = vals[1].sqrt();
      return add(l1.mul(l2)).diveq(l1.add(l2));
    }
    return evaluateFunction("square root",sqrt);
  }
  CMatrix exp() { return evaluateFunction("exponential",exp); }
  CMatrix log() { return evaluateFunction("logarithm",log); }
  CMatrix sin() { return evaluateFunction("sine",sin); }
  CMatrix cos() { return evaluateFunction("cosine",cos); }
  CMatrix sinh() { return evaluateFunction("sinh",sinh); }
  CMatrix cosh() { return evaluateFunction("cosh",cosh); }
  CMatrix atan() { return evaluateFunction("arc tangent",atan); }
  CMatrix atanh() { return evaluateFunction("atanh",atanh); }
  
  CMatrix tan() { return evaluateFunction("tan",cos).leftDivide(evaluateFunction("tan",sin)); }
  CMatrix tanh() { return evaluateFunction("tanh",cosh).leftDivide(evaluateFunction("tanh",sinh)); }
  CMatrix sec() { return evaluateFunction("sec",cos).inv(); }
  CMatrix csc() { return evaluateFunction("csc",sin).inv(); }
  CMatrix cot() { return evaluateFunction("cot",sin).leftDivide(evaluateFunction("cot",cos)); }
  CMatrix sech() { return evaluateFunction("sech",cosh).inv(); }
  CMatrix csch() { return evaluateFunction("csch",sinh).inv(); }
  CMatrix coth() { return evaluateFunction("coth",sinh).leftDivide(evaluateFunction("coth",cosh)); }
  
  CMatrix loggamma() { return evaluateFunction("lnΓ",loggamma); }
  CMatrix factorial() { return add(1).evaluateFunction("!",loggamma).exp(); }
  
  ///////////////////////////////////// LOAD FROM MATRIX /////////////////////////////////
  
  static CMatrix loadFromString(String s) {
    if(!s.startsWith("[[") || !s.endsWith("]]")) { return null; } //if it doesn't start with [[ and end with ]], return null
    s = s.substring(2,s.length()-2);     //remove [[ and ]]
    
    if(s.startsWith("]")) { //special case: nx0 matrix
      int hig = 1; //calculate the height of the matrix
      while(s.startsWith("],[")) { //repeatedly remove the first 3 characters
        s = s.substring(3);        //remove them
        hig++;                     //increment the height
      }
      if(s.length()==0) { return new CMatrix(hig,0); } //if there's nothing left, return the result
      else { return null; } //otherwise, this matrix is invalid, return the result
    }
    
    String[] split = s.split("\\],\\["); //split into substrings separated by commas with braces around them
    Complex[][] arr = new Complex[split.length][]; //initialize 2D array
    int wid = -1;                                  //width of the array
    for(int i=0;i<arr.length;i++) {                //loop through all the rows
      
      String[] split2 = split[i].split(",");       //split each row into substrings separated by commas
      if(wid==-1) { wid = split2.length; }         //find the actual width
      else if(wid!=split2.length) { return null; } //each array must be of the same length
      
      arr[i] = new Complex[wid];                   //initialize each row
      for(int j=0;j<split2.length;j++) {           //loop through each column
        arr[i][j] = Cpx.complex(split2[j]);        //cast each substring to a complex
      }
    }
    return new CMatrix(arr.length,wid,arr); //create and return matrix
  }
  
  ///////////////////// ARRAY COPYING //////////////////////
  
  static void copy2DArray(Complex[][] src, int srcPos1, int srcPos2, Complex[][] dest, int destPos1, int destPos2, int length1, int length2) {
    for(int i=0;i<length1;i++) { //loop through all rows we copy over
      System.arraycopy(src[i+srcPos1],srcPos2, dest[i+destPos1],destPos2, length2); //copy over each row
    }
  }
}

public static class MatrixSizeException extends RuntimeException {
  public MatrixSizeException() {
    super("Matrix dimensions are not compatible for the specified operation");
  }
  
  public MatrixSizeException(String message) {
    super(message);
  }
}

static interface MatFunc { //an interface just for storing matrix functions
  public Complex func(int n, Complex inp); //returns the n-th derivative of the function evaluated at input inp
}
