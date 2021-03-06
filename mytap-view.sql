-- VIEWS
-- =====

DELIMITER //

/****************************************************************************/

DROP FUNCTION IF EXISTS _has_view //
CREATE FUNCTION _has_view (sname VARCHAR(64), vname VARCHAR(64))
RETURNS BOOLEAN 
BEGIN
  DECLARE ret BOOLEAN;

  SELECT 1 INTO ret
  FROM `information_schema`.`tables`
  WHERE `table_schema` = sname
  AND `table_name` = vname
  AND `table_type` = 'VIEW';

  RETURN coalesce(ret, false);
END //

-- has_view ( schema, view )
DROP FUNCTION IF EXISTS has_view //
CREATE FUNCTION has_view(sname VARCHAR(64), vname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('View ', 
      quote_ident(sname), '.', quote_ident(vname), ' should exist');
  END IF;

  RETURN ok(_has_view(sname, vname), description);
END //

-- hasnt_view ( schema, view )
DROP FUNCTION IF EXISTS hasnt_view //
CREATE FUNCTION hasnt_view(sname VARCHAR(64), vname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('View ',
      quote_ident(sname), '.', quote_ident(vname), ' should not exist' );
  END IF;

  RETURN ok(NOT _has_view(sname, vname), description);
END //

/****************************************************************************/

DROP FUNCTION IF EXISTS _has_security //
CREATE FUNCTION _has_security(sname VARCHAR(64), vname VARCHAR(64), vsecurity VARCHAR(9))
RETURNS BOOLEAN
BEGIN
  DECLARE ret boolean;

  SELECT 1 INTO ret
  FROM `information_schema`.`views`
  WHERE `table_schema` = sname
  AND `table_name` = vname
  AND `security_type` = vsecurity;

  RETURN coalesce(ret, false);
END //

-- has_security_invoker ( schema, view )
DROP FUNCTION IF EXISTS has_security_invoker //
CREATE FUNCTION has_security_invoker(sname VARCHAR(64), vname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF NOT _has_view(sname, vname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag (CONCAT('    View ', quote_ident(sname), '.', quote_ident(vname),
        ' does not exist')));
  END IF;

  IF description = '' THEN
    SET description = concat('View ',
      quote_ident(sname), '.', quote_ident(vname), ' should have security INVOKER');
  END IF;

  RETURN ok(_has_security(sname, vname, 'INVOKER'), description);
END //

-- has_security_definer ( schema, view )
DROP FUNCTION IF EXISTS has_security_definer //
CREATE FUNCTION has_security_definer(sname VARCHAR(64), vname VARCHAR(64), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = concat('View ',
      quote_ident(sname), '.', quote_ident(vname), ' should have security DEFINER');
  END IF;

  IF NOT _has_view(sname, vname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag (CONCAT('    View ', quote_ident(sname), '.', quote_ident(vname),
        ' does not exist')));
  END IF;

  RETURN ok(_has_security(sname, vname, 'DEFINER'), description);
END //


/****************************************************************************/

-- SECURITY TYPE
-- { INVOKER | DEFINER } 
-- pgTAP style to allow eq test and diagnostics


DROP FUNCTION IF EXISTS _view_security_type //
CREATE FUNCTION _view_security_type(sname VARCHAR(64), vname VARCHAR(64))
RETURNS VARCHAR(7)
BEGIN
  DECLARE ret VARCHAR(7);

  SELECT `security_type` INTO ret
  FROM `information_schema`.`views`
  WHERE `table_schema` = sname
  AND `table_name` = vname;

  RETURN COALESCE(ret, NULL);

END //

-- view_security_type_is ( schema, view )
DROP FUNCTION IF EXISTS view_security_type_is //
CREATE FUNCTION view_security_type_is(sname VARCHAR(64), vname VARCHAR(64), stype VARCHAR(7), description TEXT) 
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('View ', quote_ident(sname), '.', quote_ident(vname),
       ' should have Security Type ', qv(stype));
  END IF;

  IF NOT _has_view(sname, vname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag (CONCAT('    View ', quote_ident(sname), '.', quote_ident(vname),
        ' does not exist')));
  END IF;

  RETURN eq(_view_security_type( sname, vname), stype, description);
END //


/****************************************************************************/

-- CHECK OPTION
-- { LOCAL | CASCADED }

DROP FUNCTION IF EXISTS _view_check_option //
CREATE FUNCTION _view_check_option(sname VARCHAR(64), vname VARCHAR(64))
RETURNS VARCHAR(8)
BEGIN
  DECLARE ret VARCHAR(8);

  SELECT `check_option` INTO ret
  FROM `information_schema`.`views`
  WHERE `table_schema` = sname
  AND `table_name` = vname;

  RETURN COALESCE(ret, NULL);
END //

-- view_check_option_is ( schema, view )
DROP FUNCTION IF EXISTS view_check_option_is //
CREATE FUNCTION view_check_option_is(sname VARCHAR(64), vname VARCHAR(64), copt VARCHAR(8), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('View ', quote_ident(sname), '.', quote_ident(vname),
      ' should have Check Option ', qv(copt));
  END IF;

  IF NOT _has_view(sname, vname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag (CONCAT('    View ', quote_ident(sname), '.', quote_ident(vname),
        ' does not exist')));
  END IF;

  RETURN eq(_view_check_option(sname, vname), copt, description);
END //


/****************************************************************************/

-- IS_UPDATABLE
-- { NO | YES }

DROP FUNCTION IF EXISTS _view_is_updatable //
CREATE FUNCTION _view_is_updatable(sname VARCHAR(64), vname VARCHAR(64))
RETURNS VARCHAR(3)
BEGIN
  DECLARE ret VARCHAR(3);

  SELECT `is_updatable` INTO ret
  FROM `information_schema`.`views`
  WHERE `table_schema` = sname
  AND `table_name` = vname;

  RETURN COALESCE(ret, NULL);
END //

-- This probably should be called is_updatable_is() to be consistent
-- but that would sound silly
DROP FUNCTION IF EXISTS view_is_updatable //
CREATE FUNCTION view_is_updatable(sname VARCHAR(64), vname VARCHAR(64), updl VARCHAR(3), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('View ', quote_ident(sname), '.', quote_ident(vname),
    ' should have Is Updatable ', qv(updl));
  END IF;

  IF NOT _has_view(sname, vname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag (CONCAT('    View ', quote_ident(sname), '.', quote_ident(vname),
        ' does not exist')));
  END IF;

  RETURN eq(_view_is_updatable(sname, vname), updl, description);
END //


/****************************************************************************/

-- DEFINER

DROP FUNCTION IF EXISTS _view_definer //
CREATE FUNCTION _view_definer(sname VARCHAR(64), vname VARCHAR(64))
RETURNS VARCHAR(93)
BEGIN
  DECLARE ret VARCHAR(93);

  SELECT `definer` INTO ret
  FROM `information_schema`.`views`
  WHERE `table_schema` = sname
  AND `table_name` = vname;

  RETURN COALESCE(ret, NULL);
END //

DROP FUNCTION IF EXISTS view_definer_is //
CREATE FUNCTION view_definer_is(sname VARCHAR(64), vname VARCHAR(64), dfnr VARCHAR(93), description TEXT)
RETURNS TEXT
BEGIN
  IF description = '' THEN
    SET description = CONCAT('View ',
       quote_ident(sname), '.', quote_ident(vname), ' should have Definer ', qv(dfnr));
  END IF;

  IF NOT _has_view(sname, vname) THEN
    RETURN CONCAT(ok(FALSE, description), '\n',
      diag (CONCAT('    View ', quote_ident(sname), '.', quote_ident(vname),
        ' does not exist')));
  END IF;

  RETURN eq(_view_definer(sname, vname), dfnr, description);
END //


/****************************************************************************/
-- Check appropriate views are defined 

DROP FUNCTION IF EXISTS _missing_views //
CREATE FUNCTION _missing_views(sname VARCHAR(64))
RETURNS TEXT
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(quote_ident(ident)) INTO ret
  FROM 
       (
          SELECT `ident`
          FROM `idents1`
          WHERE `ident` NOT IN
            (
              SELECT `table_name`
              FROM `information_schema`.`tables`
              WHERE `table_schema` = sname
              AND `table_type` = 'VIEW'
            )
        ) msng;

  RETURN COALESCE(ret, '');
END //

DROP FUNCTION IF EXISTS _extra_views //
CREATE FUNCTION _extra_views(sname VARCHAR(64))
RETURNS TEXT
BEGIN
  DECLARE ret TEXT;

  SELECT GROUP_CONCAT(quote_ident(`ident`)) INTO ret
  FROM 
    (
      SELECT `table_name` AS `ident`
      FROM `information_schema`.`tables`
      WHERE `table_schema` = sname
      AND `table_type` = 'VIEW'
      AND `table_name` NOT IN 
        (
          SELECT `ident`
          FROM `idents2`
        )
    ) xtra;

  RETURN COALESCE(ret, '');
END //


DROP FUNCTION IF EXISTS views_are //
CREATE FUNCTION views_are(sname VARCHAR(64), want TEXT, description TEXT)
RETURNS TEXT
BEGIN
  DECLARE sep       CHAR(1) DEFAULT ',';
  DECLARE seplength INTEGER DEFAULT CHAR_LENGTH(sep);

  IF description = '' THEN
    SET description = CONCAT('schema ', quote_ident(sname),
      ' should have the correct Views');
  END IF;

  SET want = _fixCSL(want);

  IF want IS NULL THEN
    RETURN CONCAT(ok(FALSE,description),'\n',
      diag(CONCAT('Invalid character in comma separated list of expected schemas\n',
                  'Identifier must not contain NUL Byte or extended characters (> U+10000)')));
  END IF;

  IF NOT _has_schema( sname ) THEN
    RETURN CONCAT(ok(FALSE,description),'\n',
      diag(CONCAT('    Schema ', quote_ident(sname), 'does not exist')));
  END IF;

  DROP TEMPORARY TABLE IF EXISTS idents1;
  CREATE TEMPORARY TABLE tap.idents1 (ident VARCHAR(64) PRIMARY KEY)
    ENGINE MEMORY CHARSET utf8 COLLATE utf8_general_ci;
  DROP TEMPORARY TABLE IF EXISTS idents2;
  CREATE TEMPORARY TABLE tap.idents2 (ident VARCHAR(64) PRIMARY KEY)
    ENGINE MEMORY CHARSET utf8 COLLATE utf8_general_ci;

  WHILE want != '' > 0 DO
    SET @val = TRIM(SUBSTRING_INDEX(want, sep, 1));
    SET @val= uqi(@val);
    IF  @val <> '' THEN 
      INSERT IGNORE INTO idents1 VALUE(@val);
      INSERT IGNORE INTO idents2 VALUE(@val);
    END IF;
    SET want = SUBSTRING(want, CHAR_LENGTH(@val) + seplength + 1);
  END WHILE;

  SET @missing = _missing_views( sname );
  SET @extras  = _extra_views( sname);

  RETURN _are('views', @extras, @missing, description);
END //


DELIMITER ;