@istest public class lpes_SObjectPlatformEventLoggerTest {

    private static List<platform_event_log__c> insertedLogs; // Logs stored here if PerformDML is FALSE
    private static List<platform_event_log_field__c> insertedFieldLogs; // Logs stored here if PerformDML is FALSE
    
    private static lpes_PlatformEventLogWrapper logContainer;
    private static boolean performDML;
    private static boolean isDebug;
    private static boolean isLogRecords;

    static 
    {
        performDML = false;
        isLogRecords = true;
        isDebug = true;
        insertedLogs = new List<platform_event_log__c>();
        insertedFieldLogs = new List<platform_event_log_field__c>();
    }


    /***************************************************
                   PUBLIC GETTER METHODS
    ****************************************************/
    
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



    /***************************************************
                   PRIVATE HELPER METHODS
    ****************************************************/ 

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

    private static void doUnitTest()
    {
        new lpes_SObjectPlatformEventLogger(isLogRecords,isDebug).logEvents(logContainer);
    }


    /***************************************************
                        UNIT TESTS
    ****************************************************/


    @istest static void passEmptyMapsToLogWrapperAndLogger() 
    {
        logContainer = new lpes_PlatformEventLogWrapper(new map<string,platform_event_log__c>(), new map<string,list<platform_event_log_field__c>>());
        test.startTest();
        doUnitTest();
        test.stopTest();

        System.assertEquals(0,getInsertedLogs().size());
        System.assertEquals(0,getInsertedFieldLogs().size());
    }

    @istest static void passPopulatedLogWrapperToLogger()
    {
        integer logCount = 20;
        integer fieldLogCount = 5;
        logContainer = new lpes_PlatformEventLogWrapper(
            lpes_TestDataFactory.generateLogMapForWrapper(logCount),
            lpes_TestDataFactory.generateFieldLogMapForWrapper(logCount,fieldLogCount)
        );

        test.startTest();
        doUnitTest();
        test.stopTest();

        System.assertEquals(logCount,getInsertedLogs().size());
        System.assertEquals(logCount*fieldLogCount,getInsertedFieldLogs().size());
    }

    /***************************************************
                    INTEGRATION TESTS
    ****************************************************/

    @isTest static void performDmlInBulk() 
    {
        // PERFORM INSERTS
        integer logCount = 250; // test valid config with high count
        integer fieldLogCount = 5;
        performDML = true; 
        
        logContainer = new lpes_PlatformEventLogWrapper(
            lpes_TestDataFactory.generateLogMapForWrapper(logCount),
            lpes_TestDataFactory.generateFieldLogMapForWrapper(logCount,fieldLogCount)
        );

        test.startTest();
        doUnitTest();
        test.stopTest();

        System.assertEquals(logCount,getInsertedLogs().size());
        System.assertEquals(logCount*fieldLogCount,getInsertedFieldLogs().size());
    }
}