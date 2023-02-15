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

-- 7 --
--View CourseQueuePositions(course,student,place): for all students who are in the queue for a course, the course code, the student's identification number, and the student's current place in the queue (the student who is first in a queue will have place "1" in that queue, etc.). This view is trivial if you store the positions directly in the database, but not if you store e.g. registration timestamps.
CREATE VIEW CourseQueuePositions AS
    SELECT course, student, position AS place
    FROM WaitingList;
    