--#SET TERMINATOR @

/**
 * Tests for the conf loggers effective table.
 */

SET CURRENT SCHEMA LOGGER_1 @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE LAST_VALUE ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE CURRENT_VALUE ANCHOR DATA TYPE TO LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE RAISED_LG002 BOOLEAN; -- Logger without parent.
DECLARE RAISED_LG003 BOOLEAN; -- ROOT logger should always exist.
DECLARE RAISED_407 BOOLEAN; -- Not null.
DECLARE RAISED_530 BOOLEAN; -- Foreign key.

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG002' SET RAISED_LG002 = TRUE;
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG003' SET RAISED_LG003 = TRUE;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502' SET RAISED_407 = TRUE;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23503' SET RAISED_530 = TRUE;
-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('TestsUndeletable: Preparing environment');
SET RAISED_LG002 = FALSE;
SET RAISED_LG003 = FALSE;
SET RAISED_407 = FALSE;
SET RAISED_530 = FALSE;
SELECT LOGGER_ID INTO LAST_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('TEST', 0, 0));
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID <> 0;

-- Test1: Inserts a normal logger.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test1: Inserts a normal logger');
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test1', 0, 0);

-- Test2: Inserts a logger with a given id.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test2: Inserts a logger with a given id');
-- Compilation error.
--INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID) VALUES
--  (2, 'test2', 0, 0);

-- Test3: Inserts a logger with a null id.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test3: Inserts a logger with a null id');
-- Compilation error.
--INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID) VALUES
--  (NULL, 'test3', 0, 0);

-- Test4: Inserts a logger with a negative id.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test4: Inserts a logger with a negative id');
-- Compilation error.
--INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID) VALUES
--  (-1, 'test4', 0, 0);

-- Test5: Inserts a logger with an inexistent parent.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test5: Inserts a logger with an inexistent parent');
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test5', LAST_VALUE + 5, 0);
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_530 = FALSE;

-- Test6: Inserts a logger with an null parent.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test6: Inserts a logger with an null parent');
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test6', NULL, 0);
IF (RAISED_LG002 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG002 = FALSE;

-- Test7: Inserts a logger with an null level.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test7: Inserts a logger with an null level');
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test7', 0, NULL);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test8: Inserts a logger with an inexistent level.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test8: Inserts a logger with an inexistent level');
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test8', 0, -1);
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_530 = FALSE;

-- Test9: Updates a normal logger.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test9: Updates a normal logger');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test9', 0, 0));
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET NAME = 'test9-1', PARENT_ID = LAST_VALUE + 1
  WHERE LOGGER_ID = CURRENT_VALUE;

-- Test10: Updates a logger with a given id.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test10: Updates a logger with a given id');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test10', 0, 0));
-- Compilation error.
--UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
--  SET LOGGER_ID = CURRENT_VALUE + 1
--  WHERE LOGGER_ID = CURRENT_VALUE;

-- Test11: Updates a logger with a null id.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test11: Updates a logger with a null id');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test11', 0, 0));
-- Compilation error.
--UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
--  SET LOGGER_ID = NULL
--  WHERE LOGGER_ID = CURRENT_VALUE;

-- Test12: Updates a logger with a negative id.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test12: Updates a logger with a negative id');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test12', 0, 0));
-- Compilation error.
--UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
--  SET LOGGER_ID = -1
--  WHERE LOGGER_ID = CURRENT_VALUE;

-- Test13: Updates a logger with an inexistent parent.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test13: Updates a logger with an inexistent parent');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test13', 0, 0));
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET PARENT_ID = CURRENT_VALUE + 1
  WHERE LOGGER_ID = CURRENT_VALUE;
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_530 = FALSE;

-- Test14: Updates a logger with an null parent.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test14: Updates a logger with an null parent');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test14', 0, 0));
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET PARENT_ID = NULL
  WHERE LOGGER_ID = CURRENT_VALUE;
IF (RAISED_LG002 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG002 = FALSE;

-- Test15: Updates a logger with an null level.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test15: Updates a logger with an null level');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test15', 0, 0));
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = NULL
  WHERE LOGGER_ID = CURRENT_VALUE;
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_407 = FALSE;

-- Test16: Updates a logger with an inexistent level.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test16: Updates a logger with an inexistent level');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test16', 0, 0));
UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
  SET LEVEL_ID = -1
  WHERE LOGGER_ID = CURRENT_VALUE;
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_530 = FALSE;

-- Test17: Deletes a normal level.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test17: Deletes a normal level');
SELECT LOGGER_ID INTO CURRENT_VALUE FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test17', 0, 0));
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = CURRENT_VALUE;

-- Test18: Tries to delete root logger.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test18: Tries to delete root logger');
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID = 0;
IF (RAISED_LG003 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG003 = FALSE;

-- Test19: Delete all loggers except root.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test19: Delete all loggers except root');
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test19', 0, 0);
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID <> 0;

-- Test20: Tries to delete all loggers.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test20: Tries to delete all loggers');
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
IF (RAISED_LG003 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Exception not raised');
END IF;
SET RAISED_LG003 = FALSE;

-- Test21: Updates root logger when it is the only existing to other id.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('Test21: Updates root logger when it is the only existing to other id');
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID) VALUES
  ('test21', 0, 0);
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  WHERE LOGGER_ID <> 0;
-- Compilation error.
--UPDATE LOGDATA.CONF_LOGGERS_EFFECTIVE
--  SET LOGGER_ID = 1
--  WHERE LOGGER_ID = 0;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (MESSAGE) VALUES ('TestsUndeletable: Finished succesfully');

END @