SET CURRENT SCHEMA LOGGER;

-- Drops all objects.
DROP MODULE LOGGER;

DROP TABLE logs;
DROP TABLE references;
DROP TABLE conf_appenders;
DROP TABLE appenders;
DROP TABLE conf_loggers_effective;
DROP TABLE conf_loggers;
DROP TABLE levels;
DROP TABLE configuration;
DROP SCHEMA LOGGER RESTRICT;
DROP TABLESPACE logger_space;

-- Tablespace for logger utility.
CREATE TABLESPACE logger_space PAGESIZE 4 K;
COMMENT ON TABLESPACE logger_space IS 'All objects for the logger utility';

-- Schema for logger utility's objects.
CREATE SCHEMA LOGGER;
COMMENT ON SCHEMA LOGGER IS 'Schema for log4db2 utility';

-- Table for the global configuration of the logger utility.
CREATE TABLE configuration (
  key VARCHAR(32) NOT NULL,
  value VARCHAR(256) NULL
  ) IN logger_space;
ALTER TABLE configuration ADD CONSTRAINT log_conf_pk PRIMARY KEY (key);
COMMENT ON TABLE configuration IS 'General configuration for the utility';
COMMENT ON configuration (
  key IS 'Configuration Id',
  value IS 'Value of the corresponding key'
  );

-- Table for the logger levels.
CREATE TABLE levels (
  level_id SMALLINT NOT NULL,
  name CHAR(5) NOT NULL
  ) IN logger_space;
ALTER TABLE levels ADD CONSTRAINT log_levels_pk PRIMARY KEY (level_id);
COMMENT ON TABLE levels IS 'Possible level for the logger';
COMMENT ON levels (
  level_id IS 'Level Id',
  name IS 'Level name'
  );

-- Table for loggers configuration.
CREATE TABLE conf_loggers (
  logger_id SMALLINT NOT NULL,
  name VARCHAR(256) NOT NULL,
  parent_id SMALLINT,
  level_id SMALLINT
  ) IN logger_space;
ALTER TABLE conf_loggers ADD CONSTRAINT log_loggers_pk PRIMARY KEY (logger_id);
ALTER TABLE conf_loggers ADD CONSTRAINT log_loggers_fk_levels FOREIGN KEY (level_id) REFERENCES levels (level_id) ON DELETE CASCADE;
COMMENT ON TABLE conf_loggers IS 'Configuration table for the logger levels';
COMMENT ON conf_loggers (
  logger_Id IS 'Logger identifier',
  name IS 'Hierarchy name to log',
  parent_id IS 'Parent logger id',
  level_id IS 'Log level to register (Optional)'
  );

-- Table for the effecetive loggers configuration.
CREATE TABLE conf_loggers_effective
  LIKE conf_loggers IN logger_space;
ALTER TABLE conf_loggers_effective ALTER COLUMN level_id SET NOT NULL;
ALTER TABLE conf_loggers_effective ALTER COLUMN logger_id set GENERATED ALWAYS AS IDENTITY (START WITH 0);
CALL SYSPROC.ADMIN_CMD ('REORG TABLE LOGGER.conf_loggers_effective');
ALTER TABLE conf_loggers_effective ADD CONSTRAINT log_loggers_eff_pk PRIMARY KEY (logger_id);
ALTER TABLE conf_loggers_effective ADD CONSTRAINT log_loggers_eff_fk_levels FOREIGN KEY (level_id) REFERENCES levels (level_id) ON DELETE CASCADE;
COMMENT ON TABLE conf_loggers_effective IS 'Configuration table for the effective logger levels';
COMMENT ON conf_loggers_effective (
  logger_Id IS 'Logger identifier',
  name IS 'Hierarchy name to log',
  parent_id IS 'Parent logger id',
  level_id IS 'Log level to register'
  );

-- Table for the appenders.
CREATE TABLE appenders (
  appender_id SMALLINT NOT NULL,
  name VARCHAR(256) NOT NULL
  ) IN logger_space;
ALTER TABLE appenders ADD CONSTRAINT log_append_pk PRIMARY KEY (appender_id);
COMMENT ON TABLE appenders IS 'Possible appenders';
COMMENT ON appenders (
  appender_id IS 'Id of the appender',
  name IS 'Name of the appender'
  );

-- Table for the configuration about where to write the logs.
CREATE TABLE conf_appenders (
  ref_id SMALLINT NOT NULL,
  name CHAR(16),
  appender_id SMALLINT NOT NULL,
  configuration VARCHAR(256)
  --pattern VARCHAR(256)
  ) IN logger_space;
ALTER TABLE conf_appenders ADD CONSTRAINT log_conf_append_pk PRIMARY KEY (ref_id);
ALTER TABLE conf_appenders ADD CONSTRAINT log_conf_append_fk_append FOREIGN KEY (appender_id) REFERENCES appenders (appender_id) ON DELETE CASCADE;
COMMENT ON TABLE conf_appenders IS 'Configuration about how to write the logs';
COMMENT ON conf_appenders (
  ref_id IS 'Id of the configuration appender',
  name IS 'Alias of the configuration to write the logs',
  appender_id IS 'Id of the appender where the logs will be written',
  configuration IS 'Configuration of the appender'
  --pattern IS 'Pattern to write the message in the log'
  );

-- Table for the loggers and appenders association.
-- TODO this table is not necessary
CREATE TABLE references (
  logger_id SMALLINT NOT NULL,
  appender_ref_id SMALLINT NOT NULL
  ) IN logger_space;
ALTER TABLE references ADD CONSTRAINT log_ref_pk PRIMARY KEY (logger_id);
ALTER TABLE references ADD CONSTRAINT log_ref_fk_conf_loggers FOREIGN KEY (logger_id) REFERENCES conf_loggers (logger_id) ON DELETE CASCADE;
ALTER TABLE references ADD CONSTRAINT log_ref_fk_conf_append FOREIGN KEY (appender_ref_id) REFERENCES conf_appenders (ref_id) ON DELETE CASCADE;
COMMENT ON TABLE references IS 'Table that associates the loggers with the appenders';
COMMENT ON references (
  logger_id IS 'Logger that will be written',
  appender_ref_id IS 'Appender used to write the log'
  );

-- Table for the pure SQL appender.
CREATE TABLE LOGS (
  date TIMESTAMP NOT NULL,
  level_id SMALLINT NOT NULL,
  logger_id SMALLINT NOT NULL,
  environment VARCHAR(32) NOT NULL,
  message VARCHAR(256) NOT NULL
  ) IN logger_space;
COMMENT ON TABLE logs IS 'Table where the logs are written';
COMMENT ON logs (
  date IS 'Date where the event was reported',
  level_id IS 'Log level',
  logger_id IS 'Logger that generated this message',
  environment IS 'Process or agent name that called the logger',
  message IS 'Message logged'
  );

-- Global configuration.
INSERT INTO configuration (key, value) VALUES
  ('checkHierarchy', 'false'),
  ('checkLevels', 'false');

-- Levels of the logger utility.
INSERT INTO levels (level_id, name) VALUES
  (0, 'off'),
  (1, 'fatal'),
  (2, 'error'),
  (3, 'warn'),
  (4, 'info'),
  (5, 'debug');

-- Root logger.
INSERT INTO conf_loggers (logger_id, name, parent_id, level_id) VALUES
  (0, 'ROOT', NULL, 3);
-- TODO remove this, and create it with a trigger
INSERT INTO conf_loggers_effective (name, parent_id, level_id) VALUES
  ('ROOT', NULL, 3);

-- Basic appenders.
INSERT INTO appenders (appender_id, name) VALUES
  (1, 'Pure SQL PL - Tables'),
  (2, 'db2diag.log'),
  (3, 'UTL_FILE'),
  (4, 'DB2 logger'),
  (5, 'Java logger');

-- Configuration for included appender.
INSERT INTO CONF_APPENDERS (REF_ID, NAME, APPENDER_ID, CONFIGURATION) VALUES
  (1, 'DB2 Tables', 1, NULL);

-- Module for all code for the logger utility.
CREATE OR REPLACE MODULE LOGGER;

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

-- Procedure to write logs.
ALTER MODULE LOGGER PUBLISH
  PROCEDURE LOG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE
  );

-- Array to store the hierarhy of a logger.
--ALTER MODULE LOGGER ADD
-- TYPE HIERARCHY_ARRAY AS VARCHAR(32) ARRAY[16];

