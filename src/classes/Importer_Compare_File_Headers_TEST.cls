/*
    Copyright (c) 2016, Salesforce.org
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
public class Importer_Compare_File_Headers_TEST {
    
    //==================== TEST METHOD(s) ======================================

    @isTest(SeeAllData='false')
    public static void CodeCoverageTests() {

        Test.StartTest();

        Import_Definition__c importDefinition = new Import_Definition__c(
          Name = 'TEST Import Definition'
        );

        Database.insert(importDefinition);

        Import_Instance__c importInstance = new Import_Instance__c(
          Import_Definition__c = importDefinition.Id
        );

        Database.insert(importInstance);

        // Create Definition File
        //
        ContentVersion contentVersionDefinition = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionDefinition;

        contentVersionDefinition = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionDefinition.Id LIMIT 1];

        insert new ContentDocumentLink (
          ContentDocumentId = contentVersionDefinition.ContentDocumentId,
          LinkedEntityId = importDefinition.Id
        );

        // Create Instance File
        //
        ContentVersion contentVersionInstance = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInstance;

        contentVersionInstance = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInstance.Id LIMIT 1];

        insert new ContentDocumentLink (
          ContentDocumentId = contentVersionInstance.ContentDocumentId,
          LinkedEntityId = importInstance.Id
        );

        // Success Check - both files
        List<Boolean> results = Importer_Compare_File_Headers.equalFileHeaders(new List<ID> { importInstance.Id });

        // StopTest will make sure any future, schedulable, and batch calls complete before proceeding
        Test.StopTest();

        System.Assert(results[0]);
    }

    @isTest(SeeAllData='false')
    public static void NegativeCheck_NoFiles() {

        Test.StartTest();

        Import_Definition__c importDefinition = new Import_Definition__c(
          Name = 'TEST Import Definition'
        );

        Database.insert(importDefinition);

        Import_Instance__c importInstance = new Import_Instance__c(
          Import_Definition__c = importDefinition.Id
        );

        Database.insert(importInstance);

        // Error check - no files
        List<Boolean> results = Importer_Compare_File_Headers.equalFileHeaders(new List<ID> { importInstance.Id });

        // StopTest will make sure any future, schedulable, and batch calls complete before proceeding
        Test.StopTest();

        System.Assert(!results[0]);
    }

    @isTest(SeeAllData='false')
    public static void NegativeCheck_OneFile() {

        Test.StartTest();

        Import_Definition__c importDefinition = new Import_Definition__c(
          Name = 'TEST Import Definition'
        );

        Database.insert(importDefinition);

        Import_Instance__c importInstance = new Import_Instance__c(
          Import_Definition__c = importDefinition.Id
        );

        Database.insert(importInstance);

        // Create Definition File
        //
        ContentVersion contentVersionDefinition = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionDefinition;

        contentVersionDefinition = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionDefinition.Id LIMIT 1];

        insert new ContentDocumentLink (
          ContentDocumentId = contentVersionDefinition.ContentDocumentId,
          LinkedEntityId = importDefinition.Id
        );

        // Error check - only 1 file
        List<Boolean> results = Importer_Compare_File_Headers.equalFileHeaders(new List<ID> { importInstance.Id });

        // StopTest will make sure any future, schedulable, and batch calls complete before proceeding
        Test.StopTest();

        System.Assert(!results[0]);       
    }

    @isTest(SeeAllData='false')
    public static void NegativeCheck_MismatchHeaders() {

        Test.StartTest();

        Import_Definition__c importDefinition = new Import_Definition__c(
          Name = 'TEST Import Definition'
        );

        Database.insert(importDefinition);

        Import_Instance__c importInstance = new Import_Instance__c(
          Import_Definition__c = importDefinition.Id
        );

        Database.insert(importInstance);

        // Create Definition File
        //
        ContentVersion contentVersionDefinition = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionDefinition;

        contentVersionDefinition = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionDefinition.Id LIMIT 1];

        insert new ContentDocumentLink (
          ContentDocumentId = contentVersionDefinition.ContentDocumentId,
          LinkedEntityId = importDefinition.Id
        );

        // Create Instance File
        //
        ContentVersion contentVersionInstance = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('MismatchHeaders'),
            IsMajorVersion = true
        );
        insert contentVersionInstance;

        contentVersionInstance = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInstance.Id LIMIT 1];

        insert new ContentDocumentLink (
          ContentDocumentId = contentVersionInstance.ContentDocumentId,
          LinkedEntityId = importInstance.Id
        );

        // Success Check - both files
        List<Boolean> results = Importer_Compare_File_Headers.equalFileHeaders(new List<ID> { importInstance.Id });

        // StopTest will make sure any future, schedulable, and batch calls complete before proceeding
        Test.StopTest();

        System.Assert(!results[0]);
    }
}