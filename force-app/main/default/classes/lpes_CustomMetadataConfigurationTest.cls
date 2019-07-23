@isTest public class lpes_CustomMetadataConfigurationTest {
    
    private static final integer count;
    private static list<Platform_Event_Log_Configuration__mdt> eventConfigurations;
    private static exception logException;
    private static lpes_CustomMetadataConfiguration config;
    private static string eventType;

    static 
    {
        count = 250;
        eventType = 'LogPlatformEventsServiceTestEvent__e';
        eventConfigurations = new List<Platform_Event_Log_Configuration__mdt>();
    }


    /** PRIVATE HELPER METHODS **/


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

    public static list<Platform_Event_Log_Configuration__mdt> getEventConfigurations()
    {
        return eventConfigurations;
    }


    // All tests are running the same core functionality, just with different config and events
    // Pulled this out to avoid duplication across all tests
    private static void doTest()
    {
        try {
            config = new lpes_CustomMetadataConfiguration(eventType);
        } catch (exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }

    private static void assertDefaultGetResponses()
    {
        System.assertEquals(null, config);
    }

    private static void assertValidConfigurationGetResponses()
    {
        System.assert(config.getIsDebug());
        System.assert(config.getIsLogFullPayload());
        System.assert(config.getIsLogRecords());
        System.assertEquals('JsonTextField__c.Publishing_User__c',config.getPublishingUserField());
        System.assertEquals('{1} - {0}',config.getNameFormatPlaceholder());
        System.assertEquals(new list<string>{'JsonTextField__c'}, config.getFieldsToLog());
    }
    



    /** TEST METHODS **/

    @isTest static void noConfigurations() 
    { 
        test.startTest();
        doTest();
        test.stopTest();

        System.assert(logException!=null);
        System.assert(logException.getMessage().contains(lpes_CustomMetadataConfiguration.NO_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
        assertDefaultGetResponses();
    }

    @isTest static void multipleActiveConfigurations() 
    {
        createPlatformEventConfigurationRecords(3,'JsonTextField__c');

        test.startTest();
        doTest();
        test.stopTest();

        System.assert(logException!=null);
        System.assert(logException.getMessage().contains(lpes_CustomMetadataConfiguration.DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
        assertDefaultGetResponses();
    }

    @isTest static void activeAndInactiveConfigurationsPassing() 
    {
        createPlatformEventConfigurationRecords(3,'JsonTextField__c');
        eventConfigurations[0].is_active__c=false;
        eventConfigurations[2].is_active__c=false;

        test.startTest();
        doTest();
        test.stopTest();

        System.assert(logException==null);
        assertValidConfigurationGetResponses();
    }

    @isTest static void activeAndInactiveConfigurationsFailing() 
    {
        createPlatformEventConfigurationRecords(3,'JsonTextField__c');
        eventConfigurations[0].is_active__c=false;

        test.startTest();
        doTest();
        test.stopTest();

        System.assert(logException!=null);
        System.assert(logException.getMessage().contains(lpes_CustomMetadataConfiguration.DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
        assertDefaultGetResponses();
    }


}
