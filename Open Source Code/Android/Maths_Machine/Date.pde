static enum Month {
  JANUARY, FEBRUARY, MARCH, APRIL, MAY, JUNE, JULY, AUGUST, SEPTEMBER, OCTOBER, NOVEMBER, DECEMBER;
  String toString() { String res = name().toLowerCase(); return char(res.charAt(0)+'A'-'a')+res.substring(1); } //make it lowercase, then capitalize the 1st letter
  String threeLetter() { return toString().substring(0,3); }
  int num() { return ordinal()+1; }
  
  int days(boolean leap) { switch(this) {
    case FEBRUARY: return leap ? 29 : 28;
    case APRIL: case JUNE: case SEPTEMBER: case NOVEMBER: return 30;
    default: return 31;
  } }
  
  int daysAccum(boolean leap) { switch(this) { //returns the number of days between the 1st of the month & new years
    case   JANUARY: return            0;
    case  FEBRUARY: return           31;
    case     MARCH: return leap? 60: 59;
    case     APRIL: return leap ?91: 90;
    case       MAY: return leap?121:120;
    case      JUNE: return leap?152:151;
    case      JULY: return leap?182:181;
    case    AUGUST: return leap?213:212;
    case SEPTEMBER: return leap?244:243;
    case   OCTOBER: return leap?274:273;
    case  NOVEMBER: return leap?305:304;
    default       : return leap?335:334;
  } }
  
  static Month toMonth(int m) { switch(m) {
    case 1: return JANUARY; case 2: return FEBRUARY; case 3: return MARCH; case 4: return APRIL;
    case 5: return MAY; case 6: return JUNE; case 7: return JULY; case 8: return AUGUST;
    case 9: return SEPTEMBER; case 10: return OCTOBER; case 11: return NOVEMBER; case 12: return DECEMBER;
    //default: throw new RuntimeException("There is no month "+m+" (only 1-12 are accepted)");
    default: return null;
  } }
  
  Month increment() { switch(this) {
    case JANUARY: return FEBRUARY;   case FEBRUARY: return MARCH;   case MARCH: return APRIL;   case APRIL: return MAY;
    case MAY: return JUNE;   case JUNE: return JULY;   case JULY: return AUGUST;   case AUGUST: return SEPTEMBER;
    case SEPTEMBER: return OCTOBER;   case OCTOBER: return NOVEMBER;   case NOVEMBER: return DECEMBER; default: return JANUARY;
  } }
  
  Month decrement() { switch(this) {
    case JANUARY: return DECEMBER;   case FEBRUARY: return JANUARY;   case MARCH: return FEBRUARY;   case APRIL: return MARCH;
    case MAY: return APRIL;   case JUNE: return MAY;   case JULY: return JUNE;   case AUGUST: return JULY;
    case SEPTEMBER: return AUGUST;   case OCTOBER: return SEPTEMBER;   case NOVEMBER: return OCTOBER; default: return NOVEMBER;
  } }
  
  //list of strings that could be converted into a month (as well as a list of the months they correspond to)
  static String matchers[] = {"January ","Jan ","February ","Feb ","March ","Mar ","April ","Apr ","May ","June ","Jun ","July ","Jul ","August ","Aug ","September ","Sept ","Sep ","October ","Oct ","November ","Nov ","December ","Dec "};
  static Month matchId[] = {JANUARY,JANUARY,FEBRUARY,FEBRUARY,MARCH,MARCH,APRIL,APRIL,MAY,JUNE,JUNE,JULY,JULY,AUGUST,AUGUST,SEPTEMBER,SEPTEMBER,SEPTEMBER,OCTOBER,OCTOBER,NOVEMBER,NOVEMBER,DECEMBER,DECEMBER};
}

static enum Weekday {
  SUNDAY, MONDAY, TUESDAY, WEDNESDAY, THURSDAY, FRIDAY, SATURDAY;
  String toString() { String res = name().toLowerCase(); return char(res.charAt(0)+'A'-'a')+res.substring(1); } //make it lowercase, then capitalize the 1st letter
  String shorten() { switch(this) { case SUNDAY: return "Sun"; case MONDAY: return "Mon"; case TUESDAY: return "Tues"; case WEDNESDAY: return "Wed"; case THURSDAY: return "Thurs"; case FRIDAY: return "Fri"; default: return "Sat"; } }
  
  int num() { return ordinal(); }
  static Weekday fromNumber(long num) {
    switch((int)(num%7)) {
      case 0:          return    SUNDAY;
      case 1: case -6: return    MONDAY;
      case 2: case -5: return   TUESDAY;
      case 3: case -4: return WEDNESDAY;
      case 4: case -3: return  THURSDAY;
      case 5: case -2: return    FRIDAY;
      default:         return  SATURDAY;
    }
  }
  Weekday increment() { switch(this) {
    case SUNDAY: return MONDAY; case MONDAY: return TUESDAY; case TUESDAY: return WEDNESDAY; case WEDNESDAY:
    return THURSDAY; case THURSDAY: return FRIDAY; case FRIDAY: return SATURDAY; default: return SUNDAY;
  } }
  Weekday decrement() { switch(this) {
    case SUNDAY: return SATURDAY; case MONDAY: return SUNDAY; case TUESDAY: return MONDAY; case WEDNESDAY:
    return TUESDAY; case THURSDAY: return WEDNESDAY; case FRIDAY: return THURSDAY; default: return FRIDAY;
  } }
}



private static class DateCombo { //can be used to represent a date
  
  //ATTRIBUTES
  Month month;
  byte day;
  long year;
  
  //CONSTRUCTORS
  DateCombo(int d, Month m, long y) { day=(byte)d; month=m; year=y; } //date given day, month, year
  DateCombo(Month m, int d, long y) { month=m; day=(byte)d; year=y; } //date given month, day, year
  DateCombo(long a, int b, long c) { switch(Date.format) {
    case 0: day=(byte)a; month = Month.toMonth(b); year = c; break;
    case 1: day=(byte)b; month = Month.toMonth((int)a); year = c; break;
    default: day=(byte)c; month = Month.toMonth((int)a); year = a;
  } }
  
  DateCombo(long d) { //date given number of days since jan 1 0000
    //float approx = d/365.2425; //A full revolution is 365.2425 days. Find how many revolutions fit into this many days
    //the above method is probably faster, but it's also much harder to implement. Gotta do a lot of tricky math
    
    /*long amt1 = floor(d/146097f);      //find how many times 400 years fits into d days
    year = amt1*400; d -= 146097*amt1; //increment our year & decrement our days by that many quadruple centuries
    long amt2 = (d-1)/36524;           //find how many times 100 years fits into the d days left
    if(amt2!=0) { year += amt2*100; d -= 36524*amt2+1; } //increment our year & decrement our days by that many centuries
    long amt3 = (d-(amt2==0?0:1))/1461; //find how many times 4 years fits into the d days left (making sure to account for whether the first year of the century is a leap year)
    if(amt3!=0) { year += amt3*4; d -= 1461*amt3-(amt2==0?0:1); } //increment our year & decrement our days by that many quadruple years
    long amt4 = (d-(amt2==0||amt3!=0?1:0))/365; //find how many times 1 year fits into the d days left (making sure to account for whether the first year is a leap year)
    if(amt4!=0) { year += amt4; d -= 365*amt4+(amt2==0||amt3!=0?1:0); } //increment our year & decrement our days by that many years*/
    
    long amt1 = floor(d/146097f);      //find how many times 400 years fits into d days
    year = amt1*400; d -= 146097*amt1; //increment our year & decrement our days by that many quadruple centuries
    long amt2 = (d-1)/36524;           //find how many times 100 years fits into the d days left
    if(amt2!=0) { year += amt2*100; d -= 36524*amt2+1; } //increment our year & decrement our days by that many centuries
    long amt3 = (d-(amt2==0?0:1))/1461; //find how many times 4 years fits into the d days left (making sure to account for whether the first year of the century is a leap year)
    if(amt3!=0) { year += amt3*4; d -= 1461*amt3; } //increment our year & decrement our days by that many quadruple years
    long amt4 = (d-(amt2==0?1:0))/365; //find how many times 1 year fits into the d days left (making sure to account for whether the first year is a leap year)
    if(amt4!=0) { year += amt4; d -= 365*amt4+(amt2==0?1:0); } //increment our year & decrement our days by that many years
    else { d += (amt2==0||amt3==0?0:1); }
    
    boolean leap = Date.isLeap(year); //find whether this is a leap year
    month = Month.JANUARY;            //initialize month to January
    while(d >= month.days(leap)) { d -= month.days(leap); month = month.increment(); } //as long as the day is larger than the number of days, increment the month and subtract that many days
    day = (byte)(d+1); //set the day of the month
  }
  
  DateCombo(Date d) { this((int)d.day); }
  
  //GETTERS/SETTERS
  Month getMonth() { return month; }
  byte  getDay  () { return   day; }
  long  getYear () { return  year; }
  
  
  //CHECKERS & TESTERS
  boolean valid() { //whether or not this is a valid date
    return month!=null && day>0 && (day<=28 || day<=month.days(Date.isLeap(year))); //return true if month is valid, day is positive, and not greater than the number of days this month has
  }
  
  int dayOfYear() { //grabs the number of days since new year's eve last year (1/1=1, 1/2=2, 12/31=365 (or 366), etc.)
    return month.daysAccum(Date.isLeap(year))+day; //take the number of days accumulated over the previous months, then add the day
  }
  
  long dayFromEpoch() { //finds the number of days since the epoch of january 1, 0000
    long yearAccum = 365*year; //compute the number of days accumulated from each year (ignoring leap days)
    yearAccum += 1+((year-1)>>2)-floor(0.01*(year-1))+floor(0.0025*(year-1)); //add up all the leap days
    return yearAccum + dayOfYear() - 1; //return those days + the days since 1/1
  }
  
  //INHERITED METHODS
  
  @Override
  String toString() {
    switch(Date.format) {
      case 0: return day+" "+month+", "+year;
      case 1: return month+" "+day+", "+year;
      default: return year+" "+month+" "+day;
    }
  }
}

public static class Date {
  //ATTRIBUTES
  long day = 0; //days since the 1/1/0000 epoch
  
  static byte format = 1; //0=D/M/Y, 1=M/D/Y, 2=Y/M/D
  static int timeZone = -4; //the current time zone
  
  Date() { }
  Date(long a, int b, long c) { day = new DateCombo(a,b,c).dayFromEpoch(); }
  Date(Month m, int d, long y) { day = new DateCombo(m,d,y).dayFromEpoch(); }
  Date(int d, Month m, long y) { day = new DateCombo(d,m,y).dayFromEpoch(); }
  Date(DateCombo d) { day = d.dayFromEpoch(); }
  Date(long d) { day = d; }
  
  @Override
  public String toString() { return new DateCombo((int)day)+""; }
  
  @Override
  public boolean equals(final Object obj) {
    return obj instanceof Date && ((Date)obj).day==day;
  }
  
  @Override
  public Date clone() { return new Date(day); }
  
  @Override
  public int hashCode() { return (int)(day ^ day>>>32); }
  
  static boolean isLeap(long y) { //whether this year is a leap year
    return (y&3)==0 && (y%100!=0 || (y&15)==0); //return true if divisible by 4 AND not divisible by 100 UNLESS it's also divisible by 400 (which would mean it's divisible by 16)
  }
  
  Date addeq(long d) { day+=d; return this; }
  Date subeq(long d) { day-=d; return this; }
  Date add(long d) { return new Date(day+d); }
  Date sub(long d) { return new Date(day-d); }
  Date increment() { return new Date(day+1); }
  Date decrement() { return new Date(day-1); }
  long sub(Date d) { return day-d.day; }
  
  
  long   getYear() { return new DateCombo(this).year; }
  Month getMonth() { return new DateCombo(this).month; }
  byte    getDom() { return new DateCombo(this).day; }
  
  static long year() { return new DateCombo(today()).year; }
  
  
  static Date today() {
    long time = System.currentTimeMillis(); //grab the time in milliseconds from January 1, 1970
    time+=Date.timeZone*3600000l;           //move to the New York time zone
    time/=86400000l;                        //divide by 1000ms * 60s * 60min * 24hr
    return new Date(time+719528);           //add the time between 0 epoch and 1970 epoch, return result
  }
  
  static Date tomorrow () { return new Date(++today().day); }
  static Date yesterday() { return new Date(--today().day); }
  
  static Date    sunday() { return new Date(7*ceil((today().day-1)/7f)+1); }
  static Date    monday() { return new Date(7*ceil((today().day-2)/7f)+2); }
  static Date   tuesday() { return new Date(7*ceil((today().day-3)/7f)+3); }
  static Date wednesday() { return new Date(7*ceil((today().day-4)/7f)+4); }
  static Date  thursday() { return new Date(7*ceil((today().day-5)/7f)+5); }
  static Date    friday() { return new Date(7*ceil((today().day-6)/7f)+6); }
  static Date  saturday() { return new Date(7*ceil(today().day/7f));       }
  
  static Date newYears(long y) { return new Date(1, Month.JANUARY, y); }
  static Date valentines(long y) { return new Date(14, Month.FEBRUARY, y); }
  static Date stPatricks(long y) { return new Date(17, Month.MARCH, y); }
  //static Date easter(long y) { } //NO NO NO NO NO NO NO NO
  static Date mothersDay(long y) {
    long first = new Date(1, Month.MAY, y).day; //look at the first of May
    return new Date(7*ceil((first-1)/7f)+8);    //return the second sunday during or after that
  }
  static Date fathersDay(long y) {
    long first = new Date(1, Month.JUNE, y).day; //look at the first of June
    return new Date(7*ceil((first-1)/7f)+15);    //return the third sunday during or after that
  }
  static Date halloween(long y) { return new Date(31, Month.OCTOBER, y); }
  static Date thanksgiving(long y) {
    long first = new Date(1, Month.NOVEMBER, y).day; //look at the first of Thursday
    return new Date(7*ceil((first-5)/7f)+26);        //return the 4th thursday during or after that
  }
  static Date christmas(long y) { return new Date(25, Month.DECEMBER, y); }
  
  Weekday dayOfWeek() { return Weekday.fromNumber(day-1); } //1/1/0000 was a Saturday
  
  boolean less(Date d) { return day < d.day; }
  boolean lessEq(Date d) { return day <= d.day; }
  boolean greater(Date d) { return day > d.day; }
  boolean greaterEq(Date d) { return day >= d.day; }
  
  
  static void setFormat(String f) { switch(f) {
    case "D/M/Y": format=0; break;
    case "M/D/Y": format=1; break;
    case "Y/M/D": format=2; break;
  } }
  
  static void setTimeZone(int shift) { timeZone = shift; }
}

public static class Time { //class used for representing time (not time of day, but rather amounts of time; hours, minutes, seconds, etc)
  long day; int hour, min, sec;
  
  Time() { }
  Time(long d, int h, int m, int s) { day=d; hour=h; min=m; sec=s; }
  Time(int h, int m, int s) { hour=h; min=m; sec=s; }
  Time(int h, int m) { hour=h; min=m; }
  Time(long s) { day=floor(s/86400f); hour=(int)(s-day*86400)/3600; min=(int)(s-day*86400-hour*3600)/60; sec=(int)(s-day*86400-hour*3600-min*60); }
  
  long seconds() { return ((day*24+hour)*60+min)*60+sec; }
  long minutes() { return (day*24+hour)*60+min; }
  long hours() { return day*24+hour; }
  
  @Override String toString() {
    if(day<0) { return "-"+neg(); }
    return day+(hour<10?":0":":")+hour+(min<10?":0":":")+min+(sec<10?":0":":")+sec;
  }
  
  @Override boolean equals(final Object obj) {
    return obj instanceof Time && ((Time)obj).sec==sec && ((Time)obj).min==min && ((Time)obj).hour==hour && ((Time)obj).day==day;
  }
  
  @Override Time clone() {
    return new Time(day,hour,min,sec);
  }
  
  @Override int hashCode() {
    return (int)(seconds() ^ seconds()>>>32);
  }
  
  Time addeq(Time t) {
    sec+=t.sec; if(sec>=60) { sec-=60; min++; }
    min+=t.min; if(min>=60) { min-=60; hour++; }
    hour+=t.hour; if(hour>=24) { hour-=24; day++; }
    day+=t.day;
    return this;
  }
  
  Time subeq(Time t) {
    sec-=t.sec; if(sec<0) { sec+=60; min--; }
    min-=t.min; if(min<0) { min+=60; hour--; }
    hour-=t.hour; if(hour<0) { hour+=24; day--; }
    day-=t.day;
    return this;
  }
  
  Time add(Time t) { return clone().addeq(t); }
  Time sub(Time t) { return clone().subeq(t); }
  
  Time neg() {
    return new Time(((sec|min|hour)==0?-day:~day),(((sec|min)==0?24:23)-hour)%24,((sec==0?60:59)-min)%60,(60-sec)%60);
  }
  
  Time muleq(int n) {
    sec*=n; min*=n; hour*=n; day*=n;
    min+=sec/60; hour+=min/60; day+=hour/24;
    sec%=60; min%=60; hour%=24;
    if(sec<0) { sec+=60; min--; } if(min<0) { min+=60; hour--; } if(hour<0) { hour+=24; day--; }
    return this;
  }
  
  Time mul(int n) { return clone().muleq(n); }
  
  Time mul(double f) { return new Time(Math.round(seconds()*f)); }
  Time div(double f) { return new Time(Math.round(seconds()/f)); }
  
  Time half() { return new Time(day>>1,12*int(day&1)+(hour>>1),30*(hour&1)+min>>1,30*(min&1)+(sec>>1)); }
  
  int compareTo(Time t) {
    if(day==t.day && hour==t.hour && min==t.min && sec==t.sec) { return 0; }
    if(day<t.day || day==t.day && (hour<t.hour || hour==t.hour && (min<t.min || min==t.min && sec<t.sec))) { return -1; }
    return 1;
  }
  
  boolean notEqual(Time t) { return sec!=t.sec || min!=t.min || hour!=t.hour || day!=t.day; }
  boolean    less(Time t) { return day<t.day || day==t.day && (hour<t.hour || hour==t.hour && (min<t.min || min==t.min && sec<t.sec)); }
  boolean greater(Time t) { return day>t.day || day==t.day && (hour>t.hour || hour==t.hour && (min>t.min || min==t.min && sec>t.sec)); }
  boolean    lessEqu(Time t) { return day<t.day || day==t.day && (hour<t.hour || hour==t.hour && (min<t.min || min==t.min && sec<=t.sec)); }
  boolean greaterEqu(Time t) { return day>t.day || day==t.day && (hour>t.hour || hour==t.hour && (min>t.min || min==t.min && sec>=t.sec)); }
  
  double div(Time t) { return (double)(seconds())/t.seconds(); }
}

static class DateTime { //something with both date AND time
  Date date; Time time;
  static boolean military = false;
  
  DateTime() { date = new Date(0); time = new Time(0); }
  
  DateTime(Date d, Time t) { date=d; time=t; }
  DateTime(Date d) { date=d; time=new Time(); }
  DateTime(Time t) { date=new Date(t.day); t.day=0; time=t; }
  
  DateTime(long a, int b, long c, int h, int m, int s) {
    date = new Date(a,b,c); time = new Time(h,m,s);
  }
  
  DateTime(long a, int b, long c, int h, int m, int s, boolean p) {
    date = new Date(a,b,c); time = new Time(h%12+(p?12:0),m,s);
  } //TEST
  
  DateTime(long sec) {
    date = new Date(sec/86400); time = new Time((int)(sec%86400));
  }
  
  @Override public String toString() {
    if(military) { return date+" "+(time+"").substring(2); } //in 24 hour format, we just show the date, and show the time (cutting out the day at the beginning of the time)
    String t = (time.hour==0||time.hour==12 ? 12 : time.hour%12)+(time.min<10?":0":":")+time.min+(time.sec<10?":0":":")+time.sec+(time.hour>11?" PM":" AM"); //grab the time (hour%=12, 0 becomes 12, AM/PM)
    return date+" "+t;
  }
  
  @Override public boolean equals(final Object obj) {
    return obj instanceof DateTime && ((DateTime)obj).date.equals(date) && ((DateTime)obj).time.equals(time);
  }
  
  @Override public DateTime clone() {
    return new DateTime(date.clone(), time.clone());
  }
  
  @Override public int hashCode() {
    return date.hashCode()*31+time.hashCode();
  }
  
  long seconds() {
    return date.day*86400+time.seconds();
  }
  
  public static DateTime now() {
    long time = System.currentTimeMillis()/1000;
    return new DateTime(time+62167219200l+3600*Date.timeZone);
  }
  
  DateTime addeq(Time t) {
    time.addeq(t); date.addeq(time.day); time.day=0;
    return this;
  }
  
  DateTime subeq(Time t) {
    time.subeq(t); date.addeq(time.day); time.day=0;
    return this;
  }
  
  DateTime add(Time t) { return clone().addeq(t); }
  DateTime sub(Time t) { return clone().subeq(t); }
  
  Time sub(DateTime d) {
    long dif1 = date.sub(d.date); //subtract dates
    Time dif2 = time.sub(d.time); //subtract times
    dif2.day += dif1; //increment day counter by change in dates
    return dif2; //return result
  }
  
  DateTime mean(DateTime d) { //finds the mean between the two dates
    Time midTime = time.add(d.time).half(); //find the mean between the two times
    Date midDate = new Date((date.day+d.date.day)>>1); //find the mean between the two days
    if(((date.day^d.date.day)&1)==1) { midTime.hour+=12; } //if the sum of the days is odd, add 12 hours
    return new DateTime(midDate,midTime);
  }
  
  Weekday dayOfWeek() { return date.dayOfWeek(); } //day of the week
}
