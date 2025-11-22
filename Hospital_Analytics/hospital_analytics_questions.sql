-- Connect to database (MySQL only)
USE hospital_db;

select * from encounters;
select * from patients;
select * from payers;
select * from procedures;

-- OBJECTIVE 1: ENCOUNTERS OVERVIEW

-- a. How many total encounters occurred each year?
select YEAR(START) as year, count(*) as total_encounter  FROM encounters group by YEAR(START) order by year;

-- b. For each year, what percentage of all encounters belonged to each encounter class
-- (ambulatory, outpatient, wellness, urgent care, emergency, and inpatient)?
select YEAR(START) as yr,
round(sum(case when ENCOUNTERCLASS='ambulatory' then 1 else 0 end)/count(*)*100,1) as 'ambulatory',
round(sum(case when ENCOUNTERCLASS='outpatient' then 1 else 0 end)/count(*)*100,1) as 'outpatient',
round(sum(case when ENCOUNTERCLASS='wellness' then 1 else 0 end)/count(*)*100,1) as 'wellness',
round(sum(case when ENCOUNTERCLASS='urgentcare' then 1 else 0 end)/count(*)*100,1) as 'urgentcare',
round(sum(case when ENCOUNTERCLASS='emergency' then 1 else 0 end)/count(*)*100,1) as 'emergency',
round(sum(case when ENCOUNTERCLASS='inpatient' then 1 else 0 end)/count(*)*100,1) as 'inpatient'
 from encounters 
 group by yr
 order by yr;

-- c. What percentage of encounters were over 24 hours versus under 24 hours?
with cte as (select  timestampdiff(HOUR, start,stop) as encounter_time from encounters) 
select  round(sum(case when encounter_time>=24 then 1 else 0 end)/count(*) * 100,1) as Encounter_Over24,
		round(sum(case when encounter_time<24 then 1 else 0 end)/count(*) * 100,1) as Encounter_Under24
from cte;

-- OBJECTIVE 2: COST & COVERAGE INSIGHTS

-- a. How many encounters had zero payer coverage, and what percentage of total encounters does this represent?
select 
sum(case when PAYER_COVERAGE=0 then 1 else 0 end) as zero_payer_coverage,
round(sum(case when PAYER_COVERAGE=0 then 1 else 0 end)/count(*) * 100,1) as percentage_of_total
from encounters;

-- b. What are the top 10 most frequent procedures performed and the average base cost for each?

select CODE,DESCRIPTION, avg(BASE_COST) as avg_base_cost,count(*) as count_of_procedure
from procedures
group by CODE, DESCRIPTION
order by count_of_procedure desc;

-- c. What are the top 10 procedures with the highest average base cost and the number of times they were performed?
select CODE, round(avg(BASE_COST),2) as avg_base_cost, count(*) as no_of_times_performed
from procedures
group by code
order by avg_base_cost desc
limit 10;
-- d. What is the average total claim cost for encounters, broken down by payer?

select p.NAME, round(avg(TOTAL_CLAIM_COST),2) as avg_total_claim_cost
from payers p left join encounters e
on p.Id=e.PAYER
group by p.NAME
order by avg_total_claim_cost desc;

-- OBJECTIVE 3: PATIENT BEHAVIOR ANALYSIS

-- a. How many unique patients were admitted each quarter over time?

select  year(e.START) as year,quarter(e.START) as quarter, count(distinct PATIENT) 
from
patients p left join encounters e
on p.Id=e.PATIENT
group by year(e.START),quarter(e.START)
order by year, quarter
;

-- b. How many patients were readmitted within 30 days of a previous encounter?

with cte as (select PATIENT,START,STOP,
	lead(START) over(partition by PATIENT ORDER BY START) AS next_admission_date
	from encounters)
select count(DISTINCT PATIENT) AS COUNT_OF_PATIENTS
from cte
where datediff(next_admission_date, STOP) <30;

-- c. Which patients had the most readmissions?
with cte as (select PATIENT,START,STOP,
	lead(START) over(partition by PATIENT ORDER BY START) AS next_admission_date
	from encounters)
select PATIENT, COUNT(*) AS No_of_readmissions
from cte
where datediff(next_admission_date, STOP) <30
group by patient
order by No_of_readmissions desc;