Insert into RSyncSt00f 
Values('SAMPLECONGIG', 'REMOTESERVER', 'your_remote_server');         
     
Insert into RSyncSt00f 
Values('SAMPLECONGIG', 'REMOTEPORT', 'your_remote_port');     
     
Insert into RSyncSt00f 
Values('SAMPLECONGIG', 'DIRECTORY', 'decide_where_you_can'); -- You have to put a master directory for Rsync and then a subdirectory that as the same name of the configuration e.g. '/RSyncRpgle/SAMEPLECONFIG'

Insert into RSyncSt00f 
Values('SAMPLECONGIG', 'ROOT', 'put_here_a_test_directory'); -- e.g. a directory in your home

Insert into RSyncSt00f 
Values('SAMPLECONGIG', 'CERTIFICATE', 
'-oGlobalKnownHostsFile=/home/ssh_global_known_hosts/known_hosts -oUserKnownHostsFile=/home/ssh_global_known_hosts/known_hosts -oIdentityFile=/home/ssh_global_known_hosts/id_rsa_d1'); 
-- I suggest to try with a simple ssh connect test with this parameter before call the program

Insert into RSyncSt00f 
Values('SAMPLECONGIG', 'DELETEROOTFILE', 'N'); 

Insert into RSyncSt00f 
Values('SAMPLECONGIG', 'USER', 'qsecofr'); 

select *from rsyncst00f for update;      