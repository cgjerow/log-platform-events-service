// Used as strategy pattern interface for lpes_LogPlatformEventsService
public interface lpes_IPlatformEventLogger 
{
    void logEvents(lpes_PlatformEventLogWrapper logs);
}