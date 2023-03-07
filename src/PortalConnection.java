
import java.sql.*; // JDBC stuff.
import java.util.List;
import java.util.Properties;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import org.json.*; // JSON

public class PortalConnection {

    // Set this to e.g. "portal" if you have created a database named portal
    // Leave it blank to use the default database of your database user
    static final String DBNAME = "";
    // For connecting to the portal database on your local machine
    static final String DATABASE = "jdbc:postgresql://localhost/"+DBNAME;
    static final String USERNAME = "postgres";
    static final String PASSWORD = "postgres";

    // For connecting to the chalmers database server (from inside chalmers)
    // static final String DATABASE = "jdbc:postgresql://brage.ita.chalmers.se/";
    // static final String USERNAME = "tda357_nnn";
    // static final String PASSWORD = "yourPasswordGoesHere";


    // This is the JDBC connection object you will be using in your methods.
    private Connection conn;

    public PortalConnection() throws SQLException, ClassNotFoundException {
        this(DATABASE, USERNAME, PASSWORD);  
    }

    // Initializes the connection, no need to change anything here
    public PortalConnection(String db, String user, String pwd) throws SQLException, ClassNotFoundException {
        Class.forName("org.postgresql.Driver");
        Properties props = new Properties();
        props.setProperty("user", user);
        props.setProperty("password", pwd);
        conn = DriverManager.getConnection(db, props);
    }


    // Register a student on a course, returns a tiny JSON document (as a String)
    public String register(String student, String courseCode){
      
      try (PreparedStatement ps = conn.prepareStatement("INSERT INTO Registrations VALUES (?,?)")){
        ps.setString(1, student);
        ps.setString(2, courseCode);
      } catch (SQLException e) {
         return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
      }
        return "{\"success\":true}";
    }

    // Unregister a student from a course, returns a tiny JSON document (as a String)
    public String unregister(String student, String courseCode){
        try(PreparedStatement ps = conn.prepareStatement("DELETE FROM Registrations WHERE student=? AND course=?");){
        ps.setString(1, student);
        ps.setString(2, courseCode);
        int i = ps.executeUpdate();
        System.out.println(i);
        if(i == 0)
          return "{\"success\":false, \"error\":\"No such registration\"}";
        } catch (SQLException e) {
          return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
      return "{\"success\":true}";
    }

    // Return a JSON document containing lots of information about a student, it should validate against the schema found in information_schema.json
    public String getInfo(String student) throws SQLException{
        JSONObject result = new JSONObject();
        //Basic information --------------------------------------------------------------------------------------------
        try(PreparedStatement st = conn.prepareStatement("SELECT * FROM BasicInformation WHERE idnr=?");){
            st.setString(1, student);

            ResultSet rs = st.executeQuery();
            if(!rs.next()){
                return "{\"success\":false, \"error\":\"No such student\"}";
            }
            result.put("student", rs.getString("idnr"));
            result.put("name", rs.getString("name"));
            result.put("login", rs.getString("login"));
            result.put("program", rs.getString("program"));
            result.put("branch", rs.getString("branch"));
        }
        catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
        //Finished -----------------------------------------------------------------------------------------------------
        try(PreparedStatement st = conn.prepareStatement("SELECT * FROM Taken LEFT OUTER JOIN Courses ON " +
                "Taken.course = Courses.code AND Taken.student =?");) {
            st.setString(1, student);

            JSONArray finished = new JSONArray();
            ResultSet rs = st.executeQuery();
            while (rs.next()) {
                if(rs.getString("code") != null){
                JSONObject course = new JSONObject();
                course.put("course", rs.getString("name"));
                course.put("code", rs.getString("code"));
                course.put("credits", rs.getFloat("credits"));
                course.put("grade", rs.getString("grade"));
                finished.put(course);
                }
            }
            result.put("finished", finished);
        }
        catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
        //Registered ---------------------------------------------------------------------------------------------------
        try(PreparedStatement st = conn.prepareStatement(
                "SELECT Courses.name, Courses.code, status, place FROM Courses LEFT OUTER JOIN " +
                        "Registrations ON Courses.code = Registrations.course AND student=? RIGHT OUTER JOIN CourseQueuePositions ON " +
                        "Registrations.student = CourseQueuePositions.student AND Registrations.course = CourseQueuePositions.course");){
            st.setString(1, student);
            JSONArray registered = new JSONArray();

            ResultSet rs = st.executeQuery();
            while (rs.next()) {
                if(rs.getString("status") != null){
                    JSONObject items = new JSONObject();
                    items.put("course", rs.getString("name"));
                    items.put("code", rs.getString("code"));
                    items.put("status", rs.getString("status"));
                    if(rs.getString("place") != null){
                        items.put("position", rs.getInt("place"));
                    }
                    registered.put(items);
                }
            }
            result.put("registered", registered);
        }
        catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
        try(PreparedStatement st = conn.prepareStatement("SELECT * FROM PathToGraduation WHERE student=?");){
            st.setString(1, student);
            ResultSet rs = st.executeQuery();
            if(!rs.next()){
                return "{\"success\":false, \"error\":\"No such student\"}";
            }
            result.put("seminarCourses", rs.getInt("seminarcourses"));
            result.put("mathCredits", rs.getFloat("mathcredits"));
            result.put("researchCredits", rs.getFloat("researchcredits"));
            result.put("totalCredits", rs.getFloat("totalcredits"));
            result.put("canGraduate", rs.getBoolean("qualified"));

        }
        catch (SQLException e) {
            return "{\"success\":false, \"error\":\""+getError(e)+"\"}";
        }
        return result.toString();
    }

    // This is a hack to turn an SQLException into a JSON string error message. No need to change.
    public static String getError(SQLException e){
       String message = e.getMessage();
       int ix = message.indexOf('\n');
       if (ix > 0) message = message.substring(0, ix);
       message = message.replace("\"","\\\"");
       return message;
    }
}