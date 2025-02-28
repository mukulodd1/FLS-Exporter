/*
    Created By: Mukul Odd (MTX)
*/
public without sharing class LogUtil {
    /* 
        Created By  : Mukul Odd 
        Params      : This funciton will create log records
    */
    public static void createLog(String logData){
        insert new logger__c(log__c=logData);
    }


    /* 
        Created By  : Mukul Odd 
        Params      : This funciton will create log records
    */
    public static void createLog(String logData,String type){
        insert new logger__c(log__c=logData,type__c=type);
    }
    

   /* 
       Created By  : Mukul Odd 
       Params      : This funciton will create log records
   */
   @future
   public static void createLogAsync(String logData){
       insert new logger__c(log__c=logData);
   }


   /* 
       Created By  : Mukul Odd 
       Params      : This funciton will create log records
   */
  @future
  public static void createLogAsync(String logData,String type){
      insert new logger__c(log__c=logData,type__c=type);
  }

  /*
    Created By : Mukul Odd
    Params     : This function is used to create log event records
  */
  public static void createLogEvent(String logData,String type){
     EventBus.publish(new log_event__e(log__c=logData,type__c=type)); 
  }

  /*
    Created By : Mukul Odd
    Desc       : This function is used to Send Emails
  */
  @future
  public static void sendEmail(String email,String body){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
        //mail.setSubject(email);
        //mail.setHtmlBody(htmlBodyStr);
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

  }
  

}