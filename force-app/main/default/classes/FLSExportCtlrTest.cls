/** 
 * *description  : Test Class for FLSExportCtlr
 */ 
@isTest
public with sharing class FLSExportCtlrTest {
    
    /*
    * @descripiton : Test Method For FLSExportCtlr.getMetadataOptions
    */
    @isTest 
    static void getMetadataOptionsTest(){    
            test.startTest();
            FLSExportCtlr.MetaDataOptionsWrapper wrapper = FLSExportCtlr.getMetaDataOptions();
            test.stopTest();
            System.assertEquals(true, wrapper!=null);
    }


    /*
    * @descripiton : Test Method For FLSExportCtlr.getPermissionsData
    */
    @isTest 
    static void getPermissionsDataTest(){    
            test.startTest();
            FLSExportCtlr.FLSInputWrapper inputWrapper= new FLSExportCtlr.FLSInputWrapper();
            inputWrapper.profileList = new List<String>{'System Administrator'};
            inputWrapper.objectList = new List<String>{'Account','Contact'};
            FLSExportCtlr.getPermissionsData(JSON.serialize(inputWrapper));
            test.stopTest();
            
    }

}