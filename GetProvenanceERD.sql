﻿CREATE FUNCTION GetProvenance() RETURNS VARCHAR(20)
AS
BEGIN
	RETURN db_name()
END