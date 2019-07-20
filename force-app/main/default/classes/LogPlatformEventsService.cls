global without sharing class LogPlatformEventsService
{

    private final sobject[] newlist;
    private final platform_event_log_configuration__mdt config;
    private platform_event_log__c[] logs;
    private map<string,list<platform_event_log_field__c>> replayidToFieldLogs;
    private list<platform_event_log_field__c> fieldlogs;

    @testvisible private static final string EMPTY_EVENT_LIST_MESSAGE;
    @testvisible private static final string DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE;
    @testvisible private static final string NO_EVENT_CONFIGURATIONS_MESSAGE;
    @testvisible private static final string JSON_PARSE_ERROR_MESSAGE;
    @testvisible private static final string INVALID_EVENT_FIELD_MESSAGE;
    @testvisible private static final string DISABLED_PAYLOAD_LOG_MESSSAGE;

    static 
    {
        // could make these messages configurable with custom setting or alternative feature
        EMPTY_EVENT_LIST_MESSAGE = 'EMPTY_EVENT_LIST: The platform event list provided was empty';
        DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE = 'DUPLICATE_PLATFORM_EVENT_CONFIGURATIONS: Multiple Platform Event Log Configuration metadata records are active for ';
        NO_EVENT_CONFIGURATIONS_MESSAGE = 'NO_PLATFORM_EVENT_CONFIGURATIONS: No Platform Event Log Configuration metadata record exists for ';
        JSON_PARSE_ERROR_MESSAGE = 'JSON_PARSE_ERROR: Could not parse JSON for this field. Review Payload on Platform Event Log.';
        INVALID_EVENT_FIELD_MESSAGE = 'INVALID_EVENT_FIELD: The following field does not exist on ';
        DISABLED_PAYLOAD_LOG_MESSSAGE = 'DISABLED_PAYLOAD_LOG: Payload logging disabled for active configuration. Related Platform Event Log Fields are still generated.';
    }

    global LogPlatformEventsService(list<sobject> newlist)
    {
        // list is requried for processing
        if (newlist==null || newlist.size()==0)
            throw new PlatformEventLogException(EMPTY_EVENT_LIST_MESSAGE);

        String eventType = String.valueOf(newlist[0].getSObjectType());

        platform_event_log_configuration__mdt[] eventLogConfigurations =
                                            [
                                                select masterlabel,
                                                is_active__c,
                                                enable_debug__c,
                                                enable_log_records__c,
                                                enable_full_payload_log__c,
                                                field_logs__c,
                                                Platform_Event_Type_API_Name__c
                                                from platform_event_log_configuration__mdt
                                                where Platform_Event_Type_API_Name__c=:eventType
                                            ];

        // Use mocks if running test
        if (test.isRunningTest())
            eventLogConfigurations = LogPlatformEventsServiceTest.getEventConfigurations();



        // At least one configuration is required, otherwise throw exception to alert admin
        if (eventLogConfigurations.size()==0)
            throw new PlatformEventLogException(NO_EVENT_CONFIGURATIONS_MESSAGE+eventType);

        // Multiple *active* configurations also throw exception to alert admin.
        // No exception is thrown if all are inactive.
        // In this case we assume they have been intentionally disabled.
        integer activeConfigurations = 0;
        for (platform_event_log_configuration__mdt eventConfig : eventLogConfigurations)
        {
            if (eventConfig.is_active__c)
            {
                activeConfigurations+=1;
                if (activeConfigurations>1)
                    throw new PlatformEventLogException(DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE+eventType);

                this.config = eventConfig;
            }
        }

        // After confirming valid list and configuration initialize object variables
        this.newlist = newlist;
        buildLogList();
    }



    global void logEvents()
    {
        // return if no active configurations exist
        if (config==null || !config.is_active__c)
            return;

        if (config.enable_log_records__c)
            this.insertPlatformEventLogs();

        if (config.enable_debug__c)
            this.debugPlatformEventLogs();
    }



    private void buildLogList()
    {
        // return if no active configuration exists
        if (this.config==null || !this.config.is_active__c)
            return;

        this.logs = new list<platform_event_log__c>();
        this.replayidToFieldLogs = new map<string,list<platform_event_log_field__c>>();
        list<string> fieldsToLog = this.config.field_logs__c.split(',');


        // build platform_event_log and platform_event_log_field records
        for (SObject event : newlist)
        {
            this.logs.add(new platform_event_log__c(
                name = this.config.Platform_Event_Type_API_Name__c+' - '+event.get('replayid'),
                replayid__c = (string)event.get('replayid'),
                platform_event_type__c = this.config.Platform_Event_Type_API_Name__c,
                platform_event_payload__c = config.enable_full_payload_log__c ? 
                                            String.valueOf(event) : DISABLED_PAYLOAD_LOG_MESSSAGE
            ));

            // iterate through all fields to log
            platform_event_log_field__c[] fields = new list<platform_event_log_field__c>();
            for (string field : fieldsToLog)
            {
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
                                value = INVALID_EVENT_FIELD_MESSAGE + this.config.Platform_Event_Type_API_Name__c + ': ' + field;
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

                fields.add(new platform_event_log_field__c(
                    name = field+' - '+event.get('replayid'),
                    field_name__c = field,
                    field_value__c = value
                ));
            }
            this.replayidToFieldLogs.put((string)event.get('replayid'),fields);
        }

    }



    private void insertPlatformEventLogs()
    {
        if (this.logs.size()>0)
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

        if (this.fieldlogs.size()>0)
            insert this.fieldlogs;
    }

    private void debugPlatformEventLogs()
    {
        for (platform_event_log__c log : this.logs)
            System.debug(System.LoggingLevel.FINE, log);
    }

    global class PlatformEventLogException extends Exception {}
}
