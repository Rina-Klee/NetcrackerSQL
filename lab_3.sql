--�� �3
/*
3.1 ������� � ������� �������������� ������� ����������� 3-��� ������ �������� (�.�.
�����, � ������� ���������������� ��������� �������� ����������� ������������
�����������). ����������� �� ���� ����������
*/
SELECT  e.*       
  FROM employees e
  WHERE  LEVEL = 3
  START WITH e.manager_id IS NULL
  CONNECT BY e.employee_id = PRIOR e.manager_id
  ORDER BY  e.employee_id
;

/* 
3.2 ��� ������� ���������� ������� ���� ��� ����������� �� ��������. ������� ����: ���
����������, ��� ���������� (������� + ��� ����� ������), ��� ����������, ���
���������� (������� + ��� ����� ������), ���-�� ������������� ����������� �����
����������� � ����������� �� ������ ������ �������. ���� � ������-�� ����������
���� ��������� �����������, �� ��� ������� ���������� � ������� ������ ����
��������� ����� � ������� ������������. ����������� �� ���� ����������, ����� ��
������ ���������� (������ � ���������������� ���������, ��������� � ������������
�����������).
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
3.3 ��� ������� ���������� ��������� ���������� ��� �����������, ��� ����������������,
��� � �� ��������. ������� ����: ��� ����������, ��� ���������� (������� + ��� �����
������), ����� ���-�� �����������.
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
3.4 ��� ������� ��������� ������� � ���� ������ ����� ������� ���� ��� �������. ���
������������ ��� ������� ������������ sys_connect_by_path (������������� ������). ���
������ ����������� ����� ������������ connect_by_isleaf
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
3.5 ��������� ������� � 4 c ������� �������� ������� � ������������ � ��������
listagg.
*/
SELECT  o.customer_id, 
        LISTAGG (o.order_date,', ') WITHIN GROUP (ORDER BY o.order_date) AS order_dates
  FROM orders o
  GROUP BY  o.customer_id
;
 
/*
3.6 ��������� ������� � 2 � ������� ������������ �������.
2. ��� ������� ���������� ������� ���� ��� ����������� �� ��������. ������� ����: ���
����������, ��� ���������� (������� + ��� ����� ������), ��� ����������, ���
���������� (������� + ��� ����� ������), ���-�� ������������� ����������� �����
����������� � ����������� �� ������ ������ �������. ���� � ������-�� ����������
���� ��������� �����������, �� ��� ������� ���������� � ������� ������ ����
��������� ����� � ������� ������������. ����������� �� ���� ����������, ����� ��
������ ���������� (������ � ���������������� ���������, ��������� � ������������
�����������).
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
3.7 ��������� ������� � 3 � ������� ������������ �������.
3. ��� ������� ���������� ��������� ���������� ��� �����������, ��� ����������������,
��� � �� ��������. ������� ����: ��� ����������, ��� ���������� (������� + ��� �����
������), ����� ���-�� �����������.
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
3.8 ������� ��������� �� �������� ����������� ��������� ��� �����. ���������� ��
�������� ������� �����������, ��� ��������� �������: �SA_MAN� � �SA_REP�. ���
������� ��������� ������� �� ���������� ������������ ��������� � �����������
������������� ������� (�������� � ���������� �������� ���� ���������� ������
���������, � �� ������� ������� ���������� ������ �� ������, � ������� ����������
������ ���). ������� ����: ��� ���������, ��� ��������� (������� + ��� �����
������), ��� �������, ��� ������� (������� + ��� ����� ������), ���� ������, �����
������, ���������� ��������� ������� � ������. ����������� ������ �� ���� ������ �
�������� �������, ����� �� ����� ������ � �������� �������, ����� �� ���� ����������.
��� ����������, � ������� ��� �������, ������� � �����.
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
3.9 ��� ������� ������ �������� ���� ����� ������ � ��������� ������� � �������� ��� �
������ ���������� � ��������� �������� ����. ���
������������ ������ ���� ���� �������� ���� ������������ ������������� ������,
����������� � ���� ���������� � ������ with. ����������� ��� � �������� ��������
����� ������ � ���� ���������� � ������ with (� ������� union all ����������� ���
����, � ������� �������/�������� ��� �� ��������� � ������� ������� �����������
��������� ��� ��� ������� � �����������). ������ ������ ��������� ��������, ����
�������� �������� ����� ������ ��������/������� ��� � ������ ����������. �������
����: ����� � ���� ������� ����� ������, ������ �������� ���� ������, ���������
�������� ����, ������ ����������� ����, ��������� ����������� ����.
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
3.10 3-� ����� ����������� �� ����� ������� �� 1999 ��� ���������� �� ��������
��������� �������� ��� �� 20%.*/
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
3.11 ������� ������ ������� ������� ������ � ����������, ������� ��������
������������� �����������. ��������� ���� ������� � �� ���������.
*/
INSERT INTO customers (cust_last_name, cust_first_name, account_mgr_id)
SELECT  'C�����',
        '������',
        e.employee_id
  FROM  employees e
  WHERE e.manager_id IS NULL
;
SELECT  c.*
  FROM  customers c
  WHERE c.cust_last_name = 'C�����'
;

/*
3.12 ��� �������, ���������� � ���������� �������, (����� ����� �� ������������� id
�������), �������������� ������ ���� �������� �� 1990 ���. (����� ����� 2 �������, ���
������������ ������� � ��� ������������ ������� ������).
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
3.13 ��� ������� ������� ������� ����� ������ �����. ������ ���� 2 �������: ������ � ���
�������� ������� � �������, ������ � �� �������� ���������� �������).
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
3.14 ��� �������, �� ������� �� ���� �� ������ ������, ��������� ���� � 2 ���� (��������
�� �����) � �������� ��������, �������� ������� ������ ����! �.
*/
UPDATE  product_information pi
  SET   pi.product_name = '����� ����! ' || pi.product_name,
        pi.list_price = round(pi.list_price / 2),
        pi.min_price = round(pi.min_price/2)
  WHERE NOT EXISTS (
          SELECT  *
            FROM  order_items oi
            WHERE oi.product_id = pi.product_id
        )
;

/*
3.15 ������������� � ���� ������ �� �����-����� ����� ���� (http://www.voronezh.ret.ru/?
&pn=down) ���������� � ���� ����������� ���������. ���������: ���������������
excel ��� ��������������� insert-�������� (��� select-��������, ��� ���� �������).
*/
INSERT  INTO product_information (product_description, list_price, min_price, warranty_period)
SELECT  TRIM(product_description) AS product_description,
        list_price,
        min_price, 
        warranty_period
  FROM  (
           SELECT '�������  7" Archos 70c Xenon, 1024*600, ARM 1.3���, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 ������ 2/0.3�����,  Android 5.1, 190*110*10�� 242�, �����������' AS product_description,  3665 AS list_price,  3665 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Galapad 7, 1024*600, NVIDIA 1.3���, 8GB, GPS, BT, WiFi, SD-micro, microHDMI, ������ 2�����, Android 4.1, 122*196*10�� 320�, ������' AS product_description,  2490 AS list_price,  2490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Huawei MediaPad T3 7.0 53010adp, 1024*600, Spreadtrum 1.3���, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/2�����, Android 7, 187.6*103.7*8.6�� 275�, �����' AS product_description,  6990 AS list_price,  6990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Iconbit NetTAB Sky 3G Duo, 1024*600, ARM 1.2���, 4GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, MiniHDMI, 2 ������ 5/0.3�����, Android 4.0, 195*124*11�� 315�, ������' AS product_description,  2700 AS list_price,  2700 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Iconbit NetTAB Sky II mk2, 800*480, ARM 1.2���, 4GB, WiFi, SD-micro, ������ 0.3�����, Android 4.1, 191*114*11�� 310�, �����' AS product_description,  2100 AS list_price,  2100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Irbis TZ71, 1024*600, ARM 1���, 8GB, 4G/3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 0.3/2�����, Android 5.1, 119.2*191.8*10.7�� 280�, ������' AS product_description,  3500 AS list_price,  3500 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Lenovo Tab 3 TB3-710I Essential ZA0S0023RU, 1024*600, MTK 1.3���, 8GB, BT, WiFi, 3G, GPS, SD-micro, 2 ������ 2/0.3�����, Android 5.1, 113*190*10�� 300�, ������' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Lenovo Tab 3 TB3-730X ZA130004RU, 1024*600,  MTK 1���, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 ������ 5/2�����, Android 6, 101*191*98�� 260�, �����' AS product_description,  7690 AS list_price,  7690 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Lenovo Tab 4 TB-7304i Essential ZA310031RU, 1024*600, MTK 1.3���, 16GB, BT, WiFi, 3G, GPS, SD-micro, 2 ������ 2/0.3�����, Android 7, 102*194.8*8.8�� 254�, ������' AS product_description,  6990 AS list_price,  6990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad  Wize 3787, 1280*800, intel 1.1���, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 5.1, 190*115*9.5�� 270�, �����' AS product_description,  4300 AS list_price,  4300 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad  Wize 3787, 1280*800, intel 1.1���, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 5.1, 190*115*9.5�� 270�, ������' AS product_description,  4300 AS list_price,  4300 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad Color Wize 3797, 1280*800, intel 1.2���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 5.1, 190*115*9.5�� 270�, �����' AS product_description,  4290 AS list_price,  4290 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad Grace PMT3157, 1280*720, MTK 1.3���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 186*115*9.5�� 280� ������' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad Grace PMT3157, 1280*720, MTK 1.3���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 186*115*9.5�� 280� ������' AS product_description,  3990 AS list_price,  3990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad PMT3677, 800*480, ARM 1���, 4GB, WiFi, SD-micro, ������ 0.3�����, Android 4.2, 192*116*11�� 300�, ������' AS product_description,  2100 AS list_price,  2100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad WIZE 3757, 1280*800, intel 1.2���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 5.1, 186*115*9.5�� 280� ������' AS product_description,  5250 AS list_price,  5250 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad Wize 3407, 1024*600, intel 1.3���, 8GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 5.1, 188*108*10.5�� 310�, ������' AS product_description,  5390 AS list_price,  5390 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Prestigio MultiPad Wize PMT3427, 1024*600, MTK 1.3���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 186*115*9.5�� 280� �����' AS product_description,  4190 AS list_price,  4190 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Samsung Galaxy Tab 4 SM-T231NYKASER, 1280*800, Samsung 1.2���, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 ������ 3/1.3�����, Android 4.2, 107*186*9�� 281�, 10�, ������' AS product_description,  8800 AS list_price,  8800 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Samsung Galaxy Tab 4 SM-T231NZWASER, 1280*800, Samsung 1.2���, 8GB, 3G, GPS, BT, WiFi, SD-micro, 2 ������ 3/1.3�����, Android 4.2, 107*186*9�� 281�, 10�, �����' AS product_description,  8800 AS list_price,  8800 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Samsung Galaxy Tab A SM-T285NZKASER, 1280*800, Samsung 1.3���, 8GB, 4G/3G, GPS, BT, WiFi, SD-micro, 2 ������ 5/2�����, Android 5.1, 109*187*8.7�� 285�, 10�, ������' AS product_description,  9990 AS list_price,  9990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Tesla Element 7.0, 1024*600, ARM 1.3���, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, ������ 0.3�����, Android 4.4, 188*108*10.5�� 311�, ������' AS product_description,  3190 AS list_price,  3190 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7" Topstar TS-AD75 TE, 1024*600, ARM 1���, 8GB, 3G, GSM, BT, WiFi, SD-micro, SDHC-micro, miniHDMI, ������ 0.3 �����, Android 4.0, 193*123*10�� 350�, ������' AS product_description,  2700 AS list_price,  2700 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7.9" Apple iPad mini 3 Demo 3A136RU, 2048*1536, A7 1.3���, 16GB, BT, WiFi, 2 ������ 5/1.2�����, 134.7*200*7.5�� 331�, 10�, ����������' AS product_description,  17990 AS list_price,  17990 AS min_price,  INTERVAL '1' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7.9" Apple iPad mini 3 MGGQ2RU/A, 2048*1536, A7 1.3���, 64GB, BT, WiFi, 2 ������ 5/1.2�����, 135*200*8�� 331�, 10�, �����' AS product_description,  25990 AS list_price,  25990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7.9" Apple iPad mini 3 MGGT2RU/A, 2048*1536, A7 1.3���, 64GB, BT, WiFi, 2 ������ 5/1.2�����, 135*200*8�� 331�, 10�, �����������' AS product_description,  25990 AS list_price,  25990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7.9" Apple iPad mini 3 MGJ32RU/A, 2048*1536, A7 1.3���, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 ������ 5/1.2�����, 134.7*200*7.5�� 341�, 10�, �����������' AS product_description,  32469 AS list_price,  32469 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7.9" Apple iPad mini 3 MGP32RU/A, 2048*1536, A7 1.3���, 128GB, BT, WiFi, 2 ������ 5/1.2�����, 134.7*200*7.5�� 331�, 10�, �����' AS product_description,  28990 AS list_price,  28990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  7.9" Apple iPad mini 3 MGYU2RU/A, 2048*1536, A7 1.3���, 128GB, 4G/3G, GSM, GPS, BT, WiFi, 2 ������ 5/1.2�����, 134.7*200*7.5�� 341�, 10�, ����������' AS product_description,  29990 AS list_price,  29990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" ASUS VivoTab Note 8 M80TA, 1280*800, Intel 1.86���, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 5/1.26�����, W8.1, 134*221*11�� 380�, ������' AS product_description,  9490 AS list_price,  9490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Acer Iconia Tab 8 A1-840FHD-17RT, 1920*1080, Intel 1.8���, 16GB, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 5/2�����, Android 4.4, �����������' AS product_description,  10200 AS list_price,  10200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Archos 80 G9, 1024*768, ARM 1���, 8GB, GPS, BT, WiFi, SD-micro, miniHDMI, ������, Android 3.2, 226*155*12�� 465�, 10�, �����-�����' AS product_description,  2290 AS list_price,  2290 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Huawei MediaPad T3 8.0 53018493, 1280*800, Qualcomm 1.4���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 7, 211*124.65*7.95��, 350��, �����' AS product_description,  10990 AS list_price,  10990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Lenovo Tab 4 TB-8504X ZA2D0036RU, 1280*800, Qualcomm 1.4���, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 ������ 5/2�����, Android 7, 211*124.2�� 310�, ������' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Lenovo Tab 4 TB-8504X ZA2D0059RU, 1280*800, Qualcomm 1.4���, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 ������ 5/2�����, Android 7, 211*124.2�� 310�, �����' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Grace PMT3118, 1280*800, MTK 1.1���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 6, 206*123*10��, 343��, ������' AS product_description,  4590 AS list_price,  4590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Grace PMT5588, 1920*1200, MTK 1���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 8.1, 213*125*8��, 357��, ������' AS product_description,  9990 AS list_price,  9990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Muze PMT3708, 1280*800, MTK 1.3���, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 206*122.8*10��, 360��, ������' AS product_description,  5990 AS list_price,  5990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Muze PMT3708, 1280*800, MTK 1.3���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 206*122.8*10��, 360��, ������' AS product_description,  5490 AS list_price,  5490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Muze PMT3718, 1280*800, MTK 1.3���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 206*122.8*10��, 360��, ������' AS product_description,  5490 AS list_price,  5490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Wize PMT3108 + CNE-CSPB26W, 1280*800, intel 1.2���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 5.1, 207*123*8.8��, 356��, ������' AS product_description,  5890 AS list_price,  5890 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Wize PMT3208, 1280*800, intel 1.1���, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 5.1, 208.2*126.2*10��, 613��, ������' AS product_description,  5390 AS list_price,  5390 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Wize PMT3418, 1280*800, MTK 1.1���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 6, 206*122.8*10��, 360��, ������' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Wize PMT3508, 1280*800, MTK 1.3���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 5.1, 206*122.8*10��, 360��, �����' AS product_description,  6200 AS list_price,  6200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Wize PMT3508, 1280*800, MTK 1.3���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 5.1, 206*122.8*10��, 360��, ������' AS product_description,  6200 AS list_price,  6200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Wize PMT3518, 1280*800, MTK 1.1���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 6, 206*122.8*10��, 360��, ������' AS product_description,  6710 AS list_price,  6710 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Prestigio MultiPad Wize PMT3618, 1280*800, MTK 1.1���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 8.1, 206*122.8*9.9��, 363��, ������' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" RoverPad Magic HD8G, 1280*800, ARM 1.3���, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/0.3�����, Android 6, 208*123.5*11�� 420�, ������' AS product_description,  4990 AS list_price,  4990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Tesla Element 8.0 3G, 1280*800, ARM 1.3���, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/0.3�����, Android 4.4, 207*123.5*9.8�� 420�, ������' AS product_description,  3490 AS list_price,  3490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  8" Tesla Impulse 8.0 3G, 1280*800, ARM 1.3���, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/0.3�����, Android 4.4, 208*123.5*11�� 420�, ������' AS product_description,  3700 AS list_price,  3700 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.6" Huawei MediaPad T3 10 53018522, 1280*800, Qualcomm 1.4���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 7, 229.8*159.8*7.95��, 460��, �����' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.6" Huawei MediaPad T3 10 53018545, 1280*800, Qualcomm 1.4���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 7, 229.8*159.8*7.95��, 460��, ����������' AS product_description,  11990 AS list_price,  11990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.6" Prestigio MultiPad Wize 3096, 1280*800, MTK 1.3���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 8, 261*155*9.8��, 554��, ������' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.6" Samsung Galaxy Tab E SM-T561NZKASER, 1280*800, ARM 1.3���, 8GB, 3G, GSM, GPS, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 5/2�����, Android 4.4, 242*149.5*8.5�� 495�, ������' AS product_description,  11890 AS list_price,  11890 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.7" Apple iPad Air 2 Demo 3A141RU, 2048*1536, A8X 1.5���, 16GB, BT, WiFi, 2 ������ 8/1.2�����, ����������' AS product_description,  22500 AS list_price,  22500 AS min_price,  INTERVAL '1' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.7" Apple iPad Air MD791, 2048*1536, A7 1.4���, 16GB, 3G/4G, GSM, GPS, BT, WiFi, 2 ������ 5/1.2�����, 170*240*8�� 480�, 10�, �����' AS product_description,  33990 AS list_price,  33990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.7" Apple iPad Air ME898, 2048*1536, A7 1.4���, 128GB, BT, WiFi, 2 ������ 5/1.2�����, 170*240*8�� 469�, 10�, �����' AS product_description,  32000 AS list_price,  32000 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.7" Apple iPad Air ME906, 2048*1536, A7 1.4���, 128GB, BT, WiFi, 2 ������ 5/1.2�����, 170*240*8�� 469�, 10�, �����������' AS product_description,  32000 AS list_price,  32000 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.7" Apple iPad Air ME987, 2048*1536, A7 1.4���, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 ������ 5/1.2�����, 170*240*8�� 478�, 10�, �����' AS product_description,  34990 AS list_price,  34990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.7" Apple iPad Air ME988, 2048*1536, A7 1.4���, 128GB, 3G/4G, GSM, GPS, BT, WiFi, 2 ������ 5/1.2�����, 170*240*8�� 480�, 10�, �����������' AS product_description,  34990 AS list_price,  34990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '�������  9.7" Apple iPad Pro MM172RU/A, 2048*1536, A9X 2.26���, 32GB, BT, WiFi, 2 ������ 12/5�����, 169.5*240*6.1��437�, 10�, ������� ������' AS product_description,  43490 AS list_price,  43490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" ASUS Eee Pad Transformer Prime TF201, 1280*800, ARM 1.4���, 32GB, GPS, BT, WiFi, Android 4.0, ���-�������, ����������, 263*181*8�� 586�, 12�, ����������' AS product_description,  7990 AS list_price,  7990 AS min_price,  INTERVAL '1' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" ASUS Transformer Book T100HA-FU002T, 1280*800, Intel 1.44���, 32GB,  BT, WiFi, SDHC-micro, microHDMI, 2 ������ 5/2�����, W10, ���-�������, ����������, 263*171*11�� 550��, �����' AS product_description,  17500 AS list_price,  17500 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" ASUS Transformer Pad TF103CG-1A056A, 1280*800, intel 1.6���, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3�����, Android 4.4, 257.3*178.4*9.9�� 550� ������' AS product_description,  7400 AS list_price,  7400 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" ASUS Transformer Pad TF103CG-1A059A, 1280*800, intel 1.33���, 8GB, BT, 3G, WiFi, SD/SD-micro, 2/0.3�����, ����������, Android 4.4, 257.3*178.4*9.9�� 550� ������' AS product_description,  13590 AS list_price,  13590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" ASUS ZenPad 10 Z300M-6A056A, 1280*800, MTK 1.3���, 8GB, BT,  WiFi, SD/SD-micro, 2/5�����, Android 6, 251.6*172*7.9�� 490�, ������' AS product_description,  9990 AS list_price,  9990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Acer Iconia Tab A200, 1280*800, ARM 1���, 32GB, GPS, BT, WiFi, SD-micro, ������ 2�����, Android 4.0, 260*175*70�� 720�, �������' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Archos 101b Copper, 1024*600, ARM 1.3���, 8GB, 3G, BT, WiFi, SD-micro, 2 ������ 2/0.3�����,  Android 4.4, 262*166*10�� 577�, �����' AS product_description,  6300 AS list_price,  6300 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Archos 101c Copper, 1024*600, ARM 1.3���, 16GB, 3G, GPS, BT, WiFi, SD-micro, 2 ������ 2/0.3�����,  Android 5.1, 259*150*9.8�� 450�, �����' AS product_description,  6250 AS list_price,  6250 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Dell XPS 10 Tablet 6225-8264, 1366*768, Qualcomm 1.5���, 64GB, BT, WiFi, SD-micro, miniHDMI, 2 ������ 5/2 �����, W8RT, ���-�������, ����������, 275*177*9�� 635�, 10.5�, ������' AS product_description,  8200 AS list_price,  8200 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Huawei MediaPad T5 10 LTE 53010DLM, 1920*1200, Kirin 2.36���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 8, 243*164*7.8��, 460��, ������' AS product_description,  15990 AS list_price,  15990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Irbis TW21, 1280*800, Intel 1.8���, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, microHDMI, 2 ������ 2/2�����, W8.1, ����������, ������' AS product_description,  6990 AS list_price,  6990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Irbis TW31, 1280*800, Intel 1.8���, 32GB, 3G, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/2�����,  W10, ����������, 170*278*10�� 600�, ������' AS product_description,  10400 AS list_price,  10400 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Lenovo Tab 4 TB-X304L ZA2K0056RU, 1280*800, Qualcomm 1.4���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 5/2�����, Android 7, 247*170*8.4�� 505�, ������' AS product_description,  13100 AS list_price,  13100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Lenovo Tab 4 TB-X304L ZA2K0082RU, 1280*800, Qualcomm 1.4���, 16GB, BT, WiFi, 4G/3G, GPS, SD-micro, 2 ������ 5/2�����, Android 7, 247*170*8.4�� 505�, �����' AS product_description,  12990 AS list_price,  12990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Pegatron Chagall 90NL-083S100, 1280*800, ARM 1.5���, 16GB, BT, WiFi, SD-micro,  2 ������ 8/2 �����, Android 4.0, 260*7*180�� 540�, 8�, ������' AS product_description,  4100 AS list_price,  4100 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Prestigio MultiPad Grace PMT3101, 1280*800, MTK 1.3���, 16GB, 4G/3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 243*171*10��, 545��, ������' AS product_description,  7990 AS list_price,  7990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Prestigio MultiPad Wize PMT3131, 1280*800, MTK 1.13���, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 6, 261*155*9.8��, 554��, ������' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Prestigio MultiPad Wize PMT3131, 1280*800, MTK 1.13���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 6, 261*155*9.8��, 554��, ������' AS product_description,  5490 AS list_price,  5490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Prestigio MultiPad Wize PMT3151, 1280*800, MTK 1.13���, 16GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 6, 261*155*9.8��, 554��, ������' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Prestigio MultiPad Wize PMT3161, 1280*800, MTK 1.3���, 8GB, 3G, WiFi, GPS, BT, SD-micro, 2 ������ 2/0.3�����, Android 7, 243*171*10��, 545��, ������' AS product_description,  6490 AS list_price,  6490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Prestigio Visconte 4U XIPMP1011TDBK, 1280*800, Intel 1.8���, 16GB, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/2�����, W10, ����������, 256*173.6*10.5�� 580�, ������' AS product_description,  7490 AS list_price,  7490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Prestigio Visconte A WCPMP1014TEDG, 1280*800, Intel 1.83���, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/2�����, W10, ����������, 259.3*173.5*10.1�� 575�, �����' AS product_description,  8490 AS list_price,  8490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" RoverPad Magic HD10G, 1280*800, ARM 1.2���, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/0.3�����, Android 7, 242.3*171.2*9.5�� 560�, ������' AS product_description,  5990 AS list_price,  5990 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 10.1" Tesla Impulse 10.1 3G, 1280*800, ARM 1.2���, 8GB, 3G, GSM, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 2/0.3�����, Android 5.1, 242.3*171.2*9.5�� 560�, ������' AS product_description,  5590 AS list_price,  5590 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual UNION ALL
          SELECT '������� 11.6" Prestigio Visconte S UEPMP1020CESR, 1920*1080, Intel 1.84���, 32GB, BT, WiFi, SD-micro/SDHC-micro, 2 ������ 5/2�����, W10, ����������, 260*186*9.75�� 684�, �����' AS product_description,  12490 AS list_price,  12490 AS min_price,  INTERVAL '12' MONTH AS warranty_period FROM dual
        )
;

