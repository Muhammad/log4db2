--#SET TERMINATOR ;
SET CURRENT SCHEMA LOGGER;

-- Tablespace for logger utility.
CREATE TABLESPACE LOGGER_SPACE PAGESIZE 4 K;

COMMENT ON TABLESPACE LOGGER_SPACE IS 'All objects for the logger utility';

-- Schema for logger utility's objects.
CREATE SCHEMA LOGGER;

COMMENT ON SCHEMA LOGGER IS 'Schema for log4db2 utility';

-- Table for the global configuration of the logger utility.
CREATE TABLE CONFIGURATION (
  KEY VARCHAR(32) NOT NULL,
  VALUE VARCHAR(256) NULL
  ) IN LOGGER_SPACE;

ALTER TABLE CONFIGURATION ADD CONSTRAINT LOG_CONF_PK PRIMARY KEY (KEY);

COMMENT ON TABLE CONFIGURATION IS 'General configuration for the utility';

COMMENT ON CONFIGURATION (
  KEY IS 'Configuration Id',
  VALUE IS 'Value of the corresponding key'
  );

-- Table for the logger levels.
CREATE TABLE LEVELS (
  LEVEL_ID SMALLINT NOT NULL,
  NAME CHAR(5) NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE LEVELS ADD CONSTRAINT LOG_LEVELS_PK PRIMARY KEY (LEVEL_ID);

COMMENT ON TABLE LEVELS IS 'Possible level for the logger';

COMMENT ON LEVELS (
  LEVEL_ID IS 'Level Id',
  NAME IS 'Level name'
  );

-- Table for loggers configuration.
CREATE TABLE CONF_LOGGERS (
  LOGGER_ID SMALLINT NOT NULL,
  NAME VARCHAR(256) NOT NULL,
  PARENT_ID SMALLINT,
  LEVEL_ID SMALLINT
  ) IN LOGGER_SPACE;

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_PK PRIMARY KEY (LOGGER_ID);

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_FK_LEVELS FOREIGN KEY (LEVEL_ID) REFERENCES LEVELS (LEVEL_ID) ON DELETE CASCADE;

ALTER TABLE CONF_LOGGERS ADD CONSTRAINT LOG_LOGGERS_FK_PARENT FOREIGN KEY (PARENT_ID) REFERENCES CONF_LOGGERS (LOGGER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_LOGGERS IS 'Configuration table for the logger levels';

COMMENT ON CONF_LOGGERS (
  LOGGER_ID IS 'Logger identifier',
  NAME IS 'Hierarchy name to log',
  PARENT_ID IS 'Parent logger id',
  LEVEL_ID IS 'Log level to register (Optional)'
  );

-- Table for the effecetive loggers configuration.
CREATE TABLE CONF_LOGGERS_EFFECTIVE
  LIKE CONF_LOGGERS IN LOGGER_SPACE;

ALTER TABLE CONF_LOGGERS_EFFECTIVE ALTER COLUMN LEVEL_ID SET NOT NULL;

ALTER TABLE CONF_LOGGERS_EFFECTIVE ALTER COLUMN LOGGER_ID SET GENERATED ALWAYS AS IDENTITY (START WITH 0);

CALL SYSPROC.ADMIN_CMD ('REORG TABLE LOGGER.conf_loggers_effective');

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_PK PRIMARY KEY (LOGGER_ID);

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_FK_LEVELS FOREIGN KEY (LEVEL_ID) REFERENCES LEVELS (LEVEL_ID) ON DELETE CASCADE;

ALTER TABLE CONF_LOGGERS_EFFECTIVE ADD CONSTRAINT LOG_LOGGERS_EFF_FK_PARENT FOREIGN KEY (PARENT_ID) REFERENCES CONF_LOGGERS_EFFECTIVE (LOGGER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_LOGGERS_EFFECTIVE IS 'Configuration table for the effective logger levels';

COMMENT ON CONF_LOGGERS_EFFECTIVE (
  LOGGER_ID IS 'Logger identifier',
  NAME IS 'Hierarchy name to log',
  PARENT_ID IS 'Parent logger id',
  LEVEL_ID IS 'Log level to register'
  );

-- Table for the appenders.
CREATE TABLE APPENDERS (
  APPENDER_ID SMALLINT NOT NULL,
  NAME VARCHAR(256) NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE APPENDERS ADD CONSTRAINT LOG_APPEND_PK PRIMARY KEY (APPENDER_ID);

COMMENT ON TABLE APPENDERS IS 'Possible appenders';

COMMENT ON APPENDERS (
  APPENDER_ID IS 'Id of the appender',
  NAME IS 'Name of the appender'
  );

-- Table for the configuration about where to write the logs.
CREATE TABLE CONF_APPENDERS (
  REF_ID SMALLINT NOT NULL,
  NAME CHAR(16),
  APPENDER_ID SMALLINT NOT NULL,
  CONFIGURATION VARCHAR(256),
  PATTERN VARCHAR(256) NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE CONF_APPENDERS ADD CONSTRAINT LOG_CONF_APPEND_PK PRIMARY KEY (REF_ID);

ALTER TABLE CONF_APPENDERS ADD CONSTRAINT LOG_CONF_APPEND_FK_APPEND FOREIGN KEY (APPENDER_ID) REFERENCES APPENDERS (APPENDER_ID) ON DELETE CASCADE;

COMMENT ON TABLE CONF_APPENDERS IS 'Configuration about how to write the logs';

COMMENT ON CONF_APPENDERS (
  REF_ID IS 'Id of the configuration appender',
  NAME IS 'Alias of the configuration to write the logs',
  APPENDER_ID IS 'Id of the appender where the logs will be written',
  CONFIGURATION IS 'Configuration of the appender',
  PATTERN IS 'Pattern to write the message in the log'
  );

-- Table for the loggers and appenders association.
-- TODO this table is not necessary
CREATE TABLE REFERENCES (
  LOGGER_ID SMALLINT NOT NULL,
  APPENDER_REF_ID SMALLINT NOT NULL
  ) IN LOGGER_SPACE;

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_PK PRIMARY KEY (LOGGER_ID);

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_FK_CONF_LOGGERS FOREIGN KEY (LOGGER_ID) REFERENCES CONF_LOGGERS (LOGGER_ID) ON DELETE CASCADE;

ALTER TABLE REFERENCES ADD CONSTRAINT LOG_REF_FK_CONF_APPEND FOREIGN KEY (APPENDER_REF_ID) REFERENCES CONF_APPENDERS (REF_ID) ON DELETE CASCADE;

COMMENT ON TABLE REFERENCES IS 'Table that associates the loggers with the appenders';

COMMENT ON REFERENCES (
  LOGGER_ID IS 'Logger that will be written',
  APPENDER_REF_ID IS 'Appender used to write the log'
  );

-- Table for the pure SQL appender.
CREATE TABLE LOGS (
  DATE TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  LEVEL_ID SMALLINT,
  LOGGER_ID SMALLINT,
  MESSAGE VARCHAR(256) NOT NULL
  ) IN LOGGER_SPACE;

COMMENT ON TABLE LOGS IS 'Table where the logs are written';

COMMENT ON LOGS (
  DATE IS 'Date where the event was reported',
  LEVEL_ID IS 'Log level',
  LOGGER_ID IS 'Logger that generated this message',
  MESSAGE IS 'Message logged'
  );

-- Global configuration.
-- checkHierarchy: Checks the logger hierarchy.
-- logInternals: Logs internal messages.
-- checkLevels: Checks the levels definition.
INSERT INTO CONFIGURATION (KEY, VALUE)
  VALUES ('checkHierarchy', 'false'),
         ('logInternals', 'false'),
         ('checkLevels', 'false');

-- Levels of the logger utility.
INSERT INTO LEVELS (LEVEL_ID, NAME)
  VALUES (0, 'off'),
         (1, 'fatal'),
         (2, 'error'),
         (3, 'warn'),
         (4, 'info'),
         (5, 'debug');

-- Root logger.
INSERT INTO CONF_LOGGERS (LOGGER_ID, NAME, PARENT_ID, LEVEL_ID)
  VALUES (0, 'ROOT', NULL, 3);

-- TODO remove this, and create it with a trigger
INSERT INTO CONF_LOGGERS_EFFECTIVE (NAME, PARENT_ID, LEVEL_ID)
  VALUES ('ROOT', NULL, 3);

-- Basic appenders.
INSERT INTO APPENDERS (APPENDER_ID, NAME)
  VALUES (1, 'Pure SQL PL - Tables'),
         (2, 'db2diag.log'),
         (3, 'UTL_FILE'),
         (4, 'DB2 logger'),
         (5, 'Java logger');

-- Configuration for included appender.
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, CONFIGURATION,
  PATTERN)
  VALUES (1, 'DB2 Tables', 1, NULL, '[%p] %c - %m');

-- Module for all code for the logger utility.
CREATE OR REPLACE MODULE LOGGER;

-- Module version.
ALTER MODULE LOGGER PUBLISH
  VARIABLE VERSION VARCHAR(32) CONSTANT '2012-09-30 1.0';

-- Public functions and procedures.
-- Function to register the logger.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE GET_LOGGER (
  IN NAME VARCHAR(256),
  OUT LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID
  )
  LANGUAGE SQL
  DETERMINISTIC -- Returns the same ID for the same logger name.
  NO EXTERNAL ACTION
  MODIFIES SQL DATA;

-- Procedure to retrieve the complete logger name.
ALTER MODULE LOGGER PUBLISH
  FUNCTION GET_LOGGER_NAME (
  IN LOG_ID ANCHOR CONF_LOGGERS.LOGGER_ID
  ) RETURNS VARCHAR(256);

-- Procedure to write logs.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  );

-- Procedure to write logs in debug mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE DEBUG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  );

-- Procedure to write logs in info mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE INFO (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  );

-- Procedure to write logs in warn mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE WARN (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  );

-- Procedure to write logs in error mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE ERROR (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  );

-- Procedure to write logs in fatal mode.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE FATAL (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  );

-- Procedure that shows the used loggers.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE SHOW_LOGGERS ();