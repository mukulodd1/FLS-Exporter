/**
 ** @description : Controller Class for the FLSExport LWC
 ** Author : mukulodd1@gmail.com | Mukul Odd | Sep 24, 2022
 */

 public with sharing class FLSExportCtlr {
    //SELECT SObjectType, FROM ObjectPermissions GROUP BY SObjectType ORDER BY SObjectType ASC

    @AuraEnabled
    public static MetaDataOptionsWrapper getMetaDataOptions(){
        try {
            MetaDataOptionsWrapper wrapper= new MetaDataOptionsWrapper();

            //Generation Profile Options
            List<Profile> profileList = [SELECT Id, Name FROM Profile ORDER BY Name ASC]; 
            wrapper.profileOptions = getOptionList(profileList, 'Name', 'Name');
       
            //Generation Permission Set Options
            List<Permissionset> permissionSetList = [SELECT Id, Label FROM Permissionset WHERE profile.Name=null AND isCustom=true ORDER BY Label ASC];
            wrapper.permissionSetOptions = getOptionList(permissionSetList,'Label','Label');

            //Generation Permission Set Options
            List<String> objectOptionList = new List<String>();
            for(AggregateResult agg:[SELECT SObjectType FROM ObjectPermissions GROUP BY SObjectType ORDER BY SObjectType ASC]){
                objectOptionList.add((String)agg.get('SObjectType'));   
            }
            objectOptionList.sort();
            wrapper.objectOptions = getOptionList(objectOptionList);
            
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /**
     * * @description : Method to generate option List
     */
    public static List<SelectOption> getOptionList(List<sObject> sObjectList, String label, String value){
        List<SelectOption> optionList = new List<SelectOption>();
        for(sObject obj:sObjectList){
            SelectOption option = new SelectOption((String)obj.get(label),(String)obj.get(value));
            optionList.add(option);
        }
        return optionList;
    }


     /**
     * * @description : Method to generate option List
     */
    public static List<SelectOption> getOptionList(List<String> inputList){
        List<SelectOption> optionList = new List<SelectOption>();
        for(String str:inputList){
            SelectOption option = new SelectOption(str,str);
            optionList.add(option);
        }
        return optionList;
    }

    /*
    * @description : Method to fetch all the Input Permissions.
    */
    @AuraEnabled
    public static FLSExportWrapper getPermissionsData(String jsonString){
        try{
            FLSInputWrapper inputWrapper = (FLSInputWrapper)JSON.deserialize(jsonString, FLSInputWrapper.class);
            FLSExportWrapper exportWrapper = new FLSExportWrapper();
            
            
            List<String> profileList = new List<String>();
            List<String> permissionSetList = new List<String>();

            if(inputWrapper != null && inputWrapper.profileList !=null){
                profileList = inputWrapper.profileList;
            }

            if(inputWrapper != null && inputWrapper.permissionSetList != null){
                permissionSetList = inputWrapper.permissionSetList;
            }

            //Querying Field Permissions
            List<FieldPermissions> permissionList = [SELECT sObjectType, Field, PermissionsRead, PermissionsEdit, Parent.Profile.Name,Parent.IsOwnedByProfile,Parent.Label 
                                        FROM FieldPermissions 
                                        WHERE ParentId IN ( SELECT Id FROM permissionset WHERE PermissionSet.Profile.Name IN:profileList
                                                           OR permissionset.label IN :permissionSetList )
                                        AND sObjectType IN : inputWrapper.objectList ORDER BY sObjectType];

            //Querying Object Permissions
            List<ObjectPermissions> objectPermList = [SELECT Id,SObjectType,Parent.Label, Parent.Profile.Name, Parent.IsOwnedByProfile,   
                                                      PermissionsRead,PermissionsCreate,
                                                      PermissionsViewAllRecords, PermissionsModifyAllRecords,
                                                      PermissionsEdit, PermissionsDelete 
                                                      FROM ObjectPermissions WHERE
                                                      ParentId IN ( SELECT Id FROM permissionset WHERE PermissionSet.Profile.Name IN:profileList
                                                      OR permissionset.label IN :permissionSetList ) AND
                                                      SObjectType IN : inputWrapper.objectList ORDER BY sObjectType];
            
            Map <String, ObjectPermissions> objectPermMap = getObjectPermissions(inputWrapper.objectList,profileList, permissionSetList);
            
            // Loop for Profile Permissions
            for(FieldPermissions permission : permissionList){
                
                //Check to pass only profiles
                if(!permission.Parent.IsOwnedByProfile) continue;

                //Configuring Profiles
                ProfilePermissionWrapper profileWrapper = new ProfilePermissionWrapper();
                if(exportWrapper.profileNameToWrapperMap.containsKey(permission.Parent.Profile.Name)){
                    profileWrapper = exportWrapper.profileNameToWrapperMap.get(permission.Parent.Profile.Name);
                }else{
                    profileWrapper = new ProfilePermissionWrapper();
                    profileWrapper.profileName = permission.Parent.Profile.Name;
                    exportWrapper.profileNameToWrapperMap.put(profileWrapper.profileName, profileWrapper);
                }

                //Configuring Objects
                ObjectPermissionWrapper objectWrapper = new ObjectPermissionWrapper();
                if(profileWrapper.objectNameToWrapperMap.containsKey(permission.sObjectType)){
                    objectWrapper = profileWrapper.objectNameToWrapperMap.get(permission.sObjectType);
                }else {
                    objectWrapper = new ObjectPermissionWrapper();
                    objectWrapper.objectName = permission.sObjectType;
                    populateObjectPermissions(objectWrapper, profileWrapper.profileName, objectPermMap);
                    profileWrapper.objectNameToWrapperMap.put(permission.sObjectType, objectWrapper);
                }
                //Configuring Fields
                FieldPermissionWrapper fieldWrapper = new FieldPermissionWrapper(permission.Field,permission.PermissionsRead,permission.PermissionsEdit);
                objectWrapper.fieldPermissionList.add(fieldWrapper);
            }

            // Loop for Permission Set Permissions
            for(FieldPermissions permission : permissionList){
                
                //Check to pass only Permission Set
                if(permission.Parent.IsOwnedByProfile) continue;

                //Configuring Profiles
                PermissionSetPermissionWrapper permissionSetWrapper = new PermissionSetPermissionWrapper();
                if(exportWrapper.permissionSetNameToWrapperMap.containsKey(permission.Parent.Label)){
                    permissionSetWrapper = exportWrapper.permissionSetNameToWrapperMap.get(permission.Parent.Label);
                }else{
                    permissionSetWrapper = new PermissionSetPermissionWrapper();
                    permissionSetWrapper.permissionSetName = permission.Parent.Label;
                    exportWrapper.permissionSetNameToWrapperMap.put(permissionSetWrapper.permissionSetName, permissionSetWrapper);
                }

                //Configuring Objects
                ObjectPermissionWrapper objectWrapper = new ObjectPermissionWrapper();
                if(permissionSetWrapper.objectNameToWrapperMap.containsKey(permission.sObjectType)){
                    objectWrapper = permissionSetWrapper.objectNameToWrapperMap.get(permission.sObjectType);
                }else {
                    objectWrapper = new ObjectPermissionWrapper();
                    objectWrapper.objectName = permission.sObjectType;
                    populateObjectPermissions(objectWrapper, permissionSetWrapper.permissionSetName, objectPermMap);
                    permissionSetWrapper.objectNameToWrapperMap.put(permission.sObjectType, objectWrapper);
                }
                //Configuring Fields
                FieldPermissionWrapper fieldWrapper = new FieldPermissionWrapper(permission.Field,permission.PermissionsRead,permission.PermissionsEdit);
                objectWrapper.fieldPermissionList.add(fieldWrapper);
            }
            return exportWrapper;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
    *  Description : Method to fetch Object Permission
    */
    public static Map<String,ObjectPermissions> getObjectPermissions(List<String> objectList,
    List<String> profileList, List<String> permissionList){
         
         Map<String,ObjectPermissions> objPermWrapper = new Map<String,ObjectPermissions>();

         //Querying Object Permissions
         List<ObjectPermissions> objectPermList = [SELECT Id,SObjectType,Parent.Label, 
                    Parent.Profile.Name, Parent.IsOwnedByProfile,   
                    PermissionsRead,PermissionsCreate,
                    PermissionsViewAllRecords, PermissionsModifyAllRecords,
                    PermissionsEdit, PermissionsDelete 
                    FROM ObjectPermissions WHERE
                    ParentId IN ( SELECT Id FROM permissionset WHERE PermissionSet.Profile.Name IN:profileList
                    OR permissionset.label IN :permissionList ) AND
                    SObjectType IN : objectList ORDER BY sObjectType];

         for(ObjectPermissions objPerm : objectPermList){

            //Checking if the Object Permission Belong to Profile
            if(String.isNotBlank(objPerm.Parent.Profile.Name)){
                objPermWrapper.put(getObjPermissionMapKey(objPerm.Parent.Profile.Name,objPerm.sObjectType), objPerm);
            }
            //If Object Permission Does not belong to Profile then it
            // Belongs to Permission Set.
            else{
                objPermWrapper.put(getObjPermissionMapKey(objPerm.Parent.Label,objPerm.sObjectType), objPerm);
            }
         }
         return objPermWrapper;
    }

    /*
        Description : Method to getObject Permission Map Key
    */
    private static string getObjPermissionMapKey(String resName, String objName){
        return resName +'::'+objName;
    }

    /*
        Description : Method to Populate Object Permissions
    */
    private static void populateObjectPermissions(ObjectPermissionWrapper wrap, 
            string resName,  Map <String, ObjectPermissions> objectPermMap){
        ObjectPermissions objPerm        = objectPermMap.get(getObjPermissionMapKey(resName,wrap.objectName));   
        
        wrap.createPermission     = objPerm.PermissionsCreate;
        wrap.viewPermission       = objPerm.PermissionsRead;
        wrap.editPermission       = objPerm.PermissionsEdit;
        wrap.deletePermission     = objPerm.PermissionsDelete;
        wrap.viewAllPermission    = objPerm.PermissionsViewAllRecords;
        wrap.modifyAllPermission  = objPerm.PermissionsModifyAllRecords;
    }
    
    /*
    * description : Input FLS Wrapper
    */
    public class FLSInputWrapper{
        @AuraEnabled public List<String> permissionSetList;
        @AuraEnabled public List<String> profileList;
        @AuraEnabled public List<String> objectList;
    }



    /* 
     *description : Wraper to Store all Permissions.
    */
    public class FLSExportWrapper{
        @AuraEnabled public Map<String,PermissionSetPermissionWrapper> permissionSetNameToWrapperMap;
        @AuraEnabled public Map<String,ProfilePermissionWrapper> profileNameToWrapperMap;   

        /*
          * @description : Empty Constructor
        */
        public FLSExportWrapper(){
            this.permissionSetNameToWrapperMap = new Map<String,PermissionSetPermissionWrapper>();
            this.profileNameToWrapperMap = new Map<String,ProfilePermissionWrapper>();
        }
    }


    /*
     * *@description : Wrapper to Store Permissions Set Permission
    */
    public class PermissionSetPermissionWrapper{
        @AuraEnabled public  string permissionSetName;
        @AuraEnabled public  Map<String,ObjectPermissionWrapper> objectNameToWrapperMap;

        /*
          * @description : Empty Constructor
        */
        public PermissionSetPermissionWrapper(){
            this.objectNameToWrapperMap = new Map<String,ObjectPermissionWrapper>();
        }
    }

    /*
     * *@description : Wrapper to Store Profile Permissions
    */
    public class ProfilePermissionWrapper{
        @AuraEnabled public  string profileName;
        @AuraEnabled public  Map<String,ObjectPermissionWrapper> objectNameToWrapperMap;

        /*
          * @description : Empty Constructor
        */
        public ProfilePermissionWrapper(){
            this.objectNameToWrapperMap =new Map<String,ObjectPermissionWrapper>();
        }
    }

    /*
     * *@description : Wrapper to Store object Permissions
    */
    public class ObjectPermissionWrapper{
        @AuraEnabled public string objectName;
        @AuraEnabled public Boolean viewPermission;
        @AuraEnabled public Boolean deletePermission;
        @AuraEnabled public Boolean createPermission;
        @AuraEnabled public Boolean editPermission;
        @AuraEnabled public Boolean viewAllPermission;
        @AuraEnabled public Boolean modifyAllPermission;
        @AuraEnabled public List<FieldPermissionWrapper> fieldPermissionList;


        /*
          * @description : Empty Constructor
        */
        public ObjectPermissionWrapper(){
            this.fieldPermissionList = new  List<FieldPermissionWrapper>();
        }
    }
    
    
    /**
     * *@description : Wrapper to Store Permissions 
    */ 
    public class FieldPermissionWrapper{
        @AuraEnabled public string field;
        @AuraEnabled public Boolean readAccess;
        @AuraEnabled public Boolean writeAccess;

        /*
          * @description : Empty Constructor
        */
        public FieldPermissionWrapper(){

        }

        /*
        * @description : Paramaterized Constructor
        */
        public FieldPermissionWrapper(String field, Boolean readAccess, Boolean writeAccess){
            this.field=field;
            this.readAccess=readAccess;
            this.writeAccess=writeAccess;
        }
    }

    /**
     * *@description : Wrapper Class for Metadata Options.
     */
    public class MetaDataOptionsWrapper{
        @AuraEnabled public List<SelectOption> permissionSetOptions;
        @AuraEnabled public List<SelectOption> profileOptions;
        @AuraEnabled public List<SelectOption> objectOptions;
    }


    /**
     ** @description :  Wrapper class to contain a list option
     */
    public class SelectOption{
        @AuraEnabled public string label;
        @AuraEnabled public string value;

        /*
        * @description : Empty Constructor
        */
        public SelectOption(){

        }

        /*
        * @description : Paramaterized Constructor
        */
        public SelectOption(String label, String value){
            this.label=label;
            this.value=value;
        }
    }
}