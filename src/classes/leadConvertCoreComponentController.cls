/*
    This is the controller for the leadConvertCoreComponent
*/
public with sharing class leadConvertCoreComponentController extends ComponentControllerBase {
    
    // prefix for the label of existing value
    private final string EXISTING = 'Attach to existing: ';
    
    // checkbox on the component indicating if there will be an email sent to the owner 
    public boolean sendOwnerEmail {get; set;}
    
    // This will hold the Opportunity for the Opportunity name on the comonent 
    public Opportunity opportunityID {get; set;}
    
    // Checkbox on the component indicating if an Opportunity should be created
    public Boolean doNotCreateOppty {get; set;}
    
    // This will hold the owner of Lead
    public Contact contactID {
        get {
            if (contactId == null) {
                contactID = new Contact(OwnerId = leadConvert.ownerId);
            }
            return contactId;
        }
        set;
    }

    // This will hold the contact lookup value
    public CampaignMember memberId {
        get {
            if (memberId == null) {
                memberId = new CampaignMember();
            }
            return memberId;
        }
        set;
    }

    //This is set by the <apex:attribute> and is the lead to convert
    public Lead leadConvert {
        get; 
        set {
            if (accounts == null) {
                system.debug('leadConvert set to ' + value);
                
                leadConvert = value;
                
                populateAccounts(); 
            }

            if (contacts == null) {

                populateContacts(); 
            }
        }
    }

    public List<Schema.FieldSetMember> getFields() {

        List<Schema.FieldSetMember> fieldSetFields = SObjectType.Lead.FieldSets.LeadConvertShowFields.getFields();
        for (String fieldSetName :Schema.SObjectType.Lead.fieldSets.getMap().keySet()) {

            // Check for custom fields set
            if (fieldSetName.containsIgnoreCase('leadconvertshowfields_custom')) {
                fieldSetFields = Schema.SObjectType.Lead.fieldSets.getMap().get(fieldSetName).getFields();
                break;
            }
        }

        return fieldSetFields;
    }

    // the list of accounts in the select list
    public List<SelectOption> accounts {get; set;}
    
    // the selected account in the select list of accounts
    public string selectedAccount {get; set;}

    // the list of contacts in the select list
    public List<SelectOption> contacts {get; set;}
    
    // the selected contact in the select list of contacts
    public string selectedContact {get; set;}

    //Constructor
    public leadConvertCoreComponentController() {
        // create a new Opportunity which will hold the Opportuniy name set by the user
        opportunityId = new Opportunity();
        
        List<npe01__Contacts_And_Orgs_Settings__c> settings = [SELECT npe01__Account_Processor__c FROM npe01__Contacts_And_Orgs_Settings__c];
        if (!settings.isEmpty() && settings[0].npe01__Account_Processor__c == 'Individual') {
            selectedAccount = 'Individual';
        }
        else {
            // set the selected Account to NONE by default
            selectedAccount = 'NONE';
        }

        // set the selected Contact to NONE by default
        selectedContact = 'NONE';

        doNotCreateOppty = true;
        sendOwnerEmail = false;
    }
    
    // Find an Account using SOSL based on the given company name
    private Account [] findCompany (string companyName) {
        
        //perform the SOSL query
        List<List<SObject>> searchList = [
            FIND :companyName 
            IN NAME FIELDS 
            RETURNING 
            Account(
                Id, 
                Name
            )
        ];
        
        List <Account> accountsFound = new List<Account>();
        
        for (List <sobject> sObjs : searchList) {
            
            for (sObject s : sObjs) {
                
                //add the account that was found to the list of found accounts
                accountsFound.add((Account) s);
            }   
        }
        
        // return the list of found accounts
        return accountsFound;
    }
    
    //populate the list of Accounts in the dropdown
    private void populateAccounts() {
        
        if (selectedAccount == 'Individual') {
            return;
        }

        if (leadConvert != null) {
                
            string company = leadConvert.Company;
            
            // find any accounts that match the SOSL query in the findCompany() method  
            Account [] accountsFound = findCompany(company + '*');
            
            accounts = new List<selectOption>();
            
            if (accountsFound != null && accountsFound.size() > 0) {
                
                // if there is at least 1 account found add a NONE option and a Create New Account option
                accounts.add(new SelectOption('NONE', '-None-'));
                
                accounts.add(new SelectOption('NEW', 'Create New Account: ' + company ));
                
                // for each account found, add an option to attach to the existing account
                for (Account a : accountsFound) {
                    
                    accounts.add(new SelectOption(a.Id, EXISTING + a.Name));
                }
                
            }
            
            else {
                
                // if no accounts matched then simply add a Create New Account option
                accounts.add(new SelectOption('NEW', 'Create New Account: ' + company ));
                
                system.debug('no account matches on company ' + company);
            }
            
            //the default opportunity name will be the lead's company
            opportunityId.Name = company + '-';
        }
        
        else
            system.debug('leadConvert = null');
            
    }
    
    // when the selected account in the select list of accounts changes this method is called 
    public PageReference accountChanged() {

        if (selectedAccount == 'Individual') {
            return null;
        }

        // if either the NONE option or the Create New Account option is selected, the Opportuniy Name is set to the lead's company
        if (selectedAccount == 'NEW' || selectedAccount == 'NONE') {
            opportunityId.Name = leadConvert.Company  + '-';
        }

        else {
            // otherwise find the account's Id and Name that was selected and set the Opportuity name to that Account
            Account [] a = [
                SELECT Id, Name 
                FROM Account WHERE Id = :selectedAccount];
            
            if (a.size() > 0) {
                opportunityId.Name = a[0].Name + '-';
            }
            
        }
        return null;
    }
    
    //this gets called when an existing account gets looked up via the lookup magnifying glass
    public PageReference accountLookedUp() {

        if (selectedAccount == 'Individual') {
            return null;
        }

        system.debug('!!! Account looked up --> ' + contactId.AccountId );
        
        //find the Id and Nmae of the Account that was looked up        
        Account [] a = [
            SELECT Id, Name 
            FROM Account WHERE Id = :contactId.AccountId];
        
        if (a.size() > 0) {
            
            // add the locked up account to the slect list
            accounts.add(new SelectOption(a[0].Id, EXISTING + a[0].Name));
            
            // set the selected account to the one that was just looked up by default
            selectedAccount = a[0].Id;
            
            // set the Opportunity name to the account's name that was looked up
            opportunityId.Name = a[0].Name + '-';
            
            system.debug('accounts --> ' + accounts);
        }
        
        return null;
    }

    // Find Contacts using SOSL based on the given lead email
    private Contact [] findContact (string email) {
        
        //perform the SOSL query
        List<List<SObject>> searchList = [
            FIND :email 
            IN EMAIL FIELDS 
            RETURNING 
            Contact(
                Id, 
                Name,
                //RecordType.DeveloperName,
                AccountId
            )
        ];
        
        List <Contact> contactsFound = new List<Contact>();
        
        for (List <sobject> sObjs : searchList) {
            
            for (sObject s : sObjs) {
                contactsFound.add((Contact) s);
            }   
        }
        
        return contactsFound;
    }
    
    // when the selected contact in the select list of contacts changes this method is called 
    public PageReference contactChanged() {

        // if either the NONE option or the Create New Contact option is selected
        if (selectedContact == 'NEW' || selectedContact == 'NONE') {
            return null;
        }

        else {

            // otherwise find the contact's Id that was selected
            Contact [] c = [
                SELECT Id, AccountId 
                FROM Contact WHERE Id = :selectedContact];
            
            if (c.size() > 0) {
                contactId.Id = c[0].Id;
                contactId.AccountId = c[0].AccountId;
            }

            system.debug('***** leadConvertCoreComponentController::contactChanged - contactId.AccountId c: ' + string.valueOf(c));
        }
        
        return null;
    }

    //populate the list of Contacts in the dropdown
    private void populateContacts() {
        
        if (leadConvert != null) {
                
            // find any contacts that match the SOSL query in the findContact() method  
            Contact [] contactsFound = findContact(leadConvert.Email + '*');
            
            contacts = new List<selectOption>();
            
            contacts.add(new SelectOption('NONE', '-None-'));

            if (contactsFound != null && contactsFound.size() > 0) {
                
                if (selectedAccount != 'Individual') {
                    contacts.add(new SelectOption('NEW', 'Create New Contact: ' + leadConvert.Name ));
                }
                
                // for each contact found, add an option to attach to the existing contact
                for (Contact a : contactsFound) {

                    String textLabel = EXISTING + a.Name + ' (';

                    if (a.get('RecordTypeId') <> null) {
                        RecordType recordType = Database.query('SELECT DeveloperName FROM RecordType WHERE Id = \'' + a.get('RecordTypeId').toString() + '\' LIMIT 1');
                        String recordTypeName = recordType.get('DeveloperName').toString();
                        textLabel += recordTypeName;
                    }

                    // Add Program Management - Engagements
                    pmdm__ProgramEngagement__c [] pmmEngagements = [
                        SELECT
                            pmdm__Program__r.Name 
                        FROM pmdm__ProgramEngagement__c
                        WHERE pmdm__Contact__c = :a.Id];
        
                    List<String> engagements = new List<String>();
                    if (pmmEngagements.size() > 0) {
                        for (pmdm__ProgramEngagement__c pmmEngagement :pmmEngagements) {
                            engagements.add(pmmEngagement.pmdm__Program__r.Name);
                        }
                    }
        
                    if (engagements.size() > 0) {
                        textLabel += ' - ' + engagements.toString();
                    }

                    textLabel +=  + ')';
        
                    contacts.add(new SelectOption(a.Id, textLabel));
                }
                
            }
            
            else {
                
                if (selectedAccount != 'Individual') {
                    // if no contacts matched then simply add a Create New Contact option
                    contacts.add(new SelectOption('NEW', 'Create New Contact: ' + leadConvert.Name ));
                }
                
                system.debug('no contact matches on Email ' + leadConvert.Email);
            }
        }
        
        else
            system.debug('leadConvert = null');
            
    }
    
    //this gets called when an existing contact gets looked up via the lookup magnifying glass
    public PageReference contactLookedUp() {
        system.debug('!!! Contact looked up --> ' + memberId.ContactId );
        
        List<Contact> a = Database.query('SELECT Id, Name, RecordTypeId, RecordType.DeveloperName, AccountId FROM Contact WHERE Id = \'' + memberId.ContactId + '\'');
        
        if (a.size() > 0) {
            
            String textLabel = EXISTING + a[0].Name + ' (';
            
            if (a[0].get('RecordTypeId') <> null) {
                String recordTypeName = a[0].get('RecordType.DeveloperName').toString();
                textLabel += recordTypeName;
            }

            // Add Program Management - Engagements
            pmdm__ProgramEngagement__c [] pmmEngagements = [
                SELECT
                    pmdm__Program__r.Name 
                FROM pmdm__ProgramEngagement__c
                WHERE pmdm__Contact__c = :memberId.ContactId];

            List<String> engagements = new List<String>();
            if (pmmEngagements.size() > 0) {
                for (pmdm__ProgramEngagement__c pmmEngagement :pmmEngagements) {
                    engagements.add(pmmEngagement.pmdm__Program__r.Name);
                }
            }

            if (engagements.size() > 0) {
                textLabel += ' - ' + engagements.toString();
            }
            textLabel +=  + ')';

            // add the locked up contact to the slect list
            contacts.add(new SelectOption(a[0].Id, textLabel));
            
            contactID.AccountId = a[0].AccountId;
            selectedContact = a[0].Id;
            
            system.debug('contacts --> ' + contacts);
        }
        
        return null;
    }

    // set up the Lead Status pick list
    public List<SelectOption> LeadStatusOption {
        
        get {
            
            
            if(LeadStatusOption == null) {
                
                LeadStatusOption = new List<SelectOption>();
                
                //get the lead statuses
                LeadStatus [] ls = [SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true ORDER BY SortOrder];
                
                // if there is more than 1 lead status option, add a NONE option  
                if (ls.size() > 1) {
                    LeadStatusOption.add(new SelectOption('NONE', '-None'));
                }
                
                // add the rest of the lead status options
                for (LeadStatus convertStatus : ls){
                    LeadStatusOption.add(new SelectOption(convertStatus.MasterLabel, convertStatus.MasterLabel));
                } 
                
            }
            
            return LeadStatusOption;
        }
        
        set;
    }
    
}