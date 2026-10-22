-- 05_insert_sample_data.sql
-- Transport Fleet Database: sample data for the main tables
-- Run after 04_create_main_tables.sql
-- The script can be re-run: existing table contents are deleted first.
 
USE TransportFleet;
GO
 
-- Clear existing data (child tables first, same order as the DROP block in 04)
 
-- Nothing references these tables and they have no IDENTITY column, so TRUNCATE is allowed
TRUNCATE TABLE dbo.OrderRequiredQualifications;
TRUNCATE TABLE dbo.TrailerTypeRequiredQualifications;
 
-- Orders is referenced by a foreign key, so TRUNCATE is not allowed. DELETE is used instead.
-- The IDENTITY counter is reset only if the table was used before:
-- on a fresh table RESEED, 0 would make the first ID 0 instead of 1.
DELETE FROM dbo.Orders;
IF EXISTS (
	SELECT 1
	FROM sys.identity_columns
	WHERE object_id = OBJECT_ID(N'dbo.Orders')
		AND last_value IS NOT NULL
)
	DBCC CHECKIDENT (N'dbo.Orders', RESEED, 0);
 
-- Link table, not referenced by anything
TRUNCATE TABLE dbo.DriverQualificationAssignments;
 
-- Same pattern as Orders: DELETE and a conditional RESEED
DELETE FROM dbo.Drivers;
IF EXISTS (
	SELECT 1
	FROM sys.identity_columns
	WHERE object_id = OBJECT_ID(N'dbo.Drivers')
		AND last_value IS NOT NULL
)
	DBCC CHECKIDENT (N'dbo.Drivers', RESEED, 0);
 
DELETE FROM dbo.Trailers;
IF EXISTS (
	SELECT 1
	FROM sys.identity_columns
	WHERE object_id = OBJECT_ID(N'dbo.Trailers')
		AND last_value IS NOT NULL
)
	DBCC CHECKIDENT (N'dbo.Trailers', RESEED, 0);
 
DELETE FROM dbo.Vehicles;
IF EXISTS (
	SELECT 1
	FROM sys.identity_columns
	WHERE object_id = OBJECT_ID(N'dbo.Vehicles')
		AND last_value IS NOT NULL
)
	DBCC CHECKIDENT (N'dbo.Vehicles', RESEED, 0);
GO

-- 1. Inserting drivers data into drivers table
INSERT INTO dbo.Drivers (FirstName, LastName, HireDate, DrivingCategoryID)
SELECT d.FirstName, d.LastName, d.HireDate, dc.DrivingCategoryID
FROM (VALUES
	(N'Jan', N'Kowalski', '2019-03-01', N'C+E'),
	(N'Anna', N'Nowak', '2020-06-15', N'C+E'),
	(N'Piotr', N'Wiśniewski', '2021-09-01', N'C'),
	(N'Marek', N'Zieliński', '2018-01-10', N'C+E'),
	(N'Katarzyna', N'Lewandowska', '2022-04-20', N'C'),
	(N'Tomasz', N'Wójcik', '2023-02-01', N'C+E')
) AS d (FirstName, LastName, HireDate, CategoryName)
JOIN dbo.DrivingCategories AS dc
	ON dc.DrivingCategoryName = d.CategoryName;
GO

-- 2. Inserting vehicles data into vehicle table
-- Brand, model and status are given by name; the JOINs replace them with IDs.
-- Brand is only used to find the right model and is not stored in Vehicles.
INSERT INTO dbo.Vehicles (RegistrationNumber, VIN, VehicleModelID, VehicleStatusID, ProductionYear)
SELECT v.RegistrationNumber, v.VIN, vm.VehicleModelID, vs.VehicleStatusID, v.ProductionYear
FROM (VALUES
	(N'WPL 10001', N'VIN00000000000001', N'Volvo', N'FH', N'Available', 2021),
	(N'WPL 10002', N'VIN00000000000002', N'Volvo', N'FH16', N'On Route', 2022),
	(N'WPL 10003', N'VIN00000000000003', N'DAF', N'XF', N'Available', 2020),
	(N'WPL 10004', N'VIN00000000000004', N'DAF', N'XG', N'In Service', 2023),
	(N'WPL 10005', N'VIN00000000000005', N'Mercedes-Benz', N'Actros', N'On Route', 2022),
	(N'WPL 10006', N'VIN00000000000006', N'Mercedes-Benz', N'Arocs', N'Out of Service', 2019)
) AS v (RegistrationNumber, VIN, VehicleBrandName, VehicleModelName, VehicleStatusName, ProductionYear)
-- Brand is used only to find the right model; it is not stored in Vehicles
JOIN dbo.VehicleBrands AS vb
	ON v.VehicleBrandName = vb.VehicleBrandName
-- Model must belong to that brand (a model name is unique only within a brand)
JOIN dbo.VehicleModels AS vm
	ON v.VehicleModelName = vm.VehicleModelName
	AND vm.VehicleBrandID = vb.VehicleBrandID
-- Replace the status name with its ID
JOIN dbo.VehicleStatuses AS vs
	ON v.VehicleStatusName = vs.VehicleStatusName;
GO

-- 3. Inserting trailers data into trailers table
INSERT INTO dbo.Trailers (RegistrationNumber, TrailerTypeID, ProductionYear)
SELECT t.RegistrationNumber, tt.TrailerTypeID, t.ProductionYear
FROM (VALUES
	(N'WPL T0001', N'Curtainsider', 2021),
	(N'WPL T0002', N'Refrigerated', 2022),
	(N'WPL T0003', N'Box', 2020),
	(N'WPL T0004', N'Flatbed', 2021),
	(N'WPL T0005', N'Tanker', 2023),
	(N'WPL T0006', N'Tipper', 2019)
) AS t (RegistrationNumber, TrailerTypeName, ProductionYear)
JOIN dbo.TrailerTypes AS tt
	ON t.TrailerTypeName = tt.TrailerTypeName;
GO

-- 4. Inserting driver qualification assignments data
INSERT INTO dbo.DriverQualificationAssignments (DriverID, DriverQualificationID, ExpiryDate)
SELECT d.DriverID, dq.DriverQualificationID, dqa.ExpiryDate
FROM (VALUES
	(N'Kowalski', N'Code 95', '2027-05-10'),
	(N'Kowalski', N'Tachograph Card', '2028-02-01'),
	(N'Kowalski', N'ADR', '2026-11-15'),
	(N'Nowak', N'Code 95', '2026-09-30'),
	(N'Nowak', N'Tachograph Card', '2027-08-20'),
	(N'Nowak', N'ADR', '2027-03-01'),
	(N'Nowak', N'Oversize Load Transport', '2027-01-15'),
	(N'Wiśniewski', N'Code 95', '2028-03-12'),
	(N'Wiśniewski', N'Tachograph Card', '2027-11-05'),
	(N'Zieliński', N'Code 95', '2027-10-01'),
	(N'Zieliński', N'Tachograph Card', '2026-12-10'),
	(N'Zieliński', N'Crane Operator', '2028-06-01'),
	(N'Zieliński', N'Forklift License', '2029-01-01'),
	(N'Lewandowska', N'Code 95', '2027-06-30'),
	(N'Lewandowska', N'Tachograph Card', '2027-06-30'),
	(N'Lewandowska', N'Forklift License', '2027-09-15'),
	(N'Wójcik', N'Code 95', '2028-01-20'),
	(N'Wójcik', N'Tachograph Card', '2028-01-20'),
	(N'Wójcik', N'ADR', '2028-05-05')
) AS dqa (LastName, DriverQualificationName, ExpiryDate)
JOIN dbo.Drivers AS d
	ON dqa.LastName = d.LastName
JOIN dbo.DriverQualifications AS dq
	ON dqa.DriverQualificationName = dq.DriverQualificationName;
GO

-- 5. Inserting trailer type required qualifications data
INSERT INTO dbo.TrailerTypeRequiredQualifications (TrailerTypeID, DriverQualificationID)
SELECT tt.TrailerTypeID, dq.DriverQualificationID
FROM (VALUES
	(N'Tanker', N'ADR'),
	(N'Flatbed', N'Oversize Load Transport')
) AS ttrq (TrailerTypeName, DriverQualificationName)
JOIN dbo.TrailerTypes AS tt
	ON ttrq.TrailerTypeName = tt.TrailerTypeName
JOIN dbo.DriverQualifications AS dq
	ON ttrq.DriverQualificationName = dq.DriverQualificationName;
GO

-- 6. Inserting orders data into orders table
-- Status, driver, vehicle and trailer are given by name or registration number;
-- the JOINs below replace them with IDs.
-- NULL in the driver, vehicle and trailer columns means the order is not assigned yet.
INSERT INTO dbo.Orders (OrderStatusID, PickupLocation, DeliveryLocation, PickupDate, DeliveryDate, DriverID, VehicleID, TrailerID)
SELECT ord.OrderStatusID, o.PickupLocation, o.DeliveryLocation, o.PickupDate, o.DeliveryDate, d.DriverID, veh.VehicleID, t.TrailerID
FROM (VALUES
	(N'Completed', N'Płock', N'Gdańsk', '2026-10-05', '2026-10-06', N'Kowalski', N'WPL 10001', N'WPL T0001'),
	(N'In Progress', N'Poznań', N'Berlin', '2026-10-18', '2026-10-20', N'Wójcik', N'WPL 10002', N'WPL T0002'),
	(N'In Progress', N'Warszawa', N'Kraków', '2026-10-19', '2026-10-19', N'Zieliński', N'WPL 10005', N'WPL T0003'),
	(N'Assigned', N'Łódź', N'Wrocław', '2026-10-22', '2026-10-23', N'Wiśniewski', N'WPL 10003', N'WPL T0003'),
	(N'Assigned', N'Gdynia', N'Hamburg', '2026-10-25', '2026-10-27', N'Kowalski', N'WPL 10001', N'WPL T0005'),
	(N'New', N'Katowice', N'Praga', '2026-11-02', '2026-11-03', NULL, NULL, NULL),
	(N'New', N'Szczecin', N'Rostock', '2026-11-05', '2026-11-05', NULL, NULL, NULL),
	(N'Cancelled', N'Lublin', N'Rzeszów', '2026-10-12', '2026-10-13', NULL, NULL, NULL)
) AS o (OrderStatusName, PickupLocation, DeliveryLocation, PickupDate, DeliveryDate, LastName, VehicleRegistrationNumber, TrailerRegistrationNumber)
-- Every order has a status, so a regular JOIN is enough
JOIN dbo.OrderStatuses AS ord
	ON o.OrderStatusName = ord.OrderStatusName
-- LEFT JOIN keeps orders that have no driver yet (NULL).
-- A regular JOIN would drop them, because NULL does not match any last name.
-- Note: a typo in the last name also gives NULL instead of an error.
LEFT JOIN dbo.Drivers AS d
	ON o.LastName = d.LastName
-- Same as above for the vehicle: unassigned orders are kept with a NULL VehicleID
LEFT JOIN dbo.Vehicles AS veh
	ON o.VehicleRegistrationNumber = veh.RegistrationNumber
-- Same as above for the trailer: unassigned orders are kept with a NULL TrailerID
LEFT JOIN dbo.Trailers AS t
	ON o.TrailerRegistrationNumber = t.RegistrationNumber;
GO

-- 7. Inserting order required qualifications data into order required qualifications table
-- An order has no unique name, so it is found by pickup location and pickup date.
INSERT INTO dbo.OrderRequiredQualifications (OrderID, DriverQualificationID)
SELECT o.OrderID, dq.DriverQualificationID
FROM (VALUES
	(N'Szczecin', '2026-11-05', N'Oversize Load Transport')
) AS orq (PickupLocation, PickupDate, DriverQualificationName)
JOIN dbo.Orders AS o
	ON o.PickupLocation = orq.PickupLocation
	AND o.PickupDate = orq.PickupDate
JOIN dbo.DriverQualifications AS dq
	ON dq.DriverQualificationName = orq.DriverQualificationName;
GO