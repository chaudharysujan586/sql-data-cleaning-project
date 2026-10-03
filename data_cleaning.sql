-- ============================================================
-- DATA CLEANING PROJECT
-- ============================================================

SELECT * 
FROM layoffs;

-- ============================================================
-- CREATE STAGING TABLE
-- ============================================================

CREATE TABLE layoffs_staging 
LIKE layoffs;

SELECT * 
FROM layoffs_staging ;


INSERT layoffs_staging 
SELECT * FROM layoffs;

-- ============================================================
-- 1. REMOVE DUPLICATES
-- ============================================================

-- Identify duplicate records using ROW_NUMBER().
-- Rows with row_num > 1 represent duplicate records.

WITH duplicate_cte AS(
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised
			) AS row_num
	FROM 
		layoffs_staging
)

SELECT * 
FROM duplicate_cte
WHERE row_num>1;

-- The following approaches were tested for deleting duplicate records
-- identified using ROW_NUMBER(), but were not successful.

WITH DELETE_CTE AS 
(
SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1
)
DELETE
FROM DELETE_CTE
;


WITH DELETE_CTE AS (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised, 
    ROW_NUMBER() OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised) AS row_num
	FROM world_layoffs.layoffs_staging
)
DELETE FROM world_layoffs.layoffs_staging
WHERE (company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised, row_num) IN (
	SELECT company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised, row_num
	FROM DELETE_CTE
) AND row_num > 1;

-- Create a temporary row_num column to identify duplicate records.
-- Duplicate records with row_num > 1 will then be removed.

ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;


SELECT *
FROM world_layoffs.layoffs_staging
;

-- Create a second staging table to store the row numbers
-- generated for duplicate identification.

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `total_laid_off` text,
  `date` text,
  `percentage_laid_off` text,
  `industry` text,
  `stage` text,
  `funds_raised` int DEFAULT NULL,
  `country` text,
  `row_num` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



SELECT *
FROM layoffs_staging2
;

-- Insert records into the second staging table and generate
-- row numbers based on the combination of relevant columns.

INSERT INTO layoffs_staging2
SELECT `company`,
  `location`,
  `total_laid_off`,
  `date`,
  `percentage_laid_off`,
  `industry`,
  `stage`,
  `funds_raised`,
  `country`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised
			) AS row_num
FROM 
layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num>1;

-- Delete duplicate records identified by row_num > 1.

DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- ============================================================
-- 2. STANDARDIZE DATA
-- ============================================================

-- Remove leading and trailing spaces from company names.

SELECT company,TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company); 

-- Check for distinct industry values and identify
-- potential inconsistencies or blank values.

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Check for NULL and blank values in the industry column.

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- Review distinct location values to identify
-- potential inconsistencies.

SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
ORDER BY location asc ;

-- Identify inconsistent location values.
-- Examples include locations with and without the ", Non-U.S." suffix.

SELECT *
FROM layoffs_staging2
WHERE location IN (
    'Bengaluru',
    'Bengaluru, Non-U.S.',
    'Kuala Lumpur',
    'Kuala Lumpur, Non-U.S.',
    'Luxembourg, Non-U.S.',
    'Melbourne, Non-U.S.',
    'Melbourne, Victoria',
    'New Delhi, New York City',
    'New Delhi, Non-U.S.',
    'Singapore',
    'Singapore, Non-U.S.'
)
ORDER BY location;

-- The query above is used to verify location inconsistencies.
-- Most of the identified values represent the same location
-- with inconsistent formatting.
-- 'New Delhi, New York City' and 'New Delhi, Non-U.S.' are
-- treated separately after checking the corresponding country values.

-- Standardize location values by removing the ", Non-U.S." suffix
-- where it appears at the end of the location value.

UPDATE layoffs_staging2
SET location = TRIM(
    REPLACE(location, ', Non-U.S.', '')
)
WHERE location LIKE '%, Non-U.S.';

-- Verify the standardized location values.

SELECT DISTINCT location
FROM world_layoffs.layoffs_staging2
ORDER BY location asc ;

-- ============================================================
-- 3. CHECK AND STANDARDIZE COUNTRY VALUES
-- ============================================================

-- Review distinct country values and identify potential
-- NULL or inconsistent values.

SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;             -- One NULL value identified

-- ============================================================
-- 4. STANDARDIZE DATE VALUES
-- ============================================================

-- Review the existing date format and convert text values
-- into the appropriate DATE format.
-- %Y is used to correctly represent the four-digit year.

SELECT date, STR_TO_DATE(date,'%m/%d/%Y')
FROM layoffs_staging2;
 
-- Update the date column using the converted DATE values.

 UPDATE layoffs_staging2
 SET date = STR_TO_DATE(date,'%m/%d/%Y');
 
-- Verify the converted date values.

 SELECT date    
FROM layoffs_staging2;

-- Change the data type of the date column from TEXT to DATE.

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- ============================================================
-- 5. HANDLE NULL AND BLANK VALUES
-- ============================================================

-- Check for records where both total_laid_off and
-- percentage_laid_off contain blank values.

SELECT *
FROM layoffs_staging2
WHERE total_laid_off = ''
AND percentage_laid_off = '';

-- Check records with NULL or blank industry values
-- and compare them with other available information.

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL or industry = '' ;

-- Review the company record to investigate the identified
-- NULL industry value.

SELECT *
FROM layoffs_staging2
WHERE company = 'Appsmith';

-- Check for NULL or blank country values.

SELECT *
FROM layoffs_staging2
WHERE country IS NULL or country = '' ;  

-- One NULL value was identified in the country column,
-- along with a NULL/blank value in percentage_laid_off.

-- ============================================================
-- 6. REMOVE RECORDS WITH INSUFFICIENT LAYOFF INFORMATION
-- ============================================================

-- Identify records where both total_laid_off and
-- percentage_laid_off are blank.

 SELECT *
FROM layoffs_staging2
WHERE total_laid_off = ''
AND percentage_laid_off = '';

-- Remove records where both layoff-related fields are blank,
-- as these records do not provide useful layoff information.

DELETE 
FROM layoffs_staging2
WHERE total_laid_off = ''
AND percentage_laid_off = '';  

SELECT *
FROM layoffs_staging2;

-- ============================================================
-- 7. REMOVE TEMPORARY DUPLICATE-IDENTIFICATION COLUMN
-- ============================================================

-- Remove the temporary row_num column after duplicate
-- identification and removal are complete.

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;