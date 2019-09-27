@isTest public class CustomMetadataEventLogConfigurationTest {
    
    private static final integer count;
    private static list<Platform_Event_Log_Configuration__mdt> eventConfigurations;
    private static exception logException;
    private static CustomMetadataEventLogConfiguration config;
    private static string eventType;
    private static string fieldName;

    static 
    {
        count = 250;
        eventType = 'LogPlatformEventsServiceTestEvent__e';
        eventConfigurations = new List<Platform_Event_Log_Configuration__mdt>();
        fieldName = 'Platform_Event_Type_API_Name__c';
    }




    /***************************************************
                   FAKE DATA GENERATORS
    ****************************************************/

    /* 
    * Leveraging the JSON.deserialize() method allows us to work 
    * around "Field Not Writable" limitations for mock data
    */

    private static void createPlatformEventConfigurationRecords(integer count, string fieldsList)
    {
        for (integer i=0;i<count;i++) 
        {
            eventConfigurations.add((Platform_Event_Log_Configuration__mdt)JSON.deserialize('{' +
                '"DeveloperName":"EVENT LOG CONFIG '+i+'",' +
                '"MasterLabel":"EVENT LOG CONFIG '+i+'",' +
                '"Is_Active__c":true,' +
                '"Enable_Debug__c":true,' +
                '"Enable_Log_Records__c":true,' +
                '"Enable_Full_Payload_Log__c":true,' +
                '"Publishing_User_Field__c":"JsonTextField__c.Publishing_User__c",' +
                '"Field_Logs__c":"'+fieldsList+'",' +
                '"Platform_Event_Type_API_Name__c":"'+eventType+'"' +
                '}',
                Platform_Event_Log_Configuration__mdt.class));
        }
    }    




    /***************************************************
                   PUBLIC GETTER METHODS
    ****************************************************/

    public static list<Platform_Event_Log_Configuration__mdt> getEventConfigurations()
    {
        return eventConfigurations;
    }




    /***************************************************
                  PRIVATE HELPER METHODS
    ****************************************************/


    // All tests are running the same core functionality, just with different config and events
    // Pulled this out to avoid duplication across all tests
    private static void doTest()
    {
        config = new CustomMetadataEventLogConfiguration(fieldName, eventType);
    }

    private static void assertValidConfigurationGetResponses()
    {
        System.assert(config.isDebug);
        System.assert(config.getIsLogFullPayload());
        System.assert(config.isLogRecords);
        System.assertEquals('JsonTextField__c.Publishing_User__c',config.getPublishingUserField());
        System.assertEquals('{1} - {0}',config.getNameFormatPlaceholder());
        System.assertEquals(new list<string>{'JsonTextField__c'}, config.getFieldsToLog());
    }

    private static void assertDefaultGetResponses()
    {
        System.assert(!config.isDebug);
        System.assert(!config.getIsLogFullPayload());
        System.assert(!config.isLogRecords);
        System.assertEquals(null,config.getPublishingUserField());
        System.assertEquals('{1} - {0}',config.getNameFormatPlaceholder());
        System.assertEquals(new list<string>(),config.getFieldsToLog());
    }
    



    /***************************************************
                        UNIT TESTS
    ****************************************************/

    @isTest static void noConfigurationsDefined() 
    { 
        test.startTest();
        try {
            doTest();
        } catch (exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        test.stopTest();

        System.assert(logException!=null);
        System.assert(logException.getMessage().contains(CustomMetadataEventLogConfiguration.NO_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
        System.assertEquals(null,config);
    }

    @isTest static void multipleActiveConfigurations() 
    {
        createPlatformEventConfigurationRecords(3,'JsonTextField__c');

        test.startTest();
        try{
            doTest();
        } catch (exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        test.stopTest();

        System.assert(logException!=null);
        System.assert(logException.getMessage().contains(CustomMetadataEventLogConfiguration.DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
        System.assertEquals(null,config);
    }

    @isTest static void activeAndInactiveConfigurationsPassing() 
    {
        createPlatformEventConfigurationRecords(3,'JsonTextField__c');
        eventConfigurations[0].is_active__c=false;
        eventConfigurations[2].is_active__c=false;

        test.startTest();
        doTest();
        test.stopTest();

        assertValidConfigurationGetResponses();
    }

    @isTest static void activeAndInactiveConfigurationsFailing() 
    {
        createPlatformEventConfigurationRecords(3,'JsonTextField__c');
        eventConfigurations[0].is_active__c=false;

        test.startTest();
        try {
            doTest();
        } catch (exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        test.stopTest();

        System.assert(logException!=null);
        System.assert(logException.getMessage().contains(CustomMetadataEventLogConfiguration.DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
        System.assertEquals(null,config);
    }


    @isTest static void dynamicSoqlException() 
    {
        fieldName = 'failSOQL';

        test.startTest();
        try {
            doTest();
        } catch (exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        test.stopTest();

        System.assert(logException!=null);
        System.assertEquals(CustomMetadataEventLogConfiguration.DYNAMIC_SOQL_ERROR_MESSAGE,logException.getMessage());
    }


    @istest static void useConstructorThatTakesCustomMetadata()
    {
        createPlatformEventConfigurationRecords(1, 'JsonTextField__c');

        test.startTest();
        config = new CustomMetadataEventLogConfiguration(eventConfigurations[0]);
        test.stopTest();

        System.assertNotEquals(null, config);
        assertValidConfigurationGetResponses();
    }

    
    @istest static void useConstructorThatTakesCustomMetadataWithEmptyRecord()
    {
        test.startTest();
        config = new CustomMetadataEventLogConfiguration(new platform_event_log_configuration__mdt());
        test.stopTest();

        assertDefaultGetResponses();
    }


}