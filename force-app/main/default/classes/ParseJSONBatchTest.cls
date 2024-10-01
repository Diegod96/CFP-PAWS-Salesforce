@IsTest
public class ParseJSONBatchTest {
    
    @TestSetup
    static void setupTestData() {
        // Creating 300 test Contact records
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 300; i++) {
            Contact contact = new Contact(
                LastName = 'TestContact' + i,
                Volunteer_Status__c = 'Active',
                First_volunteer_date__c = Date.newInstance(2020, 1, 1),
                Last_volunteer_date__c = Date.newInstance(2020, 1, 1),
                Foster_Start_Date__c = Date.newInstance(2020, 6, 1),
                Foster_End_Date__c = Date.newInstance(2021, 6, 1),
                Duplicated_Person_Ids__c = '',
                Duplicated_Volgistics_Ids__c = '',
                Total_volunteer_hours__c = 50
            );
            contacts.add(contact);
        }
        insert contacts;
    }
    
    @IsTest
    static void testMultipleBatchRequests() {
        // Fetch the inserted test data
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 300];
        
        // Split the contacts into two groups manually
        List<Contact> contactsBatch1 = new List<Contact>();
        List<Contact> contactsBatch2 = new List<Contact>();
        
        for (Integer i = 0; i < 150; i++) {
            contactsBatch1.add(contacts[i]);
        }
        
        for (Integer i = 150; i < 300; i++) {
            contactsBatch2.add(contacts[i]);
        }
        
        // Create two mock JSON strings for the two batch requests
        String mockJsonStringBatch1 = createMockJsonString(contactsBatch1, 'Inactive', 100.05);
        String mockJsonStringBatch2 = createMockJsonString(contactsBatch2, 'Active', 200.50);
        
        // Create two BatchRequest objects with different data
        TriggerBatchFlow.BatchRequest batchRequest1 = new TriggerBatchFlow.BatchRequest();
        batchRequest1.jsonString = mockJsonStringBatch1;
        
        TriggerBatchFlow.BatchRequest batchRequest2 = new TriggerBatchFlow.BatchRequest();
        batchRequest2.jsonString = mockJsonStringBatch2;
        
        // Add both batch requests to the list
        List<TriggerBatchFlow.BatchRequest> batchRequests = new List<TriggerBatchFlow.BatchRequest>{ batchRequest1, batchRequest2 };
            
            // Start the test and execute the batch
            Test.startTest();
        TriggerBatchFlow.invokeBatch(batchRequests);
        Test.stopTest();
        
        // Query and assert the updated contacts from both batches
        verifyContactsUpdated(contactsBatch1, 'Inactive', 100.05);
        verifyContactsUpdated(contactsBatch2, 'Active', 200.50);
    }
    
    @IsTest
    static void testEmptyBatchRequest() {
        // Test with an empty batch request
        List<TriggerBatchFlow.BatchRequest> batchRequests = new List<TriggerBatchFlow.BatchRequest>();
        
        Test.startTest();
        TriggerBatchFlow.invokeBatch(batchRequests); // This should handle empty gracefully
        Test.stopTest();
    }
    
    @IsTest
    static void testBatchQueueableProcessing() {
        // Create some test data
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) { // Reduce the number to avoid max depth
            contacts.add(new Contact(
                LastName = 'TestContact' + i,
                Volunteer_Status__c = 'Active',
                Total_volunteer_hours__c = 50
            ));
        }
        insert contacts;
        
        // Create mock JSON strings for batch requests
        List<TriggerBatchFlow.BatchRequest> batchRequests = new List<TriggerBatchFlow.BatchRequest>();
        for (Contact contact : contacts) {
            TriggerBatchFlow.BatchRequest batchRequest = new TriggerBatchFlow.BatchRequest();
            batchRequest.jsonString = '{"updatedContactsJson":[{"contactId":"' + contact.Id + '","volunteerStatus":"Inactive","totalVolunteerHours":"100.05"}]}';
            batchRequests.add(batchRequest);
        }
        
        // Start the queueable job with the batch requests
        Test.startTest();
        System.enqueueJob(new TriggerBatchFlow.BatchQueueable(batchRequests));
        Test.stopTest();
        
        // Query to assert that the contacts were updated
        List<Contact> updatedContacts = [SELECT Volunteer_Status__c, Total_volunteer_hours__c FROM Contact WHERE Id IN :contacts];
        for (Contact contact : updatedContacts) {
            System.assertEquals('Inactive', contact.Volunteer_Status__c, 'Contact status should be updated to Inactive');
            System.assertEquals(100.05, contact.Total_volunteer_hours__c, 'Total volunteer hours should be updated to 100.05');
        }
    }
    
    // Helper method to create the mock JSON string for the batch requests
    static String createMockJsonString(List<Contact> contacts, String volunteerStatus, Decimal totalVolunteerHours) {
        String mockJsonString = '{"updatedContactsJson":[';
        for (Contact contact : contacts) {
            mockJsonString +=
                '{"contactId": "' + contact.Id + '", ' +
                '"volunteerStatus": "' + volunteerStatus + '", ' +
                '"firstVolunteerDate": "2022-01-01", ' +
                '"lastVolunteerDate": "2022-01-01", ' +
                '"fosterStartDate": "2022-06-01", ' +
                '"fosterEndDate": "2023-06-01", ' +
                '"personIds": "[123,12345]", ' +
                '"volgisticIds": "[123,12345]", ' +
                '"totalVolunteerHours": "' + totalVolunteerHours + '"},';
        }
        mockJsonString = mockJsonString.removeEnd(',') + ']}';
        return mockJsonString;
    }
    
    // Helper method to verify that contacts were updated with the correct values
    static void verifyContactsUpdated(List<Contact> contacts, String expectedStatus, Decimal expectedHours) {
        List<Contact> updatedContacts = [SELECT Volunteer_Status__c, Total_volunteer_hours__c FROM Contact WHERE Id IN :contacts];
        for (Contact contact : updatedContacts) {
            System.assertEquals(expectedStatus, contact.Volunteer_Status__c, 'Contact status should be updated to ' + expectedStatus);
            System.assertEquals(expectedHours, contact.Total_volunteer_hours__c, 'Total volunteer hours should be updated to ' + expectedHours);
        }
    }
}