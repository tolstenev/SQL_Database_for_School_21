-- Таблицы
DROP TABLE IF EXISTS peers,
tasks,
p2p,
verter,
checks,
transferred_points,
friends,
recommendations,
xp,
time_tracking CASCADE;



-- Создание перечисления "Статус проверки"
DROP TYPE IF EXISTS check_status CASCADE;
CREATE TYPE check_status AS ENUM ('Start', 'Success', 'Failure'); -- поменяла state_of_check на check_status


-- Создание таблицы peers
CREATE TABLE peers (
    nickname varchar(16) primary key not null,
    birthday date not NULL
);

INSERT INTO peers (nickname, birthday)
VALUES 
('ethylrac', '1996-05-01'),
('nyarlath', '1996-05-10'),
('yonnarge', '1996-05-20'),
('keyesdar', '1996-01-08'),
('mikaelag', '1996-01-09'),
('milagros', '1996-01-07'),
('rossetel', '1996-01-10'),
('tamelabe', '1996-01-02'),
('violette', '1996-01-05'),
('yonnarge', '1996-01-03')



-- Создание таблицы tasks
CREATE TABLE tasks (
    title varchar(32) primary key not null,
    parent_task varchar(32),
    max_xp int not null,
    CONSTRAINT ch_range_max_xp CHECK (max_xp >= 0),
    CONSTRAINT fk_tasks_parent_task FOREIGN KEY (parent_task) REFERENCES tasks (title)
);

INSERT INTO tasks
VALUES ('C2_SimpleBashUtils', NULL, 250),
       ('C3_s21_string+', 'C2_SimpleBashUtils', 500),
       ('C4_s21_math', 'C3_s21_string+', 300),
       ('DO1_Linux', 'C3_s21_string+', 300),
       ('DO2_Linux Network', 'DO1_Linux', 250),
       ('DO3_LinuxMonitoring v1.0', 'DO2_Linux Network', 350),
       ('CPP1_s21_matrix+', 'C4_s21_math', 300),
       ('CPP2_s21_containers', 'CPP1_s21_matrix+', 350);
       


-- Создание таблицы checks
CREATE TABLE checks (
    id serial PRIMARY KEY not null,
    peer varchar(16) not null,
    task varchar(32) not null,
    date_check date not null default CURRENT_DATE,
    CONSTRAINT ch_checks_current_date CHECK (date_check <= CURRENT_DATE), 
    CONSTRAINT fk_checks_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_checks_task FOREIGN KEY (task) REFERENCES tasks (title)
);


INSERT INTO checks (peer, task, date_check)
VALUES 
('ethylrac', 'C2_SimpleBashUtils', '2023-05-01'),
('nyarlath', 'C2_SimpleBashUtils', '2023-05-10'),
('yonnarge', 'C2_SimpleBashUtils', '2023-05-20'),
('nyarlath', 'C3_s21_string+', '2023-06-10'),
('yonnarge', 'C2_SimpleBashUtils', '2023-06-10'),
('nyarlath', 'C4_s21_math', '2023-07-10'),
('nyarlath', 'DO1_Linux', '2023-08-10');
       
      
-- Создание таблицы p2p
CREATE TABLE p2p (
    id serial primary KEY NOT NULL,
    check_id int not null,
    checking_peer varchar(16) not null,
    state_check check_status not null,
    time_check time not null, -- поменяла тип данных, тк дата есть в таблице checks
    --CONSTRAINT ch_p2p_current_time CHECK (time_check <= CURRENT_TIMESTAMP), -- не смогла запустить с этим ограничением
    CONSTRAINT fk_p2p_check_id FOREIGN KEY (check_id) REFERENCES checks (id),
    CONSTRAINT fk_p2p_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT unique_p2p UNIQUE (check_id, state_check)
);


INSERT INTO P2P (check_id, checking_peer, state_check, time_check)
VALUES 
(1, 'ethylrac', 'Start', '8:00'),
(1, 'ethylrac', 'Failure', '8:25'),
(2, 'nyarlath', 'Start', '10:00'),
(2, 'nyarlath', 'Success', '10:30'),
(3, 'yonnarge', 'Start', '9:00'),
(3, 'yonnarge', 'Success', '9:40'),
(4, 'nyarlath', 'Start', '10:10'),
(4, 'nyarlath', 'Success', '10:30'),
(5, 'yonnarge', 'Start', '9:10'),
(5, 'yonnarge', 'Success', '9:50'),
(6, 'nyarlath', 'Start', '10:20'),
(6, 'nyarlath', 'Success', '11:00'),
(7, 'nyarlath', 'Start', '10:30'),
(7, 'nyarlath', 'Success', '11:10')


-- Создание таблицы verter
CREATE TABLE verter (
    id serial primary KEY NOT NULL,
    check_id int not null,
    state_check check_status not null,
    time_check time not null, -- поменяла
    --CONSTRAINT ch_verter_current_time CHECK (time_check <= current_timestamp),
    CONSTRAINT fk_verter_check_id FOREIGN KEY (check_id) REFERENCES checks (id)
);

INSERT INTO Verter (check_id, state_check, time_check)
VALUES 
(2, 'Start', '10:31'),
(2, 'Success', '10:32'),
(3, 'Start', '9:41'),
(3, 'Failure', '9:42'),
(4, 'Start', '10:31'),
(4, 'Success', '10:32'),
(5, 'Start', '9:51'),
(5, 'Success', '9:52'),
(6, 'Start', '11:01'),
(6, 'Success', '11:02');
      

DROP TABLE xp

-- Создание таблицы xp
CREATE TABLE xp (
    id serial primary KEY not null,
    check_id int not null,
    xp_amount int not null,
    CONSTRAINT ch_xp_amount_range CHECK (xp_amount >= 0),
    CONSTRAINT fk_xp_check_id FOREIGN KEY (check_id) REFERENCES checks (id),
    CONSTRAINT unique_xp UNIQUE (check_id)
);

INSERT INTO XP (check_id, xp_amount)
VALUES 
	(2, 200),
	(4, 400),
	(5, 200),
	(6, 300),
	(7, 200);  
	      
-- Создание таблицы transferred_points
CREATE TABLE transferred_points (
    id serial primary KEY NOT null,
    checking_peer varchar(16) not null,
    checked_peer varchar(16) not null,
    points_amount int default 1 not null,
    CONSTRAINT ch_range_points_amount CHECK (points_amount >= 0),
    CONSTRAINT fk_transferred_points_checking_peer FOREIGN KEY (checking_peer) REFERENCES peers (nickname),
    CONSTRAINT fk_transferred_points_checked_peer FOREIGN KEY (checked_peer) REFERENCES peers (nickname)
);

-- Создание таблицы friends
CREATE TABLE friends (
    id serial primary KEY NOT NULL,
    peer1 varchar(16) not null,
    peer2 varchar(16) not null,
    CONSTRAINT ch_prevent_self_friend CHECK (peer1 != peer2),
    CONSTRAINT fk_friends_peer1 FOREIGN KEY (peer1) REFERENCES peers (nickname),
    CONSTRAINT fk_friends_peer2 FOREIGN KEY (peer2) REFERENCES peers (nickname),
    CONSTRAINT unique_friends UNIQUE (peer1, peer2)
);

INSERT INTO Friends (id, peer1, peer2)
VALUES (1, 'ethylrac', 'milagros'),
       (2, 'ethylrac', 'nyarlath'),
       (3, 'ethylrac', 'tamelabe'),
       (4, 'nyarlath', 'keyesdar'),
       (5, 'nyarlath', 'violette'),
       (6, 'yonnarge', 'violette')
       ;


-- Создание таблицы recommendations
CREATE TABLE recommendations (
    id serial primary KEY not null,
    peer varchar(16) not null,
    recommended_peer varchar(16) not null,
    CONSTRAINT ch_prevent_self_recommendation CHECK (peer != recommended_peer),
    CONSTRAINT fk_recommendations_peer FOREIGN KEY (peer) REFERENCES peers (nickname),
    CONSTRAINT fk_recommendations_recommended_peer FOREIGN KEY (recommended_peer) REFERENCES peers (nickname),
    CONSTRAINT unique_recommendations UNIQUE (peer, recommended_peer)
);

INSERT INTO Recommendations (id, peer, recommended_peer)
VALUES (1, 'milagros', 'yonnarge'),
       (2, 'nyarlath', 'yonnarge'),
       (3, 'tamelabe', 'yonnarge'),
       (4, 'keyesdar', 'ethylrac'),
       (5, 'violette', 'ethylrac'),
       (6, 'yonnarge', 'ethylrac')
       ;




-- Создание таблицы time_tracking
CREATE TABLE time_tracking (
    id serial primary KEY not NULL,
    peer_nickname varchar(16),
    date_track date not null,
    time_track time not null,
    state_track int not null,
    CONSTRAINT fk_time_tracking_peer_nickname FOREIGN KEY (peer_nickname) REFERENCES peers (nickname),
    CONSTRAINT ch_state_track CHECK (state_track IN (1, 2)),
    CONSTRAINT ch_date_track CHECK (date_track <= CURRENT_DATE)
);

--TRUNCATE TABLE time_tracking

INSERT INTO time_tracking (peer_nickname, date_track, time_track, state_track)
VALUES
('ethylrac', '2023-04-01', '8:00:00', 1),
('ethylrac', '2023-04-10', '9:00', 1),
('ethylrac', '2023-04-21', '10:00', 1),
('ethylrac', '2023-05-01', '11:00', 1),
('ethylrac', '2023-04-01', '12:00:00', 2),
('ethylrac', '2023-04-10', '13:00:00', 2),
('ethylrac', '2023-04-21', '14:00:00', 2),
('ethylrac', '2023-05-01', '15:00:00', 2),
('nyarlath', '2023-05-10', '12:00', 1),
('nyarlath', '2023-04-30', '14:00', 1),
('nyarlath', '2023-05-10', '17:00', 2),
('nyarlath', '2023-04-30', '19:00', 2),
('nyarlath', '2023-06-10', '12:00', 1),
('nyarlath', '2023-05-10', '14:00', 1),
('nyarlath', '2023-06-10', '17:00', 2),
('nyarlath', '2023-05-31', '19:00', 2),
('yonnarge', '2023-06-10', '12:00', 1),
('yonnarge', '2023-06-05', '14:00', 1),
('yonnarge', '2023-06-10', '17:00', 2),
('yonnarge', '2023-06-05', '19:00', 2);




CREATE OR REPLACE PROCEDURE import_csv_data(
        IN table_name VARCHAR,
        IN file_path VARCHAR,
        IN delimiter VARCHAR
    ) LANGUAGE plpgsql AS $$ BEGIN EXECUTE format(
        'COPY %I FROM %L DELIMITER %L CSV',
        table_name,
        file_path,
        delimiter
    );
END;
$$;


