/*
* LogPlatformEventsService EXAMPLE TRIGGER
*
* This is an example trigger and is not required for the LogPlatformEventsService functionality.
* In order to set up logging for any Platform Event you just need to
* copy the line from this trigger into a trigger for the desired Platform Event
*
*/

trigger LogPlatformEventsServiceTestTrigger on LogPlatformEventsServiceTestEvent__e (after insert) {
    new LogPlatformEventsService(Trigger.new).logEvents();
}
