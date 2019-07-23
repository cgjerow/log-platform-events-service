global interface lpes_ILogPlatformEventsConfiguration 
{

    boolean getIsDebug();

    boolean getIsLogRecords();

    boolean getIsLogFullPayload();

    string getPublishingUserField();

    list<string> getFieldsToLog();

    // {0} replaced by ReplayId
    string getNameFormatPlaceholder();

}