**free

// Read RSYNC00F and check CCSID on local server, and set it to remote IBM I

// Prerequisite:
// 5733-SC1 
// SSH server running on remote server
// Open source tecnologies Installed
// RSync installed: yum install rsync
// for more information about prerequisite consult:
// https://bitbucket.org/ibmi/opensource/src/master/

// Read README before run program.
// ________________________________________________________

Ctl-Opt 
  DftActGrp(*No)
  ActGrp(*StgMdl)
  StgMdl(*SngLvl)
  DftName(RSYNC03R)
  DatFmt(*Iso) TimFmt(*Iso)
  Alwnull(*UsrCtl)
  Option(*SrcStmt:*NoDebugIo :*NoUnRef)
  Text('Rsync Check CCSID on Local and set to remote.')
  Debug;

// Protootype definitions
Dcl-Pr RSync03r ExtPgm('RSYNC03R');
  ParmId          Char(20) const;
End-Pr RSync03r;

Dcl-Pi RSync03r;
  ParmId          Char(20) const;
End-Pi RSync03r;

Dcl-pr usleep uns(10) extproc('usleep');
  *n uns(10) value; // millisecs
end-pr;

// Call Pase                              
Dcl-Pr Qp2Shell ExtPgm('QP2SHELL2');
  Parm1 Char(1000) Const Options(*VarSize :*trim);
  Parm2 Char(1000) Const Options(*VarSize :*trim);
  Parm3 Char(1000) Const Options(*VarSize :*trim);
End-Pr Qp2Shell;

// Parameter Initializations
Dcl-S Parm1 VarChar(1000);
Dcl-S Parm2 VarChar(1000);
Dcl-S Parm3 VarChar(1000);

// Change Directory
Dcl-Pr ChDir int(10) ExtProc('chdir');
  *n  Pointer Value Options(*string);
End-Pr ChDir;

Dcl-Pr SndDtaQ ExtPgm('QSNDDTAQ');                  
  DataQueue Char(10) Const;                         
  DataQueueLib Char(10) Const;                      
  DataLen Packed(5 :0) Const;                       
  Data Char(32767) Const Options(*Varsize);         
End-Pr SndDtaQ;                                     

Dcl-Pr Sys_Errno Pointer ExtProc('__errno') End-Pr;
Dcl-S Errno Int(10) based(p_errno);

Dcl-Pr StrError Pointer ExtProc('strerror');
  errnum  Int(10) value;
End-Pr StrError;

// Command Exec                              
Dcl-Pr Cmd Int(10) ExtProc('system');
  *n  Pointer value Options(*String);
End-Pr Cmd;

Dcl-S ErrMsgId    Char(7) Import('_EXCP_MSGID');  
Dcl-S Command     VarChar(1000);

// RSync setup value
Dcl-S  ConfigurationId  VarChar(20);
Dcl-S  SubTree          VarChar(3);
Dcl-S  RemoteServer     VarChar(80);
Dcl-S  RemotePort       Zoned(5);
Dcl-S  RemoteRoot       VarChar(640);
Dcl-S  RootInd          Ind Inz(*On);
Dcl-S  ToSite           VarChar(100);
Dcl-S  FromSite         VarChar(100);
Dcl-S  Directory        VarChar(50);
Dcl-S  Root             Varchar(640);
Dcl-S  CertificatePath  VarChar(300);
Dcl-S  Certificate      VarChar(100);
Dcl-S  UserKnownHosts   VarChar(100);
Dcl-S  GlobalKnownHosts VarChar(100);
Dcl-S  DtaqName         VarChar(100);
Dcl-S  DtaqLib          VarChar(100);
Dcl-S  Exclusion           VarChar(100);

Dcl-S PaseRSync           Char(32767) inz;
Dcl-S RSyncDirectory      VarChar(640);
Dcl-S Rc                  Int(10);
Dcl-S SqlString           VarChar(1000);
Dcl-S Cr                  Char(1) Inz(X'0D');
Dcl-S LogFile             VarChar(100);
Dcl-S setccsidscript      VarChar(100);
Dcl-S LogMsg              VarChar(1000);
Dcl-S RetCode             Int(10);
Dcl-S NumberOfSubDir      Int(10);
Dcl-S WorkStmf            VarChar(640);
Dcl-S WorkCcsid           VarChar(5);
Dcl-S RSyncFlag           Char(1);
Dcl-S DeleteRootFile      Char(1);
Dcl-S NoSubDirectory      VarChar(50);
Dcl-S DeleteOptions       VarChar(15);
Dcl-S RSyncUser           VarChar(20);

Dcl-Ds DsAttr     Qualified;
  Stmf                    VarChar(640);
  Ccsid                   Char(5);
End-Ds DsAttr;

Dcl-C EXCLUSIONFILE       '/RsyncExclusionList.txt';

Dcl-C A                   '''';
// Explaination of RSyncFlag
Dcl-C UNKNOWN             '?';
Dcl-C RECURSIVE           'R';
Dcl-C FIRSTLEVEL          'F';
Dcl-C NOTSYNCRONIZE       'N';

Dcl-C SYNCROOT            'R';
Dcl-C SUBDIRECTORY        'S';
Dcl-C NO                  'N';
Dcl-C ERROR               'E';
Dcl-C INFO                'I';
// ___________________________________________________________________________________________                                     

Exec Sql Set Option DatFmt = *Iso, TimFmt = *Iso, CloSqlCsr = *EndActgrp, Commit = *none;

*InLr = *On;

// Load Configuration from RSyncSt00f 
If RSyncSetup() < 0;
  Return;
EndIf;

// Log Begin RSync Process
RSyncLog(INFO: 'Check CCSID Process.');

Exec Sql
  Declare CheckCcsIdCursor cursor for
    Select RSyncElement, RSyncFlag
      from RSync00f
      where ConfigurationId = :ConfigurationId
        and RSyncFlag in (:FIRSTLEVEL, :RECURSIVE);

Exec Sql Open CheckCcsIdCursor;
If SqlState <> '00000';
  Exec Sql Close CheckCcsIdCursor;
  Return;
EndIf;

Dow SqlState <> '02000' or %Shtdn();

  If RootInd;
    RSyncDirectory = Root;
    RSyncFlag      = FIRSTLEVEL;
    RootInd        = *Off;
  Else;
    Exec Sql
      Fetch next from CheckCcsIdCursor into :RSyncDirectory, :RSyncFlag;
    If SqlState = '02000';
      Leave;
    EndIf;
  EndIf;
  
  // Write Record to better read RSync Log
  RSyncLog(INFO :'Check CCSID for: ' + RSyncDirectory + '.');

  If RSyncFlag = RECURSIVE;
    SubTree = 'YES';
  Else;
    SubTree = 'NO';
  EndIf;

  If CheckDirectory() < 0;
    Iter;
  EndIf;

EndDo;

Exec Sql Close CheckCcsIdCursor;

// Write Record to better read RSync Log
RSyncLog(INFO :'RSync End setting CCSID.');

Return;

// ____________________________________________________________
Dcl-Proc CheckDirectory;
  Dcl-Pi CheckDirectory Int(10);
  End-Pi CheckDirectory;
  // ____________________________________________________________

  Exec Sql
    Declare Directorytocheck cursor for 
      Select Trim(Path_Name), Trim(Char(Ccsid))
        From Table (
          Qsys2.Ifs_Object_Statistics(Start_Path_Name => :RSyncDirectory, 
                                      Subtree_Directories => :SubTree,
                                      Object_Type_list => '*ALLSTMF'))
          Where Ccsid <> 819
    ;
  Exec Sql 
    Open Directorytocheck;
  If SqlState <> '00000';
    RSyncLog(INFO :'Error open Cursor for Ifs_Object_statistics: ' + SqlState + '.');
    Exec Sql Close Directorytocheck;
    Return -1;
  EndIf;

  Dow SqlState <> '02000' and not %Shtdn();

    DsAttr = '';

    Exec Sql
      Fetch next from Directorytocheck into :DsAttr.Stmf, :DsAttr.Ccsid;
    If SqlState = '02000';
      Leave;
    EndIf;

    If SqlState <> '00000' and SqlState <> '01004';
      RSyncLog(INFO :'Error in fetch Ifs_Object_statistics: ' + SqlState + ', ' + WorkStmf);
      Iter;
    EndIf;

    If WorkStmf = '/QSYS.LIB';
      Iter;
    EndIf;
    
    SndDtaq(DtaqName :DtaqLib :%Len(DsAttr) :DsAttr);

    USleep(30000);

    RSyncLog(INFO :'Setccsid: for ' + DsAttr.Stmf + ' to: ' + DsAttr.Ccsid + '.');

  EndDo;

  Exec Sql Close Directorytocheck;

  Return 0;

End-Proc CheckDirectory;
// ____________________________________________________________                                                  
Dcl-Proc RSyncSetup;
  Dcl-Pi RSyncSetup Int(10);
  End-Pi RSyncSetup;
  // ____________________________________________________________                                                  

  
  Parm1 = Parm1 + X'00';
  Parm2 = Parm2 + X'00';

  ConfigurationId = %Trim(ParmId);

  // Load the setup value per RSync
  Exec Sql 
    Select RValue into :Directory
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'DIRECTORY';
  If SqlState <> '00000' or Directory = '';
    Dsply ('Missing DIRECTORY value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;

  Command = 'MkDir Dir(' +A+ %Subst(Directory :1 :%Scan('/' :Directory :2) -1) +A+ ')';
  Rc = Cmd(Command); 

  Command = 'MkDir Dir(' +A+ Directory +A+ ')';
  If Cmd(Command) < 0;
    RSyncLog(ERROR :'Error: Make Directory failed: '+ Directory + '. Error Code: ' + ErrMsgId); 
  EndIf;  

  LogFile   = Directory + '/' + %Char(%Date(): *Iso0) + '-RSync.log';
  Exclusion = Directory + EXCLUSIONFILE;

  Exec Sql 
    Select RValue into :RemoteServer
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'REMOTESERVER';
  If SqlState <> '00000' or RemoteServer = '';
    RSyncLog(ERROR :'Error: Missing REMOTESERVER value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;

  // RemotePort is the tcp port where sshd server is listening
  Exec Sql 
    Select RValue into :RemotePort
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'REMOTEPORT';
  If SqlState <> '00000' or RemotePort = 0;
    RSyncLog(ERROR :'Error: Missing REMOTEPORT value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;
     
  // Root is the directory you might want to replicate
  Exec Sql 
    Select RValue into :Root
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'ROOT';
  If SqlState <> '00000' or Root = '';
    RSyncLog(ERROR :'Error: Missing ROOT value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;

  // Change current directory
  If ChDir(Root) < 0;
    RSyncLog(ERROR :'Error: Root directory not found. Abort!');
    Return -1;
  EndIf;

  // RemoteRoot is the directory of the remote server
  Exec Sql 
    Select RValue into :RemoteRoot
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'REMOTEROOT';
  If SqlState <> '00000' or Root = '';
    RSyncLog(ERROR :'Error: Missing REMOTEROOT value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;

  // Attribute GlobalKnownHosts is if set to N means that you don't want to delete files in RSyncRoot
  Exec Sql 
    Select RValue into :GlobalKnownHosts
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'GLOBALKNOWNHOSTS';
  If SqlState <> '00000';
    RSyncLog(INFO :'Missing GlobalKnownHosts value into RSYNCST00F. ');
    Return -1;
  EndIf;
  GlobalKnownHosts = '-oGlobalKnownHostsFile=' + GlobalKnownHosts;

  // Attribute UserKnownHostsFile is if set to N means that you don't want to delete files in RSyncRoot
  Exec Sql 
    Select RValue into :UserKnownHosts
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'USERKNOWNHOSTS';
  If SqlState <> '00000';
    RSyncLog(INFO :'Missing USERKNOWNHOSTS value into RSYNCST00F. ');
    Return -1;
  EndIf;
  UserKnownHosts = '-oUserKnownHostsFile=' + UserKnownHosts;

  // Attribute Certificate is if set to N means that you don't want to delete files in RSyncRoot
  Exec Sql 
    Select RValue into :Certificate
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'CERTIFICATE';
  If SqlState <> '00000';
    RSyncLog(INFO :'Missing CERTIFICATE value into RSYNCST00F. ');
    Return -1;
  EndIf;
  Certificate = '-oIdentityFile=' + Certificate;

  CertificatePath = GlobalKnownHosts + ' ' + UserKnownHosts + ' ' + Certificate;

  // Attribute DeleteRootFile if set to N means that you don't want to delete files in RSyncRoot
  Exec Sql 
    Select RValue into :DeleteRootFile
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'DELETEROOTFILE';
  If SqlState <> '00000' or DeleteRootFile = '';
    RSyncLog(ERROR :'Error: Missing DELETEROOTFILE value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;

  // Attribute RSyncUser is the user you want use to doing the rsync, between two IBM I I suggest to use QSECOFR 
  //  to replicate all authorization of the stmf
  Exec Sql 
    Select RValue into :RSyncUser
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'USER';
  If SqlState <> '00000' or RSyncUser = '';
    RSyncLog(ERROR :'Error: Missing RSyncUser value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;

  // Attribute RSyncUser is the user you want use to doing the rsync, between two IBM I I suggest to use QSECOFR 
  //  to replicate all authorization of the stmf
  Exec Sql 
    Select RValue into :DtaqName
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'DTAQNAME';
  If SqlState <> '00000' or DtaqName = '';
    RSyncLog(ERROR :'Error: Missing Dtaq Value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;

  Exec Sql 
    Select RValue into :DtaqLib
      from RSyncSt00f 
      where ConfigurationId = :ConfigurationId and 
            ConfigurationName = 'DTAQLIB';
  If SqlState <> '00000' or DtaqLib = '';
    RSyncLog(ERROR :'Error: Missing Dtaq Value into RSYNCST00F. Abort!');
    Return -1;
  EndIf;
  Command = 'CrtDtaQ DtaQ(' + DtaqLib + '/' + DtaqName + ') MaxLen(700) +
        Text(' +A+ 'Invio informazione ccsid a sistema remoto(slave)' +A+ ')';
  Cmd(Command);

  Return 0;

End-Proc RSyncSetup;
// ____________________________________________________________
Dcl-Proc RSyncLog;
  Dcl-Pi RSyncLog;
    Gravity     Char(1) const;
    LogMsg      VarChar(1000) const;
  End-Pi RSyncLog;
  Dcl-S LogType      Char(9) ;
  // ____________________________________________________________

  If Gravity = ERROR;
    LogType = ' [ERROR] ';
  Else;
    LogType = ' [INFO ] ';
  EndIf;
  
  Parm1 = '/QOpenSys/pkgs/bin/bash' + X'00';
  Parm2 = '-c'  + X'00';
  // Print log into RSync log
  Parm3 = *AllX'00';
  Parm3 = 'echo "' + %Char(%Date() :*Jis) + ' ' + %Char(%Time() :*hms) + LogType + LogMsg + '" +
           >> ' + LogFile + X'00';
  Qp2Shell(Parm1 :parm2 :parm3);

  Return;

End-Proc RSyncLog;