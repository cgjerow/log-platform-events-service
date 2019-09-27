public inherited sharing class CustomMetadataEventLogConfiguration extends lpes_LogPlatformEventsConfiguration  
{

    private final platform_event_log_configuration__mdt config;
    private final string platformEventType;
    public boolean isDebug {get; private set;}
    public boolean isLogRecords {get; private set;}

    @testvisible private static final string DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE;
    @testvisible private static final string NO_EVENT_CONFIGURATIONS_MESSAGE;
    @testvisible private static final string DYNAMIC_SOQL_ERROR_MESSAGE;


    static 
    {
        DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE = 'DUPLICATE_PLATFORM_EVENT_CONFIGURATIONS: '+Label.lpes_duplicate_event_configurations_message;
        NO_EVENT_CONFIGURATIONS_MESSAGE = 'NO_PLATFORM_EVENT_CONFIGURATIONS: '+Label.lpes_no_event_configurations_message;
        DYNAMIC_SOQL_ERROR_MESSAGE = 'QUERY_EXCEPTION: Error querying Platform_Event_Log_Configuration__mdt custom metadata record';
    }

    public CustomMetadataEventLogConfiguration(string fieldName, string fieldValue) 
    {
        platform_event_log_configuration__mdt[] eventLogConfigurations;
        this.platformEventType = platformEventType;
        string query = 'select is_active__c, ' + 
                       ' enable_debug__c, ' + 
                       ' enable_log_records__c, ' + 
                       ' enable_full_payload_log__c, ' + 
                       ' field_logs__c, ' +
                       ' publishing_user_field__c, ' +
                       ' platform_event_type_api_name__c ' +
                       ' from platform_event_log_configuration__mdt where {0}=:fieldValue';
            
        try {
            eventLogConfigurations = Database.query(String.format(query, new list<string>{fieldName}));
        } catch(exception e) {
            throw new CustomMetadataEventLogConfigurationException(DYNAMIC_SOQL_ERROR_MESSAGE, e);
        }

        // Use mocks if running test
        if (test.isRunningTest())
            eventLogConfigurations = CustomMetadataEventLogConfigurationTest.getEventConfigurations();



        // At least one configuration is required, otherwise throw exception to alert admin
        if (eventLogConfigurations.size()==0)
            throw new CustomMetadataEventLogConfigurationException(String.format(NO_EVENT_CONFIGURATIONS_MESSAGE,new list<string>{platformEventType}));

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
                    throw new CustomMetadataEventLogConfigurationException(String.format(DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE,new list<string>{platformEventType}));

                this.config = eventConfig;
            }
        }

        mapMetadataToMemberVariables();
    }

    public CustomMetadataEventLogConfiguration(platform_event_log_configuration__mdt config)
    {
        this.config = config;
        mapMetadataToMemberVariables();
    }

    private void mapMetadataToMemberVariables()
    {
        if (this.config!=null)
        {
            this.isDebug = this.config.enable_debug__c;
            this.isLogRecords = this.config.enable_log_records__c;
            this.isLogFullPayload = this.config.enable_full_payload_log__c;
            this.publishingUserField = this.config.publishing_user_field__c;
            this.fieldsToLog = this.config.field_logs__c!=null ? this.config.field_logs__c.split(',') : new list<string>();
        }
        this.nameFormatPlaceholder = '{1} - {0}';
    }

    public class CustomMetadataEventLogConfigurationException extends Exception {}
}