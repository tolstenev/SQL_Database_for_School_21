CREATE DATABASE INFO_21;

-- Создание таблицы peers
CREATE TABLE peers (
    nickname varchar(16) primary key not null,
    birthday date not null
);

-- Создание таблицы tasks
CREATE TABLE tasks (
    title varchar(32) primary key not null,
    parent_task varchar(32),
    max_xp int not null,
    CHECK (max_xp >= 0),
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
    check_id int not null,
    checking_peer varchar(16),
    state state_of_check,
    time timestamp,
    FOREIGN KEY (check_id) REFERENCES checks (id),
    FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT unique_p2p UNIQUE (check_id, state)
);

-- Создание таблицы verter
CREATE TABLE verter (
    id serial primary key,
    check_id int,
    state state_of_check,
    time timestamp,
    FOREIGN KEY (check_id) REFERENCES checks (id),
    CONSTRAINT unique_verter UNIQUE (check_id, state)
);

-- Создание таблицы transferred_points
CREATE TABLE transferred_points (
    id serial primary key,
    checking_peer varchar(16),
    checked_peer varchar(16),
    points_amount int,
    CHECK (checking_peer != checked_peer),
    FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    FOREIGN KEY (checked_peer) REFERENCES peers (nickname)
);

-- Создание таблицы friends
CREATE TABLE friends (
    id serial primary key,
    peer1 varchar(16),
    peer2 varchar(16),
    CHECK (peer1 != peer2),
    FOREIGN KEY (peer1) REFERENCES peers (nickname),
    FOREIGN KEY (peer2) REFERENCES peers (nickname)
    CONSTRAINT unique_friends UNIQUE (peer1, peer2)
);

-- Создание таблицы recommendations
CREATE TABLE recommendations (
    id serial primary key,
    peer varchar(16),
    recommended_peer varchar(16),
    CHECK (peer != recommended_peer),
    FOREIGN KEY (peer) REFERENCES peers (nickname),
    FOREIGN KEY (recommended_peer) REFERENCES peers (nickname)
    CONSTRAINT unique_recommendations UNIQUE (peer, recommended_peer)
);

-- Создание таблицы xp
CREATE TABLE xp (
    id serial primary key,
    check_id int,
    xp_amount int,
    CHECK (xp_amount >= 0),
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

-- Триггеры

-- При добавлении записи в check идет проверка на завершение родительского таска
CREATE OR REPLACE FUNCTION check_parent_task_in_xp() RETURNS trigger AS $$
BEGIN
    IF (SELECT parent_task FROM tasks WHERE tasks.title = NEW.task AND parent_task IS NOT NULL) IS NOT NULL THEN
        -- Проверяем наличие записи в тpаблице xp по parent_task
        IF NOT EXISTS (SELECT 1 FROM xp
        JOIN checks ON xp.check_id = checks.id
        WHERE checks.peer = NEW.peer AND checks.task IN (SELECT parent_task FROM tasks WHERE tasks.title = NEW.task)) THEN
            RAISE EXCEPTION 'Родительский таск не был выполнен';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_xp_completed_trigger
AFTER INSERT OR UPDATE ON checks
FOR EACH ROW
EXECUTE FUNCTION check_parent_task_in_xp();


    
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