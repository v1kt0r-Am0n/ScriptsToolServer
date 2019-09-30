use AppMovilAutenticacion

ALTER TABLE [dbo].[TResgistroUsuario] DROP CONSTRAINT [FK_TResgistroUsuario_RPregunta]
GO
ALTER TABLE [dbo].[TResgistroUsuario] DROP CONSTRAINT [FK_TResgistroUsuario_RPregunta1]
GO
ALTER TABLE [dbo].[TResgistroUsuario] DROP CONSTRAINT [FK_TResgistroUsuario_RPregunta2]
GO
ALTER TABLE [dbo].[TResgistroUsuario] DROP CONSTRAINT [PK_TResgistroUsuario]
GO
DROP INDEX [IX_TResgistroUsuarioDocumentoTipoDoc] ON [dbo].[TResgistroUsuario]
GO
DROP INDEX [IX_TResgistroUsuarioUsuarioClave] ON [dbo].[TResgistroUsuario]
GO
ALTER TABLE [dbo].[TResgistroUsuario] ALTER COLUMN [Respuesta1] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
ALTER TABLE [dbo].[TResgistroUsuario] ALTER COLUMN [IdPregunta1] [int] NULL
GO
ALTER TABLE [dbo].[TResgistroUsuario] ALTER COLUMN [IdPregunta3] [int] NULL
GO
ALTER TABLE [dbo].[TResgistroUsuario] ALTER COLUMN [Respuesta3] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
ALTER TABLE [dbo].[TResgistroUsuario] ALTER COLUMN [Respuesta2] [varchar] (300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
ALTER TABLE [dbo].[TResgistroUsuario] ALTER COLUMN [IdPregunta2] [int] NULL
GO
ALTER TABLE [dbo].[TResgistroUsuario] ADD CONSTRAINT [PK_TResgistroUsuario] PRIMARY KEY CLUSTERED
	(
		[IdRegistroUsuario] ASC
	) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY  = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TResgistroUsuario] ADD CONSTRAINT [FK_TResgistroUsuario_RPregunta2] FOREIGN KEY
	(
		[IdPregunta2]
	)
	REFERENCES [dbo].[RPregunta]
	(
		[IdPregunta]
	)
GO
ALTER TABLE [dbo].[TResgistroUsuario] ADD CONSTRAINT [FK_TResgistroUsuario_RPregunta1] FOREIGN KEY
	(
		[IdPregunta1]
	)
	REFERENCES [dbo].[RPregunta]
	(
		[IdPregunta]
	)
GO
ALTER TABLE [dbo].[TResgistroUsuario] ADD CONSTRAINT [FK_TResgistroUsuario_RPregunta3] FOREIGN KEY
	(
		[IdPregunta3]
	)
	REFERENCES [dbo].[RPregunta]
	(
		[IdPregunta]
	)
GO


USE [AppMovilTarjetaCredito]
GO

ALTER TABLE [dbo].[TRegistroContactenos] ADD 
[Cedula] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
[Celular] [varchar] (30) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
GO
