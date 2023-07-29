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