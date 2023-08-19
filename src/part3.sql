-- -----------------------------------------------------------
-- 1) Написать функцию, возвращающую таблицу TransferredPoints в более человекочитаемом виде
-- Ник пира 1, ник пира 2, количество переданных пир поинтов. 
-- Количество отрицательное, если пир 2 получил от пира 1 больше поинтов.
-- -----------------------------------------------------------

DROP FUNCTION IF EXISTS get_transferred_points_readable();

CREATE OR REPLACE FUNCTION get_transferred_points_readable()
RETURNS TABLE ("Peer1" VARCHAR(16), "Peer2" VARCHAR(16), "PointsAmount" BIGINT)
LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY EXECUTE '
        SELECT p1.nickname, p2.nickname,
            CASE
                WHEN (
                    SELECT SUM(tp2.points_amount) FROM transferred_points tp2
                    WHERE tp2.checked_peer = p1.nickname AND tp2.checking_peer = p2.nickname
                ) > COUNT(points_amount) THEN -(SUM(points_amount))
                ELSE SUM(points_amount)
            END
        FROM transferred_points tp1
        JOIN peers p1 ON tp1.checking_peer = p1.nickname
        JOIN peers p2 ON tp1.checked_peer = p2.nickname
        GROUP BY 1, 2';
END;
$$;

SELECT *
FROM get_transferred_points_readable();

-- -----------------------------------------------------------
-- 2) Написать функцию, которая возвращает таблицу вида: ник пользователя, название проверенного задания, кол-во полученного XP
-- В таблицу включать только задания, успешно прошедшие проверку (определять по таблице Checks). 
-- Одна задача может быть успешно выполнена несколько раз. В таком случае в таблицу включать все успешные проверки.
-- -----------------------------------------------------------

DROP FUNCTION IF EXISTS get_user_xp();

CREATE OR REPLACE FUNCTION get_user_xp()
RETURNS TABLE ("Peer" VARCHAR(16), "Task" VARCHAR(32), "XP" BIGINT)
LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY EXECUTE '
        SELECT ch.peer, ch.task, xp.xp_amount
        FROM checks AS ch
        INNER JOIN xp ON ch.id = xp.check_id
        INNER JOIN p2p ON ch.id = p2p.check_id
        LEFT JOIN verter ON ch.id = verter.check_id
        WHERE p2p.state_check = ''success'' AND (verter.state_check = ''success'' OR verter.state_check IS NULL)';
END;
$$;

SELECT *
FROM get_user_xp();

-- Без доставерных данных. Не включает все успешные проверки. Не исключает fail
-- SELECT c.peer, c.task, x.xp_amount FROM xp x
-- JOIN checks c ON x.check_id = c.id'

-- -------------------------------------------------------------------------------------- --
-- 3) Написать функцию, определяющую пиров, которые не выходили из кампуса в течение всего дня
-- Параметры функции: день, например 12.05.2022. 
-- Функция возвращает только список пиров.
-- -------------------------------------------------------------------------------------- --

DROP FUNCTION IF EXISTS get_peers_insid_campus();

CREATE OR REPLACE FUNCTION get_peers_insid_campus(date_track date)
RETURNS TABLE ("Peer" VARCHAR(16))
LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY EXECUTE '
        SELECT peer_nickname
        FROM time_tracking tt
        WHERE tt.date_track = date_track
        GROUP BY 1
        HAVING SUM(state_track) = 3';
END;
$$;

SELECT *
FROM get_peers_insid_campus('2023-07-01');


-- -------------------------------------------------------------------------------------- --
-- 4) Посчитать изменение в количестве пир поинтов каждого пира по таблице TransferredPoints
-- Результат вывести отсортированным по изменению числа поинтов. 
-- Формат вывода: ник пира, изменение в количество пир поинтов
-- -------------------------------------------------------------------------------------- --


DROP FUNCTION IF EXISTS calculate_change_peer_points();

CREATE OR REPLACE FUNCTION calculate_change_peer_points()
RETURNS TABLE ("Peer" VARCHAR(16), "PointsChange" BIGINT)
LANGUAGE PLPGSQL AS $$
BEGIN
    RETURN QUERY EXECUTE '
        SELECT u1.cp, CAST(SUM(u1.pa) AS BIGINT) 
        FROM (
          (SELECT tp1.checking_peer AS cp, -SUM(points_amount) AS pa
          FROM transferred_points tp1
          GROUP BY 1)
          UNION
          (SELECT tp2.checked_peer AS cp, SUM(points_amount) AS pa
          FROM transferred_points tp2
          GROUP BY 1)
        ) AS u1
        GROUP BY u1.cp';
END;
$$;

SELECT *
FROM calculate_change_peer_points();


-- -- TASK 5

-- -- Для реализации данной задачи, вам потребуется использовать функцию GetPeersInsideCampus из предыдущего ответа. Эта функция возвращает список пиров, которые не выходили из кампуса в указанный день.

-- -- Ниже представлен SQL-запрос, который позволяет посчитать изменение в количестве пир поинтов для каждого пира из результата функции GetPeersInsideCampus и вывести результат отсортированным по изменению числа поинтов.

-- SELECT
--   p.peer_name AS 'Ник пира',
--   SUM(tp.points) AS 'Изменение в количестве пир поинтов'
-- FROM
--   TransferredPoints tp
-- JOIN
--   Peers p ON tp.peer_id = p.peer_id
-- WHERE
--   p.peer_name IN (
--     SELECT peer_name
--     FROM GetPeersInsideCampus('дд.мм.гггг')
--   )
-- GROUP BY
--   p.peer_name
-- ORDER BY
--   SUM(tp.points) DESC;
-- -- В этом запросе:

-- -- Выбирается ник пира (peer_name) из таблицы Peers и называется столбцом "Ник пира".
-- -- Суммируется количество переданных пир поинтов (points) из таблицы TransferredPoints и называется столбцом "Изменение в количестве пир поинтов".
-- -- Объединяются таблицы TransferredPoints и Peers по идентификатору пира (tp.peer_id = p.peer_id).
-- -- Применяется фильтр, чтобы выбрать только пиров, которые находятся в списке пиров, возвращаемом функцией GetPeersInsideCampus.
-- -- Группируются результаты по нику пира (p.peer_name).
-- -- Сортируются результаты по сумме пир поинтов в порядке убывания (SUM(tp.points) DESC).
-- -- Вы должны заменить 'дд.мм.гггг' в запросе на конкретную дату в формате 'дд.мм.гггг', чтобы получить результат для указанной даты. Результат будет в формате "ник пира, изменение в количество пир поинтов", отсортированный по изменению числа поинтов.

-- -- TASK 6

-- -- Для определения самого часто проверяемого задания за каждый день, вам потребуется использовать таблицу Checks, содержащую информацию о проверках заданий, а также столбцы check_date и task_name для определения дня и названия задания соответственно.

-- -- Ниже представлен SQL-запрос, который позволяет определить самое часто проверяемое задание за каждый день, а при одинаковом количестве проверок каких-то заданий в определенный день, выводит все эти задания.

-- SELECT
--   check_date AS 'День',
--   task_name AS 'Название задания'
-- FROM (
--   SELECT
--     check_date,
--     task_name,
--     ROW_NUMBER() OVER (PARTITION BY check_date ORDER BY COUNT(*) DESC) AS rn
--   FROM
--     Checks
--   GROUP BY
--     check_date,
--     task_name
-- ) AS subquery
-- WHERE
--   rn = 1;

-- -- Этот запрос выполняет следующие действия:

-- -- Внутренний запрос группирует проверки по дню (check_date) и названию задания (task_name), а также считает количество проверок для каждой комбинации дня и задания с помощью функции COUNT(*).
-- -- С помощью оконной функции ROW_NUMBER() назначается номер каждой строке внутреннего запроса внутри каждой группы дня (PARTITION BY check_date) в порядке убывания количества проверок (ORDER BY COUNT(*) DESC).
-- -- Внешний запрос выбирает строки, где номер равен 1 (rn = 1), что соответствует самому часто проверяемому заданию для каждого дня.
-- -- Результаты выводятся в формате "день, название задания".
-- -- Выполнив этот запрос, вы получите результат, который содержит день и название самого часто проверяемого задания за каждый день. Если есть несколько заданий с одинаковым количеством проверок в определенный день, то будут выведены все эти задания.

-- -- TASK 7

-- -- Для поиска всех пиров, выполнивших весь заданный блок задач и получения даты завершения последнего задания из этого блока, вам потребуется использовать таблицы Peers и Tasks, а также столбцы peer_name, task_name и completion_date.

-- -- Ниже представлена процедура FindPeersByBlock, которая принимает в качестве параметра название блока задач и выводит результат отсортированным по дате завершения.

-- CREATE PROCEDURE FindPeersByBlock(IN block_name VARCHAR(255))
-- BEGIN
--   SELECT
--     p.peer_name AS 'Ник пира',
--     MAX(t.completion_date) AS 'Дата завершения блока'
--   FROM
--     Peers p
--     INNER JOIN Tasks t ON p.peer_name = t.peer_name
--   WHERE
--     t.task_name LIKE CONCAT(block_name, '%')
--   GROUP BY
--     p.peer_name
--   HAVING
--     COUNT(DISTINCT t.task_name) = (
--       SELECT
--         COUNT(*)
--       FROM
--         Tasks
--       WHERE
--         task_name LIKE CONCAT(block_name, '%')
--     )
--   ORDER BY
--     MAX(t.completion_date);
-- END;
-- -- Эта процедура выполняет следующие действия:

-- -- Принимает в качестве параметра название блока задач (block_name).
-- -- Внутри процедуры выполняется SQL-запрос, который соединяет таблицы Peers и Tasks по столбцу peer_name.
-- -- В условии WHERE используется оператор LIKE для выбора заданий, чьи названия начинаются с указанного блока (block_name).
-- -- С помощью GROUP BY группируются результаты по нику пира (peer_name).
-- -- В условии HAVING проверяется, что количество уникальных заданий (DISTINCT t.task_name) для каждого пира равно общему количеству заданий в блоке. Это гарантирует, что пир выполнил все задания из блока.
-- -- Результаты сортируются по дате завершения блока (MAX(t.completion_date)), которая соответствует дате завершения последнего задания из блока.
-- -- Результаты выводятся в формате "ник пира, дата завершения блока".
-- -- Чтобы вызвать эту процедуру и получить результат, вы можете использовать следующий SQL-запрос:

-- CALL FindPeersByBlock('CPP');
-- -- Здесь 'CPP' является примером названия блока задач. Замените его на фактическое название блока, который вы хотите исследовать.

-- -- TASK 8

-- -- Для определения пира, к которому стоит идти на проверку каждому обучающемуся на основе рекомендаций друзей, вам потребуется использовать таблицы Peers и Recommendations, а также столбцы peer_name и friend_name.

-- -- Ниже представлена SQL-запрос, который выполняет данную задачу:

-- SELECT
--   r.peer_name AS 'Ник пира',
--   r.friend_name AS 'Ник найденного проверяющего'
-- FROM
--   Recommendations r
--   INNER JOIN (
--     SELECT
--       friend_name,
--       COUNT(DISTINCT peer_name) AS num_friends
--     FROM
--       Recommendations
--     GROUP BY
--       friend_name
--   ) f ON r.friend_name = f.friend_name
-- WHERE
--   f.num_friends = (
--     SELECT
--       MAX(num_friends)
--     FROM
--       (
--         SELECT
--           friend_name,
--           COUNT(DISTINCT peer_name) AS num_friends
--         FROM
--           Recommendations
--         GROUP BY
--           friend_name
--       ) t
--   );
-- -- Этот запрос выполняет следующие действия:

-- -- Внутри запроса выполняется подзапрос, который группирует рекомендации по friend_name и подсчитывает количество уникальных peer_name для каждого друга.
-- -- Затем основной запрос соединяет таблицу Recommendations с подзапросом по столбцу friend_name.
-- -- В условии WHERE выбираются только те рекомендации, где количество друзей (num_friends) равно максимальному количеству друзей, указанному в подзапросе.
-- -- Результаты выводятся в формате "ник пира, ник найденного проверяющего".
-- -- Вы можете выполнить этот запрос и получить результат в желаемом формате.

-- -- Обратите внимание, что этот запрос предполагает, что таблица Recommendations содержит информацию о рекомендациях друзей для каждого пира. Если у вас есть другая структура данных или требования, пожалуйста, уточните и я смогу предоставить более точное решение.

-- -- TASK 9

-- -- Для определения процента пиров, которые приступили только к блоку 1, только к блоку 2, приступили к обоим блокам или не приступили ни к одному, вы можете использовать таблицу Checks и параметры block1_name и block2_name в процедуре.

-- -- Ниже представлена процедура CalculatePeerPercentages, которая принимает в качестве параметров названия блоков (block1_name и block2_name) и выводит проценты в формате, указанном вами:

-- CREATE PROCEDURE CalculatePeerPercentages(IN block1_name VARCHAR(255), IN block2_name VARCHAR(255))
-- BEGIN
--   DECLARE total_peers INT;
--   DECLARE block1_peers INT;
--   DECLARE block2_peers INT;
--   DECLARE both_blocks_peers INT;
--   DECLARE no_blocks_peers INT;

--   SET total_peers = (SELECT COUNT(DISTINCT peer_name) FROM Checks);
--   SET block1_peers = (
--     SELECT COUNT(DISTINCT peer_name)
--     FROM Checks
--     WHERE task_name LIKE CONCAT(block1_name, '%')
--   );
--   SET block2_peers = (
--     SELECT COUNT(DISTINCT peer_name)
--     FROM Checks
--     WHERE task_name LIKE CONCAT(block2_name, '%')
--   );
--   SET both_blocks_peers = (
--     SELECT COUNT(DISTINCT peer_name)
--     FROM Checks
--     WHERE task_name LIKE CONCAT(block1_name, '%')
--       AND peer_name IN (
--         SELECT peer_name
--         FROM Checks
--         WHERE task_name LIKE CONCAT(block2_name, '%')
--       )
--   );
--   SET no_blocks_peers = total_peers - block1_peers - block2_peers + both_blocks_peers;

--   SELECT
--     CONCAT(ROUND((block1_peers / total_peers) * 100, 2), '%') AS 'Процент приступивших только к первому блоку',
--     CONCAT(ROUND((block2_peers / total_peers) * 100, 2), '%') AS 'Процент приступивших только ко второму блоку',
--     CONCAT(ROUND((both_blocks_peers / total_peers) * 100, 2), '%') AS 'Процент приступивших к обоим',
--     CONCAT(ROUND((no_blocks_peers / total_peers) * 100, 2), '%') AS 'Процент не приступивших ни к одному';
-- END;
-- -- Эта процедура выполняет следующие действия:

-- -- Объявляет переменные для общего числа пиров (total_peers), пиров, приступивших только к блоку 1 (block1_peers), пиров, приступивших только к блоку 2 (block2_peers), пиров, приступивших к обоим блокам (both_blocks_peers) и пиров, не приступивших ни к одному блоку (no_blocks_peers).
-- -- Внутри процедуры выполняются несколько SQL-запросов, которые подсчитывают количество пиров для каждой категории.
-- -- Результаты выводятся в формате процентов с использованием функции CONCAT и оператора ROUND для округления до двух знаков после запятой.
-- -- Чтобы вызвать эту процедуру и получить результат, вы можете использовать следующий SQL-запрос:

-- CALL CalculatePeerPercentages('SQL', 'A');
-- -- Здесь 'SQL' и 'A' являются примерами названий блоков. Замените их на фактические названия блоков, которые вы хотите исследовать.

-- -- TASK 10

-- -- Для определения процента пиров, которые успешно проходили проверку в свой день рождения, и процента пиров, которые проваливали проверку в свой день рождения, вы можете использовать таблицу Checks и информацию о днях рождения пиров.

-- -- Ниже представлена процедура CalculateBirthdayCheckPercentages, которая выводит проценты успешных и проваленных проверок в день рождения пиров:

-- CREATE PROCEDURE CalculateBirthdayCheckPercentages()
-- BEGIN
--   DECLARE total_peers INT;
--   DECLARE birthday_pass_percent DECIMAL(5,2);
--   DECLARE birthday_fail_percent DECIMAL(5,2);

--   SET total_peers = (SELECT COUNT(DISTINCT peer_name) FROM Checks);
--   SET birthday_pass_percent = (
--     SELECT ROUND((COUNT(DISTINCT peer_name) / total_peers) * 100, 2)
--     FROM Checks
--     WHERE DATE_FORMAT(birthday, '%m-%d') = DATE_FORMAT(CURDATE(), '%m-%d')
--       AND status = 'pass'
--   );
--   SET birthday_fail_percent = (
--     SELECT ROUND((COUNT(DISTINCT peer_name) / total_peers) * 100, 2)
--     FROM Checks
--     WHERE DATE_FORMAT(birthday, '%m-%d') = DATE_FORMAT(CURDATE(), '%m-%d')
--       AND status = 'fail'
--   );

--   SELECT
--     CONCAT(birthday_pass_percent, '%') AS 'Процент пиров, успешно прошедших проверку в день рождения',
--     CONCAT(birthday_fail_percent, '%') AS 'Процент пиров, проваливших проверку в день рождения';
-- END;
-- -- Эта процедура выполняет следующие действия:

-- -- Объявляет переменные для общего числа пиров (total_peers), процента пиров, успешно прошедших проверку в день рождения (birthday_pass_percent) и процента пиров, проваливших проверку в день рождения (birthday_fail_percent).
-- -- Внутри процедуры выполняются два SQL-запроса. Первый запрос подсчитывает количество пиров, успешно прошедших проверку в свой день рождения, а второй запрос подсчитывает количество пиров, проваливших проверку в свой день рождения.
-- -- Результаты выводятся в формате процентов с использованием функции CONCAT и оператора ROUND для округления до двух знаков после запятой.
-- -- Чтобы вызвать эту процедуру и получить результат, вы можете использовать следующий SQL-запрос:

-- CALL CalculateBirthdayCheckPercentages();
-- -- Процент пиров, успешно прошедших проверку в свой день рождения, и процент пиров, проваливших проверку в свой день рождения, будут выведены в результатах запроса.

-- -- TASK 11

-- Для определения пиров, которые сдали задания 1 и 2, но не сдали задание 3, можно использовать следующую процедуру:

-- CREATE PROCEDURE FindPeersWithSpecificTaskStatus(
--   IN task1 VARCHAR(255),
--   IN task2 VARCHAR(255),
--   IN task3 VARCHAR(255)
-- )
-- BEGIN
--   SELECT DISTINCT peer_name
--   FROM Tasks
--   WHERE task_name = task1 AND status = 'pass' AND peer_name NOT IN (
--     SELECT peer_name
--     FROM Tasks
--     WHERE task_name = task3 AND status = 'pass'
--   )
--   AND peer_name IN (
--     SELECT peer_name
--     FROM Tasks
--     WHERE task_name = task2 AND status = 'pass'
--   );
-- END;

-- -- Эта процедура принимает в качестве параметров названия заданий 1, 2 и 3 (task1, task2, task3). В результате выполнения процедуры будет выведен список пиров, которые сдали задания 1 и 2, но не сдали задание 3.

-- -- Чтобы вызвать эту процедуру и получить результат, вы можете использовать следующий SQL-запрос:

-- CALL FindPeersWithSpecificTaskStatus('задание 1', 'задание 2', 'задание 3');

-- -- Замените 'задание 1', 'задание 2' и 'задание 3' на фактические названия заданий, которые вы хотите использовать в поиске. Результатом будет список пиров, удовлетворяющих указанным условиям.

-- -- TASK 12

-- -- Для вывода количества предшествующих задач для каждой задачи, можно использовать рекурсивное обобщенное табличное выражение (CTE) в сочетании с функцией COUNT() для подсчета количества строк в каждой группе.

-- -- Вот пример SQL-запроса, который решает данную задачу:

-- WITH RECURSIVE TaskHierarchy AS (
--   SELECT task_name, prerequisite_task
--   FROM Tasks
--   WHERE prerequisite_task IS NULL -- Начальное условие: задача без предшествующих задач

--   UNION ALL

--   SELECT t.task_name, t.prerequisite_task
--   FROM Tasks t
--   INNER JOIN TaskHierarchy th ON t.prerequisite_task = th.task_name
-- )
-- SELECT task_name, COUNT(*) AS preceding_tasks
-- FROM TaskHierarchy
-- GROUP BY task_name;

-- -- В этом запросе мы создаем рекурсивное обобщенное табличное выражение TaskHierarchy, которое начинается с задач, у которых prerequisite_task равно NULL (задачи без предшествующих задач). Затем мы объединяем результаты сами с собой, чтобы получить все предшествующие задачи для каждой задачи.

-- -- Затем, используя CTE TaskHierarchy, мы выполняем основной запрос, который выбирает task_name и применяет функцию COUNT(*) для подсчета количества строк в каждой группе задач. Результат группируется по task_name.

-- -- Выполнив этот запрос, вы получите результат в формате: название задачи и количество предшествующих задач для каждой задачи.

-- -- TASK 13

-- -- Для нахождения "удачных" дней, в которых есть хотя бы N идущих подряд успешных проверок, можно использовать следующую процедуру:

-- CREATE PROCEDURE FindLuckyDays(
--   IN N INT
-- )
-- BEGIN
--   WITH CTE AS (
--     SELECT DATE(p2p_start_time) AS check_date,
--            ROW_NUMBER() OVER (PARTITION BY DATE(p2p_start_time) ORDER BY p2p_start_time) AS row_num,
--            xp
--     FROM Checks
--     WHERE status = 'pass' AND xp >= 0.8 * (SELECT MAX(xp) FROM Checks)
--   ),
--   LuckyDays AS (
--     SELECT check_date, row_num, xp,
--            ROW_NUMBER() OVER (PARTITION BY check_date - INTERVAL (row_num - 1) DAY ORDER BY row_num) AS lucky_row_num
--     FROM CTE
--   )
--   SELECT DISTINCT check_date
--   FROM LuckyDays
--   WHERE lucky_row_num >= N;
-- END;
-- -- В этой процедуре параметр N указывает количество идущих подряд успешных проверок, которые должны присутствовать в "удачном" дне.

-- -- Процедура использует рекурсивное обобщенное табличное выражение (CTE) для нумерации успешных проверок по дням и добавляет столбец xp, содержащий количество опыта для каждой проверки. Затем она создает CTE LuckyDays, который присваивает каждой проверке номер строки в пределах каждого дня и номер строки в пределах дня с учетом идущих подряд успешных проверок.

-- -- В итоговом запросе выбираются уникальные даты (check_date) из CTE LuckyDays, где номер строки lucky_row_num больше или равен N. Это позволяет найти "удачные" дни, в которых есть хотя бы N идущих подряд успешных проверок.

-- -- Чтобы вызвать эту процедуру и получить список "удачных" дней, вы можете использовать следующий SQL-запрос:

-- CALL FindLuckyDays(3);
-- -- Замените 3 на желаемое значение параметра N. Результатом будет список дней, в которых есть хотя бы 3 идущих подряд успешных проверки.

-- -- TASK 14

-- -- Для определения пира с наибольшим количеством XP можно использовать следующий SQL-запрос:

-- SELECT nickname, xp
-- FROM P2P
-- ORDER BY xp DESC
-- LIMIT 1;

-- -- Этот запрос выбирает ник пира (nickname) и количество XP (xp) из таблицы P2P и сортирует результаты по убыванию количества XP. Затем с помощью LIMIT 1 выбирается только первая запись, которая будет иметь наибольшее количество XP.

-- -- Результатом запроса будет ник пира с наибольшим количеством XP и само количество XP.

-- -- TASK 15

-- -- Для определения пиров, которые приходили раньше заданного времени не менее N раз за всё время, можно использовать следующую процедуру:

-- CREATE PROCEDURE FindEarlyPeers(
--   IN target_time TIME,
--   IN N INT
-- )
-- BEGIN
--   SELECT DISTINCT peer
--   FROM P2P
--   WHERE p2p_start_time < target_time
--   GROUP BY peer
--   HAVING COUNT(*) >= N;
-- END;

-- -- В этой процедуре параметр target_time указывает заданное время, а параметр N указывает минимальное количество раз, которое пир должен приходить раньше этого времени.

-- -- Процедура выполняет запрос, который выбирает уникальные пиры (peer) из таблицы P2P, у которых время начала (p2p_start_time) меньше заданного времени (target_time). Затем результаты группируются по пирам и фильтруются с помощью условия HAVING COUNT(*) >= N, чтобы выбрать только те пиры, которые приходили раньше заданного времени не менее N раз.

-- -- Чтобы вызвать эту процедуру и получить список пиров, которые приходили раньше заданного времени не менее N раз, вы можете использовать следующий SQL-запрос:

-- CALL FindEarlyPeers('12:00:00', 3);
-- -- Здесь '12:00:00' - это пример заданного времени, а 3 - примерное значение параметра N. Замените эти значения на свои собственные. Результатом будет список пиров, которые приходили раньше заданного времени не менее 3 раз.

-- -- TASK 16

-- -- Для определения пиров, которые выходили из кампуса больше M раз за последние N дней, можно использовать следующую процедуру:

-- CREATE PROCEDURE FindFrequentCampusExitPeers(
--   IN N INT,
--   IN M INT
-- )
-- BEGIN
--   DECLARE start_date DATE;
--   DECLARE end_date DATE;
  
--   SET end_date = CURDATE();
--   SET start_date = DATE_SUB(end_date, INTERVAL N DAY);
  
--   SELECT DISTINCT peer
--   FROM P2P
--   WHERE p2p_start_time >= start_date
--     AND p2p_start_time <= end_date
--     AND p2p_exit_campus = 1
--   GROUP BY peer
--   HAVING COUNT(*) > M;
-- END;
-- -- В этой процедуре параметр N указывает количество дней, а параметр M указывает минимальное количество раз, которое пир должен выходить из кампуса за указанный период.

-- -- Процедура сначала определяет начальную и конечную даты (start_date и end_date) на основе текущей даты (CURDATE()) и значения параметра N с помощью функции DATE_SUB.

-- -- Затем процедура выполняет запрос, который выбирает уникальные пиры (peer) из таблицы P2P, у которых время начала (p2p_start_time) находится в указанном периоде (start_date - end_date) и признак выхода из кампуса (p2p_exit_campus) равен 1 (вышел из кампуса). Затем результаты группируются по пирам и фильтруются с помощью условия HAVING COUNT(*) > M, чтобы выбрать только те пиры, которые выходили из кампуса больше M раз за указанный период.

-- -- Чтобы вызвать эту процедуру и получить список пиров, которые выходили из кампуса больше M раз за последние N дней, вы можете использовать следующий SQL-запрос:

-- CALL FindFrequentCampusExitPeers(7, 5);
-- -- Здесь 7 - это примерное значение параметра N (количество дней), а 5 - примерное значение параметра M (количество раз). Замените эти значения на свои собственные. Результатом будет список пиров, которые выходили из кампуса больше 5 раз за последние 7 дней.

-- -- TASK 17

-- -- Для решения данной задачи, можно использовать следующий SQL-запрос:

-- SELECT
--   DATE_FORMAT(p2p_start_time, '%Y-%m') AS month,
--   COUNT(*) AS total_entries,
--   SUM(CASE WHEN TIME(p2p_start_time) < '12:00:00' THEN 1 ELSE 0 END) AS early_entries,
--   (SUM(CASE WHEN TIME(p2p_start_time) < '12:00:00' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS early_entry_percentage
-- FROM P2P
-- WHERE MONTH(p2p_start_time) = MONTH(date_of_birth)
-- GROUP BY month;
-- -- В этом запросе используется функция DATE_FORMAT для извлечения месяца из столбца p2p_start_time в формате 'YYYY-MM'. Затем с помощью условной конструкции CASE подсчитывается общее количество входов (total_entries) и количество ранних входов (early_entries), где время начала (p2p_start_time) меньше '12:00:00'. Затем вычисляется процент ранних входов (early_entry_percentage) относительно общего числа входов.

-- -- Запрос также включает условие WHERE MONTH(p2p_start_time) = MONTH(date_of_birth), чтобы учитывать только пиры, родившиеся в том же месяце, что и время начала.

-- -- Результатом запроса будет список месяцев (month), общее количество входов (total_entries), количество ранних входов (early_entries) и процент ранних входов (early_entry_percentage) для каждого месяца.

-- -- Обратите внимание, что в запросе предполагается, что у вас есть столбец date_of_birth в таблице P2P, содержащий дату рождения пира. Если у вас другое название столбца или таблицы, пожалуйста, замените его в запросе соответствующим образом.