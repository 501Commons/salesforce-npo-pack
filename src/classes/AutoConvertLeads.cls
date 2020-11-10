// Code example sourced from https://automationchampion.com/tag/auto-convert-lead-using-process-builder/
//
Public class AutoConvertLeads
{
    @InvocableMethod
    public static void LeadAssign(List<Auto_Convert_Lead__c> leads)
    {
        LeadStatus CLeadStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true Limit 1];
        List<Database.LeadConvert> massLeadConvert = new List<Database.LeadConvert>();
        for (Auto_Convert_Lead__c currentLead: leads){
                Database.LeadConvert Leadconvert = new Database.LeadConvert();

                if (String.isBlank(currentLead.Lead__c)) {
                    continue;
                }
                Leadconvert.setLeadId(currentlead.Lead__c);

                if (!String.isBlank(currentLead.Account__c)) {
                    Leadconvert.setAccountId(currentLead.Account__c);                
                }

                Leadconvert.setConvertedStatus(CLeadStatus.MasterLabel);
                Leadconvert.setDoNotCreateOpportunity(TRUE);
                massLeadConvert.add(leadConvert);
        }
        
        if (!massLeadConvert.isEmpty()) {
            List<Database.LeadConvertResult> lcr = Database.convertLead(massLeadConvert);
        }
    }
}