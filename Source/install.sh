#!/QOpenSys/pkgs/bin/env bash

# Create directory
echo "Create directory for source program and DDL named: RSyncRpgle in root"
#mkdir /RSyncRpgle
cd /RSyncRpgle

echo "Create directory for DDL"
mkdir DDL

echo "Create directory for source program"
mkdir Source

# Download source code and instruction from bitbucket
echo "Automatic download source code and instruction from bitbucket: https://bitbucket.org/pabloto/rsyncrpgle"

curl https://bitbucket.org/pabloto/rsyncrpgle/raw/HEAD/READMEME.md -o README.md >> install.log
curl https://bitbucket.org/pabloto/rsyncrpgle/raw/HEAD/LICENCE -o LICENCE >> install.log
curl https://bitbucket.org/pabloto/rsyncrpgle/raw/HEAD/DDL/RSync_Setup_value.sql -o DDL/RSync_Setup_value.sql >> install.log
curl https://bitbucket.org/pabloto/rsyncrpgle/raw/HEAD/DDL/RSync_Tables.sql -o DDL/RSync_Tables.sql >> install.log
curl https://bitbucket.org/pabloto/rsyncrpgle/raw/HEAD/Source/Rsync01r.sqlrpgle -o Source/Rsync01r.sqlrpgle >> install.log

# Input the library in which you want to create the RSyncTable
echo "Input the library in which you want to create the RSync Table, followed by [ENTER]"

read library

system -kKveO "addlible lib($library)" >> install.log

system -kKveO "chgcurlib curlib($library)" >> install.log

echo "Create RSync Tables."
system -kKveO "RunSqlStm SrcStmf('DDL/RSync_Tables.sql') Commit(*None) DatFmt(*Iso) TimFmt(*Iso)" >> install.log

system -kKveO "MovObj Obj(RSyncSt00f) ToLib($library) ObjType(*File)" >> install.log
system -kKveO "MovObj Obj(RSync00f) ToLib($library) ObjType(*File)" >> install.log

# Input the library in which you want to create the RSync program utilities
echo "Input the library in which you want to create the RSync program utilities, followed by [ENTER]"

read library

system -kKveO "addlible lib($library)" >> install.log

system -kKveO "chgcurlib curlib($library)" >> install.log

echo "Create RSync program."
system -kKveO "CrtSqlRpgI Obj($library/RSync01r) Srcstmf('Source/Rsync01r.sqlrpgle') Commit(*None) Text('RSync Rpgle Utility') TgtRls(*Current) CloSqlCsr(*EndMod) DatFmt(*Iso) TimFmt(*Iso) DbgView(*Source)" >> install.log

echo "Installation finished look at the REAME.md for all the prerequisites."
