# RSync Rpgle
- [Prerequisites](#markdown-header-prerequisites)
- [Scope](#markdown-header-scope)
- [Tables](#markdown-header-tables)
- [Installations Notes](#markdown-header-installation-notes)
- [Notes about sshd configuration](#markdown-header-notes-about-sshd-configuration)
- [How does it works](#markdown-header-how-does-it-works)
- [Contribution Agreement](#markdown-header-contribution-agreement)
---
## Prerequisites
	1. 5733-SC1 Installed
	2. SSH server running on remote server
	3. Open source tecnologies Installed
	    Bash and RSync installed: yum install rsync bash
	    for more information about this installation please consult:
	    https://bitbucket.org/ibmi/opensource/src/master/

## Scope
The pourpose of this utility is to replicate your ifs to a remote server (like a disaster recovery).

## Tables

### RSync setup
**RSYNCST00F** 

Field Name | Alias | Type | Dimensions | Text
--- | --- | --- | ---: | --- 
configId  | ConfigurationId | Varchar | 20 | Id of RSync configuration
configNam	|  ConfigurationName | Varchar | 20 | Configuration Name see description for possible values
RValue | RValue | Varchar | 1000 | Configuration value

#### Possible values of ConfigurationName (please this field is case sensitive):

Configuration value |  Description
--- | ---
REMOTESERVER | Remote server as you want to do the syncronization
REMOTEPORT | Remote port in which the server ssh is listening  please read the suggestion about the sshd.config of the remote server
DIRECTORY | This utility need a directory in which will be the rsync log and an exclusion file
ROOT | This is your root directory you want replicate the Rsync start from there to replicate all the subdirectory you want 
CERTIFICATE | See note for Certificate
DELETEROOTFILE | Put N if you doesn't want to delete remote files in root directory that not exist in local 
USER | Remote user. To make the correct RSync between two IBM I you have to use QSECOFR not for the job run but this will be the user used by RSync command, to replicated the correct authorization.  I didn't find any other solutions. 

#### Notes for certificate  
This is the certificate you want use to made the syncronitation.  
You can use a global cerfificate with this sintax:  
-oGlobalKnownHostsFile=/home/someuser/known_hosts  
-oUserKnownHostsFile=/home/someuser/known_hosts  
-oIdentityFile=/home/someuser/yourcertificate  


 
### RSync directory tree
**RSYNC00F** 

Field Name | Alias | Type | Dimensions | Text
--- | --- | --- | ---: | --- 
InsertTs  | InsertTimestamp | Timestamp | - | Insert Timestamp
configId  | ConfigurationId | Varchar | 20 | Id of RSync configuration
RSyncElem	|  RSyncElement | Varchar | 640 | Element to Replicate or Exclude
RSyncFlag | RSyncFlag | Char | 1 | See description for possible values
RSyncDelete | RSyncDelete | Char | 1 | Set N to doesn't remove remote file that not exist in local 

#### Possible values of RSyncFlag:
Value | Description
--- | --- 
R | Recursive. RSync will syncronize all the files and subdirectory starting from this Directory.
F | First Level. RSync will syncronize all the files starting from this Directory. The Subdirectory will be written in this files with RSyncFlag set to ? (UNKNOWN).
? | Unknown. RSync will do nothing. You have to decide if you want to syncronize it by putting R or F or N (Not syncronize).
N | Not Syncronize. RSync will do nothing. All the files and subdirectory in this directory will be ignored.

## Installation notes
You can choose two kind of installation.  

1. If you have set into your pase path the directory /QOpenSys/pkgs/bin download the install.sh from Source directory into your home directory, then from pase run the script install.sh, it require curl installed, and it ask where you want to install.

2. Simply download the RSYNCRPGLE.SAVF and restore it where you want.

## Notes about sshd configuration

1. To make the correct RSync between two IBM I you have to use QSECOFR not for the job run but this will be the user used by RSync command, to replicated the correct authorization.  I didn't find any other solutions.   
2. As you had to run rsync with root you have to set sshd.config of the remote 
     server with this this setting:  
     PermitRootLogin yes  
     If the port of ssh server is directly open to internet I suggest to change 
     your sshd.config to admit to listen with another port (not open to internet)  
     For example you can change this line into your sshd.config:    
     `# this port is open to internet`  
     Port 22  
     `# this port is open only for yuor local LAN e.g. 2222`  
     Port 2222  
     `# Left the value for root login set to no`  
     PermitRootLogin no  
     `# At the end of your sshd configuration insert this:`  
     Match LocalPort 2222  
     PermitRootLogin yes  
       
     In this case the root login will be only admin in your local lan.  

## How does it works
The intent of this utility is to replicate your ifs to a remote server (for the moment I try only with two IBM I).
Once you have made the correct setting in RSyncSt00f you can try to run it.
In the first run the program will syncronize all the files in the root directory you have define, then it will write all the subdirectories in the file RSync00f, 
so you have to decide by setting the flag 'R', 'F', 'N' in RSyncFlag, and so on.

  
## Contribution Agreement
If you contribute code to this project, you are implicitly allowing your code to be distributed under the MIT license. You are also implicitly verifying that all code is your original work.

People - Paolo Salvatore.
