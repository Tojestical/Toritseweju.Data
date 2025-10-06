SELECT * FROM attendance;
SELECT * FROM department;
SELECT * FROM employee;
SELECT * FROM performance;
SELECT * FROM salary;
SELECT * FROM turnover;

--SECTION 1 (EMPLOYEE RETENTION ANALYSIS)

--1 Who are the top 5 highest serving employees?
SELECT e.employee_id, concat(e.first_name,' ', last_name) AS full_name, d.department_name, e.job_title, e.hire_date,
         EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS top_employees_service_years
FROM employee e  
JOIN department d  
ON e.department_id = d.department_id
ORDER BY e.hire_date ASC
LIMIT 5;

--2 What is the turnover rate for each department?
SELECT d.department_id, d.department_name,
    COUNT(CASE WHEN t.turnover_date BETWEEN '2024-01-01' AND '2024-12-31' THEN 1 END) AS employees_turnover_2024,
    COUNT(e.employee_id) AS total_employees,
    ROUND(COUNT(CASE WHEN t.turnover_date BETWEEN '2024-01-01' AND '2024-12-31' THEN 1 END)::decimal 
        / NULLIF(COUNT(e.employee_id), 0) * 100, 2 ) AS turnover_rate
FROM employee e
LEFT JOIN turnover t ON e.employee_id = t.employee_id
JOIN department d ON e.department_id = d.department_id
GROUP BY d.department_id, d.department_name
ORDER BY turnover_rate DESC;


-- company over all turnover rate
SELECT  ROUND( (SELECT COUNT(turnover_id) FROM turnover) * 100.0 / 
NULLIF((SELECT COUNT(employee_id) FROM employee), 0), 2)AS overall_turnover_rate;


--3 Which employees are at risk of leaving based on their performance? 
SELECT e.employee_id, CONCAT(e.first_name, ' ', e.last_name) AS employee_name, 
       p.performance_score, p.performance_date,
CASE
     WHEN p.performance_score < 4.0 THEN 'High Risk'
     ELSE 'No Risk'
END AS risk_status
FROM performance p
JOIN employee e 
ON p.employee_id = e.employee_id
ORDER BY p.performance_score DESC;

--total employees performance score based on risk category
SELECT CASE
          WHEN p.performance_score < 4.0 THEN 'High Risk'
		  ELSE 'No Risk'
END AS risk_status, COUNT(p.employee_id) AS total_emp_p_score
FROM performance p  
GROUP BY risk_status
ORDER BY total_emp_p_score DESC;


--4 What are the main reasons employees are leaving the company?
SELECT reason_for_leaving, COUNT(employee_id) AS no_of_employees_exist
FROM turnover
GROUP BY reason_for_leaving
ORDER BY no_of_employees_exist DESC;


-- SECTION 2 (PERFORMANCE ANALYSIS)

--1 How many employees has left the company?
SELECT COUNT(employee_id) AS total_employees_exist
FROM turnover;

--2 How many employees have a performance score of 5.0 / below 3.5?
SELECT COUNT(e.employee_id) AS total_employees_pscore_below_3_5
FROM employee e
JOIN performance p ON e.employee_id = p.employee_id
WHERE p.performance_score < 3.5;

SELECT COUNT(e.employee_id) AS total_employees_pscore_below_5_0
FROM employee e
JOIN performance p ON e.employee_id = p.employee_id
WHERE performance_score = 5.0;

--3 Which department has the most employees with a performance of 5.0 / below 3.5?

SELECT d.department_name, COUNT (p.employee_id)
FROM department d
JOIN performance p
ON p.department_id = d.department_id
GROUP BY d.department_name, p.performance_score
HAVING p.performance_score = 5.0 or p.performance_score < 3.5
ORDER BY COUNT (p.employee_id) DESC;

--4 What is the average performance score by department?
SELECT e.department_id, d.department_name, COUNT(p.department_id) AS total_no_department,
      round (AVG(p.performance_score),2) AS avg_dep_performance
FROM employee e
JOIN performance p
ON e.department_id = p.department_id
JOIN department d
ON d.department_id = e.department_id
GROUP BY e.department_id, d.department_name 
ORDER BY avg_dep_performance DESC;


-- SECTION 3 (SALARY ANALYSIS)

-- 1 What is the total salary expense for the company?
SELECT TO_CHAR(SUM(salary_amount), 'FM999,999,999.00') AS total_salary_expense
FROM salary;

-- 2 What is the average salary by job title?
SELECT e.job_title, TO_CHAR(AVG(s.salary_amount), 'FM999,999,999.00') AS avg_salary
FROM employee e 
JOIN salary s  
ON e.employee_id = s.employee_id
GROUP BY e.job_title
ORDER BY avg_salary DESC;

--3 How many employees earn above 80,000?
SELECT COUNT(salary_amount) AS salary_above_80k
FROM salary
WHERE salary_amount > 80000;

-- 4 How does performance correlate with salary across departments?
SELECT d.department_name,
       TO_CHAR (AVG(p.performance_score), 'FM999,999,999.00') AS avg_performance_score,
       TO_CHAR (AVG(s.salary_amount), 'FM999,999,999.00') AS avg_salary_amount
FROM employee e 
JOIN department d ON e.department_id = d.department_id
JOIN performance p ON e.employee_id = p.employee_id
JOIN salary s ON e.employee_id = s.employee_id
GROUP BY d.department_name
ORDER BY avg_salary_amount DESC;

-- total number of employee attendance status present/absent
SELECT 
    COUNT(CASE WHEN attendance_status = 'Present' THEN 1 END) AS total_present,
    COUNT(CASE WHEN attendance_status = 'Absent' THEN 1 END) AS total_absent
FROM  attendance
WHERE attendance_date = '2025-05-01';

--monthly  count of employee turnover 
SELECT TO_CHAR(DATE_TRUNC('month', turnover_date), 'YYYY-MM') AS month, COUNT(turnover_id) AS turnover_count
FROM  turnover
WHERE turnover_date IS NOT NULL
GROUP BY DATE_TRUNC('month', turnover_date)
ORDER BY month;

--yearly retained employees
SELECT
    year_series.year AS year,
    COUNT(e.employee_id) AS retained_employees
FROM (
    SELECT generate_series(
        EXTRACT(YEAR FROM MIN(e.hire_date))::int,
        EXTRACT(YEAR FROM CURRENT_DATE)::int
    ) AS year
    FROM employee e
) AS year_series
LEFT JOIN employee e ON EXTRACT(YEAR FROM e.hire_date) <= year_series.year
LEFT JOIN turnover t ON e.employee_id = t.employee_id
    AND EXTRACT(YEAR FROM t.turnover_date) <= year_series.year
WHERE t.turnover_date IS NULL OR EXTRACT(YEAR FROM t.turnover_date) > year_series.year
GROUP BY year_series.year
ORDER BY year_series.year;



