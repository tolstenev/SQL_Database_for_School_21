-- Создание таблицы Peers
CREATE TABLE Peers (
  PeerNickname VARCHAR(255) PRIMARY KEY,
  Birthday DATE
);

-- Создание таблицы Tasks
CREATE TABLE Tasks (
  TaskName VARCHAR(255) PRIMARY KEY,
  EntryTaskName VARCHAR(255),
  MaxXP INT,
  FOREIGN KEY (EntryTaskName) REFERENCES Tasks(TaskName)
);

-- Создание таблицы P2P
CREATE TABLE P2P (
  ID INT PRIMARY KEY,
  CheckID INT,
  PeerNickname VARCHAR(255),
  P2PStatus ENUM('Start', 'Success', 'Failure'),
  Time DATETIME,
  FOREIGN KEY (CheckID) REFERENCES Checks(ID),
  FOREIGN KEY (PeerNickname) REFERENCES Peers(PeerNickname)
);

-- Создание таблицы Verter
CREATE TABLE Verter (
  ID INT PRIMARY KEY,
  CheckID INT,
  VerterStatus ENUM('Start', 'Success', 'Failure'),
  Time DATETIME,
  FOREIGN KEY (CheckID) REFERENCES Checks(ID)
);

-- Создание таблицы Checks
CREATE TABLE Checks (
  ID INT PRIMARY KEY,
  PeerNickname VARCHAR(255),
  TaskName VARCHAR(255),
  CheckDate DATE,
  FOREIGN KEY (PeerNickname) REFERENCES Peers(PeerNickname),
  FOREIGN KEY (TaskName) REFERENCES Tasks(TaskName)
);

-- Создание таблицы TransferredPoints
CREATE TABLE TransferredPoints (
  ID INT PRIMARY KEY,
  ReviewerPeerNickname VARCHAR(255),
  ReviewedPeerNickname VARCHAR(255),
  TotalPoints INT,
  FOREIGN KEY (ReviewerPeerNickname) REFERENCES Peers(PeerNickname),
  FOREIGN KEY (ReviewedPeerNickname) REFERENCES Peers(PeerNickname)
);

-- Создание таблицы Friends
CREATE TABLE Friends (
  ID INT PRIMARY KEY,
  Peer1Nickname VARCHAR(255),
  Peer2Nickname VARCHAR(255),
  FOREIGN KEY (Peer1Nickname) REFERENCES Peers(PeerNickname),
  FOREIGN KEY (Peer2Nickname) REFERENCES Peers(PeerNickname)
);

-- Создание таблицы Recommendations
CREATE TABLE Recommendations (
  ID INT PRIMARY KEY,
  PeerNickname VARCHAR(255),
  RecommendedPeerNickname VARCHAR(255),
  FOREIGN KEY (PeerNickname) REFERENCES Peers(PeerNickname),
  FOREIGN KEY (RecommendedPeerNickname) REFERENCES Peers(PeerNickname)
);

-- Создание таблицы XP
CREATE TABLE XP (
  ID INT PRIMARY KEY,
  CheckID INT,
  EarnedXP INT,
  FOREIGN KEY (CheckID) REFERENCES Checks(ID)
);

-- Создание таблицы TimeTracking
CREATE TABLE TimeTracking (
  ID INT PRIMARY KEY,
  PeerNickname VARCHAR(255),
  Date DATE,
  Time TIME,
  State INT,
  FOREIGN KEY (PeerNickname) REFERENCES Peers(PeerNickname)
);

-- Заполнение таблицы Peers
INSERT INTO Peers (PeerNickname, Birthday)
VALUES
  ('peer1', '1990-01-01'),
  ('peer2', '1992-05-10'),
  ('peer3', '1988-12-15'),
  ('peer4', '1995-03-22'),
  ('peer5', '1991-09-07');

-- Заполнение таблицы Tasks
INSERT INTO Tasks (TaskName, EntryTaskName, MaxXP)
VALUES
  ('task1', NULL, 100),
  ('task2', 'task1', 200),
  ('task3', 'task1', 150),
  ('task4', 'task2', 300),
  ('task5', 'task3', 250);

-- Заполнение таблицы P2P
INSERT INTO P2P (ID, CheckID, PeerNickname, P2PStatus, Time)
VALUES
  (1, 1, 'peer1', 'Start', '2023-07-01 10:00:00'),
  (2, 1, 'peer2', 'Success', '2023-07-01 11:00:00'),
  (3, 2, 'peer3', 'Start', '2023-07-02 09:00:00'),
  (4, 2, 'peer4', 'Failure', '2023-07-02 10:30:00'),
  (5, 3, 'peer5', 'Start', '2023-07-03 14:00:00');

-- Заполнение таблицы Verter
INSERT INTO Verter (ID, CheckID, VerterStatus, Time)
VALUES
  (1, 1, 'Start', '2023-07-01 11:30:00'),
  (2, 1, 'Success', '2023-07-01 12:00:00'),
  (3, 2, 'Start', '2023-07-02 11:00:00'),
  (4, 2, 'Failure', '2023-07-02 12:30:00'),
  (5, 3, 'Start', '2023-07-03 15:00:00');

-- Заполнение таблицы Checks
INSERT INTO Checks (ID, PeerNickname, TaskName, CheckDate)
VALUES
  (1, 'peer1', 'task1', '2023-07-01'),
  (2, 'peer2', 'task2', '2023-07-02'),
  (3, 'peer3', 'task3', '2023-07-03'),
  (4, 'peer4', 'task4', '2023-07-04'),
  (5, 'peer5', 'task5', '2023-07-05');

-- Заполнение таблицы TransferredPoints
INSERT INTO TransferredPoints (ID, ReviewerPeerNickname, ReviewedPeerNickname, TotalPoints)
VALUES
  (1, 'peer1', 'peer2', 1),
  (2, 'peer1', 'peer3', 2),
  (3, 'peer2', 'peer4', 3),
  (4, 'peer3', 'peer5', 4),
  (5, 'peer4', 'peer5', 2);

-- Заполнение таблицы Friends
INSERT INTO Friends (ID, Peer1Nickname, Peer2Nickname)
VALUES
  (1, 'peer1', 'peer2'),
  (2, 'peer2', 'peer3'),
  (3, 'peer3', 'peer4'),
  (4, 'peer4', 'peer5'),
  (5, 'peer5', 'peer1');

-- Заполнение таблицы Recommendations
INSERT INTO Recommendations (ID, PeerNickname, RecommendedPeerNickname)
VALUES
  (1, 'peer1', 'peer3'),
  (2, 'peer2', 'peer4'),
  (3, 'peer3', 'peer5'),
  (4, 'peer4', 'peer1'),
  (5, 'peer5', 'peer2');

-- Заполнение таблицы XP
INSERT INTO XP (ID, CheckID, EarnedXP)
VALUES
  (1, 1, 50),
  (2, 2, 100),
  (3, 3, 75),
  (4, 4, 150),
  (5, 5, 125);

-- Заполнение таблицы TimeTracking
INSERT INTO TimeTracking (ID, PeerNickname, Date, Time, State)
VALUES
  (1, 'peer1', '2023-07-01', '08:00:00', 1),
  (2, 'peer2', '2023-07-01', '09:00:00', 1),
  (3, 'peer3', '2023-07-01', '10:00:00', 1),
  (4, 'peer4', '2023-07-01', '11:00:00', 1),
  (5, 'peer5', '2023-07-01', '12:00:00', 1);