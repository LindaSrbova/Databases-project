
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


------------------
-- view 
-----------------
--next to each beneficiary the average number of volunteers that applied, the average age that applied, 
--and the average number of volunteers they need across all of their requests
CREATE view v1_avg_ppl_supdem as 
select r.beneficiary_id, avg(r.number_of_volunteers) as avg_ppl_needed, avg(apps_per_req.app_count) as avg_ppl_applied
from request r, (
	-- nr of applications per request
	select va.request_id, count(id) as app_count
	from volunteer_application va 
	group by va.request_id) as apps_per_req
where r.id  = apps_per_req.request_id
group by r.beneficiary_id;

