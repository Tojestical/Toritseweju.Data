SELECT * FROM attendance;
SELECT * FROM department;
SELECT * FROM employee;
SELECT * FROM performance;
SELECT * FROM salary;
SELECT * FROM turnover;

--EMPLOYEE RETENTION ANALYSIS
--1 Who are the top 5 highest serving employees?
SELECT e.employee_id, concat(e.first_name,' ', last_name) AS full_name, d.department_name, e.job_title, e.hire_date,
         EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS top_employees_service_years
FROM employee e  
JOIN department d  
ON e.department_id = d.department_id
ORDER BY e.hire_date ASC
LIMIT 5;

--2 What is the turnover rate for each department?
SELECT t.department_id, COUNT(CASE WHEN turnover_date BETWEEN '2024-01-01' AND '2024-12-31' THEN 1 END) 
       AS employees_turnover2024, COUNT(employee_id) AS total_employee, ROUND(
	   (COUNT(CASE WHEN  turnover_date BETWEEN '2024-01-01' AND '2024-12-31' THEN 1 END)::decimal / 
         NULLIF(COUNT(*), 0)) * 100, 2) AS turnover_rate
FROM turnover t  
JOIN department d
ON t.department_id = d.department_id
GROUP BY t.department_id
ORDER BY turnover_rate DESC;


--Which employees are at risk of leaving based on their performance? 
SELECT e.employee_id, CONCAT(e.first_name, ' ', e.last_name) AS employee_name, 
       p.performance_score, p.performance_date,
CASE
     WHEN p.performance_score < 4.5 THEN 'High Risk'
     ELSE 'No Risk'
END AS risk_status
FROM performance p
JOIN employee e 
ON p.employee_id = e.employee_id
ORDER BY p.performance_score DESC;




