SET NOCOUNT ON ;
DECLARE @CFG_BACKUP_PATH NVARCHAR(256)
DECLARE @CFG_DAYS_DELETE INT
SET @CFG_BACKUP_PATH = 'D:\BackupData'
SET @CFG_DAYS_DELETE = 10
DECLARE @Today DATETIME
DECLARE @TodayName CHAR(8)
SET @Today = GETDATE()
SET @TodayName = CONVERT(CHAR(8), @Today, 112)
DECLARE @id INT
DECLARE @name VARCHAR(50)
DECLARE @path VARCHAR(256)
DECLARE @cmd VARCHAR(256)
DECLARE @TempDir VARCHAR(256)
SET @TempDir = @CFG_BACKUP_PATH + CHAR(92) + CONVERT(VARCHAR(256), NEWID())
SET @cmd = 'md ' + @TempDir
EXEC xp_cmdshell @cmd, no_output
DECLARE @dbList TABLE
    (dbno INT IDENTITY,
     dbname NVARCHAR(256))
INSERT  INTO @dbList ( dbname )
        SELECT  name
        FROM    master.dbo.sysdatabases
        WHERE   ( name NOT IN ( 'tempdb' ) )
            AND DATABASEPROPERTYEX(name, 'Status') = 'ONLINE'
SELECT  @id = dbno,
      @name = dbname
FROM    @dbList
WHERE   dbno = 1
WHILE @@ROWCOUNT = 1
    BEGIN
        PRINT N'++ Sao luu Database: ' + @name
        SET @path = @TempDir + CHAR(92) + @name + '.bak'       
        BACKUP DATABASE @name TO DISK = @path
        SELECT  @id = dbno,
            @name = dbname
        FROM    @dbList
        WHERE   dbno = @id + 1
    END
PRINT N'++ Nén thu m?c: ' + @TempDir
SET @cmd = 'del /f /q ' + @CFG_BACKUP_PATH + CHAR(92) + @TodayName + '.ZIP'
EXEC xp_cmdshell @cmd, no_output
DECLARE @Count INT
DECLARE @StartTime DATETIME
SET @StartTime = GETDATE()
SET @cmd = @CFG_BACKUP_PATH + '\7za.exe a -bd -y -tzip -mx2 '
SET @cmd = @cmd + @CFG_BACKUP_PATH + CHAR(92) + @TodayName + '.ZIP ' + @TempDir + '\*.bak"'
EXEC xp_cmdshell @cmd, no_output
SET @Count = DATEDIFF(second, @StartTime, GETDATE())
PRINT N'++ Th?i gian nén: ' + CONVERT(VARCHAR, @Count) + ' giây'
SET @Count = DATEDIFF(second, @Today, GETDATE())
PRINT N'++ Th?i gian x? lý: ' + CONVERT(VARCHAR, @Count) + ' giây'
SET @cmd = 'rd /s /q ' + @TempDir
EXEC xp_cmdshell @cmd, no_output
DECLARE @OlderDateName CHAR(8)
SET @OlderDateName = CONVERT(CHAR(8), @Today - @CFG_DAYS_DELETE, 112)
CREATE TABLE #delList
    (subdirectory VARCHAR(256),
    depth INT,
    [file] BIT)
INSERT  INTO #delList
      EXEC xp_dirtree @CFG_BACKUP_PATH, 1, 1
DELETE  #delList
WHERE   RIGHT(subdirectory, 4) <> '.ZIP'
SELECT  @Count = COUNT(1)
FROM    #delList
PRINT N'++ S? phiên b?n hi?n có trong thu m?c: ' + CONVERT(NVARCHAR, @Count)    
SELECT TOP 1
      @name = subdirectory
FROM    #delList
WHERE   LEN(subdirectory) = 12
      AND RIGHT(subdirectory, 4) = '.ZIP'
      AND REPLACE(subdirectory, '.ZIP', '') < @OlderDateName
WHILE ( @@ROWCOUNT = 1 )
    BEGIN
        PRINT N'++ Xóa phiên b?n: ' + @name
        SET @cmd = 'del /f /q ' + @CFG_BACKUP_PATH + CHAR(92) + @name
        EXEC xp_cmdshell @cmd, no_output        
        DELETE  #delList
        WHERE   subdirectory = @name        
        SELECT TOP 1
             @name = subdirectory
        FROM  #delList
        WHERE LEN(subdirectory) = 12
            AND RIGHT(subdirectory, 4) = '.ZIP'
            AND REPLACE(subdirectory, '.ZIP', '') < @OlderDateName
    END 
DROP TABLE #delList
PRINT N'++ Hoàn t?t.'
PRINT ''

DECLARE @RC int

-- TODO: Set parameter values here.

EXECUTE @RC = [dbo].[PRC_DBREINDEX_VTL1]