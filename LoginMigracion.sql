
SELECT * FROM sys.server_principals where type in ('S','U')

SELECT 'CREATE LOGIN ['++'] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
'


SELECT 'CREATE LOGIN ['+ name +'] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO
' FROM sys.server_principals where type in ('U') and not name like '%NT%'


SELECT 'CREATE LOGIN ['+ name +'] WITH PASSWORD=N''P4$$w0rdBDsqls3rv3r!'', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

ALTER LOGIN ['+ name +'] ENABLE
GO
' FROM sys.server_principals where type in ('S') and not name like '%NT%'
AND is_disabled=0


SELECT * FROM sys.server_principals where type in ('S') and not name like '%NT%'
AND is_disabled=0