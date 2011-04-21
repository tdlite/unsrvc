gsec -user sysdba -password masterkey -add uservice -pw uservice
isql -i sessions.sql
echo SESSIONS = C:\WINDOWS\SESSIONS.FDB >> ..\aliases.conf
PAUSE