trigger AccountTriggerEmpty on Account (after insert, after update)
{
	AcctTriggerHandler ath = new AcctTriggerHandler(Trigger.oldMap, Trigger.newMap);
    ath.handleTrigger();
}