-- DISCLAIMER:
-- The following SQL analysis is intended solely for educational and demonstration purposes.
-- The dataset used is hypothetical and does not represent real patient information or actual medical data
-- related to lung cancer or any other condition. Any similarities to real data are purely coincidental and
-- should not be interpreted as medical or clinical evidence.

USE lungcancer_analysis;

CREATE TABLE dataset_med
(
	id INT NOT NULL,
	age INT NOT NULL,
	gender VARCHAR(50) NOT NULL,
	country VARCHAR(50) NOT NULL,
	diagnosis_date DATE NOT NULL,
	cancer_stage VARCHAR(50) NOT NULL,
	family_history VARCHAR(50) NOT NULL,
	smoking_status VARCHAR(50) NOT NULL,
	bmi DECIMAL(8,2) NOT NULL,
	cholesterol_level INT NOT NULL,
	hypertension INT NOT NULL,
	asthma INT NOT NULL,
	cirrhosis INT NOT NULL,
	other_cancer INT NOT NULL,
	treatment_type VARCHAR(50) NOT NULL, 
	end_treatment_date DATE NOT NULL,
	survived INT NOT NULL,
    PRIMARY KEY (id)
);

-- BASIC DEMOGRAPHICS
-- 1. What is the average age of patients in the dataset?

SELECT
	AVG(age) AS avg_age
FROM dataset_med; 

-- 2. What is the gender distribution of patients?

SELECT
	gender,
    COUNT(*) AS total_count
FROM dataset_med
GROUP BY gender;

-- 3. Which countries have the highest number of recorded cases?

SELECT
	country,
    COUNT(*) AS total_count
FROM dataset_med
GROUP BY country
ORDER BY total_count DESC
LIMIT 1;

-- 4. What is the distribution of cancer stages at diagnosis?

SELECT
	cancer_stage,
    COUNT(*) AS total_count
FROM dataset_med
GROUP BY cancer_stage
ORDER BY cancer_stage;

-- HEALTH AND RISK FACTOR
-- 5. How many patients have a family history of cancer?

SELECT
    COUNT(*) AS total_count
FROM dataset_med
WHERE family_history LIKE '%Yes%';

-- 6. What is the average BMI of patients by cancer stage?

SELECT
	cancer_stage,
    AVG(bmi) AS avg_bmi
FROM dataset_med
GROUP BY cancer_stage
ORDER BY cancer_stage;

-- 7. How does smoking status relate to cancer stage at diagnosis?

SELECT
	cancer_stage,
    smoking_status,
    COUNT(*) AS total_count
FROM dataset_med
GROUP BY
	cancer_stage,
    smoking_status
ORDER BY 
	cancer_stage,
    smoking_status;
    
-- 8. How many patients have other chronic conditions (hypertension, asthma, cirrhosis, etc.)?

SELECT
    COUNT(*) AS total_patientsOtherCondition
FROM dataset_med
WHERE hypertension = 1 
   OR asthma = 1 
   OR cirrhosis = 1 
   OR other_cancer = 1;

-- 9. Is there a correlation between cholesterol levels and survival rates? 

SELECT
    CASE 
        WHEN cholesterol_level < 200 THEN 'Normal (<200)'
        WHEN cholesterol_level BETWEEN 200 AND 239 THEN 'Borderline High (200-239)'
        ELSE 'High (240+)' 
    END AS cholesterol_category,
    COUNT(*) AS total_patients,
    SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) AS survived_count,
    ROUND(SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS survival_ratePercentage
FROM dataset_med
GROUP BY cholesterol_category
ORDER BY cholesterol_category;

-- TREATMENT & OUTCOMES
-- 10 What is the most common treatment type for each cancer stage?

SELECT
	cancer_stage,
    treatment_type,
    COUNT(*) AS total_count
FROM dataset_med
GROUP BY
	cancer_stage,
    treatment_type
ORDER BY
	cancer_stage,
    treatment_type;
    
-- 11. What is the average duration of treatment (diagnosis date → end treatment date)?

SELECT
	ROUND(AVG(end_treatment_date - diagnosis_date),2) AS avg_treatmentdays
FROM dataset_med;

-- 12. What percentage of patients survived by treatment type?

SELECT
	treatment_type,
    COUNT(*) AS total_patients,
    SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) AS survived_count,
    ROUND(SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS survival_ratePercentage
FROM dataset_med
GROUP BY treatment_type
ORDER BY treatment_type;

-- 13. Which country has the highest survival rate?

SELECT
	country,
    COUNT(*) AS total_patients,
    SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) AS survived_count,
    ROUND(SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS survival_ratePercentage
FROM dataset_med
GROUP BY country
ORDER BY survival_ratePercentage DESC
LIMIT 1;

-- 14. What is the survival rate for patients with family history vs. without?

SELECT
	family_history,
        COUNT(*) AS total_patients,
    SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) AS survived_count,
    ROUND(SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS survival_ratePercentage
FROM dataset_med
GROUP BY family_history
ORDER BY family_history;

-- TIME BASED ANALYSIS
-- 15. Which year had the highest number of diagnosis?

SELECT
	YEAR(diagnosis_date) AS year_diagnosis,
    COUNT(*) AS total_count
FROM dataset_med
GROUP BY year_diagnosis
ORDER BY total_count DESC
LIMIT 1;

-- 16. How does survival rate vary based on year of diagnosis?

SELECT
	YEAR(end_treatment_date) AS end_treatmentYear,
	COUNT(*) AS total_count
FROM dataset_med
GROUP BY end_treatment_date
ORDER BY total_count DESC
LIMIT 1;

-- 17. What is the median survival time for different cancer stages?

WITH survival_times AS (
    SELECT
        cancer_stage,
        DATEDIFF(end_treatment_date, diagnosis_date) AS survival_days
    FROM dataset_med
    WHERE end_treatment_date IS NOT NULL
),
ranked AS (
    SELECT
        cancer_stage,
        survival_days,
        ROW_NUMBER() OVER (PARTITION BY cancer_stage ORDER BY survival_days) AS rn,
        COUNT(*) OVER (PARTITION BY cancer_stage) AS total_count
    FROM survival_times
)
SELECT
    cancer_stage,
    ROUND(AVG(survival_days),2) AS median_survivalDays
FROM ranked
WHERE rn IN (
    FLOOR((total_count + 1) / 2),
    CEIL((total_count + 1) / 2)
)
GROUP BY cancer_stage
ORDER BY cancer_stage;


-- COMPARATIVE AND PATTERN ANALYSIS
-- 18. Is there a difference in average BMI between survivors and non-survivors?

SELECT
    survived,
    ROUND(AVG(bmi), 2) AS avg_bmi,
    COUNT(*) AS total_count
FROM dataset_med
GROUP BY survived
ORDER BY survived DESC;

-- 19. Do smokers have lower survival rates compared to non-smokers?

SELECT
	smoking_status,
	SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) AS survived_count,
    ROUND(SUM(CASE 
			WHEN survived = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS survival_ratePercentage
FROM dataset_med
GROUP BY smoking_status
ORDER BY survival_ratePercentage DESC;

-- 20. Which combination of chronic diseases is most common among survivors?

SELECT
    SUM(CASE WHEN hypertension = 1 THEN 1 END) AS total_hypertension,
    SUM(CASE WHEN asthma = 1 THEN 1 END) AS total_asthma,
    SUM(CASE WHEN cirrhosis = 1 THEN 1 END) AS total_cirrhosis,
    SUM(CASE WHEN other_cancer = 1 THEN 1 END) AS total_otherCancedr,
    COUNT(*) AS total_survived
FROM dataset_med
WHERE survived = 1
ORDER BY total_survived DESC
LIMIT 1;

-- 21. Are younger patients diagnosed at earlier cancer stages more often than older ones?

SELECT
    CASE 
        WHEN age < 40 THEN 'Under 40'
        WHEN age BETWEEN 40 AND 59 THEN '40-59'
        ELSE '60+'
    END AS age_group,
    cancer_stage,
    COUNT(*) AS patient_count
FROM dataset_med
GROUP BY 
	age_group, 
    cancer_stage
ORDER BY 
	age_group DESC,
    cancer_stage,
    patient_count DESC;

-- 22. Which cancer stage has the longest average treatment duration?

SELECT
	cancer_stage,
    ROUND(AVG(end_treatment_date - diagnosis_date),2) AS avg_days 
FROM dataset_med
GROUP BY cancer_stage
ORDER BY cancer_stage

-- DISCLAIMER:
-- The following SQL analysis is intended solely for educational and demonstration purposes.
-- The dataset used is hypothetical and does not represent real patient information or actual medical data
-- related to lung cancer or any other condition. Any similarities to real data are purely coincidental and
-- should not be interpreted as medical or clinical evidence.
