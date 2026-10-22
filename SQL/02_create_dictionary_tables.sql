-- 02_create_dictionary_tables.sql
-- Transport Fleet Database: dictionary (lookup) tables
-- Run after 01_create_database.sql
-- The script can be re-run: existing tables are dropped first.

USE TransportFleet;
GO

-- Drop existing tables (child tables first)
-- Explicit dbo.(database owner) schema prefix is used on all objects for clarity and consistency.

IF OBJECT_ID(N'dbo.VehicleModels', N'U') IS NOT NULL DROP TABLE dbo.VehicleModels;
IF OBJECT_ID(N'dbo.VehicleBrands', N'U') IS NOT NULL DROP TABLE dbo.VehicleBrands;
IF OBJECT_ID(N'dbo.DrivingCategories', N'U') IS NOT NULL DROP TABLE dbo.DrivingCategories;
IF OBJECT_ID(N'dbo.TrailerTypes', N'U') IS NOT NULL DROP TABLE dbo.TrailerTypes;
IF OBJECT_ID(N'dbo.VehicleStatuses', N'U') IS NOT NULL DROP TABLE dbo.VehicleStatuses;
IF OBJECT_ID(N'dbo.OrderStatuses', N'U') IS NOT NULL DROP TABLE dbo.OrderStatuses;
IF OBJECT_ID(N'dbo.DriverQualifications', N'U') IS NOT NULL DROP TABLE dbo.DriverQualifications;
GO

-- Creating Dictionaries

-- 1. Vehicle brands

CREATE TABLE dbo.VehicleBrands (
	VehicleBrandID INT IDENTITY(1,1) NOT NULL,
	VehicleBrandName NVARCHAR(50) NOT NULL,
	CONSTRAINT PK_VehicleBrands PRIMARY KEY (VehicleBrandID),
	CONSTRAINT UQ_VehicleBrands_Name UNIQUE (VehicleBrandName)
);
GO

-- 2. Vehicle models (each model belongs to one brand)

CREATE TABLE dbo.VehicleModels (
	VehicleModelID INT IDENTITY(1,1) NOT NULL,
	VehicleBrandID INT NOT NULL,
	VehicleModelName NVARCHAR(50) NOT NULL,
	CONSTRAINT PK_VehicleModels PRIMARY KEY (VehicleModelID),
	CONSTRAINT FK_VehicleModels_VehicleBrandID FOREIGN KEY (VehicleBrandID) REFERENCES dbo.VehicleBrands(VehicleBrandID),
	CONSTRAINT UQ_VehicleModels_BrandName UNIQUE (VehicleBrandID, VehicleModelName)
);
GO

-- 3. Driving categories

CREATE TABLE dbo.DrivingCategories (
	DrivingCategoryID INT IDENTITY(1,1) NOT NULL,
	DrivingCategoryName NVARCHAR(10) NOT NULL,
	CONSTRAINT PK_DrivingCategories PRIMARY KEY (DrivingCategoryID),
	CONSTRAINT UQ_DrivingCategories_Name UNIQUE (DrivingCategoryName)
);
GO

-- 4. Trailer types

CREATE TABLE dbo.TrailerTypes (
	TrailerTypeID INT IDENTITY(1,1) NOT NULL,
	TrailerTypeName NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_TrailerTypes PRIMARY KEY (TrailerTypeID),
	CONSTRAINT UQ_TrailerTypes_Name UNIQUE (TrailerTypeName)
);
GO

-- 5. Vehicle statuses

CREATE TABLE dbo.VehicleStatuses (
	VehicleStatusID INT IDENTITY(1,1) NOT NULL,
	VehicleStatusName NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_VehicleStatuses PRIMARY KEY (VehicleStatusID),
	CONSTRAINT UQ_VehicleStatuses_Name UNIQUE (VehicleStatusName)
);
GO

-- 6. Order statuses

CREATE TABLE dbo.OrderStatuses (
	OrderStatusID INT IDENTITY(1,1) NOT NULL,
	OrderStatusName NVARCHAR(30) NOT NULL,
	CONSTRAINT PK_OrderStatuses PRIMARY KEY (OrderStatusID),
	CONSTRAINT UQ_OrderStatuses_Name UNIQUE (OrderStatusName)
);
GO

-- 7. Driver qualifications

CREATE TABLE dbo.DriverQualifications (
	DriverQualificationID INT IDENTITY(1,1) NOT NULL,
	DriverQualificationName NVARCHAR(50) NOT NULL,
	CONSTRAINT PK_DriverQualifications PRIMARY KEY (DriverQualificationID),
	CONSTRAINT UQ_DriverQualifications_Name UNIQUE (DriverQualificationName)
);
GO