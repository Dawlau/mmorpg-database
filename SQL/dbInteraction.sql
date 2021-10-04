-- Ex6. All users that have a character specified as input and their username doesn't contain the substring 'or'
CREATE OR REPLACE TYPE usernames_NestedTable IS TABLE OF varchar2(50);

CREATE OR REPLACE FUNCTION usersnames_WithCharacter(ch_name IN varchar)
RETURN usernames_NestedTable
IS
    usernames usernames_NestedTable := usernames_NestedTable();
    idx int;
    i int;
BEGIN

    SELECT DISTINCT Username
    BULK COLLECT INTO usernames
    FROM Player_Character
    WHERE lower(Character_Name) = lower(ch_name);
    
    idx := usernames.first;
    
    WHILE idx <= usernames.last
    LOOP
        i := idx;
        idx := usernames.next(idx);
        
        IF lower(usernames(i)) LIKE '%or%' THEN
            usernames.delete(i);
        END IF;
        
    END LOOP;
    
    RETURN usernames;
    
END;
/


DECLARE

    usernames usernames_NestedTable := usernames_NestedTable();
    ch_name varchar2(50) := '&Character_name';
    idx int;
BEGIN
    usernames := usersnames_WithCharacter(ch_name);
    
    if usernames.COUNT = 0 THEN
        RAISE no_data_found;
    END IF;
    
    idx := usernames.first;
    
    WHILE idx <= usernames.last
    LOOP
        DBMS_OUTPUT.PUT_LINE(usernames(idx));
        idx := usernames.next(idx);
    END LOOP;
EXCEPTION
    WHEN no_data_found THEN
        DBMS_OUTPUT.PUT_LINE('No usernames found');
END;
/





-- Ex7 Players that have at least &nr items in the inventory and have &item in it
CREATE OR REPLACE TYPE usernames_NestedTable IS TABLE OF varchar2(50);

CREATE OR REPLACE FUNCTION usernames_WithItems(cnt IN int, item IN varchar2)
RETURN usernames_NestedTable
IS
    usernames usernames_NestedTable := usernames_NestedTable();
    username varchar2(50);
    CURSOR users_WithItems IS
        SELECT DISTINCT Username
        FROM Player p
        JOIN Inventory i on i.Id = p.Inventory_id
        WHERE 
        (   SELECT COUNT(*)
            FROM
            (   SELECT Item_name
                FROM Inventory_OffItem
                WHERE Id = i.Id
                UNION
                SELECT Item_name
                FROM Inventory_DefItem
                Where Id = i.Id
            )
        ) >= cnt
        AND
          (SELECT COUNT(1) 
           FROM(   
                    SELECT Item_Name
                    FROM Inventory_OffItem
                    WHERE Id = i.Id
                    UNION
                    SELECT Item_Name
                    FROM Inventory_DefItem
                    WHERE Id = i.Id
                ) 
            WHERE lower(Item_name) = lower(item)
            ) > 0;
    
BEGIN
    
    OPEN users_WithItems;
    LOOP
    FETCH users_WithItems INTO username;
        EXIT WHEN users_WithItems%notfound;
        usernames.extend;
        usernames(usernames.COUNT) := username;
    END LOOP;
    CLOSE users_WithItems;

    RETURN usernames;
END;
/

DECLARE
    usernames usernames_NestedTable := usernames_NestedTable();
    
    items_count int := &items_count;
    item varchar2(50) := '&item_name';
    
BEGIN
    usernames := usernames_WithItems(items_count, item);
    
    IF usernames.COUNT = 0 THEN
        RAISE no_data_found;
    END IF;
    
    FOR i in usernames.first..usernames.last
    LOOP
        DBMS_OUTPUT.PUT_LINE(usernames(i));
    END LOOP;
    
EXCEPTION
    WHEN no_data_found THEN
        DBMS_OUTPUT.PUT_LINE('No usernames found');
END;
/


-- Ex8 Number of aggresive NPCs that have a chance to drop an item with at least &x bonus health and is at least level &lvl

CREATE OR REPLACE FUNCTION aggrNPCs_WithItems(x IN int, lvl IN int)
RETURN int
IS

    TYPE aggrNPC_DefItem IS RECORD (npc_Name Aggresive_NPC.Name%TYPE, item_Description Defensive_Item.Description%TYPE);
    TYPE aggrNPC_NestedTable IS TABLE OF aggrNPC_DefItem;

    npcs aggrNPC_NestedTable := aggrNPC_NestedTable();
    answer aggrNPC_NestedTable := aggrNPC_NestedTable();
    level int;
    
BEGIN

    SELECT aggr_npc.Name, def_item.Description
    BULK COLLECT INTO npcs
    FROM Aggresive_NPC aggr_npc
    JOIN Inventory inv ON (inv.Id = aggr_npc.Inventory_id)
    JOIN Inventory_DefItem inv_defitem ON (inv.Id = inv_defitem.Id)
    JOIN Defensive_item def_item ON (inv_defitem.Item_name = def_item.Name)
    WHERE def_item.Bonus_Health >= x
    ORDER BY aggr_npc.Name;
    
    IF npcs.COUNT = 0 THEN
        raise NO_DATA_FOUND;
    END IF;
    
    for i in npcs.first..npcs.last
    LOOP
        level := REGEXP_REPLACE(npcs(i).item_Description, '[^0-9]');
        
        IF level >= lvl THEN
            IF answer.COUNT = 0 THEN
                answer.extend;
                answer(answer.COUNT) := npcs(i);
            ELSIF answer(answer.COUNT).npc_Name != npcs(i).npc_Name THEN
                answer.extend;
                answer(answer.COUNT) := npcs(i);
            END IF;
        END IF;
    END LOOP;
    
    FOR i in answer.first..answer.last
    LOOP
        DBMS_OUTPUT.PUT_LINE(answer(i).npc_Name);
    END LOOP;


    RETURN answer.COUNT;

EXCEPTION    
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No data found');
        RETURN 0;
END;
/


DECLARE
    x int := &Bonus_Health;
    lvl int := &Level;
    
    npcs int;
BEGIN
    
    npcs := aggrNPCs_WithItems(x, lvl);
    
    DBMS_OUTPUT.PUT_LINE('Number of NPCs: ' || TO_CHAR(npcs));
    
END;
/


-- Ex 9: All players that have the email from &e and have characters whose skill set contains at least &y skills that give a bonus of at least &x points

CREATE OR REPLACE PROCEDURE Players_withSkills(answer OUT int, x IN int, y IN int, e IN varchar)
IS
    TYPE playerSkill IS RECORD (user_name Player.Username%TYPE, character_name varchar2(50), character_description varchar2(500));
    TYPE playerSkill_NestedTable IS TABLE OF playerSkill;

    t playerSkill_NestedTable := playerSkill_NestedTable();
    
BEGIN
    SELECT p.Username, c.Name, c.Description
    BULK COLLECT INTO t
    FROM Player p
    JOIN Player_Character pc ON (p.Username = pc.Username)
    JOIN Character c ON (c.Name = pc.Character_Name)
    WHERE 
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT *
                FROM Offensive_skill
                WHERE Bonus_Damage >= x
                UNION
                SELECT *
                FROM Defensive_skill
                WHERE Bonus_Health >= x
            ) 
            WHERE lower(Character_Name) = lower(pc.Character_Name)
        ) >= y AND p.Email LIKE '%@' || lower(e) || '%'
    ORDER BY p.Username;
        
    answer := t.COUNT;
    
    IF answer = 0 THEN
        raise no_data_found;
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        DBMS_OUTPUT.PUT_LINE('No data found');
END;
/

DECLARE
    ans int;
    
    x int := &Min_bonus;
    y int := &Skills_Count;
    e Player.Email%TYPE := '&Email_Service';
    
BEGIN
--    DBMS_OUTPUT.PUT_LINE(e);
    Players_withSkills(ans, x, y, e);
    DBMS_OUTPUT.PUT_LINE('Answer: ' || ans);
EXCEPTION
    WHEN value_error THEN
        DBMS_OUTPUT.PUT_LINE('Invalid input');
END;
/


-- Ex.10: statement-level trigger that doesn't allow for anyone to make changes in the Inventory table at 19PM on Sunday.

CREATE OR REPLACE TRIGGER deleteInventory_trigger
BEFORE DELETE ON Inventory
DECLARE
BEGIN
    IF TO_CHAR(SYSDATE, 'HH24') = 19 and TO_CHAR(SYSDATE, 'd') = 7 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Maintanance hour');
    END IF;
END;
/

INSERT INTO Inventory VALUES(100);
SELECT * FROM INVENTORY;
DELETE FROM INVENTORY WHERE Id = 100;


-- Ex.11: row-level trigger that checks for player validation in Player table when updating or inserting


CREATE OR REPLACE TRIGGER changePassword_trigger
BEFORE INSERT OR UPDATE OF Password
ON Player
FOR EACH ROW
DECLARE

BEGIN

    IF UPDATING THEN
    
        IF :NEW.Password = :OLD.Password THEN
            RAISE_APPLICATION_ERROR(-20001, 'You cannot use the same password'); 
        END IF;
        
        IF LENGTH(:NEW.Password) < 10 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Password is too short'); 
        END IF;
        
        IF :New.Password NOT LIKE '%0%' and :New.Password NOT LIKE '%1%' and :New.Password NOT LIKE '%2%' THEN
            RAISE_APPLICATION_ERROR(-20001, 'Password must contain at least one digit between 0 and 2'); 
        END IF;
        
    ELSE -- Inserting
        
        IF LENGTH(:NEW.password) < 10 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Password is too short'); 
        END IF;
        
        IF :New.Password NOT LIKE '%0%' and :New.Password NOT LIKE '%1%' and :New.Password NOT LIKE '%2%' THEN
            RAISE_APPLICATION_ERROR(-20001, 'Password must contain at least one digit between 0 and 2'); 
        END IF;
        
    END IF;
END;
/

select * from Player;

UPDATE Player
SET Password = 'test'
WHERE Username = 'Julissa';

UPDATE Player
SET Password = 'testtesttesttesttesttesttesttest'
WHERE Username = 'Julissa';

UPDATE Player
SET Password = 'romeojulieta123'
WHERE Username = 'Julissa';

UPDATE Player
SET Password = 'romeojulieta123romeojulieta123'
WHERE Username = 'Julissa';

INSERT INTO Player
VALUES ('test', 'test', 'test@gmail.com', NULL);

INSERT INTO Player
VALUES ('test', 'testtesttesttesttesttesttesttest', 'test@gmail.com', NULL);

INSERT INTO Player
VALUES ('test', 'testtesttesttesttesttesttesttest123', 'test@gmail.com', NULL);

DELETE FROM Player
WHERE Username = 'test';

-- Ex.12: LDD trigger

CREATE TABLE DDL_TABLE_LOG
(
    ora_dict_obj_name VARCHAR2(100),
    ora_login_user VARCHAR2(100),
    creation_date DATE,
    ora_sysevent VARCHAR2(100),
    ora_dict_obj_type VARCHAR2(100),
    ora_dict_obj_owner VARCHAR2(100)
);



CREATE OR REPLACE TRIGGER DLL_TRIGGER 
AFTER DDL 
ON DATABASE
BEGIN
    INSERT INTO DDL_TABLE_LOG
    VALUES
    (
        ora_dict_obj_name,
        ora_login_user,
        sysdate,
        ora_sysevent,
        ora_dict_obj_type,
        ora_dict_obj_owner
    );
END;
/

SELECT * FROM DDL_TABLE_LOG;

CREATE TABLE DLL_TEST
(
    test int PRIMARY KEY
);

DROP TABLE DLL_TEST;



-- Ex.13: Define package

CREATE OR REPLACE PACKAGE main_package AS 
    TYPE usernames_NestedTable IS TABLE OF Player.Username%TYPE;
    FUNCTION usersnames_WithCharacter(ch_name IN varchar) RETURN usernames_NestedTable;
    
    FUNCTION usernames_WithItems(cnt IN int, item IN varchar2)RETURN usernames_NestedTable;
    
    FUNCTION aggrNPCs_WithItems(x IN int, lvl IN int) RETURN int;
    
    PROCEDURE Players_withSkills(answer OUT int, x IN int, y IN int, e IN varchar);
    
END main_package; 
/

CREATE OR REPLACE PACKAGE BODY main_package AS

    FUNCTION usersnames_WithCharacter(ch_name IN varchar)
    RETURN usernames_NestedTable
    IS
        usernames usernames_NestedTable := usernames_NestedTable();
        idx int;
        i int;
    BEGIN
    
        SELECT DISTINCT Username
        BULK COLLECT INTO usernames
        FROM Player_Character
        WHERE lower(Character_Name) = lower(ch_name);
        
        idx := usernames.first;
        
        WHILE idx <= usernames.last
        LOOP
            i := idx;
            idx := usernames.next(idx);
            
            IF lower(usernames(i)) LIKE '%or%' THEN
                usernames.delete(i);
            END IF;
            
        END LOOP;
        
        RETURN usernames;
        
    END;
    
    FUNCTION usernames_WithItems(cnt IN int, item IN varchar2)
    RETURN usernames_NestedTable
    IS
        usernames usernames_NestedTable := usernames_NestedTable();
        username varchar2(50);
        CURSOR users_WithItems IS
            SELECT DISTINCT Username
            FROM Player p
            JOIN Inventory i on i.Id = p.Inventory_id
            WHERE 
            (   SELECT COUNT(*)
                FROM
                (   SELECT Item_name
                    FROM Inventory_OffItem
                    WHERE Id = i.Id
                    UNION
                    SELECT Item_name
                    FROM Inventory_DefItem
                    Where Id = i.Id
                )
            ) >= cnt
            AND
              (SELECT COUNT(1) 
               FROM(   
                        SELECT Item_Name
                        FROM Inventory_OffItem
                        WHERE Id = i.Id
                        UNION
                        SELECT Item_Name
                        FROM Inventory_DefItem
                        WHERE Id = i.Id
                    ) 
                WHERE lower(Item_name) = lower(item)
                ) > 0;
        
    BEGIN
        
        OPEN users_WithItems;
        LOOP
        FETCH users_WithItems INTO username;
            EXIT WHEN users_WithItems%notfound;
            usernames.extend;
            usernames(usernames.COUNT) := username;
        END LOOP;
        CLOSE users_WithItems;
    
        RETURN usernames;
    END;
    
    FUNCTION aggrNPCs_WithItems(x IN int, lvl IN int)
    RETURN int
    IS
    
        TYPE aggrNPC_DefItem IS RECORD (npc_Name Aggresive_NPC.Name%TYPE, item_Description Defensive_Item.Description%TYPE);
        TYPE aggrNPC_NestedTable IS TABLE OF aggrNPC_DefItem;
    
        npcs aggrNPC_NestedTable := aggrNPC_NestedTable();
        answer aggrNPC_NestedTable := aggrNPC_NestedTable();
        level int;
        
    BEGIN
    
        SELECT aggr_npc.Name, def_item.Description
        BULK COLLECT INTO npcs
        FROM Aggresive_NPC aggr_npc
        JOIN Inventory inv ON (inv.Id = aggr_npc.Inventory_id)
        JOIN Inventory_DefItem inv_defitem ON (inv.Id = inv_defitem.Id)
        JOIN Defensive_item def_item ON (inv_defitem.Item_name = def_item.Name)
        WHERE def_item.Bonus_Health >= x
        ORDER BY aggr_npc.Name;
        
        IF npcs.COUNT = 0 THEN
            raise NO_DATA_FOUND;
        END IF;
        
        for i in npcs.first..npcs.last
        LOOP
            level := REGEXP_REPLACE(npcs(i).item_Description, '[^0-9]');
            
            IF level >= lvl THEN
                IF answer.COUNT = 0 THEN
                    answer.extend;
                    answer(answer.COUNT) := npcs(i);
                ELSIF answer(answer.COUNT).npc_Name != npcs(i).npc_Name THEN
                    answer.extend;
                    answer(answer.COUNT) := npcs(i);
                END IF;
            END IF;
        END LOOP;
        
        FOR i in answer.first..answer.last
        LOOP
            DBMS_OUTPUT.PUT_LINE(answer(i).npc_Name);
        END LOOP;
    
    
        RETURN answer.COUNT;
    
    EXCEPTION    
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('No data found');
            RETURN 0;
    END;


    PROCEDURE Players_withSkills(answer OUT int, x IN int, y IN int, e IN varchar)
    IS
        TYPE playerSkill IS RECORD (user_name Player.Username%TYPE, character_name varchar2(50), character_description varchar2(500));
        TYPE playerSkill_NestedTable IS TABLE OF playerSkill;
    
        t playerSkill_NestedTable := playerSkill_NestedTable();
        
    BEGIN
        SELECT p.Username, c.Name, c.Description
        BULK COLLECT INTO t
        FROM Player p
        JOIN Player_Character pc ON (p.Username = pc.Username)
        JOIN Character c ON (c.Name = pc.Character_Name)
        WHERE 
            (
                SELECT COUNT(*)
                FROM
                (
                    SELECT *
                    FROM Offensive_skill
                    WHERE Bonus_Damage >= x
                    UNION
                    SELECT *
                    FROM Defensive_skill
                    WHERE Bonus_Health >= x
                ) 
                WHERE lower(Character_Name) = lower(pc.Character_Name)
            ) >= y AND p.Email LIKE '%@' || lower(e) || '%'
        ORDER BY p.Username;
            
        answer := t.COUNT;
        
        IF answer = 0 THEN
            raise no_data_found;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            DBMS_OUTPUT.PUT_LINE('No data found');
    END;
    
END;
/

DROP PACKAGE main_package;

-- first function
DECLARE

    usernames main_package.usernames_NestedTable := main_package.usernames_NestedTable();
    ch_name varchar2(50) := '&Character_name';
    idx int;
BEGIN
    usernames := main_package.usersnames_WithCharacter(ch_name);
    
    if usernames.COUNT = 0 THEN
        RAISE no_data_found;
    END IF;
    
    idx := usernames.first;
    
    WHILE idx <= usernames.last
    LOOP
        DBMS_OUTPUT.PUT_LINE(usernames(idx));
        idx := usernames.next(idx);
    END LOOP;
EXCEPTION
    WHEN no_data_found THEN
        DBMS_OUTPUT.PUT_LINE('No usernames found');
END;
/

-- second function
DECLARE
    usernames main_package.usernames_NestedTable := main_package.usernames_NestedTable();
    
    items_count int := &items_count;
    item varchar2(50) := '&item_name';
    
BEGIN
    usernames := main_package.usernames_WithItems(items_count, item);
    
    IF usernames.COUNT = 0 THEN
        RAISE no_data_found;
    END IF;
    
    FOR i in usernames.first..usernames.last
    LOOP
        DBMS_OUTPUT.PUT_LINE(usernames(i));
    END LOOP;
    
EXCEPTION
    WHEN no_data_found THEN
        DBMS_OUTPUT.PUT_LINE('No usernames found');
END;
/


-- third function

DECLARE
    x int := &Bonus_Health;
    lvl int := &Level;
    
    npcs int;
BEGIN
    
    npcs := main_package.aggrNPCs_WithItems(x, lvl);
    
    DBMS_OUTPUT.PUT_LINE('Number of NPCs: ' || TO_CHAR(npcs));
    
END;
/



-- fourth function

DECLARE
    ans int;
    
    x int := &Min_bonus;
    y int := &Skills_Count;
    e Player.Email%TYPE := '&Email_Service';
    
BEGIN
--    DBMS_OUTPUT.PUT_LINE(e);
    main_package.Players_withSkills(ans, x, y, e);
    DBMS_OUTPUT.PUT_LINE('Answer: ' || ans);
EXCEPTION
    WHEN value_error THEN
        DBMS_OUTPUT.PUT_LINE('Invalid input');
END;
/


-- Ex14: Players that have at least &x items in inventory and have a &ch character

CREATE OR REPLACE PACKAGE pckge AS
    TYPE playerRow is TABLE OF Player%ROWTYPE;
    TYPE players is TABLE OF playerRow;
    
    FUNCTION getPlayers(x IN int, ch IN varchar2) RETURN players;
    PROCEDURE printFilteredPlayers(x IN int, ch IN varchar2, em IN varchar2);
    
END pckge;
/

CREATE OR REPLACE PACKAGE BODY pckge AS

    FUNCTION getPlayers(x IN int, ch IN varchar2)
    RETURN players 
    IS
        matrice players := players();
        
        CURSOR fetchPlayers IS
            SELECT p.Username, p.Password, p.Email, p.Inventory_Id
            FROM Player p
            JOIN Inventory i ON(i.Id = p.Inventory_id)
            JOIN Player_Character pc ON(p.Username = pc.Username)
            WHERE (
                        SELECT COUNT(*)
                        FROM (
                                SELECT *
                                FROM Inventory_DefItem
                                WHERE Id = i.Id
                                UNION
                                SELECT *
                                FROM Inventory_OffItem
                                WHERE Id = i.Id
                             )
                  ) >= x AND lower(Character_Name) = lower(ch);
        
    BEGIN
        
        FOR p IN fetchPlayers
        LOOP
            matrice.extend;

            SELECT *
            BULK COLLECT INTO matrice(matrice.COUNT)
            FROM Player
            WHERE Username = p.Username;

        END LOOP;

        RETURN matrice;
        
    END;
    
    
    PROCEDURE printFilteredPlayers(x IN int, ch IN varchar2, em IN varchar2)
    IS
        matrice players;
        cnt int := 0;
    BEGIN
        matrice := getPlayers(x, ch);
        
        IF matrice.COUNT = 0 THEN
            RAISE no_data_found;
        END IF;
        
        FOR i IN matrice.first..matrice.last
        LOOP
            FOR j in matrice(i).first..matrice(i).last
            LOOP
                IF matrice(i)(j).Email LIKE '%@' || em || '.%' THEN
                    DBMS_OUTPUT.PUT_LINE(matrice(i)(j).Username);
                    cnt := cnt + 1;
                END IF;
            END LOOP;
        END LOOP;
        
        IF cnt = 0 THEN
            RAISE no_data_found;
        END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                DBMS_OUTPUT.PUT_LINE('No users');
        
    END;

END pckge;
/


DECLARE

    x int := &nr_items;
    ch varchar2(50) := '&character_name';
    em varchar2(50) := '&email_service';

BEGIN
    pckge.printFilteredPlayers(x, ch, em);
END;
/