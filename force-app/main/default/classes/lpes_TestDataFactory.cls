@istest public class lpes_TestDataFactory {

    public static map<string,platform_event_log__c> generateLogMapForWrapper(integer count)
    {
        map<string,platform_event_log__c> tmpLogs = new map<string,platform_event_log__c>();
        
        for (integer i=0;i<count;i++)
        {
            tmpLogs.put('12345'+i, new platform_event_log__c(
                replayid__c='12345'+i,
                platform_event_type__c='test_event__e'
            ));
        }

        return tmpLogs;
    }

    public static map<string,list<platform_event_log_field__c>> generateFieldLogMapForWrapper(integer count, integer fieldCount)
    {
        map<string,list<platform_event_log_field__c>> tmpLogs = new map<string,list<platform_event_log_field__c>>();
        
        for (integer i=0;i<count;i++)
        {
            list<platform_event_log_field__c> tmpFields = new list<platform_event_log_field__c>();
            for (integer j=0;j<fieldCount;j++)
                tmpFields.add( new platform_event_log_field__c(
                    field_name__c='name_'+j,
                    field_value__c='value_'+j
                ));
            tmpLogs.put('12345'+i, tmpFields);
        }

        return tmpLogs;
    }
}