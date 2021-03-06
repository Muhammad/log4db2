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
 * Tests for the GetLoggerName function.
 */

SET CURRENT SCHEMA LOGGER_1B @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
DECLARE ACTUAL_RET ANCHOR LOGGER.COMPLETE_LOGGER_NAME;
DECLARE EXPECTED_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE ACTUAL_ID ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID;
DECLARE EXPECTED_MSG ANCHOR LOGDATA.LOGS.MESSAGE;
DECLARE ACTUAL_MSG ANCHOR LOGDATA.LOGS.MESSAGE;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsGetLoggerName: Preparing environment');
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
CALL LOGGER.DEACTIVATE_CACHE();
COMMIT;

-- Test01: Test ID null.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test01: Test ID null');
SET ID = NULL;
SET EXPECTED_RET = '-internal-';
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test02: Test ID -1.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Test ID -1');
SET ID = -1;
SET EXPECTED_RET = '-internal-';
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test03: Test ID -2.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test03: Test ID -2');
SET ID = -2;
SET EXPECTED_RET = '-INVALID-';
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test04: Test ID negative.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test04: Test ID negative');
SET ID = -32765;
SET EXPECTED_RET = '-INVALID-';
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test05: Test ID 0.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test05: Test ID 0');
SET ID = 0;
SET EXPECTED_RET = 'ROOT';
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test06: Test ID inexistant.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test06: Test ID inexistant');
SET ID = 32765;
SET EXPECTED_RET = 'Unknown';
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test07: Test one level.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test07: Test one level');
SET EXPECTED_RET = 'logger1';
CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test08: Test two levels.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test08: Test two levels');
SET EXPECTED_RET = 'logger1.logger2';
CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test09: Test three levels.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test09: Test three levels');
SET EXPECTED_RET = 'logger1.logger2.logger3';
CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
COMMIT;

-- Test10: Test 60 levels.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Test 60 levels');
SET EXPECTED_RET = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8'
  || '.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0';
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
CALL LOGGER.DEACTIVATE_CACHE();
CALL LOGGER.GET_LOGGER(EXPECTED_RET, ID);
SET ACTUAL_RET = LOGGER.GET_LOGGER_NAME(ID);
IF (EXPECTED_RET <> ACTUAL_RET) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_RET || ' ACTUAL ' || COALESCE(ACTUAL_RET,'NULL'));
END IF;
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
COMMIT;

-- Test11: Test 61 levels.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Test 61 levels');
SET EXPECTED_ID = 0;
SET EXPECTED_RET = '1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8'
  || '.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1.2.3.4.5.6.7.8.9.0.1';
SET EXPECTED_MSG = 'LG001. Cascade call limit achieved, for GET_LOGGER: '
  || EXPECTED_RET;
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
CALL LOGGER.DEACTIVATE_CACHE();
CALL LOGGER.GET_LOGGER(EXPECTED_RET, ACTUAL_ID);
IF (EXPECTED_ID <> ACTUAL_ID) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Error in test ' || COALESCE(ID, 'NULL'));
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'EXPECTED ' || EXPECTED_ID || ' ACTUAL ' || COALESCE(ACTUAL_ID,'NULL'));
END IF;
SELECT MESSAGE INTO ACTUAL_MSG
  FROM LOGS
  WHERE DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
IF (EXPECTED_MSG <> ACTUAL_MSG) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different msg');
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'expected ' || COALESCE(EXPECTED_MSG, 'empty') || ' actual ' || COALESCE(ACTUAL_MSG, 'empty'));
END IF;
DELETE FROM LOGDATA.LOGS
  WHERE MESSAGE = EXPECTED_MSG
  AND DATE = (SELECT MAX(DATE) FROM LOGDATA.LOGS);
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsGetLoggerName: Cleaning environment');
DELETE FROM LOGDATA.CONF_LOGGERS
  WHERE LOGGER_ID <> 0;
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsGetLoggerName: Finished succesfully');
COMMIT;

END @

