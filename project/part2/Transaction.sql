--(15p) Create a transaction that will read valid applications for a request. Then
--assigns the applicants as such:
--- Prioritize the skills by their value of importance.
--- Assign volunteers with valid applications and who have these skills
--until the minimum number of volunteers needed for the skills is met
--(assigning here means is_accepted gets TRUE, you may also create a
--separate table volunteer_assignment that tracks request_id and
--volunteer_id who got assigned to the request) (you may use your
--scoring system for this)
-- Assign the rest of applied volunteers.
-- If the register by date is not past and the minimum number of
--volunteers is not met (skill based or general), roll back.
-- If the register by date is not past or the minimum number of
--volunteers is met, commit the assignment.
-- If the register by date is past and the minimum number of volunteers
--is not met, either add more time to the register by date or accept the
--volunteers.


	--create temporary table volunteer_assigned ( 
	--	assignment_id SERIAL primary key, 
	--	request_id INT, 
	--	volunteer_id INT, 
	--	volunteer_skill text, 
	--	requested_skill text);

create or replace function assign_volunteers(request_id INT) returns void as $$
declare skill_value int; skill_min_need int;
begin

	
	for skill_value, skill_min_need in 
		select value as skill_value,min_need as skill_min_need from request_skill join request on request.id = request_skill.request_id 
	loop
		raise notice 'skills % %', skill_value, skill_min_need;
	end loop;
	return;
end
$$ language plpgsql;

select from assign_volunteers(1); 


CREATE TABLE volunteer_assigned ( 

assignment_id SERIAL PRIMARY KEY, 

request_id INT, 

volunteer_id INT, 

volunteer_skill text, 

requested_skill text); 

 

BEGIN TRANSACTION; 

-- extracting the number of volunteers needed for the request and the registration deadline 

SELECT r.number_of_volunteers, r.register_by_date 

INTO total_needed, deadline 

FROM request r  

WHERE r.id = :request_id; -- dynamic assignment of the request id of interest 

 

 

WITH prioritizing_skills_order -- prioritize skills by the value of importance; listing request id, skill name, minimum number of people needed 
AS (SELECT  
rs.request_id,  
rs.skill_name,  
rs.min_need,  
ROW_NUMBER() OVER (PARTITION BY rs.request_id ORDER BY rs.value DESC) AS skill_priority_request -- within request id ordering the skills by importance 
FROM request_skill rs), 

applicant_skills_order -- matching volunteers with skills and requests and ordering by the skills importance 
AS	(SELECT  
va.volunteer_id,  
va.request_id,  
sa.skill_name, 
ROW_NUMBER() OVER (PARTITION BY rs.request_id ORDER BY rs.value DESC) AS skill_usefulness -- for each request, if the application is valid, the volunteers's skills are ordered by value of importance for the request 
FROM volunteer_application va  
JOIN skill_assignment sa ON va.volunteer_id = sa.volunteer_id 
JOIN request_skill rs ON va.request_id = rs.request_id AND sa.skill_name = rs.skill_name 
WHERE va.is_valid = TRUE), 

chosen -- matching the volunteers with the requests in order of how well their skills meet the needs 

AS (SELECT  

aso.volunteer_id,  

pso.request_id,  

aso.skill_name 

FROM applicant_skills_order aso 

JOIN prioritizing_skills_order pso ON aso.request_id = pso.request_id AND siao.skill_name = siro.skill_name 

WHERE aso.skill_usefulness <= pso.min_need) -- the rows are combined for each request as long as the integer in the column 'skill_usefulness' is lower or equal to the number of people needed for the skills 

 

-- Insert the information from 'chosen' (assigned volunteers) into the previously created volunteer_assigned table 

INSERT INTO volunteer_assigned (request_id, volunteer_id, volunteer_skill, requested_skill) 

SELECT CAST(c.request_id AS INT),  

CAST(c.volunteer_id AS INT), 

c.skill_name 

FROM chosen c; 

 

-- saving how many volunteers match the needed skills, from the data saved in the new table 

SELECT COUNT(*) AS volunteer_count, 

INTO volunteer_count 

FROM volunteer_assigned 

WHERE va.request_id = :request_id; 

 

-- If the conditions are met, commit the transaction, else roll back 

IF (volunteer_count < total_needed AND CURRENT_TIMESTAMP < deadline) THEN 

ROLLBACK; 

ELSE 

COMMIT; 

END IF; 

 END TRANSACTION; 

 

 