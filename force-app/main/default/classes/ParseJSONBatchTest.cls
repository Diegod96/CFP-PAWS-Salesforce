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
    static void testBatchProcessing() {
        // Fetch the inserted test data
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 300];

        // Create a mock JSON string for 200 contacts
        String mockJsonString = '{"updatedContactsJson":[';
        for (Contact contact : contacts) {
            mockJsonString +=
                    '{"contactId": "' + contact.Id + '", ' +
                            '"volunteerStatus": "Inactive", ' +
                            '"firstVolunteerDate": "2022-01-01", ' +
                            '"lastVolunteerDate": "2022-01-01", ' +
                            '"fosterStartDate": "2022-06-01", ' +
                            '"fosterEndDate": "2023-06-01", ' +
                            '"personIds": "[123,12345]", ' +
                            '"volgisticIds": "[123,12345]", ' +
                            '"totalVolunteerHours": "100.05"},';
        }
        mockJsonString = mockJsonString.removeEnd(',') + ']}';

        // Create a request to invoke the batch via TriggerBatchFlow
        TriggerBatchFlow.BatchRequest batchRequest = new TriggerBatchFlow.BatchRequest();
        batchRequest.jsonString = mockJsonString;

        List<TriggerBatchFlow.BatchRequest> batchRequests = new List<TriggerBatchFlow.BatchRequest>{ batchRequest };

        // Start the test and execute the batch
        Test.startTest();
        TriggerBatchFlow.invokeBatch(batchRequests);
        Test.stopTest();

        // Assertions to verify that the contacts were updated
        List<Contact> updatedContacts = [SELECT Volunteer_Status__c, Total_volunteer_hours__c FROM Contact WHERE Id IN :contacts];
        for (Contact contact : updatedContacts) {
            System.assertEquals('Inactive', contact.Volunteer_Status__c);
            System.assertEquals(100.05, contact.Total_volunteer_hours__c);
        }
    }
}
