/*
  [NOTE 01] NATIVE COMPILATION
  One can alter the session to compile code in �NATIVE� mode by executing following statement and then compile the stored procedure.
    SQL> ALTER SESSION SET PLSQL_CODE_TYPE=�NATIVE�;
    Session altered.
  To switch back to default mode,
    SQL> ALTER SESSION SET PLSQL_CODE_TYPE=�INTERPRETED�;
    Session altered.
  
  [NOTE 02] GOOD LOOKING LOGS
  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_DATE_FORMAT = ''DD-MON-YYYY HH24:MI:SS''';
  DBMS_OUTPUT.PUT_LINE(SYSDATE || ' [ERROR] Code, Message = ' || SQLCODE || ', ' || SQLERRM);
 */
 
SET SERVEROUTPUT ON;

<<ROOT>>
DECLARE
  /* CONSTANTS FIRST */
  cnMinSalary CONSTANT NUMBER(5) := 20000;
	cnMaxSalary CONSTANT NUMBER(6) := 150000;
  
  /* COMMON SIMPLE TYPES */
  nDefault  NUMBER DEFAULT 1200;          -- equals to NUMBER := 1200
  nSalary   NUMBER(4,0);                  -- from 1 to 9999. NUMBER(precision,scale)
  nSalary2  BINARY_INTEGER;               -- equals to PLS_INTEGER, better performance than NUMBER for INTEGER values
                                          -- equals to nSalary2 NATURAL and nSalary2 POSITIVE but they can't be, respectvely, less than 0 and 1
  nSalary3  SIMPLE_INTEGER DEFAULT 10;    -- even better than BINARY_INTEGER but CANNOT be NULL and it doesn't overflow, it goes back to the minimum value
  nSalary4  BINARY_FLOAT;
  nSalary5  BINARY_DOUBLE;
  
  bBoolean  BOOLEAN NOT NULL := TRUE;
	cSSN      CHAR(10);                     -- always uses N chars even if value is shorter
	vLName    VARCHAR2(15);                 -- dynamic use of bytes up to N. Note: VARCHAR is a synonim for VARCHAR2
	dDOB      DATE;
  uSomeID   UROWID;                       -- modern version of uSomeID ROWID. Identifies a physical or logical row in a table.
  uuid      RAW(16) DEFAULT SYS_GUID();   -- a UUID for each exec
  
  /* COMPLEX TYPES */
  xtySalary   employee.salary%TYPE;       -- gets EMPLOYEE.SALARY TYPE
  xtyAvgSalry xtySalary%TYPE;
  xroEmployee employee%ROWTYPE;           -- IT'S A FULL RECORD. I can do xr_employee.salary for example
  
  TYPE xtaEmployee                        -- a one-dimensional table of SSN from Employee table
    IS TABLE OF employee.ssn%TYPE
    INDEX BY SIMPLE_INTEGER;              -- this is a pre-defined column to index each value
  arrWorkers  xtaEmployee;                -- these are then basically array of SSN
  arrManagers xtaEmployee;

BEGIN
  DBMS_OUTPUT.PUT_LINE('---------- BEGIN ----------');
  DBMS_OUTPUT.PUT_LINE('The ID of this run is ' || uuid);
  GOTO ITSNOTOVERYET;

  <<ITSOVER>>
  DBMS_OUTPUT.PUT_LINE('---------- THE END                ----------');
  <<ITSNOTOVERYET>>
  DBMS_OUTPUT.PUT_LINE('---------- THE END..OR MAYBE NOT? ----------');
  DBMS_OUTPUT.NEW_LINE;
  
  
  -- LESSON 1
  ---- SELECT INTO expects only (and AT LEAST) ONE row returned.
  ---- No rows returned will trigger the NO_DATA_FOUND exception (e.g. set WHERE ssn = 'ABC')
  ---- More than one row returned will trigger the TOO_MANY_ROWS exception (e.g. set WHERE 1=1)
  ---- Remember that to be sure you can always use WHERE ROWNUM <= 1 if it makes sense
  ---- Note: Aggregate function always return one values, so.. no problem there.
  SELECT salary, lname
  INTO xtySalary, vLName
  FROM employee
  WHERE ssn = '123456789';
  DBMS_OUTPUT.PUT_LINE('Lastname is ' || vLName || ' and salary is ' || xtySalary);
  
  
  -- LESSON 2
  ---- NESTED BLOCKS will allow for local variables scope AND will manage exceptions locally
  ---- It's a good trick if you know in advance that a piece of code is likely to cause problems
  ---- Note that they use TAGS as identifiers
  <<CHILDBLOCK>>
  DECLARE
    vLocalString  VARCHAR2(50) := 'you can''t see me outside of this block';                -- NOTE: the escape char is '
    vLocalStringButBetter VARCHAR2(50) := q'(I'm like vLocalString but I'm better escape)'; -- even better, use q'( ... )' to escape everything between ()
    vLocalSalary xtySalary%TYPE := xtySalary;
    vLocalLName vLName%TYPE := vLName;
  BEGIN
    DBMS_OUTPUT.PUT_LINE(q'(I'm inside the child block now, yet I can see that ...)');
    DBMS_OUTPUT.PUT_LINE('Lastname is ' || vLName || ' and salary is ' || xtySalary);
    
      -- Let's play by causing exceptions: WHERE 1=0 for NO_DATA_FOUND and 1=1 for TOO_MANY_ROWS
      SELECT salary, lname
      INTO xtySalary, vLName
      FROM employee
      WHERE 1=0;
      DBMS_OUTPUT.PUT_LINE('Lastname is ' || vLName || ' and salary is ' || xtySalary);
      
      <<LEAFBLOCK>>
      DECLARE
      BEGIN
        -- I can go on and on with NESTED BLOCKS but there's a limit of 200 per progran
        NULL;
      END LEAFBLOCK;
      
  EXCEPTION
    WHEN NO_DATA_FOUND
      THEN DBMS_OUTPUT.PUT_LINE('!!! TOO_MANY_ROWS EXCEPTION: Eh, I knew it. This is why I''m managing it inside the child block. No harm :) !!!');
      xtySalary := cnMinSalary;
      vLName := 'Mr. No One';
    WHEN TOO_MANY_ROWS
      THEN DBMS_OUTPUT.PUT_LINE('!!! TOO_MANY_ROWS EXCEPTION: Oh come on.. I''ll let the outher block deal with this one !!!');
      RAISE; -- the RAISE command will pass the exception to the outer block to deal with
    WHEN OTHERS
      THEN DBMS_OUTPUT.PUT_LINE('!!! OTHERS EXCEPTION: Well.. shit. Dind''t see this one coming !!!');
  END CHILDBLOCK;
  
  -- Now that I'm back, I can see that my 2 vars have been updated
  -- I can't use any of the vLocal vars though, can't even see them (try and you'll get a compilation error)
  DBMS_OUTPUT.PUT_LINE('Lastname is ' || vLName || ' and salary is ' || xtySalary);
  -- LESSON 3
  ----
  
  
  -- LESSON 99
  ---- you can't put a TAG to the end of the code and jump to it. There must be at least one istruction that follows the tag.
  ---- fortunately for us, NULL is a valid istruction :')
  <<GOODBYE>>
  NULL;
  
EXCEPTION
  WHEN NO_DATA_FOUND
    THEN DBMS_OUTPUT.PUT_LINE('!!! NO_DATA_FOUND EXCEPTION: THE FUCK ARE YOU LOOKING FOR? !!!');
  WHEN TOO_MANY_ROWS
    THEN DBMS_OUTPUT.PUT_LINE('!!! TOO_MANY_ROWS EXCEPTION: WAAAY TOO GREEDY, SLOW DOWN BUDDY !!!');
  WHEN OTHERS
    THEN DBMS_OUTPUT.PUT_LINE('!!! OTHERS EXCEPTION: DAMN BRO YOU FUCKED UP BIG TIME ... !!!');
END ROOT;