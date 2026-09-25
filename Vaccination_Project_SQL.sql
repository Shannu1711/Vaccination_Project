-- ============================================================
-- PROJECT: VACCINATION DATA ANALYSIS AND VISUALIZATION
-- DATABASE: vaccination_analysis
-- ============================================================

CREATE DATABASE IF NOT EXISTS vaccination_analysis;
USE vaccination_analysis;

-- ============================================================
-- 1. TABLE CREATION
-- ============================================================

CREATE TABLE IF NOT EXISTS countries (
    country_code VARCHAR(3) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    who_region VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS coverage_data (
    coverage_id INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(3) NOT NULL,
    year INT NOT NULL,
    antigen VARCHAR(50) NOT NULL,
    antigen_description VARCHAR(255),
    coverage_category VARCHAR(100),
    coverage_category_description VARCHAR(255),
    target_number BIGINT,
    doses_administered BIGINT,
    coverage DECIMAL(6,2),

    CONSTRAINT fk_coverage_country
        FOREIGN KEY (country_code)
        REFERENCES countries(country_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS incidence_rate (
    incidence_id INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(3) NOT NULL,
    year INT NOT NULL,
    disease VARCHAR(100) NOT NULL,
    disease_description VARCHAR(255),
    denominator VARCHAR(100),
    incidence_rate DECIMAL(12,4),

    CONSTRAINT fk_incidence_country
        FOREIGN KEY (country_code)
        REFERENCES countries(country_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS reported_cases (
    case_id INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(3) NOT NULL,
    year INT NOT NULL,
    disease VARCHAR(100) NOT NULL,
    disease_description VARCHAR(255),
    cases BIGINT,

    CONSTRAINT fk_cases_country
        FOREIGN KEY (country_code)
        REFERENCES countries(country_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS vaccine_introduction (
    intro_id INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(3) NOT NULL,
    year INT NOT NULL,
    description VARCHAR(255),
    intro VARCHAR(20),

    CONSTRAINT fk_intro_country
        FOREIGN KEY (country_code)
        REFERENCES countries(country_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS vaccine_schedule (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(3) NOT NULL,
    year INT NOT NULL,
    vaccine_code VARCHAR(50),
    vaccine_description VARCHAR(255),
    schedule_rounds INT,
    target_pop VARCHAR(100),
    target_pop_description VARCHAR(255),
    geoarea VARCHAR(100),
    age_administered VARCHAR(100),
    source_comment TEXT,

    CONSTRAINT fk_schedule_country
        FOREIGN KEY (country_code)
        REFERENCES countries(country_code)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================================
-- 2. INDEXES
-- Already created in the database.
-- Kept commented to avoid duplicate-index errors.
-- ============================================================

/*
CREATE INDEX idx_coverage_year
ON coverage_data(year);

CREATE INDEX idx_coverage_antigen
ON coverage_data(antigen);

CREATE INDEX idx_incidence_year
ON incidence_rate(year);

CREATE INDEX idx_incidence_disease
ON incidence_rate(disease);

CREATE INDEX idx_cases_year
ON reported_cases(year);

CREATE INDEX idx_cases_disease
ON reported_cases(disease);

CREATE INDEX idx_intro_year
ON vaccine_introduction(year);

CREATE INDEX idx_schedule_year
ON vaccine_schedule(year);
*/

-- ============================================================
-- 3. DATA IMPORT NOTE
-- ============================================================

/*
Cleaned CSV files were imported into MySQL using SQL-ready files.

Final validated row counts:

countries               = 27
coverage_data            = 2079
incidence_rate           = 1782
reported_cases           = 1782
vaccine_introduction     = 1188
vaccine_schedule         = 2258

LOAD DATA LOCAL INFILE commands are intentionally omitted
from the final submission script to prevent accidental
duplicate imports and LOCAL INFILE configuration errors.
*/

-- ============================================================
-- 4. DATABASE VALIDATION
-- ============================================================

SELECT
    'countries' AS table_name,
    COUNT(*) AS row_count
FROM countries

UNION ALL

SELECT
    'coverage_data',
    COUNT(*)
FROM coverage_data

UNION ALL

SELECT
    'incidence_rate',
    COUNT(*)
FROM incidence_rate

UNION ALL

SELECT
    'reported_cases',
    COUNT(*)
FROM reported_cases

UNION ALL

SELECT
    'vaccine_introduction',
    COUNT(*)
FROM vaccine_introduction

UNION ALL

SELECT
    'vaccine_schedule',
    COUNT(*)
FROM vaccine_schedule;

-- ============================================================
-- Q1. COUNTRIES WITH LOWEST AVERAGE VACCINATION COVERAGE
-- ============================================================

SELECT
    c.country_name,
    ROUND(AVG(cd.coverage), 2) AS avg_coverage
FROM coverage_data cd
JOIN countries c
    ON cd.country_code = c.country_code
GROUP BY
    c.country_name
ORDER BY
    avg_coverage ASC
LIMIT 10;

-- ============================================================
-- Q2. AVERAGE VACCINATION COVERAGE BY YEAR
-- ============================================================

SELECT
    year,
    ROUND(AVG(coverage), 2) AS avg_coverage
FROM coverage_data
GROUP BY
    year
ORDER BY
    year;

-- ============================================================
-- Q3. TOTAL REPORTED CASES BY DISEASE
-- ============================================================

SELECT
    disease,
    SUM(cases) AS total_reported_cases
FROM reported_cases
GROUP BY
    disease
ORDER BY
    total_reported_cases DESC;

-- ============================================================
-- Q4. DTP1 TO DTP3 DROP-OFF BY COUNTRY
-- ============================================================

SELECT
    c.country_name,

    ROUND(
        AVG(
            CASE
                WHEN cd.antigen = 'DTP1'
                THEN cd.coverage
            END
        )
        -
        AVG(
            CASE
                WHEN cd.antigen = 'DTP3'
                THEN cd.coverage
            END
        ),
        2
    ) AS dtp_dropoff_percentage_points

FROM coverage_data cd

JOIN countries c
    ON cd.country_code = c.country_code

WHERE
    cd.antigen IN ('DTP1', 'DTP3')

GROUP BY
    c.country_name

ORDER BY
    dtp_dropoff_percentage_points DESC;

-- ============================================================
-- Q5. MCV1 TO MCV2 DROP-OFF BY COUNTRY
-- ============================================================

SELECT
    c.country_name,

    ROUND(
        AVG(
            CASE
                WHEN cd.antigen = 'MCV1'
                THEN cd.coverage
            END
        )
        -
        AVG(
            CASE
                WHEN cd.antigen = 'MCV2'
                THEN cd.coverage
            END
        ),
        2
    ) AS mcv_dropoff_percentage_points

FROM coverage_data cd

JOIN countries c
    ON cd.country_code = c.country_code

WHERE
    cd.antigen IN ('MCV1', 'MCV2')

GROUP BY
    c.country_name

ORDER BY
    mcv_dropoff_percentage_points DESC;

-- ============================================================
-- Q6. AVERAGE VACCINATION COVERAGE BY WHO REGION
-- ============================================================

SELECT
    c.who_region,
    ROUND(AVG(cd.coverage), 2) AS avg_coverage
FROM coverage_data cd
JOIN countries c
    ON cd.country_code = c.country_code
GROUP BY
    c.who_region
ORDER BY
    avg_coverage DESC;

-- ============================================================
-- Q7. VACCINE INTRODUCTION RATE BY WHO REGION AND YEAR
-- ============================================================

SELECT
    c.who_region,
    vi.year,

    ROUND(
        100.0 *
        SUM(
            CASE
                WHEN vi.intro = 'Yes'
                THEN 1
                ELSE 0
            END
        )
        /
        COUNT(*),
        2
    ) AS introduction_rate

FROM vaccine_introduction vi

JOIN countries c
    ON vi.country_code = c.country_code

GROUP BY
    c.who_region,
    vi.year

ORDER BY
    vi.year,
    introduction_rate DESC;

-- ============================================================
-- Q8. MEASLES COVERAGE VS INCIDENCE
-- ============================================================

SELECT
    cd.country_code,
    c.country_name,
    cd.year,
    cd.coverage AS measles_vaccination_coverage,
    ir.incidence_rate AS measles_incidence_rate

FROM coverage_data cd

JOIN incidence_rate ir
    ON cd.country_code = ir.country_code
    AND cd.year = ir.year

JOIN countries c
    ON cd.country_code = c.country_code

WHERE
    cd.antigen = 'MCV1'
    AND ir.disease = 'MEASLES'

ORDER BY
    c.country_name,
    cd.year;

-- ============================================================
-- Q9. POLIO COVERAGE VS INCIDENCE
-- ============================================================

SELECT
    cd.country_code,
    c.country_name,
    cd.year,
    cd.coverage AS polio_vaccination_coverage,
    ir.incidence_rate AS polio_incidence_rate

FROM coverage_data cd

JOIN incidence_rate ir
    ON cd.country_code = ir.country_code
    AND cd.year = ir.year

JOIN countries c
    ON cd.country_code = c.country_code

WHERE
    cd.antigen = 'POL3'
    AND ir.disease = 'POLIO'

ORDER BY
    c.country_name,
    cd.year;

-- ============================================================
-- Q10. HIGH COVERAGE AND HIGH INCIDENCE
-- ============================================================

WITH coverage_year AS (
    SELECT
        country_code,
        year,
        AVG(coverage) AS avg_coverage
    FROM coverage_data
    GROUP BY
        country_code,
        year
),

incidence_year AS (
    SELECT
        country_code,
        year,
        AVG(incidence_rate) AS avg_incidence
    FROM incidence_rate
    GROUP BY
        country_code,
        year
)

SELECT
    c.country_name,
    cy.year,
    ROUND(cy.avg_coverage, 2) AS avg_coverage,
    ROUND(iy.avg_incidence, 2) AS avg_incidence

FROM coverage_year cy

JOIN incidence_year iy
    ON cy.country_code = iy.country_code
    AND cy.year = iy.year

JOIN countries c
    ON cy.country_code = c.country_code

WHERE
    cy.avg_coverage >= 85
    AND iy.avg_incidence >= 20

ORDER BY
    avg_incidence DESC,
    avg_coverage DESC;

-- ============================================================
-- Q11. COUNTRIES BELOW 95% MEASLES COVERAGE TARGET
-- ============================================================

SELECT
    c.country_name,
    cd.year,
    ROUND(AVG(cd.coverage), 2) AS measles_coverage,
    ROUND(95 - AVG(cd.coverage), 2) AS gap_to_95_percent

FROM coverage_data cd

JOIN countries c
    ON cd.country_code = c.country_code

WHERE
    cd.antigen = 'MCV1'

GROUP BY
    c.country_name,
    cd.year

HAVING
    AVG(cd.coverage) < 95

ORDER BY
    gap_to_95_percent DESC;

-- ============================================================
-- Q12. RESOURCE ALLOCATION PRIORITY
-- ============================================================

WITH country_coverage AS (
    SELECT
        country_code,
        AVG(coverage) AS avg_coverage
    FROM coverage_data
    GROUP BY
        country_code
)

SELECT
    c.country_name,
    c.who_region,
    ROUND(cc.avg_coverage, 2) AS avg_coverage,
    ROUND(95 - cc.avg_coverage, 2) AS gap_to_95

FROM country_coverage cc

JOIN countries c
    ON cc.country_code = c.country_code

WHERE
    cc.avg_coverage < 80

ORDER BY
    avg_coverage ASC;

-- ============================================================
-- Q13. MEASLES CASES BEFORE VS AFTER VACCINE INTRODUCTION
-- ============================================================

WITH measles_intro AS (
    SELECT
        country_code,
        MIN(year) AS introduction_year

    FROM vaccine_introduction

    WHERE
        LOWER(description) LIKE '%measles%'
        AND intro = 'Yes'

    GROUP BY
        country_code
),

measles_cases AS (
    SELECT
        country_code,
        year,
        cases

    FROM reported_cases

    WHERE
        disease = 'MEASLES'
)

SELECT
    CASE
        WHEN mc.year < mi.introduction_year
        THEN 'Before Introduction'
        ELSE 'After Introduction'
    END AS period,

    ROUND(AVG(mc.cases), 2) AS avg_measles_cases

FROM measles_cases mc

JOIN measles_intro mi
    ON mc.country_code = mi.country_code

GROUP BY
    period;

-- ============================================================
-- Q14. TOP DISEASES BY AVERAGE INCIDENCE RATE
-- ============================================================

SELECT
    disease,
    ROUND(AVG(incidence_rate), 2) AS avg_incidence_rate

FROM incidence_rate

GROUP BY
    disease

ORDER BY
    avg_incidence_rate DESC;

-- ============================================================
-- Q15. TOP COUNTRIES BY AVERAGE VACCINATION COVERAGE
-- ============================================================

SELECT
    c.country_name,
    c.who_region,
    ROUND(AVG(cd.coverage), 2) AS avg_coverage

FROM coverage_data cd

JOIN countries c
    ON cd.country_code = c.country_code

GROUP BY
    c.country_name,
    c.who_region

ORDER BY
    avg_coverage DESC

LIMIT 10;

-- ============================================================
-- Q16. LOWEST COUNTRIES BY AVERAGE VACCINATION COVERAGE
-- ============================================================

SELECT
    c.country_name,
    c.who_region,
    ROUND(AVG(cd.coverage), 2) AS avg_coverage

FROM coverage_data cd

JOIN countries c
    ON cd.country_code = c.country_code

GROUP BY
    c.country_name,
    c.who_region

ORDER BY
    avg_coverage ASC

LIMIT 10;

-- ============================================================
-- Q17. VACCINATION COVERAGE BY ANTIGEN
-- ============================================================

SELECT
    antigen,
    ROUND(AVG(coverage), 2) AS avg_coverage

FROM coverage_data

GROUP BY
    antigen

ORDER BY
    avg_coverage DESC;

-- ============================================================
-- Q18. YEARLY TOTAL REPORTED CASES
-- ============================================================

SELECT
    year,
    SUM(cases) AS total_reported_cases

FROM reported_cases

GROUP BY
    year

ORDER BY
    year;

-- ============================================================
-- Q19. YEARLY AVERAGE INCIDENCE RATE
-- ============================================================

SELECT
    year,
    ROUND(AVG(incidence_rate), 2) AS avg_incidence_rate

FROM incidence_rate

GROUP BY
    year

ORDER BY
    year;

-- ============================================================
-- Q20. VACCINE INTRODUCTION STATUS SUMMARY
-- ============================================================

SELECT
    intro,
    COUNT(*) AS record_count,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*) FROM vaccine_introduction),
        2
    ) AS percentage

FROM vaccine_introduction

GROUP BY
    intro

ORDER BY
    record_count DESC;

-- ============================================================
-- END OF PROJECT SQL
-- ============================================================