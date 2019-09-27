@istest public class lpes_PlatformEventLogWrapperTest {

    private static integer count = 20;
    private static integer fieldCount = 5;

    private static lpes_PlatformEventLogWrapper logWrapper;
    private static map<string,platform_event_log__c> logs;
    private static map<string,list<platform_event_log_field__c>> fieldLogs; 


    /***************************************************
                   PRIVATE HELPER METHODS
    ****************************************************/

    private static void doUnitTest()
    {
        logWrapper = new lpes_PlatformEventLogWrapper(logs,fieldLogs);
    }



    /***************************************************
                        UNIT TESTS
    ****************************************************/

    @istest public static void populateValuesAndRetrieveThem()
    {
        logs = lpes_TestDataFactory.generateLogMapForWrapper(count);
        fieldLogs = lpes_TestDataFactory.generateFieldLogMapForWrapper(count,fieldCount);

        test.startTest();
        doUnitTest();
        test.stopTest();

        System.assertEquals(logs,logWrapper.platformEventLogs);
        System.assertEquals(logs.keyset(),logWrapper.replayIds);
        System.assertEquals(fieldLogs,logWrapper.platformEventLogFields);
    }


    @istest public static void passEmptyVariablesToConstructor()
    {
        logs = new map<string,platform_event_log__c>();
        fieldLogs = new map<string,list<platform_event_log_field__c>>();

        test.startTest();
        doUnitTest();
        test.stopTest();

        System.assertEquals(logs,logWrapper.platformEventLogs);
        System.assertEquals(logs.keyset(),logWrapper.replayIds);
        System.assertEquals(fieldLogs,logWrapper.platformEventLogFields);
    }


    @istest public static void passNullToConstructor()
    {
        Exception wrapperException;

        test.startTest();
        try {
            doUnitTest();
        } catch (exception e) {
            System.debug(e);
            System.debug(e.getMessage());
            wrapperException = e;
        }
        test.stopTest();

        System.assertNotEquals(null,wrapperException);
        System.assertEquals(lpes_ExceptionMessageWrapper.INVALID_PARAMETERS_MESSAGE,wrapperException.getMessage());
    }
}