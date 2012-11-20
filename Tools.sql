--#SET TERMINATOR @
SET CURRENT SCHEMA LOGGER_1A @

/**
 * Constanct internalCache
 */
ALTER MODULE LOGGER ADD
  VARIABLE INTERNAL_CACHE ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'internalCache' @

/**
 * Constant logInternals
 */
ALTER MODULE LOGGER ADD
  VARIABLE REFRESH_CONS ANCHOR LOGDATA.CONFIGURATION.KEY CONSTANT 'secondsToRefresh' @

/**
 * Variable to indicate the use of internal cache.
 */
ALTER MODULE LOGGER ADD
  VARIABLE CACHE BOOLEAN DEFAULT TRUE @

/**
 * Variable that indicates if the configuration cache has been loaded.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LOADED BOOLEAN DEFAULT FALSE @

/**
 * Variable for the last time the configuration was loaded.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LAST_REFRESH TIMESTAMP DEFAULT CURRENT TIMESTAMP @

/**
 * Configutation keys type. This type is requiered in order to retrive the keys,
 * because there is not an option in the API to retrieve the keys, just the
 * indexes.
 */
ALTER MODULE LOGGER ADD
  TYPE CONF_KEYS_TYPE AS ANCHOR LOGDATA.CONFIGURATION.KEY ARRAY [50] @

/**
 * Configuration values type.
 */
ALTER MODULE LOGGER ADD
  TYPE CONF_VALUES_TYPE AS ANCHOR LOGDATA.CONFIGURATION.VALUE ARRAY [ANCHOR LOGDATA.CONFIGURATION.KEY] @

/**
 * Configuration keys in memory.
 */
ALTER MODULE LOGGER ADD
  VARIABLE CONFIGURATION_KEYS CONF_KEYS_TYPE @

/**
 * Configuration values in memory.
 */
ALTER MODULE LOGGER ADD
  VARIABLE CONFIGURATION CONF_VALUES_TYPE @

/**
 * Complete logger name.
 */
ALTER MODULE LOGGER ADD
  VARIABLE COMPLETE_LOGGER_NAME VARCHAR(256) @

/**
 * Loggers type.
 */
ALTER MODULE LOGGER ADD
  TYPE LOGGERS_TYPE AS ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID ARRAY [ANCHOR COMPLETE_LOGGER_NAME] @

/**
 * Logger's names and ids.
 */
ALTER MODULE LOGGER ADD
  VARIABLE LOGGERS LOGGERS_TYPE @

/**
 * Function that returns the value of the given key from the configuration
 * table.
 *
 * IN KEY
 *  Identification of the key/value parameter of the configuration table.
 * RETURNS The associated value of the given key. NULL if there is not a key
 * with that value.
 */
ALTER MODULE LOGGER ADD
  FUNCTION GET_VALUE (
  IN GIVEN_KEY ANCHOR LOGDATA.CONFIGURATION.KEY
  )
  RETURNS ANCHOR LOGDATA.CONFIGURATION.VALUE
  LANGUAGE SQL
  PARAMETER CCSID UNICODE
  SPECIFIC F_GET_VAL
  DETERMINISTIC
  NO EXTERNAL ACTION
  READS SQL DATA
 F_GET_VAL: BEGIN
  DECLARE RET ANCHOR LOGDATA.CONFIGURATION.VALUE;
  DECLARE SECS SMALLINT DEFAULT 60;
  DECLARE EPOCH TIMESTAMP;

  -- Checks if internal cache should be used.
  IF (CACHE = TRUE) THEN

   -- Sets the quantity of seconds before refresh. 60 seconds by default.
   REFRESH: BEGIN
    -- Handle for the second time the function is called and the param has not
    -- been defined.
    DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
      SET SECS = 60;
    SET SECS = INT(CONFIGURATION[REFRESH_CONS]);
    IF (SECS IS NULL) THEN
     SET SECS = 60;
    END IF;
   END REFRESH;

   -- Sets a reference date 1970-01-01.
   SET EPOCH = DATE(719163);
   IF (COALESCE(LAST_REFRESH, EPOCH) + SECS SECONDS < CURRENT TIMESTAMP OR LOADED = FALSE) THEN
    BEGIN
     DECLARE VALUE ANCHOR LOGDATA.CONFIGURATION.VALUE;
     DECLARE KEY ANCHOR LOGDATA.CONFIGURATION.KEY;
     DECLARE AT_END BOOLEAN; -- End of the cursor.
     DECLARE SIZE SMALLINT;
     DECLARE POS SMALLINT;
     DECLARE CONF CURSOR FOR
       SELECT KEY, VALUE
       FROM LOGDATA.CONFIGURATION;
     DECLARE CONTINUE HANDLER FOR NOT FOUND
       SET AT_END = TRUE;

     -- Clears the current configuration.
     SET CONFIGURATION = ARRAY_DELETE(CONFIGURATION);
     SET SIZE = CARDINALITY(CONFIGURATION_KEYS);
     IF (SIZE >= 1) THEN
      SET POS = 1;
      WHILE (POS < SIZE) DO
       SET CONFIGURATION_KEYS[POS] = NULL;
       SET POS = POS + 1;
      END WHILE;
     END IF;
     -- Reads current configuration.
     SET POS = 1;
     SET AT_END = FALSE;
     OPEN CONF;
     FETCH CONF INTO KEY, VALUE;
     WHILE (AT_END = FALSE) DO
      SET CONFIGURATION[KEY] = VALUE;
      SET CONFIGURATION_KEYS[POS] = KEY;
      SET POS = POS + 1;
      FETCH CONF INTO KEY, VALUE;
     END WHILE;
     -- Sets the last configuration read as now.
     SET LAST_REFRESH = CURRENT TIMESTAMP;
    END;
    -- Checks the variable for internal cache
   -- TODO remove if the trigger works correctly
    BEGIN
     -- NULL if the key is not in the configuration.
     DECLARE EXIT HANDLER FOR SQLSTATE '2202E'
       SET CACHE = TRUE;

     SET CACHE = CASE CONFIGURATION[INTERNAL_CACHE] 
       WHEN 'true' THEN TRUE 
       ELSE FALSE
       END;
    END;
    SET LOADED = TRUE;
   END IF;

   BEGIN
    -- NULL if the key is not in the configuration.
    DECLARE EXIT HANDLER FOR SQLSTATE '2202E'
      SET RET = NULL;

    SET RET = CONFIGURATION[GIVEN_KEY];
   END;
  ELSE -- Does not use the internal cache but a query.
   -- TODO remove if the trigger works correctly
   -- Checks the cache status.
   SELECT C.VALUE INTO RET
     FROM LOGDATA.CONFIGURATION C
     WHERE C.KEY = INTERNAL_CACHE;
   SET CACHE = CASE RET
     WHEN 'true' THEN TRUE
     ELSE FALSE
     END;
   SELECT C.VALUE INTO RET
     FROM LOGDATA.CONFIGURATION C
     WHERE C.KEY = GIVEN_KEY;
  END IF;

  RETURN RET;
 END F_GET_VAL @

/**
 * Sets a value in the loggers cache.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE SET_LOGGER_CACHE (
  IN LOGGER ANCHOR LOGDATA.CONF_LOGGERS.LOGGER_ID,
  IN LEVEL ANCHOR LOGDATA.LEVELS.LEVEL_ID
  )
 P_SET_CACHE: BEGIN
  SET LOGGERS[LOGGER] = LEVEL;
 END P_SET_CACHE @

/**
 * Activates the cache.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE ACTIVATE_CACHE (
  )
 P_ACT_CACHE: BEGIN
  SET CACHE = TRUE;
  SET LOADED = FALSE;
 END P_ACT_CACHE@

/**
 * Cleans the cache, and deactives it.
 */
ALTER MODULE LOGGER ADD
  PROCEDURE DEACTIVATE_CACHE (
  )
 P_DEA_CACHE: BEGIN
  SET CACHE = FALSE;
  SET LOADED = FALSE;
  -- Cleans the cache
  SET LOGGERS = ARRAY_DELETE(LOGGERS);
 END P_DEA_CACHE@

/**
 * Procedure that dumps the configuration. It returns two result setS. The
 * first is a one-row result set providing the information when the
 * configuration was loaded, and when it will be reloaded (with its frequency).
 * In the other result set, it shows the key-values from the configuration, if
 * this was already loaded, otherwise a descriptive message appears.
 * This procedure shows the configuration, but it does not reload it, for this
 * reason, the next refresh time could be in the past, because the get_value
 * is the only one that refreshes the configuration.
 * If the cache is in false in the configuration, but the configuration has
 * not been read, it will show that the cache is active (by default).
 *
 * If there is not a user temporary tablespace created in this database, the
 * error SQL0286N with SQLState 42727 will appear. It is necessary to create
 * at least one User Temporary Tablespace for this function. It can be done
 * by executing:
 *   db2 "create user temporary tablespace USRTMPSPC pagesize 4096"
 *
 * The procedure shows an error message at the end: SQL20439N - SQLSTATE=2202E
 * and it is due that when scanning the params it uses a helper table. 
 */
ALTER MODULE LOGGER ADD
  PROCEDURE SHOW_CONF ()
  LANGUAGE SQL
  SPECIFIC P_SHOW_CONF
  DYNAMIC RESULT SETS 2
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SHOW_CONF: BEGIN
  -- Creates the cursor for the configuration refreshness.
  BEGIN
   DECLARE SECS SMALLINT;
   DECLARE STMT VARCHAR(512);
   DECLARE REF CURSOR
     WITH RETURN TO CALLER
     FOR RS;
   -- There is not a User Temporary Tablespace
   DECLARE CONTINUE HANDLER FOR SQLSTATE '42727'
    BEGIN
	 DECLARE TBLSPC CURSOR FOR
       SELECT 'Please create a User Temporary Tablespace with 4K pagesize'
       FROM SYSIBM.SYSDUMMY1;
	 OPEN TBLSPC;
	END;
   -- Sets the value for the seconds.
   BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '2202E'
      SET SECS = -1;
    SET SECS = INT(CONFIGURATION[REFRESH_CONS]);
    IF (SECS IS NULL) THEN
     SET SECS = -1;
    END IF;
   END;
   -- Creates and prepares a dynamic query.
   SET STMT = 'SELECT CASE WHEN LOADED = FALSE THEN ''Unknown'' '
     || 'WHEN CACHE = TRUE THEN ''true'' '
     || 'ELSE ''false'' END AS INTERNAL_CACHE_ACTIVATED, '
     || 'LAST_REFRESH AS LAST_REFRESH, '
     || SECS || ' AS FREQUENCY, '
     || 'CASE WHEN ' || SECS || ' = -1 OR CACHE = FALSE THEN ''Not defined'' '
     || 'ELSE CHAR(LAST_REFRESH + ' || SECS || ' SECONDS) '
     || 'END AS NEXT_REFRESH, '
     || '''' || CURRENT TIMESTAMP || ''' AS CURRENT_TIME '
     || 'FROM SYSIBM.SYSDUMMY1';
   PREPARE RS FROM STMT;
   OPEN REF;
  END;

  -- Creates a helper table with a sequence of numbers.
  -- TODO To make the next creation in a Dynamic SQL in order to catch the
  -- exception when there is not a Use Temporary tablespace.
  DECLARE GLOBAL TEMPORARY TABLE SESSION.NUMBER_SEQ (
    NUM INT NOT NULL
    ) WITH REPLACE;
  INSERT INTO SESSION.NUMBER_SEQ
    SELECT ROW_NUMBER() OVER()
    FROM SYSCAT.COLUMNS;
  
  -- Creates a cursor for configuration values.
  BEGIN
   DECLARE CARD SMALLINT;
   DECLARE CONF CURSOR
     WITH RETURN TO CALLER 
     FOR 
     SELECT NUM, 
     CONFIGURATION_KEYS[NUM] AS KEY,
     CONFIGURATION[CONFIGURATION_KEYS[NUM]] AS VALUE
     FROM SESSION.NUMBER_SEQ;
   DECLARE NOTHING CURSOR
     WITH RETURN TO CALLER
     FOR
     SELECT 'Configuration not loaded' AS MESSAGE
     FROM SYSIBM.SYSDUMMY1;
   
   -- Checks if the configuration was already loaded.
   SET CARD = CARDINALITY(CONFIGURATION_KEYS);
   IF (CARD > 0) THEN
    OPEN CONF;
   ELSE
    OPEN NOTHING;
   END IF;
  END;
 END P_SHOW_CONF @
 
ALTER MODULE LOGGER ADD
  PROCEDURE SHOW_CACHE ()
  LANGUAGE SQL
  SPECIFIC P_SHOW_CACHE
  DYNAMIC RESULT SETS 2
  MODIFIES SQL DATA
  DETERMINISTIC
  NO EXTERNAL ACTION
  PARAMETER CCSID UNICODE
 P_SHOW_CACHE: BEGIN
  DECLARE CACHE_CURSOR CURSOR
    WITH RETURN TO CALLER 
    FOR 
    SELECT SUBSTR(T.LOGGER, 1, 64) AS LOGGER_NAME, T.ID AS LOGGER_ID
    FROM UNNEST(LOGGERS) AS T(LOGGER, ID);
  -- TODO To make the next creation in a Dynamic SQL in order to catch the
  -- exception when there is not an User Temporary tablespace.
  DECLARE GLOBAL TEMPORARY TABLE SESSION.LOGGER_CACHE (
	DESC VARCHAR(64)
    ) WITH REPLACE;
  BEGIN
   DECLARE DESC_CURSOR CURSOR
   WITH RETURN TO CALLER
   FOR
   SELECT *
   FROM SESSION.LOGGER_CACHE;
   INSERT INTO SESSION.LOGGER_CACHE (DESC) VALUES ('Cardinality: ' || COALESCE(CARDINALITY(LOGGERS), -1));
   INSERT INTO SESSION.LOGGER_CACHE (DESC) VALUES ('Max cardinality: ' || COALESCE(MAX_CARDINALITY(LOGGERS), -1));
  
   OPEN DESC_CURSOR;
   OPEN CACHE_CURSOR;
  END;
 END P_SHOW_CACHE@