CREATE OR REPLACE FUNCTION parse_id(input_text TEXT)
RETURNS TABLE(birthdate_int text, separator text, code_int text, last_char text) AS $$
BEGIN
    RETURN QUERY
    SELECT
        substring(input_text FROM 1 FOR 6) AS birthdate_int,
        substring(input_text FROM 7 for 1) as separator,
        substring(input_text FROM 8 for 3) as code_int,
        right(input_text, 1) AS last_char;
       
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION id_code(vol_id TEXT)
RETURNS INTEGER AS $$
DECLARE
    bdate TEXT;
    code TEXT;
    code_int INTEGER;
    c_char_code INTEGER;
BEGIN
    bdate := substring(vol_id FROM 1 FOR 6);
    code  := substring(vol_id FROM 8 for 3);
    code_int := cast( (bdate || code) as integer);
    c_char_code := code_int % 31;

    RETURN c_char_code;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION predict_control_char(vol_id TEXT)
RETURNS TEXT AS $$
DECLARE
    bdate TEXT;
    code TEXT;
    code_int INTEGER;
    c_char_code INTEGER;
BEGIN
    bdate := substring(vol_id FROM 1 FOR 6);
    code  := substring(vol_id FROM 8 for 3);
    code_int := cast( (bdate || code) as integer);
    c_char_code := code_int % 31;

    RETURN substring('0123456789ABCDEFHJKLMNPRSTUVWXY' FROM c_char_code+1 FOR 1);

END;
$$ LANGUAGE plpgsql;



-- check constraint for the volunteer table
-- The ID is valid if they satisfies: len(id) = 11, valid separator char, correct control character is used
CREATE OR REPLACE FUNCTION check_all_(vol_id TEXT)
RETURNS BOOL AS $$
DECLARE
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
   
BEGIN
    bdate := substring(vol_id FROM 1 FOR 6);
    sepchar := substring(vol_id FROM 7 for 1);
    code  := substring(vol_id FROM 8 for 3);
    control_char := right(vol_id, 1);
    
    -- compute the control char based on the integer content of the id
    code_int := cast( (bdate || code) as integer);
    c_char_code := code_int % 31;
   	predict_c_char := substring('0123456789ABCDEFHJKLMNPRSTUVWXY' FROM c_char_code+1 FOR 1);
   
    len_check := length(vol_id) = 11;
    sepchar_check := sepchar in ('+', '-', 'A', 'B', 'C', 'D', 'E', 'F', 'X', 'Y', 'W', 'V', 'U');
    control_c_check = (control_char = predict_c_char);
   
   
    RETURN len_check and sepchar_check and control_c_check;

END;
$$ LANGUAGE plpgsql;



SELECT v.id, parsed.last_char, predict_control_char(v.id), check_all_(v.id)
FROM volunteer v, lateral parse_id(v.id) as parsed;



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

-- tested with valid inputs as well (the trigger lets them through)


