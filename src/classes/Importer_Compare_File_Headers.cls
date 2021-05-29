global class Importer_Compare_File_Headers {
   
    @InvocableMethod
    public static List<Boolean> equalFileHeaders(List<ID> importerInstances) {

      System.Debug(LoggingLevel.DEBUG, 'Importer_Compare_File_Headers::equalFileHeaders - importerInstances: ' + importerInstances);

      if (importerInstances.size() <> 1) {
         System.Debug(LoggingLevel.ERROR, 'input variable importerInstances invalid - size: ' + importerInstances.size());
         return new List<Boolean> { false };
      }

      Import_Instance__c importerInstance = [SELECT Id, Import_Definition__c FROM Import_Instance__c WHERE Id = :importerInstances[0] LIMIT 1];

      // Loop Definition Templates
      List<ID> contentDocLinks = new List<ID>();
      for (ContentDocumentLink contentDocLink :[
         SELECT ContentDocumentId
         FROM ContentDocumentLink
         WHERE (LinkedEntityId = :importerInstance.Import_Definition__c OR LinkedEntityId = :importerInstance.Id)]) {
            contentDocLinks.add(contentDocLink.ContentDocumentId);
         }
      
      if (contentDocLinks.size() < 2 || Math.mod(contentDocLinks.size(), 2) <> 0) {
         System.Debug(LoggingLevel.ERROR, 'Number files found: ' + contentDocLinks.size() + '.  Missing 1 or more files');
         return new List<Boolean> { false };
      }

      List<ContentVersion> contentVersions = [
         SELECT VersionData, Title, FileType
         FROM ContentVersion
         WHERE ContentDocumentId in :contentDocLinks AND IsLatest = true
      ];

      if (contentVersions.size() <> contentDocLinks.size()) {
         System.Debug(LoggingLevel.ERROR, 'Content versions found: ' + contentVersions.size() + ' not equal to the number of files: ' + contentDocLinks.size());
         return new List<Boolean> { false };
      }
      
      Integer index = contentVersions.size() - 1;
      Integer matchCount = 0;
      Boolean cpuLimitExceeded = false;
      for (Integer sourceIndex = index; sourceIndex > 0; sourceIndex--) {

         System.Debug(LoggingLevel.DEBUG, 'Source Title: ' + contentVersions[sourceIndex].Title + ' FileType: ' + contentVersions[sourceIndex].FileType);
         String sourceVersionData = contentVersions[sourceIndex].VersionData.toString();

         for (Integer targetIndex = sourceIndex - 1; targetIndex >= 0; targetIndex--) {

            System.Debug(LoggingLevel.DEBUG, 'Target Title: ' + contentVersions[targetIndex].Title + ' FileType: ' + contentVersions[targetIndex].FileType);
            if (contentVersions[sourceIndex].Title == contentVersions[targetIndex].Title && contentVersions[sourceIndex].FileType == contentVersions[targetIndex].FileType) {

               String targetVersionData = contentVersions[targetIndex].VersionData.toString();
               Integer compareLength = sourceVersionData.length() < targetVersionData.length() ? sourceVersionData.length() : targetVersionData.length();

               for (Integer compareIndex = 1; compareIndex <= compareLength; compareIndex++) {

                  // Limit CPU time to 50%
                  if (Limits.getCpuTime() < Limits.getLimitCpuTime() / 2) {

                     if (sourceVersionData.left(compareIndex) <> targetVersionData.left(compareIndex)) {

                        System.Debug(LoggingLevel.ERROR, 'Headers Not Equal');
                        System.Debug(LoggingLevel.DEBUG, 'Compare Index: ' + compareIndex);
                        System.Debug(LoggingLevel.DEBUG, 'Source Version Data: ' + sourceVersionData.left(compareIndex));
                        System.Debug(LoggingLevel.DEBUG, 'Target Version Data: ' + targetVersionData.left(compareIndex));

                        importerInstance.Last_Error_Message__c = Date.today() + ' - ' + ' ERROR: Headers Not Equal for ' + contentVersions[sourceIndex].Title + ' at character position ' + compareIndex;

                        if (!Test.isRunningTest()) {
                           update importerInstance;
                        }
      
                        return new List<Boolean> { false };
                     }
                  } else {
                     cpuLimitExceeded = true;

                     System.Debug(LoggingLevel.DEBUG, 'CPU Time Limit exceeded');
                     System.Debug(LoggingLevel.DEBUG, 'Compare Index: ' + compareIndex);
                     System.Debug(LoggingLevel.DEBUG, 'Source Version Data: ' + sourceVersionData.left(compareIndex));
                     System.Debug(LoggingLevel.DEBUG, 'Target Version Data: ' + targetVersionData.left(compareIndex));

                     importerInstance.Last_Error_Message__c = Date.today() + ' - ' + ' WARNING: CPU Time Limit Exceeded for ' + contentVersions[sourceIndex].Title + ' at character position ' + compareIndex + '.  Check Import Definition file to make sure only includes the header and no other data.';

                     if (!Test.isRunningTest()) {
                        update importerInstance;
                     }

                     break;
                  }
               }

               matchCount++;
            }
         }
      }

      if (matchCount <> (contentVersions.size() / 2)) {
         System.Debug(LoggingLevel.DEBUG, 'File header match count: ' + matchCount + ' not equal to expected count: ' + (contentVersions.size() / 2));
         return new List<Boolean> { false };
      }

      importerInstance.Last_Error_Message__c = '';

      if (!cpuLimitExceeded && !Test.isRunningTest()) {
         update importerInstance;
      }

      return new List<Boolean> { true };
   }
}