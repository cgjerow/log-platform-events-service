// Extend LogPlatformEventsConfig to use this test class in the MockProvider
@isTest public class lpes_PlatformEventLogFactoryTest extends lpes_LogPlatformEventsConfiguration
{
    
    private static integer count;
    private static list<LogPlatformEventsServiceTestEvent__e> testEvents;
    private static final string jsonFieldString;
    private static final string invalidJsonString;
    private static List<platform_event_log__c> insertedLogs; // Logs stored here if PerformDML is FALSE
    private static List<platform_event_log_field__c> insertedFieldLogs; // Logs stored here if PerformDML is FALSE
    private static exception logException;
    private static lpes_PlatformEventLogFactory factory;
    private static map<string,object> methodToReturnValue;
    private static lpes_PlatformEventLogWrapper logs;

    static 
    {
        count = 20;
        jsonFieldString = '{"Publishing_User__c":"'+UserInfo.getUserId()+'","innerFieldOne":"innerValueOne","innerFieldTwo":"innerValueTwo","innerFieldThree":{"deepInnerFieldOne":"deepInnerValueOne"}}';
        invalidJsonString = '{\"realfield\":\"realValue\":errorField\":\"errorValue\"}'; // throw error in JSON.deserialize
        methodToReturnValue = new map<string,object>{
            'getIsDebug'=>true,
            'getIsLogFullPayload'=>true,
            'getIsLogRecords'=>true,
            'getNameFormatPlaceholder'=>'LogPlatformEventsServiceTestEvent__e - {0}',
            'getFieldsToLog'=>'JsonTextField__c,JsonTextField__c.innerFieldOne,JsonTextField__c.innerFieldThree.deepInnerFieldOne'.split(','),
            'getPublishingUserField'=>'JsonTextField__c.Publishing_User__c'
        };
    }

    


    /***************************************************
                   FAKE DATA GENERATORS
    ****************************************************/


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





    /***************************************************
                   PRIVATE HELPER METHODS
    ****************************************************/ 


    private static void doUnitTest(list<sobject> testEvents)
    {
        factory = new lpes_PlatformEventLogFactory(
            (lpes_PlatformEventLogFactoryTest)lpes_MockProvider.createMock(lpes_PlatformEventLogFactoryTest.class, methodToReturnValue)
        );
        logs = factory.buildLogs(testEvents);
    }


    private static void doIntegrationTest(list<sobject> testEvents)
    {
        
        factory = new lpes_PlatformEventLogFactory(
            new lpes_PlatformEventLogFactoryTest.ConcreteLogPlatformEventsFactoryConfiguration(
                (boolean)methodToReturnValue.get('getIsLogFullPayload'),
                (string)methodToReturnValue.get('getPublishingUserField'),
                (list<string>)methodToReturnValue.get('getFieldsToLog'),
                (string)methodToReturnValue.get('getNameFormatPlaceholder')
        ));
        logs = factory.buildLogs(testEvents);
    }



    
    /***************************************************
     CONCRETE lpes_LogPlatformEventsFactoryConfiguration
    ****************************************************/
    
    
    public class ConcreteLogPlatformEventsFactoryConfiguration extends lpes_LogPlatformEventsConfiguration
    {
        public ConcreteLogPlatformEventsFactoryConfiguration(
            boolean logPayload, string userField, 
            list<string> logFields, string nameFormat
        )
        {
            this.isLogFullPayload = logPayload;
            this.publishingUserField = userField;
            this.fieldsToLog = logFields;
            this.nameFormatPlaceholder = nameFormat;
        }
    }
    


    /***************************************************
                        UNIT TESTS
    ****************************************************/


    @isTest static void passEmptyListToBuildLogsCall() 
    {
        test.startTest();
        try {
            doUnitTest(new List<LogPlatformEventsServiceTestEvent__e>());
        } catch(exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        test.stopTest();

        System.assert(logException==null);
        System.assertEquals(0,logs.platformEventLogs.size());
        System.assertEquals(0,logs.platformEventLogFields.size());
    }

    @isTest static void passNullToConstructor() 
    {
        test.startTest();
        try {
            factory = new lpes_PlatformEventLogFactory(null);
        } catch(exception e) {
            logException = e;
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        test.stopTest();

        System.assert(logException!=null);
        System.assertEquals(lpes_ExceptionMessageWrapper.INVALID_PARAMETERS_MESSAGE, logException.getMessage());
    }


    @isTest static void invalidPublishingUserValue() 
    {
        createPlatformEventList();

        // change to invalid field
        methodToReturnValue.put('getPublishingUserField','NotAField__c');

        test.startTest();
        doUnitTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = logs.platformEventLogs.values();

        integer nullUsers = 0;
        for (platform_event_log__c log : eventLogs)
        {
            if(log.publishing_user__c==null)
                nullUsers+=1;
        }
        System.assertEquals(count, eventLogs.size());
        System.assertEquals(count, nullUsers);

    }

    @isTest static void blankPublishingUserValue() 
    {
        createPlatformEventList();

        // change to invalid field
        methodToReturnValue.put('getPublishingUserField','');

        test.startTest();
        doUnitTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = logs.platformEventLogs.values();

        integer nullUsers = 0;
        for (platform_event_log__c log : eventLogs)
        {
            if(log.publishing_user__c==null)
                nullUsers+=1;
        }
        System.assertEquals(count, eventLogs.size());
        System.assertEquals(count, nullUsers);
    }

    @isTest static void erroneousFieldConfiguration() 
    {
        createPlatformEventList();
        methodToReturnValue.put('getFieldsToLog','WrongField__c,JsonTextField__c.OtherWrongField__c.OtherWrongField__c'.split(','));

        test.startTest();
        doUnitTest(testEvents);
        test.stopTest();

        List<platform_event_log__c> eventLogs = logs.platformEventLogs.values();
        // add assertion that field logs created for bad field paths 
        System.assertEquals(count, eventLogs.size());
    }

    @isTest static void erroneousJsonInPayload() 
    {
        createPlatformEventListWithInvalidJSON();
        methodToReturnValue.put('getFieldsToLog','JsonTextField__c.ErrorField__c'.split(','));

        test.startTest();
        doUnitTest(testEvents);
        test.stopTest();

        System.assertEquals(count, logs.platformEventLogFields.size());
        System.assertEquals(count, logs.platformEventLogs.size());

        for (string replayid : logs.replayIds)
        {
            for (platform_event_log_field__c eventLogField : logs.platformEventLogFields.get(replayId)) 
            {
                System.debug(eventLogField);
                System.assertEquals('JsonTextField__c.ErrorField__c',eventLogField.field_name__c);
                System.assert(eventLogField.field_value__c.contains(lpes_ExceptionMessageWrapper.JSON_PARSE_ERROR_MESSAGE.split(':')[0]));
            }
        }
    }

    @isTest static void oneValidConfiguration() 
    {
        count = 250; // test valid config with high count
        createPlatformEventList();

        test.startTest();
        doUnitTest(testEvents);
        test.stopTest();


        integer jsonTextFields = 0;
        integer innerFieldOneFields = 0;
        integer deepInnerFieldOneFields = 0;
        integer correctName = 0;
        integer correctPublishingUser = 0;
        integer fieldsCount = 0;

        for (string replayId : logs.replayIds)
        {
            for (platform_event_log_field__c eventLogField : logs.platformEventLogFields.get(replayId))
            {
                fieldsCount += 1;

                if (eventLogField.field_name__c=='JsonTextField__c' && eventLogField.field_value__c==jsonFieldString)
                    jsonTextFields+=1;
                else if (eventLogField.field_name__c=='JsonTextField__c.innerFieldOne' && eventLogField.field_value__c=='innerValueOne')
                    innerFieldOneFields+=1;
                else if (eventLogField.field_name__c=='JsonTextField__c.innerFieldThree.deepInnerFieldOne' && eventLogField.field_value__c=='deepInnerValueOne')
                    deepInnerFieldOneFields+=1;
            }
        }

        for (platform_event_log__c log : logs.platformEventLogs.values())
        {
            if(UserInfo.getUserId()==log.publishing_user__c)
                correctPublishingUser+=1;
            
            if (log.Name.contains('LogPlatformEventsServiceTestEvent__e'))
                correctName+=1;
        }
        
        System.assertEquals(count, logs.platformEventLogs.size());
        System.assertEquals(count*3, fieldsCount);
        System.assertEquals(count, deepInnerFieldOneFields);
        System.assertEquals(count, innerFieldOneFields);
        System.assertEquals(count, jsonTextFields);
        System.assertEquals(count, correctPublishingUser);
        System.assertEquals(count, correctName);
    }

}