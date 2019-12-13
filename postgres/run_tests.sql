CREATE OR REPLACE FUNCTION test_assertEquals_numeric(message VARCHAR, expected NUMERIC, result NUMERIC) RETURNS void as $$
begin
  if expected = result then
    null;
  else
    raise exception 'assertEquals failure: expect % instead of %', expected, result using errcode = 'triggered_action_exception';
  end if;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION test_case_update_quality() RETURNS void AS $$
DECLARE
  sell_in_result item.sell_in%TYPE;
  quality_result item.quality%TYPE;
BEGIN
  TRUNCATE TABLE item;
  CALL new_item('Aged Brie', 4, 6);

  CALL update_quality();

  SELECT quality, sell_in FROM item INTO quality_result, sell_in_result;
  perform test_assertEquals_numeric('Quality should increase', 7, quality_result);
  perform test_assertEquals_numeric('Sell in should decrease', 3, sell_in_result);
END;
$$ LANGUAGE plpgsql;

select * from test_run_all();
