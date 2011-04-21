CREATE DATABASE 'C:\WINDOWS\SESSIONS.FDB'
USER 'uservice' PASSWORD 'uservice' 
PAGE_SIZE = 8192 
DEFAULT CHARACTER SET WIN1251;

CREATE TABLE SESSIONS (
USERNAME VARCHAR(255) NOT NULL,
COMPNAME VARCHAR(255) NOT NULL,
FULLNAME VARCHAR(255),
FIRSTNAME VARCHAR(255),
LASTNAME VARCHAR(255),
DISPNAME VARCHAR(255),
TELEPHONE VARCHAR(255),
LOCATION VARCHAR(255),
EMAIL VARCHAR(255),
LOGON TIMESTAMP,
LOGOFF TIMESTAMP,
ONLINE SMALLINT NOT NULL,
PRIMARY KEY (USERNAME));