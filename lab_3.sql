--Ћ– є3
/*
3.1 ¬ыбрать с помощью иерархического запроса сотрудников 3-его уровн€ иерархии (т.е.
таких, у которых непосредственный начальник напр€мую подчин€етс€ руководителю
организации). ”пор€дочить по коду сотрудника
*/
SELECT  e.*       
  FROM employees e
  WHERE  LEVEL = 3
  START WITH e.manager_id IS NULL
  CONNECT BY e.employee_id = PRIOR e.manager_id
  ORDER BY  e.employee_id
;

/* 
3.2 ƒл€ каждого сотрудника выбрать всех его начальников по иерархии. ¬ывести пол€: код
сотрудника, им€ сотрудника (фамили€ + им€ через пробел), код начальника, им€
начальника (фамили€ + им€ через пробел), кол-во промежуточных начальников между
сотрудником и начальником из данной строки выборки. ≈сли у какого-то сотрудника
есть несколько начальников, то дл€ данного сотрудника в выборке должно быть
несколько строк с разными начальниками. ”пор€дочить по коду сотрудника, затем по
уровню начальника (первый Ц непосредственный начальник, последний Ц руководитель
организации).
*/
SELECT  e.employee_id,
        e.last_name || ' ' || e.first_name AS employee_name,
        CONNECT_BY_ROOT e.employee_id AS manager_id,
        CONNECT_BY_ROOT (e.last_name || ' ' || e.first_name) AS manager_name,
        LEVEL-2 AS manager_count
  FROM  employees e
  WHERE LEVEL > 1
  CONNECT BY  e.manager_id = PRIOR e.employee_id
  ORDER BY  e.employee_id,
            LEVEL
;

/*
3.3 ƒл€ каждого сотрудника посчитать количество его подчиненных, как непосредственных,
так и по иерархии. ¬ывести пол€: код сотрудника, им€ сотрудника (фамили€ + им€ через
пробел), общее кол-во подчиненных.
*/
SELECT  e.employee_id,     
        e.last_name || ' ' || e.first_name AS employee_name,
        COUNT (e.employee_id) AS employee_count
  FROM employees e
  WHERE LEVEL>1
  CONNECT BY e.manager_id = PRIOR e.employee_id
  GROUP BY  e.employee_id,
            e.first_name,
            e.last_name
  ORDER BY employee_count
;  

/* 
3.4 ƒл€ каждого заказчика выбрать в виде строки через зап€тую даты его заказов. ƒл€
конкатенации дат заказов использовать sys_connect_by_path (иерархический запрос). ƒл€
отбора Ђпоследнихї строк использовать connect_by_isleaf
*/
WITH rec_orders AS(
  SELECT  o.customer_id,
          o.order_date,
          row_number() OVER(PARTITION BY customer_id ORDER BY order_date) num
    FROM orders o
  )
SELECT  rs.customer_id,
        LTRIM(sys_connect_by_path(order_date,', '),', ') AS order_dates
  FROM rec_orders rs
  WHERE CONNECT_BY_ISLEAF = 1
  START WITH NUM = 1
  CONNECT BY PRIOR rs.customer_id = rs.customer_id
                  AND NUM = PRIOR NUM + 1
;

/*
3.5 ¬ыполнить задание є 4 c помощью обычного запроса с группировкой и функцией
listagg.
*/
SELECT  o.customer_id, 
        LISTAGG (o.order_date,', ') WITHIN GROUP (ORDER BY o.order_date) AS order_dates
  FROM orders o
  GROUP BY  o.customer_id
;
 
/*
3.6 ¬ыполнить задание є 2 с помощью рекурсивного запроса.
2. ƒл€ каждого сотрудника выбрать всех его начальников по иерархии. ¬ывести пол€: код
сотрудника, им€ сотрудника (фамили€ + им€ через пробел), код начальника, им€
начальника (фамили€ + им€ через пробел), кол-во промежуточных начальников между
сотрудником и начальником из данной строки выборки. ≈сли у какого-то сотрудника
есть несколько начальников, то дл€ данного сотрудника в выборке должно быть
несколько строк с разными начальниками. ”пор€дочить по коду сотрудника, затем по
уровню начальника (первый Ц непосредственный начальник, последний Ц руководитель
организации).
*/
WITH t_req(employee_id, emp_name, manager_id, manager_name, prev_manager_id, manager_level) AS (
  SELECT  e.employee_id,
          e.first_name || ' ' || e.last_name,
          e.employee_id,
          e.first_name || ' ' || e.last_name,
          e.manager_id,
          0
    FROM  employees e
  UNION ALL
  SELECT  prev.employee_id,
          prev.emp_name,
          curr.employee_id,
          curr.first_name || ' ' || curr.last_name,
          curr.manager_id,
          manager_level + 1
    FROM  t_req prev
          JOIN employees curr ON
            curr.employee_id = prev.prev_manager_id
)
SELECT  r.employee_id,
        r.emp_name, 
        r.manager_id, 
        r.manager_name, 
        r.manager_level - 1 AS manager_level
  FROM  t_req r
  WHERE manager_level > 0
  ORDER BY  r.employee_id,
            r.manager_level
;

/*
3.7 ¬ыполнить задание є 3 с помощью рекурсивного запроса.
3. ƒл€ каждого сотрудника посчитать количество его подчиненных, как непосредственных,
так и по иерархии. ¬ывести пол€: код сотрудника, им€ сотрудника (фамили€ + им€ через
пробел), общее кол-во подчиненных.
*/
WITH t_req(manager_id, man_name, employee_id) AS (
  SELECT  e.employee_id,
          e.last_name || ' ' || e.first_name,
          e.employee_id
    FROM  employees e
  UNION ALL
  SELECT  prev.manager_id,
          prev.man_name,
          curr.employee_id
    FROM  t_req prev
          JOIN  employees curr
            ON  curr.manager_id=prev.employee_id
)
SELECT  r.manager_id,
        r.man_name,
        COUNT(*)-1 AS emp_count
  FROM  t_req r
  GROUP BY  r.manager_id,
            r.man_name
  ORDER BY  emp_count DESC
;

/*
3.8  аждому менеджеру по продажам сопоставить последний его заказ. ћенеджером по
продажам считаем сотрудников, код должности которых: ЂSA_MANї и ЂSA_REPї. ƒл€
выборки последних заказов по менеджерам использовать подзапрос с применением
аналитических функций (например в подзапросе выбирать дату следующего заказа
менеджера, а во внешнем запросе Ђоставитьї только те строки, у которых следующего
заказа нет). ¬ывести пол€: код менеджера, им€ менеджера (фамили€ + им€ через
пробел), код клиента, им€ клиента (фамили€ + им€ через пробел), дата заказа, сумма
заказа, количество различных позиций в заказе. ”пор€дочить данные по дате заказа в
обратном пор€дке, затем по сумме заказа в обратном пор€дке, затем по коду сотрудника.
“ех менеджеров, у которых нет заказов, вывести в конце.
*/
SELECT  e.employee_id,
        e.first_name || ' ' || e.last_name AS emp_name,
        c.customer_id,
        c.cust_first_name || ' ' || c.cust_last_name AS cust_name,
        o.order_date,
        o.order_total,
        (
          SELECT  COUNT(oi.product_id)
            FROM  order_items oi
            WHERE oi.order_id = o.order_id
        ) AS items_count
  FROM  employees e
        LEFT JOIN (
          SELECT  o.*,
                  LEAD(o.order_date) OVER(
                    PARTITION BY o.sales_rep_id
                    ORDER BY o.order_date
                  ) AS next_order
            FROM  orders o
        ) o ON
          o.sales_rep_id = e.employee_id AND
          o.next_order IS NULL
        LEFT JOIN customers c ON
          c.customer_id = o.customer_id          
  WHERE e.job_id IN ('SA_MAN', 'SA_REP')
  ORDER BY  o.order_date DESC NULLS LAST,
            o.order_total DESC NULLS LAST,
            e.employee_id
;

/*
3.9 ƒл€ каждого мес€ца текущего года найти первые и последние рабочие и выходные дни с
учетом праздников и переносов выходных дней. ƒл€
формировани€ списка всех дней текущего года использовать иерархический запрос,
оформленный в виде подзапроса в секции with. ѕраздничные дни и переносы выходных
также задать в виде подзапроса в секции with (с помощью union all перечислить все
даты, в которых рабочие/выходные дни не совпадают с обычной логикой определени€
выходного дн€ как субботы и воскресени€). «апрос должен корректно работать, если
добавить изменить какие угодно выходные/рабочие дни в данном подзапросе. ¬ывести
пол€: мес€ц в виде первого числа мес€ца, первый выходной день мес€ца, последний
выходной день, первый праздничный день, последний праздничный день.
*/
WITH 
DAYS AS
(
  SELECT  TRUNC(sysdate, 'yyyy') + LEVEL - 1 AS dt
    FROM  dual
    CONNECT BY TRUNC(sysdate, 'yyyy') + LEVEL - 1 <
                  add_months(TRUNC(sysdate, 'yyyy'), 12)
),
holidays AS 
(
  SELECT DATE'2020-01-01' AS dt, 1 AS comments FROM dual UNION ALL
  SELECT DATE'2020-01-02', 1 FROM dual UNION ALL
  SELECT DATE'2020-01-03', 1 FROM dual UNION ALL
  SELECT DATE'2020-01-06', 1 FROM dual UNION ALL
  SELECT DATE'2020-01-07', 1 FROM dual UNION ALL
  SELECT DATE'2020-01-08', 1 FROM dual UNION ALL
  SELECT DATE'2020-02-24', 1 FROM dual UNION ALL
  SELECT DATE'2020-03-08', 1 FROM dual UNION ALL
  SELECT DATE'2020-03-09', 1 FROM dual UNION ALL
  SELECT DATE'2020-03-30', 1 FROM dual UNION ALL
  SELECT DATE'2020-03-31', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-01', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-02', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-03', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-06', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-07', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-08', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-09', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-10', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-13', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-14', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-15', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-16', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-17', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-20', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-21', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-22', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-23', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-24', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-27', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-28', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-29', 1 FROM dual UNION ALL
  SELECT DATE'2020-04-30', 1 FROM dual UNION ALL
  SELECT DATE'2020-05-01', 1 FROM dual UNION ALL
  SELECT DATE'2020-05-04', 1 FROM dual UNION ALL
  SELECT DATE'2020-05-05', 1 FROM dual UNION ALL
  SELECT DATE'2020-05-06', 1 FROM dual UNION ALL
  SELECT DATE'2020-05-07', 1 FROM dual UNION ALL
  SELECT DATE'2020-05-08', 1 FROM dual UNION ALL
  SELECT DATE'2020-05-11', 1 FROM dual UNION ALL
  SELECT DATE'2020-06-11', 0 FROM dual UNION ALL
  SELECT DATE'2020-06-12', 1 FROM dual UNION ALL
  SELECT DATE'2020-06-24', 1 FROM dual UNION ALL
  SELECT DATE'2020-07-01', 1 FROM dual UNION ALL
  SELECT DATE'2020-11-03', 0 FROM dual UNION ALL
  SELECT DATE'2020-11-04', 1 FROM dual UNION ALL
  SELECT DATE'2020-12-31', 1 FROM dual
)
SELECT  TRUNC(d.dt, 'MM') AS dt,
        MIN(
          CASE WHEN d.comments = 1 THEN d.dt
          END
        ) AS first_weekend,
        MAX(
          CASE WHEN d.comments = 1 THEN d.dt
          END
        ) AS last_weekend,
        MIN(
          CASE WHEN d.comments = 0 THEN d.dt
          END
        ) AS first_working,
        MAX(
          CASE WHEN d.comments = 0 THEN d.dt
          END
        ) AS last_working
  FROM  (
          SELECT  d.dt,
                  nvl(
                    h.comments, 
                    CASE 
                      WHEN to_char(d.dt, 'Dy', 'nls_date_language=english') IN ('Sat', 'Sun') THEN 1
                      ELSE 0
                    END
                  ) AS comments
            FROM  DAYS d
                  LEFT JOIN holidays h ON
                    h.dt = d.dt
        ) d
  GROUP BY  TRUNC(d.dt, 'MM')
  ORDER BY  dt
;

/*
3.10 3-м самых эффективным по сумме заказов за 1999 год менеджерам по продажам
увеличить зарплату еще на 20%.*/
UPDATE  employees e
  SET   e.salary = e.salary*1.2
  WHERE e.employee_id in (
          SELECT  emp.employee_id
            FROM  (
                    SELECT  e.employee_id,
                            sum_orders
                      FROM  employees e
                            JOIN (
                              SELECT  o.sales_rep_id,
                                      SUM(o.order_total) AS sum_orders
                                FROM  orders o
                                WHERE DATE'1999-01-01' <= o.order_date AND o.order_date < DATE'2000-01-01'
                                GROUP BY  o.sales_rep_id
                            ) o ON
                              o.sales_rep_id = e.employee_id
                      WHERE e.job_id in('SA_MAN', 'SA_REP')
                      ORDER BY  sum_orders DESC
                  ) emp
            WHERE ROWNUM <= 3
        )
;

SELECT  e.employee_id,
        sum_orders,
        e.salary
  FROM  employees e
        JOIN (
          SELECT  o.sales_rep_id,
                  SUM(o.order_total) AS sum_orders
            FROM  orders o
            WHERE DATE'1999-01-01' <= o.order_date AND o.order_date < DATE'2000-01-01'
            GROUP BY  o.sales_rep_id
        ) o ON
          o.sales_rep_id = e.employee_id
  ORDER BY  sum_orders DESC
;

/*
3.11 «авести нового клиента С—тарый клиентТ с менеджером, который €вл€етс€
руководителем организации. ќстальные пол€ клиента Ц по умолчанию.
*/
INSERT INTO customers (cust_last_name, cust_first_name, account_mgr_id)
SELECT  'Cтарый',
        'клиент',
        e.employee_id
  FROM  employees e
  WHERE e.manager_id IS NULL
;
SELECT  c.*
  FROM  customers c
  WHERE c.cust_last_name = 'Cтарый'
;

/*
3.12 ƒл€ клиента, созданного в предыдущем запросе, (найти можно по максимальному id
клиента), продублировать заказы всех клиентов за 1990 год. («десь будет 2 запроса, дл€
дублировани€ заказов и дл€ дублировани€ позиций заказа).
*/
INSERT INTO orders (order_date, order_mode, customer_id, order_status, order_total, sales_rep_id, promotion_id)
SELECT  o.order_date,
        o.order_mode,
        (
          SELECT  MAX(c.customer_id) AS customer_id
            FROM  customers c
        ) AS customer_id,
        o.order_status,
        o.order_total,
        o.sales_rep_id,
        o.promotion_id
  FROM  orders o
  WHERE DATE'1990-01-01' <= o.order_date AND o.order_date < DATE'1991-01-01'
;

INSERT  INTO order_items (order_id, line_item_id, product_id, unit_price, quantity)
SELECT  new_order.order_id,
        oi.line_item_id,
        oi.product_id,
        oi.unit_price,
        oi.quantity
  FROM  order_items oi
        JOIN orders o ON
          o.order_id = oi.order_id
        JOIN orders new_order ON
          new_order.order_date = o.order_date AND
          new_order.customer_id = (
            SELECT  MAX(c.customer_id) AS customer_id
              FROM  customers c
          )
  WHERE DATE'1990-01-01' <= o.order_date AND o.order_date < DATE'1991-01-01'
;

/*
3.13 ƒл€ каждого клиента удалить самый первый заказ. ƒолжно быть 2 запроса: первый Ц дл€
удалени€ позиций в заказах, второй Ц на удаление собственно заказов).
*/
DELETE  FROM order_items oi
  WHERE oi.order_id IN (
          SELECT  o.order_id
            FROM  orders o
                  JOIN (
                    SELECT  o.customer_id,
                            MIN(o.order_date) AS first_order
                      FROM  orders o
                      GROUP BY  o.customer_id
                  ) f_ord ON
                    f_ord.customer_id = o.customer_id AND
                    f_ord.first_order = o.order_date
        )
;

DELETE FROM orders o
  WHERE o.order_id IN (
                        SELECT  o.order_id
                          FROM  orders o
                                JOIN (
                                  SELECT  o.customer_id,
                                          MIN(o.order_date) AS first_order
                                    FROM  orders o
                                    GROUP BY  o.customer_id
                                ) f_ord ON
                                  f_ord.customer_id = o.customer_id AND
                                  f_ord.first_order = o.order_date
                        )
;

/*
3.14 ƒл€ товаров, по которым не было ни одного заказа, уменьшить цену в 2 раза (округлив
до целых) и изменить название, приписав префикс С—упер ÷ена! Т.
*/
UPDATE  product_information pi
  SET   pi.product_name = '—упер ÷ена! ' || pi.product_name,
        pi.list_price = round(pi.list_price / 2),
        pi.min_price = round(pi.min_price/2)
  WHERE NOT EXISTS (
          SELECT  *
            FROM  order_items oi
            WHERE oi.product_id = pi.product_id
        )
;

/*
3.15 »мпортировать в базу данных из прайс-листа фирмы Ђ–етї (http://www.voronezh.ret.ru/?
&pn=down) информацию о всех реализуемых планшетах. ѕодсказка: воспользоватьс€
excel дл€ конструировани€ insert-запросов (или select-запросов, что даже удобнее).
*/
INSERT  INTO product_information (product_description, list_price, min_price, warranty_period)
SELECT  TRIM(product_description) AS product_description,
        list_price,
        min_price, 
        warranty_period
  FROM  (
           SELECT 'ѕланшет  7" Archos 70c Xenon, 1024*600, ARM 1.3√√ц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 2/0.3ћпикс,  Android 5.1, 190*110*10мм 242г, серебристый' AS product_description,  3665 AS list_price,  3665 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Galapad 7, 1024*600, NVIDIA 1.3√√ц, 8GB, GPS, BT, WiFi, SD-micro, microHDMI, камера 2ћпикс, Android 4.1, 122*196*10мм 320г, черный' AS product_description,  2490 AS list_price,  2490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Huawei MediaPad T3 7.0 53010adp, 1024*600, Spreadtrum 1.3√√ц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/2ћпикс, Android 7, 187.6*103.7*8.6мм 275г, серый' AS product_description,  6990 AS list_price,  6990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Iconbit NetTAB Sky 3G Duo, 1024*600, ARM 1.2√√ц, 4GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, MiniHDMI, 2 камеры 5/0.3ћпикс, Android 4.0, 195*124*11мм 315г, черный' AS product_description,  2700 AS list_price,  2700 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Iconbit NetTAB Sky II mk2, 800*480, ARM 1.2√√ц, 4GB, WiFi, SD-micro, камера 0.3ћпикс, Android 4.1, 191*114*11мм 310г, белый' AS product_description,  2100 AS list_price,  2100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Irbis TZ71, 1024*600, ARM 1√√ц, 8GB, 4G/3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 0.3/2ћпикс, Android 5.1, 119.2*191.8*10.7мм 280г, черный' AS product_description,  3500 AS list_price,  3500 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Lenovo Tab 3 TB3-710I Essential ZA0S0023RU, 1024*600, MTK 1.3√√ц, 8GB, BT, WiFi, 3G, GPS, SD-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 113*190*10мм 300г, черный' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Lenovo Tab 3 TB3-730X ZA130004RU, 1024*600,  MTK 1√√ц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2ћпикс, Android 6, 101*191*98мм 260г, белый' AS product_description,  7690 AS list_price,  7690 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Lenovo Tab 4 TB-7304i Essential ZA310031RU, 1024*600, MTK 1.3√√ц, 16GB, BT, WiFi, 3G, GPS, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 102*194.8*8.8мм 254г, черный' AS product_description,  6990 AS list_price,  6990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad  Wize 3787, 1280*800, intel 1.1√√ц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 190*115*9.5мм 270г, серый' AS product_description,  4300 AS list_price,  4300 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad  Wize 3787, 1280*800, intel 1.1√√ц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 190*115*9.5мм 270г, черный' AS product_description,  4300 AS list_price,  4300 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad Color Wize 3797, 1280*800, intel 1.2√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 190*115*9.5мм 270г, серый' AS product_description,  4290 AS list_price,  4290 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad Grace PMT3157, 1280*720, MTK 1.3√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 186*115*9.5мм 280г черный' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad Grace PMT3157, 1280*720, MTK 1.3√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 186*115*9.5мм 280г черный' AS product_description,  3990 AS list_price,  3990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad PMT3677, 800*480, ARM 1√√ц, 4GB, WiFi, SD-micro, камера 0.3ћпикс, Android 4.2, 192*116*11мм 300г, черный' AS product_description,  2100 AS list_price,  2100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad WIZE 3757, 1280*800, intel 1.2√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 186*115*9.5мм 280г черный' AS product_description,  5250 AS list_price,  5250 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad Wize 3407, 1024*600, intel 1.3√√ц, 8GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 188*108*10.5мм 310г, черный' AS product_description,  5390 AS list_price,  5390 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Prestigio MultiPad Wize PMT3427, 1024*600, MTK 1.3√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 186*115*9.5мм 280г серый' AS product_description,  4190 AS list_price,  4190 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Samsung Galaxy Tab 4 SM-T231NYKASER, 1280*800, Samsung 1.2√√ц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 3/1.3ћпикс, Android 4.2, 107*186*9мм 281г, 10ч, черный' AS product_description,  8800 AS list_price,  8800 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Samsung Galaxy Tab 4 SM-T231NZWASER, 1280*800, Samsung 1.2√√ц, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 3/1.3ћпикс, Android 4.2, 107*186*9мм 281г, 10ч, белый' AS product_description,  8800 AS list_price,  8800 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Samsung Galaxy Tab A SM-T285NZKASER, 1280*800, Samsung 1.3√√ц, 8GB, 4G/3G, GPS, BT, WiFi, SD-micro, 2 камеры 5/2ћпикс, Android 5.1, 109*187*8.7мм 285г, 10ч, черный' AS product_description,  9990 AS list_price,  9990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Tesla Element 7.0, 1024*600, ARM 1.3√√ц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, камера 0.3ћпикс, Android 4.4, 188*108*10.5мм 311г, черный' AS product_description,  3190 AS list_price,  3190 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7" Topstar TS-AD75 TE, 1024*600, ARM 1√√ц, 8GB, 3G, GSM, BT, WiFi, SD-micro, SDHC-micro, miniHDMI, камера 0.3 ћпикс, Android 4.0, 193*123*10мм 350г, черный' AS product_description,  2700 AS list_price,  2700 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7.9" Apple iPad mini 3 Demo 3A136RU, 2048*1536, A7 1.3√√ц, 16GB, BT, WiFi, 2 камеры 5/1.2ћпикс, 134.7*200*7.5мм 331г, 10ч, золотистый' AS product_description,  17990 AS list_price,  17990 AS min_price,  INTERVAL '1' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7.9" Apple iPad mini 3 MGGQ2RU/A, 2048*1536, A7 1.3√√ц, 64GB, BT, WiFi, 2 камеры 5/1.2ћпикс, 135*200*8мм 331г, 10ч, серый' AS product_description,  25990 AS list_price,  25990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7.9" Apple iPad mini 3 MGGT2RU/A, 2048*1536, A7 1.3√√ц, 64GB, BT, WiFi, 2 камеры 5/1.2ћпикс, 135*200*8мм 331г, 10ч, серебристый' AS product_description,  25990 AS list_price,  25990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7.9" Apple iPad mini 3 MGJ32RU/A, 2048*1536, A7 1.3√√ц, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2ћпикс, 134.7*200*7.5мм 341г, 10ч, серебристый' AS product_description,  32469 AS list_price,  32469 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7.9" Apple iPad mini 3 MGP32RU/A, 2048*1536, A7 1.3√√ц, 128GB, BT, WiFi, 2 камеры 5/1.2ћпикс, 134.7*200*7.5мм 331г, 10ч, серый' AS product_description,  28990 AS list_price,  28990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  7.9" Apple iPad mini 3 MGYU2RU/A, 2048*1536, A7 1.3√√ц, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2ћпикс, 134.7*200*7.5мм 341г, 10ч, золотистый' AS product_description,  29990 AS list_price,  29990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" ASUS VivoTab Note 8 M80TA, 1280*800, Intel 1.86√√ц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/1.26ћпикс, W8.1, 134*221*11мм 380г, черный' AS product_description,  9490 AS list_price,  9490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Acer Iconia Tab 8 A1-840FHD-17RT, 1920*1080, Intel 1.8√√ц, 16GB, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2ћпикс, Android 4.4, серебристый' AS product_description,  10200 AS list_price,  10200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Archos 80 G9, 1024*768, ARM 1√√ц, 8GB, GPS, BT, WiFi, SD-micro, miniHDMI, камера, Android 3.2, 226*155*12мм 465г, 10ч, темно-серый' AS product_description,  2290 AS list_price,  2290 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Huawei MediaPad T3 8.0 53018493, 1280*800, Qualcomm 1.4√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 7, 211*124.65*7.95мм, 350гр, серый' AS product_description,  10990 AS list_price,  10990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Lenovo Tab 4 TB-8504X ZA2D0036RU, 1280*800, Qualcomm 1.4√√ц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2ћпикс, Android 7, 211*124.2мм 310г, черный' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Lenovo Tab 4 TB-8504X ZA2D0059RU, 1280*800, Qualcomm 1.4√√ц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2ћпикс, Android 7, 211*124.2мм 310г, белый' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Grace PMT3118, 1280*800, MTK 1.1√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 6, 206*123*10мм, 343гр, черный' AS product_description,  4590 AS list_price,  4590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Grace PMT5588, 1920*1200, MTK 1√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 8.1, 213*125*8мм, 357гр, черный' AS product_description,  9990 AS list_price,  9990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Muze PMT3708, 1280*800, MTK 1.3√√ц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 206*122.8*10мм, 360гр, черный' AS product_description,  5990 AS list_price,  5990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Muze PMT3708, 1280*800, MTK 1.3√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 206*122.8*10мм, 360гр, черный' AS product_description,  5490 AS list_price,  5490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Muze PMT3718, 1280*800, MTK 1.3√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 206*122.8*10мм, 360гр, черный' AS product_description,  5490 AS list_price,  5490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Wize PMT3108 + CNE-CSPB26W, 1280*800, intel 1.2√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 207*123*8.8мм, 356гр, черный' AS product_description,  5890 AS list_price,  5890 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Wize PMT3208, 1280*800, intel 1.1√√ц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 5.1, 208.2*126.2*10мм, 613гр, черный' AS product_description,  5390 AS list_price,  5390 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Wize PMT3418, 1280*800, MTK 1.1√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 6, 206*122.8*10мм, 360гр, черный' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Wize PMT3508, 1280*800, MTK 1.3√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 5.1, 206*122.8*10мм, 360гр, серый' AS product_description,  6200 AS list_price,  6200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Wize PMT3508, 1280*800, MTK 1.3√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 5.1, 206*122.8*10мм, 360гр, черный' AS product_description,  6200 AS list_price,  6200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Wize PMT3518, 1280*800, MTK 1.1√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 6, 206*122.8*10мм, 360гр, черный' AS product_description,  6710 AS list_price,  6710 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Prestigio MultiPad Wize PMT3618, 1280*800, MTK 1.1√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 8.1, 206*122.8*9.9мм, 363гр, черный' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" RoverPad Magic HD8G, 1280*800, ARM 1.3√√ц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3ћпикс, Android 6, 208*123.5*11мм 420г, черный' AS product_description,  4990 AS list_price,  4990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Tesla Element 8.0 3G, 1280*800, ARM 1.3√√ц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3ћпикс, Android 4.4, 207*123.5*9.8мм 420г, черный' AS product_description,  3490 AS list_price,  3490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  8" Tesla Impulse 8.0 3G, 1280*800, ARM 1.3√√ц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3ћпикс, Android 4.4, 208*123.5*11мм 420г, черный' AS product_description,  3700 AS list_price,  3700 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.6" Huawei MediaPad T3 10 53018522, 1280*800, Qualcomm 1.4√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 7, 229.8*159.8*7.95мм, 460гр, серый' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.6" Huawei MediaPad T3 10 53018545, 1280*800, Qualcomm 1.4√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 7, 229.8*159.8*7.95мм, 460гр, золотистый' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.6" Prestigio MultiPad Wize 3096, 1280*800, MTK 1.3√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 8, 261*155*9.8мм, 554гр, черный' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.6" Samsung Galaxy Tab E SM-T561NZKASER, 1280*800, ARM 1.3√√ц, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2ћпикс, Android 4.4, 242*149.5*8.5мм 495г, черный' AS product_description,  11890 AS list_price,  11890 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.7" Apple iPad Air 2 Demo 3A141RU, 2048*1536, A8X 1.5√√ц, 16GB, BT, WiFi, 2 камеры 8/1.2ћпикс, золотистый' AS product_description,  22500 AS list_price,  22500 AS min_price,  INTERVAL '1' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.7" Apple iPad Air MD791, 2048*1536, A7 1.4√√ц, 16GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2ћпикс, 170*240*8мм 480г, 10ч, серый' AS product_description,  33990 AS list_price,  33990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.7" Apple iPad Air ME898, 2048*1536, A7 1.4√√ц, 128GB, BT, WiFi, 2 камеры 5/1.2ћпикс, 170*240*8мм 469г, 10ч, серый' AS product_description,  32000 AS list_price,  32000 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.7" Apple iPad Air ME906, 2048*1536, A7 1.4√√ц, 128GB, BT, WiFi, 2 камеры 5/1.2ћпикс, 170*240*8мм 469г, 10ч, серебристый' AS product_description,  32000 AS list_price,  32000 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.7" Apple iPad Air ME987, 2048*1536, A7 1.4√√ц, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2ћпикс, 170*240*8мм 478г, 10ч, серый' AS product_description,  34990 AS list_price,  34990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.7" Apple iPad Air ME988, 2048*1536, A7 1.4√√ц, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 камеры 5/1.2ћпикс, 170*240*8мм 480г, 10ч, серебристый' AS product_description,  34990 AS list_price,  34990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет  9.7" Apple iPad Pro MM172RU/A, 2048*1536, A9X 2.26√√ц, 32GB, BT, WiFi, 2 камеры 12/5ћпикс, 169.5*240*6.1мм437г, 10ч, розовое золото' AS product_description,  43490 AS list_price,  43490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" ASUS Eee Pad Transformer Prime TF201, 1280*800, ARM 1.4√√ц, 32GB, GPS, BT, WiFi, Android 4.0, док-станци€, клавиатура, 263*181*8мм 586г, 12ч, золотистый' AS product_description,  7990 AS list_price,  7990 AS min_price,  INTERVAL '1' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" ASUS Transformer Book T100HA-FU002T, 1280*800, Intel 1.44√√ц, 32GB,  BT, WiFi, SDHC-micro, microHDMI, 2 камеры 5/2ћпикс, W10, док-станци€, клавиатура, 263*171*11мм 550гр, серый' AS product_description,  17500 AS list_price,  17500 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" ASUS Transformer Pad TF103CG-1A056A, 1280*800, intel 1.6√√ц, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3ћпикс, Android 4.4, 257.3*178.4*9.9мм 550г черный' AS product_description,  7400 AS list_price,  7400 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" ASUS Transformer Pad TF103CG-1A059A, 1280*800, intel 1.33√√ц, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3ћпикс, клавиатура, Android 4.4, 257.3*178.4*9.9мм 550г черный' AS product_description,  13590 AS list_price,  13590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" ASUS ZenPad 10 Z300M-6A056A, 1280*800, MTK 1.3√√ц, 8GB, BT,  WiFi, SD/SD-micro, 2/5ћпикс, Android 6, 251.6*172*7.9мм 490г, черный' AS product_description,  9990 AS list_price,  9990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Acer Iconia Tab A200, 1280*800, ARM 1√√ц, 32GB, GPS, BT, WiFi, SD-micro, камера 2ћпикс, Android 4.0, 260*175*70мм 720г, красный' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Archos 101b Copper, 1024*600, ARM 1.3√√ц, 8GB, 3G, BT, WiFi, SD-micro, 2 камеры 2/0.3ћпикс,  Android 4.4, 262*166*10мм 577г, серый' AS product_description,  6300 AS list_price,  6300 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Archos 101c Copper, 1024*600, ARM 1.3√√ц, 16GB, 3G, GPS, BT, WiFi, SD-micro, 2 камеры 2/0.3ћпикс,  Android 5.1, 259*150*9.8мм 450г, синий' AS product_description,  6250 AS list_price,  6250 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Dell XPS 10 Tablet 6225-8264, 1366*768, Qualcomm 1.5√√ц, 64GB, BT, WiFi, SD-micro, miniHDMI, 2 камеры 5/2 ћпикс, W8RT, док-станци€, клавиатура, 275*177*9мм 635г, 10.5ч, черный' AS product_description,  8200 AS list_price,  8200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Huawei MediaPad T5 10 LTE 53010DLM, 1920*1200, Kirin 2.36√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 8, 243*164*7.8мм, 460гр, черный' AS product_description,  15990 AS list_price,  15990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Irbis TW21, 1280*800, Intel 1.8√√ц, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, microHDMI, 2 камеры 2/2ћпикс, W8.1, клавиатура, черный' AS product_description,  6990 AS list_price,  6990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Irbis TW31, 1280*800, Intel 1.8√√ц, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2ћпикс,  W10, клавиатура, 170*278*10мм 600г, черный' AS product_description,  10400 AS list_price,  10400 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Lenovo Tab 4 TB-X304L ZA2K0056RU, 1280*800, Qualcomm 1.4√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 5/2ћпикс, Android 7, 247*170*8.4мм 505г, черный' AS product_description,  13100 AS list_price,  13100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Lenovo Tab 4 TB-X304L ZA2K0082RU, 1280*800, Qualcomm 1.4√√ц, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 камеры 5/2ћпикс, Android 7, 247*170*8.4мм 505г, белый' AS product_description,  12990 AS list_price,  12990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Pegatron Chagall 90NL-083S100, 1280*800, ARM 1.5√√ц, 16GB, BT, WiFi, SD-micro,  2 камеры 8/2 ћпикс, Android 4.0, 260*7*180мм 540г, 8ч, черный' AS product_description,  4100 AS list_price,  4100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Prestigio MultiPad Grace PMT3101, 1280*800, MTK 1.3√√ц, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 243*171*10мм, 545гр, черный' AS product_description,  7990 AS list_price,  7990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Prestigio MultiPad Wize PMT3131, 1280*800, MTK 1.13√√ц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 6, 261*155*9.8мм, 554гр, черный' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Prestigio MultiPad Wize PMT3131, 1280*800, MTK 1.13√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 6, 261*155*9.8мм, 554гр, черный' AS product_description,  5490 AS list_price,  5490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Prestigio MultiPad Wize PMT3151, 1280*800, MTK 1.13√√ц, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 6, 261*155*9.8мм, 554гр, черный' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Prestigio MultiPad Wize PMT3161, 1280*800, MTK 1.3√√ц, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 камеры 2/0.3ћпикс, Android 7, 243*171*10мм, 545гр, черный' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Prestigio Visconte 4U XIPMP1011TDBK, 1280*800, Intel 1.8√√ц, 16GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2ћпикс, W10, клавиатура, 256*173.6*10.5мм 580г, черный' AS product_description,  7490 AS list_price,  7490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Prestigio Visconte A WCPMP1014TEDG, 1280*800, Intel 1.83√√ц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/2ћпикс, W10, клавиатура, 259.3*173.5*10.1мм 575г, серый' AS product_description,  8490 AS list_price,  8490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" RoverPad Magic HD10G, 1280*800, ARM 1.2√√ц, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3ћпикс, Android 7, 242.3*171.2*9.5мм 560г, черный' AS product_description,  5990 AS list_price,  5990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 10.1" Tesla Impulse 10.1 3G, 1280*800, ARM 1.2√√ц, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 2/0.3ћпикс, Android 5.1, 242.3*171.2*9.5мм 560г, черный' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT 'ѕланшет 11.6" Prestigio Visconte S UEPMP1020CESR, 1920*1080, Intel 1.84√√ц, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 камеры 5/2ћпикс, W10, клавиатура, 260*186*9.75мм 684г, серый' AS product_description,  12490 AS list_price,  12490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual
        )
;

