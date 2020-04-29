SELECT
distinct so.name
--,sc.text
FROM
sysobjects so
INNER JOIN syscomments sc ON so.id = sc.id
WHERE
--so.type = 'P' AND
sc.text LIKE '%SELECT *%'


SELECT distinct
so.name
--,sc.text
FROM
sysobjects so
INNER JOIN syscomments sc ON so.id = sc.id
WHERE
--so.type = 'P' AND
sc.text LIKE '%SELECT *%'
