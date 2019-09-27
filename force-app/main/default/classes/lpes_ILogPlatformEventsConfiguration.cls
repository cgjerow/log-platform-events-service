public interface lpes_ILogPlatformEventsConfiguration 
{

    boolean getIsLogFullPayload();

    string getPublishingUserField();

    list<string> getFieldsToLog();

    // {0} replaced by ReplayId, {1} replaced by Platform Event Type (based on getDescribeCall at run time)
    string getNameFormatPlaceholder();

}