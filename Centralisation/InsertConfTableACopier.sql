

DELETE FROM [SourceTarget_Table]
DELETE FROM [TableACopier]
DELETE FROM [SourceTarget]

INSERT INTO [dbo].[SourceTarget]
           ([SourceDatabase]
           ,[TargetDatabase])
		   VALUES ('NARC_TRACK_MACQ_New.dbo.','NARC_TRACK_MACQ.dbo.')



INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TProtocole'
           ,'TPro_pk_id'
           ,5)


INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TObservation'
           ,'TObs_pk_id'
           ,10)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TType'
           ,'TTyp_pk_id'
           ,1)

		INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TTTypeBase'
           ,'TTBse_pk_id'
           ,0)
		
		INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('Tunite'
           ,'TUni_pk_id'
           ,0)


		INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TTProtocole'
           ,'TTpro_PK_ID'
           ,0)

		INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TTFrequence'
           ,'TTFre_PK_ID'
           ,0)

		   INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TChampLie'
           ,'TCLie_PK_ID'
           ,0)
		   


		   INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TActivite'
           ,'TAct_PK_ID'
           ,0)

INSERT INTO [dbo].[TableACopier]
           ([Name]
           ,[IdNamere]
           ,[OrdreExecution])
     VALUES
           ('TAsyncProcessList'
           ,'TAPL_PK_ID'
           ,0)


 INSERT INTO [dbo].[SourceTarget_Table]
           ([fk_SourceTarget]
           ,[fk_TableACopier])
		   SELECT s.ID,t.ID FROM TableACopier T JOIN SourceTarget S ON s.SourceDatabase='NARC_TRACK_MACQ_New.dbo.'
		   WHErE t.name in ('TProtocole','TObservation','TType','TTTypeBase','TTProtocole','TTFrequence','TChampLie','TActivite','TAsyncProcessList','Tunite')

		   
 		   
