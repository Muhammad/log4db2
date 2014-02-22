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
 * Tests for the configuration table.
 */

SET CURRENT SCHEMA LOGGER_1B @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '0000';

DECLARE RAISED_407 BOOLEAN DEFAULT FALSE; -- Null value.
DECLARE RAISED_803 BOOLEAN DEFAULT FALSE; -- Duplicated key.
DECLARE ACTUAL_KEY ANCHOR DATA TYPE TO LOGDATA.CONFIGURATION.KEY;
DECLARE ACTUAL_VALUE ANCHOR DATA TYPE TO LOGDATA.CONFIGURATION.KEY;
DECLARE EXPECTED_KEY ANCHOR DATA TYPE TO LOGDATA.CONFIGURATION.VALUE;
DECLARE EXPECTED_VALUE ANCHOR DATA TYPE TO LOGDATA.CONFIGURATION.VALUE;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_407 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23505'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'SQLState ' || SQLSTATE);
   SET RAISED_803 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsConfiguration: Preparing environment');
SET RAISED_407 = FALSE;
SET RAISED_803 = FALSE;
DELETE FROM LOGDATA.CONFIGURATION;
COMMIT;

-- Test1: Inserts a normal key/value.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test1: Inserts a normal key/value');
SET EXPECTED_KEY = 'test1';
SET EXPECTED_VALUE = 'val1';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, EXPECTED_VALUE);
SELECT KEY, VALUE INTO ACTUAL_KEY, ACTUAL_VALUE
  FROM LOGDATA.CONFIGURATION;
IF (EXPECTED_KEY <> ACTUAL_KEY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different KEY ' || EXPECTED_KEY || ' - ' || ACTUAL_KEY);
END IF;
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE ' || EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
COMMIT;

-- Test2: Inserts a key/value with null key.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test2: Inserts a key/value with null key');
SET EXPECTED_KEY = NULL;
SET EXPECTED_VALUE = 'val2';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, EXPECTED_VALUE);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test3: Inserts a key/value with null value.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test3: Inserts a key/value with null value');
SET EXPECTED_KEY = 'test3';
SET EXPECTED_VALUE = NULL;
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, EXPECTED_VALUE);
SELECT KEY, VALUE INTO ACTUAL_KEY, ACTUAL_VALUE
  FROM LOGDATA.CONFIGURATION;
IF (EXPECTED_KEY <> ACTUAL_KEY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different KEY ' || EXPECTED_KEY || ' - ' || ACTUAL_KEY);
END IF;
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE ' || EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
COMMIT;

-- Test4: Inserts a key/value with all null.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test4: Inserts a key/value with all null');
SET EXPECTED_KEY = NULL;
SET EXPECTED_VALUE = NULL;
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, EXPECTED_VALUE);
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test5: Inserts a duplicated key/value.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test5: Inserts a duplicated key/value');
SET EXPECTED_KEY = 'test5';
SET EXPECTED_VALUE = 'val5';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, EXPECTED_VALUE);
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, EXPECTED_VALUE);
IF (RAISED_803 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23505');
END IF;
SET RAISED_803= FALSE;
COMMIT;

-- Test6: Updates to a normal key/value.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test6: Updates to a normal key/value');
SET EXPECTED_KEY = 'test6';
SET EXPECTED_VALUE = 'val6u';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, 'val6');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = EXPECTED_KEY;
SELECT KEY, VALUE INTO ACTUAL_KEY, ACTUAL_VALUE
  FROM LOGDATA.CONFIGURATION;
IF (EXPECTED_KEY <> ACTUAL_KEY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different KEY ' || EXPECTED_KEY || ' - ' || ACTUAL_KEY);
END IF;
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE ' || EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
COMMIT;

-- Test7: Updates to a normal key/value to null value.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test7: Updates to a normal key/value to null value');
SET EXPECTED_KEY = 'test7';
SET EXPECTED_VALUE = NULL;
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, 'val7');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = EXPECTED_KEY;
SELECT KEY, VALUE INTO ACTUAL_KEY, ACTUAL_VALUE
  FROM LOGDATA.CONFIGURATION;
IF (EXPECTED_KEY <> ACTUAL_KEY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different KEY ' || EXPECTED_KEY || ' - ' || ACTUAL_KEY);
END IF;
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE ' || EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
COMMIT;

-- Test8: Updates to a normal key/value to null key.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test8: Updates to a normal key/value to null key');
SET EXPECTED_KEY = NULL;
SET EXPECTED_VALUE = 'val8';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES ('key8', EXPECTED_VALUE);
UPDATE LOGDATA.CONFIGURATION
  SET KEY = EXPECTED_KEY
  WHERE VALUE = EXPECTED_VALUE;
IF (RAISED_407 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23502');
END IF;
SET RAISED_407 = FALSE;
COMMIT;

-- Test9: Updates to a duplicated key/value.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test9: Updates to a duplicated key/value');
SET EXPECTED_KEY = 'test9b';
SET EXPECTED_VALUE = 'val9';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES ('test9a', EXPECTED_VALUE);
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (EXPECTED_KEY, EXPECTED_VALUE);
UPDATE LOGDATA.CONFIGURATION
  SET KEY = EXPECTED_KEY
  WHERE KEY = 'test9a';
IF (RAISED_803 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Exception raised 23505');
END IF;
SET RAISED_803= FALSE;
COMMIT;

-- Test10: Deletes a key/value.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Deletes a key/value');
SET EXPECTED_KEY = NULL;
SET EXPECTED_VALUE = NULL;
SET ACTUAL_KEY = 'test10';
SET ACTUAL_VALUE = 'val10';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (ACTUAL_KEY, ACTUAL_VALUE);
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = ACTUAL_KEY;
SELECT KEY, VALUE INTO ACTUAL_KEY, ACTUAL_VALUE
  FROM LOGDATA.CONFIGURATION;
IF (EXPECTED_KEY <> ACTUAL_KEY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different KEY ' || EXPECTED_KEY || ' - ' || ACTUAL_KEY);
END IF;
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE ' || EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
COMMIT;

-- Test11: Deletes all.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Deletes all');
SET EXPECTED_KEY = NULL;
SET EXPECTED_VALUE = NULL;
SET ACTUAL_KEY = 'test11';
SET ACTUAL_VALUE = 'val11';
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE) VALUES (ACTUAL_KEY, ACTUAL_VALUE);
DELETE FROM LOGDATA.CONFIGURATION;
SELECT KEY, VALUE INTO ACTUAL_KEY, ACTUAL_VALUE
  FROM LOGDATA.CONFIGURATION;
IF (EXPECTED_KEY <> ACTUAL_KEY) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different KEY ' || EXPECTED_KEY || ' - ' || ACTUAL_KEY);
END IF;
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE ' || EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfiguration: Cleaning environment');
DELETE FROM LOGDATA.CONFIGURATION;
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
  VALUES ('checkHierarchy', 'false'),
         ('checkLevels', 'false'),
         ('defaultRootLevelId', '3'),
         ('internalCache', 'true'),
         ('logInternals', 'false'),
         ('secondsToRefresh', '30');
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsConfiguration: Finished succesfully');
COMMIT;

END @

SELECT VARCHAR(KEY, 32) KEY, VARCHAR(VALUE, 32) VALUE
  FROM LOGDATA.CONFIGURATION @

