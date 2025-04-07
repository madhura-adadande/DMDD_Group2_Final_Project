-- Column Encryption Script with Strong Passwords
USE RestaurantDB;
GO


IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE symmetric_key_id = 101)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Str0ng!MasterKey1';
END
GO


IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'CardPaymentKey')
BEGIN
    CREATE SYMMETRIC KEY CardPaymentKey 
    WITH ALGORITHM = AES_256 
    ENCRYPTION BY PASSWORD = 'CardP@ss2024!';
END

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'CustomerKey')
BEGIN
    CREATE SYMMETRIC KEY CustomerKey 
    WITH ALGORITHM = AES_256 
    ENCRYPTION BY PASSWORD = 'Cust0mer$ecure1!';
END

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'StaffKey')
BEGIN
    CREATE SYMMETRIC KEY StaffKey 
    WITH ALGORITHM = AES_256 
    ENCRYPTION BY PASSWORD = 'St@ffKeySafe2!';
END

IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'SupplierKey')
BEGIN
    CREATE SYMMETRIC KEY SupplierKey 
    WITH ALGORITHM = AES_256 
    ENCRYPTION BY PASSWORD = 'Suppl!erStrong3';
END
GO


IF COL_LENGTH('dbo.CARD_PAYMENT', 'EncryptedCardNumber') IS NULL
    ALTER TABLE CARD_PAYMENT ADD EncryptedCardNumber VARBINARY(128);
IF COL_LENGTH('dbo.CARD_PAYMENT', 'EncryptedCVV') IS NULL
    ALTER TABLE CARD_PAYMENT ADD EncryptedCVV VARBINARY(128);
IF COL_LENGTH('dbo.CARD_PAYMENT', 'EncryptedExpirationDate') IS NULL
    ALTER TABLE CARD_PAYMENT ADD EncryptedExpirationDate VARBINARY(128);

IF COL_LENGTH('dbo.CUSTOMER', 'EncryptedFullName') IS NULL
    ALTER TABLE CUSTOMER ADD EncryptedFullName VARBINARY(128);
IF COL_LENGTH('dbo.CUSTOMER', 'EncryptedEmail') IS NULL
    ALTER TABLE CUSTOMER ADD EncryptedEmail VARBINARY(128);
IF COL_LENGTH('dbo.CUSTOMER', 'EncryptedContact') IS NULL
    ALTER TABLE CUSTOMER ADD EncryptedContact VARBINARY(128);
IF COL_LENGTH('dbo.CUSTOMER', 'EncryptedAddress') IS NULL
    ALTER TABLE CUSTOMER ADD EncryptedAddress VARBINARY(256);

IF COL_LENGTH('dbo.STAFF', 'EncryptedFullName') IS NULL
    ALTER TABLE STAFF ADD EncryptedFullName VARBINARY(128);
IF COL_LENGTH('dbo.STAFF', 'EncryptedContactNumber') IS NULL
    ALTER TABLE STAFF ADD EncryptedContactNumber VARBINARY(128);

IF COL_LENGTH('dbo.SUPPLIER', 'EncryptedContactPerson') IS NULL
    ALTER TABLE SUPPLIER ADD EncryptedContactPerson VARBINARY(128);
IF COL_LENGTH('dbo.SUPPLIER', 'EncryptedContactNumber') IS NULL
    ALTER TABLE SUPPLIER ADD EncryptedContactNumber VARBINARY(128);
GO


OPEN SYMMETRIC KEY CardPaymentKey DECRYPTION BY PASSWORD = 'CardP@ss2024!';
UPDATE CARD_PAYMENT
SET 
    EncryptedCardNumber = ENCRYPTBYKEY(KEY_GUID('CardPaymentKey'), CardNumber),
    EncryptedCVV = ENCRYPTBYKEY(KEY_GUID('CardPaymentKey'), CVV),
    EncryptedExpirationDate = ENCRYPTBYKEY(KEY_GUID('CardPaymentKey'), CONVERT(NVARCHAR(10), ExpirationDate));
CLOSE SYMMETRIC KEY CardPaymentKey;

OPEN SYMMETRIC KEY CustomerKey DECRYPTION BY PASSWORD = 'Cust0mer$ecure1!';
UPDATE CUSTOMER
SET 
    EncryptedFullName = ENCRYPTBYKEY(KEY_GUID('CustomerKey'), FullName),
    EncryptedEmail = ENCRYPTBYKEY(KEY_GUID('CustomerKey'), Email),
    EncryptedContact = ENCRYPTBYKEY(KEY_GUID('CustomerKey'), Contact),
    EncryptedAddress = ENCRYPTBYKEY(KEY_GUID('CustomerKey'), Address);
CLOSE SYMMETRIC KEY CustomerKey;

OPEN SYMMETRIC KEY StaffKey DECRYPTION BY PASSWORD = 'St@ffKeySafe2!';
UPDATE STAFF
SET 
    EncryptedFullName = ENCRYPTBYKEY(KEY_GUID('StaffKey'), FullName),
    EncryptedContactNumber = ENCRYPTBYKEY(KEY_GUID('StaffKey'), ContactNumber);
CLOSE SYMMETRIC KEY StaffKey;

OPEN SYMMETRIC KEY SupplierKey DECRYPTION BY PASSWORD = 'Suppl!erStrong3';
UPDATE SUPPLIER
SET 
    EncryptedContactPerson = ENCRYPTBYKEY(KEY_GUID('SupplierKey'), ContactPerson),
    EncryptedContactNumber = ENCRYPTBYKEY(KEY_GUID('SupplierKey'), ContactNumber);
CLOSE SYMMETRIC KEY SupplierKey;
GO
