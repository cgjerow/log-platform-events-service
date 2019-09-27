// EXAMPLE CONCRETE CONFIGURATION 

/* 
* This class extends the LogPlatformEventsConfiguration abstract class
* and populates the protected attributes based on values passed to its constructor
*
* Does not override any methods or use any attributes outside of the ones it inherits.
* This is probably the simplest example of a class that supports dynamic run time configurations
*/

public inherited sharing class ConcreteLogPlatformEventsConfiguration extends lpes_LogPlatformEventsConfiguration {

    public ConcreteLogPlatformEventsConfiguration(
        boolean logPayload, string userField, 
        list<string> logFields, string nameFormat
    )
    {
        this.isLogFullPayload = logPayload;
        this.publishingUserField = userField;
        this.fieldsToLog = logFields;
        this.nameFormatPlaceholder = nameFormat;
    }

}