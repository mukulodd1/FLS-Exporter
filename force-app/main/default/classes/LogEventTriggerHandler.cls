public with sharing class LogEventTriggerHandler {
    
    public static void generateLogRecord(List<log_event__e> logEventList){
        List<logger__c> logList = new List<logger__c>();
        for(log_event__e le : logEventList){
            logger__c log = new logger__c();
            log.log__c = le.log__c;
            log.type__c = le.type__c;
            logList.add(log); 
        }
        
        if(!logList.isEmpty()){ 
            insert logList;
        }
    }

}