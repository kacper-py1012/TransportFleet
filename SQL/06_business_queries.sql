-- 06_business_queries.sql
-- Transport Fleet Database: business queries
-- Run after 05_insert_sample_data.sql
-- The script only reads data; it does not change anything.

USE TransportFleet;
GO

-- 1. Which vehicles are available?
-- Business context: Identify fleet assets ready for new orders
SELECT 
	v.RegistrationNumber AS [Registration Number],
	b.VehicleBrandName AS [Vehicle Brand],
	m.VehicleModelName AS [Model]
FROM dbo.Vehicles AS v
-- JOIN VehicleModels and VehicleBrands to retrieve readable names
-- (Vehicles links to Models, Models links to Brands)
JOIN dbo.VehicleModels AS m
	ON v.VehicleModelID = m.VehicleModelID
JOIN dbo.VehicleBrands AS b
	ON m.VehicleBrandID = b.VehicleBrandID
JOIN dbo.VehicleStatuses AS s
	ON v.VehicleStatusID = s.VehicleStatusID
-- Filter explicitly by status name to keep business logic clear
WHERE s.VehicleStatusName = 'Available'
-- Sort by registration plate for readability
ORDER BY v.RegistrationNumber;

-- 2. Drivers with driving categories and qualifications
-- Business context: Review driver fleet skills and certifications.
SELECT
	d.LastName AS [Last Name],
	d.FirstName AS [First Name],
	dc.DrivingCategoryName AS [Driving Category],
-- Aggregate multiple qualification records into a single comma-separated string per driver
	STRING_AGG(dq.DriverQualificationName, ', ') WITHIN GROUP (ORDER BY dq.DriverQualificationName) AS [Qualifications]
FROM dbo.Drivers d
-- Mandatory JOIN for driving category as each driver must have one
JOIN dbo.DrivingCategories AS dc
	ON d.DrivingCategoryID = dc.DrivingCategoryID
-- LEFT JOIN for qualifications to preserve drivers without assigned certs
LEFT JOIN dbo.DriverQualificationAssignments AS dqa
	ON d.DriverID = dqa.DriverID
LEFT JOIN dbo.DriverQualifications AS dq
	ON dqa.DriverQualificationID = dq.DriverQualificationID
-- Group by driver attributes to aggregate multiple qualifications into a single line
GROUP BY 
	d.DriverID, d.FirstName, d.LastName, dc.DrivingCategoryName
-- Sort by drivers last name for clean reporting
ORDER BY d.LastName;
GO

-- 3. Which qualifications have expired or expire within 30 days?
-- Business context: Find drivers whose qualifications need to be renewed.
-- The result depends on the day the query is run.
SELECT
	d.LastName,
	d.FirstName,
	dq.DriverQualificationName,
	dqa.ExpiryDate,
	-- Days left until expiry (a negative number means it has already expired)
	DATEDIFF(DAY, CAST(GETDATE() AS DATE), dqa.ExpiryDate) AS DaysLeft,
	-- Label each row: Expired if the date is in the past, otherwise Expiring soon
	CASE
		WHEN dqa.ExpiryDate < CAST(GETDATE() AS DATE) THEN N'Expired'
		ELSE N'Expiring soon'
	END AS ExpiryStatus
FROM dbo.Drivers AS d
-- Go through the link table: Drivers -> Assignments -> Qualifications
JOIN dbo.DriverQualificationAssignments AS dqa
	ON d.DriverID = dqa.DriverID
JOIN dbo.DriverQualifications AS dq
	ON dqa.DriverQualificationID = dq.DriverQualificationID
-- One condition covers both groups: expired (past dates) and expiring within 30 days
WHERE dqa.ExpiryDate <= DATEADD(DAY, 30, CAST(GETDATE() AS DATE))
-- Most urgent first (oldest date on top)
ORDER BY dqa.ExpiryDate;
GO

-- 4. How many orders has each driver had in total?
-- Business context: See how much work each driver has handled (all orders, any status).
SELECT 
	d.LastName,
	d.FirstName,
-- COUNT(o.OrderID) counts real orders only.
-- COUNT(*) would count the empty row of a driver with no orders as 1.
COUNT(o.OrderID) AS [Order Count]
FROM dbo.Drivers AS d
-- LEFT JOIN keeps drivers who have no orders (they show 0).
-- A regular JOIN would drop them.
LEFT JOIN dbo.Orders AS o
	ON d.DriverID = o.DriverID
-- One row per driver; DriverID keeps two drivers with the same name from being merged
GROUP BY d.LastName, d.FirstName, d.DriverID
-- Most orders first; last name breaks ties so the order is always the same
ORDER BY [Order Count] DESC, d.LastName;
GO

-- 5a. Which drivers can take a given order?
-- Business context: Match drivers to an order based on the qualifications it requires.
-- Change @OrderID to check a different order.
-- Test: order 7 returns only Nowak Anna; order 6 (no requirements) returns all drivers.
DECLARE @OrderID INT = 7;

SELECT 
	d.LastName,
	d.FirstName
FROM dbo.Drivers AS d
WHERE NOT EXISTS (
    -- a requirement of this order...
	SELECT 1
	FROM dbo.OrderRequiredQualifications AS orq
	WHERE orq.OrderID = @OrderID
	-- ...that this driver does NOT have
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.DriverQualificationAssignments AS dqa
			WHERE dqa.DriverID = d.DriverID
				AND dqa.DriverQualificationID = orq.DriverQualificationID
		)
);
GO

-- 5b. Which drivers can take a given order, with qualifications valid on the delivery date?
-- Business context: A qualification that expires before the delivery date cannot be used
-- for that order, so it is treated as if the driver did not have it.
-- Change @OrderId to check a different order.
-- Test: order 6 (no requirements) returns all drivers.
DECLARE @OrderId INT = 7
-- Delivery date is read from the order itself, so it never has to be typed by hand
DECLARE @DeliveryDate DATE = (
	SELECT o.DeliveryDate
	FROM dbo.Orders AS o
	WHERE o.OrderID = @OrderId
)
SELECT 
	d.LastName,
	d.FirstName
FROM dbo.Drivers AS d
WHERE NOT EXISTS (
	SELECT 1
	FROM dbo.OrderRequiredQualifications AS orq
	WHERE orq.OrderID = @OrderID
		AND NOT EXISTS (
			SELECT 1
			FROM dbo.DriverQualificationAssignments AS dqa
			WHERE dqa.DriverID = d.DriverID
				AND dqa.DriverQualificationID = orq.DriverQualificationID
				AND dqa.ExpiryDate >= @DeliveryDate
		)
);
GO

-- 5c. Which drivers can take a given order, considering both order and trailer requirements?
-- Business context: Qualifications can be required directly by the order or implied by the assigned trailer type.
-- All qualifications must still be valid on the delivery date.
-- Uses UNION to combine requirements from OrderRequiredQualifications and TrailerTypeRequiredQualifications.
-- Change @OrderId to check a different order.
-- Test: order 5 (Tanker) adds ADR requirement; orders 6-8 (no trailer) yield the same result as 5b.
DECLARE @OrderID INT = 5
DECLARE @DeliveryDate DATE = (
-- Step 0: Fetch the delivery date of the target order to validate driver qualifications against it
	SELECT o.DeliveryDate
	FROM dbo.Orders AS o
	WHERE o.OrderID = @OrderID
);
-- Step 1: Build the unified list of required qualification IDs (CTE)
-- Combines direct order requirements with trailer-specific requirements using UNION to avoid duplicates
WITH RequiredQualifications AS (
-- Direct qualification requirements specified on the order itself
	SELECT orq.DriverQualificationID
	FROM dbo.OrderRequiredQualifications AS orq
	WHERE orq.OrderID = @OrderID
	UNION
-- Implicit requirements derived from the trailer assigned to this order
	SELECT ttqr.DriverQualificationID
	FROM dbo.Orders AS o
		JOIN dbo.Trailers AS t
			ON o.TrailerID = t.TrailerID
		JOIN dbo.TrailerTypeRequiredQualifications AS ttqr
			ON t.TrailerTypeID = ttqr.TrailerTypeID
	WHERE o.OrderID = @OrderID
	)
-- Step 2: Main query to select and aggregate qualified drivers
SELECT
    d.LastName AS [Last Name],
    d.FirstName AS [First Name],
-- Displays a fallback message if the order requires no qualifications at all
    ISNULL(STRING_AGG(dq.DriverQualificationName, ', ') WITHIN GROUP (ORDER BY dq.DriverQualificationName), 'No qualifications needed.') AS [Qualifications]
FROM dbo.Drivers AS d
-- Step 3: Attach readable qualification names for matched and valid requirements only
-- Pre-filters assignments to include only those required by this order and still active on the delivery date
LEFT JOIN (
    SELECT 
        dqa.DriverID,
        dq.DriverQualificationName
    FROM dbo.DriverQualificationAssignments AS dqa
    JOIN RequiredQualifications AS req
        ON dqa.DriverQualificationID = req.DriverQualificationID
    JOIN dbo.DriverQualifications AS dq
        ON dqa.DriverQualificationID = dq.DriverQualificationID
    WHERE dqa.ExpiryDate >= @DeliveryDate
) AS dq
    ON d.DriverID = dq.DriverID
-- Step 4: Double NOT EXISTS pattern (Relational Division / Gap Detector)
-- Ensures the driver has NO missing qualifications:
-- "Select driver where there DOES NOT EXIST any required qualification..."
WHERE NOT EXISTS (
    SELECT 1
    FROM RequiredQualifications AS req
-- "...for which the driver DOES NOT HAVE an active, valid assignment record"
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.DriverQualificationAssignments AS dqa
        WHERE dqa.DriverID = d.DriverID
          AND dqa.DriverQualificationID = req.DriverQualificationID
          AND dqa.ExpiryDate >= @DeliveryDate
    )
)
-- Step 5: Group by all non-aggregated columns required by STRING_AGG
GROUP BY d.DriverID, d.LastName, d.FirstName;
GO