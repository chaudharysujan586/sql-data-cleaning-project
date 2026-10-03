# SQL Data Cleaning Project

## 📌 Project Overview

This project demonstrates a complete **data cleaning workflow using MySQL**.

The project uses a raw layoffs dataset containing information about companies, locations, industries, layoffs, dates, company stages, countries, and funds raised.

The main objective was to identify and correct common data quality issues such as **duplicate records, inconsistent values, NULL/blank fields, inconsistent locations, and incorrect date formats**, producing a cleaner dataset that can be used for further data analysis.

---

## 🛠️ Tools & Technologies

* **MySQL**
* **MySQL Workbench**
* **SQL**

---

## 🔄 Data Cleaning Process

The following steps were performed during the cleaning process:

### 1. Created Staging Tables

Created staging tables to work with a copy of the original dataset while keeping the raw data unchanged.

### 2. Identified Duplicate Records

Used SQL window functions to identify duplicate records.

```sql
ROW_NUMBER() OVER (
    PARTITION BY ...
)
```

Records with `row_num > 1` were identified as duplicates and removed from the staging dataset.

### 3. Standardized Company Names

Used `TRIM()` to remove unnecessary leading and trailing spaces from company names.

### 4. Checked Industry Values

Reviewed distinct industry values and investigated NULL or blank industry records.

### 5. Standardized Location Values

Identified inconsistent location formats and standardized values such as locations containing the `, Non-U.S.` suffix.

Used:

```sql
TRIM()
REPLACE()
```

to clean the location values.

### 6. Checked Country Values

Reviewed distinct country values and identified NULL or inconsistent records.

### 7. Converted Date Values

The original date values were stored as text.

Converted them into proper date values using:

```sql
STR_TO_DATE(date, '%m/%d/%Y')
```

The column was then changed from a text data type to `DATE`.

### 8. Handled NULL and Blank Values

Checked records containing NULL or blank values in important columns such as:

* `industry`
* `country`
* `total_laid_off`
* `percentage_laid_off`

### 9. Removed Incomplete Records

Records where both `total_laid_off` and `percentage_laid_off` were blank were removed because they did not provide useful layoff information.

### 10. Removed Temporary Columns

After duplicate identification and removal, the temporary `row_num` column was removed from the final cleaned dataset.

---

## 🧠 SQL Concepts Practiced

This project provided practical experience with:

* `SELECT`
* `WHERE`
* `UPDATE`
* `DELETE`
* `CREATE TABLE`
* `INSERT`
* `ALTER TABLE`
* `TRIM()`
* `REPLACE()`
* `STR_TO_DATE()`
* Common Table Expressions (CTEs)
* Window Functions
* `ROW_NUMBER()`
* `PARTITION BY`
* NULL and blank value handling
* Data standardization
* Duplicate detection and removal
* Staging tables

---

## 📂 Project Structure

```text
SQL-Data-Cleaning-Project/
│
├── data/
│   ├── layoffs_raw.csv
│   └── layoffs_cleaned.csv
│
├── sql/
│   └── data_cleaning.sql
│
└── README.md
```

### Dataset Files

**`layoffs_raw.csv`**
Original raw dataset before cleaning.

**`layoffs_cleaned.csv`**
Final dataset after applying the SQL data-cleaning process.

**`data_cleaning.sql`**
Complete MySQL script containing the data-cleaning workflow.

---

## 📊 Dataset Fields

The dataset contains information including:

* Company
* Location
* Industry
* Total Laid Off
* Percentage Laid Off
* Date
* Stage
* Country
* Funds Raised

---

## 🎯 Project Outcome

The raw dataset was transformed into a more consistent and structured dataset by:

* Removing duplicate records
* Standardizing text and location values
* Converting dates into the correct data type
* Handling NULL and blank values
* Removing records with insufficient layoff information
* Removing temporary cleaning columns

The resulting cleaned dataset is prepared for **further exploratory data analysis and visualization**.

---

## 📚 Learning Reference

This project was recreated for **learning, SQL practice, and portfolio development** while following a data-cleaning project tutorial by **Alex The Analyst**.

The project was independently executed in **MySQL Workbench** to practice real-world SQL data-cleaning techniques.

---

## 👨‍💻 Author

**Sujan Chaudhary**

BSc Information Technology Student

Interested in **Data Analysis, SQL, Excel, Power BI, and Python**.
