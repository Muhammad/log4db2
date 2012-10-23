--#SET TERMINATOR @

/**
 * Tests for the Get Defined Parent Logger table.
 */

SET CURRENT SCHEMA LOGGER_1A @

!db2 connect to log4db2 > NUL@
!db2 -tf CleanTriggers.sql +o@

BEGIN
-- Reserved names for errors.
DECLARE SQLCODE INTEGER DEFAULT 0;
DECLARE SQLSTATE CHAR(5) DEFAULT '00000';

DECLARE RAISED_LG0F1 BOOLEAN DEFAULT FALSE; -- Invalid parameter.
DECLARE ACTUAL ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;
DECLARE EXPECTED ANCHOR DATA TYPE TO LOGDATA.LEVELS.LEVEL_ID;

-- Controlled SQL State.
DECLARE CONTINUE HANDLER FOR SQLSTATE 'LG0F1'
  BEGIN
   INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, 'SQLState ' || SQLSTATE);
   SET RAISED_LG0F1 = TRUE;
  END;

-- For any other SQL State.
DECLARE CONTINUE HANDLER FOR SQLWARNING
  INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 4, 'Warning SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
  INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 4, 'Exception SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);
DECLARE CONTINUE HANDLER FOR NOT FOUND
  INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, 'Not found SQLCode ' || SQLCODE || '-SQLState ' || SQLSTATE);

-- Prepares the environment.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'TestsFunctionGetDefinedParentLoggeer: Preparing environment');
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'WARN'
  WHERE KEY = 'defaultRootLevel';
UPDATE LOGDATA.CONFIGURATION
  SET VALUE = 'false'
  WHERE KEY = 'internalCache';
COMMIT;

-- Test1: Get default ROOT level.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test1: Get Defined parent logger');
SET EXPECTED = 3;
DELETE FROM LOGDATA.CONF_LOGGERS;
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(0);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test2: Get defined ROOT level.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test2: Get defined ROOT level');
SET EXPECTED = 2;
DELETE FROM LOGDATA.CONF_LOGGERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(0);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test3: Get defined ROOT level when there are other levels.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test3: Get defined ROOT level when there are other levels.');
SET EXPECTED = 0;
DELETE FROM LOGDATA.CONF_LOGGERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 1);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 2);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 3);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(0);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test4: Get defined level for root's son.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test4: Get defined level for root''s son.');
SET EXPECTED = 5;
DELETE FROM LOGDATA.CONF_LOGGERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 1);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 2);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 3);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(1);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test5: Get defined level for root's son with descendency.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test5: Get defined level for root''s son with descendency.');
SET EXPECTED = 4;
DELETE FROM LOGDATA.CONF_LOGGERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 1);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 2);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 3);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(2);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test6: Get defined level for second level.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test6: Get defined level for second level.');
SET EXPECTED = 3;
DELETE FROM LOGDATA.CONF_LOGGERS;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 2);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 3);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test7: Get level when nothing defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test7: Get level when nothing defined.');
SET EXPECTED = 3; -- Default
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(1);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test8: Get 2o. level when nothing defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test8: Get 2o. level when nothing defined.');
SET EXPECTED = 3; -- Default
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test9: Get ROOT level when root defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test9: Get ROOT level when root defined.');
SET EXPECTED = 5;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(0);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test10: Get first level when root defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test10: Get first level when root defined.');
SET EXPECTED = 5;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(1);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test11: Get second level when root defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test11: Get second level when root defined.');
SET EXPECTED = 5;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test12: Get first level when defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test12: Get first level when defined.');
SET EXPECTED = 4;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 4);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(1);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test13: Get second level when defined parent.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test13: Get second level when defined parent.');
SET EXPECTED = 4;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test14: Get second level when defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test14: Get second level when defined.');
SET EXPECTED = 4;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 5);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 3);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 1, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test15: Get third level when nothing defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test15: Get third level when nothing defined.');
SET EXPECTED = 3; -- Default.
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 1, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 2, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test16: Get third level when root defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test16: Get third level when root defined.');
SET EXPECTED = 4;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 1, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 2, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test17: Get third level when first defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test17: Get third level when first defined.');
SET EXPECTED = 3;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 4);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 1, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 2, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test18: Get third level when second defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test18: Get third level when second defined.');
SET EXPECTED = 2;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 4);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 3);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 1, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 1, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 2, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test19: Get third level when all defined.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test19: Get third level when all defined.');
SET EXPECTED = 1;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 4);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 3);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 1, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 2, 1);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (1, 'foo', 0, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (2, 'toto', 1, 0);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (3, 'bar', 2, 0);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(3);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test20: Get first level when new.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test20: Get first level when new.');
SET EXPECTED = 2;
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, EXPECTED);
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(1);
IF (EXPECTED <> ACTUAL) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Different Parent logger ' || EXPECTED || ' - ' || ACTUAL);
END IF;
COMMIT;

-- Test21: Get null.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test21: Get null.');
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(NULL);
IF (RAISED_LG0F1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, 'Exception raised LG0F1');
END IF;
SET RAISED_LG0F1 = FALSE;
COMMIT;

-- Test22: Get negative.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'Test22: Get negative.');
SET ACTUAL = LOGADMIN.GET_DEFINED_PARENT_LOGGER(-1);
IF (RAISED_LG0F1 = FALSE) THEN
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 2, 'Exception not raised');
ELSE
 INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 5, 'Exception raised LG0F1');
END IF;
SET RAISED_LG0F1 = FALSE;
COMMIT;

-- Cleans the environment.
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'TestsFunctionGetDefinedParentLoggeer: Cleaning environment');
DELETE FROM LOGDATA.CONF_LOGGERS;
DELETE FROM LOGDATA.CONF_LOGGERS_EFFECTIVE;
INSERT INTO LOGDATA.CONF_LOGGERS_EFFECTIVE (LOGGER_ID, NAME, PARENT_ID,
  LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 3);
COMMIT;
INSERT INTO LOGDATA.LOGS (DATE, LEVEL_ID, MESSAGE) VALUES (GENERATE_UNIQUE(), 3, 'TestsFunctionGetDefinedParentLoggeer: Finished succesfully');

END @

!db2 connect to log4db2 > NUL@
!db2 -tf Trigger.sql +o@

SELECT *
  FROM LOGDATA.CONF_LOGGERS_EFFECTIVE
  ORDER BY LOGGER_ID @