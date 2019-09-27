# Log Platform Events Service

## Deployment Instructions
This repository offers a few options for how to deploy the service and some add on functionality / examples. However, to get started is *super* easy!

### Deploy core service
First you must deploy the core service, which resides in force-app. From there you can deploy add-ons and examples from the 

### Deploy Add Ons
So you've deployed the core service, but you're thinking to yourself, "Now what? Is it running?"

The answer, NO. To keep the deployments as light-weight as possible, we only deploy the absolutely essential pieces of functionality in the core package.

To get the service actually working for specific use cases you can:  
1. If you're looking for a more configurable solution, deploy the CustomMetadataConfiguration add on (which you can preview in the demo noted above) and an example trigger.    
2. If you're building a more custom solution, familiarize yourself with the LogPlatformEventsService public interface and get building!  

Just a reminder, no add ons will be deployable until you've deployed the core service.

### Deploy CustomMetadataConfiguration Add On
You will need to do two things to set up logging for a new platform event:  
1. configure a LogPlatformEventsServiceConfiguration custom metadata record (look to the admin guide for instructions)  
2. create a trigger (you can deploy the example trigger, but it would be just as easy to create a new trigger for the platform event you want to log and follow the directions below.

To get logging running from your trigger just add these two lines into the body of the trigger and replace PLATFORM_EVENT_API_NAME with your platform event api name. (This should match the appropriate field on your custom metadata configuration)  

```javascript
    CustomMetadataEventLogConfiguration config = new CustomMetadataEventLogConfiguration('platform_event_type_api_name__c','PLATFORM_EVENT_API_NAME');
    new lpes_SObjectPlatformEventLogger(config.isLogRecords, config.isDebug).logEvents(new lpes_PlatformEventLogFactory(config).buildLogs(trigger.new));			
```

## Test Coverage
Test coverage greater than 95% with assertions covering the vast majority of use cases.
The holistic test cases can be used as examples for different types of configurations as well as for understanding the services error handling procedures.

## Custom Code
- lpes_CustomMetadataConfiguration & Test (Add On)
- lpes_ILogPlatformEventsConfiguration
- lpes_LogPlatformEventsService & Test
- lpes_MockProvider

### CustomMetadataConfiguration Class
Implements the lpes_ILogPlatformEventsConfiguration interface. 
Retrieves the active custom metadata configuration for specified Platform Event type.

### ILogPlatformEventsConfiguration Interface
Defines the interface for the configuration required by the lpes_LogPlatformEventsService.
Allows more flexibility than just taking a custom metadata record as developers can implement more conditional & dynamic configurations so long as they implement this interface.

### LogPlatformEventsService Class
Accepts a list of platform events and a configuration that implements the lpes_ILogPlatformEventsConfiguration interface and performs logging based on the configuration.
Can log in Apex Debug Logs, generate Platform_Event_Log & Platform_Event_Log_Field records, or both.

### MockProvider Class
Lightweight mocking framework that implements the System.StubProvider interface using the Singleton pattern. 
Takes a map of MethodName to ReturnValue to inform what the mock objects return in handleMethodCall().

## Configuration
- Platform_Event_Log: Main object used to store Platform Event logs. Tracks information such as the ReplayId, the user who published the log, and the platform event payload itself.
- Platform_Event_Log_Field: Child of the Platform_Event_Log object. Logs individual Platform Event field values, including nested values if the field on the Platform Event is valid JSON. The fields to be logged are configured in the Custom Metadata records.

### Platform_Event_Log Custom Object
Main object used to store Platform Event logs. 
Tracks information such as the ReplayId, the user who published the log, and the platform event payload itself.

### Platform_Event_Log_Field Custom Object
Child of the Platform_Event_Log object. 
Logs individual Platform Event field values, including nested values if the field on the Platform Event is valid JSON. The fields to be logged are configured in the Custom Metadata records.

### Platform_Event_Log_Configuration Custom Metadata
Custom Metadata configurations used to inform the Platform Event logging service. 
Specify multiple configurations by Platform Event type. Maximum of one configuration per Event type should be active, otherwise an exception will be thrown.

#### Options
- Enable_Debug: log Platform Events in the Apex Debug Logs. Note that platform event triggers run in the *Automated Process* context when setting up debug tracking.
- Enable_Log_Records: generate Platform_Event_Log and Platform_Event_Log_Field records
- Enable_Full_Payload_Log: log full platform event as text on the Platform_Event_Log object. Can disable if there is a concern about sensitive information being logged.
- Field_Logs: comma separated list of fields to log in the Platform_Event_Log_Field object. A more user friendly way of storing and viewing specific fields on the Platform Event. Supports dot notation assuming a field on the Platform Event is a valid JSON text field.
- Is_Active: activate a configuration so that it is visible in the lpes_CustomMetadataConfigurationClass. Allows for multiple configurations per event type, but only one should be active at any given time. Configurations of different event types can be active at the same time.
- Platform_Event_Type_API_Name: platform event type api name
- Publishing_User_Field: by default the Publishing_User field on Platform_Event_Log object is populated by the CreatedById on the platform event. Providing a field name (also supports dot notation) will override that default and use the value stored in this field. If the field does not exist or does not have a valid User id the Publishin_User field will be null.

