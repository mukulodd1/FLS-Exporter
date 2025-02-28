@isTest
public with sharing class LogUtilTest {
    @IsTest
    static void testLogs(){
        LogUtil.createLog('logData');
        LogUtil.createLog('logData','test');
        LogUtil.createLogAsync('logData');
        LogUtil.createLogAsync('logData','test');
        LogUtil.createLogEvent('logData','test');
    }
}