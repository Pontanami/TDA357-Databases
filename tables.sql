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

