CREATE TABLE Inventory (
  Id int,
  PRIMARY KEY (Id)
);

CREATE TABLE Player (
  Username varchar2(50),
  Password varchar2(50),
  Email varchar2(50),
  Inventory_id int UNIQUE,
  PRIMARY KEY (Username),
  FOREIGN KEY (Inventory_id) REFERENCES Inventory(Id)
);

CREATE TABLE Defensive_item (
  Name varchar2(50),
  Description varchar2(50),
  Bonus_Health int,
  PRIMARY KEY (Name)
);

CREATE TABLE Offensive_item (
  Name varchar2(50),
  Description varchar2(50),
  Bonus_Damage int,
  PRIMARY KEY (Name)
);

CREATE TABLE Inventory_DefItem (
  Id int,
  Item_name varchar2(50),
  PRIMARY KEY (Id, Item_name),
  FOREIGN KEY (Id) REFERENCES Inventory(id),
  FOREIGN KEY (Item_name) REFERENCES Defensive_item(Name)
);

CREATE TABLE Inventory_OffItem (
  Id int,
  Item_name varchar2(50),
  PRIMARY KEY (Id, Item_name),
  FOREIGN KEY (Id) REFERENCES Inventory(id),
  FOREIGN KEY (Item_name) REFERENCES Offensive_item(Name)
);

CREATE TABLE Aggresive_NPC (
  Name varchar2(50),
  Description varchar2(500),
  Inventory_id int UNIQUE,
  FOREIGN KEY (Inventory_Id) REFERENCES Inventory(Id),
  PRIMARY KEY (Name)
);

CREATE TABLE Neutral_NPC (
  Name varchar2(50),
  Description varchar2(500),
  Inventory_id int UNIQUE,
  PRIMARY KEY (Name),
  FOREIGN KEY (Inventory_Id) REFERENCES Inventory(Id)
);

CREATE TABLE Character (
  Name varchar2(50),
  Description varchar2(500),
  PRIMARY KEY (Name)
);

CREATE TABLE Offensive_skill (
  Name varchar2(50),
  Description varchar2(150),
  Bonus_Damage int,
  Character_name varchar2(50),
  PRIMARY KEY (Name),
  FOREIGN KEY (Character_name) REFERENCES Character(Name)
);

CREATE TABLE Defensive_skill (
  Name varchar2(50),
  Description varchar2(150),
  Bonus_Health int,
  Character_Name varchar2(50),
  PRIMARY KEY (Name),
  FOREIGN KEY (Character_name) REFERENCES Character(Name)
);

CREATE TABLE Player_Character (
  Username varchar2(50),
  Character_Name varchar2(50),
  Lvl int,
  PRIMARY KEY (Username, Character_Name),
  FOREIGN KEY (Username) REFERENCES Player(Username),
  FOREIGN KEY (Character_Name) REFERENCES Character(Name)
);