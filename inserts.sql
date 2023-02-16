INSERT INTO Departments VALUES ('Dept. of Computing Science', 'CS');--
INSERT INTO Departments VALUES ('Computer Science and Engineering program', 'CSEP');--

INSERT INTO Programs VALUES ('Prog1', 'P1');--
INSERT INTO Programs VALUES ('Prog2', 'P2');--

INSERT INTO Branches VALUES ('B2','Prog2');
INSERT INTO Branches VALUES ('B1','Prog1');

INSERT INTO Students VALUES ('1111111111','N1','ls1','Prog1');
INSERT INTO Students VALUES ('2222222222','N2','ls2','Prog1');
INSERT INTO Students VALUES ('3333333333','N3','ls3','Prog2');
INSERT INTO Students VALUES ('4444444444','N4','ls4','Prog1');
INSERT INTO Students VALUES ('5555555555','Nx','ls5','Prog2');
INSERT INTO Students VALUES ('6666666666','Nx','ls6','Prog2');

INSERT INTO Courses VALUES ('CCC111','C1',22.5,'Dept. of Computing Science');--
INSERT INTO Courses VALUES ('CCC222','C2',20,'Computer Science and Engineering program');--
INSERT INTO Courses VALUES ('CCC333','C3',30,'Dept. of Computing Science');--
INSERT INTO Courses VALUES ('CCC444','C4',60,'Dept. of Computing Science');--
INSERT INTO Courses VALUES ('CCC555','C5',50,'Computer Science and Engineering program');--
INSERT INTO Courses VALUES ('CCC666', 'C6', 20, 'Computer Science and Engineering program');--

INSERT INTO LimitedCourses VALUES ('CCC222',3);
INSERT INTO LimitedCourses VALUES ('CCC333',2);
INSERT INTO LimitedCourses VALUES ('CCC444',3);

INSERT INTO Prerequisites VALUES('CCC666', 'CCC111');
INSERT INTO Prerequisites VALUES('CCC666', 'CCC222');

INSERT INTO Classifications VALUES ('math');
INSERT INTO Classifications VALUES ('research');
INSERT INTO Classifications VALUES ('seminar');

INSERT INTO Classified VALUES ('CCC333','math');
INSERT INTO Classified VALUES ('CCC444','math');
INSERT INTO Classified VALUES ('CCC444','research');
INSERT INTO Classified VALUES ('CCC444','seminar');

INSERT INTO StudentBranches VALUES ('2222222222','B1','Prog1');
INSERT INTO StudentBranches VALUES ('3333333333','B2','Prog2');--
INSERT INTO StudentBranches VALUES ('4444444444','B1','Prog1');
INSERT INTO StudentBranches VALUES ('5555555555','B2','Prog2');--

INSERT INTO MandatoryProgram VALUES ('CCC111','Prog1');

INSERT INTO MandatoryBranch VALUES ('CCC333', 'B1', 'Prog1');
INSERT INTO MandatoryBranch VALUES ('CCC444', 'B2', 'Prog2');

INSERT INTO RecommendedBranch VALUES ('CCC222', 'B1', 'Prog1');
INSERT INTO RecommendedBranch VALUES ('CCC333', 'B2', 'Prog2');

INSERT INTO Registrations VALUES ('1111111111','CCC111');
INSERT INTO Registrations VALUES ('1111111111','CCC222');
INSERT INTO Registrations VALUES ('1111111111','CCC333');
INSERT INTO Registrations VALUES ('3333333333','CCC111');
INSERT INTO Registrations VALUES ('2222222222','CCC222');
INSERT INTO Registrations VALUES ('5555555555','CCC222');
INSERT INTO Registrations VALUES ('5555555555','CCC333');

INSERT INTO Taken VALUES('4444444444','CCC111','5');
INSERT INTO Taken VALUES('4444444444','CCC222','5');
INSERT INTO Taken VALUES('4444444444','CCC333','5');
INSERT INTO Taken VALUES('4444444444','CCC444','5');

INSERT INTO Taken VALUES('5555555555','CCC111','5');
INSERT INTO Taken VALUES('5555555555','CCC222','4');
INSERT INTO Taken VALUES('5555555555','CCC444','3');

INSERT INTO Taken VALUES('2222222222','CCC111','U');
INSERT INTO Taken VALUES('2222222222','CCC222','U');
INSERT INTO Taken VALUES('2222222222','CCC444','U');

INSERT INTO Registrations VALUES('3333333333','CCC222');
INSERT INTO Registrations VALUES('3333333333','CCC333');
INSERT INTO Registrations VALUES('2222222222','CCC333');
INSERT INTO Registrations VALUES('6666666666','CCC333');
