
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CopierUneSource]') AND type in (N'P', N'PC'))
DROP PROCEDURE CopierUneSource
GO

CREATE PROCEDURE CopierUneSource(
	@IDSourceTarget INT
)
AS
BEGIN
	DECLARE 
	@SourceDatabase VARCHAR(250)
	,@TargetDatabase VARCHAR(250)
	,@TargetInstance INT
	,@HasError BIT


	-- TODO Prendre en compte la table TPropagation
	-- TODO Pour éviter les conflits synonym utiliser infostatus, cf. Gestion individuhistory 
	
	SET @HasError = 0

	SELECT @SourceDatabase = [SourceDatabase],@TargetDatabase=TargetDatabase,@TargetInstance=Instance
	FROM SourceTarget
	WHERE ID=@IDSourceTarget

	print ' instance ' + convert(varchar,@TargetInstance)
	

	DECLARE @cur_SQL NVARCHAR(MAX)
	SET @cur_SQL = 'IF EXISTS (SELECT * FROM sys.synonyms WHERE name = ''SysColonne'')  drop synonym SysColonne ; CREATE SYNONYM SysColonne FOR ' + replace(@SourceDatabase,'dbo.','sys.') + 'columns'
	print @cur_SQL
	exec sp_executesql @cur_SQL

	SET @cur_SQL = 'IF EXISTS (SELECT * FROM sys.synonyms WHERE name = ''SysObject'')  drop synonym SysObject ; CREATE SYNONYM SysObject FOR ' + replace(@SourceDatabase,'dbo.','sys.') + 'objects'
	print @cur_SQL
	exec sp_executesql @cur_SQL

	DECLARE @TableName VARCHAR(250)
	,@TabidName VARCHAR(250)
	,@TypeObject [varchar](50)
	,@IdObject [varchar](50)

	DECLARE c_table CURSOR FOR
		select [Name] ,[IdNamere] ,[TypeObject],idObject
		FROM TableACopier T JOIN [SourceTarget_Table] S ON t.ID = S.fk_TableACopier
		WHERE S.[fk_SourceTarget] = @IDSourceTarget
		ORDER by [OrdreExecution]


	OPEN c_table   
	FETCH NEXT FROM c_table INTO @TableName, @TabidName , @TypeObject,@IdObject

	WHILE @@FETCH_STATUS = 0   
	BEGIN   
		-- TODO Gérer les exceptions
		BEGIN TRY
			BEGIN TRAN

			print 'Traitement de la table '+ @TableName + ' Type: ' + @TypeObject

			IF OBJECT_ID('tempdb..#IdToUpdate') IS NOT NULL
			DROP TABLE #IdToUpdate

			CREATE TABLE #IdToUpdate(ID INT,IDObject INT )

			DECLARE @SQLOld nvarchar(max)
			,@SQLNew nvarchar(max)
			,@SQLFinalUpdate nvarchar(max)
			,@SQLInsert nvarchar(max)
			,@SQLSelectinInsert nvarchar(max)

			SET @SQLOld='SELECT '
			SET @SQLNew='SELECT '
			SET @SQLFinalUpdate='UPDATE OLd SET '
			SET @SQLInsert = 'SET IDENTITY_INSERT ' +  @TargetDatabase + @TableName + ' ON; INSERT INTO  ' + @TargetDatabase + @TableName + '(' + @TabidName 
			SET @SQLSelectinInsert=@TabidName


			SELECT @SQLOld = @SQLOld + c.name + ',' 
			,@SQLNew=@SQLNew+c.name + ',' 
			,@SQLFinalUpdate=CASE WHEN c.name = @TabidName THEN @SQLFinalUpdate ELSE @SQLFinalUpdate + c.name + ' = New.' + c.name + ','    END
			,@SQLInsert = CASE WHEN c.name = @TabidName THEN @SQLInsert ELSE @SQLInsert + ',' + c.name END
			,@SQLSelectinInsert = CASE WHEN c.name = @TabidName THEN @SQLSelectinInsert ELSE @SQLSelectinInsert + ',' + c.name END
			FROM SysColonne c JOIN SysObject o ON c.object_id = o.object_id 
			WHERE o.name = @TableName and o.type='U'
			and c.system_type_id not in (35)


			SET @SQLOld = @SQLOld +'#FROM ' + @TargetDatabase +  @TableName 
			SET @SQLOld = replace(@SQLOld,',#FROM',' FROM')

			SET @SQLNew = @SQLNew +'#FROM ' + @SourceDatabase +  @TableName 
			SET @SQLNew = replace(@SQLNew,',#FROM',' FROM')


			SET @cur_SQL = 'SELECT ' + @TabidName + ',' + @IdObject + '  FROM (' + @SQLNew  + ' EXCEPT ' + @SQLOld + ') E'
			INSERT INTO #IdToUpdate
			exec sp_executesql @cur_SQL
			print @cur_SQL


			--select @TableName
			--select @TypeObject

			

			--select * from #IdToUpdate

			-- On supprime les ID des objets qui ont comme première règle qui match un valeur de propagation à 0
			DELETE from #IdToUpdate 
			where ID in (
						select ID from
						(SELECT row_number() over(partition by i.id order by [Priority]) nb,i.ID,p.propagation 
						from [TPropagation] P LEFT JOIN #IdToUpdate I ON (i.IDObject = [Source_ID] or [Source_ID] =-1)
						where (P.[Instance] = @TargetInstance or P.[Instance] =-1) and (p.[TypeObject] = @TypeObject or p.typeobject IS NULL)
						) P where p.nb =1 and p.propagation=0
			)		
			
			
			
			
			--select * from #IdToUpdate
			




			SET @SQLFinalUpdate = @SQLFinalUpdate + '#FROM  ' + @TargetDatabase +  @TableName + ' Old  JOIN ' + @SourceDatabase +  @TableName + ' New ON Old.' +  @TabidName + '= New.' +  @TabidName
			SET @SQLFinalUpdate = @SQLFinalUpdate + ' WHERE Old.' + @TabidName + ' IN (SELECT  ID FROM #IdToUpdate) ' 

			SET @SQLFinalUpdate = replace(@SQLFinalUpdate,',#FROM',' FROM')


			-- TODO Gérer les suppressions ???????
			print @SQLFinalUpdate
			exec sp_executesql @SQLFinalUpdate
		


			SET @SQLInsert = @SQLInsert + ') select ' + @SQLSelectinInsert+ ' FROM ' + @SourceDatabase + @TableName + ' New where ' + @TabidName + ' not in (select ' + @TabidName + ' FROM ' + @TargetDatabase + @TableName + ') AND  New.' + @TabidName + ' IN (SELECT  ID FROM #IdToUpdate)  ;SET IDENTITY_INSERT ' +  @TargetDatabase + @TableName + ' OFF '
			print @SQLInsert

			exec sp_executesql @SQLInsert
			commit tran
		END TRY
		BEGIN CATCH
			
			SET @HasError  =1
			ROLLBACK TRAN;
			print 'Traitement erreur sur objet ' + @TypeObject
			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;
			
			SELECT 
				@ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();
				-- TODO INSERTION DANS TMESSAGE ...
		END CATCH	

		FETCH NEXT FROM c_table INTO @TableName, @TabidName  ,@TypeObject,@IdObject

	END

	CLOSE c_table   
	DEALLOCATE c_table

	IF (@HasError=1)
	BEGIN 
		RAISERROR ('Error during copy, see TLOG_MESSAGES for details' , -- Message text.
					   15, -- Severity.
					   2 -- State.
					   );

	END

END

