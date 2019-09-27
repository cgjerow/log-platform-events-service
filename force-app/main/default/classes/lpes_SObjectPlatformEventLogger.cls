public inherited sharing class lpes_SObjectPlatformEventLogger implements lpes_IPlatformEventLogger 
{

    private lpes_PlatformEventLogWrapper logContainer;
    private boolean isLogRecords;
    private boolean isDebug; 

    public lpes_SObjectPlatformEventLogger(boolean isLogRecords, boolean isDebug) 
    {
        this.isLogRecords = isLogRecords;
        this.isDebug = isDebug;
    }


    public void logEvents(lpes_PlatformEventLogWrapper logContainer)
    {
        this.logContainer = logContainer;
        if (this.isLogRecords) 
            this.insertPlatformEventLogs();

        if (this.isDebug)
            this.debugPlatformEventLogs();
    }


    private void insertPlatformEventLogs()
    {
        try 
        {
            if (test.isRunningTest() && !lpes_SObjectPlatformEventLoggerTest.getPerformDML())
                lpes_SObjectPlatformEventLoggerTest.setInsertedLogs(this.logContainer.platformEventLogs.values());
            else if (this.logContainer.platformEventLogs.values().size()>0)
                insert this.logContainer.platformEventLogs.values();

            // attach field logs to parent log recor and add all to list for insert
            list<platform_event_log_field__c> fieldlogs = new list<platform_event_log_field__c>();
            for (platform_event_log__c log : this.logContainer.platformEventLogs.values())
            {
                for (platform_event_log_field__c field : this.logContainer.platformEventLogFields.get(log.replayid__c))
                {
                    field.platform_event_log__c = log.id;
                    fieldlogs.add(field);
                }
            }

            
            if (test.isRunningTest() && !lpes_SObjectPlatformEventLoggerTest.getPerformDML())
                lpes_SObjectPlatformEventLoggerTest.setInsertedLogFields(fieldLogs);
            else if (fieldlogs.size()>0)
                insert fieldlogs;
        }
        catch(exception e)
        {
            throw new SObjectPlatformEventLoggerException('Error Logging Platform Events: '+e.getMessage(),e);
        }
    }


    private void debugPlatformEventLogs()
    {
        for (platform_event_log__c log : this.logContainer.platformEventLogs.values())
            System.debug(System.LoggingLevel.FINE, log);
    }

    public class SObjectPlatformEventLoggerException extends Exception {}

}