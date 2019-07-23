// EXAMPLE CONCRETE CONFIGURATION 

/* 
* This class extends the LogPlatformEventsConfiguration abstract class
* and populates the protected attributes based on values passed to its constructor
*
* Does not override any methods or use any attributes outside of the ones it inherits.
* This is probably the simplest example of a class that supports dynamic run time configurations
*/

public class lpes_ExampleConcreteConfiguration extends lpes_LogPlatformEventsConfiguration {

    public lpes_ExampleConcreteConfiguration(
        boolean logRecords, boolean debug, boolean logPayload,
        string userField, list<string> logFields, string nameFormat
    )
    {
        this.isLogRecords = logRecords;
        this.isDebug = debug;
        this.isLogFullPayload = logPayload;
        this.publishingUserField = userField;
        this.fieldsToLog = logFields;
        this.nameFormatPlaceholder = nameFormat;
    }

}
