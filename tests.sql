--------------            Register tests     -------------------------------
-- TEST #1: Register for an unlimited course.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('1111111111', 'CCC555'); 

---------------------------------------------
-- TEST #2: Register for a limited course
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('3333333333', 'CCC444'); 

---------------------------------------------
-- TEST #3: Register an already registered student.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('1111111111', 'CCC111'); 

---------------------------------------------
-- TEST #4: waiting for a limited course;
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES('6666666666', 'CCC222');

---------------------------------------------
-- TEST #5: Register a student who has met prerequisites.
-- EXPECTED OUTCOME: Pass
INSERT INTO Registrations VALUES ('5555555555', 'CCC666'); 

---------------------------------------------
-- TEST #6: Register a student who has not met prerequisites.
-- EXPECTED OUTCOME: Fail 
INSERT INTO Registrations VALUES ('2222222222', 'CCC666'); 

---------------------------------------------
-- TEST #7: Register a student who has passed the course.
-- EXPECTED OUTCOME: Fail
INSERT INTO Registrations VALUES ('4444444444', 'CCC111');

---------------------------------------------
-- TEST #8: Register a student who is already on the waiting list.
-- EXPECTED OUTCOME: Fail 
INSERT INTO Registrations VALUES ('3333333333', 'CCC333');

--------------            Unregister tests     -------------------------------
-- TEST #9: Unregister from an unlimited course. 
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCC111';

---------------------------------------------
-- TEST #10: Unregister from a limited course without waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '3333333333' AND course = 'CCC111';

---------------------------------------------
-- TEST #11: Unregister from a limited course with waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '6666666666' AND course = 'CCC333';

---------------------------------------------
-- TEST #12 Unregister from a limited course with a waiting list, when the student is registered.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '1111111111' AND course = 'CCC333';

---------------------------------------------
-- TEST #12 Unregister from a limited course with a waiting list, when the student is in the middle of the waiting list.
-- EXPECTED OUTCOME: Pass
DELETE FROM Registrations WHERE student = '2222222222' AND course ='CCC333';

---------------------------------------------
-- TEST #12 Unregister from an overfull course with a waiting list.?
-- EXPECTED OUTCOME: Pass

---------------------------------------------
-- TEST #13 Unregster student that is not registered or on waitinglist
-- EXPECTED OUTCOME Fail
DELETE FROM Registrations WHERE student = '6666666666' AND course = 'CCC333';

