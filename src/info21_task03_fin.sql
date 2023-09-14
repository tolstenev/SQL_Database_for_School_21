/*
task 7
Найти всех пиров, выполнивших весь заданный блок задач и дату завершения последнего задания
Параметры процедуры: название блока, например "CPP". 
Результат вывести отсортированным по дате завершения. 
Формат вывода: ник пира, дата завершения блока (т.е. последнего выполненного задания из этого блока)
*/

DROP PROCEDURE finished_date(IN block varchar, IN ref refcursor)

CREATE OR REPLACE PROCEDURE finished_date(IN block varchar, IN ref refcursor)
AS $$
BEGIN 
	OPEN REF FOR 
	
	WITH 
	tmp AS (	
		SELECT 		
		peer,
		count(task) AS cnt,
		max(date_check) AS date
		FROM checks c 
		JOIN p2p pp ON c.id = pp.check_id
		LEFT JOIN verter v ON c.id = v.check_id
		WHERE pp.state_check = 'Success' 
						AND (v.state_check  = 'Success' OR v.state_check IS NULL)
						AND task SIMILAR TO concat(block, '[0-9]%')
		GROUP BY peer
		)
	SELECT 
		peer, 
		date
	FROM tmp
	WHERE cnt = (
			SELECT count(title) AS cnt
			FROM tasks
			WHERE title SIMILAR TO concat(block, '[0-9]%')
			);

END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL finished_date('C', 'ref');
FETCH ALL IN "ref";
END;



/*
8) Определить, к какому пиру стоит идти на проверку каждому обучающемуся
Определять нужно исходя из рекомендаций друзей пира, т.е. нужно найти пира, 
проверяться у которого рекомендует наибольшее число друзей. 
Формат вывода: ник пира, ник найденного проверяющего
 */

CREATE OR REPLACE PROCEDURE recommended_peer(IN ref refcursor)
AS $$
BEGIN 
	OPEN REF FOR 
	WITH a AS (
		
			SELECT 
				nickname,
				(CASE WHEN nickname = friends.peer1 
					THEN peer2 
					ELSE peer1 
				END) AS friend
			FROM peers
			JOIN friends ON peers.nickname = friends.peer1 
								OR peers.nickname = friends.peer2
			ORDER BY 1
				
		),
		b AS (
			SELECT nickname, recommended_peer, count(recommended_peer) AS count
			FROM a JOIN recommendations r ON a.friend = r.peer
			GROUP BY nickname, recommended_peer
		),
		c AS (
			SELECT 
				nickname,
				max(count) AS count
			FROM b
			GROUP BY nickname
		)
	SELECT b.nickname, recommended_peer
	FROM b
	JOIN c ON c.count = b.count AND b.nickname = c.nickname;

END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL recommended_peer('ref');
FETCH ALL IN "ref";
END;

/*
9. Посчитать доли пиров, которые:
- Приступили только к блоку 1
- Приступили только к блоку 2
- Приступили к обоим
- Не приступили ни к одному

Пир считается приступившим к блоку, если он проходил 
хоть одну проверку любого задания из этого блока (по таблице Checks)
 */

CREATE OR REPLACE PROCEDURE started_block_2(IN ref refcursor,
											IN block1 varchar ,
											IN block2 varchar
											)
AS $$

BEGIN 
	OPEN REF FOR 	

	WITH 
	started_b1 AS (
		SELECT  DISTINCT peer
		FROM  checks
		WHERE task SIMILAR TO concat(block1, '[0-9]%')),
	started_b2 AS (
		SELECT  DISTINCT peer
		FROM  checks
		WHERE task SIMILAR TO concat(block2, '[0-9]%')),
	only_b1 AS (
		SELECT  *
		FROM  started_b1
		EXCEPT 
		SELECT  *
		FROM started_b2),
	only_b2 AS (
		SELECT  *
		FROM  started_b2
		EXCEPT 
		SELECT  *
		FROM started_b1),
	b1_b2 AS (
		SELECT  *
		FROM  started_b1
		INTERSECT  
		SELECT  *
		FROM started_b2),
	b_nothing AS (
		SELECT p.nickname
		FROM peers p 
		EXCEPT
		SELECT  peer
		FROM only_b1
		EXCEPT 
		SELECT  peer
		FROM only_b2
		EXCEPT 
		SELECT  peer
		FROM b1_b2
	)
	SELECT 
		(SELECT count(only_b1.peer) FROM  only_b1) *100  / (SELECT count(nickname) FROM peers) AS StartedBlock1,
		(SELECT count(only_b2.peer) FROM  only_b2) * 100/ (SELECT count(nickname) FROM peers) AS StartedBlock2,
		(SELECT count(b1_b2.peer) FROM  b1_b2) * 100/ (SELECT count(nickname) FROM peers) AS StartedBothBlocks,
		(SELECT count(b_nothing.nickname) FROM  b_nothing) * 100 / (SELECT count(nickname) FROM peers) AS DidntStartAnyBlock;

END;
$$ LANGUAGE plpgsql;


BEGIN;
CALL started_block_2('ref', 'C', 'DO' );
FETCH ALL IN "ref";
END;


--10. Определить процент пиров, которые когда-либо успешно проходили проверку в свой день рождения

CREATE OR REPLACE PROCEDURE birthday_check (IN ref refcursor)																					
AS $$
DECLARE peers_count int := (SELECT count(nickname) FROM peers);
BEGIN 
	OPEN REF FOR 	

	WITH birth_suc AS (
SELECT 
	DISTINCT p.nickname
FROM peers p 
JOIN checks c ON p.nickname = c.peer 
JOIN p2p pp ON p.nickname = pp.checking_peer AND state_check = 'Success'
WHERE 
	DATE_PART('month', date_check::DATE) = DATE_PART('month', birthday::DATE)
  	AND DATE_PART('day', date_check::DATE) = DATE_PART('day', birthday::DATE)
),
birth_fal AS (
SELECT 
	DISTINCT p.nickname
FROM peers p 
JOIN checks c ON p.nickname = c.peer 
JOIN p2p pp ON p.nickname = pp.checking_peer AND state_check = 'Failure'
WHERE 
	DATE_PART('month', date_check::DATE) = DATE_PART('month', birthday::DATE)
  	AND DATE_PART('day', date_check::DATE) = DATE_PART('day', birthday::DATE)
)
SELECT 
	((SELECT count(nickname) FROM  birth_suc) * 100 / peers_count) AS "SuccessfulChecks",
	((SELECT count(nickname) FROM  birth_fal) * 100 / peers_count) AS "UnsuccessfulChecks"
;

END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL birthday_check('ref');
FETCH ALL IN "ref";
END;


--11. Определить всех пиров, которые сдали заданные задания 1 и 2, но не сдали задание 3

CREATE OR REPLACE PROCEDURE complete_task12_not_3(
        IN cursor REFCURSOR,
        IN task_1 VARCHAR(50),
        IN task_2 VARCHAR(50),
        IN task_3 VARCHAR(50)
    ) AS $$ BEGIN OPEN cursor FOR 
    
    WITH success_tasks AS(
        SELECT c.peer
        FROM xp
            LEFT JOIN checks c ON xp.check_id = c.id
        WHERE c.task = task_1
            OR c.task = task_2
        GROUP BY c.peer
        HAVING COUNT(c.task) = 2
    ),
    done_task_3 AS(
        SELECT DISTINCT c.peer
        FROM xp
            LEFT JOIN checks c ON xp.check_id = c.id
        WHERE c.task = task_3
    )
SELECT peer
FROM success_tasks
EXCEPT
SELECT peer
FROM done_task_3;
END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL complete_task12_not_3('REFCURSOR', 'C2_SimpleBashUtils', 'C3_s21_string+', 'CPP1_s21_matrix+');
FETCH ALL IN "REFCURSOR";
END;

/*
12. Используя рекурсивное обобщенное табличное выражение, 
для каждой задачи вывести кол-во предшествующих ей задач
 */


CREATE OR REPLACE PROCEDURE cnt_previous_tasks(IN cursor REFCURSOR)
    AS $$ 
    BEGIN 
	    OPEN cursor FOR 
   
        WITH RECURSIVE r AS 
        	(SELECT (CASE WHEN tasks.parent_task IS NULL THEN 0
                     ELSE 1
                     END) AS count, 
                     tasks.title, 
                     tasks.parent_task, 
                     tasks.parent_task
            FROM tasks
            UNION ALL
            SELECT (CASE WHEN tasks.parent_task IS NOT NULL THEN count + 1
                    ELSE count
                    END) AS count,  
                    tasks.title, tasks.parent_task, r.title
                    FROM tasks
                    CROSS JOIN r
                    WHERE r.title LIKE tasks.parent_task)
          SELECT title, MAX(count)
          FROM r
          GROUP BY title
         ORDER BY MAX(count)
        ;
    END;
$$ LANGUAGE plpgsql;


BEGIN;
CALL cnt_previous_tasks('REFCURSOR');
FETCH ALL IN "REFCURSOR";
END;

/*
13. Найти "удачные" для проверок дни. День считается "удачным", если в нем есть хотя бы N идущих подряд успешных проверки
 */

CREATE OR REPLACE PROCEDURE cnt_suc_days(IN cursor REFCURSOR,IN N int )
    AS $$ 
    BEGIN 
	    OPEN cursor FOR 
	    
		WITH tmp AS (
		
			SELECT date_check
			FROM  checks c
			JOIN p2p p ON c.id = p.check_id AND state_check = 'Success'
			JOIN xp using(check_id)
			GROUP BY date_check
			HAVING count(date_check) = 2
			)
			
		SELECT 
			count(DISTINCT date_check)
		FROM  checks c
		JOIN p2p p ON c.id = p.check_id AND state_check = 'Success'
		JOIN xp using(check_id)
		JOIN tasks t ON t.title = c.task
		WHERE date_check = (SELECT date_check FROM tmp ) AND 
				xp_amount * 100 / max_xp >= 80;

    END;
$$ LANGUAGE plpgsql;


BEGIN;
CALL cnt_suc_days('REFCURSOR', 2);
FETCH ALL IN "REFCURSOR";
END;	


/*
14. Определить пира с наибольшим количеством XP
*/

CREATE OR REPLACE PROCEDURE max_xp (IN ref refcursor)																					
AS $$
BEGIN 
	OPEN REF FOR 	
       
    SELECT 
       checks.peer AS "Peer", 
       SUM(xp_amount) AS "XP"
    FROM xp
    JOIN checks ON xp.check_id = checks.id
    GROUP BY checks.peer
    ORDER BY SUM(xp_amount) DESC 
    LIMIT 1;

END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL max_xp('ref');
FETCH ALL IN "ref";
END;


/*
15. Определить пиров, приходивших раньше заданного времени не менее N раз за всё время
*/

CREATE OR REPLACE PROCEDURE early_visit (IN ref refcursor,
										IN visit_time time ,
										IN cnt int
										)
AS $$

BEGIN 
	OPEN REF FOR 	

	WITH tmp AS (
		SELECT 
			DISTINCT peer_nickname, 
			count(peer_nickname), 
			time_track 
		FROM time_tracking
		WHERE time_track  < visit_time AND state_track = 1
		GROUP BY peer_nickname, time_track)
	SELECT peer_nickname
	FROM tmp
	WHERE count >= cnt;
	
END;
$$ LANGUAGE plpgsql;


BEGIN;
CALL early_visit('ref', '10:00:00', 1 );
FETCH ALL IN "ref";
END;


/*
16. Определить пиров, выходивших за последние N (60) дней из кампуса больше M раз (1)
*/

CREATE OR REPLACE PROCEDURE peers_delay (IN ref refcursor,
										IN cnt_days int ,
										IN cnt_visits int
										)
AS $$

BEGIN 
	OPEN REF FOR 	

	WITH a AS (	
		SELECT 
			peer_nickname,
			count(date_track) AS cnt 
		FROM time_tracking
		WHERE state_track = 2
		GROUP BY peer_nickname),
		b AS (
		SELECT *
		FROM a 
		WHERE cnt > cnt_visits),	
		c AS (
		SELECT 
			peer_nickname, 
			date_track, 
			CURRENT_DATE - date_track AS days_from_now
		FROM time_tracking
		WHERE state_track = 2
		GROUP BY peer_nickname, date_track)
	SELECT b.peer_nickname, days_from_now
	FROM b
	JOIN c ON b.peer_nickname = c.peer_nickname AND 
			days_from_now < cnt_days;
	
	
	
END;
$$ LANGUAGE plpgsql;


BEGIN;
CALL peers_delay('ref', 450, 1 );
FETCH ALL IN "ref";
END;

/*
peer_nickname|cnt_days|
-------------+--------+
tamelabe     |     442|
*/

--17) Определить для каждого месяца процент ранних входов

--Для каждого месяца посчитать, сколько раз люди, родившиеся в этот месяц, 
--приходили в кампус за всё время 
--(будем называть это общим числом входов).


CREATE OR REPLACE PROCEDURE EarlyEntries (IN ref refcursor)																					
AS $$
BEGIN 
	OPEN REF FOR 	
-- кол-во приходов всего
	WITH a AS (
		SELECT 
			peer_nickname,
			EXTRACT(MONTH FROM date_track) AS visit_month,
			EXTRACT(MONTH FROM birthday) AS bd_month
		FROM time_tracking tt
		JOIN peers p ON tt.peer_nickname = p.nickname 
		WHERE state_track = 1),
	b as (
		SELECT 
			visit_month,
			count(peer_nickname) AS total_visits
		FROM a
		WHERE visit_month = bd_month
		GROUP BY visit_month, bd_month),
	-- ранние приходы
	c AS  (
		SELECT 
			peer_nickname,
			EXTRACT(MONTH FROM date_track) AS visit_month,
			EXTRACT(MONTH FROM birthday) AS bd_month
		FROM time_tracking tt
		JOIN peers p ON tt.peer_nickname = p.nickname 
		WHERE state_track = 1 AND time_track < '12:00:00'),
	d AS (
		SELECT 
			visit_month,
			count(peer_nickname) AS early_visits
		FROM c
		WHERE visit_month = bd_month 
		GROUP BY visit_month, bd_month)
	-- собрала до кучи
	SELECT (CASE WHEN b.visit_month = 1 THEN 'January'
	                WHEN b.visit_month = 2 THEN 'February'
	                WHEN b.visit_month = 3 THEN 'March'
	                WHEN b.visit_month = 4 THEN 'April'
	                WHEN b.visit_month = 5 THEN 'May'
	                WHEN b.visit_month = 6 THEN 'June'
	                WHEN b.visit_month = 7 THEN 'July'
	                WHEN b.visit_month = 8 THEN 'August'
	                WHEN b.visit_month = 9 THEN 'September'
	                WHEN b.visit_month = 10 THEN 'October'
	                WHEN b.visit_month = 11 THEN 'November' 
	                ELSE 'December' END) AS "Month", 
		early_visits * 100 / total_visits AS "EarlyEntries"
	FROM b
	JOIN d ON b.visit_month = d.visit_month;

END;
$$ LANGUAGE plpgsql;

BEGIN;
CALL EarlyEntries('ref');
FETCH ALL IN "ref";
END;


