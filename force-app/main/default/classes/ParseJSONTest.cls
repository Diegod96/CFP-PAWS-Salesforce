/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-20-2024
 * @last modified by  : Diego Delgado
**/
@isTest
private class ParseJSONTest {

    // Utility method to create test data
    private static String createTestData() {
        // Create and insert a new Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create and insert a new Contact linked to the Account
        Contact testContact = new Contact(
            LastName = 'Test Contact',
            AccountId = testAccount.Id
        );
        insert testContact;

        // Return a JSON string with the newly created Contact ID
        return '{\"createdById\": \"0052g000003G926AAC\",\"createdDate\": \"1693078705\",\"updatedContactsJson\":[{\"contactId\":\"' + testContact.Id + '\",\"personIds\":[\"\"],\"firstVolunteerDate\":\"2023-08-29\", \"fosterEndDate\":\"2023-08-29\", \"fosterStartDate\":\"2023-08-29\", \"lastVolunteerDate\":\"2023-08-29\", \"totalVolunteerHours\":\"106.5\", \"volunteerStatus\":\"Inactive\", \"volgisticIds\":[\"9277188\",\"5555555\"]}]}';
    }

    // Test method to verify parsing with a valid JSON string that includes a dynamically created Contact ID
    @isTest static void testParseWithDynamicContactId() {
        // Create test data and get the JSON string with the new Contact ID
        String jsonString = createTestData();
        
        // Wrap the JSON string in a list of RequestWrapper as expected by the invocable method
        List<ParseJSON.RequestWrapper> requests = new List<ParseJSON.RequestWrapper>();
        ParseJSON.RequestWrapper request = new ParseJSON.RequestWrapper();
        request.jsonString = jsonString;
        requests.add(request);

        // Invoke the method
        Test.startTest();
        List<ParseJSON.ResponseWrapper> responses = ParseJSON.parseJson(requests);
        Test.stopTest();

        // Assertions to ensure that the method behaves as expected
        System.assertNotEquals(null, responses, 'The response should not be null.');
        System.assertEquals(1, responses.size(), 'There should be one response.');
        System.assertEquals(1, responses[0].contactsInfo.size(), 'There should be one contact info parsed.');
    }
}