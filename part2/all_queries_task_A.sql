
-- 1.For each request, include the starting date and the end date in the title.
UPDATE request 
SET title = title || ' from '|| start_date|| ' to ' || end_date;


--2.For each request, find volunteers whose skill assignments match the
--requesting skills. List these volunteers from those with the most matching
--skills to those with the least (even 0 matching skills). Only consider
--volunteers who applied to the request and have a valid application
SELECT va.volunteer_id
FROM request r
JOIN volunteer_application va ON va.request_id = r.id
LEFT JOIN request_skill rs ON rs.request_id = r.id -- joins requests with skills, if there are no requested skills assigned, then it is assigned to be NULL
LEFT JOIN skill_assignment sa ON sa.volunteer_id = va.volunteer_id AND sa.skill_name = rs.skill_name -- left join tries to include volunteers skills by matching the volunteer id. The sa.skill_name will be kept as it is, if its matches with request skills, otherwise it will contain NULL values
WHERE va.is_valid = TRUE -- condition to select only valid applications
GROUP BY va.volunteer_id -- groups the rows by volutneer id
ORDER BY COUNT(sa.skill_name) DESC; -- ordering from highest to lowest number of matching skills per volunteer. Since column of skill name contains null values whenever it does not match the requested skill, the function count (does not count NULL values) can be used to count the number of matching skills

--3. For each request, show the missing number of volunteers needed per
--skill (minimum needed of that skill). Assume a volunteer fulfills the need for all
--the skills they possess.
select rs.request_id, rs.skill_name, (rs.min_need - COUNT(DISTINCT sa.volunteer_id)) AS missing_skills_count
-- reporting request id for each skill (thus each request id will have as many rows as there is the number of assigned skills to it)
-- reporting the number of people that are still needed 
from request_skill rs
join volunteer_application va on rs.request_id =va.request_id -- joining volunteer applications with requests for skills
join skill_assignment sa on sa.volunteer_id = va.volunteer_id -- joining volunteer skills by volunteer id
where rs.skill_name =sa.skill_name OR rs.skill_name IS null -- selecting rows where there is a match between the skills, of the volunteer who applied, and the listed skill needed
group by rs.request_id,rs.skill_name, rs.min_need -- group by request id
HAVING 
(rs.min_need - COUNT(DISTINCT sa.volunteer_id)) > 0; -- filter to show only the requests and the related skills for which there are volunteers still missing
-- reducing the number of volunteers needed for the skills of the specific request by each distinct volunteer that applied and matches the skill


--4. Sort requests and the beneficiaries who made them by the highest
--number of priority (requestʼs priority value) and the closest 'register by date'.
SELECT r.title , b."name" 
FROM request r
JOIN beneficiary b ON r.beneficiary_id = b.id -- Join request and beneficiary by matching the beneficiary id
where r.register_by_date > current_date -- removing those requests that have already passed the registration deadline
ORDER BY 
r.priority_value DESC, -- Ordering by request's priority from the highest
r.register_by_date ASC; -- Sort by register by the closest register date - the most urgent


--5.For each volunteer, list requests that are within their volunteer range and
--match at least 2 of their skills (also include requests that donʼt require any skills)
SELECT vr.volunteer_id, rl.request_id, 
from request r 
JOIN request_location rl ON r.id = rl.request_id --joining request and range by id
join volunteer_range vr on vr.city_id = rl.city_id -- joining volunteer range by city
JOIN skill_assignment sa ON vr.volunteer_id = sa.volunteer_id -- joining volunteer skills by matching volunteer ids
LEFT JOIN request_skill rs ON rs.request_id = rl.request_id -- joining requested skills by request id; left join ensures that if no request skills are for the given request, then the skills column is null
and rs.skill_name = sa.skill_name -- Adjusted LEFT JOIN condition, the matching is only if the requested and volunteer skills match
GROUP BY vr.volunteer_id, rl.request_id -- grouping
HAVING 
COUNT(*) >= 2 --for each volunteer and request, count those that have more than 2 rows (ie fulfilling the conditions of matching and range)


--6.adding a new empty column in request 
ALTER TABLE request ADD COLUMN normalized_title VARCHAR(255);

--the column filled up with edited title to be same format as interest_name 
--(selecting string until ‘need’ - to remove the dates and include only info that is indicated in volunteers’ assignment of interest; 
--first letter of word in caps and removing space between words)
update request 
SET normalized_title = REGEXP_REPLACE( 
INITCAP( CASE
	WHEN POSITION('needed' IN title) > 0 THEN
	LEFT(title, POSITION('needed' IN title) - 1)
else title end),'[^a-zA-Z0-9]+', '', 'g');

-- For each volunteer, listing all the requests where the title matches their area
--of interest and are still available to register.
select r.title
from interest_assignment ia 
JOIN request r ON ia.interest_name LIKE r.normalized_title
WHERE r.register_by_date > CURRENT_DATE;


--7. Listing the request ID and the volunteers who applied to them (name and
-- email) but are not within the location range of the request. Order volunteers by readiness to travel.
select r.id, v."name",v.email -- listing request ID, volunteer name and email 
from request r		-- first table is request 
join request_location rl on rl.request_id = r.id -- joining info on the location at which the request is needed, it can be at multiple distinct locations 
inner join volunteer_application va on r.id =va.request_id -- joining request table and volunteer application only for rows where the request id is matching. One request has often many applications, even from the same person 
join volunteer v on v.id = va.volunteer_id -- joining volunteer table by matching volunteer id with volunteer application table. One volunteer, with specific name, email, and travel_readiness, usually submits many applications to different requests
join volunteer_range vr on vr.volunteer_id = va.volunteer_id -- adding information on the volunteer location 
where vr.city_id != rl.city_id -- selecting only the rows where the volunteer and request locations do not match 
group by r.id, va.request_id, va.id, v."name",v.email, v.travel_readiness -- Each volunteer can have many locations and each request can have many locations. Therefore, for each request, all the possible combinations, where these don’t match, are listed. To not list them separately by locations, we group them. 
order by v.travel_readiness ; -- ordering the list by travel_readiness which is specific for each volunteer

--8. Order the skills overall (from all requests) in the most prioritized to least prioritized (average the importance value)
SELECT rs.skill_name -- listing the skills in order
FROM request_skill rs -- from table request_skill, which already contains all the skills requested by beneficiaries
GROUP BY rs.skill_name -- we group it by skills, because the skills are repated in many requests
ORDER BY avg(rs.value) DESC; -- and for each skill we calculate the average val


--------------------
-- FREE QUERIES
---------------------

-- find volunteers and beneficiaries that reside in the same city, given that volunteers applied for the requests made by those beneficiaries
select distinct b.name as ben_name, v.name as vol_name,  c."name" as city_name
from volunteer v, volunteer_application va, request r, beneficiary b, city c
where v.id = va.volunteer_id and va.request_id = r.id and r.beneficiary_id = b.id and v.city_id = b.city_id and v.city_id = c.id;

-- find volunteers who do not want to travel outside the city where they reside 
select v_home."name", v_home.id, c."name" 
from city c, (
	-- among volunteers, find only those who chose only their home city as the volunteer_range
	select v."name", v.id, v.city_id
	from volunteer v
	except ( 
		-- cut off volunteers who chose cities different from their home city
		select distinct  v.name, v.id, vr.city_id
		from volunteer v, volunteer_range vr
		where v.id=vr.volunteer_id and v.city_id <> vr.city_id)
		) as v_home
where c.id = v_home.city_id;

-- see how many skills volunteers have relative to the number of requests they applied for
select v."name", sa.volunteer_id, vol_req_count.req_count, count(sa.skill_name) as skill_count
from volunteer v, skill_assignment sa, (
	-- count the nr of requests each volunteer applied for
	select va.volunteer_id, count(va.request_id) as req_count
	from volunteer_application va
	group by va.volunteer_id) as vol_req_count	
where v.id = sa.volunteer_id and v.id = vol_req_count.volunteer_id
group by sa.volunteer_id, vol_req_count.req_count, v."name";


-- for each request, see the number of applications compared to the min_number of people needed (skills not verified)
select rs.request_id, sum(rs.min_need) as ppl_needed, req_app_cnt.appls_count
from request_skill rs, (
	-- count the nr of applications submitted for each request
	select va.request_id, count(id) as appls_count
	from volunteer_application va 
	group by request_id) as req_app_cnt
where rs.request_id = req_app_cnt.request_id				
group by rs.request_id, req_app_cnt.request_id, req_app_cnt.appls_count;


