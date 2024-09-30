--For each month, what are the number of valid volunteer applications
--compared to the number of valid requests?
-- What months have the most and least for each, how about the difference between the requests and
--volunteers for each month? Is there a general/seasonal trend? Is there any
--correlation between the time of the year and number of requests and
--volunteers?


select
	month,
	count(*)
from
	(
	select
		id,
		generate_series(extract(month from start_date)::integer,
			extract(month from end_date)::integer) as month
	from
		(
		select
			r.id,
			start_date,
			end_date
		from
			volunteer_application va
		join request r on
			va.request_id = r.id
		where
			va.is_valid = true) a) a
group by
	month
order by
	month;


select month,count(*) from (select id,generate_series(EXTRACT(MONTH FROM start_date)::integer,EXTRACT(MONTH FROM end_date)::integer) as month
from request) a group by month order by month;


