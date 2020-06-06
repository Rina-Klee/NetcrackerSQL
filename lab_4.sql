--ЛР №4
/* 
4.1 В анонимном PL/SQL блоке распечатать все пифагоровы числа, меньшие 25 
(для печати использовать пакет dbms_output, процедуру put_line).*/

DECLARE
  max_number INT := 25;
BEGIN
  FOR i IN 1..max_number LOOP
    FOR j IN i..max_number LOOP
      FOR k IN j..max_number LOOP
        IF i*i + j*j = k*k THEN
          dbms_output.put_line(i || ' ' || j || ' ' || k || '  ' || i*i || '+' || j*j || '=' || k*k);
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;
END;
/

/* 
4.2 Переделать предыдущий пример, чтобы для определения, что 3 числа пифагоровы использовалась функция.*/

CREATE FUNCTION fn_pifagor_check_cond(
  i INT,
  j INT,
  k INT
) RETURN BOOLEAN
IS
BEGIN
  RETURN (i*i + j*j) = k*k;
END;
  
DECLARE
  max_number INT := 25;
BEGIN
  FOR i IN 1..max_number LOOP
    FOR j IN i..max_number LOOP
      FOR k IN j..max_number LOOP
        IF fn_pifagor_check_cond(i, j, k) THEN
          dbms_output.put_line(i || ' ' || j || ' ' || k || '  ' || i*i || '+' || j*j || '=' || k*k);
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;
END;
/

/*
4.3 Написать хранимую процедуру, которой передается ID сотрудника и которая увеличивает ему зарплату на 10%,
если в 2000 году у сотрудника были продажи. Использовать выборку количества заказов за 2000 год в переменную.
А затем, если переменная больше 0, выполнить update данных.*/

SELECT  o.*
  FROM  orders o
  WHERE DATE'2000-01-01' <= o.order_date AND o.order_date < DATE'2001-01-01'
  ORDER BY  o.sales_rep_id
;
  
CREATE PROCEDURE pr_increase_salary(par_id employees.employee_id%TYPE)
IS
  var_orders INT;
BEGIN
  SELECT  COUNT(o.order_id)
    INTO  var_orders
    FROM  orders o
    WHERE o.sales_rep_id = par_id AND
          DATE'2000-01-01' <= o.order_date AND o.order_date < DATE'2001-01-01';
  IF var_orders > 0 THEN
    UPDATE  employees e
      SET   e.salary = e.salary * 1.1
      WHERE e.employee_id = par_id;
  END IF;
END;
/

DECLARE
  var_order_count INT;
  var_salary employees.salary%TYPE;
  var_emp_id employees.employee_id%TYPE := 155;
BEGIN
  SELECT  e.salary
    INTO  var_salary
    FROM  employees e
    WHERE e.employee_id = var_emp_id;
  dbms_output.put_line('before:' || '' || var_salary);
  pr_increASe_salary(var_emp_id);
  SELECT  e.salary
    INTO  var_salary
    FROM  employees e
    WHERE e.employee_id = var_emp_id;
  dbms_output.put_line('after:' || '' ||var_salary);
END;
/

/* 
4.4 Проверить корректность данных о заказах, а именно, что поле ORDER_TOTAL равно сумме UNIT_PRICE * QUANTITY 
по позициям каждого заказа. Для этого создать хранимую процедуру, в которой будет в цикле for проход по всем заказам,
далее по конкретному заказу отдельным select-запросом будет выбираться сумма по позициям данного заказа 
и сравниваться с ORDER_TOTAL. Для «некорректных» заказов распечатать код заказа, дату заказа, заказчика и менеджера.
*/

CREATE PROCEDURE pr_check_order_total
IS
  var_order_total orders.order_total%TYPE;
  var_real_price number;
BEGIN
  FOR i_order IN (
    SELECT  o.*
      FROM  orders o
  ) LOOP
    var_order_total := i_order.order_total;
    SELECT  SUM(oi.unit_price * oi.quantity)
      INTO  var_real_price
      FROM  order_items oi
      WHERE oi.order_id = i_order.order_id;
    IF var_real_price <> var_order_total THEN
      dbms_output.put_line(i_order.order_id || ' ' || i_order.order_date || ' ' || i_order.customer_id || ' ' || i_order.sales_rep_id);
    END IF;
  END LOOP;
END;
/
  
DECLARE
BEGIN
  pr_check_order_total();
END;
/

/* 
4.5 Переписать предыдущее задание с использованием явного курсора.*/

CREATE PROCEDURE pr_check_order_total_explict_cursor
IS
  CURSOR cur_check IS
    SELECT  o.order_id,
            oi.real_price,
            o.order_total,
            o.order_date,
            o.customer_id,
            o.sales_rep_id
      FROM  orders o
            INNER JOIN (SELECT  SUM(oi.unit_price * oi.quantity) AS real_price,
                                oi.order_id
                          FROM  order_items oi
                          GROUP BY oi.order_id
                  ) oi ON
                    oi.order_id = o.order_id;

  var_order cur_check%rowtype;
BEGIN
  OPEN cur_check;
  LOOP
    FETCH cur_check INTO var_order;
    EXIT WHEN cur_check%notfound;
    IF var_order.order_total <> var_order.real_price THEN
      dbms_output.put_line(var_order.order_id || ' ' || var_order.order_date || ' ' || var_order.customer_id || ' ' || var_order.sales_rep_id);
    END IF;
  END LOOP;        
END;
/

DECLARE
BEGIN
  pr_check_order_total_explict_cursor();
END;
/

/* 
4.6 Написать функцию, в которой будет создан тестовый клиент, которому будет сделан заказ
на текущую дату из одной позиции каждого товара на складе. Имя тестового клиента и ID склада передаются в качестве параметров.
Функция возвращает ID созданного клиента.*/

CREATE FUNCTION fn_make_test_order(
   par_first_name IN customers.cust_first_name%TYPE,
   par_last_name IN customers.cust_last_name%TYPE,
   par_warehouse_id IN warehouses.warehouse_id%TYPE
) RETURN customers.customer_id%TYPE
IS 
  var_customer_id customers.customer_id%TYPE;
  var_order_id orders.order_id%TYPE;
  var_line_item_id order_items.line_item_id%TYPE := 1;
  var_order_total orders.order_total%TYPE := 0;
BEGIN
  INSERT INTO customers (cust_first_name, cust_last_name)
    VALUES (par_first_name, par_last_name)
    RETURNING customer_id INTO var_customer_id;
  INSERT INTO orders (order_date, customer_id)
    VALUES (sysdate, var_customer_id)
    RETURNING order_id INTO var_order_id;
  FOR i_product IN (
    SELECT pi.*
      FROM  inventories inv
            JOIN product_information pi ON 
              pi.product_id = inv.product_id
      WHERE inv.warehouse_id = par_warehouse_id and
            inv.quantity_on_hand > 0
  ) LOOP
    INSERT INTO order_items (order_id, line_item_id, product_id, unit_price, quantity)
      VALUES (var_order_id, var_line_item_id, i_product.product_id, i_product.list_price, 1);
    var_line_item_id := var_line_item_id + 1;
    var_order_total := var_order_total + i_product.list_price;
  END LOOP;
  UPDATE  orders 
     SET  order_total = var_order_total
    WHERE order_id = var_order_id;
  RETURN var_customer_id;
END;
/

DECLARE
BEGIN
  dbms_output.put_line(fn_make_test_order('Ekaterina', 'Fateeva', 1));
END;
/

SELECT  oi.*,
        c.customer_id,
        c.cust_first_name,
        c.cust_last_name
  FROM  orders o LEFT JOIN customers c 
          ON c.customer_id = o.customer_id
        LEFT JOIN order_items oi
          ON o.order_id = oi.order_id
  WHERE c.customer_id = 1000
;

SELECT  COUNT(DISTINCT oi.line_item_id)
  FROM  order_items oi
;

/* 
4.7 Добавить в предыдущую функцию проверку на существование склада с переданным ID. 
Для этого выбрать склад в переменную типа «запись о складе» и перехватить исключение no_data_found, 
если оно возникнет. В обработчике исключения выйти из функции, вернув null.
*/

CREATE FUNCTION fn_make_test_order_expr_example(
     par_first_name IN customers.cust_first_name%TYPE,
     par_last_name IN customers.cust_last_name%TYPE,
     par_warehouse_id IN warehouses.warehouse_id%TYPE
  ) RETURN customers.customer_id%TYPE
  IS 
    var_warehouse warehouses%ROWTYPE;
    var_customer_id customers.customer_id%TYPE;
    var_order_id orders.order_id%TYPE;
    var_line_item_id order_items.line_item_id%TYPE := 1;
    var_order_total orders.order_total%TYPE := 0;
  BEGIN
    BEGIN
      SELECT  *
        INTO  var_warehouse
        FROM  warehouses w
        WHERE w.warehouse_id = par_warehouse_id;
    EXCEPTION
    WHEN no_data_found THEN
      RETURN NULL;
    END;
    INSERT INTO customers (cust_first_name, cust_last_name)
      VALUES (par_first_name, par_last_name)
      RETURNING customer_id INTO var_customer_id;
    INSERT INTO orders (order_date, customer_id)
      VALUES (sysdate, var_customer_id)
      RETURNING order_id INTO var_order_id;
    FOR i_product IN (SELECT pi.*
                          FROM  inventories inv
                                JOIN product_inFORmatiON pi ON 
                                  pi.product_id = inv.product_id
                          WHERE inv.warehouse_id = par_warehouse_id AND
                                inv.quantity_on_hand > 0) LOOP
      INSERT INTO order_items (order_id, line_item_id, product_id, unit_price, quantity)
        VALUES (var_order_id, var_line_item_id, i_product.product_id, i_product.list_price, 1);
      var_line_item_id := var_line_item_id + 1;
      var_order_total := var_order_total + i_product.lISt_price;
    END LOOP;
    UPDATE  orders 
         SET  order_total = var_order_total
        WHERE order_id = var_order_id;
      RETURN var_customer_id;
    RETURN var_customer_id;
END;
/

DECLARE
BEGIN
  dbms_output.put_line(fn_make_test_order_expr_example('Ekaterina', 'Fateeva', 1));
END;
/

/*
4.8 Написанные процедуры и функции объединить в пакет FIRST_PACKAGE.*/

CREATE OR REPLACE PACKAGE first_package AS  
 FUNCTION fn_pifagor_check_cond(
    i INT,
    j INT,
    k INT
  ) RETURN BOOLEAN;

  PROCEDURE pr_increase_salary(par_id employees.employee_id%TYPE);

  PROCEDURE pr_check_order_total;

  PROCEDURE pr_check_order_total_explict_cursor;

 FUNCTION fn_make_test_order(
     par_first_name IN customers.cust_first_name%TYPE,
     par_last_name IN customers.cust_last_name%TYPE,
     par_warehouse_id IN warehouses.warehouse_id%TYPE
  ) RETURN customers.customer_id%TYPE;
  
 FUNCTION fn_make_test_order_expr_example(
     par_first_name IN customers.cust_first_name%TYPE,
     par_last_name IN customers.cust_last_name%TYPE,
     par_warehouse_id IN warehouses.warehouse_id%TYPE
  ) RETURN customers.customer_id%TYPE;
END first_package;
/

/* 
4.9 Написать функцию, которая возвратит таблицу (table of record), содержащую информацию 
о частоте встречаемости отдельных символов во всех названиях (и описаниях) товара на заданном языке 
(передается код языка, а также параметр, указывающий, учитывать ли описания товаров). 
Возвращаемая таблица состоит из 2-х полей: символ, частота встречаемости в виде частного от кол-ва данного символа 
к количеству всех символов в названиях (и описаниях) товара.
*/

CREATE TYPE tp_char_result AS 
OBJECT(
  ch NCHAR(1), 
  freq number
);
/
CREATE TYPE tp_char_result_table AS
TABLE OF tp_char_result;
/
CREATE FUNCTION fn_char_find_freq(
  par_lang_id IN product_descriptions.language_id%TYPE,
  par_description IN INT
) RETURN tp_char_result_table
IS 
  TYPE tp_char_result_indexed_table IS 
    TABLE OF tp_char_result INDEX BY binary_integer;
  var_result_table tp_char_result_table;
  var_indexed_table tp_char_result_indexed_table;
  var_ch NCHAR(1);
  var_code binary_integer;
BEGIN 
  var_result_table := tp_char_result_table();
  FOR i_pd IN (SELECT  *
                 FROM  product_descriptions pd
                 WHERE pd.language_id = par_lang_id
  ) LOOP
    FOR i_l IN 1..LENGTH(i_pd.translated_name) LOOP
      var_ch := substr(i_pd.translated_name, i_l, 1);
      var_code := ASCII(var_ch);
      IF NOT var_indexed_table.exists(var_code) THEN
        var_indexed_table(var_code) := tp_char_result(var_ch, 0);
      END IF;
      var_indexed_table(var_code).freq := var_indexed_table(var_code).freq + 1;
    END LOOP;
  END LOOP;
  IF par_descriptiON>0 THEN 
    FOR i_pd IN (SELECT  *
                   FROM  product_descriptions pd
                   WHERE pd.language_id = par_lang_id
    ) LOOP
      FOR i_l IN 1..LENGTH(i_pd.translated_description) LOOP
        var_ch := substr(i_pd.translated_descriptiON, i_l, 1);
        var_code := ASCII(var_ch);
        IF NOT var_indexed_table.exists(var_code) THEN
          var_indexed_table(var_code) := tp_char_result(var_ch, 0);
        END IF;
        var_indexed_table(var_code).freq := var_indexed_table(var_code).freq + 1;
      END LOOP;
    END LOOP;
  END IF;
  var_code := var_indexed_table.first;
  WHILE var_code IS NOT NULL
    LOOP
      var_result_table.extend(1);
      var_result_table(var_result_table.last) := var_indexed_table(var_code);
      var_code := var_indexed_table.next(var_code);
    END LOOP;
  RETURN var_result_table;
END;
/
DECLARE
  var_result tp_char_result_table;
BEGIN
  var_result := fn_char_find_freq('RU', 1);
  FOR i IN 1..var_result.count
    LOOP
      dbms_output.put_line(var_result(i).ch || ' ' || var_result(i).freq);
    END LOOP;
END;
/
SELECT  *
  FROM  TABLE(CAST(fn_char_find_freq('RU', 1) AS tp_char_result_table))
;
/

/*
4.10 Написать функцию, которой передается sys_refcursor и которая по данному курсору формирует HTML-таблицу,
содержащую информацию из курсора. Тип возвращаемого значения – clob.
*/

DECLARE
  var_cur sys_refcursor;
  var_result CLOB;
 FUNCTION get_html_table(par_cur IN OUT sys_refcursor)
    RETURN CLOB
  IS
    var_cur sys_refcursor := par_cur;
    var_cn INTEGER;
    var_cols_desc dbms_sql.desc_tab2;
    var_cols_count INTEGER;
    var_temp INTEGER;
    var_result CLOB;
    var_str VARCHAR2(32767);
  BEGIN
    dbms_lob.createtemporary(var_result, true);
    var_cn := dbms_sql.to_cursor_number(var_cur);
    dbms_sql.describe_columns2(var_cn, var_cols_count, var_cols_desc);
    FOR i_index IN 1 .. var_cols_count LOOP
      dbms_sql.define_column(var_cn, i_index, var_str, 1000);
    END LOOP;
    dbms_lob.append(var_result, '<table><tr>');
    FOR i_index IN 1..var_cols_count LOOP
      dbms_lob.append(var_result, '<th>' || var_cols_desc(i_index).col_name || '</th>');
    END LOOP;
    dbms_lob.append(var_result, '</tr>');
    LOOP
      var_temp:=dbms_sql.fetch_rows(var_cn);
      EXIT WHEN var_temp = 0;
      dbms_lob.append(var_result, '<tr>');
      FOR i_index IN 1 .. var_cols_count
        LOOP
          dbms_sql.column_value(var_cn, i_index, var_str);
          dbms_lob.append(var_result, '<td>' || var_str || '</td>');
        END LOOP;
      dbms_lob.append(var_result, '</tr>');
    END LOOP;
    dbms_lob.append(var_result, '</table>');
    RETURN var_result;
  END;
BEGIN
  OPEN var_cur FOR
    SELECT j.* 
      FROM jobs j;
  var_result := get_html_table(var_cur);
  dbms_output.put_line(var_result);
END;
/
  
  
  
  
  
  


