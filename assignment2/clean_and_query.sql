-- Task 3: Clean Up and Query Your Dataset

-- 1. Delete records where total_amount = 0 OR trip_distance = 0
DELETE FROM taxi_trips
WHERE total_amount = 0 OR trip_distance = 0;

-- 2. Calculate the average taxi fare (total_amount)
SELECT AVG(total_amount) AS avg_fare
FROM taxi_trips;

-- 3. Find the maximum and minimum total amount
SELECT 
    MAX(total_amount) AS max_total_amount, 
    MIN(total_amount) AS min_total_amount
FROM taxi_trips;

-- 4. Find the driver with the highest number of taxi rides
SELECT hack_license, COUNT(*) AS total_rides
FROM taxi_trips
GROUP BY hack_license
ORDER BY total_rides DESC
LIMIT 1;

-- 5. Compare tip amounts by payment type (Cash vs. Card)
SELECT payment_type, AVG(tip_amount) AS avg_tip
FROM taxi_trips
GROUP BY payment_type;
