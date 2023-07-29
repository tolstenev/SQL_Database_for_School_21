-- Ниже представлен скрипт part2.sql, который содержит процедуру AddP2PCheck для добавления P2P проверки, а также тестовые запросы/вызовы для каждого пункта.

-- Создание процедуры добавления P2P проверки
DELIMITER //

CREATE PROCEDURE AddP2PCheck(
  IN peerToCheck VARCHAR(255),
  IN peerToVerify VARCHAR(255),
  IN taskName VARCHAR(255),
  IN p2pStatus VARCHAR(255),
  IN checkTime DATETIME
)
BEGIN
  DECLARE newCheckID INT;

  -- Добавление записи в таблицу Checks
  IF p2pStatus = 'начало' THEN
    INSERT INTO Checks (task_name, check_status, check_date)
    VALUES (taskName, p2pStatus, CURDATE());
    SET newCheckID = LAST_INSERT_ID();
  ELSE
    SELECT check_id INTO newCheckID
    FROM Checks
    WHERE task_name = taskName AND check_status = 'незавершенный P2P'
    LIMIT 1;
  END IF;

  -- Добавление записи в таблицу P2P
  INSERT INTO P2P (peer_to_check, peer_to_verify, check_id, check_time)
  VALUES (peerToCheck, peerToVerify, newCheckID, checkTime);
END //

DELIMITER ;

-- Тестовые запросы/вызовы для каждого пункта

-- Добавление P2P проверки со статусом "начало"
CALL AddP2PCheck('проверяемый1', 'проверяющий1', 'Задание1', 'начало', NOW());

-- Добавление P2P проверки со статусом "незавершенный P2P"
CALL AddP2PCheck('проверяемый2', 'проверяющий2', 'Задание2', 'незавершенный P2P', NOW());

-- В этом скрипте создана процедура AddP2PCheck, которая принимает параметры peerToCheck (ник проверяемого), peerToVerify (ник проверяющего), taskName (название задания), p2pStatus (статус P2P проверки) и checkTime (время проверки). Внутри процедуры выполняются следующие действия:

-- Если задан статус "начало", добавляется запись в таблицу Checks с указанием текущей даты (CURDATE()) в качестве даты проверки. Полученный check_id сохраняется в переменную newCheckID.
-- Если задан статус "начало", в таблицу P2P добавляется запись с указанными параметрами, а в поле check_id записывается значение newCheckID. Если задан статус "незавершенный P2P", в таблицу P2P добавляется запись с указанными параметрами, а в поле check_id записывается значение check_id из записи с соответствующим заданием и статусом "незавершенный P2P" в таблице Checks.
-- После определения процедуры AddP2PCheck следуют тестовые запросы/вызовы для каждого пункта:

-- Добавление P2P проверки со статусом "начало" для проверяемого пира "проверяемый1", проверяющего пира "проверяющий1" и задания с названием "Задание1". Время проверки устанавливается на текущий момент (NOW()).
-- Добавление P2P проверки со статусом "незавершенный P2P" для проверяемого пира "проверяемый2", проверяющего пира "проверяющий2" и задания с названием "Задание2". Время проверки устанавливается на текущий момент (NOW()).
-- Вы можете изменить параметры вызовов процедуры AddP2PCheck в тестовых запросах, чтобы адаптировать их под свои данные.


-- Ниже представлен скрипт part2.sql, который содержит процедуру AddVerterCheck для добавления проверки Verter'ом, а также тестовые запросы/вызовы для каждого пункта.

-- Создание процедуры добавления проверки Verter'ом
DELIMITER //

CREATE PROCEDURE AddVerterCheck(
  IN peerToCheck VARCHAR(255),
  IN taskName VARCHAR(255),
  IN verterStatus VARCHAR(255),
  IN checkTime DATETIME
)
BEGIN
  DECLARE latestSuccessfulP2PCheckID INT;

  -- Получение ID последней успешной P2P проверки для задания
  SELECT MAX(check_id) INTO latestSuccessfulP2PCheckID
  FROM Checks
  WHERE task_name = taskName AND check_status = 'успешный P2P';

  -- Добавление записи в таблицу Verter
  INSERT INTO Verter (peer_to_check, task_name, p2p_check_id, verter_status, check_time)
  VALUES (peerToCheck, taskName, latestSuccessfulP2PCheckID, verterStatus, checkTime);
END //

DELIMITER ;

-- Тестовые запросы/вызовы для каждого пункта

-- Добавление проверки Verter'ом
CALL AddVerterCheck('проверяемый1', 'Задание1', 'успешная проверка', NOW());

-- В этом скрипте создана процедура AddVerterCheck, которая принимает параметры peerToCheck (ник проверяемого), taskName (название задания), verterStatus (статус проверки Verter'ом) и checkTime (время проверки). Внутри процедуры выполняются следующие действия:

-- Выполняется запрос для получения ID последней успешной P2P проверки для задания. В переменную latestSuccessfulP2PCheckID сохраняется результат этого запроса.
-- В таблицу Verter добавляется запись с указанными параметрами, а в поле p2p_check_id записывается значение latestSuccessfulP2PCheckID.
-- После определения процедуры AddVerterCheck следует тестовый запрос/вызов:

-- Добавление проверки Verter'ом для проверяемого пира "проверяемый1", задания с названием "Задание1" и статуса "успешная проверка". Время проверки устанавливается на текущий момент (NOW()).
-- Вы можете изменить параметры вызова процедуры AddVerterCheck в тестовом запросе, чтобы адаптировать их под свои данные.

-- Ниже представлен скрипт part3.sql, который содержит триггер UpdateTransferredPoints для изменения записи в таблице TransferredPoints после добавления записи со статусом "начало" в таблицу P2P.

-- Создание триггера для изменения записи в таблице TransferredPoints
DELIMITER //

CREATE TRIGGER UpdateTransferredPoints
AFTER INSERT ON P2P
FOR EACH ROW
BEGIN
  -- Обновление записи в таблице TransferredPoints
  UPDATE TransferredPoints
  SET transfer_status = 'начало'
  WHERE transfer_id = NEW.transfer_id;
END //

DELIMITER ;

-- Тестовые запросы/вызовы для каждого пункта

-- Добавление записи в таблицу P2P
INSERT INTO P2P (transfer_id, transfer_status)
VALUES (1, 'начало');

-- Проверка изменений в таблице TransferredPoints
SELECT * FROM TransferredPoints;
-- В этом скрипте создан триггер UpdateTransferredPoints, который срабатывает после добавления записи в таблицу P2P. Каждый раз, когда происходит вставка новой записи в таблицу P2P, триггер выполняет следующие действия:

-- Обновляет запись в таблице TransferredPoints, устанавливая значение transfer_status в "начало" для записи с соответствующим transfer_id, который соответствует только что добавленной записи в таблицу P2P.
-- После определения триггера UpdateTransferredPoints следуют тестовые запросы/вызовы:

-- Добавление записи со статусом "начало" в таблицу P2P с transfer_id равным 1.
-- Проверка изменений в таблице TransferredPoints, чтобы убедиться, что соответствующая запись была обновлена и transfer_status установлено в "начало".
-- Вы можете изменить параметры вставки в тестовом запросе, чтобы адаптировать их под свои данные.

-- Ниже представлен скрипт part4.sql, который содержит триггер CheckXPRecord для проверки корректности добавляемой записи в таблицу XP.

-- Создание триггера для проверки корректности записи в таблице XP
DELIMITER //

CREATE TRIGGER CheckXPRecord
BEFORE INSERT ON XP
FOR EACH ROW
BEGIN
  DECLARE maxXP INT;
  DECLARE checkStatus VARCHAR(255);

  -- Получение максимального доступного количества XP для проверяемой задачи
  SELECT max_xp INTO maxXP
  FROM Tasks
  WHERE task_name = NEW.task_name;

  -- Получение статуса проверки, на которую ссылается запись
  SELECT check_status INTO checkStatus
  FROM Checks
  WHERE check_id = NEW.check_id;

  -- Проверка корректности записи
  IF NEW.xp_amount <= maxXP AND checkStatus = 'успешный' THEN
    -- Запись корректна, ничего не делаем
  ELSE
    -- Запись не корректна, отмена вставки
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Некорректная запись XP';
  END IF;
END //

DELIMITER ;

-- Тестовые запросы/вызовы для каждого пункта

-- Добавление корректной записи в таблицу XP
INSERT INTO XP (xp_id, task_name, check_id, xp_amount)
VALUES (1, 'Задание1', 1, 100);

-- Попытка добавления некорректной записи в таблицу XP
INSERT INTO XP (xp_id, task_name, check_id, xp_amount)
VALUES (2, 'Задание1', 2, 200);

-- Проверка содержимого таблицы XP
SELECT * FROM XP;
-- В этом скрипте создан триггер CheckXPRecord, который срабатывает перед добавлением записи в таблицу XP. При каждой попытке добавления новой записи в таблицу XP, триггер выполняет следующие действия:

-- Получает максимальное доступное количество XP для проверяемой задачи из таблицы Tasks и сохраняет его в переменную maxXP.
-- Получает статус проверки, на которую ссылается запись, из таблицы Checks и сохраняет его в переменную checkStatus.
-- Проверяет корректность записи:
-- Проверяет, что количество XP (xp_amount) не превышает maxXP и статус проверки (checkStatus) равен "успешный".
-- Если запись корректна, ничего не делает.
-- Если запись некорректна, генерирует ошибку с сообщением "Некорректная запись XP", что приведет к отмене вставки записи.
-- После определения триггера CheckXPRecord следуют тестовые запросы/вызовы:

-- Добавление корректной записи в таблицу XP с xp_id равным 1, task_name равным "Задание1", check_id равным 1 и xp_amount равным 100.
-- Попытка добавления некорректной записи в таблицу XP с xp_id равным 2, task_name равным "Задание1", check_id равным 2 и xp_amount равным 200.
-- Проверка содержимого таблицы XP, чтобы убедиться, что только корректная запись была добавлена.
-- Вы можете изменить параметры вставки в тестовых запросах, чтобы адаптировать их под свои данные.