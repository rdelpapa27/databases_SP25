CREATE DATABASE taxi_database;
USE taxi_database;

drop table taxi_data_table;

CREATE TABLE taxi_data_table (
    medallion VARCHAR(50),
    hack_license VARCHAR(50),
    pickup_datetime DATETIME,
    dropoff_datetime DATETIME,
    trip_time_in_secs INT,
    trip_distance DECIMAL(10 , 2 ),
    pickup_longitude VARCHAR(30),
    pickup_latitude VARCHAR(30),
    dropoff_longitude VARCHAR(30),
    dropoff_latitude VARCHAR(30),
    payment_type VARCHAR(10),
    fare_amount DECIMAL(10 , 2 ),
    surcharge DECIMAL(10 , 2 ),
    mta_tax DECIMAL(10 , 2 ),
    tip_amount DECIMAL(10 , 2 ),
    tolls_amount DECIMAL(10 , 2 ),
    total_amount DECIMAL(10 , 2 )
);


describe taxi_data_table;
