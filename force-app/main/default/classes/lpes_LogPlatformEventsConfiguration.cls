public abstract class lpes_LogPlatformEventsConfiguration implements lpes_ILogPlatformEventsConfiguration 
{
    
    protected boolean isLogFullPayload = false;
    protected string publishingUserField = '';
    protected list<string> fieldsToLog = new list<string>();
    protected string nameFormatPlaceholder = '';
    

    public virtual boolean getIsLogFullPayload()
    {
        return this.isLogFullPayload;
    }

    public virtual string getPublishingUserField()
    {
        return this.publishingUserField;
    }

    public virtual list<string> getFieldsToLog()
    {
        return this.fieldsToLog;
    }

    // {0} replaced by ReplayId, {1} replaced by Platform Event Type (based on getDescribeCall at run time)
    public virtual string getNameFormatPlaceholder()
    {
        return this.nameFormatPlaceholder;
    }
}