 --(5p) Create a trigger that updates the number of volunteers for a request
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