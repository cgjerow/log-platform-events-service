@isTest
global class LogPlatformEventsServiceTest 
{
    private static final integer count=500;
    private static list<LogPlatformEventsServiceTestEvent__e> testEvents;
    private static list<Platform_Event_Log_Configuration__mdt> eventConfigurations;
    private static final string jsonFieldString;
    private static final string invalidJsonString;

    static 
    {
        eventConfigurations = new List<Platform_Event_Log_Configuration__mdt>();
        jsonFieldString = '{"Publishing_User__c":"0051N000006Ckw6QAC","innerFieldOne":"innerValueOne","innerFieldTwo":"innerValueTwo","innerFieldThree":{"deepInnerFieldOne":"deepInnerValueOne"}}';
        invalidJsonString = '{\"realfield\":\"realValue\":errorField\":\"errorValue\"}'; // throw error in JSON.deserialize
    }


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

    private static void createPlatformEventConfigurationRecords(integer count, string eventType, string fieldsList)
    {
        for (integer i=0;i<count;i++) 
        {
            eventConfigurations.add((Platform_Event_Log_Configuration__mdt)JSON.deserialize('{' +
                '"ReplayId":"0123456'+i+'",' +
                '"DeveloperName":"EVENT LOG CONFIG '+i+'",' +
                '"MasterLabel":"EVENT LOG CONFIG '+i+'",' +
                '"Is_Active__c":true,' +
                '"Enable_Debug__c":true,' +
                '"Enable_Log_Records__c":true,' +
                '"Publishing_User_Field__c":"JsonTextField__c.Publishing_User__c",' +
                '"Field_Logs__c":"'+fieldsList+'",' +
                '"Platform_Event_Type_API_Name__c":"'+eventType+'"' +
                '}',
                Platform_Event_Log_Configuration__mdt.class));
        }
    }    

    global static list<Platform_Event_Log_Configuration__mdt> getEventConfigurations()
    {
        return eventConfigurations;
    }

    
    // ALL TEST METHODS BELOW

    @isTest
    static void passEmptyListToConstructor() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(new List<LogPlatformEventsServiceTestEvent__e>());
            eventlogger.logEvents();
        } catch (exception e) {
            emptyListException = e;
        }
        test.stopTest();

        System.assert(emptyListException!=null);
        System.assert(emptyListException.getMessage().contains(LogPlatformEventsService.EMPTY_EVENT_LIST_MESSAGE.split(':')[0]));
    }

    @isTest
    static void passNullToConstructor() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(null);
            eventlogger.logEvents();
        } catch (exception e) {
            emptyListException = e;
        }
        test.stopTest();

        System.assert(emptyListException!=null);
        System.assert(emptyListException.getMessage().contains(LogPlatformEventsService.EMPTY_EVENT_LIST_MESSAGE.split(':')[0]));
    }

    @isTest
    static void noConfigurations() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            emptyListException = e;
        }
        test.stopTest();

        System.assert(emptyListException!=null);
        System.assert(emptyListException.getMessage().contains(LogPlatformEventsService.NO_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
    }

    @isTest
    static void multipleActiveConfigurations() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();
        createPlatformEventConfigurationRecords(3,'LogPlatformEventsServiceTestEvent__e','JsonTextField__c');

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            emptyListException = e;
        }
        test.stopTest();

        System.assert(emptyListException!=null);
        System.assert(emptyListException.getMessage().contains(LogPlatformEventsService.DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
    }

    @isTest
    static void activeAndInactiveConfigurationsPassing() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();
        createPlatformEventConfigurationRecords(3,'LogPlatformEventsServiceTestEvent__e','JsonTextField__c');
        eventConfigurations[0].is_active__c=false;
        eventConfigurations[2].is_active__c=false;

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            emptyListException = e;
        }
        test.stopTest();

        List<platform_event_log__c> eventLogs = [select id, name from platform_event_log__c];
        System.assert(emptyListException==null);
        System.assertEquals(count, eventLogs.size());
    }

    @isTest
    static void activeAndInactiveConfigurationsFailing() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();
        createPlatformEventConfigurationRecords(3,'LogPlatformEventsServiceTestEvent__e','JsonTextField__c');
        eventConfigurations[0].is_active__c=false;

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            emptyListException = e;
        }
        test.stopTest();

        System.assert(emptyListException!=null);
        System.assert(emptyListException.getMessage().contains(LogPlatformEventsService.DUPLICATE_EVENT_CONFIGURATIONS_MESSAGE.split(':')[0]));
    }

    @isTest
    static void oneValidConfiguration() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();
        createPlatformEventConfigurationRecords(1,'LogPlatformEventsServiceTestEvent__e','JsonTextField__c,JsonTextField__c.innerFieldOne,JsonTextField__c.innerFieldThree.deepInnerFieldOne');

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            emptyListException = e;
        }
        test.stopTest();

        List<platform_event_log__c> eventLogs = [select id, name, publishing_user__c from platform_event_log__c];
        list<platform_event_log_field__c> eventLogFields = [select id, field_name__c, field_value__c from platform_event_log_field__c];

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
        
        System.assert(emptyListException==null);
        System.assertEquals(count, eventLogs.size());
        System.assertEquals(count*3, eventLogFields.size());
        System.assertEquals(count,deepInnerFieldOneFields);
        System.assertEquals(count,innerFieldOneFields);
        System.assertEquals(count,jsonTextFields);

        for (platform_event_log__c log : eventLogs)
        {
            System.assertEquals('0051N000006Ckw6QAC',log.publishing_user__c);
        }
    }

    @isTest
    static void invalidPublishingUserValue() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();
        createPlatformEventConfigurationRecords(1,'LogPlatformEventsServiceTestEvent__e','JsonTextField__c,JsonTextField__c.innerFieldOne,JsonTextField__c.innerFieldThree.deepInnerFieldOne');

        eventConfigurations[0].Publishing_User_Field__c = 'NotAField__c';

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            emptyListException = e;
        }
        test.stopTest();

        List<platform_event_log__c> eventLogs = [select id, name, publishing_user__c from platform_event_log__c];
        
        
        System.assert(emptyListException==null);
        System.assertEquals(count, eventLogs.size());

        for (platform_event_log__c log : eventLogs)
        {
            System.assertEquals(null,log.publishing_user__c);
        }
    }

    @isTest
    static void erroneousFieldConfiguration() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();
        createPlatformEventConfigurationRecords(1,'LogPlatformEventsServiceTestEvent__e','WrongField__c,JsonTextField__c.OtherWrongField__c.OtherWrongField__c');

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            System.debug(e);
            emptyListException = e;
        }
        test.stopTest();

        List<platform_event_log__c> eventLogs = [select id, name from platform_event_log__c];
        System.assert(emptyListException==null);
        System.assertEquals(count, eventLogs.size());
    }

    @isTest
    static void erroneousJsonInPayload() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventListWithInvalidJSON();
        createPlatformEventConfigurationRecords(1,'LogPlatformEventsServiceTestEvent__e','JsonTextField__c.ErrorField__c');

        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            System.debug(e);
            emptyListException = e;
        }
        test.stopTest();

        List<platform_event_log__c> eventLogs = [select id, name from platform_event_log__c];
        List<platform_event_log_field__c> eventLogFields = [select id, field_name__c, field_value__c from platform_event_log_field__c];

        System.assert(emptyListException==null);
        System.assertEquals(count, eventLogs.size());
        System.assertEquals(count, eventLogFields.size());

        for (platform_event_log_field__c eventLogField : eventLogFields) 
        {
            System.assertEquals('JsonTextField__c.ErrorField__c',eventLogField.field_name__c);
            System.assert(eventLogField.field_value__c.contains(LogPlatformEventsService.JSON_PARSE_ERROR_MESSAGE.split(':')[0]));
        }
    }

    @isTest
    static void inactiveConfiguration() 
    {
        exception emptyListException;
        LogPlatformEventsService eventlogger;

        createPlatformEventList();
        createPlatformEventConfigurationRecords(1,'LogPlatformEventsServiceTestEvent__e','JsonTextField__c');
        eventConfigurations[0].Is_Active__c = false;
        test.startTest();
        try {
            eventlogger = new LogPlatformEventsService(testEvents);
            eventlogger.logEvents();
        } catch (exception e) {
            System.debug(e);
            System.debug(e.getStackTraceString());
            emptyListException = e;
        }
        test.stopTest();

        List<platform_event_log__c> eventLogs = [select id, name from platform_event_log__c];
        System.assert(emptyListException==null);
        System.assertEquals(0, eventLogs.size());
    }
}
