@isTest
private class ParseJSONTest {

    // Utility method to create test data with 120 unique contacts and accounts
    private static String createTestData() {
        List<Account> accounts = new List<Account>();
        List<Contact> contacts = new List<Contact>();
        
        // Create 120 unique accounts and contacts
        for (Integer i = 0; i < 120; i++) {
            // Create a unique account
            Account acc = new Account(Name = 'Test Account ' + i);
            accounts.add(acc);
        }
        
        // Insert all accounts at once to avoid hitting governor limits
        insert accounts;

        // Create contacts linked to each account
        for (Integer i = 0; i < 120; i++) {
            // Create a unique contact linked to the inserted account
            Contact con = new Contact(
                LastName = 'Test Contact ' + i,
                AccountId = accounts[i].Id
            );
            contacts.add(con);
        }

        // Insert all contacts at once to avoid hitting governor limits
        insert contacts;

        // Initialize the JSON string with fixed fields
        String jsonString = '{\"createdById\": \"0052g000003G926AAC\",\"createdDate\": \"1693078705\",\"updatedContactsJson\":[';

        // Add each contact to the "updatedContactsJson" array
        for (Integer i = 0; i < 120; i++) {
            Contact testContact = contacts[i];
            String contactJson = '{' +
                '\"contactId\":\"' + testContact.Id + '\",' +
                '\"personIds\":[\"' + i + '\"],' +
                '\"firstVolunteerDate\":\"2023-08-29\",' +
                '\"fosterEndDate\":\"2023-08-29\",' +
                '\"fosterStartDate\":\"2023-08-29\",' +
                '\"lastVolunteerDate\":\"2023-08-29\",' +
                '\"totalVolunteerHours\":\"106.5\",' +
                '\"volunteerStatus\":\"Inactive\",' +
                '\"volgisticIds\":[\"' + i + '\"]' +
                '}';

            // Append each contact JSON entry to the main JSON string
            jsonString += contactJson;

            // Add a comma between entries, except for the last one
            if (i < 119) {
                jsonString += ',';
            }
        }

        // Close the JSON string
        jsonString += ']}';

        // Return the completed JSON string with 120 entries
        return jsonString;
    }

    // Test method to verify parsing with a valid JSON string that includes 120 unique contacts
    @isTest static void testParseWithMultipleUniqueContacts() {
        // Create test data and get the JSON string with 120 contact entries
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
        System.assertEquals(120, responses[0].contactsInfo.size(), 'There should be 120 contact info entries parsed.');
    }
}