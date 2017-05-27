{ ok, to run a WWIV 3.21d program under WWIV v4.00:

  take the source to the 3.21d .chn file, edit it, and remove procedure
  return.  Then, make sure this (new) common.pas is in the same directory,
  and compile the 3.21d .chn to a .com file.  Say the program is "dukedom".
  you compile it to dukedom.com.  Now, make sure it is in your main WWIV
  v4.00 directory, and add a new chain to the wwiv 4.00 database.  For the
  filename, say "dukedom %1".

  For more advanced conversion, you should go through the source, and,
  wherever you find something like "'gfiles\whatever.msg'", replace it with
  either "gfilespath+'whatever.msg'", or "datapath+'whatever.msg'".  You
  should use gfilespath if the file is an ascii file, and datapath if the
  file is a data file.  Then, of course, you have to make sure that the
  files are in the correct directory.
}

Uses Crt, sysutils; 

CONST strlen=160;

TYPE str=string[strlen];
     userrec=record
               name:string[25];
               realname:string[14];
               laston:string[10];
               linelen:byte;
               pagelen:byte;
               sl:byte;
               age:byte;
               sex:char;
               callsign:string[8];
               gold:real;
             end;
      regs=record ax,bx,cx,dx,bp,si,di,ds,es,flags:integer; end;

var
    sysopf:text;
    sysopffn:string[80];
    gfilespath,datapath:string[80];
    usernum:integer;
    incom,okansi,cs,so,hangup:boolean;
    timeon,timeleft:real;
    thisuser:userrec;
    rp:regs;

{ Returns time in seconds }
function timer:real;
begin
  timer := Real(Now);
end;

function nsl:real;
begin
  if timer<timeon then
    timeon:=timeon-24.0*3600.0;
  nsl:=timeleft-(timer-timeon);
end;

{ TODO: Actually detect if sysop }
function sysop1:boolean;
begin
    { if (mem[0:1047] and 16)=0 then sysop1:=false else sysop1:=true;}
    sysop1 := false
end;

function sysop:boolean;
begin
  sysop:=sysop1;
end;

procedure sl1(i:str);
begin
  writeln(sysopf,i);
end;

procedure sysoplog(i:str);
begin
  if (not so) or incom then
    sl1('   '+i);
end;

function tch(i:str):str;
begin
  if length(i)>2 then i:=copy(i,length(i)-1,2) else
    if length(i)=1 then i:='0'+i;
  tch:=i;
end;

{ Returns current time as a string HH:MM:SS -bcg'17 }
function time:str;
begin
    time := FormatDateTime('hh:nn:ss', Now)
end;

{ REMOVE:
function time:str;
var reg:record
          ax,bx,cx,dx,bp,si,di,ds,es,flags:integer;
        end;
    h,m,s:string[4];
begin
  reg.ax:=$2c00; intr($21,reg);
  str(reg.cx shr 8,h); str(reg.cx mod 256,m); str(reg.dx shr 8,s);
  time:=tch(h)+':'+tch(m)+':'+tch(s);
end;
}

{ Returns current date in mm/dd/yy (y2k bug) -bcg'17 }
function date:str;
begin
    date := FormatDateTime('mm/dd/yy', Now)
end;

{ REMOVE:
function date:str;
var reg:record
          ax,bx,cx,dx,bp,si,di,ds,es,flags:integer;
        end;
    m,d,y:string[4];
begin
  reg.ax:=$2a00; msdos(reg); str(reg.cx,y); str(reg.dx mod 256,d);
  str(reg.dx shr 8,m);
  date:=tch(m)+'/'+tch(d)+'/'+tch(y);
end;
}

function value(I:str):integer;
var n,n1:integer;
begin
  val(i,n,n1);
  if n1<>0 then begin
    i:=copy(i,1,n1-1);
    val(i,n,n1)
  end;
  value:=n;
  if i='' then value:=0;
end;

function cstr(i:integer):str;
begin
  cstr := IntToStr(i)
end;

function nam:str;
var s:str; i:integer; tf:boolean;
begin
  s:=thisuser.name;
  tf:=true;
  for i:=1 to length(s) do
    if s[i]<'A' then
      tf:=true
    else begin
      if (s[i]<='Z') and not tf then
        s[i]:=chr(ord(s[i])+32);
      tf:=false;
    end;
  nam:=s+' #'+cstr(usernum);
end;

function leapyear(yr:integer):boolean;
begin
  leapyear:=(yr mod 4=0) and ((yr mod 100<>0) or (yr mod 400=0));
end;

function days(mo,yr:integer):integer;
var d:integer;
begin
  d:=value(copy('312831303130313130313031',1+(mo-1)*2,2));
  if (mo=2) and leapyear(yr) then d:=d+1;
  days:=d;
end;

function daycount(mo,yr:integer):integer;
var m,t:integer;
begin
  t:=0;
  for m:=1 to (mo-1) do t:=t+days(m,yr);
  daycount:=t;
end;

function daynum(dt:str):integer;
var d,m,y,t,c:integer;
begin
  t:=0;
  m:=value(copy(dt,1,2));
  d:=value(copy(dt,4,2));
  y:=value(copy(dt,7,2))+1900;
  for c:=1985 to y-1 do
    if leapyear(c) then t:=t+366 else t:=t+365;
  t:=t+daycount(m,y)+(d-1);
  daynum:=t;
  if y<1985 then daynum:=0;
end;

function dat:str;
var ap,x,y:str; i:integer;
begin
  case daynum(date) mod 7 of
    0:x:='Tue';
    1:x:='Wed';
    2:x:='Thu';
    3:x:='Fri';
    4:x:='Sat';
    5:x:='Sun';
    6:x:='Mon';
  end;
  case value(copy(date,1,2)) of
    1:y:='Jan';
    2:y:='Feb';
    3:y:='Mar';
    4:y:='Apr';
    5:y:='May';
    6:y:='Jun';
    7:y:='Jul';
    8:y:='Aug';
    9:y:='Sep';
    10:y:='Oct';
    11:y:='Nov';
    12:y:='Dec';
  end;
  x:=x+' '+y+' '+copy(date,4,2)+', '+cstr(1900+value(copy(date,7,2)));
  y:=time; i:=value(copy(y,1,2));
  if i>11 then ap:='pm' else ap:='am';
  if i>12 then i:=i-12;
  if i=0 then i:=12;
  dat:=cstr(i)+copy(y,3,3)+' '+ap+'  '+x;
end;

procedure checkhangup;
begin
end;

procedure getkey(var c:char); forward;

procedure prompt(i:str); forward;


procedure ansic(c:integer);
var i:str;
begin
  if (c=1) or (c=0) then
    c:=0
  else
    if (c=2) then
      c:=7
    else
      c:=c-2;
  i:=#3+chr(ord('0')+c);
  prompt(i);
end;

procedure sdc;
begin
  ansic(0);
end;


procedure pausescr;
var i:integer; cc:char;
begin
  ansic(3); prompt('(-*-)'); ansic(0);
  getkey(cc);
  for i:=1 to 5 do
    prompt(#8+' '+#8);
end;

procedure prompt(i:str);
var c:integer;
begin
  if (not hangup) then
    for c:=1 to length(i) do begin
      if (i[c]=#10) then
        ansic(0);
      write(i[c]);
    end;
end;

procedure print(i:str);
begin
  prompt(i+chr(13)+chr(10))
end;

procedure nl;
begin
  prompt(chr(13)+chr(10))
end;

procedure prt(i:str);
begin
  ansic(4); prompt(i); ansic(0);
end;

procedure ynq(i:str);
begin
  ansic(7); prompt(i);
end;

procedure mpl(c:integer);
var n:integer; i:str;
begin
  if okansi then begin
    ansic(6);
    i:='';
    for n:=1 to c do i:=i+' ';
    prompt(i);
    prompt(#27+'['+cstr(c)+'D');
  end;
end;

procedure tleft;
begin
  if timer<timeon then timeon:=timeon-24.0*60*60;
  if (nsl<0) then begin
    nl;
    print('Time expired.');
    hangup:=true;
  end;
  checkhangup;
end;


{ Is the key buffer empty - ie, no key has been pressed -bcg'17 }
function empty:boolean;
begin
  empty := not KeyPressed;
end;

function inkey:char;
begin
  if (empty) then
    inkey:=#0
  else begin
    inkey:=ReadKey
  end;
end;


procedure getkey(var c:char);
begin
    c := ReadKey
end;

procedure cls;
begin
  write(chr(12));
end;


function yn:boolean;
var c:char;
begin
  if not hangup then begin
    ansic(3);
    repeat
      getkey(c);
      c:=upcase(c);
    until (c='Y') or (c='N') or (c=chr(13)) or hangup;
    if c='Y' then begin print('Yes'); yn:=true; end else begin print('No'); yn:=false; end;
    if hangup then yn:=false;
  end;
end;

procedure input1(var i:str; ml:integer; tf:boolean);
var cp:integer;
    c:char;
    r:real;
begin
 checkhangup;
 if not hangup then begin
  r:=timer;
  cp:=1;
  repeat
    getkey(c);
    if c=#1 then r:=timer;
    if not tf then c:=upcase(c);
    if (c>=' ') and (c<chr(127)) then
      if cp<=ml then begin
      i[cp]:=c;
      cp:=cp+1;
      write(c);
    end else else case ord(c) of
      8:if cp>1 then begin
               c:=chr(8);
               write(#8#32#8);
               cp:=cp-1;
             end;
      21,24:while cp<>1 do begin
               cp:=cp-1;
               write(#8#32#8);
             end;
    end;
    if (timer-r)>300.0 then hangup:=true;
  until (c=#13) or (c=#14) or hangup;
  i[0]:=chr(cp-1);
  nl;
 end;
end;

procedure input(var i:str; ml:integer);
begin
  input1(i,ml,false);
end;


procedure inputl(var i:str; ml:integer);
begin
  input1(i,ml,true);
end;

procedure onek(var c:char; ch:str);
begin
  repeat
    getkey(c);
    c:=upcase(c);
  until (pos(c,ch)>0) or hangup;
  if hangup then c:=ch[1];
  print(''+c);
end;


 procedure wkey(var abort,next:boolean);
 var cc:char;
 begin
    while not (empty or hangup or abort) do begin
      getkey(cc);
      if (cc=' ') or (cc=chr(3)) or (cc=chr(24)) or (cc=chr(11)) then
        abort:=true;
      if (cc=chr(14)) then begin abort:=true; next:=true; end;
      if (cc=chr(19)) or (cc='P') or (cc='p') then begin
        getkey(cc);
      end;
    end;
 end;

function ctim(rl:real):str;
var h,m,s:str;
begin
  s:=tch(cstr(trunc(rl-int(rl/60.0)*60.0)));
  m:=tch(cstr(trunc(int(rl/60.0)-int(rl/3600.0)*60.0)));
  h:=cstr(trunc(rl/3600.0));
  if length(h)=1 then h:='0'+h;
  ctim:=h+':'+m+':'+s;
end;

function tlef:str;
begin
  tlef:=ctim(nsl);
end;

function cstrr(rl:real; base:integer):str;
var c1:integer; i:str; r1,r2:real;
begin
 if rl<=0.0 then cstrr:='0' else begin
  r1:=ln(rl)/ln(1.0*base);
  r2:=exp(ln(1.0*base)*(trunc(r1)));
  i:='';
  while (r2>0.999) do begin
    c1:=trunc(rl/r2);
    i:=i+copy('0123456789ABCDEF',c1+1,1);
    rl:=rl-c1*r2;
    r2:=r2/(1.0*base);
  end;
  cstrr:=i;
 end;
end;


procedure printa1(i:str; var abort,next:boolean);
var c:integer;
begin
 checkhangup;
 if not hangup then begin
  abort:=false; next:=false; c:=1;
  if not empty then wkey(abort,next);
  while (not abort) and (c-1<length(i)) and (not hangup) do begin
    checkhangup;
    if i[c]=#3 then
      if i[c+1] in [#0..#8] then
        if okansi then
          ansic(ord(i[c+1]));
    if not empty then wkey(abort,next);
    if i[c]=#3 then
      c:=c+1
    else
      write(i[c]);
    c:=c+1;
  end;
 end else abort:=true;
end;

procedure printa(i:str; var abort,next:boolean);
var s:str; p,op,rp,rop,nca:integer; crend:boolean;
begin
  abort:=false;
  crend:=(i[length(i)]=#1) and (i[length(i)-1]<>#3);
  if crend then i:=copy(i,1,length(i)-1);
  wkey(abort,next);
  if i='' then nl;
  while (i<>'') and (not abort) and (not hangup) do begin
    rp:=0; nca:=thisuser.linelen-wherex-1; p:=0;
    while (rp<nca) and (p<length(i)) do begin
      if i[p+1]=#8 then rp:=rp-1 else
        if i[p+1]=#3 then
          p:=p+1
        else
          if (i[p+1]<>#10) then rp:=rp+1;
      p:=p+1;
    end;
    op:=p; rop:=rp;
    if (rp>=nca) and (p<length(i)) then begin
      while ((not (i[p] in [' ',#8,#10])) or (i[p-1]=#3)) and (p>1) do begin
        rp:=rp-1; p:=p-1;
      end;
      if p=1 then
        if not (i[1] in [' ',#8,#10]) then begin rp:=rp-1; p:=p-1; end;
    end;
    if abs(rop-rp)>=(thisuser.linelen div 2) then p:=op;
    s:=copy(i,1,p); delete(i,1,p);
    if (s[length(s)]=' ') then s[0]:=pred(s[0]);
    printa1(s,abort,next);
    if ((i='') and crend) or (i<>'') or abort then
      nl
    else
      printa1(' ',abort,next);
  end;
end;

procedure printacr(i:str; var abort,next:boolean);
begin
 if not abort then
  if i[length(i)]=#1 then
    printa(i,abort,next)
  else
    printa(i+#1,abort,next);
end;

procedure pfl(fn:str; var abort:boolean; cr:boolean);
var fil:text;
    i:str;
    next:boolean;
begin
    if not hangup then begin
      assign(fil,fn);
      {$I-} reset(fil); {$I+}
      if ioresult<>0 then print('File not found.') else begin
        abort:=false;
        while not eof(fil) and (not abort) and (not hangup) do begin
          readln(fil,i);
          if cr then
            printacr(i,abort,next)
          else
            printa(i,abort,next);
        end;
        close(fil);
      end;
      nl;nl;
    end;
end;

procedure printfile(fn:str);
var abort:boolean;
begin
  pfl(fn,abort,true);
end;

procedure iport;
var f:text;
    i:str;
    n:integer;
begin
  assign(f,paramstr(1));
  {$I-} reset(f); {$I+}
  if (ioresult=0) then begin
    readln(f,usernum);
    readln(f,thisuser.name);
    readln(f,thisuser.realname);
    readln(f,thisuser.callsign);
    readln(f,thisuser.age);
    readln(f,thisuser.sex);
    readln(f,thisuser.gold);
    readln(f,thisuser.laston);
    readln(f,thisuser.linelen);
    readln(f,thisuser.pagelen);
    readln(f,thisuser.sl);
    readln(f,n);
    cs:=(n=1);
    readln(f,n);
    so:=(n=1);
    readln(f,n);
    okansi:=(n=1);
    readln(f,n);
    incom:=(n=1);
    readln(f,timeleft);
    readln(f,gfilespath);
    readln(f,datapath);
    readln(f,i);
    close(f);
    sysopffn:=gfilespath+i;
    assign(sysopf,sysopffn);
    {$I-} append(sysopf); {$I+}
    if (ioresult<>0) then begin
      rewrite(sysopf);
    end;
  end else begin
    writeln('Parameter file not found.');
    halt;
  end;
  hangup:=false;
  timeon:=timer;
end;

procedure return;
begin
  close(sysopf);
  halt;
end;

procedure topscr;
begin
end;

