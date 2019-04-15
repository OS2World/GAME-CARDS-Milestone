/* Speed Constants file */
UNIT MS_RC;

INTERFACE

 USES ObjectPM; {uses for cm_first constant}

 CONST cm_Play      = 152; {main window buttons}
       cm_Discard   = 153;
       cm_StartNew  = 154;
       cm_But1      = 102; {choice buttons}
       cm_But2      = 103;
       cm_But3      = 104;
       cm_But4      = 105;
       cm_But5      = 106;
       cm_But6      = 107;
       cm_But7      = 108;
       cm_Yes       = 180; {end dialog buttons}
       cm_No        = 181;
       cm_CompPlay  = cm_First + 200; {automatic messages}
       cm_InitDraw  = cm_First + 201;
       id_Main      = 1;   {main window}
       id_Choice    = 2;   {choice dialog}
       id_EndDlg    = 3;   {end round/game dialog}
       id_About     = 4;   {about dialog}
       id_Mess      = 5;
       id_YDistance = 103; {main window ids}
       id_MDistance = 105;
       id_CardsLeft = 107;
       id_Discard   = 110;
       id_Message   = 112;
       id_UserC1    = 120;
       id_UserC2    = 121;
       id_UserC3    = 122;
       id_UserC4    = 123;
       id_UserC5    = 124;
       id_UserC6    = 125;
       id_UserC7    = 126;
       id_YSpeed    = 130;
       id_YBattle   = 131;
       id_YSafe1    = 132;
       id_YSafe2    = 133;
       id_YSafe3    = 134;
       id_YSafe4    = 135;
       id_MSpeed    = 140;
       id_MBattle   = 141;
       id_MSafe1    = 142;
       id_MSafe2    = 143;
       id_MSafe3    = 144;
       id_MSafe4    = 145;
       id_MessLine  = 190;
       id_EndPrompt = 101; {end dialog ids}
       id_RoundTxt  = 125;
       id_M_Dist    = 127;
       id_Y_Dist    = 128;
       id_M_CompTrp = 129;
       id_Y_CompTrp = 130;
       id_M_CoupF   = 131;
       id_Y_CoupF   = 132;
       id_M_Safe    = 133;
       id_Y_Safe    = 134;
       id_M_ShutOut = 135;
       id_Y_ShutOut = 136;
       id_M_RoundT  = 137;
       id_Y_RoundT  = 138;
       id_M_GrandT  = 139;
       id_Y_GrandT  = 140;
       {string constants}
       ids_ShuffleMsg = 32;
       ids_NewBtn     = 33;
       ids_StartBtn   = 34;
       ids_PlayTitle  = 35;
       ids_DiscardTit = 36;
       ids_EndGameTit = 37;
       ids_EndGamPrmt = 38;
       ids_CompPlay   = 39;
       ids_UserPlay   = 40;
       sc_About       = 100;
       help_Client    = 499;

(************************************************************************)

IMPLEMENTATION

(************************************************************************)

END. (*of unit*)

