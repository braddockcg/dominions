Program Dominions;

{    This program was modified by Siroos Afshar to add Radars - July 1989.
      
     
     Dominions!
     Version 1.41 (written with WWIV 4.06)
     May 1989
                         ///////     //////////
     =>Apocalypse<= of  ///   trange/// // ///ode
   (aka Chris Haisty)  ///////     /// // ///  /\
                          ///     /// // ///   \oftware
                     ///////     /// // ///   \/

     Home Board : Pandemonium
                  (919) 768-6354          Apocalypse 15 @ 9951
                  WWIVnet ID 9951
                  Winston-Salem, NC
                  SysOp : The Catt                        }

{$I COMMON.PAS}

 Const
   Number_of_Planets  : Byte = 200;
   Number_of_Ships    : Byte = 6;
   Number_of_Radars   : Byte = 3;
   Number_of_Players  : Byte = 20;
   Number_of_Squads   : Integer = 600;
   Number_of_Messages : Byte = 200;
   Ship_Cost          : Array [1..6] of Byte = (5, 10, 20, 40, 80, 160);
   Radar_Cost         : Array [1..3] of Integer = (100, 300, 700 );
   Radar_Range        : Array [1..3] of Integer = ( 4, 8, 12 );
   Ship_Tech          : Array [1..6] of Real = (1, 2, 3.5, 5.5, 9, 15);
   Radar_Tech         : Array [1..3] of Real = (5.5, 12.0, 20.0 );
   Ship_Name          : Array [1..6] of String[20] = ('Frigate',
                                                      'Destroyer',
                                                      'Cruiser',
                                                      'Battleship',
                                                      'Dreadnought',
                                                      'SuperDreadnought');
   Radar_Name         : Array [1..3] of String[20] = ('Short Range',
                                                      'Mid Range',
                                                      'Long Range');
   Ship_Attack        : Array [1..6] of Byte = (1,2,4,8,16,32);
   Ship_Defense       : Array [1..6] of Byte = (2,3,6,12,24,48);
   Ship_Damage        : Array [1..6] of Byte = (5,11,24,53,116,255);
   Month              : Array [1..12] of String[9] = ('January','Febuary',
                              'March','April', 'May','June','July','August',
                              'September','October','November','December');
   IsFalse            : Boolean = false;

   Type
      String160 = String[160];
      String80 = String [80];
      String40 = String [40];
      String25 = String [25];
      String20 = String [20];
      String2 = String [2];

      Empirerecord = Record
         User_Number       : Integer;
         User_Name,
         Empire_Name       : String25;
         Technology_Level,
         Total_Population  : Real;
         Planets           : Byte;
         Intel_Reports     : Byte;
         Industry_Units,
         Technology_Units  : Real;
         Ships             : Array [1..6] of Integer;
         Radars            : Array [1..3] of Integer;
         Points            : Real;
         Expert            : Boolean;
      End;

      Empirerecs = Array [1..20] of Empirerecord;

      Planetrecord = Record
         Planet_Name        : String20;
         X,Y,Owner          : Byte;
         Population         : Real;
         Habitability,
         Industry_Percent,
         Technology_Percent : Byte;
         Industrial_Level   : Real;
         Ships              : Array [1..6] of Integer;
	 Radars		    : Array [1..3] of Byte;	{ --SKA--}
      End;

      Planetrecs = Array [1..200] of Planetrecord;

      Squadronrecord = Record
         Owner         : Byte;
         Distance_Left : Real;
         Destination   : Byte;
         Speed         : Byte;
         Ships         : Array [1..6] of Integer;
      End;

      Squadronrecs = Array [1..600] of Squadronrecord;

      Messagerecord = Record
         Sent_By : Byte;
         Sent_To : Byte;
         Message : String80;
      End;

      Messagerecs = Array [1..200] of Messagerecord;

   Var
      BigString : String160;
      OneChar : Char;
      Player_Number, EC, CurMonth, Year, Len : Integer;
      Empire : Empirerecs;
      Planet : Planetrecs;
      Squadron : Squadronrecs;
      Messages : Messagerecs;
      Filled_Up : Boolean;
      date_now : string160;

FUNCTION addfront(b:STR;l:INTEGER): STR; {adds spaces in front}
BEGIN
  WHILE LENGTH(b)< l DO
    b := ' '+b;
  addfront := b;
END;

FUNCTION addrear(b:STR;l:INTEGER): STR; {adds spaces in rear}
BEGIN
  WHILE LENGTH(b)< l DO
    b := b+' ';
  addrear := b;
END;

   { NOTE : The following three procedures are the only fifth generation
            proecedures.}

function St (StA : Real) : String160;

   { Called from several procedures and MAINTAIN.DOM .
     This function converts a number into a String useable with the
     Print and Prompt functions of COMMON.PAS and also adds commas for
     longer variables.}

 Var
  BS : String160;
  SN : Byte;

 Begin
   sta:=sta-frac(sta);
   system.Str (StA:0:0,BS);
   SN := length (BS);
   if SN > 4 then
     While SN > 3 do
       Begin
         SN := SN - 3;
         if not ((SN = 1) and (BS[1] = '-')) then insert (',', BS, SN+1);
       End;
   St := BS;
End;

function StReal (Z : Real; W : Integer) : String160;

   {St function for reals using decimals.}

  Var
   SV : String160;

  Begin
    system.Str (Z:0:W,SV);
    StReal := SV;
  End;


{$I OVERLAY3.DOM}       {Fourth generation procedures.}
{$I OVERLAY2.DOM}       {Third generation procedures.}
{$I OVERLAY1.DOM}       {Second generation procedures.}
{$I MAINTAIN.DOM}       {Maintenence procedures.}


{ *!*!*!* The Main Menu in the flesh! *!*!*!*}

   procedure Main_Menu;

      Begin
         Repeat
            writeln;
            writeln;
            print ('Dominions! Main Menu');
            print ('~~~~~~~~~~~~~~~~~~~~');
            if not Empire[Player_Number].Expert then
               Begin
                  print ('(C)ounterintelligence');
                  print ('(E)mpire Management');
                  print ('(H)elp');
                  print ('(I)nstructions');
                  print ('(M)ap of the Galaxy');
                  print ('(N)avy Management');
                  print ('(P)lanet Management');
                  print ('(Q)uit');
                  print ('(R)ecent Happenings');
                  print ('(S)cores');
                  print ('e(X)pert Mode Toggle');
                  writeln;
               End;
            if Empire[Player_Number].Expert
               then prompt ('Option (C,E,H,I,M,N,P,Q,R,S,X) > ')
               else prompt ('Option > ');
            Onek (OneChar, 'CEHIMNPQRSX');
            Case OneChar of
               'C' : Counterintelligence_Menu;    {Case of... }
               'E' : Empire_Menu;                 {Sends Game to Correct }
               'H' : PrintFile ('HelpMain.Dom');  {Procedure for Main }
               'I' : PrintFile ('Instruct.Dom');  {Input.}
               'M' : Maps;
               'N' : Navy_Menu;
               'P' : Planet_Menu;
               'Q' : Begin
                        writeln;
                        prompt ('Are you sure ? ');
                        if YN then Exit;
                     End;
               'R' : Read_Recent_Happenings;
               'S' : Scores;
               'X' : Empire[Player_Number].Expert := not Empire[Player_Number].Expert;
            End;
         Until IsFalse;
      End;

{ --------========>>>>>> Main Program Procedures <<<<<<=======-------- }

   { The following procedures are all called from the Main Body of the
     program.}

   procedure Introduction;

      Begin
         Ansic (0);
         cls;
         PrintFile ('Picture.Dom');
         Delay(750);
         cls;
         print ('Programming and Design...   Apocalypse');
         print ('Thanks to...                 The Catt');
         print ('                            Tarl Cabot');
         print ('                            The Dubber');
         print ('                             Mr. Bill');
         print ('Playtesting...           The Pandemonium');
         print ('                           Playtesters');
         print ('Addition of Radars...     Siroos Afshar');
         print ('2017 port to Free Pascal Braddock Gaskill');
         {PauseScr;}
         Delay(750);
      End;

   procedure Load_Information;

      Var
         EmpireFile : file of Empirerecord;
         PlanetFile : file of Planetrecord;
         SquadFile : file of Squadronrecord;
         MessageFile : file of Messagerecord;
         LastOnFile : file of String160;
         LastPlayed : String160;
         DateFile : File of Integer;
         LoopLI : Integer;

      Begin
         Assign (EmpireFile, 'Empires.Dom');
         Reset (EmpireFile);
         for LoopLI := 1 to Number_of_Players do
            Read (EmpireFile, Empire[LoopLI]);
         Close (EmpireFile);
         Assign (PlanetFile, 'Planets.Dom');
         Reset (PlanetFile);
         for LoopLI := 1 to Number_of_Planets do
            Read (PlanetFile, Planet[LoopLI]);
         Close (PlanetFile);
         Assign (SquadFile, 'Squads.Dom');
         Reset (SquadFile);
         for LoopLI := 1 to Number_of_Squads do
            read (SquadFile, Squadron[LoopLI]);
         Close (SquadFile);
         Assign (MessageFile, 'Messages.Dom');
         Reset (MessageFile);
         for LoopLI := 1 to Number_of_Messages do
            read (MessageFile, Messages[LoopLI]);
         Close (MessageFile);
         Assign (LastOnFile, 'LastOn.Dom');
         if Empire[1].User_Number > 0 then
            Begin
               Reset (LastOnFile);
               Read (LastOnFile, Lastplayed);
            End;
         Date_Now := date;
         Assign (DateFile, 'Date.Dom');
         Reset (DateFile);
         Read (DateFile, CurMonth, Year);
         Close (DateFile);
         if (Lastplayed <> Date_Now) and (Empire[1].User_Number > 0) then
            Maintenence;
         for LoopLI := 1 to 20 do
            Begin
               if (Empire[LoopLI].User_Number = UserNum) and
                  (Empire[LoopLI].User_Name = ThisUser.Name) then
                     Player_Number := LoopLI;
            End;
         if Player_Number = 0 then
            Begin
               LoopLI := 0;
               Repeat
                  LoopLI := LoopLI + 1;
               Until (Empire[LoopLI].User_Number = 0) or (LoopLI = 21);
               if LoopLI < 21 then Make_New_Player(LoopLI);
            End;
         if Player_Number = 0 then
            Begin
               print ('Sorry, but all twenty empires are are taken.');
               print ('You must wait for the game to be reset in order');
               print ('to play.');
            End;
      End;

   procedure Print_Messages;

      Var
         LoopPM, TotalMsgs : Byte;

      Begin
         cls;
         TotalMsgs := 0;
         for LoopPM := 1 to Number_of_Messages do
            if Messages[LoopPM].Sent_To = Player_Number then
               with Messages[LoopPM] do
                  Begin
                     if TotalMsgs > 6 then
                        Begin
                           PauseScr;
                           TotalMsgs := 0;
                        End;
                     TotalMsgs := TotalMsgs + 1;
                     if Sent_By > 0 then
                        print ('A message from ' + Empire[Sent_By].Empire_Name +
                           '[' + St(Sent_By) + ']...');
                     print (Message);
                     print ('---------------------------------------');
                     Sent_By := 0;
                     Sent_To := 0;
                     Message := '';
                  End;
      End;

   procedure Save_All;

      Var
         EmpireFile : file of Empirerecord;
         PlanetFile : file of Planetrecord;
         SquadFile : file of Squadronrecord;
         MessageFile : file of Messagerecord;
         DateFile : file of Integer;
         LastonFile : file of String160;
         LoopSA : Integer;

      Begin
         writeln;
         print ('=!=!=!=Saving=!=!=!=');
         Assign (DateFile, 'Date.Dom');
         Rewrite (DateFile);
         Write (DateFile, CurMonth, Year);
         Close (DateFile);
         Assign (LastonFile, 'LastOn.Dom');
         Rewrite (LastonFile);
         Write (LastOnFile, Date_Now);
         Close (LastOnFile);
         Empire[Player_Number].Points := Score(Player_Number);
         Assign (EmpireFile, 'Empires.Dom');
         Rewrite (EmpireFile);
         for LoopSA := 1 to Number_of_Players do
             write (EmpireFile, Empire[LoopSA]);
         Close (EmpireFile);
         Assign (PlanetFile, 'Planets.Dom');
         Rewrite (PlanetFile);
         for LoopSA := 1 to Number_of_Planets do
             write (PlanetFIle, Planet[LoopSA]);
         Close (PlanetFile);
         Assign (SquadFile, 'Squads.Dom');
         Rewrite (SquadFile);
         for LoopSA := 1 to Number_of_Squads do
             write (SquadFile, Squadron[LoopSA]);
         Close (SquadFile);
         Assign (MessageFile, 'Messages.Dom');
         Rewrite (MessageFile);
         for LoopSA:= 1 to Number_of_Messages do
             write (MessageFile, Messages[LoopSA]);
         Close (MessageFile);
      End;

{ +!+!+!+ The Main Body of the Program! +!+!+!+ }

   Begin
      Iport;                       {Gets the bbs User's stats from WWIV.}
      Player_Number := 0;
      Introduction;
      Load_Information;
      if Player_Number = 0 then
         Begin
            writeln;
            Scores;
            Save_All;
            Halt;
         End;
      SysopLog ('+>+> ' + ThisUser.Name + ' played Dominions! as ' +
         Empire[Player_Number].Empire_Name);
      clrscr;
      cls;
      Print_Messages;
      writeln;
      print (Month[CurMonth] + ' ' + St(Year));
      Main_Menu;
      Save_All;
   End.
