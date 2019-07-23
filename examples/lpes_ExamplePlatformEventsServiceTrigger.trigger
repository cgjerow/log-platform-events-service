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

trigger lpes_ExamplePlatformEventsServiceTrigger on LogPlatformEventsServiceTestEvent__e (after insert) {


    // Quick Start with Custom Metadata Configuration
    
    new lpes_LogPlatformEventsService(Trigger.new, new lpes_CustomMetadataConfiguration('LogPlatformEventsServiceTestEvent__e')).logEvents();
    



    // Example of how the strategy pattern of the service 
    // allows you to create dynamic configurations at run time 
    // based on some conditions. 

    // Here we will look to see if the event list size > 1 (i.e. if it's batched)

    
    new lpes_LogPlatformEventsService(
        Trigger.new,
        new lpes_ExampleConcreteConfiguration(
            Trigger.new.size()>1,
            true,
            true,
            '',
            new list<string>{'JsonTextField__c'},
            'Batched LogPlatformEventsServiceTestEvent__e'
        )
    ).logEvents();
    
}