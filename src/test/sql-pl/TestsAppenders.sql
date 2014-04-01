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
 * Tests for the appenders table.
 */

SET CURRENT SCHEMA LOGGER_1B @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE RAISED_LG0A1 BOOLEAN; -- For a controlled error.
DECLARE RAISED_407 BOOLEAN; -- Not null.

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0A1'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0A1 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_407 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsAppenders: Preparing environment');
SET RAISED_LG0A1 = FALSE;
SET RAISED_407 = FALSE;
DELETE FROM LOGDATA.APPENDERS;
COMMIT;

-- Test1: Inserts a normal appender configuration.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test1: Inserts a normal appender configuration');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (1, 'test1');
COMMIT;

-- Test2: Inserts an appender with null appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test2: Inserts an appender with null appender_id');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (NULL, 'test2');
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test3: Inserts an appender with negative appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test3: Inserts an appender with negative appender_id');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (-1, 'test3');
IF (RAISED_LG0A1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0A1');
END IF;
SET RAISED_LG0A1 = FALSE;
COMMIT;

-- Test4: Updates an appender with null appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test4: Updates an appender with null appender_id');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (4, 'test4');
UPDATE LOGDATA.APPENDERS
  SET APPENDER_ID = NULL
  WHERE APPENDER_ID = 4;
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test5: Updates an appender with negative appender_id.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test5: Updates an appender with negative appender_id');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (5, 'test5');
UPDATE LOGDATA.APPENDERS
  SET APPENDER_ID = -1
  WHERE APPENDER_ID = 5;
IF (RAISED_LG0A1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised LG0A1');
END IF;
SET RAISED_LG0A1 = FALSE;
COMMIT;

-- Test6: Updates an appender normally.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test6: Updates an appender normally');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (6, 'test6');
UPDATE LOGDATA.APPENDERS
  SET APPENDER_ID = 7
  WHERE APPENDER_ID = 6;
COMMIT;

-- Test7: Deletes an appender normally.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test7: Deletes an appender normally');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (7, 'test7');
DELETE FROM LOGDATA.APPENDERS
  WHERE APPENDER_ID = 7;
COMMIT;

-- Test8: Deletes all appenders.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test8: Deletes all appenders');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME) VALUES
  (8, 'test8');
DELETE FROM LOGDATA.APPENDERS;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsAppenders: Cleaning environment');
DELETE FROM LOGDATA.APPENDERS;
INSERT INTO LOGDATA.APPENDERS (APPENDER_ID, NAME)
  VALUES (1, 'Tables'),
         (2, 'db2diag.log'),
         (3, 'UTL_FILE'),
         (4, 'DB2LOGGER'),
         (5, 'Java logger');
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsAppenders: Finished succesfully');
COMMIT;

END @

