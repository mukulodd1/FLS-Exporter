/* eslint-disable guard-for-in */
import { LightningElement } from 'lwc';
import getMetaDataOptions from '@salesforce/apex/FLSExportCtlr.getMetaDataOptions';
import getPermissionsData from '@salesforce/apex/FLSExportCtlr.getPermissionsData';
import { loadScript} from 'lightning/platformResourceLoader';
import sheetjs from '@salesforce/resourceUrl/xlsx';

let XLS = {};
export default class FLSExport extends LightningElement {
    
    response={};
    dataObj={};
    excelData={};
    showSpinner=false;
    connectedCallback(){
        this._getMetaDataOptions();
        this._loadScripts();
    }

    _loadScripts(){
        Promise.all([
            loadScript(this,sheetjs)
        ]).then(() => {
            console.log('loaded');
            XLS = XLSX;
        }).catch(err=>{
            console.error('ERROR: '+err);
            console.error('ERROR: '+JSON.stringify(err));
        });
    }

    /*
    * method to fetch the metadata options
    */
    _getMetaDataOptions(){
        this.showSpinner=true;
        getMetaDataOptions({}).then(res=>{
            console.log('Response is : '+JSON.stringify(res));
            if(res!=null){
                this.response=res;
            }
        }).catch(err=>{
            console.log('Error: '+JSON.stringify(err));
        }).finally(fnl=>{
            this.showSpinner=false;
        });
    }

    /*
    * Method to handle the change Events.
    */
    handleChange(event){
       this.dataObj[event.target.name]=event.target.value;
    }

    /*
    * Method to handle the Export Events.
    */
    handleExport(){
        this._getPermissionsData();
    }

    /*
    * Method to fetch Permissions.
    */
    _getPermissionsData(){
        console.log('JSON String is : '+JSON.stringify(this.dataObj));
        this.showSpinner=true;
        getPermissionsData({'jsonString':JSON.stringify(this.dataObj)}).then(res=>{
            console.log('Result is: '+JSON.stringify(res));
            if(res!=null){
                this.excelData=res;
                this.generateSheetProfile();
                this.generateSheetPermissionSet();
            }
        }).catch(err=>{
            console.error('ERROR is: '+JSON.stringify(err));
        }).finally(fnl=>{
            this.showSpinner=false;
        });
    }

  
    //-----------------------------------------------------   CODE To Generate Excel ----------------------------------------------------------------------------------------
    generateExcel(){
        var ws_data = [
            ["Column 1"],
            [1]
          ];
          var ws = XLS.utils.aoa_to_sheet(ws_data);
          var ws_data2 = [
            ["Column 2"],
            [2]
          ];
          var ws2 = XLS.utils.aoa_to_sheet(ws_data2);
          
          const wb = XLS.utils.book_new();
          XLS.utils.book_append_sheet(wb, ws, "SheetJS1");
          XLS.utils.book_append_sheet(wb, ws2, "SheetJS2");
          XLS.writeFile(wb, "sheetjs.xlsx");
    }


    columnHeaders = ['Field', 'Read Access', 'Write Access'];
    wscols = [
        {wch: 30}, // "characters"
        {wch: 20},
        {wch: 20}
    ];
    /* 
       * description : Method to generate sheets for Profiles
    */
    generateSheetProfile(){
        if(this.excelData.profileNameToWrapperMap == null || Object.keys(this.excelData.profileNameToWrapperMap).length === 0  ) {
            return ;
        }
        
        //Iterating over profile
        for (const profileName in this.excelData.profileNameToWrapperMap) {
            let profile = this.excelData.profileNameToWrapperMap[profileName];
            if(profile.objectNameToWrapperMap == null || Object.keys(profile.objectNameToWrapperMap).length === 0  ){
                continue;
            }

            let sObjectData =  profile.objectNameToWrapperMap;
            const wb = XLS.utils.book_new();
            for(const objectName in sObjectData){
                  if(sObjectData[objectName].fieldPermissionList==null || sObjectData[objectName].fieldPermissionList.length === 0){
                    continue;
                  }           
                  let sheetData = this.getSheetData(sObjectData[objectName].fieldPermissionList);
                  let ws = XLS.utils.aoa_to_sheet(sheetData);
                  ws['!cols'] = this.wscols;
                  XLS.utils.book_append_sheet(wb, ws, objectName);
            }
            XLS.writeFile(wb, profileName +'|Profile.xlsx');
        }
    }

    /* 
       * description : Method to generate sheets for Profiles
    */
    generateSheetPermissionSet(){
        if(this.excelData.permissionSetNameToWrapperMap == null || Object.keys(this.excelData.permissionSetNameToWrapperMap).length === 0  ) {
            return ;
        }
        
        //Iterating over profile
        for (const permissionSetName in this.excelData.permissionSetNameToWrapperMap) {
            let permissionSet = this.excelData.permissionSetNameToWrapperMap[permissionSetName];
            if(permissionSet.objectNameToWrapperMap == null || Object.keys(permissionSet.objectNameToWrapperMap).length === 0  ){
                continue;
            }

            let sObjectData =  permissionSet.objectNameToWrapperMap;
            const wb = XLS.utils.book_new();
            for(const objectName in sObjectData){
                  if(sObjectData[objectName].fieldPermissionList==null || sObjectData[objectName].fieldPermissionList.length === 0){
                    continue;
                  }           
                  let sheetData = this.getSheetData(sObjectData[objectName].fieldPermissionList);
                  let ws = XLS.utils.aoa_to_sheet(sheetData);
                  ws['!cols'] = this.wscols;
                  XLS.utils.book_append_sheet(wb, ws, objectName);
            }
            XLS.writeFile(wb, permissionSetName +'|PermissionSet.xlsx');
        }
    }

    getSheetData(permissionList){
            let data = [this.columnHeaders];
            permissionList.forEach(ele=>{
                    let row = [ele.field,ele.readAccess, ele.writeAccess];
                    data.push(row);
            });
        return data;
    }
}