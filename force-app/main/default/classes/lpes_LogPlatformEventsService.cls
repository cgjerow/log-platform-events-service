public without sharing class lpes_LogPlatformEventsService
{

    private final sobject[] newlist;
    private final lpes_ILogPlatformEventsConfiguration config;
    private platform_event_log__c[] logs;
    private map<string,list<platform_event_log_field__c>> replayidToFieldLogs;
    private list<platform_event_log_field__c> fieldlogs;
    protected map<string,fieldsetting> fieldPathToSettings;

    @testvisible private static final string JSON_PARSE_ERROR_MESSAGE;
    @testvisible private static final string INVALID_EVENT_FIELD_MESSAGE;
    @testvisible private static final string DISABLED_PAYLOAD_LOG_MESSSAGE;

    static 
    {
        JSON_PARSE_ERROR_MESSAGE = 'JSON_PARSE_ERROR: '+Label.lpes_json_parse_error_message;
        INVALID_EVENT_FIELD_MESSAGE = 'INVALID_EVENT_FIELD: '+Label.lpes_invalid_event_field_message;
        DISABLED_PAYLOAD_LOG_MESSSAGE = 'DISABLED_PAYLOAD_LOG: '+Label.lpes_disabled_payload_log_message;
    }

    public lpes_LogPlatformEventsService(list<sobject> newlist, lpes_ILogPlatformEventsConfiguration config)
    {
        this.debugLimits('Start Constructor');
        // initialize log records for debug & insert
        this.config = config;
        this.newlist = newlist;
        
        buildLogList();
        this.debugLimits('End Constructor');
    }



    public void logEvents()
    {
        this.debugLimits('Start Log Events');

        if (this.config.getIsLogRecords())
            this.insertPlatformEventLogs();

        if (this.config.getIsDebug())
            this.debugPlatformEventLogs();

        this.debugLimits('End Log Events');
    }



    private void buildLogList()
    {
        this.debugLimits('Start Build Log List');

        this.logs = new list<platform_event_log__c>();
        this.replayidToFieldLogs = new map<string,list<platform_event_log_field__c>>();
        list<string> fieldsToLog = this.config.getFieldsToLog();
        this.fieldPathToSettings = new map<string,fieldsetting>();


        for (string fieldPath : fieldsToLog)
        {
            if (!String.isBlank(fieldPath))
                this.setLogField(fieldPath);
        }

        this.setPublishingUserField(this.config.getPublishingUserField());


        // build platform_event_log and platform_event_log_field records
        for (SObject event : this.newlist)
        {
            id publishingUser;
            string platformEventType = event.getSobjectType().getDescribe().getName(); // maybe create a map to minimize repeated describe calls
            platform_event_log_field__c[] fields = new list<platform_event_log_field__c>();

            // iterate through all fields to log
            for (FieldSetting fs : fieldPathToSettings.values())
            {
                System.debug('FIELD SETTING : '+fs);
                string field = fs.fieldPath;
                string value;
                map<string,object> nestedObj;

                // support dot notation for valid json text fields on the platform event
                // iterate through fields in field path to get final value
                for (string attribute : field.split('\\.'))
                {
                    try {
                        // fields in json object stored in the platform event field
                        if (nestedObj!=null)
                        {
                            value = String.valueOf(nestedObj.get(attribute));
                            if (nestedObj.get(attribute)==null || nestedObj.get(attribute) instanceof map<string,object>)
                                nestedObj = (map<string,object>)nestedObj.get(attribute);
                        }

                        // platform event field (first field in each field path)
                        else
                        {
                            try {
                                value =  String.valueOf(event.get(attribute));
                            } catch(SObjectException e) {
                                System.debug(e.getMessage());
                                System.debug(INVALID_EVENT_FIELD_MESSAGE);
                                value = String.format(INVALID_EVENT_FIELD_MESSAGE, new list<string>{field,platformEventType});
                                break;
                            }
                            
                            // Only parse nestedObj for fields using dot notation
                            if (field.contains('.'))
                                nestedObj = (map<string,object>)JSON.deserializeUntyped(value);
                        }
                    } catch(exception e) {
                        System.debug(e.getMessage());
                        System.debug(JSON_PARSE_ERROR_MESSAGE);
                        value = JSON_PARSE_ERROR_MESSAGE;
                        break;
                    }

                    // if part way through field path and no value is returned, break loop
                    if (nestedObj==null)
                        break;
                }

                // allow admin to configure what field to use to populate publishing_user__c
                if (fs.isPublishingUserField)
                    publishingUser = this.getUserId(value);

                if (fs.isLogField)
                    fields.add(new platform_event_log_field__c(
                        name = field+' - '+event.get('replayid'),
                        field_name__c = field,
                        field_value__c = value
                    ));
            }

            
            this.logs.add(new platform_event_log__c(
                name = String.format(this.config.getNameFormatPlaceholder(),
                                     new list<string>{(string)event.get('replayid')}),
                replayid__c = (string)event.get('replayid'),                
                platform_event_type__c = platformEventType,
                publishing_user__c = (id)publishingUser,
                platform_event_payload__c = this.config.getIsLogFullPayload() ? 
                                            String.valueOf(event) : DISABLED_PAYLOAD_LOG_MESSSAGE
            ));

            this.replayidToFieldLogs.put((string)event.get('replayid'),fields);

            // reset tmp fields
            publishingUser = null;
        }

        this.debugLimits('End Build Log List');
    }



    private void insertPlatformEventLogs()
    {
        this.debugLimits('Start Insert Platform Event Logs');

        if (test.isRunningTest() && !lpes_LogPlatformEventsServiceTest.getPerformDML())
            lpes_LogPlatformEventsServiceTest.setInsertedLogs(this.logs);
        else if (this.logs.size()>0)
            insert this.logs;

        // attach field logs to parent log recor and add all to list for insert
        this.fieldlogs = new list<platform_event_log_field__c>();
        for (platform_event_log__c log : this.logs)
        {
            for (platform_event_log_field__c field : replayidToFieldLogs.get(log.replayid__c))
            {
                field.platform_event_log__c = log.id;
                this.fieldlogs.add(field);
            }
        }

        
        if (test.isRunningTest() && !lpes_LogPlatformEventsServiceTest.getPerformDML())
            lpes_LogPlatformEventsServiceTest.setInsertedLogFields(this.fieldLogs);
        else if (this.fieldlogs.size()>0)
            insert this.fieldlogs;

        this.debugLimits('End Insert Platform Event Logs');
    }

    private void debugPlatformEventLogs()
    {
        for (platform_event_log__c log : this.logs)
            System.debug(System.LoggingLevel.FINE, log);
    }

    // Validate id string and return valid id or null
    private id getUserId(string idstring)
    {
        try {
            return ((id)idstring).getSobjectType().getDescribe().getName()=='User' ? idstring : null;
        } catch (exception e) {
            System.debug('Invalid User Id Value');
            System.debug(e.getMessage());
            return null;
        }
    }

    private void setPublishingUserField(string fieldPath)
    {
        if (String.isBlank(fieldPath))
            fieldPath = 'CreatedById';

        FieldSetting fieldSetting = getFieldSetting(fieldPath);
        fieldSetting.setPublishingUserField();
        this.fieldPathToSettings.put(fieldPath,fieldSetting);
    }

    private void setLogField(string fieldPath)
    {
        if (String.isBlank(fieldPath))
            return;

        FieldSetting fieldSetting = getFieldSetting(fieldPath);
        fieldSetting.setLogField();
        this.fieldPathToSettings.put(fieldPath,fieldSetting);
    }

    private FieldSetting getFieldSetting(string fieldPath)
    {
        return this.fieldPathToSettings.get(fieldPath)!=null ? this.fieldPathToSettings.get(fieldPath) : new FieldSetting(fieldPath);
    }

    // can uncomment or update for logging throughout service
    private void debugLimits(string message)
    {
        //System.debug('lpes_LogPlatformEventsService Limits: ' + message +
        //            '\n*** CPU TIME ***: ' + Limits.getCpuTime());
    }


    private class FieldSetting
    {
        private final string fieldPath;
        private boolean isPublishingUserField = false;
        private boolean isLogField = false;

        private FieldSetting(string fieldPath)
        {
            this.fieldPath = fieldPath;
        }

        private void setLogField()
        {
            this.isLogField=true;
        }

        private void setPublishingUserField()
        {
            this.isPublishingUserField=true;
        }
    }

    public class PlatformEventLogException extends Exception {}
}