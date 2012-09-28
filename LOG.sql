--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER@

ALTER MODULE LOGGER ADD 
  PROCEDURE LOG_SQL (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID DEFAULT 0,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID DEFAULT 0,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION)
  SPECIFIC P_LOG_SQL
  LANGUAGE SQL
  DETERMINISTIC -- With the same parameters, it will always do the same.
  NO EXTERNAL ACTION
  MODIFIES SQL DATA
 P_LOG_SQL: BEGIN
  INSERT INTO LOGS (DATE, LEVEL_ID, LOGGER_ID, ENVIRONMENT, MESSAGE) VALUES
    (CURRENT TIMESTAMP, LEVEL_ID, LOGGER_ID, CURRENT USER, MESSAGE); 
 END P_LOG_SQL@
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_DB2DIAG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION)@
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_UTL_FILE (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION)@
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_DB2LOGGER (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION)@
ALTER MODULE LOGGER PUBLISH 
  PROCEDURE LOG_JAVA (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE,
  IN CONFIGURATION ANCHOR CONF_APPENDERS.CONFIGURATION)@

/**
 * Sends a message into the logger system. Before to log this message in an
 * appender, this method verifies in the logger level given is superior or
 * or equal to the configured level. If not, it skips this process.
 * After validating the level, it checks all appenders to see in which in has to
 * log the message.
 *
 * IN LOGGER_ID
 *   This is the associated logger of the provided message.
 * IN LEVEL_ID
 *   Level of the message.
 * IN MESSAGE
 *   Message to log.
 */
ALTER MODULE LOGGER ADD 
  PROCEDURE LOG (
  IN LOGGER_ID ANCHOR CONF_LOGGERS.LOGGER_ID,
  IN LEVEL_ID ANCHOR LEVELS.LEVEL_ID,
  IN MESSAGE ANCHOR LOGS.MESSAGE)
  SPECIFIC P_LOG
  LANGUAGE SQL
  NOT DETERMINISTIC -- If the configuration changes, the log could not be
                    -- written in the same way.
  NO EXTERNAL ACTION
  MODIFIES SQL DATA
 P_LOG: BEGIN
  DECLARE CURRENT_LEVEL_ID SMALLINT; -- Level in the configuration.
  DECLARE APPENDER_ID SMALLINT; -- Appender's ID.
  DECLARE CONFIGURATION VARCHAR(256); -- Appender's configuration.
  DECLARE AT_END BOOLEAN; -- End of the cursor.
  DECLARE APPENDERS CURSOR FOR
    SELECT APPENDER_ID, CONFIGURATION
    FROM CONF_APPENDERS;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET AT_END = TRUE;
  -- Retrieves the current level in the configuration for the given logger.
  SELECT C.LEVEL_ID INTO CURRENT_LEVEL_ID 
    FROM CONF_LOGGERS_EFFECTIVE C
    WHERE C.LOGGER_ID = LOGGER_ID;
    
  -- Checks if the current level is at least equal to the provided level.
  -- TODO Verificar esto, ya que aqu� se puede usar la tabla references, si root
  -- no est� activo.
  IF (CURRENT_LEVEL_ID >= LEVEL_ID) THEN
   -- TODO Format the message according to the pattern.
   -- SYSPROC.MON_GET_APPLICATION_ID()
   -- Retrieves all the configurations for the appenders.
   OPEN APPENDERS;
   SET AT_END = FALSE;
   FETCH APPENDERS INTO APPENDER_ID, CONFIGURATION;
   -- Iterates over the results.
   WHILE AT_END = FALSE DO
    -- Checks the values
    CASE APPENDER_ID
      WHEN 1 THEN -- Pure SQL PL, writes in tables.
        CALL LOG_SQL(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 2 THEN -- Writes in the db2diag.log file via a function.
        CALL LOG_DB2DIAG(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 3 THEN -- Writes in a file (Not available in express-c edition.)
        CALL LOG_UTL_FILE(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 4 THEN -- Sends the log to the DB2LOGGER in C.
        CALL LOG_DB2LOGGER(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      WHEN 5 THEN -- Sends the log to Java, and takes the configuration there.
        CALL LOG_JAVA(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
      ELSE -- By default writes in the tables.
        CALL LOG_SQL(LOGGER_ID, LEVEL_ID, MESSAGE, CONFIGURATION);
    END CASE;
    FETCH APPENDERS INTO APPENDER_ID, CONFIGURATION;
   END WHILE;
   CLOSE APPENDERS;
  END IF;
END P_LOG@
