CREATE DATABASE OlistStoreDB;
GO
USE OlistStoreDB;
GO

CREATE TABLE Customer (
    c_id VARCHAR(50) PRIMARY KEY,
    c_unique_id VARCHAR(50),
    c_city VARCHAR(100),
    c_state VARCHAR(10),
    c_zip VARCHAR(20)
);

CREATE TABLE Product (
    p_id VARCHAR(50) PRIMARY KEY,
    p_category_name VARCHAR(100),
    p_name_length INT,
    p_description_length INT,
    p_photos_qty INT,
    p_weight_g INT,
    p_length_cm INT,
    p_height_cm INT,
    p_width_cm INT
);

CREATE TABLE Sellers (
    s_id VARCHAR(50) PRIMARY KEY,
    s_zip_code VARCHAR(20),
    s_city VARCHAR(100),
    s_state VARCHAR(10)
);

CREATE TABLE Orders (
    o_id VARCHAR(50) PRIMARY KEY,
    c_id VARCHAR(50),
    o_status VARCHAR(30),
    purchase_timestamp DATETIME,
    o_approved_at DATETIME,
    o_delivered_carrier_date DATETIME,
    o_delivered_customer_date DATETIME,
    o_estimated_delivery_date DATETIME,
    FOREIGN KEY (c_id) REFERENCES Customer(c_id)
);

CREATE TABLE Order_Item (
    o_id VARCHAR(50),
    o_item_id INT,
    p_id VARCHAR(50),
    s_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (o_id, o_item_id),
    FOREIGN KEY (o_id) REFERENCES Orders(o_id),
    FOREIGN KEY (p_id) REFERENCES Product(p_id),
    FOREIGN KEY (s_id) REFERENCES Sellers(s_id)
);

CREATE TABLE Order_Payment (
    o_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(30),
    payment_installments INT,
    payment_value DECIMAL(10, 2),
    PRIMARY KEY (o_id, payment_sequential),
    FOREIGN KEY (o_id) REFERENCES Orders(o_id)
);

CREATE TABLE Review (
    r_id VARCHAR(50),
    o_id VARCHAR(50),
    r_score INT,
    r_comment NVARCHAR(MAX),
    r_creation DATETIME,
    r_answer_timestamp DATETIME,
    PRIMARY KEY (r_id, o_id),
    FOREIGN KEY (o_id) REFERENCES Orders(o_id)
);