
--The big transaction:
--Create a transaction that will read valid applications for a request. Then
--assigns the applicants as such:











----------------------------------------------------------------------------------
--[free choice] (5p) Create a transaction of your own choice and provide a
--reasoning of your choice.
-- let beneficiaries update the end and regby dates of their requests
-- however, if start-date is older than the new end-date or if the start-date is later than the new regby date 
-- or the new end-date is earlier than the new regby date, then rollover the transaction

begin;

DO $$
DECLARE
   	new_end_date date := '2024-01-01';
    req_id_used integer := 1; -- set here the request id you're willing to change
    check_end_date bool;
begin
	
	WITH req_cte AS (
	    SELECT * FROM request
	    where request.id = req_id_used )

    SELECT new_end_date < req_cte.start_date INTO check_end_date from req_cte;


    -- Raise the exception if the new end-date ends up being earlier than the existing start-date
    IF check_end_date THEN
        RAISE EXCEPTION 'The new end-date cannot be earlier than the start-date';

    ELSE
        -- If the condition is satisfied, update the row
        UPDATE request
        SET end_date = new_end_date, register_by_date = new_end_date
        where id = req_id_used; 
       
    END IF;
END $$;

-- Commit the transaction if no exception was raised
COMMIT;   

   
select *
from request
where id = 1