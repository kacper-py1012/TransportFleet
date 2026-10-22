-- 03_insert_dictionary_data.sql
-- Transport Fleet Database: dictionary tables insert
-- Run after 02_create_dictionary_tables.sql
-- The script can be re-run: existing table contents are deleted first.

USE TransportFleet;
GO

-- Clear existing data. TRUNCATE TABLE also resets the IDENTITY counter, so IDs start from 1 again.
-- Child table first (VehicleModels references VehicleBrands).
TRUNCATE TABLE dbo.VehicleModels;

-- VehicleBrands is referenced by a foreign key (FK_VehicleModels_VehicleBrands),
-- so TRUNCATE is not allowed on it. DELETE is used instead, and the IDENTITY counter
-- is reset manually.
-- RESEED is skipped on a table that has never held any rows (last_value IS NULL),
-- because there RESEED, 0 would make the first ID 0 instead of 1.
DELETE FROM dbo.VehicleBrands;
IF EXISTS(
	SELECT 1 FROM sys.identity_columns
	WHERE object_id = OBJECT_ID (N'dbo.VehicleBrands')
		AND last_value IS NOT NULL
)
	DBCC CHECKIDENT (N'dbo.VehicleBrands', RESEED, 0);

TRUNCATE TABLE dbo.VehicleStatuses;

TRUNCATE TABLE dbo.TrailerTypes;

TRUNCATE TABLE dbo.OrderStatuses;

TRUNCATE TABLE dbo.DrivingCategories;

TRUNCATE TABLE dbo.DriverQualifications;
GO

-- Inserting data into dictionaries

-- 1. Driver qualifications dictionary
INSERT INTO dbo.DriverQualifications(DriverQualificationName)
VALUES (N'Code 95'), (N'Tachograph Card'), (N'ADR'), (N'Forklift License'), (N'Crane Operator'), (N'Oversize Load Transport');
GO

-- 2. Driving categories dictionary
INSERT INTO dbo.DrivingCategories(DrivingCategoryName)
VALUES (N'C'), (N'C+E');
GO

-- 3. Order statuses dictionary
INSERT INTO dbo.OrderStatuses(OrderStatusName)
VALUES (N'New'), (N'Assigned'), (N'In Progress'), (N'Completed'), (N'Cancelled');
GO

-- 4. Trailer types dictionary
INSERT INTO dbo.TrailerTypes(TrailerTypeName)
VALUES (N'Curtainsider'), (N'Refrigerated'), (N'Box'), (N'Flatbed'), (N'Tanker'), (N'Tipper');
GO

-- 5. Vehicle statuses dictionary
INSERT INTO dbo.VehicleStatuses(VehicleStatusName)
VALUES (N'Available'), (N'On Route'), (N'In Service'), (N'Out of Service');
GO

-- 6. Vehicle brands dictionary
INSERT INTO dbo.VehicleBrands(VehicleBrandName)
VALUES (N'Volvo'), (N'DAF'), (N'Mercedes-Benz');
GO

-- 7. Vehicle models dictionary
-- Brand names are used instead of IDs: the JOIN below looks up VehicleBrandID by name.
INSERT INTO dbo.VehicleModels (VehicleBrandID, VehicleModelName)
SELECT b.VehicleBrandID, v.ModelName
FROM (VALUES
    (N'Volvo', N'FH'),
    (N'Volvo', N'FH16'),
    (N'Volvo', N'FM'),
    (N'DAF', N'XF'),
    (N'DAF', N'XG'),
    (N'DAF', N'CF'),
    (N'Mercedes-Benz', N'Actros'),
    (N'Mercedes-Benz', N'Arocs'),
    (N'Mercedes-Benz', N'Atego')
) AS v (BrandName, ModelName)
-- Match each brand name to its ID in VehicleBrands
JOIN dbo.VehicleBrands AS b
    ON b.VehicleBrandName = v.BrandName;
GO