Create or Replace Table RSync00f (
    InsertTimestamp for column InsertTs     TIMESTAMP DEFAULT CURRENT_TIMESTAMP , 
    ConfigurationId      for column configId       Varchar(20) ccsid 1208 not null,    
    RSyncElement    for column RSyncElem    varchar(640) ccsid 1208 not null,
    RSyncFlag                               char(1)       ccsid 1208 not null,
    RSyncDelete                             char(1)       ccsid 1208 not null,
    Primary key (ConfigurationId, RSyncElement))
    RcdFmt RSyncRec;
    
Label on Table RSync00f is
     'RSync - List of directory/exclusion';

Label on Column RSync00f (
     InsertTimestamp is 'Insert              Timestamp',
     ConfigurationId is 'Configuration       ID',
     RSyncElement    is 'Element to          Replicate or        Exclude',
     RSyncFlag       is 'RSync               Flag',
     RSyncDelete     is 'Delete              Remote              File');
     
Label on Column RSync00f (
     InsertTimestamp Text is 'Insert Timestamp',  
     ConfigurationId Text is 'Configuration ID',
     RSyncElement    Text is 'Element to Replicate or Exclude',
     RSyncFlag       Text is 'RSync Flag',
     RSyncDelete     Text is 'Delete Remote File');     
     
     
Create or Replace Table RSyncSt00f (
    ConfigurationId      for column configId       Varchar(20) ccsid 1208 not null,
    ConfigurationName    for column configNam      Varchar(20)   ccsid 1208 not null,
    RValue                                         VarChar(1000) ccsid 1208 not null,
    Primary key (ConfigurationId, ConfigurationName))
    RcdFmt RSyncSt;
    
Label on Table RSyncSt00f is
     'RSync - Configuration file';

Label on Column RSyncSt00f (
     ConfigurationId   is 'Configuration       ID',
     ConfigurationName is 'Configuration       Name',
     RValue            is 'Configuration       Value');
     
Label on Column RSyncSt00f (
     ConfigurationId    Text is 'Configuration ID',
     ConfigurationName  Text is 'Configuration Name',
     RValue             Text is 'Configuration Value');         
     
--Select *From rsyncst00f for update;
     