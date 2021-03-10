**free

// ‚Read RSYNC00F and syncronize RSyncElement to a remote IBM I

// Prerequisite:
// 5733-SC1 
// SSH server running on remote server
// Open source tecnologies Installed
// RSync installed: yum install rsync
// for more information about prerequisite consult:
// https://bitbucket.org/ibmi/opensource/src/master/

// Notes:
// 1. To make the correct RSync between two IBM I you have to use Qsecofr 
//      not for the job run but the RSync command as you can see in this source,
//      because already the file replicated doesn't get the correct authorization.
//      I didn't find any other solutions.

// 2. As you had to run rsync with root you have to set sshd.config of the remote 
//      server with this this setting:
//      PermitRootLogin yes
//      If the port of ssh server is directly open to internet I suggest to change 
//      your sshd.config to admit to listen with another port (not open to internet)

//      For example you can change this into your sshd.config:
//      # this port is open to internet
//      Port 22
//      # this port is open only for yuor local LAN
//      Port 2222  
//      # Left the value for root login set to no
//      PermitRootLogin no
//      # At the end of your sshd configuration insert this:
//      Match LocalPort 2222
//      PermitRootLogin yes

//      In this case the root login will be only admin in your local lan.

// 3. You can create the qsecofr certificate or you can change the   
//      the RSyncSt00f for the configuration name CERTIFICATE  setting the value :
//      -oGlobalKnownHostsFile=/home/someuser/known_hosts 
//      -oUserKnownHostsFile=/home/someuser/known_hosts
//      -oIdentityFile=/home/someuser/yourcertificate

//      in this case you can use a specific certificate. 
// Read README before run program.
// ________________________________________________________

Ctl-Opt 
  DftActGrp(*No)
  ActGrp(*StgMdl)
  StgMdl(*SngLvl)
  DftName(RSYNC01R)
  DatFmt(*Iso) TimFmt(*Iso)
  Alwnull(*UsrCtl)
  Option(*SrcStmt:*NoDebugIo :*NoUnRef)
  Text('Rsync Utility to replicate IFS.')
  Debug;

// Protootype definitions
Dcl-Pr RSync01r ExtPgm('RSYNC01R');
  ParmId          Char(20) const;
End-Pr RSync01r;

Dcl-Pi RSync01r;
  ParmId          Char(20) const;
End-Pi RSync01r;

// Change Directory
Dcl-Pr ChDir int(10) ExtProc('chdir');
  *n  Pointer Value Options(*string);
End-Pr ChDir;

// Open Directory
Dcl-Pr OpenDir Pointer ExtProc('opendir');
  *n  Pointer   value options(*string);
End-Pr OpenDir;

// Close Directory
Dcl-Pr CloseDir Pointer ExtProc('closedir');
  *n  Pointer   value options(*string);
End-Pr CloseDir;

// Read Directory
Dcl-Pr ReadDir Pointer ExtProc('readdir');
  *n  Pointer   value;
End-Pr ReadDir;

Dcl-Pr Sys_Errno Pointer ExtProc('__errno') End-Pr;
Dcl-S Errno Int(10) based(p_errno);

Dcl-Pr StrError Pointer ExtProc('strerror');
  errnum  Int(10) value;
End-Pr StrError;

// lstat64 Get File or Link Information
Dcl-Pr lstat64 Int(10) ExtProc('lstat64');
  *n    pointer value options(*string);
  *n    likeds(Stat64Ds);
End-Pr lstat64;

Dcl-Pr SndDtaQ ExtPgm('QSNDDTAQ');                  
  DataQueue Char(10) Const;                         
  DataQueueLib Char(10) Const;                      
  DataLen Packed(5 :0) Const;                       
  Data Char(32767) Const Options(*Varsize);         
End-Pr SndDtaQ; 

Dcl-pr usleep uns(10) extproc('usleep');
  *n uns(10) value; // millisecs
end-pr;

// Command Exec                              
Dcl-Pr Cmd Int(10) ExtProc('system');
  *n  Pointer value Options(*String);
End-Pr Cmd;

Dcl-S ErrMsgId    Char(7) Import('_EXCP_MSGID');  
Dcl-S Command     VarChar(1000);

// Call Pase                              
Dcl-Pr Qp2Shell ExtPgm('QP2SHELL');
  Parm1 Char(1000) Const Options(*VarSize :*trim);
  Parm2 Char(1000) Const Options(*VarSize :*trim);
  Parm3 Char(1000) Const Options(*VarSize :*trim);
End-Pr Qp2Shell;

// Parameter Initializations
Dcl-S Parm1 VarChar(1000) inz('/QOpenSys/pkgs/bin/-bash');
Dcl-S Parm2 VarChar(1000) inz('-c');
Dcl-S Parm3 VarChar(1000);

// RSync setup value
Dcl-S  ConfigurationId  VarChar(20);
Dcl-S  RemoteServer     VarChar(80);
Dcl-S  RemoteRoot       VarChar(640);
Dcl-S  RemotePort       Zoned(5);
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

// Work Variabile
Dcl-Ds Stat64Ds Qualified;
  mode            Uns(10);
  ino             Uns(10);
  uid             Uns(10);
  gid             Uns(10);
  size            Int(20);
  atime           Int(10);
  mtime           Int(10);
  ctime           Int(10);
  dev             Uns(10);
  blksize         Uns(10);
  nlink           Uns(5);
  codepage        Uns(5);
  allocsize       Uns(20);
  ino_gen_id      Uns(10);
  objtype         Char(11);
  reserved2       Char(5);
  rdev            Uns(10);
  rdev64          Uns(20);
  dev64           Uns(20);
  nlink32         Uns(10);
  reserved1       Char(26);
  ccsid           Uns(5);
End-Ds Stat64Ds;

Dcl-Ds DirectoryEntry  Qualified Based(DirEntryPtr);
  Reserved1       Char(16);
  FileGenGid      Uns(10);
  FileNumber      Uns(10);
  RecordLen       Uns(10);
  Reserved3       Int(10);
  Reserved4       Char(8);
  Dcl-Ds NationalInfo len(12);
    Ccsid         Int(10);
    Country       Char(2);
    Language      Char(3);
  End-Ds NationalInfo;
  NameLen         Uns(10);
  Name            Char(640);
End-Ds DirectoryEntry;

Dcl-Ds DsAttr     Qualified;
  Stmf                    VarChar(640);
  Ccsid                   Char(5);
End-Ds DsAttr;

Dcl-S PaseRSync           Char(32767) inz;
Dcl-S RSyncElement        VarChar(640);
Dcl-S RSyncDirectory      VarChar(640);
Dcl-S Rc                  Int(10);
Dcl-S ElementToExclude    VarChar(640) ;
Dcl-S StmfField           SqlType(Clob: 10000000) CcsId( 1208);
Dcl-S SqlString           VarChar(1000);
Dcl-S StmfToExcl          SqlType(Clob_File) CCsId(1208);
Dcl-S Cr                  Char(1) Inz(X'0D');
Dcl-S LogFile             VarChar(100);
Dcl-S Exclusion           VarChar(100);
Dcl-S LogMsg              VarChar(1000);
Dcl-S LibRmt              Char(20);
Dcl-S RetCode             Char(1);
Dcl-S DirectoryPtr        Pointer;
Dcl-S NumberOfDirToSinc   Int(10);
Dcl-S IdxDir              Int(10);
Dcl-S IdxSubtree          Int(10);
Dcl-S NumberOfSubDir      Int(10);
Dcl-S WorkStmf            VarChar(640);
Dcl-S RSyncFlag           Char(1);
Dcl-S DeleteRootFile      Char(1);
Dcl-S NoSubDirectory      VarChar(1000);
Dcl-S DeleteOptions       VarChar(15);
Dcl-S RSyncUser           VarChar(20);

Dcl-Ds DirectorySubTree Qualified dim(24000);
  Flag          Char(1);
  Attr          Char(1);
  Analize       Char(1);
  Del           Char(1);
  Name          VarChar(640);
End-Ds DirectorySubTree;

Dcl-Ds DirectoryToSync LikeDs(DirectorySubTree) dim(24000);

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

//‚ Log Begin RSync Process
RSyncLog(INFO: 'Start RSync Process.');

// Reading RSync00f look if there are directory deleted and alert 
If CheckForDelDirectory() < 0;
  Return;
EndIf;

LogMsg = 'Inizio Procedura CheckForNewDirectory.';
RSyncLog(INFO :LogMsg);

// Starting from root check if there are new directory 
If CheckForNewDirectory() < 0;
  Return;
EndIf;

LogMsg = 'Fine Procedura CheckForNewDirectory.';
RSyncLog(INFO :LogMsg);

//‚ Log Begin generate exclusion list
RSyncLog(INFO :'Begin Exclusion list.');

//‚ Prepare Exclusion list
If RSyncExclusionList() < 0;
  RSyncLog(ERROR :'Prepare of Exclusion list failed, check the joblog.');
  Return;
EndIf;

//‚ Log End generate exclusion list
RSyncLog(INFO :'End Exclusion list.');

If NumberOfDirToSinc > 1;
  Sorta %SubArr(DirectoryToSync(*).Name :2 :NumberOfDirToSinc - 1);
EndIf;

For IdxDir = 1 to NumberOfDirToSinc;

  If %Shtdn();
    Leave;
  EndIf;
  // Write Record to better read RSync Log
  RSyncLog(INFO :'RSync Element: ' + DirectoryToSync(IdxDir).Name + '.');

  // For the root dir I will sincronize only the files prensent into root dir
  If DirectoryToSync(IdxDir).Attr = SYNCROOT or DirectoryToSync(IdxDir).Flag = FIRSTLEVEL;
    If %SubSt(DirectoryToSync(IdxDir).Name :%Len(DirectoryToSync(IdxDir).Name) :1) <> '/';
      WorkStmf =  DirectoryToSync(IdxDir).Name + '/';
    Else;
      WorkStmf =  DirectoryToSync(IdxDir).Name;
    EndIf;
    NoSubDirectory = ' --filter="- ' + WorkStmf + '*/" --filter="+ *"';
  Else;
    NoSubDirectory = '';
  EndIf;

  If DirectoryToSync(IdxDir).Del = NO;
    DeleteOptions = '';
  Else;
    DeleteOptions = '--delete ';
  EndIf;

  ToSite = RSyncUser + '@' + %Trim(RemoteServer) + ':' + RemoteRoot + ' ';
  FromSite = '"' + DirectoryToSync(IdxDir).Name + '" ';

  // Invoke RSync
  Parm3 = 'rsync -avRqhpe "ssh ' + CertificatePath + ' -p' + %Char(RemotePort) + '"  '+  
          FromSite + ToSite + DeleteOptions +
          NoSubDirectory + ' --log-file=' + LogFile + 
          ' --exclude-from ' +A+ Exclusion +A+ X'00';

  Qp2Shell(Parm1 :Parm2 :Parm3);

EndFor;

// Setting CCSID to remote
If SetCCSID() < 0;
  RSyncLog(INFO :'RSync Errore set ccsid su remoto');
EndIf;

// Write Record to better read RSync Log
RSyncLog(INFO :'RSync End of Syncronization.');

Return;

// ___________________________________________________________________________________
Dcl-Proc RSyncExclusionList;
  Dcl-Pi RSyncExclusionList Int(10);
  End-Pi RSyncExclusionList;
  // ___________________________________________________________________________________

  StmfToExcl_Name = Exclusion;
  StmfToExcl_NL = %Len(Exclusion);
  StmfToExcl_FO = SQFOVR; //‚OverWrite
  StmfField_len  = 0;


  // Select from RSync00f all the element UNKNOWN and NOTSYNCRONIZE
  Exec Sql 
    Declare ExclCur cursor for
      Select RSyncElement
          from RSync00f
          where ConfigurationId = :ConfigurationId and 
                RSyncFlag in (:UNKNOWN, :NOTSYNCRONIZE)
          Order by 1;

  Exec Sql Open ExclCur;
  If SqlState <> '00000' or Directory = '';
    RSyncLog(ERROR :'Error: Apertura cursore su RSync00f non riuscita!'); 
    Return -1;
  EndIf;

  Dow not %Shtdn();

    Exec Sql 
      Fetch next from ExclCur Into :ElementToExclude;

    If SqlState = '02000';
      Leave;
    EndIf;

    If Stmffield_len = 0;
      StmfField_Data = ElementToExclude + Cr;
    Else;
      StmfField_Data = %Subst(StmfField_Data :1 :StmfField_len) + ElementToExclude + Cr;
    EndIf;
    StmfField_len  = StmfField_len + %len(ElementToExclude) + 1;

  EndDo;

  Exec Sql Close ExclCur;

  Exec Sql Set :StmfToExcl = :StmfField;

  If SqlState <> '00000';
    Return -1;
  EndIf;

  Return 0;

End-Proc RSyncExclusionList;

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

// ____________________________________________________________                                                  
Dcl-Proc CheckForNewDirectory;
  Dcl-Pi CheckForNewDirectory Int(10);
  End-Pi CheckForNewDirectory;
  Dcl-s  WorkDir Varchar(640);
// ____________________________________________________________                                                  

  IdxDir = 1;
  NumberOfDirToSinc = 1;
  // Starting from the Root parameter read from RSyncSt00f look for new directory
  //  the root directory will always be set to RECURSIVE
  DirectoryToSync(IdxDir).Name    = Root;
  DirectoryToSync(IdxDir).Flag    = RECURSIVE;
  DirectoryToSync(IdxDir).Attr    = SYNCROOT;
  DirectoryToSync(IdxDir).Del     = DeleteRootFile;

  Dow Not %Shtdn();

    WorkDir = DirectoryToSync(IdxDir).Name;
    Exec Sql 
      Declare ListDir cursor for
        Select path_name
          From Table(
              QSys2.Ifs_Object_Statistics(:WorkDir, 'NO', '*ALLDIR', ''))
          Order by 1;
    Exec Sql Open ListDir;
    If SqlState <> '00000';
      LogMsg = 'Error in Open Directory: ' + SqlState;
      RSyncLog(ERROR :LogMsg);
      Exec Sql Close ListDir;
      Return -1;
    EndIf;

    Clear DirectorySubTree;

    If ReadDirectory(IdxDir) < 0;
      Return -1;
    EndIf;

    Exec Sql Close ListDir;

    // Once Read the Directory set the analize flag to YES
    DirectoryToSync(IdxDir).Analize = 'Y';

    For IdxSubtree = 1 To NumberOfSubDir; 

      If DirectorySubTree(IdxSubtree).Flag = RECURSIVE or DirectorySubTree(IdxSubtree).Flag = FIRSTLEVEL;
        NumberOfDirToSinc += 1;
        DirectoryToSync(NumberOfDirToSinc) = DirectorySubTree(IdxSubtree);
        DirectoryToSync(NumberOfDirToSinc).Attr = SUBDIRECTORY;
        // If this directory is set to RECURSIVE I didn't have to analize for new directory
        If DirectorySubTree(IdxSubtree).Flag = RECURSIVE;
          DirectoryToSync(NumberOfDirToSinc).Analize = 'Y';
        EndIf;
      EndIf;

    EndFor;  

    // Look for new directory to read
    IdxDir = %Lookup('' :DirectoryToSync(*).Analize :1 :NumberOfDirToSinc);
    // If all directory are read return
    If IdxDir = 0;
      Leave;
    EndIf;

  EndDo;  

  Return 0;

End-Proc CheckForNewDirectory;

// ____________________________________________________________                                                  
Dcl-Proc CheckForDelDirectory;
  Dcl-Pi CheckForDelDirectory Int(10);
  End-Pi CheckForDelDirectory;

  Dcl-S DirectoryToCheck Varchar(640);
// ____________________________________________________________                                                  

  Exec Sql 
    Declare RSyncDel cursor for
    Select RSyncElement
      from RSync00f 
      where ConfigurationId = :ConfigurationId;

  Exec Sql 
    Open RSyncDel;
  
  Clear Stat64Ds;

  Dow SqlState <> '02000';

    Exec Sql
      Fetch next from RSyncDel into :DirectoryToCheck;
    If SqlState = '02000';
      Leave;
    EndIf;
    
    // get file or directory informations, I use it to know if it is a file or a Directory
    If lstat64(DirectoryToCheck :Stat64Ds) = -1;
      P_Errno = Sys_Errno();
      LogMsg = 'Directory: ' + DirectoryToCheck + ' not found: ' + %Str(StrError(Errno));
      RSyncLog(ERROR :LogMsg);
      Exec Sql 
        Close RSyncDel;
      Return -1;
    EndIf;

  EndDo;
  
  Exec Sql 
    Close RSyncDel;

  Return 0;
  
End-Proc CheckForDelDirectory;  
// ____________________________________________________________                                                  
Dcl-Proc ReadDirectory;
  Dcl-Pi ReadDirectory Int(10);
    CurrentIndex   Int(10) const;
  End-Pi ReadDirectory;

// ____________________________________________________________                                                  

  IdxSubtree = 0;
  
  // Read the directory opened
  Dow not %Shtdn();

    Exec Sql Fetch next from ListDir into :WorkStmf;
    If SqlState = '02000';
      NumberOfSubDir = IdxSubtree;
      Return 0;
    EndIf;
    If SqlState <> '00000';
      LogMsg = 'Error in fetch: ' + SqlState;
      RSyncLog(ERROR :LogMsg);
      Return -1;
    EndIf;
    If WorkStmf = DirectoryToSync(CurrentIndex).Name;
      Iter;
    EndIf;

    IdxSubtree +=1;
    DirectorySubTree(IdxSubtree).Flag = 'N';
    DirectorySubTree(IdxSubtree).Name = WorkStmf;

    // Check for which kind of Syncronization you want for this directory
    If CheckSyncronizationSetting() < 0;
      Return -1;
    EndIf;

    // If DirectorySubTree(IdxSubtree).Flag = RECURSIVE;
    //   Leave;
    // EndIf;

  EndDo;  

  Return 0;

End-Proc ReadDirectory;

// ____________________________________________________________                                                  
Dcl-Proc CheckSyncronizationSetting;
  Dcl-Pi CheckSyncronizationSetting Int(10);
  End-Pi CheckSyncronizationSetting;

  Dcl-S RSyncFlag    Char(1) inz('');
  Dcl-S RSyncDelete  Char(1) inz('');
// ____________________________________________________________                                                  


    // Check if exist and which setting have into RSync00f
    Exec Sql  
      Select RSyncFlag, RSyncDelete into :RSyncFlag, :RSyncDelete
        from RSync00f
        where ConfigurationId = :ConfigurationId and 
              RSyncElement = :WorkStmf;

    Select;
      // If not found write a new record into RSync00f 
      // with flag set to UNKNOWN 
      When SqlState = '02000';
        Exec Sql 
          Insert into RSync00f (ConfigurationId, RSyncElement, RSyncFlag, RSyncDelete)
            Values(:ConfigurationId, :WorkStmf, :UNKNOWN, :NO);
        If SqlState <> '00000';
          RSyncLog(ERROR :'Error in Insert of new Directory: ' + WorkStmf);
        EndIf;

      // Recursive mean that all the directory and sub-directory starting from this will be syncronize
      When RSyncFlag = RECURSIVE;
        DirectorySubTree(IdxSubtree).Flag = RECURSIVE;
      
      // First level means that this directory will be syncronize
      //  the subdirectory depends on what you have set into RSync00f 
      //  so we have to analize al the tree
      When RSyncFlag = FIRSTLEVEL;
        DirectorySubTree(IdxSubtree).Flag = FIRSTLEVEL;
      
      // Not Syncronize means that you don't want to syncronize this directory and all the sub-directory
      When RSyncFlag = NOTSYNCRONIZE;
        DirectorySubTree(IdxSubtree).Flag = NOTSYNCRONIZE;
            
      // Unknown you have to set in RSync00f what you can do with this directory
      When RSyncFlag = UNKNOWN;
        DirectorySubTree(IdxSubtree).Flag = UNKNOWN;
      
      Other;
        RSyncLog(ERROR :'RSyncFlag: '+ RSyncFlag + ' not expected for Directory: ' + WorkStmf);
        Return -1;
        
    EndSl;

    DirectorySubTree(IdxSubtree).Del = RSyncDelete;

    Return 0;

End-Proc CheckSyncronizationSetting;

// ____________________________________________________________                                                  
Dcl-Proc SetCCSID;
  Dcl-Pi SetCCSID Int(10);
  End-Pi SetCCSID;
  // ____________________________________________________________                                                  

  Parm3 = 'rm ' + Directory + '/setccsid.txt' ;

  Qp2Shell(Parm1 :Parm2 :Parm3);

  Parm3 = 'grep ' +A+ '<f' +A+ ' ' + LogFile + ' |  awk ' +A+ '{ print $5 }' +A+ 
            ' | sort | uniq -c | awk '+A+ '{ print $2 }'+A+ ' > ' + Directory + '/setccsid.txt' ;

  Qp2Shell(Parm1 :Parm2 :Parm3);

  Exec Sql
    Declare Global Temporary table StmfCcsId
      (Stmf varchar(640) NOT NULL ccsid 1208)
      with replace;

  Command = 'CpyFrmImpf FromStmf(' +A+ Directory + '/setccsid.txt' +A+ ') +   
           ToFile(StmfCcsId) MbrOpt(*Replace) RcdDlm(*ALL) StrDlm(*None)';

  If Cmd(Command) < 0;
    RSyncLog(ERROR :'Errore nella copia da setccsid.txt al file fisico');
    Return -1;
  EndIf;

  Exec Sql 
    Declare CcsIdCur cursor for
      Select Stmf from stmfccsid;

  Exec Sql Open CcsIdCur;

  If SqlState <> '00000';
    RSyncLog(ERROR :'Error: Apertura cursore su StmfCcsId non riuscita!'); 
    Return -1;
  EndIf;

  Dow not %Shtdn();  

    DsAttr = ' ';

    Exec Sql
      Fetch next from CcsIdCur into :DsAttr.Stmf;
    If SqlState = '02000';
      Leave;
    EndIf;

    // Reperisco il CCSID del File
    Exec Sql
      Select CCSID into :DsAttr.CCsId 
            From Table(QSys2.Ifs_Object_Statistics(:Dsattr.Stmf));

    If SqlState <> '00000';
      RSyncLog(ERROR :'Error: Lettura CCSID per file: ' + Dsattr.Stmf + ' non riuscita verificare.'); 
      Iter;
    EndIf;

    // Invio a sistema remoto solo i ccsid <> da 819
    If DsAttr.CcsId = '819';
      Iter;
    EndIf;
    
    SndDtaq(DtaqName :DtaqLib :%Len(DsAttr) :DsAttr);

    USleep(30000);

    RSyncLog(INFO :'Setccsid: for ' + DsAttr.Stmf + ' to: ' + DsAttr.Ccsid + '.');
  
  EndDo;

  Exec Sql Close CcsIdCur;

  Return 0;

End-Proc SetCCSID;

// ____________________________________________________________                                                  
Dcl-Proc RSyncLog;
  Dcl-Pi RSyncLog;
    Gravity     Char(1) const;
    LogMsg      VarChar(1000) const;
  End-Pi RSyncLog;
  Dcl-S LogType      Char(9) ;
  // ____________________________________________________________                                                  

  If Gravity = ERROR;
    LogType = ' [ERROR] ';
  Else;
    LogType = ' [INFO ] ';
  EndIf;
  // Print log into RSync log
  Parm3 = 'echo "' + %Char(%Date() :*Jis) + ' ' + %Char(%Time() :*hms) + LogType + LogMsg + '" +
           >> ' + LogFile + X'00';
  Qp2Shell(Parm1 :parm2 :parm3);

  Return;

End-Proc RSyncLog;