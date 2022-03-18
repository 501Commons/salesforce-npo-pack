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

@isTest
public class CTRL_CampaignHistoryView_TEST {
    
    //==================== TEST METHOD(s) ======================================

    @isTest(SeeAllData='true')
    public static void CodeCoverageTests() {

        Contact contact = new Contact(
          LastName = 'TEST LastName'
        );

        Database.insert(contact, false);

        // Wrap in Id checks to protect against required fields added by custom fields
        //  Future improvement is query for required fields and populate with valid values
        //
        if (!String.isBlank(contact.Id)) {
          Campaign campaign = new Campaign(
            Name = 'TEST Name'
          );

          Database.insert(campaign, false);

          if (!String.isBlank(campaign.Id)) {
            CampaignMember campaignMember = new CampaignMember(
              CampaignId = campaign.Id,
              ContactId = contact.Id
            );

            Database.insert(campaignMember, false);
          }
        }

        Test.StartTest();

        CTRL_CampaignHistoryView ctrl = new CTRL_CampaignHistoryView();

        // StopTest will make sure any future, schedulable, and batch calls complete before proceeding
        Test.StopTest();

        // Filter by Name
        List<SelectOption> searchFilters = ctrl.listSOCustomSearchFilters;
        ctrl.ResetCampaignMembers();
        ctrl.FilterRelativeDateName = 'All';
        ctrl.ChangeListView();

        System.Assert(ctrl.listSORelativeDates.size() > 1);
        System.Assert(ctrl.listCampaignHistory.size() > 0);
    }

}