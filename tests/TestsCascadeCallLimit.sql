--#SET TERMINATOR @

/**
 * Tests for the conf loggers effective table.
 */

SET CURRENT SCHEMA LOGGER_1A @

CREATE OR REPLACE PROCEDURE LOGGING (
  IN VAL SMALLINT,
  IN LEVEL SMALLINT,
  IN LIMIT SMALLINT)
 BEGIN
  DECLARE STMT STATEMENT;
  
--  IF (VAL >= LIMIT) THEN
--   CASE LEVEL
--    WHEN 1 THEN
--     CALL LOGGER.FATAL(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
--    WHEN 2 THEN
--     CALL LOGGER.ERROR(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
--    WHEN 3 THEN
--     CALL LOGGER.WARN(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
--    WHEN 4 THEN
--     CALL LOGGER.INFO(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
--    WHEN 5 THEN
--     CALL LOGGER.DEBUG(0, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
--    ELSE
     CALL LOGGER.LOG(0, 3, 'Cascade call for "LOGGING" enters with ' || COALESCE(VAL, -1));
--    END CASE;
   COMMIT;
--  ELSE
   PREPARE STMT FROM 'CALL LOGGING(?, ?, ?)';
--   EXECUTE STMT USING VAL + 1, LEVEL, LIMIT;
--  END IF;
 END @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE RAISED_LG001 BOOLEAN DEFAULT FALSE; -- Just one ROOT.
DECLARE RAISED_724 BOOLEAN DEFAULT FALSE; -- Null value.
DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LOGS.MESSAGE;
-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG001'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG001 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '54038'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_724 = TRUE;
  END;

  -- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCascadeCallLimit: Preparing environment');
SET RAISED_LG001 = FALSE;
SET RAISED_724 = FALSE;
DELETE FROM LOGDATA.LOGS;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
COMMIT;

---- Test1: Limit logging to ROOT with fatal.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test1: Limit logging to ROOT with fatal');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 1, 60);
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE = '[FATAL] ROOT - Cascade call for "LOGGING" enters with 60';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test2: Limit achieved logging to ROOT with fatal.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test2: Limit achieved logging to ROOT with fatal');
--SET EXPECTED = 'TRUE';
----DELETE FROM LOGS
----  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--CALL LOGGING(1, 1, 61);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test3: Limit passed logging to ROOT with fatal.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test3: Limit passed logging to ROOT with fatal');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 1, 62);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for FATAL: (0) Cascade call for "LOGGING" en%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test4: Cascade call limit with fatal.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test4: Cascade call limit with fatal');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 1, 63);
--IF (RAISED_724 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
--END IF;
--SET RAISED_724 = FALSE;
--COMMIT;
--
---- Test5: Limit logging to ROOT with error.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test5: Limit logging to ROOT with error');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 2, 60);
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE = '[ERROR] ROOT - Cascade call for "LOGGING" enters with 60';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test6: Limit achieved logging to ROOT with error.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test6: Limit achieved logging to ROOT with error');
--SET EXPECTED = 'TRUE';
--DELETE FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--CALL LOGGING(1, 2, 61);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test7: Limit passed logging to ROOT with error.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test7: Limit passed logging to ROOT with error');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 2, 62);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for ERROR: (0) Cascade call for "LOGGING" en%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test8: Cascade call limit with error.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test8: Cascade call limit with error');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 2, 63);
--IF (RAISED_724 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
--END IF;
--SET RAISED_724 = FALSE;
--COMMIT;
--
---- Test9: Limit logging to ROOT with warn.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test9: Limit logging to ROOT with warn');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 3, 60);
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE = '[WARN ] ROOT - Cascade call for "LOGGING" enters with 60';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test10: Limit achieved logging to ROOT with warn.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Limit achieved logging to ROOT with warn');
--SET EXPECTED = 'TRUE';
--DELETE FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--CALL LOGGING(1, 3, 61);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test11: Limit passed logging to ROOT with warn.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Limit passed logging to ROOT with warn');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 3, 62);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for WARN: (0) Cascade call for "LOGGING" en%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test12: Cascade call limit with warn.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test12: Cascade call limit with warn');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 3, 63);
--IF (RAISED_724 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
--END IF;
--SET RAISED_724 = FALSE;
--COMMIT;
--
---- Test13: Limit logging to ROOT with info.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test13: Limit logging to ROOT with info');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 4, 60);
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE = '[INFO ] ROOT - Cascade call for "LOGGING" enters with 60';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test14: Limit achieved logging to ROOT with info.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test14: Limit achieved logging to ROOT with info');
--SET EXPECTED = 'TRUE';
--DELETE FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--CALL LOGGING(1, 4, 61);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test15: Limit passed logging to ROOT with info.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test15: Limit passed logging to ROOT with info');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 4, 62);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for INFO: (0) Cascade call for "LOGGING" en%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test16: Cascade call limit with info.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test16: Cascade call limit with info');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 4, 63);
--IF (RAISED_724 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
--END IF;
--SET RAISED_724 = FALSE;
--COMMIT;
--
---- Test17: Limit logging to ROOT with debug.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test17: Limit logging to ROOT with debug');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 5, 60);
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE = '[DEBUG] ROOT - Cascade call for "LOGGING" enters with 60';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test18: Limit achieved logging to ROOT with debug.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test18: Limit achieved logging to ROOT with debug');
--SET EXPECTED = 'TRUE';
--DELETE FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--CALL LOGGING(1, 5, 61);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test19: Limit passed logging to ROOT with debug.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test19: Limit passed logging to ROOT with debug');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 5, 62);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for DEBUG: (0) Cascade call for "LOGGING" en%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test20: Cascade call limit with debug.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test20: Cascade call limit with debug');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, 5, 63);
--IF (RAISED_724 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
--END IF;
--SET RAISED_724 = FALSE;
--COMMIT;

-- Test21: Limit logging to ROOT with default.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test21: Limit logging to ROOT with default');
SET EXPECTED = 'TRUE';
CALL LOGGING(1, 6, 55);
SELECT 'TRUE' INTO ACTUAL
  FROM LOGS
  WHERE MESSAGE = '[DEBUG] ROOT - Cascade call for "LOGGING" enters with 60';
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;
--
---- Test22: Limit achieved logging to ROOT with default.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test22: Limit achieved logging to ROOT with default');
--SET EXPECTED = 'TRUE';
--DELETE FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--CALL LOGGING(1, -1, 61);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for LOG: Cascade call for "LOGGING" enters w%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test23: Limit passed logging to ROOT with default.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test23: Limit passed logging to ROOT with default');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, -1, 62);
--IF (RAISED_LG001 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG001');
--END IF;
--SET RAISED_LG001 = FALSE;
--SELECT 'TRUE' INTO ACTUAL
--  FROM LOGS
--  WHERE MESSAGE LIKE 'Cascade call limit achieve, for DEBUG: (0) Cascade call for "LOGGING" en%';
--IF (EXPECTED <> ACTUAL) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different MESSAGE ' || EXPECTED || ' - ' || ACTUAL);
--END IF;
--COMMIT;
--
---- Test24: Cascade call limit with default.
--INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test24: Cascade call limit with default');
--SET EXPECTED = 'TRUE';
--CALL LOGGING(1, -1, 63);
--IF (RAISED_724 = FALSE) THEN
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
--ELSE
-- INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 54038');
--END IF;
--SET RAISED_724 = FALSE;
--COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCascadeCallLimit: Cleaning environment');
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCascadeCallLimit: Finished succesfully');
COMMIT;

END @

DROP PROCEDURE LOGGING @