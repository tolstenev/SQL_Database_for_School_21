-- TODO: проверить все ограничения в таблицах
-- время проверки Verter'ом не может быть раньше, чем окончание проверки P2P
-- проверка Verter'ом может ссылаться только на те проверки в таблице Checks, которые уже включают в себя успешную P2P проверку
-- в таблице transferred_points количество points_amount должно быть неотрицательным
-- в таблице friends поля peer1 и peer2 для одной записи не могут совпадать
-- в таблице recommendations рекомендовать можно только того, у кого был на проверке, то есть в поле peer можно добавлять записи checked_peer из transferred_points, а в recommended_peer можно добавлять только checking_peer соответствующего checked_peer
-- количество xp в таблице xp не может превышать максимальное доступное для проверяемой задачи - поле max_xp из таблицы tasks
-- поле check_id таблицы xp может ссылаться только на успешные проверки
-- Таблица time_tracking. Состояние (1 - пришел, 2 - вышел). В течение одного дня должно быть одинаковое количество записей с состоянием 1 и состоянием 2 для каждого пира. Записи должны идти в чередующемся порядке 1, 2, 1, 2 и т.д.


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
       ('cherigra', '1988-12-15'),
       ('tamelabe', '1996-08-11'),
       ('manhunte', '1991-09-07');

-- Создание таблицы tasks
CREATE TABLE tasks
(
    title       varchar(32) primary key,
    parent_task varchar(32),
    max_xp      int,
    FOREIGN KEY (parent_task) REFERENCES tasks (title)
);

-- Заполнение таблицы tasks
INSERT INTO tasks (title, parent_task, max_xp)
VALUES ('Pool', NULL, 0),
       ('C2_Simple_Bash_Utils', 'Pool', 250),
       ('C3_s21_stringplus', 'C2_Simple_Bash_Utils', 500),
       ('C5_s21_decimal', 'C3_s21_stringplus', 350),
       ('DO1_Linux', 'C3_s21_stringplus', 300),
       ('C6_s21_matrix', 'C5_s21_decimal', 200);

-- Создание типа перечисления для статуса проверки
CREATE TYPE state_of_check AS ENUM ('Start', 'Success', 'Failure');

-- Создание таблицы p2p
CREATE TABLE p2p
(
    id            serial primary key,
    check_id      int,
    checking_peer varchar(16),
    state         state_of_check,
    time          timestamp,
    FOREIGN KEY (check_id) REFERENCES checks (id),
    FOREIGN KEY (checking_peer) REFERENCES peers (nickname)
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
       (10, 5, 'nyarlath', 'success', '2023-07-05 22:00:00');

-- Создание таблицы verter
CREATE TABLE verter
(
    id            serial primary key,
    check_id      int,
    verter_status state_of_check,
    time          timestamp,
    FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Заполнение таблицы verter
INSERT INTO verter (id, check_id, verter_status, time)
VALUES (1, 1, 'start', '2023-07-01 11:01:00'),
       (2, 1, 'success', '2023-07-01 11:02:00'),
       (3, 2, 'start', '2023-07-02 10:31:00'),
       (4, 2, 'success', '2023-07-02 10:32:00'),
       (5, 5, 'start', '2023-07-05 22:01:11'),
       (6, 5, 'failure', '2023-07-05 22:02:23');

-- Создание таблицы checks
CREATE TABLE checks
(
    id   serial primary key,
    peer varchar(16),
    task varchar(32),
    date date,
    FOREIGN KEY (peer) REFERENCES peers (nickname),
    FOREIGN KEY (task) REFERENCES tasks (title)
);

-- Заполнение таблицы checks
INSERT INTO checks (id, peer, task, date)
VALUES (1, 'tamelabe', 'C2_Simple_Bash_Utils', '2023-07-01'),
       (2, 'nyarlath', 'C3_s21_stringplus', '2023-07-02'),
       (3, 'cherigra', 'C5_s21_decimal', '2023-07-03'),
       (4, 'manhunte', 'DO1_Linux', '2023-07-04'),
       (5, 'yonnarge', 'C6_s21_matrix', '2023-07-05');

-- Создание таблицы transferred_points
CREATE TABLE transferred_points
(
    id            serial primary key,
    checking_peer varchar(16),
    checked_peer  varchar(16),
    points_amount int,
    FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    FOREIGN KEY (checked_peer) REFERENCES peers (nickname)
);

-- Заполнение таблицы transferred_points
INSERT INTO transferred_points (id, checking_peer, checked_peer, points_amount)
VALUES (1, 'yonnarge', 'tamelabe', 1),
       (2, 'cherigra', 'nyarlath', 1),
       (3, 'manhunte', 'cherigra', 1),
       (4, 'tamelabe', 'manhunte', 1),
       (5, 'nyarlath', 'yonnarge', 1);

-- Создание таблицы friends
CREATE TABLE friends
(
    id    serial primary key,
    peer1 varchar(16),
    peer2 varchar(16),
    FOREIGN KEY (peer1) REFERENCES peers (nickname),
    FOREIGN KEY (peer2) REFERENCES peers (nickname)
);

-- Заполнение таблицы friends
INSERT INTO friends (id, peer1, peer2)
VALUES (1, 'manhunte', 'cherigra'),
       (2, 'nyarlath', 'tamelabe'),
       (3, 'tamelabe', 'yonnarge'),
       (4, 'yonnarge', 'nyarlath'),
       (5, 'cherigra', 'nyarlath');

-- Создание таблицы recommendations
CREATE TABLE recommendations
(
    id               serial primary key,
    peer             varchar(16),
    recommended_peer varchar(16),
    FOREIGN KEY (peer) REFERENCES peers (nickname),
    FOREIGN KEY (recommended_peer) REFERENCES peers (nickname)
);

-- Заполнение таблицы recommendations
INSERT INTO recommendations (id, peer, recommended_peer)
VALUES (1, 'cherigra', 'manhunte'),
       (2, 'manhunte', 'tamelabe'),
       (3, 'nyarlath', 'cherigra'),
       (4, 'tamelabe', 'yonnarge'),
       (5, 'yonnarge', 'nyarlath');

-- Создание таблицы xp
CREATE TABLE xp
(
    id        serial primary key,
    check_id  int,
    xp_amount int,
    FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Заполнение таблицы xp
INSERT INTO xp (id, check_id, xp_amount)
VALUES (1, 1, 250),
       (2, 2, 500),
       (3, 3, 350),
       (4, 4, 0),
       (5, 5, 0);

-- Создание таблицы time_tracking
CREATE TABLE time_tracking
(
    id            serial primary key,
    peer_nickname varchar(16),
    date          date,
    time          time,
    state         int,
    FOREIGN KEY (peer_nickname) REFERENCES peers (nickname),
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


--   -- Процедура импорта данных в таблицу Peers из файла CSV
-- DELIMITER //
--
-- CREATE PROCEDURE ImportPeers(IN fileName VARCHAR(255), IN delimiter CHAR(1))
-- BEGIN
--   SET @query = CONCAT("LOAD DATA INFILE '", fileName, "' INTO TABLE Peers FIELDS TERMINATED BY '", delimiter, "' IGNORE 1 LINES;");
--   PREPARE stmt FROM @query;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
-- END //
--
-- DELIMITER ;
--
-- -- Процедура экспорта данных из таблицы Peers в файл CSV
-- DELIMITER //
--
-- CREATE PROCEDURE ExportPeers(IN fileName VARCHAR(255), IN delimiter CHAR(1))
-- BEGIN
--   SET @query = CONCAT("SELECT * INTO OUTFILE '", fileName, "' FIELDS TERMINATED BY '", delimiter, "' FROM Peers;");
--   PREPARE stmt FROM @query;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
-- END //
--
-- DELIMITER ;
--
-- -- Аналогично создайте процедуры импорта и экспорта для каждой оставшейся таблицы
--
-- -- Процедура импорта данных в таблицу Tasks из файла CSV
-- DELIMITER //
--
-- CREATE PROCEDURE ImportTasks(IN fileName VARCHAR(255), IN delimiter CHAR(1))
-- BEGIN
--   SET @query = CONCAT("LOAD DATA INFILE '", fileName, "' INTO TABLE Tasks FIELDS TERMINATED BY '", delimiter, "' IGNORE 1 LINES;");
--   PREPARE stmt FROM @query;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
-- END //
--
-- DELIMITER ;
--
-- -- Процедура экспорта данных из таблицы Tasks в файл CSV
-- DELIMITER //
--
-- CREATE PROCEDURE ExportTasks(IN fileName VARCHAR(255), IN delimiter CHAR(1))
-- BEGIN
--   SET @query = CONCAT("SELECT * INTO OUTFILE '", fileName, "' FIELDS TERMINATED BY '", delimiter, "' FROM Tasks;");
--   PREPARE stmt FROM @query;
--   EXECUTE stmt;
--   DEALLOCATE PREPARE stmt;
-- END //
--
-- DELIMITER ;