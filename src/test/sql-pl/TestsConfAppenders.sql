--#SET TERMINATOR @

/*
Copyright (c) 2012 - 2014, Andres Gomez Casanova (AngocA)
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * Tests for the conf_appenders table.
 */

SET CURRENT SCHEMA LOGGER_1B @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE RAISED_407 BOOLEAN; -- Not null.
DECLARE RAISED_530 BOOLEAN; -- Foreign key.
DECLARE RAISED_798 BOOLEAN; -- Generated key.
DECLARE ID ANCHOR LOGDATA.CONF_APPENDERS.REF_ID;
DECLARE STMT VARCHAR(256);
DECLARE PREP STATEMENT;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_407 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23503'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_530 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '428C9'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_798 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfAppenders: Preparing environment');
SET RAISED_407 = FALSE;
SET RAISED_530 = FALSE;
SET RAISED_798 = FALSE;
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test1', 1, '%m'));
DELETE FROM LOGDATA.CONF_APPENDERS;

-- Test1: Inserts a normal appender_ref configuration.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test1: Inserts a normal appender_ref configuration');
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test1', 1, '%m');
COMMIT;

-- Test2: Inserts an appender_ref with null appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test2: Inserts an appender_ref with null appender_id');
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test2', NULL, '%m');
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test3: Inserts an appender_ref with inexistent appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test3: Inserts an appender_ref with inexistent appender_id');
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test3', 0, '%m');
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23503');
END IF;
SET RAISED_530 = FALSE;
COMMIT;

-- Test4: Inserts an appender_ref with id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test4: Inserts an appender_ref with id');
SET STMT = 'INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES (1, ''test4'', 1, ''%m'')';
PREPARE PREP FROM STMT;
IF (RAISED_798 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 428C9');
END IF;
SET RAISED_798 = FALSE;
COMMIT;

-- Test5: Inserts an appender_ref with negative id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test5: Inserts an appender_ref with negative id');
SET STMT = 'INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES (-1, ''test4'', 1, ''%m'')';
PREPARE PREP FROM STMT;
IF (RAISED_798 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 428C9');
END IF;
SET RAISED_798 = FALSE;
COMMIT;

-- Test6: Inserts an appender_ref with null id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test6: Inserts an appender_ref with null id');
SET STMT = 'INSERT INTO LOGDATA.CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, PATTERN) VALUES (NULL, ''test6'', 1, ''%m'')';
PREPARE PREP FROM STMT;
IF (RAISED_798 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 428C9');
END IF;
SET RAISED_798 = FALSE;
COMMIT;

-- Test7: Updates an appender_ref with null appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test7: Updates an appender_ref with null appender_id');
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test7', 1, '%m'));
UPDATE LOGDATA.CONF_APPENDERS
  SET APPENDER_ID = NULL
  WHERE REF_ID = ID;
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test8: Updates an appender with inexistant appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test8: Updates an appender_ref with inexistant appender_id');
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test8', 1, '%m'));
UPDATE LOGDATA.CONF_APPENDERS
  SET APPENDER_ID = 0
  WHERE REF_ID = ID;
IF (RAISED_530 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23503');
END IF;
SET RAISED_530 = FALSE;
COMMIT;

-- Test9: Updates an appender_ref with negative id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test9: Updates an appender_ref with negative id');
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test9', 1, '%m'));
SET STMT = 'UPDATE LOGDATA.CONF_APPENDERS SET REF_ID = -1 WHERE REF_ID = ' || ID;
PREPARE PREP FROM STMT;
IF (RAISED_798 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 428C9');
END IF;
SET RAISED_798 = FALSE;
COMMIT;

-- Test10: Updates an appender_ref with null id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Updates an appender_ref with null id');
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test10', 1, '%m'));
SET STMT = 'UPDATE LOGDATA.CONF_APPENDERS SET REF_ID = NULL WHERE REF_ID = ' || ID;
PREPARE PREP FROM STMT;
IF (RAISED_798 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 428C9');
END IF;
SET RAISED_798 = FALSE;
COMMIT;

-- Test11: Updates an appender_ref normally.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Updates an appender_ref normally');
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION, PATTERN) VALUES
  ('test11', 1, NULL, '%m'));
UPDATE LOGDATA.CONF_APPENDERS
  SET NAME = 'TEST10', PATTERN = ' --%m-- ', CONFIGURATION = 'NOTHING'
  WHERE REF_ID = ID;
COMMIT;

-- Test12: Deletes an appender.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test12: Deletes an appender');
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test12', 1, '%m'));
DELETE FROM LOGDATA.CONF_APPENDERS
  WHERE REF_ID = ID;
COMMIT;

-- Test13: Deletes all appenders.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test13: Deletes all appenders');
SELECT REF_ID INTO ID FROM FINAL TABLE (
  INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN) VALUES
  ('test13', 1, '%m'));
DELETE FROM LOGDATA.CONF_APPENDERS;
COMMIT;

-- Test14: Inserts a normal appender_ref configuration with a level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test14: Inserts a normal appender_ref configuration with a level');
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  ('test1', 1, '%m', 2);
COMMIT;

-- Test15: Inserts a normal appender_ref configuration with a null level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test15: Inserts a normal appender_ref configuration with a null level');
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, PATTERN, LEVEL_ID) VALUES
  ('test1', 1, '%m', null);
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfAppenders: Cleaning environment');
DELETE FROM LOGDATA.CONF_APPENDERS;
INSERT INTO LOGDATA.CONF_APPENDERS (NAME, APPENDER_ID, CONFIGURATION,
  PATTERN)
  VALUES ('DB2 Tables', 1, NULL, '[%p] %c - %m');
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfAppenders: Finished succesfully');

END @

