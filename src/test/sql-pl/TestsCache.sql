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
 * Tests for the logger cache functionality.
 */

SET CURRENT SCHEMA LOGGER_1B @

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE RAISED_LG0A1 BOOLEAN; -- For a controlled error.
DECLARE RAISED_407 BOOLEAN; -- Not null.
DECLARE MY_KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
DECLARE EXPECTED_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
DECLARE ACTUAL_VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0A1'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (1, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0A1 = TRUE;
  END;
DECLARE CONTINUE HANDLER FOR SQLSTATE '23502'
  BEGIN
   INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (1, 'SQLState ' || SQLSTATE);
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
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (4, 'TestsCache: Preparing environment');
DELETE FROM LOGDATA.CONFIGURATION;
CALL LOGGER.DEACTIVATE_CACHE();
COMMIT;

-- Test01: Get value from cache - Active cache.
-- A-I---
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test01: Get value from cache - Active cache');
SET MY_KEY = 'Test01';
SET EXPECTED_VALUE = 'Val01';
CALL LOGGER.ACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, EXPECTED_VALUE);
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test02: Get value from cache - Active cache + refresh.
-- A-IR--
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test02: Get value from cache - Active cache + refresh');
SET MY_KEY = 'Test02';
SET EXPECTED_VALUE = 'Val02';
CALL LOGGER.ACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, EXPECTED_VALUE);
CALL LOGGER.REFRESH_CONF();
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test03: Get new value from cache - Active cache.
-- A-I-U-
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test03: Get new value from cache - Active cache');
SET MY_KEY = 'Test03';
SET EXPECTED_VALUE = 'NewValue';
CALL LOGGER.ACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'Val03');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = MY_KEY;
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test04: Get new value from cache - Active cache + refresh.
-- A-I-UR
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test04: Get new value from cache - Active cache + refresh');
SET MY_KEY = 'Test04';
SET EXPECTED_VALUE = 'NewValue';
CALL LOGGER.ACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'Val04');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = MY_KEY;
CALL LOGGER.REFRESH_CONF();
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test05: Get old value from cache - Active cache + refresh.
-- A-IRU-
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test05: Get old value from cache - Active cache + refresh');
SET MY_KEY = 'Test05';
SET EXPECTED_VALUE = 'Val05';
CALL LOGGER.ACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, EXPECTED_VALUE);
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'NewValue'
  WHERE KEY = MY_KEY;
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test06: Get new value from cache - Active cache.
-- ARI---
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test06: Get new value from cache - Active cache');
SET MY_KEY = 'Test06';
SET EXPECTED_VALUE = 'Val06';
CALL LOGGER.ACTIVATE_CACHE();
CALL LOGGER.REFRESH_CONF();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, EXPECTED_VALUE);
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test07: Get null from cache - Active cache.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test07: Get null from cache - Active cache');
SET MY_KEY = 'Test07';
SET EXPECTED_VALUE = NULL;
CALL LOGGER.ACTIVATE_CACHE();
CALL LOGGER.REFRESH_CONF();
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test08: Get new value - Deactive cache.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test08: Get new vale - Deactive cache');
SET MY_KEY = 'Test08';
SET EXPECTED_VALUE = 'Val08';
CALL LOGGER.DEACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = MY_KEY;
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test09: Get new value, refresh - Deactive cache.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test09: Get new vale, refresh - Deactive cache');
SET MY_KEY = 'Test09';
SET EXPECTED_VALUE = 'Val09';
CALL LOGGER.DEACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = MY_KEY;
CALL LOGGER.REFRESH_CONF();
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test10: Get null - Deactive cache.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test10: Get null - Deactive cache');
SET MY_KEY = 'Test10';
SET EXPECTED_VALUE = NULL;
CALL LOGGER.DEACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = MY_KEY;
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test11: Get null, refresh - Deactive cache.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test11: Get null, refresh - Deactive cache');
SET MY_KEY = 'Test11';
SET EXPECTED_VALUE = NULL;
CALL LOGGER.DEACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = MY_KEY;
CALL LOGGER.REFRESH_CONF();
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;

-- Test12: Get null, refresh - Deactive cache.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'Test12: Get null, refresh - Deactive cache');
SET MY_KEY = 'Test11';
SET EXPECTED_VALUE = NULL;
CALL LOGGER.DEACTIVATE_CACHE();
INSERT INTO LOGDATA.CONFIGURATION VALUES (MY_KEY, 'OldValue');
CALL LOGGER.REFRESH_CONF();
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = EXPECTED_VALUE
  WHERE KEY = MY_KEY;
SET ACTUAL_VALUE = LOGGER.GET_VALUE(MY_KEY);
IF (EXPECTED_VALUE <> ACTUAL_VALUE) THEN
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, 'Different VALUE');
 INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (2, EXPECTED_VALUE || ' - ' || ACTUAL_VALUE);
END IF;
DELETE FROM LOGDATA.CONFIGURATION
  WHERE KEY = MY_KEY;
COMMIT;
-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCache: Cleaning environment');
INSERT INTO LOGDATA.CONFIGURATION (KEY, VALUE)
  VALUES ('defaultRootLevelId', '3'),
         ('internalCache', 'true'),
         ('logInternals', 'false'),
         ('secondsToRefresh', '30'),
         ('checkHierarchy', 'false'),
         ('checkLevels', 'false');
INSERT INTO LOGDATA.LOGS (LEVEL_ID, MESSAGE) VALUES (3, 'TestsCache: Finished succesfully');
COMMIT;

END @

