-- docker run --name pg-index-testing -p 5432:5432 -e POSTGRES_PASSWORD=123456 -d postgres

-- public.test_indexing definition

-- Drop table
-- DROP TABLE public.test_indexing;

CREATE TABLE public.test_indexing (
	id int4 NOT NULL,
	"json_array" jsonb NOT NULL,
	"name" text NOT NULL
);

CREATE OR REPLACE FUNCTION random_string(n INT) 
RETURNS TEXT AS $$
DECLARE
    chars TEXT[] := '{AAA,BBB,CCC,DDD,EEE,FFF,GGG}';
    result TEXT := '';
    i INT := 0;
    char_index INT;
BEGIN
    -- Loop to generate N characters
    FOR i IN 1..n LOOP
        -- Generate a random index to pick a character from chars array
        char_index := floor(random() * array_length(chars, 1) + 1)::INT;
        -- Concatenate the random character to the result
        result := result || chars[char_index];
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

DO
$do$
BEGIN
	for ind in 1..4000000 loop
		INSERT INTO public.test_indexing
		(id, "json_array", "name")
		VALUES(nextval('index_test_sq'), jsonb('[ {"id":"'||random_string(1)||'","name":"'||random_string(6)||'"},{"id":"'||random_string(1)||'","name":"'||random_string(6)||'"} ]'), 'blah blah');
	end loop;
end
$do$
;

--select count(1) from test_indexing;

--QUERY NOT USING INDEX
select
	t.id as table_id,
	t.name
	--,json_elements.value ->> 'id' as json_id
from
	test_indexing t,
	jsonb_array_elements(t.json_array) as json_elements(value)
where 
	json_elements.value ->> 'id' = 'CCC';


--QUERY USING INDEX
select
	t.id as table_id,
	t.name
	--,t."json_array" as arr
from
	test_indexing t
where
	t."json_array" @> '[{"id":"CCC"}]'
--	t."json_array" @> '[{"name":"EEEDDDFFFDDDFFFAAA"}]'
;

/*
--select count(1) from test_indexing;
--CREATE INDEX test_indexing_gin_idx ON test_indexing USING gin ("json_array");
--drop index test_indexing_gin_idx;
   
--SELECT pg_size_pretty(pg_database_size('postgres'));

VACUUM 
--Without indexing 609 MB
--With indexing    676 MB

DELETE FROM test_indexing 
ALTER TABLE test_indexing DROP CONSTRAINT test_indexing_pk;

*/
