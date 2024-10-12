public static class CVector implements Iterable<Complex> {
  /////////////// ATTRIBUTES /////////////////
  
  Complex[] elements; //all the elements (x,y,z, etc.)
  
  /////////////// CONSTRUCTORS /////////////////
  
  CVector() { elements = new Complex[0]; }
  
  CVector(Complex... c) {
    for(Complex c2 : c) { if(c2==null) { throw new NullPointerException("Vector cannot have null elements"); } }
    elements = new Complex[c.length];
    arrayCopy(c, elements);
  }
  
  CVector(double... d) {
    elements = new Complex[d.length];
    for(int n=0;n<d.length;n++) { elements[n] = new Complex(d[n]); }
  }
  
  //////////////// INHERITED METHODS ///////////////////
  
  @Override
  boolean equals(final Object obj) {
    if(!(obj instanceof CVector)) { return false; } //not a vector: return false
    CVector v = (CVector)obj;
    if(v.size() != size()) { return false; } //different sizes: return false
    for(int n=0;n<size();n++) { if(!get(n).equals(v.get(n))) { return false; } } //one or more elements don't equal: return false
    return true; //otherwise, return true
  }
  
  @Override
  int hashCode() {
    int hash = 0;
    for(Complex c : this) { hash = 31*hash + c.hashCode(); }
    return hash;
  }
  
  @Override
  CVector clone() {
    Complex[] arr = new Complex[size()];
    for(int n=0;n<size();n++) { arr[n] = elements[n].clone(); }
    return new CVector(arr);
  }
  
  String toString(int dig) {
    double threshold = 0; //how small something has to be to be rounded down to 0
    if(Complex.omit_Option) { //if we omit small parts, the threshold is non-zero
      double biggest = lazyMag(); //find the biggest element
      threshold = Math.min(1e-11d*biggest, 1e-12d); //set our threshold to either 10^-12, or 10^-11*biggest element
    }
    
    String result = "["; //initialize to opening left bracket
    for(int n=0;n<size();n++) {            //loop through all elements in the array
      if(elements[n].lazyabs()<threshold) { result+="0"; } //if this element is below our threshold, round down to 0
      else { result += elements[n].toString(dig); } //concatenate each element, outputted to the given amount of precision
      if(n!=size()-1) { result+=","; }     //put a comma after all entries but the last
    }
    return result+"]"; //close with right bracket, return result
  }
  
  @Override
  String toString() { return toString(-1); } //default toString: output result to maximum precision
  
  @Override
  Iterator<Complex> iterator() { return new Iterator<Complex>() {
    private int index = 0;
    public Complex next() { return elements[index++]; }
    public boolean hasNext() { return index<elements.length; }
  }; }
  
  //////////////// GETTERS / SETTERS /////////////////////
  
  int size() { return elements.length; }
  
  Complex get(int ind) { return elements[ind]; }
  
  void set(int ind, Complex c) {
    if(c==null) { throw new NullPointerException("Cannot give vector null elements"); }
    elements[ind] = c;
  }
  void set(int ind, double d) { elements[ind] = new Complex(d); }
  
  //////////////// ARITHMETIC //////////////////////
  
  double lazyMag() { double mag = 0; for(Complex c : this) { mag = Math.max(mag, c.lazyabs()); } return mag; }
  
  boolean isReal() { for(Complex c : this) { if(!c.isReal( )) { return false; } } return  true; }
  boolean isZero() { for(Complex c : this) { if(!c.equals(0)) { return false; } } return  true; }
  boolean isInf () { for(Complex c : this) { if( c.isInf ( )) { return  true; } } return false; }
  
  CVector negeq () { for(Complex c : this) { c.negeq (); } return this; }
  CVector muleqI() { for(Complex c : this) { c.muleqI(); } return this; }
  CVector diveqI() { for(Complex c : this) { c.diveqI(); } return this; }
  CVector conjeq() { for(Complex c : this) { c.conjeq(); } return this; }
  
  CVector neg () { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].neg (); } return new CVector(arr); }
  CVector mulI() { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mulI(); } return new CVector(arr); }
  CVector divI() { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].divI(); } return new CVector(arr); }
  CVector conj() { Complex[] arr=new Complex[elements.length]; for(int n=0;n<elements.length;n++) { arr[n]=elements[n].conj(); } return new CVector(arr); }
  
  Complex magSq() { Complex res=Cpx.zero(); for(Complex c : this) { res.addeq(c.sq()); } return res; }
  Complex mag() {
    double mag = lazyMag(); //first, for the sake of preventing overflow/underflow, compute the lazy magnitude
    if(mag<=1.055E-154D) { Complex sum=Cpx.zero(); for(Complex c : this) { sum.addeq(c.scalb( 1022).sq()); } return sum.sqrt().scalb(-1022); } //if it underflows, we * by 2^1022, find the magnitude, and / by 2^1022
    if(mag>=9.481E+153D) { Complex sum=Cpx.zero(); for(Complex c : this) { sum.addeq(c.scalb(-1022).sq()); } return sum.sqrt().scalb( 1022); } //if it  overflows, we / by 2^1022, find the magnitude, and * by 2^1022
    
    Complex sum=Cpx.zero(); for(Complex c : this) { sum.addeq(c.sq()); } return sum.sqrt(); //default: add the square of each term, find the square root
  }
  
  
  
  CVector addeq(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot add vector["+size()+"] to vector["+v.size()+"]"); }
    for(int n=0;n<size();n++) { get(n).addeq(v.get(n)); }
    return this;
  }
  CVector subeq(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot subtract vector["+size()+"] minus vector["+v.size()+"]"); }
    for(int n=0;n<size();n++) { get(n).subeq(v.get(n)); }
    return this;
  }
  CVector muleq(final Complex c) { for(Complex c2 : this) { c2.muleq(c); } return this; }
  CVector muleq(final  double d) { for(Complex c  : this) {  c.muleq(d); } return this; }
  CVector diveq(final Complex c) { Complex inv = c.inv(); for(Complex c2 : this) { c2.muleq(inv); } return this; }
  CVector diveq(final  double d) { double  inv = 1d/d;    for(Complex c  : this) {  c.muleq(inv); } return this; }
  
  
  CVector add(final CVector v) {
    if(elements.length!=v.elements.length) { throw new IllegalArgumentException("Cannot add vector["+elements.length+"] to vector["+v.elements.length+"]"); }
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].add(v.elements[n]); }
    return new CVector(arr);
  }
  CVector sub(final CVector v) {
    if(elements.length!=v.elements.length) { throw new IllegalArgumentException("Cannot subtract vector["+elements.length+"] minus vector["+v.elements.length+"]"); }
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].sub(v.elements[n]); }
    return new CVector(arr);
  }
  CVector mul(final Complex c) {
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(c); }
    return new CVector(arr);
  }
  CVector mul(final double d) {
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(d); }
    return new CVector(arr);
  }
  CVector div(final Complex c) { return mul(c.inv()); }
  CVector div(final double d) { return mul(1d/d); }
  
  CVector uniteq() {
    Complex normInv = mag().inv();
    for(Complex c : this) { c.muleq(normInv); }
    return this;
  }
  CVector unit() {
    Complex normInv = mag().inv();
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(normInv); }
    return new CVector(arr);
  }
  
  
  
  Complex dot(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot dot vector["+size()+"] with vector["+v.size()+"]"); }
    Complex dot = Cpx.zero();
    for(int n=0;n<size();n++) { dot.addeq(get(n).mul(v.get(n))); }
    return dot;
  }
  Complex pDot(final CVector v) {
    if(size()!=2 || v.size()!=2) { throw new IllegalArgumentException("Cannot perpendicular-dot vector["+size()+"] with vector["+v.size()+"]"); }
    return get(0).mul(v.get(1)).subeq(get(1).mul(v.get(0)));
  }
  CVector perp() {
    if(elements.length!=2) { throw new IllegalArgumentException("Cannot apply perpendicular operator to vector["+size()+"]"); }
    return new CVector(elements[1].neg(), elements[0].copy());
  }
  CVector cross(final CVector v) {
    if(size()!=3 || v.size()!=3) { throw new IllegalArgumentException("Cannot cross vector["+size()+"] with vector["+v.size()+"]"); }
    return new CVector(get(1).mul(v.get(2)).subeq(get(2).mul(v.get(1))), get(2).mul(v.get(0)).subeq(get(0).mul(v.get(2))), get(0).mul(v.get(1)).subeq(get(1).mul(v.get(0))));
  }
  Complex tripleScalar(final CVector u, final CVector v) {
    if(size()!=3 || u.size()!=3 || v.size()!=3) { throw new IllegalArgumentException("Cannot perform triple scalar product on vector["+size()+"], vector["+u.size()+"], and vector["+v.size()+"]"); }
    return get(0).mul(u.get(1).mul(v.get(2)).subeq(u.get(2).mul(v.get(1)))).addeq(get(1).mul(u.get(2).mul(v.get(0)).subeq(u.get(0).mul(v.get(2))))).addeq(get(2).mul(u.get(0).mul(v.get(1)).subeq(u.get(1).mul(v.get(0)))));
  }
  
  Complex wedgeMagSq(final CVector v) { //computes the magnitude squared of the wedge product
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot wedge vector["+size()+"] with vector["+v.size()+"]"); } //must have same dimensions
    return magSq().muleq(v.magSq()).subeq(dot(v).sq()); // |a|²|b|²-(a.b)²
  }
  Complex wedgeMag(final CVector v) { //computes the magnitude of the wedge product
    return wedgeMagSq(v).sqrt(); //square root of magnitude squared
  }
  Complex wedgeComponent(final CVector v, final int i, final int j) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot wedge vector["+size()+"] with vector["+v.size()+"]"); } //must have same dimensions
    if(i<0 || j<0 || i>=size() || j>=size()) { throw new IllegalArgumentException("Cannot find component "+i+","+j+" of vector["+size()+"] wedge vector["+v.size()+"]"); }
    return get(i).mul(v.get(j)).subeq(get(j).mul(v.get(i)));
  }
  
  
  Complex distSq(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot find distance between vector["+size()+"] and vector["+v.size()+"]"); } //must have same dimensions
    Complex sum = Cpx.zero();
    for(int n=0;n<size();n++) { sum.addeq(get(n).sub(v.get(n)).sq()); }
    return sum;
  }
  Complex dist(final CVector v) {
    return distSq(v).sqrt();
  }
  
  Complex angleBetween(final CVector v) {
    if(size()!=v.size()) { throw new IllegalArgumentException("Cannot find angle between vector["+size()+"] and vector["+v.size()+"]"); }
    double mag1 = lazyMag(), mag2 = v.lazyMag(); //first, to prevent overflow/underflow, compute the lazy magnitudes
    //TODO the rest of the overflow/underflow protection
    Complex cos = dot(v).diveq(magSq().muleq(v.magSq()).sqrt());
    return cos.acos();
  }
  
  
  double frobeniusMagSq() {
    double sum=0; for(Complex c : this) { sum+=c.absq(); } return sum;
  }
  //double frobeniusMag() { return Math.sqrt(frobeniusMagSq()); }
  double frobeniusMag() {
    double mag = lazyMag(); //first, for the sake of preventing overflow/underflow, compute the lazy magnitude
    if(mag<=1.055E-154D) { double sum=0; for(Complex c : this) { sum+=c.scalb( 1022).absq(); } return Math.scalb(Math.sqrt(sum),-1022); } //if it underflows, we * by 2^1022, find the magnitude, and / by 2^1022
    if(mag>=9.481E+153D) { double sum=0; for(Complex c : this) { sum+=c.scalb(-1022).absq(); } return Math.scalb(Math.sqrt(sum), 1022); } //if it  overflows, we / by 2^1022, find the magnitude, and * by 2^1022
    
    double sum=0; for(Complex c : this) { sum+=c.absq(); } return Math.sqrt(sum); //default: add the absolute square of each term, find the square root
  }
  
  Complex frobeniusProduct(final CVector v) {
    if(elements.length!=v.elements.length) { throw new IllegalArgumentException("Cannot perform Frobenius product on vector["+elements.length+"] and vector["+v.elements.length+"]"); }
    Complex sum = Cpx.zero();
    for(int n=0;n<elements.length;n++) { sum.addeq(elements[n].mul(v.elements[n].conj())); }
    return sum;
  }
  
  CVector frobeniusUnit() {
    double inv = 1d/frobeniusMag();
    Complex[] arr = new Complex[elements.length];
    for(int n=0;n<elements.length;n++) { arr[n]=elements[n].mul(inv); }
    return new CVector(arr);
  }
  
  
  CVector re() {
    Complex[] arr = new Complex[size()];
    for(int n=0;n<size();n++) { arr[n] = new Complex(elements[n].re); }
    return new CVector(arr);
  }
  
  CVector im() {
    Complex[] arr = new Complex[size()];
    for(int n=0;n<size();n++) { arr[n] = new Complex(elements[n].im); }
    return new CVector(arr);
  }
  
  public static CVector zero(final int dim) {
    double[] d = new double[dim];
    return new CVector(d);
  }
  
  public static CVector loadFromString(String s) {
    if(!s.startsWith("[") || !s.endsWith("]")) { return null; } //if doesn't start with [ and ], return null
    if(s.equals("[]")) { return new CVector(); } //if it's empty, return an empty vector
    s = s.substring(1,s.length()-1); //remove [ and ]
    String[] split = s.split(","); //split into substrings separated by commas
    Complex[] elem = new Complex[split.length]; //initialize complex array
    for(int n=0;n<split.length;n++) { elem[n] = Cpx.complex(split[n]); } //cast each substring to a complex
    return new CVector(elem); //return resulting vector
  }
  
  double ulpMax() {
    double ulp = Double.MIN_VALUE;
    for(int n=0;n<size();n++) {
      ulp = Double.max(ulp, elements[n].ulpMax());
    }
    return ulp;
  }
  
  double ulpMin() {
    double ulp = Double.MIN_VALUE;
    for(int n=0;n<size();n++) {
      ulp = Double.min(ulp, elements[n].ulpMin());
    }
    return ulp;
  }
}
