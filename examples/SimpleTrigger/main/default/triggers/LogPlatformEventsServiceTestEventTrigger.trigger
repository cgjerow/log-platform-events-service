/*
* LogPlatformEventsService EXAMPLE TRIGGER
*
* This is an example trigger and is not required for the LogPlatformEventsService functionality.
* In order to set up logging for any Platform Event you just need to
* copy the line from this trigger into a trigger for the desired Platform Event
*
* If you want more conditional / dynamic configurations built at run time, look at the second example
* This outlines a simple check to see if this is a single event or a batch
* It either just debugs to logs or generates Platform Event Log records depending on that condition
*/

trigger LogPlatformEventsServiceTestEventTrigger on LogPlatformEventsServiceTestEvent__e (after insert) {

    // Quick Start with Custom Metadata Configuration
        
    CustomMetadataEventLogConfiguration config = new CustomMetadataEventLogConfiguration('platform_event_type_api_name__c','LogPlatformEventsServiceTestEvent__e');
    new lpes_SObjectPlatformEventLogger(config.isLogRecords, config.isDebug).logEvents(new lpes_PlatformEventLogFactory(config).buildLogs(trigger.new));



    /*
    // Example of how the template pattern of the service 
    // allows you to create dynamic configurations at run time
    */

    // In this case we will look to see if the event list size > 1 (i.e. if it's batched)

    
    new lpes_SObjectPlatformEventLogger(trigger.new.size()>1, true)
        .logEvents( 
            new lpes_PlatformEventLogFactory (
                new ConcreteLogPlatformEventsConfiguration(
                    true,
                    '',
                    new list<string>{'JsonTextField__c'},
                    'Batched LogPlatformEventsServiceTestEvent__e'
                )
            )
        .buildLogs(trigger.new) );

}