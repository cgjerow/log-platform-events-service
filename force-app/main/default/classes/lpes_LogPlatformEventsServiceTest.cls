@isTest public class lpes_LogPlatformEventsServiceTest 
{
    
    private static integer count;
    private static list<LogPlatformEventsServiceTestEvent__e> testEvents;
    private static final string jsonFieldString;
    private static final string invalidJsonString;
    private static boolean performDML;
    private static List<platform_event_log__c> insertedLogs; // Logs stored here if PerformDML is FALSE
    private static List<platform_event_log_field__c> insertedFieldLogs; // Logs stored here if PerformDML is FALSE
    private static exception logException;
    private static lpes_LogPlatformEventsService eventlogger;
    private static map<string,object> methodToReturnValue;

    static 
    {
        count = 20;
        jsonFieldString = '{"Publishing_User__c":"'+UserInfo.getUserId()+'","innerFieldOne":"innerValueOne","innerFieldTwo":"innerValueTwo","innerFieldThree":{"deepInnerFieldOne":"deepInnerValueOne"}}';
        invalidJsonString = '{\"realfield\":\"realValue\":errorField\":\"errorValue\"}'; // throw error in JSON.deserialize
        performDML = false;
        insertedLogs = new List<platform_event_log__c>();
        insertedFieldLogs = new List<platform_event_log_field__c>();
        methodToReturnValue = new map<string,object>{
            'getIsDebug'=>true,
            'getIsLogFullPayload'=>true,
            'getIsLogRecords'=>true,
            'getNameFormatPlaceholder'=>'LogPlatformEventsServiceTestEvent__e - {0}',
            'getFieldsToLog'=>'JsonTextField__c,JsonTextField__c.innerFieldOne,JsonTextField__c.innerFieldThree.deepInnerFieldOne'.split(','),
            'getPublishingUserField'=>'JsonTextField__c.Publishing_User__c'
        };
    }


    /** PRIVATE HELPER METHODS **/


    /* 
    * Leveraging the JSON.deserialize() method allows us to work 
    * around "Field Not Writable" limitations for mock data
    */

    private static void createPlatformEventList()
    {
        testEvents = new list<LogPlatformEventsServiceTestEvent__e>();
        for (integer i=0;i<count;i++)
        {
            testEvents.add((LogPlatformEventsServiceTestEvent__e)JSON.deserialize('{' +
            '"ReplayId":"123456'+i+'",' +
            '"JsonTextField__c":' + JSON.serialize(jsonFieldString)  +
            '}',
             LogPlatformEventsServiceTestEvent__e.class));
        }
    }

    private static void createPlatformEventListWithInvalidJson()
    {
        testEvents = new list<LogPlatformEventsServiceTestEvent__e>();
        for (integer i=0;i<count;i++)
        {
            LogPlatformEventsServiceTestEvent__e e = (LogPlatformEventsServiceTestEvent__e)JSON.deserialize('{' +
            '"ReplayId":"123456'+i+'"' +
            '}',
            LogPlatformEventsServiceTestEvent__e.class);
            e.JsonTextField__c = invalidJsonString;

            testEvents.add(e);
        }
    }

    public static boolean getPerformDML()
    {
        return performDML;
    }

    public static void setInsertedLogs(List<platform_event_log__c> logs)
    {
        insertedLogs = logs;
    }

    public static void setInsertedLogFields(List<platform_event_log_field__c> fieldLogs)
    {
        insertedFieldLogs = fieldLogs;
    }

    private static list<platform_event_log__c> getInsertedLogs() 
    {
        if (performDML)
            return [select id, name, publishing_user__c from platform_event_log__c];
        else 
            return insertedLogs;
    }

    private static list<platform_event_log_field__c> getInsertedFieldLogs()
    {
        if (performDML)
            return [select id, field_name__c, field_value__c from platform_event_log_field__c];
        else 
            return insertedFieldLogs;
    }


    // All tests are running the same core functionality, just with different config and events
    // Pulled this out to avoid duplication across all tests
    private static void doTest(list<sobject> testEvents)
    {
        try {
            eventlogger = new lpes_LogPlatformEventsService(testEvents,
                              (lpes_CustomMetadataConfiguration)lpes_MockProvider.createMock(lpes_CustomMetadataConfiguration.class, methodToReturnValue));
            eventlogger.logEvents();
        } catch (exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
    



    /** TEST METHODS **/

    @isTest static void passEmptyListToConstructor() 
    {
        test.startTest();
        doTest(new List<LogPlatformEventsServiceTestEvent__e>());
        test.stopTest();

        System.assert(logException==null);
    }

    @isTest static void passNullToConstructor() 
    {
        test.startTest();
        doTest(null);
        test.stopTest();

        System.assert(logException!=null);
    }

    @isTest static void oneValidConfigurationWithDML() 
    {
        // PERFORM INSERTS
        count = 250; // test valid config with high count
        performDML = true;
        createPlatformEventList();

        test.startTest();
        doTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = getInsertedLogs();
        list<platform_event_log_field__c> eventLogFields = getInsertedFieldLogs();

        integer jsonTextFields = 0;
        integer innerFieldOneFields = 0;
        integer deepInnerFieldOneFields = 0;

        for (platform_event_log_field__c eventLogField : eventLogFields)
        {
            if (eventLogField.field_name__c=='JsonTextField__c' && eventLogField.field_value__c==jsonFieldString)
                jsonTextFields+=1;
            else if (eventLogField.field_name__c=='JsonTextField__c.innerFieldOne' && eventLogField.field_value__c=='innerValueOne')
                innerFieldOneFields+=1;
            else if (eventLogField.field_name__c=='JsonTextField__c.innerFieldThree.deepInnerFieldOne' && eventLogField.field_value__c=='deepInnerValueOne')
                deepInnerFieldOneFields+=1;
        }
        
        System.assert(logException==null);
        System.assertEquals(count, eventLogs.size());
        System.assertEquals(count*3, eventLogFields.size());
        System.assertEquals(count,deepInnerFieldOneFields);
        System.assertEquals(count,innerFieldOneFields);
        System.assertEquals(count,jsonTextFields);

        for (platform_event_log__c log : eventLogs)
        {
            System.assertEquals(UserInfo.getUserId(),log.publishing_user__c);
        }
    }

    @isTest static void oneValidConfiguration() 
    {
        count = 250; // test valid config with high count
        createPlatformEventList();

        test.startTest();
        doTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = getInsertedLogs();
        list<platform_event_log_field__c> eventLogFields = getInsertedFieldLogs();

        integer jsonTextFields = 0;
        integer innerFieldOneFields = 0;
        integer deepInnerFieldOneFields = 0;

        for (platform_event_log_field__c eventLogField : eventLogFields)
        {
            System.debug(eventLogField);
            if (eventLogField.field_name__c=='JsonTextField__c' && eventLogField.field_value__c==jsonFieldString)
                jsonTextFields+=1;
            else if (eventLogField.field_name__c=='JsonTextField__c.innerFieldOne' && eventLogField.field_value__c=='innerValueOne')
                innerFieldOneFields+=1;
            else if (eventLogField.field_name__c=='JsonTextField__c.innerFieldThree.deepInnerFieldOne' && eventLogField.field_value__c=='deepInnerValueOne')
                deepInnerFieldOneFields+=1;
        }
        
        System.assert(logException==null);
        System.assertEquals(count, eventLogs.size());
        System.assertEquals(count*3, eventLogFields.size());
        System.assertEquals(count,deepInnerFieldOneFields);
        System.assertEquals(count,innerFieldOneFields);
        System.assertEquals(count,jsonTextFields);

        for (platform_event_log__c log : eventLogs)
        {
            System.assertEquals(UserInfo.getUserId(),log.publishing_user__c);
        }
    }

    @isTest static void invalidPublishingUserValue() 
    {
        createPlatformEventList();

        // change to invalid field
        methodToReturnValue.put('getPublishingUserField','NotAField__c');

        test.startTest();
        doTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = getInsertedLogs();
        
        
        System.assert(logException==null);
        System.assertEquals(count, eventLogs.size());

        for (platform_event_log__c log : eventLogs)
        {
            System.assertEquals(null,log.publishing_user__c);
        }
    }

    @isTest static void blankPublishingUserValue() 
    {
        createPlatformEventList();

        // change to invalid field
        methodToReturnValue.put('getPublishingUserField','');

        test.startTest();
        doTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = getInsertedLogs();
        
        
        System.assert(logException==null);
        System.assertEquals(count, eventLogs.size());

        for (platform_event_log__c log : eventLogs)
        {
            System.assertEquals(null,log.publishing_user__c);
        }
    }

    @isTest static void erroneousFieldConfiguration() 
    {
        createPlatformEventList();
        methodToReturnValue.put('getFieldsToLog','WrongField__c,JsonTextField__c.OtherWrongField__c.OtherWrongField__c'.split(','));

        test.startTest();
        doTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = getInsertedLogs();
        System.assert(logException==null);
        System.assertEquals(count, eventLogs.size());
    }

    @isTest static void erroneousJsonInPayload() 
    {
        createPlatformEventListWithInvalidJSON();
        methodToReturnValue.put('getFieldsToLog','JsonTextField__c.ErrorField__c'.split(','));

        test.startTest();
        doTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = getInsertedLogs();
        List<platform_event_log_field__c> eventLogFields = getInsertedFieldLogs();

        System.assert(logException==null);
        System.assertEquals(count, eventLogs.size());
        System.assertEquals(count, eventLogFields.size());

        for (platform_event_log_field__c eventLogField : eventLogFields) 
        {
            System.debug(eventLogField);
            System.assertEquals('JsonTextField__c.ErrorField__c',eventLogField.field_name__c);
            System.assert(eventLogField.field_value__c.contains(lpes_LogPlatformEventsService.JSON_PARSE_ERROR_MESSAGE.split(':')[0]));
        }
    }

    @isTest static void inactiveConfiguration() 
    {
        createPlatformEventList();
        methodToReturnValue.put('getIsDebug',false);
        methodToReturnValue.put('getIsLogRecords',false);
        
        test.startTest();
        doTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = getInsertedLogs();
        System.assert(logException==null);
        System.assertEquals(0, eventLogs.size());
    }
}