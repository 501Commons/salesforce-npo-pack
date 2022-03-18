/*
    Nonprofit Salesforce © 2022 by 501 Commons is licensed under CC BY 4.0, Copyright (c) 2016, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.
 
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/

public virtual without sharing class CTRL_CampaignHistoryView {

    private List<String> listStrFields;
    private String orderByField = 'Campaign.CreatedDate';
    private String customSearchFilterAPIName;
    public Contact contact { get; private set; }
    
    // constructor
    public CTRL_CampaignHistoryView() {

        System.Debug(LoggingLevel.DEBUG, '***** CTRL_CampaignHistoryView::CTRL_CampaignHistoryView Constructor');

        this.contact = new Contact( 
            Id = ApexPages.currentPage().getParameters().get('id')
        );

        // Get list of fields FROM fieldset
        listStrFields = new List<String>();
        for (Schema.FieldSetMember f : this.getFields()) {
            if (f.getFieldPath().containsIgnoreCase('date')) {
                this.orderByField = f.getFieldPath();
            }
            listStrFields.add(f.getFieldPath());
        }

        // Required fields
//        if (!ListPartialContains(listStrFields, 'Id')) {
//            listStrFields.add('Id');
//        }
    }   
    
    //
    //  OnPageLoad added to do the inialization so that any DML calls while initializing are commited to the database.
    //      For Instance if you just reference listAccounts getter in a datatable then any DML calls are cached in memory and not committed until there is an action invoked (e.g., ChangeAccount, SaveAccount)
    //          Non-Action (DML Calls will be cached & not committed unless you trigger an action):     <apex:dataTable value="{!listAccounts}" ...
    //          Action (DML Calls will be committed):                                                   <apex:commandButton styleClass="slds-button slds-button_brand" action="{!SaveAccounts}" ...
    //
    public void OnPageLoad() {

        // Initialize data
        this.getFields();
        List<CampaignMember> displayObjects = this.listCampaignHistory;
        List<SelectOption> objectsFilter = this.listSORelativeDates;
    }
/*
    private Boolean ListPartialContains(List<String> listStrFields, String fieldValue) {

        if (listStrFields == null) {
            return false;
        }

        for (String listValue :listStrFields) {
            if (listValue.contains(fieldValue)) {
                return true;
            }
        }

        return false;
    }
*/
    public List<SelectOption> listSOCustomSearchFilters {
        get {
            if (listSOCustomSearchFilters == null) {

                c501_npo_settings__c customFilterOptionSettings = c501_npo_settings__c.getOrgDefaults();
                if (customFilterOptionSettings == null || String.isBlank(customFilterOptionSettings.Campaign_History_Custom_Filter__c)) {
                    return null;
                }

                // Expecting format: [Custom_Field_API_Name]:CSV of picklist options
                if (customFilterOptionSettings.Campaign_History_Custom_Filter__c.split(':').size() != 2) {
                    return null;
                }

                // Expecting Name Format: [Display Name],[API Name]
                String fieldName = customFilterOptionSettings.Campaign_History_Custom_Filter__c.split(':')[0];
                if (fieldName.split(',').size() != 2) {
                    return null;
                }

                String customSearchName = fieldName.split(',')[0];
                this.customSearchFilterAPIName = fieldName.split(',')[1];

                listSOCustomSearchFilters = new List<SelectOption> {
                    new SelectOption('Select ' + customSearchName, 'Select ' + customSearchName)
                };

                String fieldValues = customFilterOptionSettings.Campaign_History_Custom_Filter__c.split(':')[1];
                for (String customFilterOption :fieldValues.split(',')) {
                    listSOCustomSearchFilters.add(new SelectOption(customFilterOption, customFilterOption));
                }
            }

            return listSOCustomSearchFilters;
        }

        set;
    }
    
    public List<SelectOption> listSORelativeDates {
        get {
            if (listSORelativeDates == null)
                // Query to get all ListView
                listSORelativeDates = new List<SelectOption> { 
                    new SelectOption('Select Relative Date', 'Select Relative Date'),
                    new SelectOption('THIS_FISCAL_YEAR', 'This Fiscal Year'),
                    new SelectOption('LAST_FISCAL_YEAR', 'Last Fiscal Year'),
                    new SelectOption('NEXT_FISCAL_YEAR', 'Next Fiscal Year'),
                    new SelectOption('THIS_YEAR', 'This Year'),
                    new SelectOption('LAST_YEAR', 'Last Year'),
                    new SelectOption('NEXT_YEAR', 'Next Year'),
                    new SelectOption('THIS_MONTH', 'This Month'),
                    new SelectOption('LAST_MONTH', 'Last Month'),
                    new SelectOption('NEXT_MONTH', 'Next Month'),
                    new SelectOption('All', 'All')
                };

            return listSORelativeDates;
        }

        set;
        }

    public Schema.FieldSet fieldSetActive {
        get {

            Schema.FieldSet fieldSetCheck = SObjectType.CampaignMember.FieldSets.CampaignHistoryShowFields;
            for (String fieldSetName :Schema.SObjectType.CampaignMember.fieldSets.getMap().keySet()) {

                // Check for custom fields set
                if (fieldSetName.containsIgnoreCase('CampaignHistoryShowFields_Custom')) {
                    fieldSetCheck = Schema.SObjectType.CampaignMember.fieldSets.getMap().get(fieldSetName);
                    break;
                }
            }

            return fieldSetCheck;
        }
        set;
    }

    // getter - reference in Visualforce as fields
    public List<Schema.FieldSetMember> getFields() {
        return fieldSetActive.getFields();
    }

    public String FilterRelativeDateName {
        get;
        set;
    }

    public String FilterCustomSearch {
        get;
        set;
    }

    // the user has changed the CampaignMember dropdown
    public virtual PageReference ChangeListView() {

        this.listCampaignHistory = null;

        return null;
    }

    public virtual void ResetCampaignMembers() {

        System.Debug(LoggingLevel.DEBUG, '***** CTRL_CampaignHistoryView::ResetCampaignMembers');

        listSORelativeDates = null;
        listCampaignHistory = null;
    }

    // The list of contacts.
    public List<CampaignMember> listCampaignHistory {
        get {
            if (listCampaignHistory == null) {
                this.listCampaignHistory = new List<CampaignMember>();
                FillListCampaignMembers();
            }

            return listCampaignHistory;
        }
        
        set;
    }
        
    // helper function that the client can override, to query for the appropriate fields in Contacts.
    public virtual void FillListCampaignMembers() {

        if (String.isBlank(this.FilterRelativeDateName) || this.FilterRelativeDateName.equalsIgnoreCase('Select Relative Date')) {
            return;
        }

        String strSoql = 'SELECT ' + String.join(listStrFields, ',');
        strSoql += ' FROM CampaignMember ';
        if (!String.isBlank(this.contact.Id)) {
            strSoql += ' WHERE LeadOrContactId = \'' + this.contact.Id + '\'';
        }
        if (this.FilterRelativeDateName <> 'All') {
            strSoql += ' AND ' + this.orderByField + ' = ' + this.FilterRelativeDateName;
        }
        if (!String.isBlank(this.FilterCustomSearch) 
            && !this.FilterCustomSearch.containsIgnoreCase('Select ')
            && !String.isBlank(this.customSearchFilterAPIName)) {

            strSoql += ' AND ' + this.customSearchFilterAPIName + ' = \'' + this.FilterCustomSearch + '\'';
        }
        strSoql += ' ORDER BY ' + this.orderByField + ' DESC NULLS FIRST';
        
        System.Debug(LoggingLevel.DEBUG, '***** ' + String.valueOf(this).substring(0,String.valueOf(this).indexOf(':')) + '::FillListCampaignMembers CampaignMember Query strSoql: ' + strSoql);

        for (CampaignMember objectRecord :Database.Query(strSoql) ) {
            listCampaignHistory.add(objectRecord);
        }
    }

    /*
    public void GetListViewRecords() {

        //Make sure your Salesforce instance URL is added in remote site settings
        String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm(); 
        String restAPIURL = sfdcURL + '/services/data/v52.0/ui-api/list-ui/Contact/All_Substitutes';  

        HttpRequest httpRequest = new HttpRequest();  
        httpRequest.setMethod('GET');   
        httpRequest.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());        
        httpRequest.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
        httpRequest.setEndpoint(restAPIURL);  
        String response = '';
        try {  
                Http http = new Http();   
                HttpResponse httpResponse = http.send(httpRequest);  
                if (httpResponse.getStatusCode() == 200 ) {  
                    response = JSON.serializePretty( JSON.deserializeUntyped(httpResponse.getBody()) );  
                } else {  
                    System.debug(' httpResponse ' + httpResponse.getBody() );  
                    throw new CalloutException( httpResponse.getBody() );  
                }   
        } catch( System.Exception e) {  
                System.debug('ERROR: '+ e);  
                throw e;  
        }  
        System.debug(' ** response ** : ' + response );  
    }
*/
}