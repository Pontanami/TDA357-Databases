CREATE VIEW CourseQueuePositions AS
    SELECT course, student, ROW_NUMBER() OVER (PARTITION BY course ORDER BY position) AS place
    FROM WaitingList;

CREATE FUNCTION register() RETURNS trigger AS $$
    BEGIN
        --Check prerequisites for the course
        IF(( SELECT COUNT(prerequisite)
            FROM Prerequisites
            WHERE course = NEW.course AND (prerequisite NOT IN(SELECT course FROM PassedCourses WHERE student = NEW.student))) > 0)
            THEN RAISE EXCEPTION '% has not met the prerequisites for this course', NEW.student;
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
		IF(NOT EXISTS (SELECT code FROM LimitedCourses WHERE code = NEW.course))
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
        IF (SELECT COUNT(*) FROM Registrations WHERE course = NEW.course AND status = 'registered') >=
        (SELECT capacity FROM LimitedCourses WHERE code = NEW.course)
        THEN
            -- course is full insert into waitinglist
            INSERT INTO WaitingList(student, course, position) VALUES (
				NEW.student, NEW.course,
				DEFAULT
			);
             RETURN NEW;
        ELSE
            -- course is not full Insert into registered (Limited course)
		    INSERT INTO Registered(student, course) VALUES (NEW.student, NEW.course);	
		    RETURN NEW;
        END IF;
    END
$$ LANGUAGE plpgsql;

CREATE TRIGGER register_trigger
INSTEAD OF INSERT ON Registrations
FOR EACH ROW EXECUTE PROCEDURE register();

CREATE FUNCTION unregister() RETURNS trigger AS $$
    BEGIN
        --Check if student is not registered or not on waitinglist for this course (Cannot check this with this trigger)
        --IF(
        --NOT EXISTS(SELECT student FROM Registrations WHERE student = OLD.student AND course = OLD.course))
        --    THEN RAISE EXCEPTION '% is not registered for course %', OLD.student, OLD.course;
        --END IF;

        --Check if its a limitedcourse or not, if not then unregister for course.
		IF(NOT EXISTS (SELECT code FROM LimitedCourses WHERE code = OLD.course))
			THEN 
			DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
			RETURN OLD;
		END IF;

        --Check if course is overfull
		IF((SELECT COUNT(student) FROM Registered WHERE course = OLD.course) - 1 >= 
        (SELECT capacity FROM LimitedCourses WHERE code = OLD.course))
			THEN 
			DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
			RETURN OLD;
		END IF;

        --Check if there are no students in waitinglist
		IF(NOT EXISTS (SELECT student FROM WaitingList WHERE course = OLD.course))
			THEN
			DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
			RETURN OLD;
		END IF;
        
        --Delete student from WaitingList if not first 
        IF((SELECT place FROM CourseQueuePositions WHERE student = OLD.student AND course = OLD.course) != 1)
            THEN DELETE FROM WaitingList WHERE student = OLD.student AND course = OLD.course;
            RETURN OLD;
        END IF;

        --Add first student in waitinglist to registered and then delete from waitinglist
        INSERT INTO Registered(student, course) VALUES (
            (SELECT student FROM WaitingList WHERE course = OLD.course ORDER BY position LIMIT 1),
            OLD.course
        );
        DELETE FROM WaitingList WHERE student = (SELECT student FROM WaitingList WHERE course = OLD.course ORDER BY position LIMIT 1) 
        AND course = OLD.course;
        
        --Delete student from Registrations
        DELETE FROM Registered WHERE student = OLD.student AND course = OLD.course;
        RETURN OLD;
    END
$$ LANGUAGE plpgsql;

CREATE TRIGGER unregister_trigger
INSTEAD OF DELETE ON Registrations
FOR EACH ROW EXECUTE FUNCTION unregister();
