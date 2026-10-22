-- 01_create_database.sql
-- Creates the TransportFleet database.
-- Run first, before 02_create_dictionary_tables.sql
-- The script can be re-run. An existing TransportFleet database is dropped first.
-- Re-running deletes the database together with all of its data.

-- Switch to master: a database cannot be dropped while it is the current one
USE master;
GO

-- Drop the database if it already exists (closes any open connections first)
-- DB_ID returns NULL when the database does not exist, so the block runs only if it exists
IF DB_ID(N'TransportFleet') IS NOT NULL
BEGIN
	-- Disconnect all other users, otherwise DROP DATABASE may fail
	ALTER DATABASE TransportFleet SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	-- Delete the database with all its data
	DROP DATABASE TransportFleet;
END
GO

-- Create the database
CREATE DATABASE TransportFleet;
GO

-- Keep the database open (AUTO_CLOSE is inherited as ON from the model database on some installations)
ALTER DATABASE TransportFleet SET AUTO_CLOSE OFF;
GO