CREATE OR REPLACE FUNCTION test_assertEquals_numeric(message VARCHAR, expected NUMERIC, result NUMERIC) RETURNS void as $$
begin
  if expected = result then
    null;
  else
    raise exception '% assertEquals failure: expect % instead of %', message, expected, result using errcode = 'triggered_action_exception';
  end if;
end;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION test_assertEquals_text(message VARCHAR, expected TEXT, result TEXT) RETURNS void as $$
begin
  if expected = result then
    null;
  else
    raise exception E'% assertEquals failure: expect \n%\n\n instead of \n%', message, expected, result using errcode = 'triggered_action_exception';
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

CREATE OR REPLACE FUNCTION put_line(buffer text, line text) RETURNS text AS $$
BEGIN
    RETURN CONCAT(buffer, E'\n', line);
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_case_update_quality_golden_master() RETURNS void AS $$
DECLARE
  sell_in_result item.sell_in%TYPE;
  quality_result item.quality%TYPE;
  days integer;
  result text;
  expected text;
BEGIN
  -- given
  TRUNCATE TABLE item;
  CALL new_item('+5 Dexterity Vest', 10, 20);
  CALL new_item('Aged Brie', 2, 0);
  CALL new_item('Elixir of the Mongoose', 5, 7);
  CALL new_item('Sulfuras, Hand of Ragnaros', 0, 80);
  CALL new_item('Sulfuras, Hand of Ragnaros', -1, 80);
  CALL new_item('Backstage passes to a TAFKAL80ETC concert', 15, 20);
  CALL new_item('Backstage passes to a TAFKAL80ETC concert', 10, 49);
  CALL new_item('Backstage passes to a TAFKAL80ETC concert', 5, 49);
  -- this conjured item does not work properly yet ;
  CALL new_item('Conjured Mana Cake', 3, 6);
  days := 2;

  -- when
  FOR current_day IN 1 .. days
  LOOP
    result := put_line(result, CONCAT('-------- day ', current_day, ' --------'));
    result := put_line(result, 'name, sellIn, quality');

    -- FOR l_item IN c_items
    -- LOOP
    -- put_line(v_result, l_item.name || ', ' || l_item.sell_in || ', ' || l_item.quality);
    -- END LOOP;

    -- CALL update_quality();
  END LOOP;

  perform test_assertEquals_text('invalid text', expected, result);

  SELECT quality, sell_in FROM item INTO quality_result, sell_in_result;
  perform test_assertEquals_numeric('Quality should increase', 7, quality_result);
  perform test_assertEquals_numeric('Sell in should decrease', 3, sell_in_result);
END;
$$ LANGUAGE plpgsql;

select * from test_run_all();

-- CREATE OR REPLACE PACKAGE BODY texttest IS
--    co_lf   CONSTANT VARCHAR2(1) := CHR(10);

--    PROCEDURE put_line(p_buffer IN OUT NOCOPY VARCHAR2, p_line VARCHAR2) IS
--    BEGIN
--       p_buffer := p_buffer || p_line || co_lf;
--    END put_line;

--    PROCEDURE setup IS
--    BEGIN
--       DELETE FROM ITEM;

--       new_item('+5 Dexterity Vest', 10, 20);
--       new_item('Aged Brie', 2, 0);
--       new_item('Elixir of the Mongoose', 5, 7);
--       new_item('Sulfuras, Hand of Ragnaros', 0, 80);
--       new_item('Sulfuras, Hand of Ragnaros', -1, 80);
--       new_item('Backstage passes to a TAFKAL80ETC concert', 15, 20);
--       new_item('Backstage passes to a TAFKAL80ETC concert', 10, 49);
--       new_item('Backstage passes to a TAFKAL80ETC concert', 5, 49);
--       -- this conjured item does not work properly yet ;
--       new_item('Conjured Mana Cake', 3, 6);
--    END setup;

--    PROCEDURE main_test IS
--       v_result     VARCHAR2(4000) := '';

--       v_expected   VARCHAR2(4000) := '';

--       l_days       NUMBER(3);

--       CURSOR c_items IS SELECT name, sell_in, quality FROM item;

--       l_item       c_items%ROWTYPE;
--    BEGIN
--       put_line(v_expected, 'OMGHAI!');
--       put_line(v_expected, '-------- day 0 --------');
--       put_line(v_expected, 'name, sellIn, quality');
--       put_line(v_expected, '+5 Dexterity Vest, 10, 20' || co_lf || 'Aged Brie, 2, 0');
--       put_line(v_expected, 'Elixir of the Mongoose, 5, 7');
--       put_line(v_expected, 'Sulfuras, Hand of Ragnaros, 0, 80');
--       put_line(v_expected, 'Sulfuras, Hand of Ragnaros, -1, 80');
--       put_line(v_expected, 'Backstage passes to a TAFKAL80ETC concert, 15, 20');
--       put_line(v_expected, 'Backstage passes to a TAFKAL80ETC concert, 10, 49');
--       put_line(v_expected, 'Backstage passes to a TAFKAL80ETC concert, 5, 49');
--       put_line(v_expected, 'Conjured Mana Cake, 3, 6');
--       put_line(v_expected, '-------- day 1 --------');
--       put_line(v_expected, 'name, sellIn, quality');
--       put_line(v_expected, '+5 Dexterity Vest, 9, 19');
--       put_line(v_expected, 'Aged Brie, 1, 1');
--       put_line(v_expected, 'Elixir of the Mongoose, 4, 6');
--       put_line(v_expected, 'Sulfuras, Hand of Ragnaros, 0, 80');
--       put_line(v_expected, 'Sulfuras, Hand of Ragnaros, -1, 80');
--       put_line(v_expected, 'Backstage passes to a TAFKAL80ETC concert, 14, 21');
--       put_line(v_expected, 'Backstage passes to a TAFKAL80ETC concert, 9, 50');
--       put_line(v_expected, 'Backstage passes to a TAFKAL80ETC concert, 4, 50');
--       put_line(v_expected, 'Conjured Mana Cake, 2, 5');

--       put_line(v_result, 'OMGHAI!');
--       l_days := 2;

--       FOR i IN 0 .. l_days - 1
--       LOOP
--          put_line(v_result, '-------- day ' || TO_CHAR(i) || ' --------');
--          put_line(v_result, 'name, sellIn, quality');

--          FOR l_item IN c_items
--          LOOP
--             put_line(v_result, l_item.name || ', ' || l_item.sell_in || ', ' || l_item.quality);
--          END LOOP;

--          update_quality();
--       END LOOP;

--       ut.expect(v_result).to_equal(v_expected);
--    END;
-- END texttest;
-- /