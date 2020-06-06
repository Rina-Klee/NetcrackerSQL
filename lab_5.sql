/* 
5. Создать схему БД для фиксации успеваемости студентов.

Есть таблицы:
	Специальности (просто справочник);
Учебный план (специальность, семестр, предмет, вид отчетности);
Студенты (фио, специальность, год поступления);
Оценки (студент, дата, оценка – предусмотреть неявку).
(Понятно, что указаны не все необходимые поля, а только список того, что должно быть обязательно).

В таблицах должны быть предусмотрены все ограничения целостности.

Создать триггеры для автоинкрементности первичных ключей.

Заполнить таблицы тестовыми данными.

Написать запрос, выводящий список должников на текущий момент времени (сколько семестров проучился студент вычислять из года поступления и текущей даты – написать для этого функцию). Должны выводиться поля: код студента, ФИО студента, курс, код предмета, название предмета, семестр, оценка (2 – если сдавал экзамен, нулл – если не сдавал).

Сделать из этого запроса представление.

Выбрать из представления студентов с 4-мя и более хвостами (на отчисление).*/

CREATE TABLE specialties(
  spec_id NUMBER(4, 0),
  spec_name VARCHAR2(63) NOT NULL,
  CONSTRAINT spec_pk
    PRIMARY KEY (spec_id),
  CONSTRAINT spec_name_uniq
    UNIQUE (spec_name)
);

CREATE TABLE subjects(
  subj_id NUMBER(4, 0),
  subj_name VARCHAR(63) NOT NULL,
  CONSTRAINT subj_pk
    PRIMARY KEY (subj_id),
  CONSTRAINT subj_name_uniq
    UNIQUE (subj_name)
);

CREATE TABLE curriculums(
  curr_id NUMBER(10, 0),
  spec_id NUMBER(4, 0) NOT NULL,
  semester NUMBER(2, 0) NOT NULL,
  subj_id NUMBER(4, 0) NOT NULL,
  report_TYPE VARCHAR2(15) NOT NULL,
  CONSTRAINT curr_pk 
    PRIMARY KEY (curr_id),
  CONSTRAINT fk_specialties_curriculums
    FOREIGN KEY (spec_id)
    REFERENCES specialties(spec_id),
  CONSTRAINT fk_subjects_curriculums
    FOREIGN KEY (subj_id)
    REFERENCES subjects(subj_id),
  CONSTRAINT CHECK_curriculums_report_type
    CHECK (report_type IN ('Credit', 'Credit_with_mark','Examination'))
);

CREATE TABLE students(
  stud_id NUMBER(12, 0),
  stud_name VARCHAR2(255) NOT NULL,
  spec_id NUMBER(4,0) NOT NULL,
  year_of_entry NUMBER(5,0) NOT NULL,
  CONSTRAINT stud_pk
    PRIMARY KEY (stud_id),
  CONSTRAINT fk_specialties_students
    FOREIGN KEY (spec_id)
    REFERENCES specialties(spec_id)
);

CREATE TABLE marks ( 
  stud_id NUMBER(12, 0),
  curr_id NUMBER(10, 0),
  exam_date date,
  MARK NUMBER(3, 0),
  CONSTRAINT marks_pk 
    PRIMARY KEY (stud_id, curr_id, exam_date),
  CONSTRAINT fk_students_marks
    FOREIGN KEY (stud_id)
    REFERENCES students(stud_id),
  CONSTRAINT fk_subjects_marks
    FOREIGN KEY (curr_id)
    REFERENCES curriculums(curr_id)
);

CREATE SEQUENCE spec_seq
  MINVALUE 1
  MAXVALUE 10000
  INCREMENT BY 1
  NOCACHE NOORDER NOCYCLE
;
/
CREATE TRIGGER spec_tr_set_id
  BEFORE INSERT ON specialties
  FOR EACH ROW
BEGIN
  IF  :new.spec_id IS NULL THEN
    SELECT spec_seq.nextval
      INTO :new.spec_id 
      FROM dual;
  END IF ;
END;
/
ALTER TRIGGER spec_tr_set_id ENABLE;
/
CREATE SEQUENCE curr_seq
  MINVALUE 1
  MAXVALUE 10000
  INCREMENT BY 1
  NOCACHE NOORDER NOCYCLE
;
/
CREATE TRIGGER curr_tr_set_id
  BEFORE INSERT ON curriculums
  FOR EACH ROW
BEGIN
  IF  :new.curr_id IS NULL THEN
    SELECT curr_seq.nextval
      INTO :new.curr_id
      FROM dual;
  END IF ;
END;
/
ALTER TRIGGER curr_tr_set_id ENABLE;
/
CREATE SEQUENCE stud_seq
  MINVALUE 1
  MAXVALUE 10000
  INCREMENT BY 1
  NOCACHE NOORDER NOCYCLE
;
/
CREATE TRIGGER stud_tr_set_id
  BEFORE INSERT ON students
  FOR EACH ROW
BEGIN
  IF  :new.stud_id IS NULL THEN
    SELECT stud_seq.nextval
      INTO :new.stud_id
      FROM dual;
  END IF ;
END;
/
ALTER TRIGGER stud_tr_set_id ENABLE;
/
CREATE SEQUENCE subj_seq
  MINVALUE 1
  MAXVALUE 10000
  INCREMENT BY 1
  NOCACHE NOORDER NOCYCLE
;
/
CREATE TRIGGER subj_tr_set_id
  BEFORE INSERT ON subjects
  FOR EACH ROW
BEGIN
  IF  :new.subj_id IS NULL THEN
    SELECT subj_seq.nextval
      INTO :new.subj_id
      FROM dual;
  END IF ;
END;
/
ALTER TRIGGER subj_tr_set_id ENABLE;
/

INSERT ALL
  INTO specialties (spec_name) VALUES ('History')
  INTO specialties (spec_name) VALUES ('Architecture')
  INTO specialties (spec_name) VALUES ('Chemistry')
  INTO specialties (spec_name) VALUES ('Medicine')
  INTO specialties (spec_name) VALUES ('IT')
SELECT * FROM dual
;

INSERT ALL
  INTO students (stud_name, year_of_entry, spec_id) VALUES ('Tatyana', 2019, 1)
  INTO students (stud_name, year_of_entry, spec_id) VALUES ('Egor', 2019, 2)
  INTO students (stud_name, year_of_entry, spec_id) VALUES ('Arina', 2019, 3)
  INTO students (stud_name, year_of_entry, spec_id) VALUES ('Valentin', 2019, 4)
  INTO students (stud_name, year_of_entry, spec_id) VALUES ('Polina', 2019, 5)
SELECT * FROM dual;

INSERT ALL
  INTO subjects (subj_name) VALUES ('Higher_mathematics')    
  INTO subjects (subj_name) VALUES ('Electric_drive') 
  INTO subjects (subj_name) VALUES ('Theoretical_mechanics') 
  INTO subjects (subj_name) VALUES ('German') 
  INTO subjects (subj_name) VALUES ('History')  
  INTO subjects (subj_name) VALUES ('Economy')  
  INTO subjects (subj_name) VALUES ('Сhemistry')     
SELECT * FROM dual;


INSERT ALL
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (1, 1, 1, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (1, 1, 3, 'Examination') 
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (1, 1, 4, 'Examination') 
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (1, 1, 7, 'Examination')
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (2, 1, 1, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (2, 1, 3, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (2, 1, 4, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (2, 1, 2, 'Examination') 
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (2, 1, 7, 'Examination')
  
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (3, 1, 1, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (3, 1, 4, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (3, 1, 6, 'Examination') 
  
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (4, 1, 1, 'Examination') 
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (4, 1, 4, 'Examination')
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (4, 1, 5, 'Examination')  
  
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (5, 1, 1, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (5, 1, 2, 'Examination')   
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (5, 1, 4, 'Examination') 
  INTO curriculums (spec_id, semester, subj_id, report_TYPE) VALUES (5, 1, 7, 'Examination')
SELECT * FROM dual;

INSERT ALL
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (1, 1, DATE'2020-01-14', 5)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (1, 2, DATE'2020-01-17', 5)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (1, 3, DATE'2020-01-21', 4)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (1, 4, DATE'2020-01-24', 4)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (2, 5, DATE'2020-01-14', 2)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (2, 6, DATE'2020-01-17', 4)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (2, 7, DATE'2020-01-21', 4)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (2, 8, DATE'2020-01-27', 3)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (2, 9, DATE'2020-01-24', 4)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (3, 10, DATE'2020-01-14', 3)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (3, 11, DATE'2020-01-21', 3)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (3, 12, DATE'2020-01-17', 4)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (4, 13, DATE'2020-01-21', 2)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (4, 14, DATE'2020-01-17', 2)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (4, 15, DATE'2020-01-14', 2)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (5, 16, DATE'2020-01-14', 2)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (5, 17, DATE'2020-01-21', 2)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (5, 18, DATE'2020-01-17', 2)
  INTO marks (student_id, curriculum_id, exam_date, MARK) VALUES (5, 19, DATE'2020-01-24', 5)
SELECT * FROM dual;

/
CREATE OR REPLACE FUNCTION fn_count_semester (
  par_stud_id in students.stud_id%TYPE
) RETURN NUMBER
IS
  var_year_of_entry students.year_of_entry%TYPE;
  var_years NUMBER;
  var_MONTH NUMBER;
  var_semestrs NUMBER;
BEGIN
  SELECT s.year_of_entry
    INTO var_year_of_entry
    FROM students s
    WHERE s.stud_id = par_stud_id;
  var_years := EXTRACT(YEAR FROM sysdate) - var_year_of_entry;
  var_MONTH := EXTRACT(MONTH FROM sysdate);
  var_semestrs := var_years * 2;
  IF  (var_month < 2) THEN
    var_semestrs := var_semestrs - 1;
  END IF ;
  IF  (var_month >= 9) THEN 
    var_semestrs := var_semestrs + 1;
  END IF ;
  RETURN var_semestrs;
END;
/

CREATE OR REPLACE VIEW v_academic_debts AS
SELECT  s.stud_id,
        s.stud_name,
        round(fn_count_semester(s.stud_id)/2) AS course,
        sub.subj_id,
        sub.subj_name,
        cur.semester AS semester
  FROM  students s
        INNER JOIN  specialties sp ON
          sp.spec_id = s.spec_id
        INNER JOIN  curriculums cur ON
          cur.spec_id = sp.spec_id AND
          cur.semester < fn_count_semester(s.stud_id)
        INNER JOIN  subjects sub ON
          sub.subj_id = cur.subj_id
        LEFT JOIN marks m ON
          m.stud_id = s.stud_id AND
          m.curr_id = cur.curr_id
  WHERE nvl(m.mark, 2) = 2
;

SELECT * FROM v_academic_debts;

SELECT  vad.stud_id,
        vad.stud_name, 
        COUNT(vad.stud_id) AS academic_debts_count
  FROM  v_academic_debts vad
  GROUP BY  vad.stud_id,
            vad.stud_name
  HAVING  COUNT(vad.stud_id) > 3
;

