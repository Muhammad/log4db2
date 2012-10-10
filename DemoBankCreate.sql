--#SET TERMINATOR @
SET CURRENT SCHEMA DEMOBANK @

CREATE SCHEMA DEMOBANK @

CREATE TABLE ACCOUNTS (
  ACCOUNT_NUM INTEGER NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY (START WITH 1),
  FIRST_NAME VARCHAR(32) NOT NULL,
  LAST_NAME VARCHAR(32) NOT NULL,
  BALANCE INTEGER NOT NULL
  )@

CREATE TABLE TRANSACTIONS (
  DATE TIMESTAMP NOT NULL WITH DEFAULT CURRENT TIMESTAMP,
  ACCOUNT_NUM INTEGER,
  TYPE CHAR(1) NOT NULL CHECK (TYPE IN ('W', 'D', 'B', 'C', 'T', 'X')),
  BALANCE_BEFORE INTEGER NOT NULL,
  BALANCE_AFTER INTEGER NOT NULL,
  CPY_ACCOUNT_NUM INTEGER NOT NULL,
  NOTES VARCHAR(32),
  CONSTRAINT FK_ACCTS FOREIGN KEY (ACCOUNT_NUM) REFERENCES ACCOUNTS (ACCOUNT_NUM) ON DELETE SET NULL
  )@
  
CREATE PROCEDURE CREATE_ACCOUNT (
  IN LN VARCHAR(32),
  IN FN VARCHAR(32))
 BEGIN
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
  DECLARE ACCOUNT INTEGER;
  DECLARE LOGGER_ID SMALLINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    CALL LOGGER.ERROR(LOGGER_ID, 'Exception: SQLCODE ' || SQLCODE || ' - SQLState ' || SQLSTATE);
    RESIGNAL SQLSTATE 'BK001';
   END;

  CALL LOGGER.GET_LOGGER('DemoBank.Operation.Create', LOGGER_ID);
  BEGIN ATOMIC
   SELECT ACCOUNT_NUM INTO ACCOUNT FROM FINAL TABLE (
     INSERT INTO ACCOUNTS (FIRST_NAME, LAST_NAME, BALANCE)
     VALUES (LN, FN, 0));
   INSERT INTO TRANSACTIONS (ACCOUNT_NUM, TYPE, BALANCE_BEFORE, BALANCE_AFTER, CPY_ACCOUNT_NUM)
     VALUES (ACCOUNT, 'C', 0, 0, ACCOUNT);
  END;
 END@

CREATE PROCEDURE GET_BALANCE (
  IN ACCOUNT INTEGER,
  OUT BALANCE_OUT INTEGER)
 BEGIN
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
  DECLARE LOGGER_ID SMALLINT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    CALL LOGGER.ERROR(LOGGER_ID, 'Exception: SQLCODE ' || SQLCODE || ' - SQLState ' || SQLSTATE);
    RESIGNAL SQLSTATE 'BK002';
   END;

  CALL LOGGER.GET_LOGGER('DemoBank.Operation.Balance', LOGGER_ID);

  SELECT BALANCE INTO BALANCE_OUT
    FROM ACCOUNTS
    WHERE ACCOUNT_NUM = ACCOUNT
    WITH CS;
  INSERT INTO TRANSACTIONS (ACCOUNT_NUM, TYPE, BALANCE_BEFORE, BALANCE_AFTER, CPY_ACCOUNT_NUM)
    VALUES (ACCOUNT, 'B', BALANCE_OUT, BALANCE_OUT, ACCOUNT);
 END@

CREATE PROCEDURE DEPOSIT (
  IN ACCOUNT INTEGER,
  IN AMOUNT INTEGER)
 BEGIN
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
  DECLARE BAL INTEGER;
  DECLARE NEW_BAL INTEGER;
  DECLARE LOGGER_ID SMALLINT;
  DECLARE C CURSOR FOR
    SELECT BALANCE
    FROM ACCOUNTS
    WHERE ACCOUNT_NUM = ACCOUNT
    FOR UPDATE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    CALL LOGGER.ERROR(LOGGER_ID, 'Exception: SQLCODE ' || SQLCODE || ' - SQLState ' || SQLSTATE);
    RESIGNAL SQLSTATE 'BK003';
   END;

  CALL LOGGER.GET_LOGGER('DemoBank.Operation.Deposit', LOGGER_ID);

  OPEN C;
  FETCH C INTO BAL;
  IF (SQLCODE <> 100) THEN
   SET NEW_BAL = BAL + AMOUNT;
   BEGIN ATOMIC
    UPDATE ACCOUNTS
      SET BALANCE = NEW_BAL 
      WHERE CURRENT OF C;
    INSERT INTO TRANSACTIONS (ACCOUNT_NUM, TYPE, BALANCE_BEFORE, BALANCE_AFTER, CPY_ACCOUNT_NUM)
      VALUES (ACCOUNT, 'D', BAL, NEW_BAL, ACCOUNT);
   END;
  ELSE
   CALL LOGGER.WARN(LOGGER_ID, 'The ' || ACCOUNT || ' account has been deleted.');
  END IF;
  CLOSE C;
 END@

CREATE PROCEDURE WITHDRAWAL (
  IN ACCOUNT INTEGER,
  IN AMOUNT INTEGER)
 BEGIN
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
  DECLARE BAL INTEGER;
  DECLARE NEW_BAL INTEGER;
  DECLARE LOGGER_ID SMALLINT;
  DECLARE C CURSOR FOR
    SELECT BALANCE
    FROM ACCOUNTS
    WHERE ACCOUNT_NUM = ACCOUNT
    FOR UPDATE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    CALL LOGGER.ERROR(LOGGER_ID, 'Exception: SQLCODE ' || SQLCODE || ' - SQLState ' || SQLSTATE);
    RESIGNAL SQLSTATE 'BK004';
   END;

  CALL LOGGER.GET_LOGGER('DemoBank.Operation.Withdrawal', LOGGER_ID);

  OPEN C;
  FETCH C INTO BAL;
  SET NEW_BAL = BAL - AMOUNT;
  IF (NEW_BAL >= 0) THEN
   BEGIN ATOMIC:
    UPDATE ACCOUNTS
      SET BALANCE = NEW_BAL
      WHERE CURRENT OF C;
    INSERT INTO TRANSACTIONS (ACCOUNT_NUM, TYPE, BALANCE_BEFORE, BALANCE_AFTER, CPY_ACCOUNT_NUM)
      VALUES (ACCOUNT, 'W', BAL, NEW_BAL, ACCOUNT);
   END;
  ELSE
   CALL LOGGER.INFO (LOGGER_ID, 'The ' || ACCOUNT || ' account has not enough funds to realize this withdrawal (' || AMOUNT || ')');
  END IF;
  CLOSE C;
 END@

CREATE PROCEDURE TRANSFER (
  IN ACCOUNT_SOURCE INTEGER,
  IN ACCOUNT_TARGET INTEGER,
  IN AMOUNT INTEGER)
 BEGIN
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
  DECLARE BAL_SOURCE INTEGER;
  DECLARE BAL_TARGET INTEGER;
  DECLARE NEW_BAL_SOURCE INTEGER;
  DECLARE NEW_BAL_TARGET INTEGER;
  DECLARE LOGGER_ID SMALLINT;
  DECLARE C_SOURCE CURSOR FOR
    SELECT BALANCE
    FROM ACCOUNTS
    WHERE ACCOUNT_NUM = ACCOUNT_SOURCE
    FOR UPDATE;
  DECLARE C_TARGET CURSOR FOR
    SELECT BALANCE
    FROM ACCOUNTS
    WHERE ACCOUNT_NUM = ACCOUNT_TARGET
    FOR UPDATE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    CALL LOGGER.ERROR(LOGGER_ID, 'Exception: SQLCODE ' || SQLCODE || ' - SQLState ' || SQLSTATE);
    RESIGNAL SQLSTATE 'BK005';
   END;

  CALL LOGGER.GET_LOGGER('DemoBank.Operation.Transfer', LOGGER_ID);
  
  OPEN C_SOURCE;
  OPEN C_TARGET;
  FETCH C_SOURCE INTO BAL_SOURCE;
  IF (SQLCODE <> 100) THEN
   SET NEW_BAL_SOURCE = BAL_SOURCE - AMOUNT;
   IF (NEW_BAL_SOURCE >= 0) THEN
    FETCH C_TARGET INTO BAL_TARGET;
    IF (SQLCODE <> 100) THEN
     SET NEW_BAL_TARGET = BAL_TARGET + AMOUNT;
     BEGIN ATOMIC
      UPDATE ACCOUNTS
        SET BALANCE = NEW_BAL_SOURCE
        WHERE CURRENT OF C_SOURCE;
      UPDATE ACCOUNTS
        SET BALANCE = NEW_BAL_TARGET
        WHERE CURRENT OF C_TARGET;
      INSERT INTO TRANSACTIONS (ACCOUNT_NUM, TYPE, BALANCE_BEFORE, BALANCE_AFTER, CPY_ACCOUNT_NUM)
        VALUES (ACCOUNT_SOURCE, 'T', BAL_SOURCE, NEW_BAL_SOURCE, ACCOUNT_SOURCE);
      INSERT INTO TRANSACTIONS (ACCOUNT_NUM, TYPE, BALANCE_BEFORE, BALANCE_AFTER, CPY_ACCOUNT_NUM)
        VALUES (ACCOUNT_TARGET, 'T', BAL_TARGET, NEW_BAL_TARGET, ACCOUNT_TARGET);
     END;
    ELSE
     CALL LOGGER.WARN(LOGGER_ID, 'The ' || ACCOUNT_TARGET || ' target account has been deleted.');
    END IF;
   ELSE
    CALL LOGGER.INFO (LOGGER_ID, 'The ' || ACCOUNT_SOURCE || ' account has not enough funds to realize this tranference of ' || AMOUNT || ' to ' || ACCOUNT_TARGET);
   END IF;
  ELSE
   CALL LOGGER.WARN(LOGGER_ID, 'The ' || ACCOUNT_SOURCE || ' source account has been deleted.');
  END IF;
 END@

CREATE PROCEDURE CLOSE_ACCOUNT (
  IN ACCOUNT INTEGER)
 BEGIN
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE SQLSTATE CHAR(5) DEFAULT '0000';
  DECLARE BALANCE INTEGER;
  DECLARE LOGGER_ID SMALLINT;
  DECLARE C CURSOR FOR
    SELECT BALANCE
    FROM ACCOUNTS
    WHERE ACCOUNT_NUM = ACCOUNT
    FOR UPDATE;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    CALL LOGGER.ERROR(LOGGER_ID, 'Exception: SQLCODE ' || SQLCODE || ' - SQLState ' || SQLSTATE || ' account ' || COALESCE(ACCOUNT, -1));
    RESIGNAL SQLSTATE 'BK006';
   END;

  CALL LOGGER.GET_LOGGER('DemoBank.Operation.Close', LOGGER_ID);

  CALL LOGGER.DEBUG(LOGGER_ID, 'Begin operation for account ' || ACCOUNT);

  OPEN C;
  FETCH C INTO BALANCE;
  IF (SQLCODE <> 100) THEN
   BEGIN ATOMIC
    DELETE FROM ACCOUNTS
      WHERE CURRENT OF C;
    INSERT INTO TRANSACTIONS (ACCOUNT_NUM, TYPE, BALANCE_BEFORE, BALANCE_AFTER, CPY_ACCOUNT_NUM)
       VALUES (NULL, 'X', BALANCE, 0, ACCOUNT);
   END;
  ELSE
   CALL LOGGER.WARN(LOGGER_ID, 'The ' || ACCOUNT || ' account has been deleted.');
  END IF;
 END@