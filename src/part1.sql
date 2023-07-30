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

CREATE TABLE peers (
    nickname varchar(16) primary key,
    birthday date
);

-- Создание таблицы tasks
CREATE TABLE tasks (
    title varchar(32) primary key,
    parent_task varchar(32),
    max_xp int,
    FOREIGN KEY (parent_task) REFERENCES tasks (title)
);

-- Создание таблицы checks
CREATE TABLE checks (
    id serial primary key,
    peer varchar(16),
    task varchar(32),
    date date,
    FOREIGN KEY (peer) REFERENCES peers (nickname),
    FOREIGN KEY (task) REFERENCES tasks (title)
);

-- Создание типа перечисления для статуса проверки
CREATE TYPE state_of_check AS ENUM ('start', 'success', 'failure');

-- Создание таблицы p2p
CREATE TABLE p2p (
    id serial primary key,
    check_id int,
    checking_peer varchar(16),
    state state_of_check,
    time timestamp,
    FOREIGN KEY (check_id) REFERENCES checks (id),
    FOREIGN KEY (checking_peer) REFERENCES peers (nickname)
);

-- Создание таблицы verter
CREATE TABLE verter (
    id serial primary key,
    check_id int,
    verter_status state_of_check,
    time timestamp,
    FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Создание таблицы transferred_points
CREATE TABLE transferred_points (
    id serial primary key,
    checking_peer varchar(16),
    checked_peer varchar(16),
    points_amount int,
    FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    FOREIGN KEY (checked_peer) REFERENCES peers (nickname)
);

-- Создание таблицы friends
CREATE TABLE friends (
    id serial primary key,
    peer1 varchar(16),
    peer2 varchar(16),
    FOREIGN KEY (peer1) REFERENCES peers (nickname),
    FOREIGN KEY (peer2) REFERENCES peers (nickname)
);

-- Создание таблицы recommendations
CREATE TABLE recommendations (
    id serial primary key,
    peer varchar(16),
    recommended_peer varchar(16),
    FOREIGN KEY (peer) REFERENCES peers (nickname),
    FOREIGN KEY (recommended_peer) REFERENCES peers (nickname)
);

-- Создание таблицы xp
CREATE TABLE xp (
    id serial primary key,
    check_id int,
    xp_amount int,
    FOREIGN KEY (check_id) REFERENCES checks (id)
);

-- Создание таблицы time_tracking
CREATE TABLE time_tracking (
    id serial primary key,
    peer_nickname varchar(16),
    date date,
    time time,
    state int,
    FOREIGN KEY (peer_nickname) REFERENCES peers (nickname),
    CONSTRAINT ch_state CHECK (
        state IN (1, 2)
    )
);
    
-- Функция импорта данных из CSV файла в указанную таблицу
CREATE OR REPLACE FUNCTION ImportTableFromCSV(
  IN table_name TEXT,
  IN delimiter CHAR,
  IN file_path TEXT
)
RETURNS VOID
LANGUAGE plpgsql
AS $$
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
AS $$
BEGIN
  EXECUTE format('COPY %I TO %L WITH (FORMAT CSV, DELIMITER %L, HEADER)', table_name, file_path, delimiter);
END;
$$;

-- Импорт данных из CSV файла
-- CALL ImportTableFromCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/xp.csv');
SELECT ImportTableFromCSV('peers', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/peers.csv');
SELECT ImportTableFromCSV('tasks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/tasks.csv');
SELECT ImportTableFromCSV('checks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/checks.csv');
SELECT ImportTableFromCSV('p2p', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/p2p.csv');
SELECT ImportTableFromCSV('verter', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/verter.csv');
SELECT ImportTableFromCSV('transferred_points', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/transferred_points.csv');
SELECT ImportTableFromCSV('friends', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/friends.csv');
SELECT ImportTableFromCSV('recommendations', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/recommendations.csv');
SELECT ImportTableFromCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/xp.csv');
SELECT ImportTableFromCSV('time_tracking', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/time_tracking.csv');

-- Экспорт данных в CSV файл
SELECT ExportTableToCSV('peers', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/peers.csv');
SELECT ExportTableToCSV('tasks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/tasks.csv');
SELECT ExportTableToCSV('checks', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/checks.csv');
SELECT ExportTableToCSV('p2p', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/p2p.csv');
SELECT ExportTableToCSV('verter', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/verter.csv');
SELECT ExportTableToCSV('transferred_points', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/transferred_points.csv');
SELECT ExportTableToCSV('friends', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/friends.csv');
SELECT ExportTableToCSV('recommendations', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/recommendations.csv');
SELECT ExportTableToCSV('xp', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/xp.csv');
SELECT ExportTableToCSV('time_tracking', ',', '/Users/nyarlath/Desktop/SQL2_Info21_v1.0-2/src/data/time_tracking.csv');