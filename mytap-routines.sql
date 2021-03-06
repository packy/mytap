DELIMITER //

/****************************************************************************/

-- internal function to check

DROP FUNCTION IF EXISTS _has_routine  //
CREATE FUNCTION _has_routine(sname VARCHAR(64), rname VARCHAR(64), rtype VARCHAR(10))
RETURNS BOOLEAN 
BEGIN
  DECLARE ret BOOLEAN;

  SELECT '1' INTO ret
  FROM `information_schema`.`routines`
  WHERE `routine_schema` = sname
  AND `routine_name` = rname
  AND `routine_type` = rtype;

  RETURN COALESCE(ret, 0);
END //


-- has_function(schema, function, description)
DROP FUNCTION IF EXISTS has_function //
CREATE FUNCTION has_function(sname VARCHAR(64), rname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Function ',
      quote_ident(sname), '.', quote_ident(rname), ' should exist');
  END IF;

  RETURN ok(_has_routine(sname, rname, 'FUNCTION'), description);
END //


-- hasnt_function(schema, function, description)
DROP FUNCTION IF EXISTS hasnt_function //
CREATE FUNCTION hasnt_function(sname VARCHAR(64), rname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Function ',
      quote_ident(sname), '.', quote_ident(rname), ' should not exist');
  END IF;
  RETURN ok(NOT _has_routine(sname, rname, 'FUNCTION'), description);
END //


-- has_procedure(schema, procedure, description)
DROP FUNCTION IF EXISTS has_procedure //
CREATE FUNCTION has_procedure(sname VARCHAR(64), rname TEXT, description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Procedure ',
      quote_ident(sname), '.', quote_ident(rname), ' should exist');
  END IF;

  RETURN ok(_has_routine(sname, rname, 'PROCEDURE'), description);
END //

-- hasnt_procedure(schema, procedure, description)
DROP FUNCTION IF EXISTS hasnt_procedure //
CREATE FUNCTION hasnt_procedure(sname VARCHAR(64), rname TEXT, description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Procedure ',
      quote_ident(sname), '.', quote_ident(rname), ' should not exist');
  END IF;

  RETURN ok(NOT _has_routine(sname, rname, 'PROCEDURE'), description);
END //


/****************************************************************************/

-- FUNCTION DATA_TYPE i.e. return type

-- _function_data_type(schema, function, returns, description)
DROP FUNCTION IF EXISTS _function_data_type  //
CREATE FUNCTION _function_data_type(sname VARCHAR(64), rname VARCHAR(64))
RETURNS VARCHAR(64)
BEGIN
  DECLARE ret VARCHAR(64);

  SELECT `data_type` INTO ret
  FROM `information_schema`.`routines`
  WHERE `routine_schema` = sname
  AND `routine_name` = rname
  AND `routine_type` = 'FUNCTION';

  RETURN COALESCE(ret, NULL);
END //


-- function_data_type_is(schema, function, returns, description)
DROP FUNCTION IF EXISTS function_data_type_is//
CREATE FUNCTION function_data_type_is(sname VARCHAR(64), rname VARCHAR(64), dtype VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('Function ', quote_ident(sname), '.', quote_ident(rname),
      ' should return ', quote_ident(_datatype(dtype)));
  END IF;

  IF NOT _has_routine(sname, rname, 'FUNCTION') THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('    Function ', quote_ident(sname),'.', quote_ident(rname),
        ' does not exist')));
  END IF;

  RETURN eq(_function_data_type(sname, rname), _datatype(dtype), description);
END //


/****************************************************************************/

-- IS_DETERMINISTIC YES/NO

-- _routine_is_deterministic(schema, function, deterministic, description)
DROP FUNCTION IF EXISTS _routine_is_deterministic  //
CREATE FUNCTION _routine_is_deterministic(sname VARCHAR(64), rname VARCHAR(64), rtype VARCHAR(9))
RETURNS VARCHAR(3)
BEGIN
  DECLARE ret VARCHAR(3);

  SELECT `is_deterministic` INTO ret
  FROM `information_schema`.`routines`
  WHERE `routine_schema` = sname
  AND `routine_name` = rname
  AND `routine_type` = rtype;

  RETURN COALESCE(ret, NULL);
END //


-- function_is_deterministic(schema, function, description)
DROP FUNCTION IF EXISTS function_is_deterministic //
CREATE FUNCTION function_is_deterministic(sname VARCHAR(64), rname VARCHAR(64), val VARCHAR(3), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Function ', quote_ident(sname), '.', quote_ident(rname),
      ' should have Is Deterministic ', quote_ident(val));
  END IF;

  IF NOT _has_routine(sname, rname, 'FUNCTION') THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('    Function ', quote_ident(sname), '.', quote_ident(rname),
        ' does not exist')));
  END IF;

  RETURN eq(_routine_is_deterministic(sname, rname, 'FUNCTION'), val, description);
END //

-- procedure_is_deterministic(schema, procedure, description)
DROP FUNCTION IF EXISTS procedure_is_deterministic //
CREATE FUNCTION procedure_is_deterministic(sname VARCHAR(64), rname VARCHAR(64), val VARCHAR(3), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Procedure ', quote_ident(sname), '.', quote_ident(rname),
      ' should have Is Deterministic ', quote_ident(val));
  END IF;

  IF NOT _has_routine(sname, rname, 'PROCEDURE') THEN
     RETURN CONCAT(ok(FALSE, description), '\n',
       diag(CONCAT('    Procedure ', quote_ident(sname), '.', quote_ident(rname),
        ' does not exist')));
  END IF;

  RETURN eq(_routine_is_deterministic(sname, rname, 'PROCEDURE'), val, description);
END //


/****************************************************************************/

-- SECURITY TYPE
-- { INVOKER | DEFINER }

-- _routine_security_type(schema, routine, security_type, description)
DROP FUNCTION IF EXISTS _routine_security_type //
CREATE FUNCTION _routine_security_type(sname VARCHAR(64), rname VARCHAR(64), rtype VARCHAR(9))
RETURNS VARCHAR(7)
BEGIN
  DECLARE ret VARCHAR(7);

  SELECT `security_type` INTO ret
  FROM `information_schema`.`routines`
  WHERE `routine_schema` = sname
  AND `routine_name` = rname
  AND `routine_type` = rtype ;

  RETURN COALESCE(ret, NULL);
END //


-- function_security_type_is(schema, function, security type , description)
DROP FUNCTION IF EXISTS function_security_type_is //
CREATE FUNCTION function_security_type_is(sname VARCHAR(64), rname VARCHAR(64), stype VARCHAR(7), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Function ', quote_ident(sname), '.', quote_ident(rname),
      ' should have Security Type ' , quote_ident(stype));
  END IF;

  IF stype NOT IN('INVOKER','DEFINER') THEN
    RETURN CONCAT(ok(FALSE, description),'\n',
      diag('    Security Type must be { INVOKER | DEFINER }'));
  END IF;

  IF NOT _has_routine(sname, rname, 'FUNCTION') THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('    Function ', quote_ident(sname), '.', quote_ident(rname), ' does not exist')));
  END IF;

  RETURN eq(_routine_security_type(sname, rname, 'FUNCTION'), stype, description);
END //

-- procedure_security_type_is(schema, procedure, security type , description)
DROP FUNCTION IF EXISTS procedure_security_type_is //
CREATE FUNCTION procedure_security_type_is(sname VARCHAR(64), rname VARCHAR(64), stype VARCHAR(7), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Procedure ', quote_ident(sname), '.', quote_ident(rname),
      ' should have Security Type ',  quote_ident(stype));
  END IF;

  IF stype NOT IN('INVOKER','DEFINER') THEN
    RETURN CONCAT(ok(FALSE, description),'\n',
      diag('    Security type must be { INVOKER | DEFINER }'));
  END IF;

  IF NOT _has_routine(sname, rname, 'PROCEDURE') THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('    Procedure ', quote_ident(sname), '.', quote_ident(rname), ' does not exist')));
  END IF;

  RETURN eq(_routine_security_type(sname, rname, 'PROCEDURE'), stype, description);
END //


/****************************************************************************/

-- SQL_DATA_ACCESS
-- { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }

-- _routine_sql_data_access(schema, routine, type, description)
DROP FUNCTION IF EXISTS _routine_sql_data_access  //
CREATE FUNCTION _routine_sql_data_access(sname VARCHAR(64), rname VARCHAR(64), rtype VARCHAR(9))
RETURNS VARCHAR(64)
BEGIN
  DECLARE ret VARCHAR(64);

  SELECT `sql_data_access` INTO ret
  FROM `information_schema`.`routines`
  WHERE `routine_schema` = sname
  AND `routine_name` = rname
  AND `routine_type` = rtype ;

  RETURN COALESCE(ret, NULL);
END //


-- function_sql_data_access_is(schema, function, sql data access , description)
DROP FUNCTION IF EXISTS function_sql_data_access_is //
CREATE FUNCTION function_sql_data_access_is(sname VARCHAR(64), rname VARCHAR(64), sda VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Function ', quote_ident(sname), '.', quote_ident(rname),
      ' should have SQL Data Access ', quote_ident(sda));
  END IF;

  IF NOT sda IN('CONTAINS SQL','NO SQL','READS SQL DATA','MODIFIES SQL DATA') THEN
    RETURN CONCAT(ok(FALSE,description), '\n',
      diag('    SQL Data Access must be { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }'));
  END IF;

  IF NOT _has_routine(sname, rname, 'FUNCTION') THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('    Function ', quote_ident(sname), '.', quote_ident(rname), ' does not exist')));
  END IF;

  RETURN eq(_routine_sql_data_access(sname, rname, 'FUNCTION'), sda, description);
END //


-- procedure_sql_data_access_is(schema, procedure, security type , description)
DROP FUNCTION IF EXISTS procedure_sql_data_access_is //
CREATE FUNCTION procedure_sql_data_access_is(sname VARCHAR(64), rname VARCHAR(64), sda VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('Procedure ', quote_ident(sname), '.', quote_ident(rname),
      ' should have SQL_DATA_ACCESS set to ', quote_ident(sda));
  END IF;

  IF NOT sda IN('CONTAINS SQL','NO SQL','READS SQL DATA','MODIFIES SQL DATA') THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag('    SQL_DATA_ACCESS must be { CONTAINS SQL | NO SQL | READS SQL DATA | MODIFIES SQL DATA }'));
  END IF;

  IF NOT _has_routine(sname, rname, 'PROCEDURE') THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('    Procedure ', quote_ident(sname), '.', quote_ident(rname), ' does not exist')));
  END IF;

  RETURN eq(_routine_sql_data_access(sname, rname, 'PROCEDURE'), sda, description);
END //


/*******************************************************************/
-- Check that the proper routines are defined

DROP FUNCTION IF EXISTS _missing_routines //
CREATE FUNCTION _missing_routines(sname VARCHAR(64), rtype VARCHAR(9))
RETURNS TEXT
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(qi(`ident`)) INTO ret
  FROM 
   (
      SELECT `ident`
      FROM `idents1`
      WHERE `ident` NOT IN
       (
          SELECT `routine_name`
          FROM `information_schema`.`routines`
          WHERE `routine_schema` = sname
          AND `routine_type` = rtype
       )
    ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_routines //
CREATE FUNCTION _extra_routines(sname VARCHAR(64), rtype VARCHAR(9))
RETURNS TEXT
BEGIN
  DECLARE ret TEXT;
  
  SELECT GROUP_CONCAT(qi(`ident`)) INTO ret
  FROM 
   (
      SELECT `routine_name` AS `ident`
      FROM `information_schema`.`routines`
      WHERE `routine_schema` = sname
      AND `routine_type` = rtype
      AND `routine_name` NOT IN 
       (
          SELECT `ident`
          FROM `idents2`
       )
   ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS routines_are //
CREATE FUNCTION routines_are(sname VARCHAR(64), rtype VARCHAR(9), want TEXT, description TEXT)
RETURNS TEXT
BEGIN

  DECLARE sep       CHAR(1) DEFAULT ',';
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);

  IF description = '' THEN 
    SET description = CONCAT('Schema ', quote_ident(sname),
      ' should have the correct ', LOWER(rtype), 's');
  END IF;

  IF NOT _has_schema(sname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag(CONCAT('    Schema ', quote_ident(sname), ' does not exist')));
  END IF;

  SET want = _fixCSL(want);

  IF want IS NULL THEN
    RETURN CONCAT(ok(FALSE,description),'\n',
      diag(CONCAT('Invalid character in comma separated list of expected schemas\n',
                  'Identifier must not contain NUL Byte or extended characters(> U+10000)')));
  END IF;

  DROP TEMPORARY TABLE IF EXISTS idents1;
  CREATE TEMPORARY TABLE tap.idents1(ident VARCHAR(64) PRIMARY KEY)
    ENGINE MEMORY CHARSET utf8 COLLATE utf8_general_ci;
  DROP TEMPORARY TABLE IF EXISTS idents2;
  CREATE TEMPORARY TABLE tap.idents2(ident VARCHAR(64) PRIMARY KEY)
    ENGINE MEMORY CHARSET utf8 COLLATE utf8_general_ci;

  WHILE want != '' > 0 DO
    SET @val = TRIM(SUBSTRING_INDEX(want, sep, 1));
    SET @val = uqi(@val);
    IF  @val <> '' THEN 
      INSERT IGNORE INTO idents1 VALUE(@val);
      INSERT IGNORE INTO idents2 VALUE(@val);
    END IF;
    SET want = SUBSTRING(want, CHAR_LENGTH(@val) + seplength + 1);
  END WHILE;

  SET @missing = _missing_routines(sname, rtype);
  SET @extras  = _extra_routines(sname, rtype);

  RETURN _are(CONCAT(rtype, 's'), @extras, @missing, description);
END //



DELIMITER ;