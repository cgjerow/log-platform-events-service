@istest public class lpes_LogPlatformEventsConfigurationTest {

    private static ConcreteLogPlatformEventsConfigurationTestClass config;

    /***************************************************
                   PRIVATE HELPER METHODS
    ****************************************************/

    private static void doUnitTest()
    {
        config = new ConcreteLogPlatformEventsConfigurationTestClass();
    }


    /***************************************************
              INNER CLASS EXTENDS CONFIGURATION
    ****************************************************/

    public class ConcreteLogPlatformEventsConfigurationTestClass extends lpes_LogPlatformEventsConfiguration {}



    /***************************************************
                        UNIT TESTS
    ****************************************************/

    @istest public static void populateValuesAndRetrieveThem()
    {

        test.startTest();
        doUnitTest();
        test.stopTest();

        System.assertEquals(false,config.getIsLogFullPayload());
        System.assertEquals('',config.getNameFormatPlaceholder());
        System.assertEquals(new list<string>(),config.getFieldsToLog());
        System.assertEquals('',config.getPublishingUserField());
    }
}