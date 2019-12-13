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

CREATE OR REPLACE FUNCTION test_assertEquals_golden_master(expected TEXT, result TEXT) RETURNS void as $$
DECLARE
    golden text;
begin
  if expected = result then
    null;
  else
    golden := CONCAT('expected := put_line(expected, ''', REPLACE(result, E'\n', E''');\nexpected := put_line(expected, '''), ''');');
    raise exception E'assertEquals failure: expect \n%\n\n instead of \n%\n\nFor update, copy:\n%', expected, result, golden using errcode = 'triggered_action_exception';
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
    IF buffer IS NULL
    THEN RETURN line;
    ELSE RETURN CONCAT(buffer, E'\n', line);
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION test_case_update_quality_golden_master() RETURNS void AS $$
DECLARE
  sell_in_result item.sell_in%TYPE;
  quality_result item.quality%TYPE;
  days integer;
  result text;
  expected text;
  item_result RECORD;
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
  days := 10;               

  -- when
  FOR current_day IN 1 .. days
  LOOP
    result := put_line(result, CONCAT('-------- day ', current_day, ' --------'));
    result := put_line(result, 'name, sellIn, quality');

    CALL update_quality();

    FOR item_result IN (SELECT name, sell_in, quality FROM item ORDER BY name ASC, sell_in ASC, quality ASC) 
    LOOP
      result := put_line(result, format('%s, %s, %s', item_result.name, item_result.sell_in, item_result.quality));
    END LOOP;
  END LOOP;

  -- then
  expected := put_line(expected, '-------- day 1 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 9, 19');                                                   
  expected := put_line(expected, 'Aged Brie, 1, 1');                                                            
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 4, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 9, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 14, 21');                          
  expected := put_line(expected, 'Conjured Mana Cake, 2, 5');                                                   
  expected := put_line(expected, 'Elixir of the Mongoose, 4, 6');                                               
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                          
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 2 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 8, 18');                                                   
  expected := put_line(expected, 'Aged Brie, 0, 2');                                                            
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 3, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 8, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 13, 22');                          
  expected := put_line(expected, 'Conjured Mana Cake, 1, 4');                                                   
  expected := put_line(expected, 'Elixir of the Mongoose, 3, 5');                                               
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 3 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 7, 17');                                                   
  expected := put_line(expected, 'Aged Brie, -1, 4');                                                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 2, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 7, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 12, 23');                           
  expected := put_line(expected, 'Conjured Mana Cake, 0, 3');                                                   
  expected := put_line(expected, 'Elixir of the Mongoose, 2, 4');                                               
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 4 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 6, 16');                                                   
  expected := put_line(expected, 'Aged Brie, -2, 6');                                                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 1, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 6, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 11, 24');                          
  expected := put_line(expected, 'Conjured Mana Cake, -1, 1');                                                  
  expected := put_line(expected, 'Elixir of the Mongoose, 1, 3');                                               
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 5 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 5, 15');                                                   
  expected := put_line(expected, 'Aged Brie, -3, 8');                                                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 0, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 5, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 10, 25');                          
  expected := put_line(expected, 'Conjured Mana Cake, -2, 0');                                                  
  expected := put_line(expected, 'Elixir of the Mongoose, 0, 2');                                               
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 6 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 4, 14');                                                   
  expected := put_line(expected, 'Aged Brie, -4, 10');                                                          
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, -1, 0');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 4, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 9, 27');                           
  expected := put_line(expected, 'Conjured Mana Cake, -3, 0');                                                  
  expected := put_line(expected, 'Elixir of the Mongoose, -1, 0');                                              
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 7 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 3, 13');                                                   
  expected := put_line(expected, 'Aged Brie, -5, 12');                                                          
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, -2, 0');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 3, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 8, 29');                           
  expected := put_line(expected, 'Conjured Mana Cake, -4, 0');                                                  
  expected := put_line(expected, 'Elixir of the Mongoose, -2, 0');                                              
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 8 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 2, 12');                                                   
  expected := put_line(expected, 'Aged Brie, -6, 14');                                                          
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, -3, 0');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 2, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 7, 31');                           
  expected := put_line(expected, 'Conjured Mana Cake, -5, 0');                                                  
  expected := put_line(expected, 'Elixir of the Mongoose, -3, 0');                                              
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 9 --------');                                                    
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 1, 11');                                                   
  expected := put_line(expected, 'Aged Brie, -7, 16');                                                          
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, -4, 0');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 1, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 6, 33');                           
  expected := put_line(expected, 'Conjured Mana Cake, -6, 0');                                                  
  expected := put_line(expected, 'Elixir of the Mongoose, -4, 0');                                              
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');                                          
  expected := put_line(expected, '-------- day 10 --------');                                                   
  expected := put_line(expected, 'name, sellIn, quality');                                                      
  expected := put_line(expected, '+5 Dexterity Vest, 0, 10');                                                   
  expected := put_line(expected, 'Aged Brie, -8, 18');                                                          
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, -5, 0');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 0, 50');                           
  expected := put_line(expected, 'Backstage passes to a TAFKAL80ETC concert, 5, 35');                           
  expected := put_line(expected, 'Conjured Mana Cake, -7, 0');                                                  
  expected := put_line(expected, 'Elixir of the Mongoose, -5, 0');                                              
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, -1, 80');                                         
  expected := put_line(expected, 'Sulfuras, Hand of Ragnaros, 0, 80');   
  perform test_assertEquals_golden_master(expected, result);
END;
$$ LANGUAGE plpgsql;

select * from test_run_all();
