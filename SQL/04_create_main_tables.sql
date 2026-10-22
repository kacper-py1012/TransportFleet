-- 04_create_main_tables.sql
-- Transport Fleet Database: creating main tables
-- Run after 03_insert_dictionary_data.sql
-- The script can be re-run: existing tables are deleted first.

USE TransportFleet;
GO

-- Drop existing tables (child tables first).
IF OBJECT_ID(N'dbo.OrderRequiredQualifications', N'U') IS NOT NULL DROP TABLE dbo.OrderRequiredQualifications;
IF OBJECT_ID(N'dbo.TrailerTypeRequiredQualifications', N'U') IS NOT NULL DROP TABLE dbo.TrailerTypeRequiredQualifications;
IF OBJECT_ID(N'dbo.Orders', N'U') IS NOT NULL DROP TABLE dbo.Orders;
IF OBJECT_ID(N'dbo.DriverQualificationAssignments', N'U') IS NOT NULL DROP TABLE dbo.DriverQualificationAssignments;
IF OBJECT_ID(N'dbo.Drivers', N'U') IS NOT NULL DROP TABLE dbo.Drivers;
IF OBJECT_ID(N'dbo.Trailers', N'U') IS NOT NULL DROP TABLE dbo.Trailers;
IF OBJECT_ID(N'dbo.Vehicles', N'U') IS NOT NULL DROP TABLE dbo.Vehicles;
GO

-- 1. Creating vehicles table
CREATE TABLE dbo.Vehicles (
	VehicleID INT IDENTITY(1,1) NOT NULL,
	RegistrationNumber NVARCHAR(15) NOT NULL,
	VIN CHAR(17) NOT NULL,
	VehicleModelID INT NOT NULL,
	VehicleStatusID INT NOT NULL,
	ProductionYear INT NOT NULL,
	CONSTRAINT PK_Vehicles PRIMARY KEY (VehicleID),
	CONSTRAINT UQ_Vehicles_RegistrationNumber UNIQUE (RegistrationNumber),
	CONSTRAINT UQ_Vehicles_VIN UNIQUE (VIN),
	CONSTRAINT FK_Vehicles_VehicleModelID FOREIGN KEY (VehicleModelID) REFERENCES dbo.VehicleModels(VehicleModelID),
	CONSTRAINT FK_Vehicles_VehicleStatusID FOREIGN KEY (VehicleStatusID) REFERENCES dbo.VehicleStatuses(VehicleStatusID)
);
GO

-- 2. Creating trailers table
CREATE TABLE dbo.Trailers (
	TrailerID INT IDENTITY(1,1) NOT NULL,
	RegistrationNumber NVARCHAR(15) NOT NULL,
	TrailerTypeID INT NOT NULL,
	ProductionYear INT NOT NULL,
	CONSTRAINT PK_Trailers PRIMARY KEY (TrailerID),
	CONSTRAINT UQ_Trailers_RegistrationNumber UNIQUE (RegistrationNumber),
	CONSTRAINT FK_Trailers_TrailerTypeID FOREIGN KEY (TrailerTypeID) REFERENCES dbo.TrailerTypes(TrailerTypeID)
);
GO

-- 3. Creating drivers table
CREATE TABLE dbo.Drivers (
	DriverID INT IDENTITY(1,1) NOT NULL,
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,
	HireDate DATE NOT NULL,
	DrivingCategoryID INT NOT NULL,
	CONSTRAINT PK_Drivers PRIMARY KEY (DriverID),
	CONSTRAINT FK_Drivers_DrivingCategoryID FOREIGN KEY (DrivingCategoryID) REFERENCES dbo.DrivingCategories(DrivingCategoryID)
);
GO

-- 4. Creating driver qualification assignments table (link table, many-to-many)
-- One row = one qualification held by one driver, with its expiry date.
CREATE TABLE dbo.DriverQualificationAssignments (
	DriverID INT NOT NULL,
	DriverQualificationID INT NOT NULL,
	-- Validity is calculated from this date; no status is stored
	ExpiryDate DATE NOT NULL,
	-- Composite primary key: one driver cannot get the same qualification twice
	-- Primary key made of two columns: the same pair cannot repeat
	CONSTRAINT PK_DriverQualificationAssignments PRIMARY KEY (DriverID, DriverQualificationID),
	-- The driver must exist in Drivers
	CONSTRAINT FK_DriverQualificationAssignments_DriverID FOREIGN KEY (DriverID) REFERENCES dbo.Drivers(DriverID),
	-- The qualification must exist in DriverQualifications
	CONSTRAINT FK_DriverQualificationAssignments_DriverQualificationID FOREIGN KEY (DriverQualificationID) REFERENCES dbo.DriverQualifications(DriverQualificationID)
);
GO

-- 5. Creating orders table
CREATE TABLE dbo.Orders (
	OrderID INT IDENTITY(1,1) NOT NULL,
	OrderStatusID INT NOT NULL,
	PickupLocation NVARCHAR(100) NOT NULL,
	DeliveryLocation NVARCHAR(100) NOT NULL,
	PickupDate DATE NOT NULL,
	DeliveryDate DATE NOT NULL,
	DriverID INT NULL,
	VehicleID INT NULL,
	TrailerID INT NULL,
	CONSTRAINT PK_Orders PRIMARY KEY (OrderID),
	CONSTRAINT FK_Orders_OrderStatusID FOREIGN KEY (OrderStatusID) REFERENCES dbo.OrderStatuses(OrderStatusID),
	CONSTRAINT FK_Orders_DriverID FOREIGN KEY (DriverID) REFERENCES dbo.Drivers(DriverID),
	CONSTRAINT FK_Orders_VehicleID FOREIGN KEY (VehicleID) REFERENCES dbo.Vehicles(VehicleID),
	CONSTRAINT FK_Orders_TrailerID FOREIGN KEY (TrailerID) REFERENCES dbo.Trailers(TrailerID)
);
GO

-- 6. Creating trailer type required qualifications
CREATE TABLE dbo.TrailerTypeRequiredQualifications (
	TrailerTypeID INT NOT NULL,
	DriverQualificationID INT NOT NULL,
	CONSTRAINT PK_TrailerTypeRequiredQualifications PRIMARY KEY (TrailerTypeID, DriverQualificationID),
	CONSTRAINT FK_TrailerTypeRequiredQualifications_TrailerTypeID FOREIGN KEY (TrailerTypeID) REFERENCES dbo.TrailerTypes(TrailerTypeID),
	CONSTRAINT FK_TrailerTypeRequiredQualifications_DriverQualificationID FOREIGN KEY (DriverQualificationID) REFERENCES dbo.DriverQualifications(DriverQualificationID)
);
GO

-- 7. Creating order required qualifications table
CREATE TABLE dbo.OrderRequiredQualifications (
	OrderID INT NOT NULL,
	DriverQualificationID INT NOT NULL,
	CONSTRAINT PK_OrderRequiredQualifications PRIMARY KEY(OrderID, DriverQualificationID),
	CONSTRAINT FK_OrderRequiredQualifications_OrderID FOREIGN KEY (OrderID) REFERENCES dbo.Orders(OrderID),
	CONSTRAINT FK_OrderRequiredQualifications_DriverQualificationID FOREIGN KEY (DriverQualificationID) REFERENCES dbo.DriverQualifications(DriverQualificationID)
);
GO