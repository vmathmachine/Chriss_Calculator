import java.math.BigInteger;

public static class Cpx3 extends Cpx2 {
  public static Complex polygamma2(int m, Complex z) {
    if(m==-2) { return kFunction(z,false).addeq(mul(sub(Math.log(2*Math.PI)+1,z),z,0.5)); }
    return polygamma(m,z);
  }
  
  public static Complex kFunction(Complex a, boolean expo) { //K-Function
    
    if(a.equals(0)) { return one(); } //special case a==0: return 1
    
    Complex z=a.re>=0 ? a.add(5) : sub(6,a); //either perform the K-Function 5 steps ahead & work backwards, or do the same thing for 1-a & use a reflection formula
    
    Complex expon=mul(z,z.sub(1),0.5).addeq(1.0D/12).muleq(ln(z)).subeq(sq(z.mul(0.5))); //initialize our exponent
    
    Complex iter=sq(z.inv()); //this is what the term will multiply by each time
    Complex term=iter.copy(); //this'll store z^(-2k+2)
    
    for(int k=2;k<8;k++) {
      expon.subeq(term.mul(Bernoulli[k<<1]/(4*k*(2*k-1)*(k-1)))); //add each term
      term.muleq(iter); //multiply by the iterator
    }
    
    for(int n=1;n<=5;n++) { //loop through the five numbers right before z, and subtract said numbers times their natural log
      expon.subeq(ln(z.sub(n)).muleq(z.sub(n)));
    }
    
    if(a.re<0) { //if a is less than 0, apply the (very intricate) reflection formula
      expon.addeq(Cl2(a.mul(2*Math.PI)).div(2*Math.PI)); //for starters, the exponent has to add a scaled version of the clausen function

      Complex reflector=a.mul(sub(1,a));        //this is our reflector.  It will either be added or subtracted from our answer, depending on the imaginary part
      Complex b=a.sub(Math.ceil(a.re));         //I'll be honest, I don't fully understand how this reflection works, I mostly just used trial and error on a very exception-heavy problem
      reflector.addeq(b.mul(b.add(1)));
      reflector.muleqI(HALFPI);
      if(a.im<0) { expon.addeq(reflector); } //if the imaginary part is negative, add the reflector
      else       { expon.subeq(reflector); } //if it's positive or 0, subtract the reflector
    }
    
    expon.re+=0.2487544770337843D; //add the log of the Glaisher-Kinkelin constant
    
    return expo ? exp(expon) : expon; //return the natural exponent of our result (unless we want the log-K function)
  }
  
  public static Complex barnesG(Complex z) { //returns the Barnes G-Function of z
    if(z.isInt() && z.re<=0) { return zero(); }                       //special case z is non-positive integer: return 0
    Complex ans = exp(sub(z,1).muleq(loggamma(z))).diveq(kFunction(z,true)); //G(z)=Γ(z)^(z-1)/K(z)
    if(z.im==0) { ans.im=0; }
    return ans;
  }
  
  ////////////////////////////// ZETA FUNCTIONS ///////////////////////////
  
  public static Complex zeta(Complex s) {
    if(Math.abs(s.im)>30 && s.re>-4 && s.re<5) { return zeta2(s); }
    else                                       { return zeta1(s); }
  }
  
  private static Complex zeta1(Complex s) {
    
    if(s.re<0.5) {
      if(Math.abs(s.im)>300) { return exp(s.sub(1).mul(Math.log(2*Math.PI)).add(s.mulI().abs2().mul(HALFPI)).add(loggamma(sub(1,s)))).mul(zeta1(sub(1,s))).mulI(csgn(s.im)); }
      return mul(pow(complex(2*Math.PI),s),sin(s.mul(HALFPI)),gamma(sub(1,s))) .mul(zeta1(sub(1,s))).div(Math.PI);
    }
    
    double[] coef={1.0D, -1.0D, 1.0D, -1.0D, 1.0D, -0.9999999999999956D, 0.9999999999997994D, -0.9999999999938609D, 0.9999999998649105D, -0.9999999977694676D,
            0.9999999714737119D, -0.9999997104537386D, 0.9999976222939507D, -0.9999839584657739D, 0.999909963580878D, -0.9995752248158726D, 0.998300908965645D, -0.9941953510449523D, 0.9829544651872266D, -0.9567257315192D,
            0.9044921225074828D, -0.8156949871875634D, 0.6869855506262866D, -0.5283436869577361D, 0.36280435095577035D, -0.21751716776255578D, 0.11124997091266166D, -0.04729731398489733D, 0.016192457785229986D, -0.004275662228214578D,
            8.152497252699953E-4D, -9.970680093230158E-5D, 5.86510593719421E-6D};
    
    Complex sum=zero();
    for(int n=1;n<=coef.length;n++) {
      sum.addeq(mul(pow(new Complex(n),s.neg()),coef[n-1]));
    }
    
    return div(sum,sub(1,pow(complex(2),sub(1,s))));
  }
  
  private static Complex zeta2(Complex s) {
    Complex t=sub(0.5,s).muleqI();
    int m=(int)Math.floor(sqrt(t.mul(csgn(s.im)/(2*Math.PI))).re);
    
    Complex theta=rsTheta(s.sub(0.5).diveqI()); //compute the Riemann-Siegel Theta Function
    
    Complex sum=(m==0?zero():cos(theta));
    for(int k=2;k<=m;k++) {
      sum.addeq( cos(theta.sub(t.mul(Math.log(k)))).diveq(Math.sqrt(k)) );
    }
    sum.muleq(2);
    
    Complex sum2=zero();
    Complex term=one();
    Complex iter=sqrt(div(2*Math.PI*csgn(s.im),t));
    Complex inp=iter.inv().subeq(m).muleq(2).subeq(1);
    
    double[] coef={0.5D,0.5D,1.2337005501361697D,1.2337005501361697D,0.41576387242884216D,-17.571264781494055D,-89.76409950303267D,-348.55262483408745D,-764.3879449480118D,1784.5561668662722D,29190.148401564962D,202565.10667286662D,814080.3882205525D,
            974030.8878581069D,-1.957849534898767E7D,-2.2459951712568212E8D,-1.390261988148928E9D,-4.633697498894301E9D,1.6887987043774656E10D,4.036267034527721E11D,3.580901293164045E12D,1.8567163359058586E13D,6.489660305505916E12D,
            -1.0340517738538868E15D,-1.3024983661929054E16D,-9.2205787899349568E16D,-2.57539235105429344E17D,3.3255537896359675E18D,6.3351064269818356E19D,5.831853872469764E20D,2.7815735241170354E21D,-1.064709072231034E22D};
    Complex[] deriv=new Complex[19];
    Complex termd=one(), iterd=inp.abs2().sub(0.5);
    //if(testmessage) { println(iterd); }
    for(int n=0;n<19;n++) if(n!=13 && n!=16 && n!=17) { deriv[n]=zero(); }
    for(int n2=0;n2<coef.length;n2++) {
      for(int n=0;n<19;n++) if(n!=13 && n!=16 && n!=17 && n<coef.length-n2) {
        deriv[n].addeq(termd.mul(coef[n2+n]));
      }
      termd.muleq(iterd.div(n2+1));
    }
    if(!inp.isRoot()) { for(int n=1;n<17;n+=2) if(n!=13) { deriv[n].negeq(); } }
    
    
    Complex[] out={deriv[0], deriv[3].div(-12*Math.PI*Math.PI), deriv[2].div(16*Math.PI*Math.PI).add(deriv[6].div(288*pow(Math.PI,4))), deriv[1].div(-32*Math.PI*Math.PI).sub(deriv[5].div(120*pow(Math.PI,4))).sub(deriv[9].div(10368*pow(Math.PI,6)))
            ,deriv[0].mul(143/(18432*Math.PI*Math.PI)).add(deriv[4].mul(19/(1536*pow(Math.PI,4)))).add(deriv[8].mul(11/(23040*pow(Math.PI,6)))).add(deriv[12].div(497664*pow(Math.PI,8)))
            ,deriv[3].mul(-2879/(221184*pow(Math.PI,4))).sub(deriv[7].mul(901/(645120*pow(Math.PI,6)))).sub(deriv[11].mul(7/(414720*pow(Math.PI,8)))).sub(deriv[15].div(29859840*pow(Math.PI,10)))
            ,deriv[2].mul(2879/(294912*pow(Math.PI,4))).add(deriv[5].mul(79267/(26542080*pow(Math.PI,6)))).add(deriv[10].mul(18889/(232243200*pow(Math.PI,8)))).add(deriv[14].mul(17/(39813120*pow(Math.PI,10)))).add(deriv[18].div(2149908480L*pow(Math.PI,12)))
    };
    
    for(int n=0;n<out.length;n++) {
      sum2.addeq(term.mul(out[n]));
      term.muleq(iter);
    }
    sum2.muleq(sqrt(iter));
    
    if((m&1)==0) { sum.subeq(sum2); }
    else         { sum.addeq(sum2); }
    
    sum.muleq(exp(theta.divI()));
    
    return sum;
  }
  
  public static Complex rsTheta(Complex t) { //returns the Riemann-Siegel Theta function
    
    Complex s=t.mulI().addeq(0.5);
    
    Complex theta=sub(Math.log(Math.PI),s.mul(Math.log(2*Math.PI)).add(loggamma(sub(1,s))));
    if(Math.abs(s.im)>400) { theta.subeq(s.mulI(HALFPI).abs2().subeq(new Complex(LOG2,-HALFPI*csgn(s.im))));                                    }
    else                   { theta.subeq(ln(sin(s.mul(HALFPI)))).subeq(iTimes(2*Math.PI*csgn(s.re*s.im)*Math.round(0.25*csgn(s.re)*(1-s.re)))); }
    theta.muleqI(-0.5);
    if(t.im==0) { theta.im=0; }
    
    return theta;
  }
  
  public static Complex rsZFunction(Complex t) { //returns the Riemann-Siegel Z Function
    
    Complex s=t.mulI().addeq(0.5);
    Complex res=zeta(s).muleq(exp(rsTheta(t).muleqI())); //compute the result
    if(t.im==0) { res.im=0; }
    return res;
  }
  
  ///////////////////////////// POLYLOGARITHMS ////////////////////////////
  
  public static Complex Li2(Complex z) { return polylog(2,z); } //dilogarithm of complex input z
  
  public static Complex Cl2(Complex z) { //returns the clausen function of complex z
    if(z.im==0) { return new Complex(Li2(exp(iTimes(z.re))).im); } //if a is real, return the imaginary part of Li2(e^(ai))
    return Li2(exp(z.mulI())).sub(Li2(exp(z.divI()))).mulI(-0.5D); //otherwise, return (Li2(e^(ai))-Li2(e^(-ai)))/(2i)
  }
  
  private static Complex powPolylog(int s, Complex z, int iters) { //computes the polylogarithm via a power series
    if(absq(z)>1) {
      Complex reflector=bernPoly(s,ln(z.neg()).muleqI(-1.0D/(2*Math.PI)).addeq(0.5)).muleq(pow(iTimes(2*Math.PI),s).negeq());
      if(z.im==0 && z.re>0 && z.re<1) {
        reflector.addeq(pow(ln(z),s-1).muleqI(2*Math.PI*s));
      }
      double fact=1.0D;
      for(long k=1;k<=s;k++) { fact*=k; }
      reflector.diveq(fact);
      if((s&1)==0) { return reflector.subeq(powPolylog(s,z.inv(),iters)); }
      else         { return reflector.addeq(powPolylog(s,z.inv(),iters)); }
    }
    
    Complex sum=zero(), expo=z.copy();
    for(int n=1;n<=iters;n++) {
      sum.addeq(expo.div(pow(n,s)));
      expo.muleq(z);
    }
    
    return sum;
  }
  
  private static Complex logPolylog(int s, Complex lnz, int iters) { //computes polylogarithm via a power series of the natural logarithm (plus an ln(-ln(z)) term)
    double[] zetaPos={-0.5D,INF,1.64493406684822644D,1.20205690315959429D,1.08232323371113819D,1.03692775514336993D,1.01734306198444914D,1.00834927738192283D,1.00407735619794434D,
            1.00200839282608221D,1.00099457512781808D,1.00049418860411946D,1.00024608655330804D,1.00012271334757848D,1.00006124813505870D,1.00003058823630702D,1.00001528225940865D};
    double[] zetaNeg={-0.5D,-1.0D/12,0,1.0D/120,0,-1.0D/252,0,1.0D/240,0,-1.0D/132,0,691.0D/32760,0,-1.0D/12,0,3617.0D/8160,0,-43867.0D/14364,0,174611.0D/6600,0,-77683.0D/276,0,
            236364091.0D/65520,0,-657931.0D/12,0,3392780147.0D/3480,0,-1723168255201.0D/85932,0,7709321041217.0D/16320,0,-151628697551.0D/12,0,26315271553053477373.0D/6909840,
            0,-154210205991661.0D/12};
    //create arrays to store precomputed values for the zeta function at particular points
    
    Complex sum=zero(), expo=one(), iter=lnz.copy(); //init sum, exponent, and iterator
    
    for(int n=0;n<s-1;n++) { //compute Σ[n=0,s-2] ζ(s-n)ln(z)^n/n!
      if(s-n>16) {
        double zetaapprox=1;
        for(int k=2;k<=10;k++) { zetaapprox+=pow(k,-s); }
        sum.addeq(expo.mul(zetaapprox));
      }
      else { sum.addeq(expo.mul(zetaPos[s-n])); }
      expo.muleq(iter).diveq(n+1);
    }
    
    if(!iter.equals(0)) { //this term can only be added if lnz!=0 (otherwise, we get lim(x→0) xln(x) = 0)
      double Harmon=0.0D;
      for(int n=1;n<s;n++) { Harmon+=1.0D/n; }
      sum.addeq(sub(Harmon,ln(iter.neg())).muleq(expo)); //add ln(z)^(s-1)/(s-1)!*(Σ[n=1,s-1]1/n - ln(-ln(z)))
    }
    expo.muleq(iter).diveq(s); //exponent := ln(z)^s/s!
    
    sum.subeq(expo.mul(0.5D));   //subtract exponent/2
    expo.muleq(iter).diveq(s+1); //exponent := ln(z)^(s+1)/(s+1)!
    iter.muleq(iter);            //square the iterator
    
    for(int n=0;n<=iters-s;n++) { //add Σ[n=0,iters-s → ∞] ζ(2n+1)*ln(z)^(s+2n+1)/(s+2n+1)!
      sum.addeq(expo.mul(zetaNeg[2*n+1]));
      expo.muleq(iter).diveq((2*n+s+2)*(2*n+s+3));
    }
    
    return sum; //return summation
  }
  
  public static Complex polylog(int s, Complex z) { //computes the s-th polylogarithm of complex z
    
    if(s<2) { //if s<2, then we can compute the polylogarithm through explicit means
      if(s==1) { return ln(sub(1,z)).negeq(); } //Li1(z) = -ln(1-z)
      if(s==0) { return z.div(sub(1,z));      } //Li0(z) = z/(1-z)
      if(s<0) {                                 //for negative s, we take a power series, where each coefficient is found through a sum. (both sums are finite)
        Complex iter=z.div(sq(sub(1,z))); //iterator
        Complex expo=iter.copy();         //exponent = iter ^ k
        Complex sum=zero();               //sum
        double term_init=1;               //equals (-1)^(k-1) * (2k choose k+1) each iteration
        for(int k=1;k<=(1-s)>>1;k++) {    //perform power series
          double coef=0;                  //init coefficient to 0
          double term=term_init;          //term equals (-1)^(j-k) times (2k choose j+k)
          for(int j=1;j<=k;j++) {         //coef=Σ[j=1,k] (-1)^(j-k) * (2k choose j+k) * j^(2ceil(-s/2))
            coef+=term*pow(j,(~s&~1)+2);
            term*=(j-k)/(double)(j+k);
          }
          if((s&1)==1) { coef/=k; }                      //if s odd, divide by k
          sum.addeq(expo.mul(coef));                     //add coef * exponent
          expo.muleq(iter);                              //exponent mults by iterator
          term_init*=-(2*k+1)*(2*k+2)/(double)(k*(k+2));
        }
        if((s&1)==0) { sum.muleq(div(add(1,z),sub(1,z))); } //multiply by this thing if s is even
        return sum;                                         //return sum
      }
    }
    //approximate polylogarithm through a combination of the power series, log series, duplication formula, & reflection formula
    
    Complex u=ln(z), v=u.div(2*Math.PI);                      //u=ln(z), v=ln(z)/(2π)
    Complex lnneg=v.add(iTimes(0.5*csgn(-v.im)));             //ln(-z)/(2π)
    Complex lnsq=v.mul(2).addeq(iTimes(Math.round(-2*v.im))); //ln(z²)/(2π)
    
    //"CONVergence", each # is proportional to the approx convergence time of each alg. If an alg never converges, the denom becomes negative, so
    //we use this max(0,#) trick to turn any negative denom to 0, to represent ∞ convergence time
    double[] conv={2.0D/Math.abs(u.re), 1.0D/Math.max(0,-ln(v).re), 1.0D/Math.max(0,-ln(lnsq).re), 1.0D/Math.max(0,-ln(lnneg).re)};
    
    conv[2]+=conv[3];     //we could initialize them all at once, but it's slightly faster this way
    conv[3]+=0.5*conv[0];
    
    double mins=INF; //minimum convergence rate
    int best=-1;     //index of the best convergence rate
    
    for(int n=0;n<4;n++) if(conv[n]<mins) { mins=conv[n]; best=n; } //sequential search for minimum
    
    Complex ans;
    
    switch(best) {
      case 0 : ans = powPolylog(s,z,20); break;                      //alg 0: power series (combined w/ refl. formula for |z|>1)
      case 1 : ans = logPolylog(s,u,20); break;                      //alg 1: power series of ln(z) (plus an ln(-ln(z)) term)
      case 2 : ans = logPolylog(s,lnsq.mul(2*Math.PI),14).muleq(pow(2,1-s)).subeq(logPolylog(s,lnneg.mul(2*Math.PI),14)); break; //duplication formula w/ 2 log series
      default: ans = powPolylog(s,sq(z)              ,15).muleq(pow(2,1-s)).subeq(logPolylog(s,lnneg.mul(2*Math.PI),15)); break; //duplication formula w/ 1 power & 1 log series
    }
    
    if(z.im==0 && z.re<=1) { ans.im=0; }
    return ans;
  }
  
  public static Complex bernPoly(int n, Complex z) { //computes the nth Bernoulli polynomial for Complex z
    if(n==0) { return one(); } //special case, n=0: return 1
    Complex sum=zero(), expo=((n&1)==0)?one():z.mul(n), iter=sq(z);
    for(int k=n&1;k<n-1;k++) {
      sum.addeq(expo.mul(Bernoulli[n-k]));
      expo.muleq(z).muleq(((double)(n-k))/(k+1));
    }
    sum.addeq(expo.mul(z.div(n).sub(0.5D)));
    return sum;
  }
  
  public static Complex Cl(int s, Complex z) { //computes the generalized Clausen function
    
    if(z.isReal()) {
      Complex li = polylog(s,Cpx.polar(1,z.re));
      switch(s&3) {
        case  0: return new Complex( li.im);
        case  1: return new Complex( li.re);
        case  2: return new Complex(-li.im);
        default: return new Complex(-li.re);
      }
    }
    
    Complex exp = z.mulI().exp(), inv = exp.inv();
    Complex li1 = polylog(s,exp), li2 = polylog(s,inv);
    switch(s&3) {
      case 0: li1.diveqI(); li2.muleqI(); break;
      case 2: li1.muleqI(); li2.diveqI(); break;
      case 3: li1.negeq (); li2.negeq (); break;
    }
    return li1.addeq(li2).scalbeq(-1);
  }
  
  ///////////////////////////// EXPONENTIAL INTEGRALS ///////////////////////////
  
  public static Complex ein(Complex a) { //takes the (adjusted) Exponential integral of complex input a
    if((a.re-0.179D)*(a.re-0.179D)/598.487D+a.im*a.im/194.017D <= 1.0D) {
      Complex sum=zero();        //this is used to store a long summation
      Complex term=a.copy();     //this is used to store each term in the series
      Complex iter=a.mul(-0.5D); //this is what term will multiply by each time
      double sum2=1.0D;          //this will be used to store a sum within the sum
      
      for(int n=1;n<=40;n++) {
        sum.addeq(term.mul(sum2)); //add each term
        
        term.muleq(iter.div(n+1));         //multiply the term by the iterator
        if((n&1)==0) { sum2+=1.0D/(n+1); } //only if n is even, add 1/(n+1) to the nested sum
      }
      
      sum.muleq(exp(a.mul(0.5)));          //multiply the sum by e^(a/2)
      return sum.add(GAMMA); //return the sum plus the mascheroni constant
    }
    
    else {
      double[][] coef={{1,-7.44437068161936701e2D, 1.96396372895146870e5D,-2.37750310125431834e7D, 1.43073403821274637e9D,-4.33736238870432523e10D, 6.40533830574022023e11D,-4.20968180571076940e12D, 1.00795182980368575e13D,-4.94816688199951963e12D, -4.94701168645415960e11D},
              {1,-7.46437068161927678e2D, 1.97865247031583951e5D,-2.41535670165126845e7D, 1.47478952192985465e9D,-4.58595115847765780e10D, 7.08501308149515402e11D,-5.06084464593475077e12D, 1.43468549171581016e13D,-1.11535493509914254e13D},
              {1,-8.13595201151686150e2D, 2.35239181626478200e5D,-3.12557570795778731e7D, 2.06297595146763354e9D,-6.83052205423625007e10D, 1.09049528450362786e12D,-7.57664583257834349e12D, 1.81004487464664575e13D,-6.43291613143049485e12D, -1.36517137670871689e12D},
              {1,-8.19595201151451564e2D, 2.40036752835578778e5D,-3.26026661647090822e7D, 2.23355543278099360e9D,-7.87465017341829930e10D, 1.39866710696414565e12D,-1.17164723371736605e13D, 4.01839087307656620e13D,-3.99653257887490811e13D}};
      
      Complex[] numden={zero(), zero(), zero(), zero()}; //these will give us the numerators and denominators of the f and g auxiliary functions
      
      Complex term, iter=sq(a.inv()); //term and iterator
      
      for(int m=0;m<4;m++) { //loop through all 4 entries in the numden array
        term=one();          //initialize term to 1
        for(double c: coef[m]) {        //loop through the coefficients
          numden[m].addeq(term.mul(c)); //add each term times the coefficient
          term.muleq(iter);             //multiply the term by the iterator
        }
      }
      
      Complex auxf=numden[0].div(numden[1].mul(a)), auxg=numden[2].div(numden[3]).mul(iter); //compute the auxiliary f and g functions
      
      Complex ret=add(auxf,auxg).mul(exp(a)); //this is what we will return
      if(a.im>0 || a.im==0 && a.re<0) { ret.im+=Math.PI; }
      else if(a.im<0)                 { ret.im-=Math.PI; }
      ret.subeq(ln(a)); //subtract the natural logarithm
      
      return ret; //return the result
    }
  }
  
  public static Complex trigInt(Complex a, boolean CorS) { //this takes either the Ci or Si of complex a
    Complex sample=ein(a.mulI()); //first, calculate the regularized Exponential integral of a*i
    
    if(a.im==0) { //if a is real:
      return new Complex(CorS ? sample.re : sample.im); //either return the real or imaginary part of the Ein, depending on if it's the Ci or Si function
    }
    
    if(CorS) { return sample.add(ein(a.divI())).mul(0.5); } //Ci(x)=(Ein(xi)+Ein(-xi))/2
    return sample.sub(ein(a.divI())).mulI(-0.5D);           //Si(x)=(Ein(xi)-Ein(-xi))/(2i)
  }
  
  public static Complex auxInt(Complex a, boolean fOrg) { //this takes the auxiliary f or g function of  complex a
    if(fOrg) { return sub(HALFPI,trigInt(a,false)).mul(cos(a)).add(add(trigInt(a,true),ln(a),GAMMA).mul(sin(a))); }
    else     { return sub(HALFPI,trigInt(a,false)).mul(sin(a)).sub(add(trigInt(a,true),ln(a),GAMMA).mul(cos(a))); }
  }
  
  ///////////////////////////// ELLIPTIC INTEGRALS //////////////////////////////
  
  private static Complex[] AGM_method(Complex k, int type) { //this computes the AGM between k and 1.  If the type is 2, it also computes the derivative of the AGM
    if(k.equals(0)) { return new Complex[] {zero(),complex(-INF)}; } //special case: k==0, return 0 & -∞
    if(k.equals(1)) { return new Complex[] {one (),complex(0.5) }; } //special case: k==1, return 0 & 1/2
    
    Complex a=one(), b=k.copy(), c=zero(), d=one(); //initialize a, b, c, & d to 1, k, 0, 1
    Complex b2, d2;                                 //declare b2 and d2 to store copies of b & d
    
    for(short n=0;n<8;n++) {  //loop through several iterations of the process below
      b2=b.copy();            //copy b
      b=sqrt(mul(a,b));       //set b=geometric mean
      if(type==2) {           //do this step only if type is 2
        d2=d.copy();          //copy d
        d=add(mul(b2,c),mul(a,d)).div(b.mul(2)); //set d = derivative of b
        c=add(c,d2).mul(0.5); //set c = derivative of a
      }
      a=add(a,b2).mul(0.5);   //set a = arithmeic mean
    }
    
    if(absq(a.sub(b))>=1E-10)            { println("AGM Error: " +str(a)+"!="+str(b)); } //if a!=b,
    if(type==2 && absq(c.sub(d))>=1E-10) { println("AGM' Error: "+str(c)+"!="+str(d)); } //or c!=d, it's an error as the series didn't converge fast enough
    
    return new Complex[] {a,c.mul(k)}; //return an array containing the AGM and its derivative (times k)
  }
  
  public static Complex completeF(Complex k) { //returns the complete elliptic integral of the first kind for complex k
    if(k.equals(0)) { return complex(HALFPI); } //special case: if k==0, return π/2
    if(k.equals(1)) { return complex(INF);    } //special case: if k==1, return ∞
    
    return div(HALFPI,AGM_method(sqrt(sub(1,k)),1)[0]); //return π/(2*AGM)
  }
  
  public static Complex completeE(Complex k) { //returns the complete elliptic integral of the second kind for complex k
    if(k.equals(0)) { return complex(HALFPI); } //special case: k==0, return π/2
    if(k.equals(1)) { return one();           } //special case: k==1, return 1
    
    Complex[] AGM=AGM_method(sqrt(sub(1,k)),2); //find the AGM & AGM'
    
    return k.mul(AGM[1]).div(AGM[0]).add(sub(1,k)).div(AGM[0]).mul(HALFPI); //return π/(2*AGM) * (k√(1-k)*(AGM'/AGM)+1-k)
  }
  
  public static Complex completePI(Complex n, Complex k) { //returns the complete elliptic integral of the third kind for complex k and n
    if(k.equals(0)) { return div(HALFPI,sqrt(sub(1,n)));      } //special case: k==0, return π/(2√(1-n))
    if(n.equals(0)) { return completeF(k);                    } //special case: n==0, return F(k)
    if(k.equals(1) || n.equals(1)) { return new Complex(INF); } //special case: k==1 or n==1, return ∞
    
    Complex[] storage=carlson(zero(),sub(1,k),one(),sub(1,n),3); //compute the carlson symmetric R_F and R_J
    
    Complex ans=storage[0].add(mul(storage[1],n.div(3))); //compute R_F+n/3*R_J
    
    return ans; //return the result
  }
  
  private static Complex[] carlson(Complex x, Complex y, Complex z, Complex p, int type) { //this returns the carlson symmetric R_F of x,y,z (and possibly RJ of x,y,z,p if type is 2 or 3)
    Complex mu=add(x,y.add(z)).div(3); //this is the mean between the x, y, and z
    
    double delta=10000*Math.max(Math.max(absq(x.sub(mu)), absq(y.sub(mu))), absq(z.sub(mu))); //this is how far the inputs are from the mean
    
    if(type==3) { delta=Math.max(delta, 10000*absq(p.sub(mu))); }                            //if the type is 3, we need to include p in our results
    
    Complex part=zero(); //this is the sum of all the stuff we add on to the R_D function (even if it's only for type 2 or 3, it still must be declared in this scope)
    double pow4=1.0D;    //this will divide by 4 each iteration, and will be multiplied by a sum we'll perform at the end to find R_D
    
    while(delta > absq(mu)) { //while all terms are far apart, use the following duplication formula,
      Complex s1=sqrt(x), s2=sqrt(y), s3=sqrt(z);        //compute the √ of x, y, and z
      Complex lambda=s1.mul(add(s2,s3)).add(mul(s2,s3)); //compute lambda in our duplication formula
      
      delta*=0.0625D; //divide our square difference by 16
      
      if(type==2||type==3) { //if the type is either 2 or 3, there's an extra step to this
        if(type==2) {
          part.addeq(div(3*pow4, mul(s3,add(s1,s3),add(s2,s3)) )); //type 2: add on a special case of type 3 where p==z
        }
        else        {         //type 3: unlike type 2, this isn't a special case, and we have to give p some special treatment since it isn't z
          Complex s4=sqrt(p); //find the square root of p
          Complex sto=sqrt(mul(sub(p,x),sub(p,y),sub(p,z))); //store this thing to save on multiplications
          part.addeq(atan( sto.div(mul(add(s1,s4),add(s2,s4),add(s3,s4))) ).mul(6*pow4).div(sto)); //add this big ass equation
          p=add(p,lambda).div(4); //perform the "duplication" on p as well
        }
        pow4*=0.25D; //pow4 must divide by 4
      }
      
      x =add(x ,lambda).muleq(0.25);  //set x, y, z, and mu to themselves plus lambda all over 4
      y =add(y ,lambda).muleq(0.25);  //for some reason, this is called a "duplication formula"
      z =add(z ,lambda).muleq(0.25);
      mu=add(mu,lambda).muleq(0.25);
    }
    
    //now we compute the R_F function
    
    Complex z1=x.div(mu).sub(1), z2=y.div(mu).sub(1), z3=z.div(mu).sub(1); //these are the ratio between how far x y & z are from mu and mu itself
    Complex E2=z1.mul(add(z2,z3)).add(mul(z2,z3)), E3=mul(z1,z2,z3);       //E2 & E3 are the sum of all 2nd & 3rd degree products with x,y,z
    
    Complex sum=sub(1,E2.div(10)).sub(E3.div(14)).add(sq(E2).div(24)).add(mul(E2,E3,3.0D/44)).add(sq(E3).mul(3.0D/104)).sub(cub(E2).mul(5.0D/208)).sub(mul(sq(E2),E3,0.0625D)); //approximation
    //1-E2/10+E3/14+E2^2/24+3E2E3/44+3E3^2/104-5E2^3/208-E2^2E3/16
    
    sum.diveq(sqrt(mu)); //divide the sum by the square root of mu, and we now have R_F
    
    if(type==1) { return new Complex[] {sum}; } //if the type is 1, return only the R_F function
    if(type==2) { p=z.copy();                 } //if the type is 2, set p equal to z
    
    //note now the type can only be 2 or 3
    
    //now we compute the R_J function
    
    mu=add(add(x,y),add(z,p.mul(2))).div(5); //change the mu value
    
    z1=x.div(mu).sub(1); z2=y.div(mu).sub(1); z3=z.div(mu).sub(1); //change the z values
    Complex z4=p.div(mu).sub(1);                                   //create a new z value
    
    E2=z1.mul(add(z2,z3)).add(mul(z2,z3)).sub(sq(z4).mul(3));
    E3=z4.mul(z1.mul(add(z2,z3)).add(mul(z2,z3)).sub(sq(z4))).mul(2).add(z1.mul(mul(z2,z3)));
    Complex E4=z4.mul(z1.mul(add(z2,z3)).add(mul(z2,z3))).add(mul(mul(z1,z2),mul(z3,2))).mul(z4);
    Complex E5=mul(mul(z1,z2),mul(z3,sq(z4)));
    
    Complex sum2=sub(1,E2.mul(3.0D/14)).sub(E3.div(6)).sub(E4.mul(3.0D/22)).sub(E5.mul(3.0D/26)).add(sq(E3).mul(9.0D/88)).add(mul(E2,E3,9.0D/52)).add(mul(E2,E4,0.15D)).add(mul(E2,E5,9.0D/68)).add(sq(E3).mul(0.075D)).add(mul(E3,E4,9.0D/68)).sub(cub(E2).div(16)).sub(mul(sq(E2),E3,45.0D/272));
    //1-3E2/14-E3/6-3E4/22-3E5/26+9E3^2/88+9E2E3/52+3E2E4/20+9E2E5/68-E2^3/16-45E2^2E3/272
    
    sum2.muleq(pow4);             //divide the sum by 4^(whatever)
    sum2.diveq(mul(mu,sqrt(mu))); //divide by mu^(3/2)
    sum2.addeq(part);             //add the additional part
    
    return new Complex[] {sum,sum2}; //return the result
  }
  
  public static Complex incompleteF(Complex theta, Complex k) {   //returns the incomplete elliptic F function of complex numbers theta and k
    
    if(k.equals(0)) { return theta.copy(); } //k==0: the integral evaluates to theta
    if(k.equals(1)) {                        //k==1: the integral simplifies, but isn't always defined
      if(theta.re>= HALFPI) { return complex( INF); } //theta>=π/2: return ∞
      if(theta.re<=-HALFPI) { return complex(-INF); } //theta<=-π/2: return -∞
      return ln(add(tan(theta),sec(theta)));          //otherwise, return ln(sec(theta)+tan(theta))
    }
    if(Math.abs(theta.im)>100) {                               //theta has large imaginary part: approximate the integral with two complete elliptic integrals
      double adjust=Math.round((theta.re-0.5*arg(k))/Math.PI); //find how many times π goes into theta
      Complex ans=(theta.im>0) ? completeF(sub(1,k)).mulI() : completeF(sub(1,k)).divI(); //set our answer to ±K(1-k)i
      if(adjust!=0) { ans.addeq(completeF(k).mul(2*adjust)); } //if π goes into theta, add on K(k) times 2*adjust
      return ans;                                              //return the result
    }
    
    double adjust=Math.round(theta.re/Math.PI); //find how many times π goes into theta
    Complex inp=theta.sub(Math.PI*adjust);      //our input is theta minus π times our adjustment
    
    if(inp.equals(0))       { return completeF(k).mul(2*adjust);   } //if the modulo is 0 or -π/2, we can finish the calculation with completeF
    if(inp.equals(-HALFPI)) { return completeF(k).mul(2*adjust-1); }
    
    Complex sum=carlson(sq(cos(inp)),sub(1,sq(sin(inp)).mul(k)),one(),zero(),1)[0]; //compute the RF of cos²,1-ksin²,1
    
    sum.muleq(sin(inp)); //multiply by the sine
    
    if(adjust!=0) { sum.addeq(completeF(k).mul(2*adjust)); } //add F(k) times how many times π goes into theta
    
    return sum; //return the result
  }
  
  public static Complex incompleteE(Complex theta, Complex k) { //returns the incomplete elliptic E function of complex theta and k
    
    if(k.equals(0)) { return theta.copy(); } //k==0: just return theta
    if(k.equals(1)) {                        //k==1: return the integral of |cos(x)|dx
      return sin(theta).mul(Math.IEEEremainder(theta.re/Math.PI+0.5,2)>0 ? 1 : -1).sub(2*Math.round(-theta.re/Math.PI));
    }
    if(Math.abs(theta.im)>100) {                               //theta has large imaginary part: approximate with exponents
      Complex ans=mul(exp(theta.im>0 ? theta.divI() : theta.mulI()),sqrt(k),0.5); //take √(k)e^(theta/±i)/2
      ans=(theta.im>0 == ans.isRoot()) ? ans.mulI() : ans.divI();                 //mult/div by i, depending on csgn, and on sgn of imag part
      //Most of the equation is solved. This always evaluates to something huge, thus the rest of the approximation is insignificant...
      
      if(ans.re==0 || ans.im==0) { //...unless either the re or im is 0
        Complex term=sub(completeF(sub(1,k)),completeE(sub(1,k))); //compute F(1-k)-E(1-k)
        term=theta.im>0 ? term.mulI() : term.divI();               //multiply by ±i
        
        double adjust=Math.round((theta.re-0.5*arg(k))/Math.PI);  //find how many E(k)'s to tack on
        if(adjust!=0) { term.addeq(completeE(k).mul(2*adjust)); } //if it goes in at all, tack on those E(k)'s
        
        ans.addeq(term); //add this term to our integral
      }
      
      return ans; //return the result
    }
    
    double adjust=Math.round(theta.re/Math.PI); //find how many times π goes into theta
    Complex inp=theta.sub(Math.PI*adjust);      //our input is theta minus π times our adjustment
    
    if(inp.equals(0))       { return completeE(k).mul(2*adjust);   } //if the modulo is 0 or -π/2, we can finish the calculation with completeE
    if(inp.equals(-HALFPI)) { return completeE(k).mul(2*adjust-1); }
    
    Complex sins=sin(inp); //compute the sine
    
    Complex[] storage=carlson(sq(cos(inp)),sub(1,mul(sq(sins),k)),one(),zero(),2); //find R_F and R_J
    
    Complex sum=storage[0], sum2=storage[1]; //store these forms as two variables
    
    sum2.muleq(sq(sins).mul(k.div(3)));
    
    sum.subeq(sum2);                       //subtract the other sum
    sum.muleq(sins);                       //multiply entire sum by sin(theta)
    if(adjust!=0) {
      sum.addeq(completeE(k).mul(2*adjust)); //add the complete elliptic E times how many times π goes into theta
    }
    
    return sum; //return the result
  }
  
  //////////////////////////// BESSEL /////////////////////////////
  
  public static Complex besselJ(Complex a, Complex z) { //the Bessel J function
    if(0.00585385632d*z.re*z.re + 0.00242167992d*z.im*z.im < 1) {
      return besselJ_taylor(a, z, 32); //if close to 0, return a Taylor's series
    }
    return besselJ_asymp(a, z, 32); //otherwise, return an asymptotic expansion
  }
  
  public static Complex besselY(Complex a, Complex z) { //the Bessel Y function
    if(0.00585385632d*z.re*z.re + 0.00242167992d*z.im*z.im < 1) {
      return besselJY_taylor(a, z, 32)[1]; //if close to 0, return a Taylor's series (kind of)
    }
    return besselY_asymp(a, z, 32); //otherwise, return an asymptotic expansion
  }
  
  public static Complex[] besselJY(Complex a, Complex z) { //both Bessel functions
    if(0.00585385632d*z.re*z.re + 0.00242167992d*z.im*z.im < 1) {
      return besselJY_taylor(a, z, 32); //if close to 0, return their Taylor's series
    }
    return besselJY_asymp(a, z, 32); //otherwise, return their asymptotic expansion
  }
  
  public static Complex besselI(Complex a, Complex z) { //the modified Bessel I function
    return besselJ(a, z.mulI()) .muleq(exp(a.mulI(-HALFPI))); //take J of zi, then divide by i^a
  }
  
  public static Complex besselK(Complex a, Complex z) { //the modified Bessel K function
    if(z.im>=0) { return besselH2(a,z.mulI()).muleq(exp(a.add(1).mulI(-HALFPI))); } //it should be noted that both of these are equivalent for z.re>0
    else        { return besselH1(a,z.mulI()).muleq(exp(a.add(1).mulI( HALFPI))); }
  }
  
  public static Complex besselH1(Complex a, Complex z) { //the Hankel function #1
    Complex[] jy = besselJY(a,z); //compute J and Y
    return jy[0].addeq(jy[1].muleqI()); //return J+Yi
  }
  
  public static Complex besselH2(Complex a, Complex z) { //the Hankel function #2
    Complex[] jy = besselJY(a,z); //compute J and Y
    return jy[0].subeq(jy[1].muleqI()); //return J-Yi
  }
  
  private static Complex besselJ_taylor(Complex a, Complex z, int stop) { //approximates the Bessel J function w/ a Taylor's series
    
    if(a.isInt() && a.re<0) { //special case: a is a negative integer
      return besselJ_taylor(a.neg(),z,stop).muleq(a.re%2==0 ? 1 : -1); //J(a,z) = (-1)^a*J(-a,z)d
    }
    
    Complex sum = zero();               //the sum
    Complex term = (z.mul(0.5)).pow(a); //each term in the summation
    term.diveq(factorial(a));           //initially just (z/2)^a/a!
    Complex mul = z.mul(0.5).sq().negeq(); //one of the things the term multiplies by each iteration, -z^2/4
    for(int m=0;m<=stop;m++) { //loop through all terms in the sum
      sum.addeq(term);         //add each term
      term.muleq(mul).diveq(a.add(m+1).mul(m+1)); //update to the next term = (-1)^m(z/2)^(2m+a)/(m!(a+m)!)
    }
    return sum; //return result
  }
  
  private static Complex[] besselJY_taylor(Complex a, Complex z, int stop) { //approximates the Bessel J and Y functions w/ a power series
    if(a.isInt()) { //special case: if a is an integer:
      return besselJY_taylor((int)a.re, z, stop); //use the specialized function for when a is an integer
    }
    
    //otherwise, we compute Y(a,z) as (J(a,z)cos(pi*a)-J(-a,z))/sin(pi*a)
    Complex[] trig = a.mul(Math.PI).fsincos(); //find sin and cos of pi*a
    
    Complex sum1 = zero(), sum2 = zero(); //these store both sums to make both bessel J functions
    Complex term1 = (z.mul(0.5)).pow(a).diveq(factorial(a));      //each term in each summation, initially just (z/2)^(+-a)/((+-a)!)
    //Complex term2 = (z.mul(0.5)).pow(a.neg()).diveq(factorial(a.neg())); //TODO have this term be solved in terms of the other term
    Complex term2 = trig[0].div(mul(Math.PI,term1,a));            //however, using reflection rules, we can solve for the second one in terms of the first, making this slightly faster
    Complex mul = z.mul(0.5).sq().negeq(); //one of the things both terms multiply by each iteration, -z^2/4
    for(int m=0;m<=stop;m++) { //loop through all terms in the sum
      sum1.addeq(term1);       //add up each term
      sum2.addeq(term2);
      
      term1.muleq(mul).diveq(add(m+1,a).mul(m+1)); //update to the next term = (-1)^m(z/2)^(2m+-a)/(m!(m+-a)!)
      term2.muleq(mul).diveq(sub(m+1,a).mul(m+1));
    }
    
    //return besselJ_taylor(a,z,stop).mul(trig[1]).subeq(besselJ_taylor(a.neg(),z,stop)).diveq(trig[0]); //do this
    return new Complex[] {sum1, sum1.mul(trig[1]).subeq(sum2).diveq(trig[0])}; //lastly, plug in all the stuff and return J and Y
  }
  
  private static Complex[] besselJY_taylor(int a, Complex z, int stop) {
    if(a<0) {
      Complex[] result = besselJY_taylor(-a,z,stop); //a is negative: negate a,
      if((a&1)==1) { result[0].negeq(); result[1].negeq(); } //multiply by (-1)^a
      return result; //return the result
    }
    
    //to compute the Bessel Y function, we have to compute 3 sums and add/subtract them together
    
    Complex termInit = z.mul(0.5).pow(a).diveq(factorial(a)); //First, let's compute this. Trust me, it'll save us on powers and, more importantly, gamma functions
    
    //first, we compute the sum of a bunch of terms with negative powers:
    //(well, the powers aren't all negative, these are just powers less than a)
    Complex sum1 = zero();          //the sum itself
    Complex term = termInit.mul(a); //the term
    Complex mul = div(4,z.sq()); //one of the things the term multiplies by each time
    term.muleq(mul);             //initialize the term to (z/2)^(a-2)/(a-1)!
    for(int k=0;k<a;k++) { //loop through all a terms
      sum1.addeq(term);                      //add each term in the series
      term.muleq((k+1)*(a-k-1)).muleq(mul); //update each term, should be (z/2)^(a-2k-2) * k!/(a-k-1)!
    }
    
    //finally, the last 2 sums:
    Complex sum2 = zero(); //a sum of powers >= a
    Complex j    = zero(); //and a sum of powers >= a, multiplied by ln(z/2). This will be the same as 2J(a,z)ln(z/2)
    
    term = termInit;               //the term, initialized to (z/2)^a/a!
    mul = z.mul(0.5).sq().negeq(); //part of what we multiply by each time, -z^2/4
    double harmonic = -2*GAMMA;    //and, the sum of two harmonic series, each of which get initialized to -gamma because that's just how it works
    for(int k=1;k<=a;k++) { harmonic += 1d/k; } //initialize the harmonic series term
    
    for(int m=0;m<=stop;m++) { //loop through the infinite remaining iterations until we reach the point at which we agreed to stop
      sum2.addeq(term.mul(harmonic));  //each iteration, the sum adds the term times the harmonic sum
      j.addeq(term);                   //meanwhile, the J sum just adds the term bare butt
      
      double inv = 1d/((m+1)*(a+m+1)); //precompute a reciprocal to save on divisions
      term.muleq(mul).muleq(inv);      //each iteration, the term = (-1)^m*(z/2)^(2m+a)/(m!(a+m)!), so we multiply by -(z/2)^2 / ((m+1)(a+m+1)
      harmonic += (a+2*m+2)*inv;       //each iteration, the harmonic sum = digamma(m+1)+digamma(a+m+1), so we add 1/(m+1)+1/(a+m+1) = (a+2m+2)/((m+1)(a+m+1))
    }
    
    Complex y = j.mul(z.mul(0.5).ln()).muleq(2) .subeq(sum1).subeq(sum2).diveq(Math.PI); //multiply the j term by the 2ln(z/2), then combine the 3 sums and divide by pi
    
    return new Complex[] {j,y}; //return the resulting j and y
  }
  
  private static Complex besselJ_asymp(Complex a, Complex z, int stop) { //approximates the Bessel J function w/ an asymptotic series
    if(z.re<0) { //if the real part is negative:
      //reflection formula: J(a,z) = J(a,-z)*(-1)^+-a, where +-1 is csgn(z/i)
      Complex j = besselJ_asymp(a,z.neg(),stop);             //compute this on -z
      if(a.isInt()) { return a.re%2==0 ? j : j.neg(); }      //if integer, the reflection is simple
      return j.muleq(exp(a.mulI(z.im>=0?Math.PI:-Math.PI))); //otherwise, (-1)^a isn't as simple
    }
    
    Complex inv = z.inv(); //compute 1/z
    Complex[] trig = z.sub(a.mul(0.5).addeq(0.25).muleq(Math.PI)).fsincos(); //compute sine and cosine of z-(2a+1)π/4
    Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
    return trig[1].muleq(pq[0]).subeq(trig[0].muleq(pq[1])).muleq(sqrt(inv.div(HALFPI))); //finally, take (cos*P-sin*Q)*√(2/(πz))
  }
  
  private static Complex besselY_asymp(Complex a, Complex z, int stop) { //approximates the Bessel Y function w/ an asymptotic series
    if(z.re<0) { //if the real part is negative:
      //reflection formula: Y(a,z) = Y(a,-z)*(-1)^-+a +- 2i*cos(pi*a)*J(a,-z), where +-1 is csgn(z/i)
      
      Complex inv = z.inv().negeq(); //compute -1/z
      Complex[] trig = z.add(a.mul(0.5).addeq(0.25).muleq(Math.PI)).negeq().fsincos(); //compute the sine and cosine of -z-(2a+1)π/4
      Complex[] trig2 = a.mul(Math.PI).fsincos();                                      //also compute the sine and cosine of πa
      Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
      int csgn = z.im>=0 ? 1 : -1;         //compute csgn(z/i)
      
      Complex y = pq[0].mul(trig[0]).addeq(pq[1].mul(trig[1])); //compute Y (ignoring the (pi/2*z)^(-1/2) term)
      Complex j = pq[0].mul(trig[1]).subeq(pq[1].mul(trig[0])); //compute J
      return y.muleq(trig2[1].sub(trig2[0].mulI(csgn))) .addeq(mul(j, new Complex(0,2*csgn),trig2[1])) .muleq(sqrt(inv.div(HALFPI))); //return y*(-1)^(-+a) +- j*2icos (making sure to include the (pi/2*z)^(-1/2) term)
    }
    
    //otherwise, we evaluate it normally
    Complex inv = z.inv(); //compute 1/z
    Complex[] trig = z.sub(a.mul(0.5).addeq(0.25).muleq(Math.PI)).fsincos(); //compute sine and cosine of z-(2a+1)π/4
    Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
    return trig[0].muleq(pq[0]).addeq(trig[1].muleq(pq[1])).muleq(sqrt(inv.div(HALFPI))); //finally, take (sin*P+cos*Q)*√(2/(πz))
  }
  
  private static Complex[] besselJY_asymp(Complex a, Complex z, int stop) { //approximates both Bessel functions w/ an asymptotic series
    if(z.re<0) { //if the real part is negative:
      //reflection formula: Y(a,z) = Y(a,-z)*(-1)^-+a +- 2i*cos(pi*a)*J(a,-z), where +-1 is csgn(z/i)
      
      Complex inv = z.inv().negeq(); //compute -1/z
      Complex[] trig = z.add(a.mul(0.5).addeq(0.25).muleq(Math.PI)).negeq().fsincos(); //compute the sine and cosine of -z-(2a+1)π/4
      Complex[] trig2;
      if(a.isInt()) { trig2 = new Complex[] {zero(), new Complex(a.re%2==0?1:-1)}; }
      else          { trig2 = a.mul(Math.PI).fsincos();                            }   //also compute the sine and cosine of πa
      Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
      int csgn = z.im>=0 ? 1 : -1;         //compute csgn(z/i)
      
      Complex y = pq[0].mul(trig[0]).addeq(pq[1].mul(trig[1])); //compute Y (ignoring the (pi/2*z)^(-1/2) term)
      Complex j = pq[0].mul(trig[1]).subeq(pq[1].mul(trig[0])); //compute J
      Complex root = sqrt(inv.div(HALFPI));                     //compute the square root term
      return new Complex[] {mul(j, trig2[1].add(trig2[0].mulI(csgn)), root),
                            y.mul(trig2[1].sub(trig2[0].mulI(csgn))) .addeq(mul(j, new Complex(0,2*csgn),trig2[1])) .muleq(root)};
      //return  j*(-1)^(+-a)  and  y*(-1)^(-+a) +- j*2icos
    }
    
    //otherwise, we evaluate it normally
    Complex inv = z.inv(); //compute 1/z
    Complex[] trig = z.sub(a.mul(0.5).addeq(0.25).muleq(Math.PI)).fsincos(); //compute sine and cosine of z-(2a+1)π/4
    Complex[] pq = besselPQ(a,inv,stop); //compute the Bessel P and Q functions
    Complex root = sqrt(inv.div(HALFPI)); //compute the square root term
    return new Complex[] {trig[1].mul(pq[0]).subeq(trig[0].mul(pq[1])).muleq(root),
                          trig[0].mul(pq[0]).addeq(trig[1].mul(pq[1])).muleq(root)};
    //finally, return (cos*P-sin*Q)*√(2/(πz)) and (sin*P+cos*Q)*√(2/(πz))
  }
  
  private static Complex[] besselPQ(Complex a, Complex inv, int stop) { //both supplementary functions used to construct the asymptotic series
    Complex p = zero(), q = zero(); //init both sums to 0
    Complex term = one();           //the term that p or q adds each time
    Complex mul = inv.mulI(0.5d);  //one of the things we multiply by each time
    double prevMult = Mafs.INF;
    for(int n=0;n<=stop;n++) {
      if((n&1)==0) { p.addeq(term); } //for even iterations, add to p
      else         { q.addeq(term); } //for  odd iterations, add to q
      
      Complex multiplier = a.sq().subeq((n+0.5)*(n+0.5)).muleq(mul).diveq(n+1); //compute what we must multiply our term by
      if(multiplier.absq()>prevMult && multiplier.absq()>1) { break; } //if our multiplier is bigger than 1, quit the loop
      term.muleq(multiplier);            //otherwise, multiply the term by the mutiplier and go to the next iteration
      
      prevMult = multiplier.absq();
      
      //each iteration, the term = (a+n-1/2)!/((a-n-1/2)!n!) * (inv*i/2)^n
    }
    return new Complex[] {p, q.divI()}; //return p and q (with q divided by i)
  }
  
  //////////////////////////// OTHER //////////////////////////////
  
  
}

static long gcf(long... inps) { //computes the greatest common factor of a set of inputs
  long inp[] = new long[inps.length];
  System.arraycopy(inps,0,inp,0,inps.length);
  
  for(int n=0;n<inp.length;n++) { if(inp[n]<0) { inp[n] = -inp[n]; } } //first, we perform the trivial step of negating all negative inputs
  
  //throughout this process, we will want all 0s at the end of the array. We will pretend those zeros aren't there and the array is shorter. z is the length of said pretend array
  int z = inp.length;         //initialize z to the length of the array
  z = moveZerosToEnd(inp, z); //move all 0 elements to the end of the array, all while updating z
  
  //now, all 0s are at the end of the array, and z is the length the array would be if we cut out the zeros
  if(z==0) { throw new ArithmeticException("Answer is Infinite"); } //the GCF of an empty array or an array of all 0s would be infinite
  
  //now, we have to divide each element by the greatest power of 2 that divides them all (then multiply back by that at the end)
  int shift = 0; //shift is said power of 2
  long or = 0; for(int n=0;n<z;n++) { or |= inp[n]; } //take the bitwise or of all non-zero elements
  while((or&1)==0)     { or>>>=1; ++shift; } //continually right shift our or & increment our shift until the or is odd
  for(int n=0;n<z;n++) { inp[n]>>>=shift; } //lastly, right shift all elements by said shift
  
  //the next step is that we have to take all even numbers and divide by the largest divisible power of 2. Remember, at least one of these numbers is odd, so the GCF isn't divisible by 2
  for(int n=0;n<z;n++) { while((inp[n]&1)==0) { inp[n]>>>=1; } } //take each element, divide by 2 until odd
  
  
  //now, for the main bulk of the algorithm: we perform a combination of subtracting elements from eachother, dividing elements by 2, and moving 0s to the end until all elements but one are 0
  while(z!=1) { //perform the following steps repeatedly until there's only one non-zero element
    for(int n=0;n<z-1;n++) { //loop through all pairs of sequential elements in the array
      if(inp[n]<inp[n+1]) { long t=inp[n]; inp[n]=inp[n+1]; inp[n+1]=t; } //if the 1st is smaller than the 2nd, swap places
      
      inp[n] = (inp[n]-inp[n+1])>>>1; //replace a with (a-b)/2 (making it smaller w/out changing the GCF)
      if(inp[n]==0) { inp[n]=inp[z-1]; inp[z-1]=0; z--; n--; continue; } //if the element is now 0, move it to the end & restart this iteration
      while((inp[n]&1)==0) { inp[n]>>>=1; } //while this element is even, divide by 2
      if(inp[n]>inp[n+1]) { long t=inp[n]; inp[n]=inp[n+1]; inp[n+1]=t; } //if the 1st is larger than the 2nd, swap places
    }
  }
  
  return inp[0]<<shift; //finally, return the only remaining non-zero element (left shifted by that shift we computed earlier)
}

static int moveZerosToEnd(long[] inps, int z) { //moves all 0 elements to the end of the array, all indices >= z are 0, we return our new value of z after the elements have been moved
  for(;z>0&&inps[z-1]==0;z--) { } //decrement z until the element before it is non-zero (or until there is no element before it)
  for(int n=0;n<z;n++) { //loop through all inputs before z
    if(inps[n]==0) {     //if 0:
      z--; inps[n]=inps[z]; inps[z]=0; //swap with the last non-zero element and decrement z
      for(;z>0&&inps[z-1]==0;z--) { }  //decrement z until the element before it is non-zero (or until there's no element before it)
    }
  }
  return z; //return our new z
}

/*static String primeFactor(long f) { //computes the prime factorization
  if(f<=0) { return "Can only factor positive integers"; }
  if(f==1) { return "Empty Product"; }
  
  String result = ""; //initialize to empty string
  
  //first, check if 2, 3, 5, or 7 are prime factors
  byte pow = 0; while((f&1)==0) { f>>=1; pow++; } //first 2 (shift right until last digit is 1)
  if(pow!=0) { result += "*2"+(pow==1 ? "" : "^"+pow); }
  pow = 0; while(0x5555555555555555l*(f+1) >= 0x2AAAAAAAAAAAAAABl) { f*=0xAAAAAAAAAAAAAAABl; pow++; } //then 3 (sped up using modular arithmetic)
  if(pow!=0) { result += "*3"+(pow==1 ? "" : "^"+pow); }
  pow = 0; while(0x3333333333333333l*(f+2) >= 0x4CCCCCCCCCCCCCCDl) { f*=0xCCCCCCCCCCCCCCCDl; pow++; } //then 5 (sped up using modular arithmetic)
  if(pow!=0) { result += "*5"+(pow==1 ? "" : "^"+pow); }
  pow = 0; while(0x6DB6DB6DB6DB6DB7l*(f+1)-1 >= 0x5B6DB6DB6DB6DB6Dl) { f*=0x6DB6DB6DB6DB6DB7l; pow++; } //then 7 (sped up using modular arithmetic)
  if(pow!=0) { result += "*7"+(pow==1 ? "" : "^"+pow); }
  
  if(f==1) { return result.substring(1); } //if there are no more factors, we can stop now and just return what we have (without the initial times sign, of course)
  
  //next, we loop through all possible factors between 11 and sqrt(f), ignoring all numbers divisible by 2, 3, 5, or 7. In doing so, we cut out 27/35 of the numbers over that range, and only have to explore 22.9% of those numbers
  long root = (long)Math.floor(Math.sqrt(f)); //compute the square root of f
  byte option = 2; //this represents the 48 possible values n could be mod 210
  for(long n=11;n<=root;) {
    pow = 0; while(f%n==0) { f/=n; pow++; } //count how many times f is divisible by n
    if(pow!=0) { //if non-zero:
      result += "*"+n+(pow==1 ? "" : "^"+pow); //attach this to our prime factorization
      root = (long)Math.floor(Math.sqrt(f));   //compute the square root once again
    }
    
    //now, our next value for n depends on our option:
    switch(option&127) { //switch the option (ignore the sign bit)
      case  0: n+=2; option^=-128; break; //for option  0, we increase by 2 and switch directions
      case 24: n+=4; option^=-128; break; //for option 24, we increase by 4 and switch direcitons
      
      case 2: case 4: case  7: case 10: case 14: case 17: case 23: n+=2; break; //for these options, increase by 2
      case 3: case 5: case  9: case 11: case 16: case 19: case 22: n+=4; break; //for these options, increase by 4
      case 6: case 8: case 12: case 13: case 15: case 18: case 20: n+=6; break; //for these options, increase by 6
      
      case 21: n+= 8; break; //increase by 8
      case  1: n+=10; break; //increase by 10
    }
    if(option<0) { option--; } else { option++; } //If negative, decrease. If positive, increase
  }
  
  if(result.length()==0) { return f+""; } //if there were no prime factors, this number is prime and you should just return the number
  
  if(f!=1) { result += "*"+f; } //if there is still one prime factor left, tack that on at the end
  return result.substring(1);   //finally, remove the initial times sign and then return the result
}*/

static class PrimeFactorization {
  java.util.TreeMap<Long, Integer> factors;
  
  PrimeFactorization(long f) {
    factors = primeFactor(f);
  }
  
  static java.util.TreeMap<Long, Integer> primeFactor(long f) { //computes the prime factorization (returns an arraylist of longs and their powers
    if(f==0) { return null; } //0: undefined, since 0 can factor out all numbers
    if(f==1) { return new java.util.TreeMap<Long, Integer>(); } //1: empty product
    
    java.util.TreeMap<Long, Integer> factor = new java.util.TreeMap<Long, Integer>(); //initialize prime factorization list
    
    if(f<0) { factor.put(-1l,1); f=-f; }
    
    //first, check if 2, 3, 5, or 7 are prime factors
    int pow = 0; while((f&1)==0) { f>>=1; pow++; } //first 2 (shift right until last digit is 1)
    if(pow!=0) { factor.put(2l,pow); }
    pow = 0; while(0x5555555555555555l*(f+1) >= 0x2AAAAAAAAAAAAAABl) { f*=0xAAAAAAAAAAAAAAABl; pow++; } //then 3 (sped up using modular arithmetic)
    if(pow!=0) { factor.put(3l,pow); }
    pow = 0; while(0x3333333333333333l*(f+2) >= 0x4CCCCCCCCCCCCCCDl) { f*=0xCCCCCCCCCCCCCCCDl; pow++; } //then 5 (sped up using modular arithmetic)
    if(pow!=0) { factor.put(5l,pow); }
    pow = 0; while(0x6DB6DB6DB6DB6DB7l*(f+1)-1 >= 0x5B6DB6DB6DB6DB6Dl) { f*=0x6DB6DB6DB6DB6DB7l; pow++; } //then 7 (sped up using modular arithmetic)
    if(pow!=0) { factor.put(7l,pow); }
    
    if(f==1) { return factor; } //if there are no more factors, we can stop now and just return what we have
    
    //next, we loop through all possible factors between 11 and sqrt(f), ignoring all numbers divisible by 2, 3, 5, or 7. In doing so, we cut out 27/35 of the numbers over that range, and only have to explore 22.9% of those numbers
    long root = (long)Math.floor(Math.sqrt(f)); //compute the square root of f
    byte option = 2; //this represents the 48 possible values n could be mod 210
    for(long n=11;n<=root;) {
      pow = 0; while(f%n==0) { f/=n; pow++; } //count how many times f is divisible by n
      if(pow!=0) { //if non-zero:
        factor.put(n,pow); //attach this to our prime factorization
        root = (long)Math.floor(Math.sqrt(f)); //compute the square root once again (so we know to stop even sooner)
      }
      
      //now, our next value for n depends on our option:
      switch(option&127) { //switch the option (ignore the sign bit)
        case  0: n+=2; option^=-128; break; //for option  0, we increase by 2 and switch directions
        case 24: n+=4; option^=-128; break; //for option 24, we increase by 4 and switch direcitons
        
        case 2: case 4: case  7: case 10: case 14: case 17: case 23: n+=2; break; //for these options, increase by 2
        case 3: case 5: case  9: case 11: case 16: case 19: case 22: n+=4; break; //for these options, increase by 4
        case 6: case 8: case 12: case 13: case 15: case 18: case 20: n+=6; break; //for these options, increase by 6
        
        case 21: n+= 8; break; //increase by 8
        case  1: n+=10; break; //increase by 10
      }
      if(option<0) { option--; } else { option++; } //If negative, decrease. If positive, increase
    }
    
    if(f!=1) { factor.put(f,1); } //whatever's left has to be added to the prime factorization (unless it's 1, which can happen if the largest factor has a multiplicity greater than 1)
    return factor;
  }
  
  @Override
  String toString() { //outputs the prime factorization as a string
    if(factors==null) { return "0"; }
    
    String result = "";
    boolean init = true;
    for(Map.Entry<Long,Integer> entry : factors.entrySet()) {
      long prime = entry.getKey();
      int exponent = entry.getValue();
      
      if(!init) { result+="*"; }
      result+=prime;
      if(exponent > 1) { result+="^"+exponent; }
      init = false;
    }
    
    return result;
  }
}

static long[] bezout(long a, long b) { //Using extended Euclidean algorithm, returns the result of Bezout's identity, ax+by=gcf(a,b), returning an array {x,y,gcf(a,b)}
  long[] prev = {0,a,1,0}; //two arrays, containing (in order) q, r, s, t
  long[] curr = {0,b,0,1};
  long[] temp; //temporary (storage) array
  
  while(curr[1]!=0) {
    prev[0]=prev[1]/curr[1]; //compute quotient
    prev[1]-=prev[0]*curr[1]; //remainder
    prev[2]-=prev[0]*curr[2]; //s
    prev[3]-=prev[0]*curr[3]; //t
    
    temp = curr; curr = prev; prev = temp; //swap temp and curr
  }
  
  //finally, return x, y, and gcf
  if(prev[1]<0) { return new long[] {-prev[2],-prev[3],-prev[1]}; } //if gcf is negative, negate the result
  return                 new long[] { prev[2], prev[3], prev[1]};
}

static long modInv(long x, long m) { //find the inverse of x mod m
  if((m&(m-1))==0) { //modulo is a power of 2 (there's a faster method):
    if((x&1)==0) { //if not even, cannot invert
      throw new RuntimeException("Cannot find inverse of "+x+" mod "+m+", they aren't coprime (they're both even)");
    }
    long res = 2-x, prod = x*(2-x); //otherwise, we use the Newton-Raphson method. It requires at most 6 iterations
    while(prod!=1) {
      res *= 2-prod;
      prod = x*res;
    }
    return res&(m-1); //return result (but forced to be positive)
  }
  
  long[] b = bezout(x,m); //perform the extended Euclidean algorithm
  if(b[2]!=1l) { throw new RuntimeException("Cannot find inverse of "+x+" mod "+m+", they aren't coprime (gcf="+b[2]+")"); } //not coprime: output error
  return Math.floorMod(b[0],m); //otherwise, return the result (modulo m)
}

static long totient(long x) { //computes the Euler's totient function
  PrimeFactorization factor = new PrimeFactorization(x); //first, compute its prime factorization
  
  for(Map.Entry<Long, Integer> entry : factor.factors.entrySet()) { //loop through all the prime factors
    long prime = entry.getKey();
    if(prime!=-1) { x *= 1-1d/prime; }
  }
  return x;
}

static ArrayList<double[]> stirling1 = new ArrayList<double[]>(); //arraylist containing the stirling numbers of the first kind
static ArrayList<double[]> stirling2 = new ArrayList<double[]>(); //arraylist containing the stirling numbers of the second kind

static double stirling1(int n, int k) { //gets the stirling number of the first kind
  if(k<0 || k>n) { return 0; } //out of bounds: return 0
  for(int r=stirling1.size();r<=n;r++) { //iteratively generate each missing row
    double[] row = new double[r+1]; //initialize row
    
    if(r!=0) { row[0] = 0; } //make 0th element 0
    row[r] = 1;              //make last element 1
    
    for(int j=1;j<r;j++) { //compute the rest of the elements recursively
      row[j] = stirling1.get(r-1)[j-1] + (r-1)*stirling1.get(r-1)[j]; //this is the recurrence relation
    }
    stirling1.add(row); //add the row to the stirling triangle
  }
  return stirling1.get(n)[k]; //return the value here
}

static double stirling2(int n, int k) { //gets the stirling number of the second kind
  if(k<0 || k>n) { return 0; } //out of bounds: return 0
  for(int r=stirling2.size();r<=n;r++) { //iteratively generate each missing row
    double[] row = new double[r+1]; //initialize row
    
    if(r!=0) { row[0] = 0; } //make 0th element 0
    row[r] = 1;              //make last element 1
    
    for(int j=1;j<r;j++) { //compute the rest of the elements recursively
      row[j] = j*stirling2.get(r-1)[j] + stirling2.get(r-1)[j-1]; //this is the recurrence relation
    }
    stirling2.add(row); //add the row to the stirling triangle
  }
  return stirling2.get(n)[k]; //return the value here
}

/*static long modPow(long a, long b, long m) { //computes a to the b modulo m
  if(a==Long.MIN_VALUE) { long root = modPow(modInv(a,m),0x4000000000000000l,m); return Math.floorMod(root*root,m); } //special case: exponent is minimum integer, raise to the power of -2^62, then square result.
  //NOTE: without the above code, raising a number to the power of -2^63 would result in a stack overflow, since a would be repeatedly negated (to no effect) and z would be repeatedly inverted
  
  if(b<0) { return modPow(modInv(a,m),-b,m); } //a is negative: return (1/z)^(-a)
  //general case:
  long ans = 1;        //return value: a^b (init to 1 in case b==0)
  long ex=b;           //copy of b
  long iter=a%m;       //a ^ (2 ^ (whatever digit we're at))
  boolean inits=false; //true once ans is initialized (to something other than 1)
  
  while(ex!=0) {                               //loop through all b's digits (if b==0, exit loop, return 1)
    if((ex&1)==1) {
      if(inits) { ans = (ans*iter)%m;   } //mult ans by iter ONLY if this digit is 1
      else      { ans=iter; inits=true; } //if ans still = 1, set ans=iter (instead of multiplying by iter)
    }
    ex >>= 1;                               //remove the last digit
    if(ex!=0)   { iter = (iter*iter)%m; } //square the iterator (unless the loop is over)
  }
  
  return Math.floorMod(ans,m); //return the result
}*/

static long modPow(long a, long b, long m) { //computes a to the b modulo m
  return BigInteger.valueOf(a).modPow(BigInteger.valueOf(b), BigInteger.valueOf(m)).longValue();
}

static long modMult(long a, long b, long m) { //computes a * b mod m
  return BigInteger.valueOf(a).multiply(BigInteger.valueOf(b)).mod(BigInteger.valueOf(m)).longValue();
}

static Long discLog_babyGiant(long base, long num, long mod, long phi) {
  
  HashMap<Long,Long> powMap = new HashMap<Long,Long>();
  
  long root1 = (long)Math.round(Math.sqrt(phi));    //the size of the big step
  long root2 = (phi+root1-1)/root1; //the number of big steps in the cycle (rounded up)
  
  //first, we populate the power map with powers
  long bigStep = modPow(base,root1,mod);
  long pow = 1;
  for(long n=0;n<root2;n++) {
    powMap.put(pow,n);
    pow = modMult(pow,bigStep,mod);
  }
  
  long inv = modInv(base,mod);
  for(int n=0;n<root1;n++) {
    Long exp = powMap.get(num);
    if(exp!=null) { return root1*exp+n; }
    
    num = modMult(num,inv,mod);
  }
  
  return null;
}

static long carmichael(long inp) {
  PrimeFactorization factor = new PrimeFactorization(inp); //compute the prime factorization
  
  BigInteger tot = BigInteger.ONE;
  for(Map.Entry<Long,Integer> entry : factor.factors.entrySet()) { //loop through all prime factors
    long prime = entry.getKey(), pow = entry.getValue(); //get the prime and the exponent
    
    long term;
    if(prime==-1) { continue; }
    else if(prime==2) {
      if(pow>=3) { term = 1<<(pow-2); }
      else       { term = 1<<(pow-1); }
    }
    else {
      term = BigInteger.valueOf(prime).pow((int)(pow-1)).longValue()*(prime-1);
    }
    
    tot = tot.multiply(BigInteger.valueOf(term)).divide(tot.gcd(BigInteger.valueOf(term)));
    
  }
  
  return tot.longValue();
}
