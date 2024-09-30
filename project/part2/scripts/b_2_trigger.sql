--(5p) Create a trigger that updates the number of volunteers for a request
--whenever the minimum need for any of its skill requirements is changed.
--The total number of volunteers needed for each request is calculated as the sum
-- of unskilled volunteers (those without any skill requirements) and the
-- minimum need for each required skill.

CREATE TRIGGER r.number_of_volunteers -- trigger that updates the total number of volunteers needed for specific request after any of the request's skill requirements are changed
AFTER UPDATE OF rs.min_need -- trigger launched whenever min_need in any request_skill is modified
FOR EACH ROW
BEGIN
	DECLARE skilled_total INT; -- declaring variables for storing skilled total
	DECLARE unskilled_total INT; -- declaring variables for storing
	
	  -- Calculate the total skilled volunteers needed for the request; working with the assumption that request skill always contains some specific skill
	SELECT COALESCE(SUM(rs.min_need), 0) -- this calculates the sum of the column min_need across the skills in the updated request
	INTO skilled_total
	FROM request r  
	JOIN request_skill rs ON rs.request_id = r.id -- requests joined with all the requested skills by matching the request ids
	WHERE r.id = :NEW.request_id; -- but only those related to the specific request_id that has been updated
	
	select r.number_of_volunteers
	into unskilled_total
	from request r; 

  -- Update the total number of volunteers needed for the request
	UPDATE request
	SET total_volunteers_needed = skilled_total + unskilled_total
	WHERE request_id = :NEW.request_id;
END;
