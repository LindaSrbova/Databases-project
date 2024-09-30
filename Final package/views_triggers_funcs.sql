
------------------
--a) Views:
------------------

------------------
-- view 1
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



------------------
-- view 2 - free choice
------------------
--Visualizes the interest areas per city, checking if a certain area is of an  interest (and how many people) in a specific city
create or replace view city_interest as
(select city.name,interest_assignment.interest_name,count(*) as volunteers_count
from city join volunteer on volunteer.city_id = city.id
join interest_assignment on volunteer_id = volunteer.id
group by city.id,city.geolocation,city.name,interest_assignment.interest_name);




-----------------
-- b) Trigger and Functions
------------------

-- Trigger 1: “Finnish personal identity codes are issued by the Population Register
--Centre (DVV). They consist of a string of numbers that indicates the
--individual’s date of birth, an individualized string, and a control character


-- trigger function definition
CREATE OR REPLACE FUNCTION check_valid_input()
RETURNS TRIGGER AS $$
declare
	vol_id text;
    bdate TEXT;
    sepchar text;
    code TEXT;
    code_int INTEGER;
    c_char_code INTEGER;
    control_char text;
    predict_c_char text;
   	
   	len_check BOOL;
    sepchar_check bool;
    control_c_check bool;
   
begin
	vol_id := new.id;
	
	-- extract the elements of volunteer id required for validation
    bdate := substring(vol_id FROM 1 FOR 6);
    sepchar := substring(vol_id FROM 7 for 1);
    code  := substring(vol_id FROM 8 for 3);
    control_char := right(vol_id, 1);
    
    -- compute the control char based on the integer content of the id
    code_int := cast( (bdate || code) as integer);
    c_char_code := code_int % 31;
   	predict_c_char := substring('0123456789ABCDEFHJKLMNPRSTUVWXY' FROM c_char_code+1 FOR 1);
   
    -- compute boolean checkers
    len_check := length(vol_id) = 11;
    sepchar_check := sepchar in ('+', '-', 'A', 'B', 'C', 'D', 'E', 'F', 'X', 'Y', 'W', 'V', 'U');
    control_c_check := (control_char = predict_c_char);
   
	-- process each of the checks one by one
    -- raise an exception if any of them is wrong
    -- print the reason for a failure
    IF not len_check THEN
        RAISE EXCEPTION 'id length is not exactly 11!';
    END IF;
   
   	IF not sepchar_check THEN
        RAISE EXCEPTION 'invalid separator character used!';
    END IF;
   
    IF not control_c_check THEN
        RAISE EXCEPTION 'control character is invalid!';
    END IF;
   
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- trigger definition
CREATE TRIGGER new_volunteer_validation
BEFORE INSERT ON volunteer
FOR EACH ROW
EXECUTE FUNCTION check_valid_input();


-- examples of incorrect ids (prevented by the trigger)
INSERT INTO volunteer (id) VALUES ('121191123-419H'); -- invalid length
INSERT INTO volunteer (id) VALUES ('121191Q419H'); -- invalid separator
INSERT INTO volunteer (id) VALUES ('121191-419H'); -- invalid control char

-- tested with valid inputs as well (the trigger lets them through).



-----------------------------------------------------------------------------------

 --Trigger 2: “Create a trigger that updates the number of volunteers for a request
--whenever the minimum need for any of its skill requirements is changed. The
--total number of volunteers needed for each request is calculated as the sum
--of unskilled volunteers needed (those without any skill requirements) and the
--minimum need for each required skill.

 create function edit_volunteers() returns trigger as $$
 begin
 	update request set number_of_volunteers = 

 	number_of_volunteers + (new.min_need - old.min_need);
 end;
 $$ language plpgsql;
 
 
 create trigger change_volunteers
 after update of min_need on request_skill
 for each row
execute function edit_volunteers();


