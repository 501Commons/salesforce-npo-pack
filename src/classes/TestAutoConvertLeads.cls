@isTest
private class TestAutoConvertLeads {

    static testMethod void myUnitTest() {
        Account newAccount = new Account(
          name = 'Test Account'
        );
        Insert newAccount;

        Contact newContact = new Contact(
          LastName = 'Test Lead',
          FirstName = 'First',
          Email = 'email@domain.com',
          AccountId = newAccount.Id
//          ,Imported_From__c = 'Imagine'
        );
        
        Insert newContact;

        Lead newLead = new Lead(
                        Company = 'Test Account', 
                        LastName = 'Test Lead',
                        LeadSource = 'Web',  
                        Status = 'Closed - Converted'
//                        ,c501_cm__Training_Status__c = 'Pending'
        );
        
        Insert newLead;

        AutoConvertLeads.LeadAssign(new List<Auto_Convert_Lead__c> { new Auto_Convert_Lead__c(
          Lead__c = newLead.Id,
          Account__c = newAccount.Id) });

        Lead convertedLead = [SELECT Id FROM Lead WHERE ConvertedAccountId = :newAccount.Id LIMIT 1];
        System.assertEquals(convertedLead.Id, newLead.Id, 'Error - convert lead expected to be related to the account');
   } 
}