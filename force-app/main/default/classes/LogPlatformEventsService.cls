global without sharing class LogPlatformEventsService
{

    private final sobject[] newlist;
    private final platform_event_log_configuration__mdt config;
    private platform_event_log__c[] logs;
    private map<string,list<platform_event_log_field__c>> replayidToFieldLogs;
    private list<platform_event_log_field__c> fieldlogs;
    protected map<string,fieldsetting> fieldPathToSettings;

    @testvisible private static final string EMPTY_EVENT_LIST_MESSAGE;
    @testvisible private static final string DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE;
    @testvisible private static final string NO_EVENT_CONFIGURATIONS_MESSAGE;
    @testvisible private static final string JSON_PARSE_ERROR_MESSAGE;
    @testvisible private static final string INVALID_EVENT_FIELD_MESSAGE;
    @testvisible private static final string DISABLED_PAYLOAD_LOG_MESSSAGE;

    static 
    {
        EMPTY_EVENT_LIST_MESSAGE = 'EMPTY_EVENT_LIST: '+Label.lpes_empty_event_list_message;
        DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE = 'DUPLICATE_PLATFORM_EVENT_CONFIGURATIONS: '+Label.lpes_duplicate_event_configurations_message;
        NO_EVENT_CONFIGURATIONS_MESSAGE = 'NO_PLATFORM_EVENT_CONFIGURATIONS: '+Label.lpes_no_event_configurations_message;
        JSON_PARSE_ERROR_MESSAGE = 'JSON_PARSE_ERROR: '+Label.lpes_json_parse_error_message;
        INVALID_EVENT_FIELD_MESSAGE = 'INVALID_EVENT_FIELD: '+Label.lpes_invalid_event_field_message;
        DISABLED_PAYLOAD_LOG_MESSSAGE = 'DISABLED_PAYLOAD_LOG: '+Label.lpes_disabled_payload_log_message;
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
                                                publishing_user_field__c,
                                                Platform_Event_Type_API_Name__c
                                                from platform_event_log_configuration__mdt
                                                where Platform_Event_Type_API_Name__c=:eventType
                                            ];

        // Use mocks if running test
        if (test.isRunningTest())
            eventLogConfigurations = LogPlatformEventsServiceTest.getEventConfigurations();



        // At least one configuration is required, otherwise throw exception to alert admin
        if (eventLogConfigurations.size()==0)
            throw new PlatformEventLogException(String.format(NO_EVENT_CONFIGURATIONS_MESSAGE,new list<string>{eventType}));

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
                    throw new PlatformEventLogException(String.format(DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE,new list<string>{eventType}));

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

        id pubishingUser;
        this.logs = new list<platform_event_log__c>();
        this.replayidToFieldLogs = new map<string,list<platform_event_log_field__c>>();
        list<string> fieldsToLog = this.config.field_logs__c.split(',');
        this.fieldPathToSettings = new map<string,fieldsetting>();


        for (string fieldPath : fieldsToLog)
        {
            if (!String.isBlank(fieldPath))
                this.setLogField(fieldPath);
        }

        if (!String.isBlank(this.config.publishing_user_field__c))
            this.setPublishingUserField(this.config.publishing_user_field__c);


        // build platform_event_log and platform_event_log_field records
        for (SObject event : this.newlist)
        {
            id publishingUser;
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
                                value = String.format(INVALID_EVENT_FIELD_MESSAGE, new list<string>{field,this.config.Platform_Event_Type_API_Name__c});
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
                name = this.config.Platform_Event_Type_API_Name__c+' - '+event.get('replayid'),
                replayid__c = (string)event.get('replayid'),                
                platform_event_type__c = this.config.Platform_Event_Type_API_Name__c,
                publishing_user__c = (id) ( this.config.publishing_user_field__c==null ? 
                                            event.get('createdbyid') : publishingUser ),
                platform_event_payload__c = config.enable_full_payload_log__c ? 
                                            String.valueOf(event) : DISABLED_PAYLOAD_LOG_MESSSAGE
            ));

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
            return;

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

    global class PlatformEventLogException extends Exception {}
}
