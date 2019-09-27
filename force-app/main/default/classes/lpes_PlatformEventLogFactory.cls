public inherited sharing class lpes_PlatformEventLogFactory
{

    private sobject[] newlist;
    private final lpes_ILogPlatformEventsConfiguration config;
    private map<string,list<platform_event_log_field__c>> replayidToFieldLogs;
    private map<string,platform_event_log__c> logs;
    private list<platform_event_log_field__c> fieldlogs;
    private map<sobjecttype,string> typeToName;
    private id publishingUser;
    protected map<string,fieldsetting> fieldPathToSettings;

    public lpes_PlatformEventLogFactory(lpes_ILogPlatformEventsConfiguration config)
    {
        if (config==null)
            throw new PlatformEventLogFactoryException(lpes_ExceptionMessageWrapper.INVALID_PARAMETERS_MESSAGE);

        this.config = config;
    }


    public lpes_PlatformEventLogWrapper buildLogs(list<sobject> events)
    {
        if (events==null)
            throw new PlatformEventLogFactoryException(lpes_ExceptionMessageWrapper.INVALID_PARAMETERS_MESSAGE);

        this.newlist = events;
        this.logs = new map<string,platform_event_log__c>();
        this.replayidToFieldLogs = new map<string,list<platform_event_log_field__c>>();
        this.fieldPathToSettings = new map<string,fieldsetting>();
        this.typeToName = new map<sobjecttype,string>();

        // populate fielPathToSettings map 
        this.setLogFields(this.config.getFieldsToLog());
        this.setPublishingUserField(this.config.getPublishingUserField());


        // build platform_event_log and platform_event_log_field records
        for (SObject event : this.newlist)
        {
            string platformEventType = this.getPlatformEventTypeName(event.getSObjectType());
            platform_event_log_field__c[] fields = this.buildLogFieldsList(event,platformEventType);

            // Add Platform Event Log record to list
            this.logs.put((string) event.get('replayid'), new platform_event_log__c(
                name = String.format(this.config.getNameFormatPlaceholder(),
                                     new list<string>{(string)event.get('replayid'),platformEventType}),
                replayid__c = (string)event.get('replayid'),                
                platform_event_type__c = platformEventType,
                publishing_user__c = (id)publishingUser,
                platform_event_payload__c = this.config.getIsLogFullPayload() ? 
                                            JSON.serialize(event) : lpes_ExceptionMessageWrapper.DISABLED_PAYLOAD_LOG_MESSSAGE
            ));

            this.replayidToFieldLogs.put((string)event.get('replayid'),fields);

            // reset tmp fields
            this.publishingUser = null;
        }

        return new lpes_PlatformEventLogWrapper(this.logs, this.replayidToFieldLogs);
    }

    private list<platform_event_log_field__c> buildLogFieldsList(SObject event, String platformEventType)
    {
        list<platform_event_log_field__c> fields = new list<platform_event_log_field__c>();
        // iterate through all fields to log
        for (FieldSetting fs : fieldPathToSettings.values())
        {
            string value = this.getFieldValue(event,fs.fieldPath,platformEventType);

            // allow admin to configure what field to use to populate publishing_user__c
            if (fs.isPublishingUserField)
                this.publishingUser = this.getUserId(value);

            if (fs.isLogField)
                fields.add(new platform_event_log_field__c(
                    name = fs.fieldPath+' - '+event.get('replayid'),
                    field_name__c = fs.fieldPath,
                    field_value__c = value
                ));
        }

        return fields;
    }


    // Iterate through all fields in field path and retrieve value
    private string getFieldValue(sobject event, string field, string platformEventType)
    {
        String value; 
        map<string,object> nestedObj;

        // support dot notation for valid json text fields on the platform event
        // iterate through fields in field path to get final value
        for (string attribute : field.split('\\.'))
        {
            try {
                // fields in json object stored in the platform event field
                if (nestedObj!=null)
                {
                    value = String.valueOf(nestedObj.get(attribute));
                    if (nestedObj.get(attribute)==null || nestedObj.get(attribute) instanceof map<string,object>)
                        nestedObj = (map<string,object>)nestedObj.get(attribute);
                }

                // platform event field (first field in each field path)
                else
                {
                    try {
                        value =  String.valueOf(event.get(attribute));
                    } catch(SObjectException e) {
                        System.debug(e.getMessage());
                        System.debug(lpes_ExceptionMessageWrapper.INVALID_EVENT_FIELD_MESSAGE);
                        value = String.format(lpes_ExceptionMessageWrapper.INVALID_EVENT_FIELD_MESSAGE, new list<string>{field,platformEventType});
                        break;
                    }
                    
                    // Only parse nestedObj for fields using dot notation
                    if (field.contains('.'))
                        nestedObj = (map<string,object>)JSON.deserializeUntyped(value);
                }
            } catch(exception e) {
                System.debug(e.getMessage());
                System.debug(lpes_ExceptionMessageWrapper.JSON_PARSE_ERROR_MESSAGE);
                value = lpes_ExceptionMessageWrapper.JSON_PARSE_ERROR_MESSAGE;
                break;
            }

            // if part way through field path and no value is returned, break loop
            if (nestedObj==null)
                break;
        }

        return value;
    }


    // Validate id string and return valid id or null
    private id getUserId(string idstring)
    {
        try {
            return ((id)idstring).getSobjectType().getDescribe().getName()=='User' ? idstring : null;
        } catch (exception e) {
            System.debug('Invalid User Id Value');
            System.debug(e.getMessage());
            return null;
        }
    }

    private string getPlatformEventTypeName(sobjecttype eventType) 
    {
        String name = typeToName.get(eventType);
        if (name==null)
        {
            name = eventType.getDescribe().getName();
            typeToName.put(eventType,name);
        }

        return name;
    }



    /******************************************************
         FIELD SETTING INNER CLASS AND HELPER METHODS
    *******************************************************/


    private class FieldSetting
    {
        private final string fieldPath;
        private boolean isPublishingUserField = false;
        private boolean isLogField = false;

        private FieldSetting(string fieldPath)
        {
            this.fieldPath = fieldPath;
        }

        private void setLogField()
        {
            this.isLogField=true;
        }

        private void setPublishingUserField()
        {
            this.isPublishingUserField=true;
        }
    }

    private void setPublishingUserField(string fieldPath)
    {
        if (String.isBlank(fieldPath))
            fieldPath = 'CreatedById';

        FieldSetting fieldSetting = getFieldSetting(fieldPath);
        fieldSetting.setPublishingUserField();
        this.fieldPathToSettings.put(fieldPath,fieldSetting);
    }

    private void setLogFields(list<string> fieldsToLog)
    {
        for (string fieldPath : fieldsToLog)
        {
            if (!String.isBlank(fieldPath))
                this.setLogField(fieldPath);
        }
    }

    private void setLogField(string fieldPath)
    {
        if (String.isBlank(fieldPath))
            return;

        FieldSetting fieldSetting = getFieldSetting(fieldPath);
        fieldSetting.setLogField();
        this.fieldPathToSettings.put(fieldPath,fieldSetting);
    }

    private FieldSetting getFieldSetting(string fieldPath)
    {
        return this.fieldPathToSettings.get(fieldPath)!=null ? this.fieldPathToSettings.get(fieldPath) : new FieldSetting(fieldPath);
    }



    public class PlatformEventLogFactoryException extends Exception {}
}