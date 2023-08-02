-- TODO: проверить все ограничения в таблицах
-- [*] время проверки Verter'ом не может быть раньше, чем окончание проверки P2P
-- [*] проверка Verter'ом может ссылаться только на те проверки в таблице Checks, которые уже включают в себя успешную P2P проверку
-- [*] в таблице transferred_points количество points_amount должно быть неотрицательным
-- [*] в таблице friends поля peer1 и peer2 для одной записи не могут совпадать
-- [*] в таблице recommendations  поля peer и recommended_peer не может быть одним человекрм
-- в таблице recommendations рекомендовать можно только того, у кого был на проверке, то есть в поле peer можно добавлять записи checked_peer из transferred_points, а в recommended_peer можно добавлять только checking_peer соответствующего checked_peer
-- [*] количество xp в таблице xp не может превышать максимальное доступное для проверяемой задачи - поле max_xp из таблицы tasks
-- [*] поле id таблицы xp может ссылаться только на успешные проверки (Проверка считается успешной, если соответствующий P2P этап успешен, а этап Verter успешен, либо отсутствует)
-- Таблица time_tracking. Состояние (1 - пришел, 2 - вышел). В течение одного дня должно быть одинаковое количество записей с состоянием 1 и состоянием 2 для каждого пира. Записи должны идти в чередующемся порядке 1, 2, 1, 2 и т.д.
-- p2p и verter происходят в один день, (дата в checks)
-- в таблицу check возможно добавить проверку задания пира, только если в ней есть успешная проверка предыдущего задания (выполнено условие входа) Добавить условие, что мы не добавляем Pool. Pool без родителя.

-- Проверить:
-- В таблицу P2P и Verter можно добавить  запись со статусом Failure раньше чем запись со статусом Start. Это не логично.
-- В таблицу P2P и Verter можно добавить 2 записи. Одну со статусом Failure, а другую со статусом Success.
-- В таблицу P2P и Verter можно добавить запись с записью Failure или Success, у которой время раньше чем у записи со статусом Start.
-- Нумерация в таблицах P2P и Verter  происходит не порядку. Допустим в таблице при внесении данных произошла автоматическая нумерация после 16, сразу 18, а потом 20.

-- ПРОВЕРКИ НА УНИКАЛЬНОСТЬ И ЛОГИКУ:

-- для таблицы p2p
-- если в таблице p2p нет записей для проверки, то добавляемая запись должна быть со статусом start
-- если в таблице p2p есть запись со статусом start, нельзя добавить запись со временем более ранним, чем у записи со статусом start
-- если в таблице p2p есть запись со статусом start, то добавляемая запись должна быть со статусом success или failure
-- если в таблице p2p есть запись со статусом success или failure, нельзя добавить новую запись

-- для таблицы verter:
-- если в таблице verter нет записей для проверки, то добавляемая запись должна иметь статус success в p2p
-- если в таблице verter нет записей для проверки, то добавляемая запись должна быть со статусом start
-- если в таблице verter есть запись со статусом start, нельзя добавить запись со временем более ранним, чем у записи со статусом start
-- если в таблице verter есть запись со статусом start, то добавляемая запись должна быть со статусом success или failure
-- если в таблице verter есть запись со статусом success или failure, нельзя добавить новую запись

-- для таблицы friends
-- если дружба уже существует, то нельзя добавить дубль

-- для таблицы recommendations
-- если дружба уже существует, то нельзя добавить дубль

-- нельзя передать поинт самому себе

-- для таблицы time_tracking
-- ?

-- TODO: задачи
-- проверить ограничения таска с описанными выше - есть ли запись? Если записи нет, возможно уже реализовано.
-- создать и добавить 2 успешные проверки в таблицу xp

-- CREATE DATABASE info_21;

-- Подключиться к созданной базе следует вручную
-- psql -h хост -p порт -U пользователь -d имя_базы_данных
-- где:
-- хост - адрес сервера базы данных PostgreSQL
-- порт - порт сервера базы данных PostgreSQL (обычно 5432)
-- пользователь - имя пользователя базы данных
-- имя_базы_данных - имя созданной базы данных

CREATE SCHEMA IF NOT EXISTS public;

DROP TABLE IF EXISTS peers, tasks, p2p, verter, checks, transferred_points, friends, recommendations, xp, time_tracking CASCADE;
DROP TYPE IF EXISTS state_of_check;

-- Создание таблицы peers
CREATE TABLE peers
(
    nickname varchar(16) primary key,
    birthday date
);

-- Заполнение таблицы peers
INSERT INTO peers (nickname, birthday)
VALUES ('yonnarge', '1997-10-07'),
       ('nyarlath', '2004-09-14'),
       ('cherigra', NULL),
       ('tamelabe', '1996-08-11'),
       ('manhunte', NULL);

-- Создание таблицы tasks
CREATE TABLE tasks
(
    title       varchar(32) primary key,
    parent_task varchar(32),
    max_xp      int,
    CONSTRAINT ch_range_max_xp CHECK (max_xp >= 0),
    CONSTRAINT fk_tasks_parent_task FOREIGN KEY (parent_task) REFERENCES tasks (title)
);

-- Заполнение таблицы tasks
INSERT INTO tasks (title, parent_task, max_xp)
VALUES ('Pool', NULL, 0),
       ('C2_Simple_Bash_Utils', 'Pool', 250),
       ('C3_s21_stringplus', 'C2_Simple_Bash_Utils', 500),
       ('C5_s21_decimal', 'C3_s21_stringplus', 350),
       ('DO1_Linux', 'C3_s21_stringplus', 300),
       ('C6_s21_matrix', 'C5_s21_decimal', 200);

-- Создание таблицы checks
CREATE TABLE checks
(
    id   serial primary key,
    peer varchar(16),
    task varchar(32),
    date date,
    CONSTRAINT ch_checks_current_date CHECK ( date <= current_date ),
    CONSTRAINT fk_checks_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_checks_task FOREIGN KEY (task) REFERENCES tasks (title)
);

-- Заполнение таблицы checks
INSERT INTO checks (id, peer, task, date)
VALUES (1, 'tamelabe', 'C2_Simple_Bash_Utils', '2023-07-01'),
       (2, 'nyarlath', 'C3_s21_stringplus', '2023-07-02'),
       (3, 'cherigra', 'C5_s21_decimal', '2023-07-03'),
       (4, 'manhunte', 'DO1_Linux', '2023-07-04'),
       (5, 'yonnarge', 'C6_s21_matrix', '2023-07-05'),
       (6, 'nyarlath', 'DO1_Linux', '2023-07-06');

-- Создание типа перечисления для статуса проверки
CREATE TYPE state_of_check AS ENUM ('start', 'success', 'failure');

-- Создание таблицы p2p
CREATE TABLE p2p
(
    id            serial primary key,
    check_id      int,
    checking_peer varchar(16),
    state         state_of_check,
    time          timestamp,
    CONSTRAINT ch_p2p_current_time CHECK ( time <= current_timestamp ),
    CONSTRAINT fk_p2p_check_id FOREIGN KEY (check_id) REFERENCES checks (id),
    CONSTRAINT fk_p2p_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname)
);

-- Заполнение таблицы p2p
INSERT INTO p2p (id, check_id, checking_peer, state, time)
VALUES (1, 1, 'yonnarge', 'start', '2023-07-01 10:00:00'),
       (2, 1, 'yonnarge', 'success', '2023-07-01 11:00:00'),
       (3, 2, 'cherigra', 'start', '2023-07-02 09:00:00'),
       (4, 2, 'cherigra', 'success', '2023-07-02 10:30:00'),
       (5, 3, 'manhunte', 'start', '2023-07-03 14:00:00'),
       (6, 3, 'manhunte', 'failure', '2023-07-03 14:30:00'),
       (7, 4, 'tamelabe', 'start', '2023-07-04 09:00:00'),
       (8, 4, 'tamelabe', 'success', '2023-07-04 10:30:00'),
       (9, 5, 'nyarlath', 'start', '2023-07-05 21:30:00'),
       (10, 5, 'nyarlath', 'success', '2023-07-05 22:00:00'),
       (11, 6, 'manhunte', 'start', '2023-07-06 14:30:00'),
       (12, 6, 'manhunte', 'success', '2023-07-06 15:30:00');


CREATE OR REPLACE FUNCTION p2p_check_two_notes()
    RETURNS TRIGGER AS
$$
DECLARE
    count_records INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO count_records
    FROM p2p
    WHERE check_id = NEW.check_id;

    IF count_records >= 2 THEN
        RAISE EXCEPTION 'maximum number of records with the same check_id reached';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER p2p_check_two_notes_trigger
    BEFORE INSERT OR UPDATE
    ON p2p
    FOR EACH ROW
EXECUTE FUNCTION p2p_check_two_notes();

-- Создание таблицы verter
CREATE TABLE verter
(
    id       serial primary key,
    check_id int,
    state    state_of_check,
    time     timestamp,
    CONSTRAINT ch_verter_current_time CHECK ( time <= current_timestamp ),
    CONSTRAINT fk_verter_check_id FOREIGN KEY (check_id) REFERENCES checks (id)
);

CREATE OR REPLACE FUNCTION check_verter_time()
    RETURNS TRIGGER AS
$$
BEGIN
    -- Проверка, что время проверки Verter'ом не раньше, чем окончание проверки P2P
    IF EXISTS(
        -- Запрашиваем только одну строку с единственным значением 1.
        -- Это делается для оптимизации запроса, поскольку нам не нужны фактические данные из таблицы,
        -- нам нужно только узнать, есть ли хотя бы одна запись, удовлетворяющая условию.
            SELECT 1
            FROM p2p
            WHERE p2p.check_id = NEW.check_id
              AND p2p.time > NEW.time
        ) THEN
        RAISE EXCEPTION 'verter checking time cannot be earlier than p2p checking time';
    END IF;

    RETURN NEW;
END ;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_verter_time_trigger
    BEFORE INSERT OR UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_verter_time();

CREATE OR REPLACE FUNCTION check_success_p2p()
    RETURNS TRIGGER AS
$$
BEGIN
    -- Проверка, что можно ссылаться только на успешные P2P проверки
    IF NOT EXISTS(
            SELECT 1
            FROM checks
                     JOIN p2p ON checks.id = p2p.check_id
            WHERE checks.id = NEW.check_id
              AND p2p.state = 'success'
        ) THEN
        RAISE EXCEPTION 'you can only refer to successful p2p checks';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verter_check_success_p2p_trigger
    BEFORE INSERT OR UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION check_success_p2p();

CREATE OR REPLACE FUNCTION verter_check_two_notes()
    RETURNS TRIGGER AS
$$
DECLARE
    count_records INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO count_records
    FROM verter
    WHERE check_id = NEW.check_id;

    IF count_records >= 2 THEN
        RAISE EXCEPTION 'maximum number of records with the same check_id reached';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verter_check_two_notes_trigger
    BEFORE INSERT OR UPDATE
    ON verter
    FOR EACH ROW
EXECUTE FUNCTION verter_check_two_notes();

-- Заполнение таблицы verter
INSERT INTO verter (id, check_id, state, time)
VALUES (1, 1, 'start', '2023-07-01 11:01:00'),
       (2, 1, 'success', '2023-07-01 11:02:00'),
       (3, 2, 'start', '2023-07-02 10:31:00'),
       (4, 2, 'success', '2023-07-02 10:32:00'),
       (5, 5, 'start', '2023-07-05 22:01:11'),
       (6, 5, 'failure', '2023-07-05 22:02:23');

-- Создание таблицы transferred_points
CREATE TABLE transferred_points
(
    id            serial primary key,
    checking_peer varchar(16),
    checked_peer  varchar(16),
    points_amount int,
    CONSTRAINT ch_range_points_amount CHECK (points_amount >= 0),
    CONSTRAINT fk_transferred_points_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT fk_transferred_points_checked_peer FOREIGN KEY (checked_peer) REFERENCES peers (nickname)
);

-- Заполнение таблицы transferred_points
INSERT INTO transferred_points (id, checking_peer, checked_peer, points_amount)
VALUES (1, 'yonnarge', 'tamelabe', 1),
       (2, 'cherigra', 'nyarlath', 1),
       (3, 'manhunte', 'cherigra', 1),
       (4, 'tamelabe', 'manhunte', 1),
       (5, 'nyarlath', 'yonnarge', 1),
       (6, 'manhunte', 'nyarlath', 1);

-- Создание таблицы friends
CREATE TABLE friends
(
    id    serial primary key,
    peer1 varchar(16),
    peer2 varchar(16),
    CONSTRAINT ch_prevent_self_friend CHECK (peer1 != peer2),
    CONSTRAINT fk_friends_peer1 FOREIGN KEY (peer1) REFERENCES peers (nickname),
    CONSTRAINT fk_friends_peer2 FOREIGN KEY (peer2) REFERENCES peers (nickname)
);

-- Проверяет дублирующие записи в таблице friends
CREATE OR REPLACE FUNCTION prevent_duplicate_friends()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT 1
            FROM friends
            WHERE (peer1 = NEW.peer1 AND peer2 = NEW.peer2)
        ) THEN
        RAISE EXCEPTION 'duplicate_friendship_is_not_allowed';
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

-- Предотвращает дублирующие записи в таблице friends
CREATE TRIGGER check_duplicate_friends
    BEFORE INSERT
    ON friends
    FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_friends();

-- Заполнение таблицы friends
INSERT INTO friends (id, peer1, peer2)
VALUES (1, 'manhunte', 'cherigra'),
       (2, 'nyarlath', 'tamelabe'),
       (3, 'tamelabe', 'yonnarge'),
       (4, 'yonnarge', 'nyarlath'),
       (5, 'cherigra', 'nyarlath');

-- -- Проверка на запрет дублирования в таблице friends
-- INSERT INTO friends (id, peer1, peer2)
-- VALUES (6, 'manhunte', 'cherigra');

-- -- Проверка на запрет дружбы с самим собой
-- INSERT INTO friends (id, peer1, peer2)
-- VALUES (7, 'manhunte', 'manhunte');

-- Создание таблицы recommendations
CREATE TABLE recommendations
(
    id               serial primary key,
    peer             varchar(16),
    recommended_peer varchar(16),
    CONSTRAINT ch_prevent_self_recommendation CHECK (peer != recommended_peer),
    CONSTRAINT fk_recommendations_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_recommendations_recommended_peer FOREIGN KEY (recommended_peer) REFERENCES peers (nickname)
);

-- Проверяет дублирующие записи в таблице recommendations
CREATE OR REPLACE FUNCTION prevent_duplicate_recommendations()
    RETURNS TRIGGER AS
$$
BEGIN
    IF EXISTS(
            SELECT 1
            FROM recommendations
            WHERE peer = NEW.peer
              AND recommended_peer = NEW.recommended_peer
        ) THEN
        RAISE EXCEPTION 'Duplicate recommendation is not allowed';
    END IF;
    RETURN NEW;
END;
$$
    LANGUAGE plpgsql;

-- Предотвращает дублирующие записи в таблице recommendations
CREATE TRIGGER check_duplicate_recommendations
    BEFORE INSERT
    ON recommendations
    FOR EACH ROW
EXECUTE FUNCTION prevent_duplicate_recommendations();

-- Заполнение таблицы recommendations
INSERT INTO recommendations (id, peer, recommended_peer)
VALUES (1, 'cherigra', 'manhunte'),
       (2, 'manhunte', 'tamelabe'),
       (3, 'nyarlath', 'cherigra'),
       (4, 'tamelabe', 'yonnarge'),
       (5, 'yonnarge', 'nyarlath');

-- -- Проверка на запрет дублирования в таблице recommendations
-- INSERT INTO recommendations (id, peer, recommended_peer)
-- VALUES (6, 'cherigra', 'manhunte');

-- -- Проверка на запрет дружбы с самим recommendations
-- INSERT INTO recommendations (id, peer, recommended_peer)
-- VALUES (7, 'manhunte', 'manhunte');

-- Создание таблицы xp
CREATE TABLE xp
(
    id        serial primary key,
    check_id  int,
    xp_amount int,
    CONSTRAINT ch_xp_amount_range CHECK (xp_amount >= 0),
    CONSTRAINT fk_xp_check_id FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Проверяет, что значение xp_amount не превышает max_xp для соответствующего задания:
CREATE OR REPLACE FUNCTION check_xp_amount()
    RETURNS TRIGGER AS
$$
BEGIN
    DECLARE
        max_xp_value INT;
    BEGIN
        SELECT max_xp
        INTO max_xp_value
        FROM tasks
                 JOIN checks ON tasks.title = checks.task
        WHERE checks.id = NEW.check_id;

        -- Проверка, что xp_amount не превышает max_xp
        IF NEW.xp_amount > max_xp_value THEN
            RAISE EXCEPTION 'xp_amount exceeds max_xp';
        END IF;

        RETURN NEW;
    END;
END;
$$ LANGUAGE plpgsql;

-- Функция для таблицы xp, которая проверяет, что проверка Verter'ом является успешной или отсутствует:
CREATE OR REPLACE FUNCTION check_success_verter()
    RETURNS TRIGGER AS
$$
DECLARE
    verter_check_success BOOLEAN;
    verter_check_exists  BOOLEAN;
BEGIN
    SELECT EXISTS(
                   SELECT 1
                   FROM verter
                   WHERE check_id = NEW.check_id
               )
    INTO verter_check_exists;

    SELECT EXISTS(
                   SELECT 1
                   FROM verter
                   WHERE check_id = NEW.check_id
                     AND state = 'success'
               )
    INTO verter_check_success;

    IF (NOT verter_check_exists) AND verter_check_success THEN
        RAISE EXCEPTION 'there are not successful verter check';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Проверяет, не превышает ли добавляемое значение xp максимально возможное для данного задания
-- перед добавлением/изменением в таблице xp
CREATE TRIGGER xp_check_xp_amount_trigger
    BEFORE INSERT OR UPDATE
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION check_xp_amount();

-- Проверяет есть ли успешная проверка p2p задания
-- перед добавлением/изменением в таблице xp
CREATE TRIGGER xp_check_success_p2p
    BEFORE INSERT OR UPDATE
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION check_success_p2p();

-- Проверяет есть ли успешная проверка verter'ом задания
-- перед добавлением/изменением в таблице xp
CREATE TRIGGER xp_check_success_verter
    BEFORE INSERT OR UPDATE
    ON xp
    FOR EACH ROW
EXECUTE FUNCTION check_success_verter();

-- Заполнение таблицы xp
INSERT INTO xp (id, check_id, xp_amount)
VALUES (1, 1, 250),
       (2, 2, 500),
       (6, 6, 300);

-- Создание таблицы time_tracking
CREATE TABLE time_tracking
(
    id            serial primary key,
    peer_nickname varchar(16),
    date          date,
    time          time,
    state         int,
    CONSTRAINT fk_time_tracking_peer_nickname FOREIGN KEY (peer_nickname) REFERENCES peers (nickname),
    CONSTRAINT ch_state CHECK ( state IN (1, 2) )
);

-- Заполнение таблицы time_tracking
INSERT INTO time_tracking (id, peer_nickname, date, time, state)
VALUES (1, 'tamelabe', '2023-07-01', '08:00:00', 1),
       (2, 'cherigra', '2023-07-01', '09:00:00', 1),
       (3, 'cherigra', '2023-07-01', '10:00:00', 2),
       (4, 'manhunte', '2023-07-01', '12:00:00', 1),
       (5, 'manhunte', '2023-07-01', '17:00:00', 2),
       (6, 'tamelabe', '2023-07-01', '18:00:00', 2);

-- Функция импорта данных из CSV файла в указанную таблицу
CREATE OR REPLACE FUNCTION ImportTableFromCSV(
    IN table_name TEXT,
    IN delimiter CHAR,
    IN file_path TEXT
)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$$
BEGIN
    EXECUTE format('COPY %I FROM %L WITH (FORMAT CSV, DELIMITER %L, HEADER)', table_name, file_path, delimiter);
END;
$$;

-- Функция экспорта данных из указанной таблицы в CSV файл
CREATE OR REPLACE FUNCTION ExportTableToCSV(
    IN table_name TEXT,
    IN delimiter CHAR,
    IN file_path TEXT
)
    RETURNS VOID
    LANGUAGE plpgsql
AS
$$
BEGIN
    EXECUTE format('COPY %I TO %L WITH (FORMAT CSV, DELIMITER %L, HEADER)', table_name, file_path, delimiter);
END;
$$;

-- -- Импорт данных из CSV файла
-- -- CALL ImportTableFromCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/xp.csv');
-- SELECT ImportTableFromCSV('peers', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/peers.csv');
-- SELECT ImportTableFromCSV('tasks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/tasks.csv');
-- SELECT ImportTableFromCSV('checks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/checks.csv');
-- SELECT ImportTableFromCSV('p2p', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/p2p.csv');
-- SELECT ImportTableFromCSV('verter', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/verter.csv');
-- SELECT ImportTableFromCSV('transferred_points', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/transferred_points.csv');
-- SELECT ImportTableFromCSV('friends', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/friends.csv');
-- SELECT ImportTableFromCSV('recommendations', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/recommendations.csv');
-- SELECT ImportTableFromCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/xp.csv');
-- SELECT ImportTableFromCSV('time_tracking', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/time_tracking.csv');
--
-- -- Экспорт данных в CSV файл
-- SELECT ExportTableToCSV('peers', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/peers.csv');
-- SELECT ExportTableToCSV('tasks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/tasks.csv');
-- SELECT ExportTableToCSV('checks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/checks.csv');
-- SELECT ExportTableToCSV('p2p', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/p2p.csv');
-- SELECT ExportTableToCSV('verter', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/verter.csv');
-- SELECT ExportTableToCSV('transferred_points', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/transferred_points.csv');
-- SELECT ExportTableToCSV('friends', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/friends.csv');
-- SELECT ExportTableToCSV('recommendations', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/recommendations.csv');
-- SELECT ExportTableToCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/xp.csv');
-- SELECT ExportTableToCSV('time_tracking', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/time_tracking.csv');

