-- =============================================
-- MIGRATION: Social Login Support
-- Run this on existing LeafGoDB database
-- =============================================

USE LeafGoDB;
GO

-- 1. PasswordHash → NULL (social login users don't have a password)
ALTER TABLE Users ALTER COLUMN PasswordHash NVARCHAR(500) NULL;
GO

-- 2. PhoneNumber → NULL (social login users enter phone number in step 2)
ALTER TABLE Users ALTER COLUMN PhoneNumber NVARCHAR(20) NULL;
GO

-- 3. Drop and recreate PhoneNumber constraint to allow NULL
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Users_PhoneNumber_VN')
BEGIN
    ALTER TABLE Users DROP CONSTRAINT CK_Users_PhoneNumber_VN;
END
GO

ALTER TABLE Users
ADD CONSTRAINT CK_Users_PhoneNumber_VN
CHECK (
    PhoneNumber IS NULL
    OR (PhoneNumber LIKE '0%' AND LEN(PhoneNumber) = 10 AND PhoneNumber NOT LIKE '%[^0-9]%')
);
GO

-- 4. Drop and recreate unique index on PhoneNumber to exclude NULLs
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_Users_Phone_Active' AND object_id = OBJECT_ID('Users'))
BEGIN
    DROP INDEX UX_Users_Phone_Active ON Users;
END
GO

CREATE UNIQUE INDEX UX_Users_Phone_Active
ON Users (PhoneNumber)
WHERE IsDeleted = 0 AND PhoneNumber IS NOT NULL;
GO

-- 5. Create UserExternalLogins table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'UserExternalLogins')
BEGIN
    CREATE TABLE UserExternalLogins (
        Id UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId UNIQUEIDENTIFIER NOT NULL,
        Provider NVARCHAR(50) NOT NULL,         -- 'Google', 'Facebook'
        ProviderKey NVARCHAR(255) NOT NULL,     -- Provider's unique user ID
        Email NVARCHAR(255) NULL,               -- Email from provider
        DisplayName NVARCHAR(255) NULL,         -- Display name from provider
        AvatarUrl NVARCHAR(500) NULL,           -- Avatar URL from provider
        CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
        FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_UserExternalLogins_Provider UNIQUE (Provider, ProviderKey),
        INDEX IX_UserExternalLogins_UserId (UserId)
    );
END
GO

PRINT 'Migration completed: Social Login support added successfully.';
GO
