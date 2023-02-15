-- CREATE FUNCTION name (parameters) RETURNS type AS $$
-- < function code here >
-- $$ LANGUAGE language;

CREATE OR REPLACE FUNCTION register RETURNS trigger AS $$
    BEGIN
        --Check prerequisites for the course
        IF(( SELECT COUNT(prerequisite)
            FROM Prerequisites
            WHERE course = NEW.course AND (prerequisite NOT IN(SELECT course FROM PassedCourses WHERE student = NEW.student))) > 0)
            THEN RAISE EXCEPTION '% has not met the prerequisites for this course', NEW.student
        END IF;

        --Check if student has passed this course already
        IF(EXISTS(SELECT student FROM Taken WHERE student = NEW.student AND course = NEW.course AND grade != 'U'))
			THEN RAISE EXCEPTION '% has already passed course %', NEW.student, NEW.course;
		END IF;

        --Check if student is already registered for this course
        IF(EXISTS(SELECT student FROM Registered WHERE student = NEW.student AND course = NEW.course))
            THEN RAISE EXCEPTION '% is already registered for course %', NEW.student, NEW.course;
        END IF;

        --Check if course is limited, if not then register for course.
		IF(NOT EXISTS (SELECT code FROM LimitedCourse WHERE code = NEW.course))
			THEN 
			--Insert into registered
			INSERT INTO Registered(student, course) VALUES (NEW.student, NEW.course);	
			RETURN NEW;
		END IF;

        --Check if already on WaitingList
        IF(EXISTS (SELECT student FROM WaitingList WHERE student = NEW.student AND course = NEW.course))
			THEN RAISE EXCEPTION '% is already in waitinglist for course %', NEW.student, NEW.course;
		END IF;

        --Check if course is full
        IF (SELECT COUNT(*) FROM Registrations WHERE course = NEW.code AND status = 'registered') >=
        (SELECT capacity FROM LimitedCourses WHERE code = NEW.code)
        THEN
            -- course is full insert into waitinglist
            INSERT INTO WaitingList(student, course, position) VALUES (
				NEW.student,
				NEW.course,
				((SELECT Count(student) FROM WaitingList WHERE course = NEW.course) + 1)
			);
        ELSE
            -- course is not full Insert into registered (Limited course)
		    INSERT INTO Registered(student, course) VALUES (NEW.student, NEW.course);	
		    RETURN NEW;
        END IF;
    END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER register
INSTEAD OF INSERT ON Registrations
FOR EACH ROW EXECUTE FUNCTION register() ;

CREATE FUNCTION unregister RETURNS trigger AS $$
    BEGIN
        --Check if its a limitedcourse or not, if not then unregister for course.
		IF(NOT EXISTS (SELECT code FROM LimitedCourse WHERE code = OLD.course))
			THEN 
			DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
			RETURN NEW;
		END IF;

        --Check if student is not registered for this course
        IF(NOT EXISTS(SELECT student FROM Registered WHERE student = OLD.student AND course = OLD.course))
            THEN RAISE EXCEPTION '% is not registered for course %', OLD.student, OLD.course;
        END IF;

        --Check if student is on waitinglist for this course
        IF(EXISTS(SELECT student FROM WaitingList WHERE student = OLD.student AND course = OLD.course))
            THEN RAISE EXCEPTION '% is on waitinglist for course %', OLD.student, OLD.course;
        END IF;

        --Delete student fromm Registrations

        -- Check if this opened up a spot on the course. if so, add first in WaitingList to Registrations
    END;
$$ LANGUAGE plpgsql;