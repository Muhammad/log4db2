--#SET TERMINATOR @
SET CURRENT SCHEMA TESTS @

SET PATH = "SYSIBM","SYSFUN","SYSPROC","SYSIBMADM", LOGGER_1 @

CREATE SCHEMA TESTS @

CREATE OR REPLACE PROCEDURE TESTS.CONNECTION_SETUP()
BEGIN
 -- Do nothing if there is a problem.
 --DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
 -- SET CURRENT SCHEMA TESTS; 
 CALL LOGGER.FATAL(0, 'Connection established by ' || CURRENT USER);
END @

--#SET TERMINATOR ;
UPDATE DB CFG USING CONNECT_PROC TESTS.CONNECTION_SETUP;
 
CONNECT RESET;

-- The following statements are to reverse the configuration.
CONNECT TO LOG4DB2;

UPDATE DB CFG USING CONNECT_PROC NULL;

DROP PROCEDURE TESTS.CONNECTION_SETUP;

DROP SCHEMA TESTS RESTRICT;

CONNECT RESET;