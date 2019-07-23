public with sharing class lpes_CustomMetadataConfiguration implements lpes_ILogPlatformEventsConfiguration 
{

    private boolean isLogRecords = false;
    private boolean isDebug = false;
    private boolean isLogFullPayload = false;
    private string publishingUserField = '';
    private list<string> fieldsToLog = new list<string>();
    private string nameFormatPlaceholder = '';

    private final platform_event_log_configuration__mdt config;
    private final string platformEventType;

    @testvisible private static final string DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE;
    @testvisible private static final string NO_EVENT_CONFIGURATIONS_MESSAGE;

    static 
    {
        DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE = 'DUPLICATE_PLATFORM_EVENT_CONFIGURATIONS: '+Label.lpes_duplicate_event_configurations_message;
        NO_EVENT_CONFIGURATIONS_MESSAGE = 'NO_PLATFORM_EVENT_CONFIGURATIONS: '+Label.lpes_no_event_configurations_message;
    }

    public lpes_CustomMetadataConfiguration(string platformEventType) {

        this.platformEventType = platformEventType;
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
                                        where Platform_Event_Type_API_Name__c=:platformEventType
                                    ];

        // Use mocks if running test
        if (test.isRunningTest())
            eventLogConfigurations = lpes_CustomMetadataConfigurationTest.getEventConfigurations();



        // At least one configuration is required, otherwise throw exception to alert admin
        if (eventLogConfigurations.size()==0)
            throw new lpes_CustomMetadataConfigurationException(String.format(NO_EVENT_CONFIGURATIONS_MESSAGE,new list<string>{platformEventType}));

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
                    throw new lpes_CustomMetadataConfigurationException(String.format(DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE,new list<string>{platformEventType}));

                this.config = eventConfig;
            }
        }

        if (this.config!=null)
        {
            this.isDebug = this.config.enable_debug__c;
            this.isLogRecords = this.config.enable_log_records__c;
            this.isLogFullPayload = this.config.enable_full_payload_log__c;
            this.publishingUserField = this.config.publishing_user_field__c;
            this.fieldsToLog = this.config.field_logs__c.split(',');
        }
        this.nameFormatPlaceholder = this.platformEventType + ' - {0}';
    }

    public boolean getIsDebug()
    {
        return this.isDebug;
    }

    public boolean getIsLogRecords()
    {
        return this.isLogRecords;
    }

    public boolean getIsLogFullPayload()
    {
        return this.isLogFullPayload;
    }

    public string getPublishingUserField()
    {
        return this.publishingUserField;
    }

    public list<string> getFieldsToLog()
    {
        return this.fieldsToLog;
    }

    // {0} replaced by ReplayId
    public string getNameFormatPlaceholder()
    {
        return this.nameFormatPlaceholder;
    }

    public class lpes_CustomMetadataConfigurationException extends Exception {}
}