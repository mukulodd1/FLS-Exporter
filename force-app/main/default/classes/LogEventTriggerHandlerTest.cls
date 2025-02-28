/*
    Created By  : Mukul Odd
    Description : Test Class for LogEventTrigger,LogEventTriggerHandler
*/
@isTest
public with sharing class LogEventTriggerHandlerTest {
    @isTest
    static void testLogEvent(){
        Test.startTest();
            log_event__e levent = new log_event__e();
            levent.type__c = 'test Type';
            levent.log__c = 'test Log event';
            EventBus.publish(levent);
        Test.stopTest();

        List<logger__c> logList = [Select Id from logger__c];
        Assert.areEqual(true, logList.size()!= 0);
    
    }
}