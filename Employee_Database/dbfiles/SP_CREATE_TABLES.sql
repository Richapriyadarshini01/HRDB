CREATE DEFINER=`root`@`localhost` PROCEDURE `SP_CREATE_TABLES`()
BEGIN

/*DECLARING THE VARIABLES*/

DECLARE TABLE_COUNT INT;
DECLARE OPERATION_TYPE VARCHAR(50);
DECLARE LOG_DETAILS VARCHAR(50);
DECLARE PROCESS_NAME VARCHAR(30);
SET OPERATION_TYPE = 'CREATING THE TABLE FOR ALL THE LAYERS';
SET PROCESS_NAME = 'SP_CREATE_TABLES';



/*THIS IS THE AUDIT TABLE WHERE WE WILL CAPTURE ALL THE OPERATION AND DETAILS FOR AUDITING*/
CREATE TABLE HRDB_SYS_AUDIT_CONTROL
(OP_ID INT PRIMARY KEY AUTO_INCREMENT,  
SOURCE_NAME VARCHAR(30),
TARGET_NAME VARCHAR(30),
PROCESS_NAME VARCHAR(30),
OPERATION_TYPE VARCHAR(50),
SOURCE_COUNT INT,
TARGET_COUNT INT,
LOG_DETAILS VARCHAR(50),
OPERATED_BY VARCHAR(20),
OPERATION_DATE TIMESTAMP);

/*THIS IS THE STAGING AREA, WHERE WE ARE GOING TO DUMP ALL THE DATA COMING FROM THE CSV SOURCE*/

CREATE TABLE TBL_STG_EMPLOYEES
(
EMPLOYEE_ID INT,
FIRST_NAME VARCHAR(45),
LAST_NAME VARCHAR(45),
EMAIL VARCHAR(20),
PHONE_NUMBER VARCHAR(20),
HIRE_DATE DATE,
JOB_ID VARCHAR(10),
SALARY DECIMAL(10,2),
COMMISSION_PCT DECIMAL(3,2),
MANAGER_ID INT,
DEPARTMENT_ID INT
); 

CREATE TABLE TBL_STG_DEPARTMENTS
(
DEPARTMENT_ID INT,
DEPARTMENT_NAME VARCHAR(45),
MANAGER_ID INT,
LOCATION_ID INT
); 

CREATE TABLE TBL_STG_JOBS
(
JOB_ID VARCHAR(10),
JOB_TITLE VARCHAR(45),
MIN_SALARY INT,
MAX_SALARY INT
); 

CREATE TABLE TBL_STG_JOB_HISTORY
(
EMPLOYEE_ID INT,
START_DATE DATE,
END_DATE DATE,
JOB_ID VARCHAR(10),
DEPARTMENT_ID INT
); 

CREATE TABLE TBL_STG_COUNTRIES
(
COUNTRY_ID VARCHAR(2),
COUNTRY_NAME VARCHAR(20),
REGION_ID INT
); 

CREATE TABLE TBL_STG_LOCATIONS
(
LOCATION_ID INT,
STREET_ADDRESS VARCHAR(45),
POSTAL_CODE VARCHAR(10),
CITY VARCHAR(25),
STATE_PROVINCE VARCHAR(25),
COUNTRY_ID VARCHAR(2)
); 

CREATE TABLE TBL_STG_REGIONS
(
REGION_ID INT,
REGION_NAME VARCHAR(22)
);

/*THIS IS THE HOP1 TRANSFORMATION AREA, WHERE WE ARE GOING TO MODIFY 
THE EXISTING COLUMNS BASED ON THE REQUIREMENTS DATA*/

CREATE TABLE TBL_TRANS_EMPLOYEES_HOP1
(
EMPLOYEE_ID INT,
FIRST_NAME VARCHAR(45),
LAST_NAME VARCHAR(45),
EMAIL VARCHAR(50),
PHONE_NUMBER VARCHAR(20),
HIRE_DATE DATE,
JOB_ID VARCHAR(10),
SALARY DECIMAL(10,2),
COMMISSION_PCT DECIMAL(3,2),
MANAGER_ID INT,
DEPARTMENT_ID INT
);


CREATE TABLE TBL_TRANS_DEPARTMENTS_HOP1
(
DEPARTMENT_ID INT,
DEPARTMENT_NAME VARCHAR(45),
MANAGER_ID INT,
LOCATION_ID INT
); 

CREATE TABLE TBL_TRANS_LOCATIONS_HOP1
(
LOCATION_ID INT,
STREET_ADDRESS VARCHAR(45),
POSTAL_CODE VARCHAR(10),
CITY VARCHAR(25),
STATE_PROVINCE VARCHAR(25),
COUNTRY_ID VARCHAR(2)
); 


/*THIS IS THE HOP2 TRANSFORMATION AREA, WHERE WE ARE GOING TO ADD NEW COLUMNS IN THE TABLE 
BASED ON THE REQUIREMENTS DATA*/

CREATE TABLE TBL_TRANS_EMPLOYEES_HOP2
(
EMPLOYEE_ID INT,
EMPLOYEE_NAME VARCHAR(50),
EMAIL VARCHAR(50),
PHONE_NUMBER VARCHAR(20),
HIRE_DATE DATE,
JOB_ID VARCHAR(10),
SALARY DECIMAL(10,2),
COMMISSION_PCT DECIMAL(3,2),
MONTHLY_SALARY DECIMAL(10,2),
SALARY_CATEGORY VARCHAR(20),
MANAGER_ID INT,
DEPARTMENT_ID INT
);

/*THIS IS THE FINAL AREA, WHERE WE WE WILL HAVE ALL THE CLEANED DATA*/
CREATE TABLE TBL_FNL_EMPLOYEES (
    EMPLOYEE_ID INT,
    EMPLOYEE_NAME VARCHAR(45) NOT NULL,
    EMAIL VARCHAR(50) UNIQUE,
    PHONE_NUMBER VARCHAR(20) UNIQUE,
    HIRE_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    JOB_ID VARCHAR(10),
    SALARY DECIMAL(10,2) CHECK (SALARY > 0),
    COMMISSION_PCT DECIMAL(3,2),
    MONTHLY_SALARY DECIMAL(15,2),
    SALARY_CATEGORY VARCHAR(20),
    MANAGER_ID INT,
    DEPARTMENT_ID INT
);

CREATE TABLE TBL_FNL_DEPARTMENTS(
DEPARTMENT_ID INT ,
DEPARTMENT_NAME VARCHAR(50) NOT NULL,
MANAGER_ID INT,
LOCATION_ID INT
);

CREATE TABLE TBL_FNL_LOCATIONS(
LOCATION_ID INT ,
STREET_ADDRESS VARCHAR(50) NOT NULL,
POSTAL_CODE VARCHAR(10),
CITY VARCHAR(25),
STATE_PROVINCE VARCHAR(25),
COUNTRY_ID VARCHAR(2)
);

CREATE TABLE TBL_FNL_COUNTRIES(
COUNTRY_ID VARCHAR(2) ,
COUNTRY_NAME VARCHAR(20) NOT NULL,
REGION_ID INT
);

CREATE TABLE TBL_FNL_REGIONS(
REGION_ID INT ,
REGION_NAME VARCHAR(50) NOT NULL
);

CREATE TABLE TBL_FNL_JOBS(
JOB_ID VARCHAR(10) ,
JOB_TITLE VARCHAR(50) NOT NULL,
MIN_SALARY DECIMAL(10,2) CHECK (MIN_SALARY>0),
MAX_SALARY DECIMAL(10,2) CHECK (MAX_SALARY>0)
);


CREATE TABLE TBL_FNL_JOB_HISTORY(
EMPLOYEE_ID INT, 
START_DATE DATE,
END_DATE DATE, 
JOB_ID VARCHAR(10),
DEPARTMENT_ID INT
);

CREATE OR REPLACE VIEW VW_REGIONS AS 
SELECT 
REG.REGION_ID,
CNT.COUNTRY_NAME,
REG.REGION_NAME,

CASE 
	WHEN REG.REGION_ID=3 THEN 'APAC'
    WHEN REG.REGION_ID=1 OR REG.REGION_ID=4 THEN 'EMEA'
    WHEN CNT.COUNTRY_NAME IN ('Argentina','Brazil','Mexico') THEN 'LATAM'
    WHEN CNT.COUNTRY_NAME IN ('United States of America','Canada') THEN 'NORAM'
    WHEN CNT.COUNTRY_NAME = 'Australia' THEN 'OCEANIA'
END REGION
FROM TBL_FNL_REGIONS REG
INNER JOIN TBL_FNL_COUNTRIES CNT
ON REG.REGION_ID=CNT.REGION_ID;


SELECT COUNT(*) INTO TABLE_COUNT FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA='HRDB';

IF TABLE_COUNT = 20 THEN
        SET LOG_DETAILS = 'ALL THE TABLES ARE CREATED SUCCESSFULLY';
ELSE
		SET LOG_DETAILS = 'THERE IS NO MISMATCH IN THE NUMBER OF TABLES';
END IF;


INSERT INTO HRDB_SYS_AUDIT_CONTROL 
    (
    PROCESS_NAME,
    OPERATION_TYPE,
    LOG_DETAILS,
    OPERATED_BY,
	OPERATION_DATE)
    VALUES 
        (
        PROCESS_NAME,
        OPERATION_TYPE,
        LOG_DETAILS,
        CURRENT_USER(),
        CURRENT_TIMESTAMP());

END