trigger LogEventTrigger on log_event__e (after insert) {
    LogEventTriggerHandler.generateLogRecord(Trigger.new);
}