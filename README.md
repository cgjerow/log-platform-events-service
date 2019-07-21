# Log Platform Events Service

## Dev, Build, and Test
Test coverage greater than 95% with assertions covering the vast majority of use cases.

## Custom Code
- LogPlatformEventsService & Test

## Configuration
### Custom Objects
- Platform_Event_Log: Main object used to store Platform Event logs. Tracks information such as the ReplayId, the user who published the log, and the platform event payload itself.
- Platform_Event_Log_Field: Child of the Platform_Event_Log object. Logs individual Platform Event field values, including nested values if the field on the Platform Event is valid JSON. The fields to be logged are configured in the Custom Metadata records.

### Custom Metadata
*Documentation Coming Soon*
