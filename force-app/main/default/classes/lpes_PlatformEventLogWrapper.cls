public inherited sharing class lpes_PlatformEventLogWrapper 
{
    
    public set<string> replayIds {get; private set;}
    public map<string,platform_event_log__c> platformEventLogs {get; private set;}
    public map<string,list<platform_event_log_field__c>> platformEventLogFields {get; private set;}

    public lpes_PlatformEventLogWrapper(map<string,platform_event_log__c> logs, map<string,list<platform_event_log_field__c>> fields) 
    {
        if (logs==null || fields==null)
            throw new PlatformEventLogWrapperException(lpes_ExceptionMessageWrapper.INVALID_PARAMETERS_MESSAGE);

        this.replayIds = logs.keyset();
        this.platformEventLogs = logs;
        this.platformEventLogFields = fields;
    }


    public class PlatformEventLogWrapperException extends Exception {}
}