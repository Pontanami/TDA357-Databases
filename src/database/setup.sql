CREATE TABLE Departments(
    name TEXT PRIMARY KEY,
    abbreviation TEXT NOT NULL UNIQUE
);

CREATE TABLE Programs(
    name TEXT PRIMARY KEY,
    abbreviation TEXT UNIQUE
);

CREATE TABLE Students(
    idnr TEXT PRIMARY KEY CHECK (idnr SIMILAR TO '[0-9]{10}'),
    name TEXT NOT NULL,
    login TEXT NOT NULL UNIQUE,
    program TEXT NOT NULL,
    FOREIGN KEY (program) REFERENCES Programs,
    UNIQUE (idnr, program)
);
CREATE TABLE DepartmentPrograms(
    program TEXT,
    department TEXT,
    PRIMARY KEY (program, department),
    FOREIGN KEY (program) REFERENCES Programs,
    FOREIGN KEY (department) REFERENCES Departments
);

CREATE TABLE Branches(
    name TEXT,
    program TEXT,
    PRIMARY KEY (name, program),
    FOREIGN KEY (program) REFERENCES Programs
);

CREATE TABLE Courses(
    code CHAR(6) PRIMARY KEY,
    name TEXT NOT NULL,
    credits FLOAT NOT NULL CHECK(credits >= 0),
    department TEXT NOT NULL,
    FOREIGN KEY (department) REFERENCES Departments
);

CREATE TABLE LimitedCourses(
    code CHAR(6) PRIMARY KEY,
    capacity INT NOT NULL CHECK (capacity >= 0),
    FOREIGN KEY (code) REFERENCES Courses
);

CREATE TABLE Prerequisites(
    course CHAR(6),
    prerequisite CHAR(6),
    PRIMARY KEY (course, prerequisite),
    FOREIGN KEY (course) REFERENCES Courses,
    FOREIGN KEY (prerequisite) REFERENCES Courses
);

CREATE TABLE DepartmentCourses(
    code CHAR(6),
    department TEXT NOT NULL,
    PRIMARY KEY (code, department),
    FOREIGN KEY (code) REFERENCES Courses,
    FOREIGN KEY (department) REFERENCES Departments
);

CREATE TABLE StudentBranches(
    student TEXT PRIMARY KEY,
    branch TEXT NOT NULL,
    program TEXT NOT NULL,
    FOREIGN KEY (student, program) REFERENCES Students(idnr, program),
    FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE Classifications(
    name TEXT PRIMARY KEY
);

CREATE TABLE Classified(
    course CHAR(6),
    classification TEXT NOT NULL,
    PRIMARY KEY(course, classification),
    FOREIGN KEY (course) REFERENCES Courses,
    FOREIGN KEY (classification) REFERENCES Classifications
);

CREATE TABLE MandatoryProgram(
    course CHAR(6),
    program TEXT,
    PRIMARY KEY(course, program),
    FOREIGN KEY (course) REFERENCES Courses
);

CREATE TABLE MandatoryBranch(
    course CHAR(6),
    branch TEXT,
    program TEXT,
    PRIMARY KEY(course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses,
    FOREIGN KEY (branch, program) REFERENCES Branches
);

CREATE TABLE RecommendedBranch(
    course CHAR(6),
    branch TEXT,
    program TEXT,
    PRIMARY KEY(course, branch, program),
    FOREIGN KEY (course) REFERENCES Courses,
    FOREIGN KEY (branch, program) REFERENCES Branches,
    FOREIGN KEY (program) REFERENCES Programs
);

CREATE TABLE Registered(
    student TEXT,
    course CHAR(6),
    PRIMARY KEY(student, course),
    FOREIGN KEY (student) REFERENCES Students,
    FOREIGN KEY (course) REFERENCES Courses
);

CREATE TABLE Taken(
    student TEXT,
    course CHAR(6),
    grade CHAR(1) NOT NULL DEFAULT 'U' CHECK (grade IN ('U','3','4','5')),
    PRIMARY KEY(student, course),
    FOREIGN KEY (student) REFERENCES Students,
    FOREIGN KEY (course) REFERENCES Courses
);

CREATE TABLE WaitingList(
    student TEXT,
    course TEXT,
    position SERIAL,
    PRIMARY KEY(student, course),
    FOREIGN KEY (student) REFERENCES Students,
    FOREIGN KEY (course) REFERENCES LimitedCourses,
    UNIQUE (course, position)
);


-- 1 --
CREATE VIEW BasicInformation AS
    SELECT idnr, Students.name, login, Students.program, branch 
    FROM Students LEFT OUTER JOIN StudentBranches --Include null values
    ON idnr = StudentBranches.student; --Join on student idnr
-- 2 --
CREATE VIEW FinishedCourses AS
    SELECT student, course, grade, credits FROM Courses, Taken 
    WHERE Courses.code = Taken.course;
-- 3 --
CREATE VIEW PassedCourses AS
    SELECT student, course, credits FROM FinishedCourses
    WHERE grade != 'U';
-- 4 --
CREATE VIEW Registrations AS
    SELECT Registered.student, course, 'registered' AS status FROM Registered
    UNION
    SELECT WaitingList.student, course, 'waiting' AS status FROM WaitingList;
-- 5 --
CREATE VIEW UnreadMandatory AS
    SELECT * FROM(
    SELECT idnr as student, course FROM BasicInformation, MandatoryProgram
    WHERE (BasicInformation.program = MandatoryProgram.program)
    UNION
    SELECT idnr as student, course FROM BasicInformation, MandatoryBranch 
    WHERE ((BasicInformation.branch, BasicInformation.program) = (MandatoryBranch.branch, MandatoryBranch.program))) AS Mandatory 
    WHERE (student, course) NOT IN (SELECT student, course FROM PassedCourses);
-- 6 --
CREATE VIEW PathToGraduation AS( 
    WITH
    ------- Helper queries -------
    StudentClassifications AS(
    SELECT student, classification, credits FROM PassedCourses, Classified WHERE PassedCourses.course = Classified.course),

    RecommendedCredits AS(
    SELECT BasicInformation.idnr AS student, COALESCE(SUM(PassedCoursesAndPrograms.credits),0) AS recommendedCredits 
    FROM BasicInformation LEFT OUTER JOIN 
        (SELECT student, PassedCourses.course, credits, branch, program FROM PassedCourses, RecommendedBranch
        WHERE PassedCourses.course = RecommendedBranch.course) AS PassedCoursesAndPrograms 
    ON BasicInformation.idnr = PassedCoursesAndPrograms.student AND PassedCoursesAndPrograms.program = BasicInformation.program
    AND BasicInformation.branch = PassedCoursesAndPrograms.branch
    GROUP BY BasicInformation.idnr ORDER BY BasicInformation.idnr),
    ------------------------------
    TotalCredits AS (SELECT student, SUM(credits) AS totalCredits FROM PassedCourses GROUP BY student),
    
    MandatoryLeft AS (
    SELECT BasicInformation.idnr as student, COALESCE(COUNT(UnreadMandatory.course),0) as mandatoryLeft 
    FROM BasicInformation LEFT OUTER JOIN UnreadMandatory 
    ON BasicInformation.idnr = UnreadMandatory.student
    GROUP BY BasicInformation.idnr ORDER BY BasicInformation.idnr),

    StudentClassificationCredits AS(
    SELECT BasicInformation.idnr AS student, 
    SUM(CASE WHEN classification = 'math' THEN StudentClassifications.credits ELSE 0 END) AS mathCredits,
    SUM(CASE WHEN classification = 'research' THEN StudentClassifications.credits ELSE 0 END) AS researchCredits,
    SUM(CASE WHEN classification = 'seminar' THEN 1 ELSE 0 END) AS seminarCourses
    FROM BasicInformation LEFT OUTER JOIN StudentClassifications ON BasicInformation.idnr = StudentClassifications.student
    GROUP BY BasicInformation.idnr ORDER BY BasicInformation.idnr)

    --- Select/Control all values
    SELECT BasicInformation.idnr AS student,
    COALESCE(totalCredits, 0) AS totalCredits, mandatoryLeft, mathCredits, researchCredits, seminarCourses, 
   (mandatoryLeft = 0 AND mathCredits >= 20 AND researchCredits >= 10 AND seminarCourses >= 1 AND recommendedCredits >= 10 
   AND BasicInformation.branch IS NOT NULL) AS qualified

    -- Join all tables together
    FROM BasicInformation
    LEFT OUTER JOIN TotalCredits ON BasicInformation.idnr = TotalCredits.student
    LEFT OUTER JOIN MandatoryLeft ON BasicInformation.idnr = MandatoryLeft.student
    LEFT OUTER JOIN StudentClassificationCredits ON BasicInformation.idnr = StudentClassificationCredits.student
    LEFT OUTER JOIN RecommendedCredits ON BasicInformation.idnr = RecommendedCredits.student);

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
INSERT INTO Students VALUES ('7777777777','Nx','ls7','Prog1');

INSERT INTO Courses VALUES ('CCC111','C1',22.5,'Dept. of Computing Science');--
INSERT INTO Courses VALUES ('CCC222','C2',20,'Computer Science and Engineering program');--
INSERT INTO Courses VALUES ('CCC333','C3',30,'Dept. of Computing Science');--
INSERT INTO Courses VALUES ('CCC444','C4',60,'Dept. of Computing Science');--
INSERT INTO Courses VALUES ('CCC555','C5',50,'Computer Science and Engineering program');--
INSERT INTO Courses VALUES ('CCC666', 'C6', 20, 'Computer Science and Engineering program');--

INSERT INTO LimitedCourses VALUES ('CCC222',3);
INSERT INTO LimitedCourses VALUES ('CCC333',2);
INSERT INTO LimitedCourses VALUES ('CCC444',3);
INSERT INTO LimitedCourses VALUES ('CCC555',2);

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

INSERT INTO Registered VALUES ('1111111111','CCC111');
INSERT INTO Registered VALUES ('1111111111','CCC222');
INSERT INTO Registered VALUES ('1111111111','CCC333');
INSERT INTO Registered VALUES ('3333333333','CCC111');
INSERT INTO Registered VALUES ('2222222222','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC222');
INSERT INTO Registered VALUES ('5555555555','CCC333');

INSERT INTO Registered VALUES('5555555555', 'CCC555');
INSERT INTO Registered VALUES('2222222222', 'CCC555');
INSERT INTO Registered VALUES('3333333333', 'CCC555');

INSERT INTO WaitingList VALUES('4444444444', 'CCC555');

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

INSERT INTO WaitingList VALUES('3333333333','CCC222');
INSERT INTO WaitingList VALUES('3333333333','CCC333');
INSERT INTO WaitingList VALUES('2222222222','CCC333');
INSERT INTO WaitingList VALUES('6666666666','CCC333');
INSERT INTO WaitingList VALUES('7777777777','CCC333');
