# Log Platform Events Service

## Dev, Build, and Test
Test coverage greater than 95% with assertions covering the vast majority of use cases.

## Custom Code
- lpes_CustomMetadataConfiguration & Test
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

