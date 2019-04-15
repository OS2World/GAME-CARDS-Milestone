PROGRAM Milestone;

(*                                                                      *)
(* AUTHOR: Michael G. Slack - based on program by David Addison         *)
(* DATE WRITTEN:   03/21/1989 - Original (C) 1986 D.A.                  *)
(* DATE REWRITTEN: 07/23/1995                                           *)
(* ENVIRONMENT: Speed Pascal/2 V1.00+ (PM)                              *)
(*     -> converted from Turbo Pascal V5.0 source.                      *)
(*     -> original program written on the Amiga 1000 in ABASIC.         *)
(*                                                                      *)
(* This program will play a simple card game.  Player plays against the *)
(* computer.                                                            *)
(*                                                                      *)
(* -------------------------------------------------------------------- *)
(*                                                                      *)
(* REVISED: 07/23/1995 - Beginning build.                               *)
(*          02/08/1996 - Added about box.                               *)
(*          05/06/1996 - Modified for SP/2 version 1.5.                 *)
(*          11/03/1996 - Modified for Warp IV (moveable dialogs).       *)
(*          1997/12/26 - Compiled with fixpack 2 (removed several vars  *)
(*                       declared by not used).                         *)
(*          2001/06/03 - Updated about dialog, cleaned up code.         *)
(*                                                                      *)

{$R g:\speed\progs\milestne.srf}

 USES ObjectPM, ODialogs, PMWin, PMGPI, PMHelp, OS2Def, MS_RC, Strings;

 CONST G_Computer = 0; {index of computer in arrays}
       G_Player   = 1; {index of player in arrays}

 TYPE ARRAY1TO4     = ARRAY[1..4] OF INTEGER;
      ARRAY1TO41TO5 = ARRAY[1..4,1..5] OF INTEGER;
      CARDRECORD    = RECORD
                       Name : STRING[16];
                       id_N : ULONG;
                       Pic  : HBITMAP;
                      END;
      CARDARRAY     = ARRAY[1..22] OF CARDRECORD; {21 and 22 are card backs}

 CONST MaxCards : INTEGER = 106;
       ConTT1   : ARRAY1TO4     = (18,56,60,106);
       ConTT2   : ARRAY1TO41TO5 = ((4,7,10,14,19),  (25,31,37,43,57),
                                   (58,59,60,60,61),(65,77,87,97,107));
       ConTTSt  : CARDARRAY     =
                   ((Name:'Out Of Gas';      id_N:1000; Pic:0), {hazards}
                    (Name:'Flat Tire';       id_N:1001; Pic:0),
                    (Name:'Accident';        id_N:1002; Pic:0),
                    (Name:'Speed Limit(50)'; id_N:1003; Pic:0),
                    (Name:'Stop';            id_N:1004; Pic:0),
                    (Name:'Gas';             id_N:2000; Pic:0), {remedies}
                    (Name:'Spare Tire';      id_N:2001; Pic:0),
                    (Name:'Repairs';         id_N:2002; Pic:0),
                    (Name:'End Speed Limit'; id_N:2003; Pic:0),
                    (Name:'Roll';            id_N:2004; Pic:0),
                    (Name:'Extra Tank';      id_N:3000; Pic:0), {safeties}
                    (Name:'Permanent Tire';  id_N:3001; Pic:0),
                    (Name:'Driving Ace';     id_N:3002; Pic:0),
                    (Name:'R';               id_N:3003; Pic:0),
                    (Name:'Right-Of-Way';    id_N:3004; Pic:0),
                    (Name:'200 Mile';        id_N:4000; Pic:0), {mileage}
                    (Name:'100 Mile';        id_N:4001; Pic:0),
                    (Name:'75 Mile';         id_N:4002; Pic:0),
                    (Name:'50 Mile';         id_N:4003; Pic:0),
                    (Name:'25 Mile';         id_N:4004; Pic:0),
                    (Name:'PlayersBack';     id_N:5000; Pic:0), {backs}
                    (Name:'NormalBack';      id_N:5001; Pic:0));

 TYPE PARR8INTS  = ^TARR8INTS;
      TARR8INTS  = ARRAY[0..7] OF INTEGER;
      PMESS_DLG  = ^TMESS_DLG;          {message box dialog}
      TMESS_DLG  = OBJECT(TDIALOG)
                    TheMsg, Titl : STRING;
                    CONSTRUCTOR Init(Parent, Owner : HWND; hMod : HMODULE;
                                     idDlg : LONGWORD;
                                     pCreateParams : POINTER;
                                     AMsg, ATitl : STRING);
                    PROCEDURE WMInitDlg(VAR Msg : TMESSAGE);
                     VIRTUAL wm_First + wm_InitDlg;
                   END;
      PYRMY_HAND = ^TYRMY_HAND;         {general hand object}
      TYRMY_HAND = OBJECT
                    HHH    : ARRAY[0..6] OF INTEGER;
                    ParWnd : HWND;
                    CONSTRUCTOR Init(ParentWnd : HWND);
                    PROCEDURE WriteDistance(id_N : LONG; Dist : INTEGER);
                    FUNCTION  GetTheIndex(C : INTEGER) : INTEGER;
                    PROCEDURE Show_Card(C : LONGWORD; P : HBITMAP; CC : INTEGER);
                    PROCEDURE SetRoll(Who : BYTE);
                    FUNCTION  GetTheMilageNumber : INTEGER;
                    PROCEDURE MileageSound;
                   END;
      PMY_HAND   = ^TMY_HAND;           {computers hand object}
      TMY_HAND   = OBJECT(TYRMY_HAND)
                    CONSTRUCTOR Init(ParentWnd : HWND);
                    PROCEDURE FigureCard1(VAR SF, CF, HZ, M, N : INTEGER);
                    PROCEDURE FigureCard2(VAR SF, CF, HZ, M, N : INTEGER;
                                          VAR DStr : STRING);
                    PROCEDURE FigureCard3(VAR Chh, M, N, HZ : INTEGER);
                    PROCEDURE FigureCard4(VAR Chh, N : INTEGER);
                    PROCEDURE FigureCard5(VAR Chh, N : INTEGER);
                    PROCEDURE FigureCard6(VAR Chh, M, N : INTEGER);
                    PROCEDURE FigureCard7(VAR DStr : STRING;
                                          VAR N, SF, CF, M, HZ : INTEGER);
                    PROCEDURE DisplayCCard(N, CF : INTEGER; VAR DStr : STRING);
                    PROCEDURE PlayComsHand(VAR DStr : STRING);
                   END;
      PYOUR_HAND = ^TYOUR_HAND;         {players hand object}
      TYOUR_HAND = OBJECT(TYRMY_HAND)
                    PlayedCard : INTEGER;
                    CONSTRUCTOR Init(ParentWnd : HWND);
                    PROCEDURE DisplayHand;
                    PROCEDURE PlayerPlayCard(VAR Cur : INTEGER);
                    PROCEDURE PlayerDiscardCard(VAR Cur : INTEGER);
                   END;
      PENDDLG    = ^TENDDLG;            {end round/game dialog}
      TENDDLG    = OBJECT(TDIALOG)
                    End_Flg : BOOLEAN;
                    CONSTRUCTOR Init(Parent, Owner : HWND; hMod : HMODULE;
                                     idDlg : LONGWORD; pCreateParams : POINTER;
                                     VAR AFlg : BOOLEAN);
                    PROCEDURE CMYes(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_Yes;
                    PROCEDURE CMNo(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_No;
                    PROCEDURE WMInitDlg(VAR Msg : TMESSAGE);
                     VIRTUAL wm_First + wm_InitDlg;
                   END;
      PCHOICEDLG = ^TCHOICEDLG;         {select card dialog}
      TCHOICEDLG = OBJECT(TDIALOG)
                    PlayOne : BOOL;
                    CONSTRUCTOR Init(Parent, Owner : HWND; hMod : HMODULE;
                                     idDlg : LONGWORD; PlyF : BOOL;
                                     pCreateParams : POINTER);
                    PROCEDURE CMBut1(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_But1;
                    PROCEDURE CMBut2(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_But2;
                    PROCEDURE CMBut3(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_But3;
                    PROCEDURE CMBut4(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_But4;
                    PROCEDURE CMBut5(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_But5;
                    PROCEDURE CMBut6(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_But6;
                    PROCEDURE CMBut7(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_But7;
                    PROCEDURE WMInitDlg(VAR Msg : TMESSAGE);
                     VIRTUAL wm_First + wm_InitDlg;
                   END;
      PMS_WIN    = ^TMS_WIN;            {main window object}
      TMS_WIN    = OBJECT(TDIALOG)
                    C_Hand  : PMY_HAND;                 {computers hand}
                    U_Hand  : PYOUR_HAND;               {players hand}
                    FirstGame,                          {new/game over flag}
                    P_Play  : BOOLEAN;                  {players playing}
                    CCC     : ARRAY[1..106] OF INTEGER; {card deck}
                    Top,                                {players cards left (end)}
                    Cntt    : INTEGER;                  {number of cards played}
                    HelpI   : HELPINIT;                 {help init struct}
                    HelpTitle,                          {help sys title}
                    HelpLib : CSTRING;                  {help library}
                    HelpWnd : HWND;                     {help sys window}
                    CONSTRUCTOR Init(Parent, Owner : HWND; hMod : HMODULE;
                                     idDlg : LONGWORD; pCreateParams : POINTER);
                    DESTRUCTOR Done; VIRTUAL;
                    PROCEDURE ShuffleCards;
                    PROCEDURE ResetGameBoard;
                    PROCEDURE Init_GameVars(Start : BOOLEAN);
                    PROCEDURE DisplayCard(Card : INTEGER; id_C : LONG);
                    PROCEDURE DisplayCardsLeft;
                    PROCEDURE ShowMsg(VAR Msg : STRING);
                    PROCEDURE DoEnd;
                    PROCEDURE EnabControls(Enab, AllB : BOOL);
                    PROCEDURE GetNewCard;
                    PROCEDURE CMCompPlay(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_CompPlay;
                    PROCEDURE CMPlay(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_Play;
                    PROCEDURE CMDiscard(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_Discard;
                    PROCEDURE CMStartNew(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_StartNew;
                    PROCEDURE CMHelp(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_Help;
                    PROCEDURE CMInitDraw(VAR Msg : TMESSAGE);
                     VIRTUAL cm_First + cm_InitDraw;
                    PROCEDURE WMInitDlg(VAR Msg : TMESSAGE);
                     VIRTUAL wm_First + wm_InitDlg;
                    PROCEDURE WMPaint(VAR Msg : TMESSAGE);
                     VIRTUAL wm_First + wm_Paint;
                    PROCEDURE WMSysCommand(VAR Msg : TMESSAGE);
                     VIRTUAL wm_First + wm_SysCommand;
                   END;
      PSTUBWIN   = ^TSTUBWIN;
      TSTUBWIN   = OBJECT(TWINDOW)      {stub window to hold dialog main window}
                    MainDlg : PMS_WIN;
                    PROCEDURE SetupWindow; VIRTUAL;
                   END;
      TMS_APP    = OBJECT(TAPPLICATION) {application object}
                    PROCEDURE InitMainWindow; VIRTUAL;
                   END;

 CONST {wm_paint holding arrays}
       ShowYC   : ARRAY[id_UserC1..id_UserC7] OF INTEGER = (21,21,21,21,21,21,21);
       ShwYPile : ARRAY[id_YSpeed..id_YSafe4] OF INTEGER = (22,22,22,22,22,22);
       ShwMPile : ARRAY[id_MSpeed..id_MSafe4] OF INTEGER = (22,22,22,22,22,22);
       ShwDisc  : INTEGER = 22;
       PaintNow : BOOLEAN = FALSE;

 VAR SSA      : TARR8INTS;                   {global score array}
     PPL      : ARRAY[0..1,0..3] OF INTEGER; {hazard array}
     Safety   : ARRAY[0..1,1..5] OF INTEGER; {array of safeties played}
     RndCt,                                  {round counter}
     SSS,                                    {cards in hand for comp}
     KKK, LLL : INTEGER;                     {position holders}
     YCT, MCT : BOOLEAN;                     {complete trip flags}

(************************************************************************)
(** Message dialog object (TDIALOG)                                    **)
(************************************************************************)

 CONSTRUCTOR TMESS_DLG.Init(Parent, Owner : HWND; hMod : HMODULE; idDlg : LONGWORD;
                            pCreateParams : POINTER; AMsg, ATitl : STRING);
     (* constructor to create end dialog *)

  BEGIN (*tmess_dlg.init*)
   TheMsg := AMsg; Titl := ATitl;
   INHERITED Init(Parent,Owner,hMod,idDlg,pCreateParams);
  END; (*tmess_dlg.init*)

(************************************************************************)

 PROCEDURE TMESS_DLG.WMInitDlg(VAR Msg : TMESSAGE);
     (* procedure to initialize message dialog *)

    VAR H : HWND;

  BEGIN (*tmess_dlg.wminitdlg*)
   INHERITED WMInitDlg(Msg);
   H := Msg.Receiver;
   WinSetWindowText(H,Titl);
   WinSetDlgItemText(H,id_MessLine,TheMsg);
  END; (*tmess_dlg.wminitdlg*)

(************************************************************************)
(** Message box function                                               **)

 FUNCTION Mess_Box(PWnd : HWND; Msg, Titl : STRING) : INTEGER;
     (* function to run a dialog message box for program *)


    VAR Dlg : PMESS_DLG;

  BEGIN (*mess_box*)
   Dlg := New(PMESS_DLG,Init(1,PWnd,0,id_Mess,NIL,Msg,Titl));
   Mess_Box := Dlg^.ExecDialog;
   Dispose(Dlg,Done);
  END; (*mess_box*)

(**                                                                    **)
(************************************************************************)
(** Generic hand object (TOBJECT)                                      **)
(************************************************************************)

 CONSTRUCTOR TYRMY_HAND.Init(ParentWnd : HWND);
     (* constructor to create hand object *)

  BEGIN (*tyrmy_hand.init*)
   FillChar(HHH,SizeOf(HHH),0); ParWnd := ParentWnd;
  END; (*tyrmy_hand.init*)

(************************************************************************)

 PROCEDURE TYRMY_HAND.WriteDistance(id_N : LONG; Dist : INTEGER);
     (* procedure to write up score/distance on screen *)

    VAR S : STRING[10];

  BEGIN (*tyrmy_hand.writedistance*)
   Str(Dist,S);
   WinSetDlgItemText(ParWnd,id_N,S);
  END; (*tyrmy_hand.writedistance*)

(************************************************************************)

 FUNCTION TYRMY_HAND.GetTheIndex(C : INTEGER) : INTEGER;
     (* function to return the index of the card (ConTTSt) *)

    VAR I, J : INTEGER;

  BEGIN (*tyrmy_hand.gettheindex*)
   GetTheIndex := -1; I := 1;
   WHILE I < 5 DO
    BEGIN {i loop}
     J := 1;
     WHILE J < 6 DO
      BEGIN {j loop}
       IF C > ConTT1[I]
        THEN J := 6
       ELSE IF C < ConTT2[I,J]
             THEN BEGIN {assign index value - found}
                   GetTheIndex := ((I-1)*5+1)+(J-1);
                   KKK := I; LLL := J; I := 5; J := 6;
                  END; {else - then}
       Inc(J);
      END; {while loop}
     Inc(I);
    END; {while loop}
  END; (*tyrmy_hand.gettheindex*)

(************************************************************************)

 PROCEDURE TYRMY_HAND.Show_Card(C : LONGWORD; P : HBITMAP; CC : INTEGER);
     (* procedure to show the card (for comps and players hand) *)

    VAR W    : HWND;
        Ahps : HPS;
        S    : SWP;
        T    : POINTL;

  BEGIN (*tyrmy_hand.show_card*)
   W := WinWindowFromID(ParWnd,C);
   WinQueryWindowPos(W,S);
   T.X := S.X; T.Y := S.Y;
   Ahps := WinGetPS(ParWnd);
   WinDrawBitmap(Ahps,P,NIL,T,0,0,dbm_Normal);
   WinReleasePS(Ahps);
   CASE C OF  {set up for paint}
    120..126 : ShowYC[C] := CC;
    130..135 : ShwYPile[C] := CC;
    140..145 : ShwMPile[C] := CC;
    ELSE ShwDisc := CC;
   END; {case}
  END; (*tyrmy_hand.show_card*)

(************************************************************************)

 PROCEDURE TYRMY_HAND.SetRoll(Who : BYTE);
     (* procedure to do set roll card if have right-a-way *)

    VAR C : LONGWORD;
        P : HBITMAP;

  BEGIN (*tyrmy_hand.setroll*)
   IF (Safety[Who,5] = 1) AND (PPL[Who,2] > -1)
    THEN BEGIN {set roll card for player/computer}
          PPL[Who,2] := 5; P := ConTTSt[10].Pic; {roll picture}
          IF Who = G_Player THEN C := id_YBattle ELSE C := id_MBattle;
          Show_Card(C,P,10);
         END; {then}
  END; (*tyrmy_hand.setroll*)

(************************************************************************)

 FUNCTION TYRMY_HAND.GetTheMilageNumber : INTEGER;
     (* function to get the number of a mileage card *)

    VAR I : INTEGER;

  BEGIN (*tyrmy_hand.getthemilagenumber*)
   CASE LLL OF
    1 : I := 200;
    2 : I := 100;
    3 : I := 75;
    4 : I := 50;
    5 : I := 25;
   END; {case}
   IF KKK <> 4 THEN I := 0;
   GetTheMilageNumber := I;
  END; (*tyrmy_hand.getthemilagenumber*)

(************************************************************************)

 PROCEDURE TYRMY_HAND.MileageSound;
     (* procedure to make mileage sound *)

    VAR I : INTEGER;

  BEGIN (*tyrmy_hand.mileagesound*)
   FOR I := 1 TO 30 DO
    Beep(50,2);
  END; (*tyrmy_hand.mileagesound*)

(************************************************************************)
(** Players hand object (TYRMY_HAND)                                   **)
(************************************************************************)

 CONSTRUCTOR TYOUR_HAND.Init(ParentWnd : HWND);
     (* constructor to create the users hand (player) *)

  BEGIN (*tyour_hand.init*)
   INHERITED Init(ParentWnd);
   PlayedCard := -1;
  END; (*tyour_hand.init*)

(************************************************************************)

 PROCEDURE TYOUR_HAND.DisplayHand;
     (* procedure to display the players hand (initial) *)

    VAR I, Idx : INTEGER;
        C      : LONGWORD;
        P      : HBITMAP;

  BEGIN (*tyour_hand.displayhand*)
   C := id_UserC1; {set to first card picture}
   FOR I := 0 TO 6 DO
    BEGIN {loop through hand and display cards}
     IF HHH[I] <> -1
      THEN Idx := GetTheIndex(HHH[I])
     ELSE Idx := -1;
     IF Idx <> -1
      THEN P := ConTTSt[Idx].Pic {card picture}
     ELSE P := ConTTSt[21].Pic; {back picture}
     IF Idx = -1 THEN Idx := 21;
     Show_Card(C,P,Idx);
     Inc(C);
    END; {for loop}
  END; (*tyour_hand.displayhand*)

(************************************************************************)

 PROCEDURE TYOUR_HAND.PlayerPlayCard(VAR Cur : INTEGER);
     (* procedure to play the players choosen card *)

    CONST CntPly : STRING[15] = 'You can''t play';

    VAR St, I : INTEGER;
        Msg   : STRING[80];
        C     : LONGWORD;
        CF    : BOOLEAN;

  BEGIN (*tyour_hand.playerplaycard*)
   IF HHH[Cur-1] = -1
    THEN BEGIN {no card to play}
          Msg := 'There''s no card to play there.';
          Beep(500,400);
          Mess_Box(ParWnd,Msg,CntPly);
          Cur := -1;
          Exit;
         END; {then}
   St := GetTheIndex(HHH[Cur-1]);
   Msg := '';
   CASE KKK OF
    1 : BEGIN {kkk = 1 (playing hazard)}
         IF (LLL <> 4) AND (PPL[G_Computer,2] < 5)
          THEN Msg := 'I don''t have a Roll card';
         IF (LLL <> 4) AND (PPL[G_Computer,2] < 0)
          THEN Msg := 'I already have a hazard';
         IF (LLL = 4) AND (PPL[G_Computer,1] < 0)
          THEN Msg := 'I have a SPEED LIMIT';
         IF (LLL = 4) AND (Safety[G_Computer,5] = 1)
          THEN Msg := 'I have the Right-of-Way';
         IF Safety[G_Computer,LLL] = 1 THEN Msg := 'I have the safety';
         IF Msg <> ''
          THEN BEGIN {write up no-play message}
                Beep(500,400);
                Mess_Box(ParWnd,Msg,CntPly);
                Cur := -1;
                Exit;
               END; {then}
         IF LLL <> 4
          THEN PPL[G_Computer,2] := -LLL
         ELSE PPL[G_Computer,1] := -4;
         IF LLL = 4
          THEN Show_Card(id_MSpeed,ConTTSt[St].Pic,St) {card on comps speed pile}
         ELSE Show_Card(id_MBattle,ConTTSt[St].Pic,St); {card on comps battle pile}
        END; {1}
    2 : BEGIN {kkk = 2 (playing either battle/speed piles)}
         IF LLL <> 5
          THEN BEGIN
                IF (LLL = 4) AND (PPL[G_Player,1] = -4)
                 THEN PPL[G_Player,1] := 4
                ELSE IF PPL[G_Player,2] <> -LLL
                      THEN Msg := 'You don''t need to do that';
                IF (Msg = '') AND (LLL <> 4) THEN PPL[G_Player,2] := LLL;
               END {then}
         ELSE BEGIN
               IF PPL[G_Player,2] = 5 THEN Msg := 'You have a Roll card';
               IF PPL[G_Player,2] < 0
                THEN BEGIN
                      Msg := 'You have a HAZARD';
                      IF PPL[G_Player,2] = -5 THEN Msg := '';
                     END;
               IF Msg = '' THEN PPL[G_Player,2] := 5;
              END; {else}
         IF Msg <> ''
          THEN BEGIN {no play message}
                Beep(500,400);
                Mess_Box(ParWnd,Msg,CntPly);
                Cur := -1;
                Exit;
               END; {then}
         IF LLL <> 4
          THEN Show_Card(id_YBattle,ConTTSt[St].Pic,St) {battle pile}
         ELSE Show_Card(id_YSpeed,ConTTSt[St].Pic,St); {speed pile}
        END; {2}
    3 : BEGIN {kkk = 3 (playing a safety)}
         CF := FALSE;
         IF PPL[G_Player,2] = -LLL
          THEN BEGIN {had hazard safety took care of}
                PPL[G_Player,2] := LLL;
                CF := TRUE;
               END; {then}
         IF (LLL = 5) AND (PPL[G_Player,1] < 0) THEN CF := TRUE;
         SSA[5] := SSA[5] + 100;
         Safety[G_Player,LLL] := 1;
         IF CF
          THEN BEGIN {display message}
                Beep(50,500);
                Beep(320,500);
                Beep(700,500);
                Mess_Box(ParWnd,'Got me','= = > COUP FOURRE < = =');
                SSA[3] := SSA[3] + 300;
               END; {then}
         IF LLL = 5
          THEN BEGIN {right-of-way played}
                Safety[G_Player,4] := 1; Safety[G_Player,5] := 1;
                PPL[G_Player,1] := 4;
                Show_Card(id_YSpeed,ConTTSt[9].Pic,9);
               END;
         IF ConTTSt[St].Name[1] = 'R' THEN C := id_YSafe1;
         IF ConTTSt[St].Name[1] = 'E' THEN C := id_YSafe2;
         IF ConTTSt[St].Name[1] = 'P' THEN C := id_YSafe3;
         IF ConTTSt[St].Name[1] = 'D' THEN C := id_YSafe4;
         Show_Card(C,ConTTSt[St].Pic,St);
         IF CF AND (PPL[G_Player,2] = LLL)
          THEN BEGIN {display remedy over hazard}
                I := ((2-1)*5+1)+(LLL-1);
                Show_Card(id_YBattle,ConTTSt[I].Pic,I);
               END; {then}
         CF := FALSE;
        END; {3}
    4 : BEGIN {kkk = 4 (playing milage card)}
         I := GetTheMilageNumber;
         IF PPL[G_Player,0]+I > 1000
          THEN Msg := 'You have exceeded 1000 miles';
         IF (PPL[G_Player,1] = -4) AND (I > 50)
          THEN Msg := 'You have a '+ConTTSt[4].Name + ' card';
         IF PPL[G_Player,2] < 5
          THEN Msg := 'You don''t have a Roll card';
         IF PPL[G_Player,2] < 0 THEN Msg := 'You have a HAZARD';
         IF Msg <> ''
          THEN BEGIN {display the message}
                Beep(500,400);
                Mess_Box(ParWnd,Msg,CntPly);
                Cur := -1;
                Exit;
               END; {then}
         MileageSound;
         PPL[G_Player,0] := PPL[G_Player,0] + I;
         WriteDistance(id_YDistance,PPL[G_Player,0]);
        END; {4}
   END; {case}
   Show_Card(id_UserC1 + Cur - 1,ConTTSt[21].Pic,21);
   HHH[Cur-1] := -1;
  END; (*tyour_hand.playerplaycard*)

(************************************************************************)

 PROCEDURE TYOUR_HAND.PlayerDiscardCard(VAR Cur : INTEGER);
     (* procedure to discard the players choosen card *)

    CONST CntDis : STRING[18] = 'You can''t discard';

    VAR St  : INTEGER;
        Msg : STRING[33];

  BEGIN (*tyour_hand.playerdiscardcard*)
   IF HHH[Cur-1] = -1
    THEN BEGIN {no card to play}
          Msg := 'There''s no card to discard there.';
          Beep(500,400);
          Mess_Box(ParWnd,Msg,CntDis);
          Cur := -1;
          Exit;
         END; {then}
   St := GetTheIndex(HHH[Cur-1]);
   Show_Card(id_Discard,ConTTSt[St].Pic,St);
   Show_Card(id_UserC1 + Cur - 1,ConTTSt[21].Pic,21);
   HHH[Cur-1] := -1;
  END; (*tyour_hand.playerdiscardcard*)

(************************************************************************)
(** Computers hand object (TYRMY_HAND)                                 **)
(************************************************************************)

 CONSTRUCTOR TMY_HAND.Init(ParentWnd : HWND);
     (* constructor to create the computers hand  *)

  BEGIN (*tmy_hand.init*)
   INHERITED Init(ParentWnd);
  END; (*tmy_hand.init*)

(************************************************************************)

 PROCEDURE TMY_HAND.FigureCard1(VAR SF, CF, HZ, M, N : INTEGER);
     (* procedure to figure out which card to play *)

    VAR A, I, St : INTEGER;
        Tp       : REAL;

  BEGIN (*tmy_hand.figurecard1*)
   SF := 0; CF := 0; A := SSS;
   WHILE A <= 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     IF KKK = 3
      THEN BEGIN
            IF (PPL[G_Computer,1] < 0) AND (LLL = 5) THEN CF := 1;
            Tp := 1;
            FOR I := 1 TO LLL-1 DO
             Tp := Tp * 2;
            SF := SF + Round(Tp+0.5); M := LLL; N := A;
            IF LLL = -HZ THEN CF := 2;
            IF LLL = 5 THEN SF := SF + 8;
            IF CF > 0 THEN A := 6;
           END; {then}
     Inc(A);
    END; {while}
  END; (*tmy_hand.figurecard1*)

(************************************************************************)

 PROCEDURE TMY_HAND.FigureCard2(VAR SF, CF, HZ, M, N : INTEGER; VAR DStr : STRING);
     (* procedure to figure out a card to play *)

    VAR I, J, St : INTEGER;

  BEGIN (*tmy_hand.figurecard2*)
   FigureCard1(SF,CF,HZ,M,N);
   IF SF > 0
    THEN BEGIN {playing safety card}
          Safety[G_Computer,M] := 1;
          DStr := 'PLAY';
          SSA[4] := SSA[4] + 100;
          Exit;
         END; {then}
   J := 1;
   REPEAT
    REPEAT
     N := Random(7);
    UNTIL N >= SSS;
    IF SSS > 0 THEN Exit;
    St := GetTheIndex(HHH[N]);
    I := GetTheMilageNumber;
    Inc(J);
   UNTIL (KKK <> 4) OR (I < 100) OR (J = 20);
  END; (*tmy_hand.figurecard2*)

(************************************************************************)

 PROCEDURE TMY_HAND.FigureCard3(VAR Chh, M, N, HZ : INTEGER);
     (* procedure to figure out a card to play *)

    VAR A, St : INTEGER;

  BEGIN (*tmy_hand.figurecard3*)
   Chh := 0; A := SSS;
   WHILE A <= 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     IF (KKK = 2) AND (LLL = -HZ)
      THEN BEGIN
            Chh := 2; M := LLL; N := A; A := 6;
           END {then}
     ELSE IF (KKK = 2) AND (LLL = 4) AND (PPL[G_Computer,1] = -4)
           THEN BEGIN
                 Chh := 1; M := LLL; N := A; A := 6;
                END; {else - then}
     Inc(A);
    END; {while}
  END; (*tmy_hand.figurecard3*)

(************************************************************************)

 PROCEDURE TMY_HAND.FigureCard4(VAR Chh, N : INTEGER);
     (* procedure to figure out which card to play *)

    VAR A, St : INTEGER;

  BEGIN (*tmy_hand.figurecard4*)
   Chh := 0; A := SSS;
   WHILE (A <= 6) DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     IF (KKK = 2) AND (LLL = 4)
      THEN BEGIN
            Chh := 1; N := A; A := 6;
           END; {then}
     Inc(A);
    END; {while}
  END; (*tmy_hand.figurecard4*)

(************************************************************************)

 PROCEDURE TMY_HAND.FigureCard5(VAR Chh, N : INTEGER);
     (* procedure to figure out a card to play *)

    VAR A, St : INTEGER;

  BEGIN (*tmy_hand.figurecard5*)
   Chh := 0;
   FOR A := SSS TO 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     IF (KKK = 2) AND (LLL = 5)
      THEN BEGIN
            Chh := 1; N := A; Exit;
           END; {then}
    END; {for loop}
  END; (*tmy_hand.figurecard5*)

(************************************************************************)

 PROCEDURE TMY_HAND.FigureCard6(VAR Chh, M, N : INTEGER);
     (* procedure to figure out a card to play *)

    VAR A, St : INTEGER;

  BEGIN (*tmy_hand.figurecard6*)
   Chh := 0; A := SSS;
   WHILE A <= 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     IF (KKK = 1) AND (LLL = 4) AND (PPL[G_Player,1] > -1)
      THEN BEGIN
            Chh := 1; M := LLL; N := A;
           END; {then}
     IF (KKK = 1) AND (LLL <> 4) AND (PPL[G_Player,2] > 0)
      THEN BEGIN
            Chh := 2; M := LLL; N := A;
           END; {then}
     IF Safety[G_Player,LLL] = 1 THEN Chh := 0;
     IF Chh > 0 THEN A := 6;
     Inc(A);
    END; {while}
  END; (*tmy_hand.figurecard6*)

(************************************************************************)

 PROCEDURE TMY_HAND.FigureCard7(VAR DStr : STRING; VAR N,SF,CF,M,HZ : INTEGER);
     (* procedure to figure out which card to play *)

    VAR A, I, St : INTEGER;

  BEGIN (*tmy_hand.figurecard7*)
   DStr := 'DISCARD'; A := SSS;
   WHILE A <= 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     IF ((KKK = 1) AND (Safety[G_Computer,LLL] = 1)) OR
        ((KKK = 1) AND (LLL = 4) AND (PPL[G_Player,0] > 949)) OR
        ((KKK = 2) AND ((Safety[G_Computer,LLL] = 1) OR (SF > 0)))
      THEN BEGIN
            N := A; Exit;
           END; {then}
     I := GetTheMilageNumber;
     IF I <> 0
      THEN BEGIN
            IF (KKK = 4) AND (I > (1000-PPL[G_Computer,0]))
             THEN BEGIN
                   N := A; Exit;
                  END; {then}
           END; {then}
     Inc(A);
    END; {while}
   A := SSS;
   WHILE A <= 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     I := GetTheMilageNumber;
     IF I <> 0
      THEN BEGIN
            IF (KKK = 4) AND (I < 76)
             THEN BEGIN
                   N := A; Exit;
                  END; {then}
           END; {then}
     Inc(A);
    END; {while}
   A := SSS;
   WHILE A <= 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     IF ((KKK = 1) AND ((Safety[G_Computer,LLL] = 0) OR (SF = 0))) OR
        ((KKK = 2) AND (Safety[G_Player,LLL] = 0))
      THEN BEGIN
            N := A; Exit;
           END; {then}
     Inc(A);
    END; {while}
   FigureCard2(SF,CF,HZ,M,N,DStr);
  END; (*tmy_hand.figurecard7*)

(************************************************************************)

 PROCEDURE TMY_HAND.DisplayCCard(N, CF : INTEGER; VAR DStr : STRING);
     (* procedure to display the card choosen by the computer *)

    VAR I, St : INTEGER;
        Msg   : STRING[90];
        C     : LONGWORD;

  BEGIN (*tmy_hand.displayccard*)
   St := GetTheIndex(HHH[N]);
   Msg := 'I will ' + DStr + ' a ' + ConTTSt[St].Name + ' card.';
   Beep(700,300);
   Mess_Box(ParWnd,Msg,'Computers Move');
   IF Length(DStr) > 6
    THEN BEGIN {discard move}
          Show_Card(id_Discard,ConTTSt[St].Pic,St);
          HHH[N] := HHH[SSS];
          Exit;
         END; {then}
   IF CF > 0
    THEN BEGIN {coup fourre}
          Beep(50,500);
          Beep(320,500);
          Beep(700,500);
          Mess_Box(ParWnd,'Got you','= = > COUP FOURRE < = =');
         END; {then}
   IF KKK = 4
    THEN BEGIN {play milage}
          MileageSound;
          WriteDistance(id_MDistance,PPL[G_Computer,0]);
          HHH[N] := HHH[SSS];
          Exit;
         END; {then}
   IF KKK = 3
    THEN BEGIN {play a safety}
          IF LLL = 5
           THEN BEGIN {right of way}
                 Safety[G_Computer,4] := 1; Safety[G_Computer,5] := 1;
                 PPL[G_Computer,1] := 4;
                 Show_Card(id_MSpeed,ConTTSt[9].Pic,9);
                END; {then}
          IF ConTTSt[St].Name[1] = 'R' THEN C := id_MSafe1;
          IF ConTTSt[St].Name[1] = 'E' THEN C := id_MSafe2;
          IF ConTTSt[St].Name[1] = 'P' THEN C := id_MSafe3;
          IF ConTTSt[St].Name[1] = 'D' THEN C := id_MSafe4;
          Show_Card(C,ConTTSt[St].Pic,St);
          IF (CF > 1) AND (PPL[G_Computer,2] = LLL)
           THEN BEGIN {display remedy of hazard}
                 I := ((2-1)*5+1)+(LLL-1);
                 Show_Card(id_MBattle,ConTTSt[I].Pic,I);
                END; {then}
          HHH[N] := HHH[SSS];
          Exit;
         END; {then}
   IF KKK = 2
    THEN BEGIN {playing battle/speed pile}
          IF LLL <> 4
           THEN Show_Card(id_MBattle,ConTTSt[St].Pic,St) {battle pile}
          ELSE Show_Card(id_MSpeed,ConTTSt[St].Pic,St); {speed pile}
          HHH[N] := HHH[SSS];
          Exit;
         END; {then}
   IF LLL <> 4 {play on players battle/speed piles}
    THEN Show_Card(id_YBattle,ConTTSt[St].Pic,St) {battle pile}
   ELSE Show_Card(id_YSpeed,ConTTSt[St].Pic,St); {speed pile}
   HHH[N] := HHH[SSS];
  END; (*tmy_hand.displayccard*)

(************************************************************************)

 PROCEDURE TMY_HAND.PlayComsHand(VAR DStr : STRING);
     (* procedure to play the computers card *)

    LABEL L1, L2, L3, L4, L5;

    VAR LM, CF, SF, HZ, M, N, Chh, D, A, I, St : INTEGER;

  BEGIN (*tmy_hand.playcomshand*)
   N := 0; CF := 0; HZ := PPL[G_Computer,2];
   IF (HZ > -1) AND (PPL[G_Computer,1] > -1) THEN GOTO L1;
   FigureCard1(SF,CF,HZ,M,N);
   IF CF > 0
    THEN BEGIN {play safety (cf)}
          Safety[G_Computer,M] := 1;
          PPL[G_Computer,CF] := M;
          SSA[2] := SSA[2] + 300;
          SSA[4] := SSA[4] + 100;
          GOTO L4;
         END; {then}
   IF (SSS > 0) OR (PPL[G_Player,0] > 790) OR (PPL[G_Computer,0] > 790)
    THEN BEGIN
          FigureCard2(SF,CF,HZ,M,N,DStr);
          IF SF > 0 THEN GOTO L4;
         END;
   FigureCard3(Chh,M,N,HZ);
   IF Chh > 0
    THEN BEGIN
          PPL[G_Computer,Chh] := M; GOTO L4;
         END;
   IF PPL[G_Computer,2] > -1 THEN GOTO L1;
   GOTO L3;
   L1:
   IF PPL[G_Computer,2] < 5 THEN GOTO L2;
   LM := 201;
   IF PPL[G_Computer,1] < 0 THEN LM := 51;
   IF (LM < 200) AND (PPL[G_Computer,0] < 900)
    THEN BEGIN
          FigureCard4(Chh,N);
          IF Chh > 0
           THEN BEGIN
                 PPL[G_Computer,1] := 4; GOTO L4;
                END;
         END; {then}
   Chh := 0; D := 0; A := SSS;
   WHILE A <= 6 DO
    BEGIN
     St := GetTheIndex(HHH[A]);
     I := GetTheMilageNumber;
     IF I <> 0
      THEN BEGIN
            IF (I < LM) AND (I+PPL[G_Computer,0] < 1001) AND (I > D)
             THEN BEGIN
                   D := I; N := A; Chh := 1;
                  END;
           END; {then}
     Inc(A);
    END; {while}
   IF Chh > 0
    THEN BEGIN
          PPL[G_Computer,0] := PPL[G_Computer,0] + D; GOTO L4;
         END; {then}
   GOTO L3;
   L2:
   FigureCard5(Chh,N);
   IF (Chh > 0) AND (PPL[G_Computer,2] > -1)
    THEN BEGIN
          PPL[G_Computer,2] := 5; GOTO L4;
         END;
   L3:
   IF (PPL[G_Player,2] < 0) AND (PPL[G_Player,1] < 0) THEN GOTO L5;
   FigureCard6(Chh,M,N);
   CASE Chh OF
    1 : IF PPL[G_Player,0] < 950
         THEN BEGIN
               PPL[G_Player,1] := -4; GOTO L4;
              END;
    2 : IF PPL[G_Player,2] = 5
         THEN BEGIN
               PPL[G_Player,2] := -M; GOTO L4;
              END;
   END; {case}
   L5: FigureCard7(DStr,N,SF,CF,M,HZ);
   L4: DisplayCCard(N,CF,DStr);
  END; (*tmy_hand.playcomshand*)

(************************************************************************)
(** End round/game dialog object (TDIALOG)                             **)
(************************************************************************)

 CONSTRUCTOR TENDDLG.Init(Parent, Owner : HWND; hMod : HMODULE; idDlg : LONGWORD;
                          pCreateParams : POINTER; VAR AFlg : BOOLEAN);
     (* constructor to create end dialog *)

  BEGIN (*tenddlg.init*)
   End_Flg := AFlg;
   INHERITED Init(Parent,Owner,hMod,idDlg,pCreateParams);
  END; (*tenddlg.init*)

(************************************************************************)

 PROCEDURE TENDDLG.CMYes(VAR Msg : TMESSAGE);
     (* procedure used to handle yes button press *)

  BEGIN (*tenddlg.cmyes*)
   Msg.Result := cm_Yes;
  END; (*tenddlg.cmyes*)

(************************************************************************)

 PROCEDURE TENDDLG.CMNo(VAR Msg : TMESSAGE);
     (* procedure to handle no button press *)

  BEGIN (*tenddlg.cmno*)
   Msg.Result := cm_No;
  END; (*tenddlg.cmno*)

(************************************************************************)

 PROCEDURE TENDDLG.WMInitDlg(VAR Msg : TMESSAGE);
     (* procedure to initialize end dialog *)

    VAR T    : CSTRING[255];
        NStr : STRING[5];
        H    : HWND;

  BEGIN (*tenddlg.wminitdlg*)
   INHERITED WMInitDlg(Msg);
   H := Msg.Receiver;
   IF End_Flg
    THEN BEGIN {end of game - change title and prompt}
          WinLoadString(AppHandle,NullHandle,ids_EndGameTit,SizeOf(T),T);
          WinSetWindowText(H,T);
          WinLoadString(AppHandle,NullHandle,ids_EndGamPrmt,SizeOf(T),T);
          WinSetDlgItemText(H,id_EndPrompt,T);
         END; {then}
   Inc(RndCt); Str(RndCt,NStr);
   IF Length(NStr) = 1 THEN NStr := ' ' + NStr;
   WinQueryDlgItemText(H,id_RoundTxt,254,T);
   T[6] := NStr[1]; T[7] := NStr[2];
   WinSetDlgItemText(H,id_RoundTxt,T);
   {set mileage totals}
   Str(PPL[G_Computer,0],NStr); WinSetDlgItemText(H,id_M_Dist,NStr);
   Str(PPL[G_Player,0],NStr); WinSetDlgItemText(H,id_Y_Dist,NStr);
   {set bonus total}
   IF MCT THEN WinSetDlgItemText(H,id_M_CompTrp,'400');
   IF YCT THEN WinSetDlgItemText(H,id_Y_CompTrp,'400');
   {set coup foures totals}
   Str(SSA[2],NStr); WinSetDlgItemText(H,id_M_CoupF,NStr);
   Str(SSA[3],NStr); WinSetDlgItemText(H,id_Y_CoupF,NStr);
   {set safety totals}
   Str(SSA[4],NStr); WinSetDlgItemText(H,id_M_Safe,NStr);
   Str(SSA[5],NStr); WinSetDlgItemText(H,id_Y_Safe,NStr);
   {set shutout bonus, if any}
   IF PPL[G_Player,0] = 0 THEN WinSetDlgItemText(H,id_M_ShutOut,'500');
   IF PPL[G_Computer,0] = 0 THEN WinSetDlgItemText(H,id_Y_ShutOut,'500');
   {set round totals}
   Str(SSA[6],NStr); WinSetDlgItemText(H,id_M_RoundT,NStr);
   Str(SSA[7],NStr); WinSetDlgItemText(H,id_Y_RoundT,NStr);
   {set grand totals}
   Str(SSA[0],NStr); WinSetDlgItemText(H,id_M_GrandT,NStr);
   Str(SSA[1],NStr); WinSetDlgItemText(H,id_Y_GrandT,NStr);
  END; (*tenddlg.wminitdlg*)

(************************************************************************)
(** Choice dialog object (TDIALOG)                                     **)
(************************************************************************)

 CONSTRUCTOR TCHOICEDLG.Init(Parent, Owner : HWND; hMod : HMODULE; idDlg : LONGWORD;
                             PlyF : BOOL; pCreateParams : POINTER);
     (* constructor to initialize choice dialog *)

  BEGIN (*tchoicedlg.init*)
   PlayOne := PlyF;
   INHERITED Init(Parent,Owner,hMod,idDlg,pCreateParams);
  END; (*tchoicedlg.init*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.CMBut1(VAR Msg : TMESSAGE);
     (* procedure to handle the button 1 press *)

  BEGIN (*tchoicedlg.cmbut1*)
   Msg.Result := cm_But1;
  END; (*tchoicedlg.cmbut1*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.CMBut2(VAR Msg : TMESSAGE);
     (* procedure to handle the button 2 press *)

  BEGIN (*tchoicedlg.cmbut2*)
   Msg.Result := cm_But2;
  END; (*tchoicedlg.cmbut2*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.CMBut3(VAR Msg : TMESSAGE);
     (* procedure to handle the button 3 press *)

  BEGIN (*tchoicedlg.cmbut3*)
   Msg.Result := cm_But3;
  END; (*tchoicedlg.cmbut3*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.CMBut4(VAR Msg : TMESSAGE);
     (* procedure to handle the button 4 press *)

  BEGIN (*tchoicedlg.cmbut4*)
   Msg.Result := cm_But4;
  END; (*tchoicedlg.cmbut4*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.CMBut5(VAR Msg : TMESSAGE);
     (* procedure to handle the button 5 press *)

  BEGIN (*tchoicedlg.cmbut5*)
   Msg.Result := cm_But5;
  END; (*tchoicedlg.cmbut5*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.CMBut6(VAR Msg : TMESSAGE);
     (* procedure to handle the button 6 press *)

  BEGIN (*tchoicedlg.cmbut6*)
   Msg.Result := cm_But6;
  END; (*tchoicedlg.cmbut6*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.CMBut7(VAR Msg : TMESSAGE);
     (* procedure to handle the button 7 press *)

  BEGIN (*tchoicedlg.cmbut7*)
   Msg.Result := cm_But7;
  END; (*tchoicedlg.cmbut7*)

(************************************************************************)

 PROCEDURE TCHOICEDLG.WMInitDlg(VAR Msg : TMESSAGE);
     (* procedure to set up choice dialog *)

    VAR H : HWND;
        T : CSTRING[40];

  BEGIN (*tchoicedlg.wminitdlg*)
   INHERITED WMInitDlg(Msg);
   H := Msg.Receiver;
   IF PlayOne
    THEN WinLoadString(AppHandle,NullHandle,ids_PlayTitle,SizeOf(T),T)
   ELSE WinLoadString(AppHandle,NullHandle,ids_DiscardTit,SizeOf(T),T);
   WinSetWindowText(H,T);
  END; (*tchoicedlg.wminitdlg*)

(************************************************************************)
(** Main window object (TDIALOG)                                       **)
(************************************************************************)

 CONSTRUCTOR TMS_WIN.Init(Parent, Owner : HWND; hMod : HMODULE; idDlg : LONGWORD;
                          pCreateParams : POINTER);
     (* constructor to create main dialog window of milestone *)

  BEGIN (*tms_win.init*)
   INHERITED Init(Parent,Owner,hMod,idDlg,pCreateParams);
   Randomize;
   FirstGame := TRUE;
  END; (*tms_win.init*)

(************************************************************************)

 DESTRUCTOR TMS_WIN.Done;
     (* destructor to destroy the milestone main window *)

    VAR I : INTEGER;

  BEGIN (*tms_win.done*)
   FOR I := 1 TO 22 DO
    IF ConTTSt[I].Pic <> 0 THEN GpiDeleteBitmap(ConTTSt[I].Pic);
   IF HelpWnd <> NullHandle
    THEN BEGIN {get rid of help system instance}
          WinDestroyHelpInstance(HelpWnd); HelpWnd := 0;
         END; {then}
   INHERITED Done;
  END; (*tms_win.done*)

(************************************************************************)

 PROCEDURE TMS_WIN.ShuffleCards;
     (* procedure used to shuffle the card deck *)

    VAR I, R, T : INTEGER;
        TStr    : STRING[60];
        TT      : CSTRING[60];

  BEGIN (*tms_win.shufflecards*)
   WinLoadString(AppHandle,NullHandle,ids_ShuffleMsg,SizeOf(TT),TT);
   TStr := StrPas(@TT);
   ShowMsg(TStr);
   Cntt := 0; SSS := 0; Top := 0;
   FOR I := 1 TO MaxCards DO
    BEGIN {shuffle up the deck}
     R := Random(MaxCards) + 1;
     T := CCC[I]; CCC[I] := CCC[R]; CCC[R] := T;
    END; {for loop}
   TStr := '';
   ShowMsg(TStr);
  END; (*tms_win.shufflecards*)

(************************************************************************)

 PROCEDURE TMS_WIN.ResetGameBoard;
     (* procedure to reset the board back to the default *)

    VAR K : LONGWORD;
        T : STRING;

  BEGIN (*tms_win.resetgameboard*)
   FOR K := id_UserC1 TO id_UserC7 DO
    DisplayCard(21,K);
   FOR K := id_YSpeed TO id_YSafe4 DO
    DisplayCard(22,K);
   FOR K := id_MSpeed TO id_MSafe4 DO
    DisplayCard(22,K);
   DisplayCard(22,id_Discard);
   U_Hand^.WriteDistance(id_YDistance,0);
   C_Hand^.WriteDistance(id_MDistance,0);
   WinSetDlgItemText(HwndDlg,id_CardsLeft,'0');
   T := '';
   ShowMsg(T);
   WinUpdateWindow(HwndDlg);
  END; (*tms_win.resetgameboard*)

(************************************************************************)

 PROCEDURE TMS_WIN.Init_GameVars(Start : BOOLEAN);
     (* procedure to initialize all global game variables *)

    VAR I, J : INTEGER;

  BEGIN (*tms_win.init_gamevars*)
   IF Start
    THEN BEGIN {start of game inits}
          SSA[0] := 0; SSA[1] := 0; RndCt := 0;
         END; {then}
   P_Play := TRUE;
   FOR I := 1 TO MaxCards DO
    CCC[I] := I;
   ShuffleCards;
   FillChar(PPL,SizeOf(PPL),0);
   FillChar(Safety,SizeOf(Safety),0);
   FOR I := 0 TO 6 DO
    FOR J := 0 TO 1 DO
     BEGIN {initial deal of cards}
      Inc(Cntt);
      CASE J OF
       0 : C_Hand^.HHH[I] := CCC[Cntt];
       1 : U_Hand^.HHH[I] := CCC[Cntt];
      END; {case}
     END; {for loops}
   FOR I := 2 TO 7 DO
    SSA[I] := 0;
   DisplayCardsLeft;
  END; (*tms_win.init_gamevars*)

(************************************************************************)

 PROCEDURE TMS_WIN.DisplayCard(Card : INTEGER; id_C : LONG);
     (* procedure used to display a card at a specific id spot *)

    VAR B_Dlg : HWND;
        Ahps  : HPS;
        S     : SWP;
        T     : POINTL;

  BEGIN (*tms_win.displaycard*)
   B_Dlg := WinWindowFromID(HwndDlg,id_C);
   WinQueryWindowPos(B_Dlg,S);
   T.X := S.X; T.Y := S.Y;
   Ahps := WinGetPS(HwndDlg);
   WinDrawBitmap(Ahps,ConTTSt[Card].Pic,NIL,T,0,0,dbm_Normal);
   WinReleasePS(Ahps);
   CASE id_C OF  {set up for paint}
    120..126 : ShowYC[id_C] := Card;
    130..135 : ShwYPile[id_C] := Card;
    140..145 : ShwMPile[id_C] := Card;
    ELSE ShwDisc := Card;
   END; {case}
  END; (*tms_win.displaycard*)

(************************************************************************)

 PROCEDURE TMS_WIN.DisplayCardsLeft;
     (* procedure to display the number of cards left in the deck *)

    VAR S : STRING[10];
        I : INTEGER;

  BEGIN (*tms_win.displaycardsleft*)
   I := MaxCards - Cntt; IF I < 0 THEN I := 0;
   Str(I,S);
   WinSetDlgItemText(HwndDlg,id_CardsLeft,S);
  END; (*tms_win.displaycardsleft*)

(************************************************************************)

 PROCEDURE TMS_WIN.ShowMsg(VAR Msg : STRING);
     (* procedure to display message in the message window *)

  BEGIN (*tms_win.showmsg*)
   WinSetDlgItemText(HwndDlg,id_Message,Msg);
  END; (*tms_win.showmsg*)

(************************************************************************)

 PROCEDURE TMS_WIN.DoEnd;
     (* procedure to run end of game stuff *)

    VAR E_Dlg : PENDDLG;
        E_Flg : BOOLEAN;
        Ret   : LONGWORD;
        TT    : CSTRING[40];

  BEGIN (*tms_win.doend*)
   EnabControls(FALSE,TRUE);
   E_Flg := FALSE; MCT := FALSE; YCT := FALSE;
   SSA[6] := PPL[G_Computer,0]; SSA[7] := PPL[G_Player,0]; {start with mileage totals}
   {add bonus for 1000 miles}
   IF SSA[6] = 1000
    THEN BEGIN {computer bonus - complete trip}
          SSA[6] := SSA[6] + 400; MCT := TRUE;
         END; {then}
   IF SSA[7] = 1000
    THEN BEGIN {players bonus - complete trip}
          SSA[7] := SSA[7] + 400; YCT := TRUE;
         END; {then}
   {add coup foures totals (comp/player)}
   SSA[6] := SSA[6] + SSA[2]; SSA[7] := SSA[7] + SSA[3];
   {add safety totals (comp/player)}
   SSA[6] := SSA[6] + SSA[4]; SSA[7] := SSA[7] + SSA[5];
   {add in shut out bonus, if any}
   IF PPL[G_Player,0] = 0 THEN SSA[6] := SSA[6] + 500; {player shut out}
   IF PPL[G_Computer,0] = 0 THEN SSA[7] := SSA[7] + 500; {comp shut out}
   {add to round totals to grand totals}
   SSA[0] := SSA[0] + SSA[6]; SSA[1] := SSA[1] + SSA[7];
   IF (SSA[0] >= 5000) OR (SSA[1] >= 5000) THEN E_Flg := TRUE; {game over}
   E_Dlg := New(PENDDLG,Init(1,HwndDlg,0,id_EndDlg,NIL,E_Flg));
   Ret := E_Dlg^.ExecDialog;
   Dispose(E_Dlg,Done);
   Ret := Ret - cm_First;
   IF E_Flg
    THEN BEGIN {reset game}
          FirstGame := TRUE;
          WinLoadString(AppHandle,NullHandle,ids_StartBtn,SizeOf(TT),TT);
          WinSetDlgItemText(HwndDlg,cm_First+cm_StartNew,TT); {set btn text}
         END; {then}
   IF Ret = cm_No
    THEN BEGIN {quit program then}
          WinPostMsg(HwndDlg,wm_Quit,0,0); Exit;
         END; {then}
   ResetGameBoard;
   IF NOT(E_Flg)
    THEN BEGIN {shuffle and deal new hand}
          Init_GameVars(FALSE);
          U_Hand^.DisplayHand;
          EnabControls(TRUE,TRUE);
         END {then}
   ELSE EnabControls(TRUE,FALSE);
  END; (*tms_win.doend*)

(************************************************************************)

 PROCEDURE TMS_WIN.EnabControls(Enab, AllB : BOOL);
     (* procedure enable or disable controls/buttons *)

  BEGIN (*tms_win.enabcontrols*)
   IF AllB
    THEN BEGIN {enable/disable all buttons}
          WinEnableControl(HwndDlg,cm_First+cm_Play,Enab);
          WinEnableControl(HwndDlg,cm_First+cm_Discard,Enab);
         END; {then}
   WinEnableControl(HwndDlg,cm_First+cm_Help,Enab);
   WinEnableControl(HwndDlg,cm_First+cm_StartNew,Enab);
  END; (*tms_win.enabcontrols*)

(************************************************************************)

 PROCEDURE TMS_WIN.GetNewCard;
     (* procedure to get and display a new card for the player *)

    VAR I, J : INTEGER;
        P    : HBITMAP;
        C    : LONGWORD;

  BEGIN (*tms_win.getnewcard*)
   J := CCC[Cntt]; I := U_Hand^.PlayedCard - 1; C := id_UserC1 + I;
   U_Hand^.HHH[I] := J;
   I := U_Hand^.GetTheIndex(J);
   IF I <> -1
    THEN P := ConTTSt[I].Pic  {card picture}
   ELSE P := ConTTSt[21].Pic; {back picture}
   IF I = -1 THEN I := 21;
   U_Hand^.Show_Card(C,P,I);
   DisplayCardsLeft;
  END; (*tms_win.getnewcard*)

(************************************************************************)

 PROCEDURE TMS_WIN.CMCompPlay(VAR Msg : TMESSAGE);
     (* procedure to handle the computers play command message *)

    VAR TT, T2 : STRING[80];
        T1     : CSTRING[80];

  BEGIN (*tms_win.cmcompplay*)
   Msg.Handled := TRUE;
   WinLoadString(AppHandle,NullHandle,ids_CompPlay,SizeOf(T1),T1);
   TT := StrPas(@T1);
   ShowMsg(TT);
   C_Hand^.SetRoll(G_Player);
   Inc(Cntt);
   IF Cntt > MaxCards
    THEN BEGIN {no more cards left}
          Dec(Cntt); Inc(SSS); Inc(Top);
          IF SSS > 6
           THEN BEGIN {no one wins round}
                 DoEnd; Exit;
                END; {then}
         END {then}
   ELSE GetNewCard;
   Inc(Cntt);
   TT := 'PLAY';
   C_Hand^.PlayComsHand(TT); T2 := '';
   ShowMsg(T2);
   U_Hand^.SetRoll(G_Computer);
   IF PPL[G_Computer,0] = 1000
    THEN BEGIN {computer wins}
          DoEnd; Exit;
         END; {then}
   {get card for computer}
   IF SSS = 0 THEN C_Hand^.HHH[0] := CCC[Cntt];
   DisplayCardsLeft;
   WinLoadString(AppHandle,NullHandle,ids_UserPlay,SizeOf(T1),T1);
   TT := StrPas(@T1);
   ShowMsg(TT);
   EnabControls(TRUE,TRUE); P_Play := TRUE;
  END; (*tms_win.cmcompplay*)

(************************************************************************)

 PROCEDURE TMS_WIN.CMPlay(VAR Msg : TMESSAGE);
     (* procedure to run the play button press for the user *)

    VAR Dlg : PCHOICEDLG;
        Ret : LONGWORD;
        C   : INTEGER;

  BEGIN (*tms_win.cmplay*)
   Msg.Handled := TRUE;
   IF NOT P_Play THEN Exit;
   Dlg := New(PCHOICEDLG,Init(1,HwndDlg,0,id_Choice,TRUE,NIL));
   Ret := Dlg^.ExecDialog;
   Dispose(Dlg,Done);
   C := -1; Ret := Ret - cm_First;
   CASE Ret OF
    cm_But1 : C := 1;
    cm_But2 : C := 2;
    cm_But3 : C := 3;
    cm_But4 : C := 4;
    cm_But5 : C := 5;
    cm_But6 : C := 6;
    cm_But7 : C := 7;
   END; {case}
   IF C = -1 THEN Exit;
   P_Play := FALSE; EnabControls(FALSE,TRUE);
   U_Hand^.PlayerPlayCard(C);
   IF C = -1
    THEN BEGIN {couldn't play card exit}
          EnabControls(TRUE,TRUE); P_Play := TRUE; Exit;
         END; {then}
   U_Hand^.PlayedCard := C;
   IF PPL[G_Player,0] = 1000
    THEN BEGIN {player won round}
          DoEnd; Exit;
         END; {then}
   WinPostMsg(HwndDlg,wm_Command,cm_First+cm_CompPlay,0);
  END; (*tms_win.cmplay*)

(************************************************************************)

 PROCEDURE TMS_WIN.CMDiscard(VAR Msg : TMESSAGE);
     (* procedure to handle the discard button pressed by user *)

    VAR Dlg : PCHOICEDLG;
        Ret : LONGWORD;
        C   : INTEGER;

  BEGIN (*tms_win.cmdiscard*)
   Msg.Handled := TRUE;
   IF NOT P_Play THEN Exit;
   Dlg := New(PCHOICEDLG,Init(1,HwndDlg,0,id_Choice,FALSE,NIL));
   Ret := Dlg^.ExecDialog;
   Dispose(Dlg,Done);
   C := -1; Ret := Ret - cm_First;
   CASE Ret OF
    cm_But1 : C := 1;
    cm_But2 : C := 2;
    cm_But3 : C := 3;
    cm_But4 : C := 4;
    cm_But5 : C := 5;
    cm_But6 : C := 6;
    cm_But7 : C := 7;
   END; {case}
   IF C = -1 THEN Exit;
   P_Play := FALSE; EnabControls(FALSE,TRUE);
   U_Hand^.PlayerDiscardCard(C);
   IF C = -1
    THEN BEGIN {couldn't discard card exit}
          EnabControls(TRUE,TRUE); P_Play := TRUE; Exit;
         END; {then}
   U_Hand^.PlayedCard := C;
   WinPostMsg(HwndDlg,wm_Command,cm_First+cm_CompPlay,0);
  END; (*tms_win.cmdiscard*)

(************************************************************************)

 PROCEDURE TMS_WIN.CMStartNew(VAR Msg : TMESSAGE);
     (* procedure to run the start/new button press *)

    VAR TStr : STRING[40];
        TT   : CSTRING[40];

  BEGIN (*tms_win.cmstartnew*)
   ResetGameBoard;
   IF FirstGame
    THEN BEGIN {set up for new instead of start}
          FirstGame := FALSE;
          WinLoadString(AppHandle,NullHandle,ids_NewBtn,SizeOf(TT),TT);
          WinSetDlgItemText(HwndDlg,cm_First+cm_StartNew,TT); {set button text}
         END; {then}
   Init_GameVars(TRUE);
   U_Hand^.DisplayHand;
   WinLoadString(AppHandle,NullHandle,ids_UserPlay,SizeOf(TT),TT);
   TStr := StrPas(@TT);
   ShowMsg(TStr);
   EnabControls(TRUE,TRUE);
   Msg.Handled := TRUE;
  END; (*tms_win.cmstartnew*)

(************************************************************************)

 PROCEDURE TMS_WIN.CMHelp(VAR Msg : TMESSAGE);
     (* procedure to handle the help button press *)

  BEGIN (*tms_win.cmhelp*)
   Msg.Handled := TRUE;
   IF HelpWnd <> NullHandle THEN WinSendMsg(HelpWnd,hm_Help_Contents,0,0);
  END; (*tms_win.cmhelp*)

(************************************************************************)

 PROCEDURE TMS_WIN.CMInitDraw(VAR Msg : TMESSAGE);
     (* procedure used to initially draw dialog after it shows *)

  BEGIN (*tms_win.cminitdraw*)
   Msg.Handled := TRUE;
   ResetGameBoard;
  END; (*tms_win.cminitdraw*)

(************************************************************************)

 PROCEDURE TMS_WIN.WMInitDlg(VAR Msg : TMESSAGE);
     (* procedure used to set up the dialog *)

    VAR I          : INTEGER;
        SysW, H    : HWND;
        A          : HPS;
        P          : HPOINTER;
        S          : SWP;
        T          : STRING[40];
        TmpM, SysM : PMENUITEM;
        AStr       : PCHAR;

  BEGIN (*tms_win.wminitdlg*)
   INHERITED WMInitDlg(Msg);
   H := Msg.Receiver;
   {set up icon}
   P := WinLoadPointer(hwnd_Desktop,0,id_Main);
   WinSendMsg(H,wm_SetIcon,P,0);
   {delete system menu items}
   GetMem(SysM,SizeOf(MENUITEM));
   SysW := WinWindowFromID(H,fid_SysMenu);
   WinSendMsg(SysW,mm_QueryItem,MPFrom2Short(sc_SysMenu,0),MPARAM(SysM));
   WinSendMsg(SysM^.hwndSubMenu,mm_DeleteItem,MPFrom2Short(sc_Size,1),0);
   WinSendMsg(SysM^.hwndSubMenu,mm_DeleteItem,MPFrom2Short(sc_Maximize,1),0);
   I := WinSendMsg(SysM^.hwndSubMenu,mm_DeleteItem,MPFrom2Short(sc_Hide,1),0);
   GetMem(TmpM,SizeOf(MENUITEM));
   FillChar(TmpM^,SizeOf(MENUITEM),0);
   TmpM^.iPosition := I;
   TmpM^.afStyle := mis_Separator;
   WinSendMsg(SysM^.hwndSubMenu,mm_InsertItem,MPFromP(TmpM),0);
   Inc(TmpM^.iPosition); T := '~About'; T[7] := #0; AStr := @T[1];
   TmpM^.afStyle := mis_Text OR mis_SysCommand;
   TmpM^.id := sc_About;
   WinSendMsg(SysM^.hwndSubMenu,mm_InsertItem,MPFromP(TmpM),MPFromP(AStr));
   FreeMem(TmpM,SizeOf(MENUITEM));
   FreeMem(SysM,SizeOf(MENUITEM));
   {set up help system}
   HelpTitle := 'OS/2 Milestone Help';
   HelpLib   := 'milestne.hlp';
   FillChar(HelpI,SizeOf(HELPINIT),0);
   WITH HelpI DO
    BEGIN {initialize help structure}
     cb                 := SizeOf(HELPINIT);
     phtHelpTable       := PHELPTABLE(MAKEULONG(help_Client,$FFFF));
     pszHelpWindowTitle := @HelpTitle;
     fShowPanelID       := cmic_Hide_Panel_Id;
     pszHelpLibraryName := @HelpLib;
    END; {with}
   HelpWnd := WinCreateHelpInstance(AppHandle,HelpI);
   IF (HelpWnd <> NullHandle) AND (HelpI.ulReturnCode <> 0)
    THEN BEGIN {not a good help instance}
          WinDestroyHelpInstance(HelpWnd);
          HelpWnd := NullHandle;
         END; {then}
   IF HelpWnd <> NullHandle
    THEN WinAssociateHelpInstance(HelpWnd,H);
   {load bitmaps}
   A := WinGetPS(H);
   FOR I := 1 TO 22 DO
    ConTTSt[I].Pic := GpiLoadBitmap(A,0,ConTTSt[I].id_N,0,0);
   WinReleasePS(A);
   {move windows around - hide stub window}
   WinQueryWindowPos(H,S);
   WinSetWindowPos(Application^.MainWindow^.HWindowFrame,0,S.x,S.y,S.cx,S.cy,
                   swp_Size OR swp_Move OR swp_Hide);
   WinSetWindowPos(H,0,S.x-2,S.y,0,0,swp_Move);
   {create players}
   C_Hand := New(PMY_HAND,Init(H));
   U_Hand := New(PYOUR_HAND,Init(H));
   PaintNow := TRUE;
   WinPostMsg(H,wm_Command,cm_First+cm_InitDraw,0);
  END; (*tms_win.wminitdlg*)

(************************************************************************)

 PROCEDURE TMS_WIN.WMPaint(VAR Msg : TMESSAGE);
     (* procedure used to handle paint messages *)

    VAR B    : HWND;
        Ahps : HPS;
        I    : LONGWORD;
        S    : SWP;
        T    : POINTL;
        J    : INTEGER;

  BEGIN (*tms_win.wmpaint*)
   DefDlgProc(Msg);
   IF NOT PaintNow THEN Exit;
   Ahps := WinGetPS(HwndDlg);
   FOR I := id_UserC1 TO id_UserC7 DO
    BEGIN
     B := WinWindowFromID(HwndDlg,I);
     WinQueryWindowPos(B,S);
     T.X := S.X; T.Y := S.Y; J := ShowYC[I];
     WinDrawBitmap(Ahps,ConTTSt[J].Pic,NIL,T,0,0,dbm_Normal);
    END;
   FOR I := id_YSpeed TO id_YSafe4 DO
    BEGIN
     B := WinWindowFromID(HwndDlg,I);
     WinQueryWindowPos(B,S);
     T.X := S.X; T.Y := S.Y; J := ShwYPile[I];
     WinDrawBitmap(Ahps,ConTTSt[J].Pic,NIL,T,0,0,dbm_Normal);
    END;
   FOR I := id_MSpeed TO id_MSafe4 DO
    BEGIN
     B := WinWindowFromID(HwndDlg,I);
     WinQueryWindowPos(B,S);
     T.X := S.X; T.Y := S.Y; J := ShwMPile[I];
     WinDrawBitmap(Ahps,ConTTSt[J].Pic,NIL,T,0,0,dbm_Normal);
    END;
   B := WinWindowFromID(HwndDlg,id_Discard);
   WinQueryWindowPos(B,S);
   T.X := S.X; T.Y := S.Y; J := ShwDisc;
   WinDrawBitmap(Ahps,ConTTSt[J].Pic,NIL,T,0,0,dbm_Normal);
   WinReleasePS(Ahps);
  END; (*tms_win.wmpaint*)

(************************************************************************)

 PROCEDURE TMS_WIN.WMSysCommand(VAR Msg : TMESSAGE);
     (* procedure to handle some system commands *)

    VAR Dlg : PDIALOG;

  BEGIN (*tms_win.wmsyscommand*)
   IF Msg.Param1 = sc_About
    THEN BEGIN {display about box}
          Dlg := New(PDIALOG,Init(1,HwndDlg,0,id_About,NIL));
          Dlg^.ExecDialog;
          Dispose(Dlg,Done);
         END; {then}
   DefDlgProc(Msg);
  END; (*tms_win.wmsyscommand*)

(************************************************************************)
(** Program stub window object (TWINDOW)                               **)
(************************************************************************)

 PROCEDURE TSTUBWIN.SetupWindow;
     (* procedure used to set up and execute the dialog main window *)

  BEGIN (*tstubwin.setupwindow*)
   INHERITED SetupWindow;
   MainDlg := New(PMS_WIN,Init(1,HWindowFrame,0,id_Main,NIL));
   MainDlg^.ExecDialog;
   Dispose(MainDlg,Done);
   WinPostMsg(HWindow,wm_Quit,0,0);
  END; (*tstubwin.setupwindow*)

(************************************************************************)
(** Application object (TAPPLICATION)                                  **)
(************************************************************************)

 PROCEDURE TMS_APP.InitMainWindow;
     (* procedure used by the application to setup main window *)

  BEGIN (*tms_app.initmainwindow*)
   MainWindow := New(PSTUBWIN,Init(NIL,ApplicationName+' - Fake Window'));
   MainWindow^.Attr.HasIcon := TRUE;
   MainWindow^.Attr.ResourceID := id_Main;
   MainWindow^.Attr.WindowID := id_Main;
  END; (*tms_app.initmainwindow*)

(************************************************************************)
(*** Main program                                                     ***)
(************************************************************************)

 VAR App : TMS_APP;

BEGIN (*MAIN*)
 App.Init('OS/2 Milestone');
 App.Run;
 App.Done;
END. (*MAIN*)

