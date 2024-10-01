// Create a list to hold multiple BatchRequest objects
List<TriggerBatchFlow.BatchRequest> batchRequests = new List<TriggerBatchFlow.BatchRequest>();

// Create mock JSON strings for multiple batch requests
for (Integer i = 0; i < 5; i++) { // Creating 5 batch requests as an example
    TriggerBatchFlow.BatchRequest batchRequest = new TriggerBatchFlow.BatchRequest();
    
    // Construct a mock JSON string for each batch request
    String mockJsonString = '{"updatedContactsJson":[' +
        '{"contactId": "0032g00000UtKcBAAV", ' + // Replace with actual Contact Ids in your org
        '"volunteerStatus": "Inactive", ' +
        '"firstVolunteerDate": "2022-01-01", ' +
        '"lastVolunteerDate": "2022-01-01", ' +
        '"fosterStartDate": "2022-06-01", ' +
        '"fosterEndDate": "2023-06-01", ' +
        '"personIds": "[123,12345]", ' +
        '"volgisticIds": "[123,12345]", ' +
        '"totalVolunteerHours": "100.05"}]}';
    
    batchRequest.jsonString = mockJsonString;
    batchRequests.add(batchRequest);
}

// Invoke the method with multiple batch requests
TriggerBatchFlow.invokeBatch(batchRequests);

// Check the results by querying the updated contacts
List<String> contactIds = new List<String>();
for (Integer i = 0; i < 5; i++) {
    contactIds.add('0032g00000UtKcBAAV'); // Replace with actual Contact Ids
}
List<Contact> updatedContacts = [SELECT Id, Volunteer_Status__c, Total_volunteer_hours__c FROM Contact WHERE Id IN :contactIds];

for (Contact contact : updatedContacts) {
    System.debug('Contact Id: ' + contact.Id + ', Status: ' + contact.Volunteer_Status__c + ', Total Hours: ' + contact.Total_volunteer_hours__c);
}
