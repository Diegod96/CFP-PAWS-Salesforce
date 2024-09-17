/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-18-2024
 * @last modified by  : Diego Delgado
**/
@isTest
public with sharing class ContactWrapperTest {
    static testMethod void testParse() {

		

		Account account = new Account();
		Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household Account').getRecordTypeId();
		account.RecordTypeId = accountRecordTypeId;
		account.Name = 'Test Household';
		insert account;

		Contact contact = new Contact();
		contact.AccountId = account.Id;
		contact.FirstName = 'Jane';
		contact.LastName = 'Doe';
		Id contactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Person').getRecordTypeId();
		contact.RecordTypeId = contactRecordTypeId;
		insert contact;

		system.debug('-- Contact : ' + contact.Account.Name);
		system.debug('-- Contact : ' + contact.ID);

		Test.startTest();

		String jsonString = '{\"createdById\": \"0052g000003G926AAC\",\"createdDate\": \"1693078705\",\"updatedContactsJson\":[{\"contactId\":\"0032g00000Ukx9bAAB\",\"personId\":[\"55298146\",\"55298147\"],\"firstVolunteerDate\":\"2023-08-29\", \"fosterEndDate\":\"2023-08-29\", \"fosterStartDate\":\"2023-08-29\", \"lastVolunteerDate\":\"2023-08-29\", \"totalVolunteerHours\":\"106.5\", \"volunteerStatus\":\"Active\", \"volgisticIds\":[\"9277188\",\"5555555\"]}]}';

		// Deserialize JSON string into Map<String, Object>
		Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

		// Get the 'updatedContactsJson' object from the map
		List<Object> updatedContacts = (List<Object>) jsonMap.get('updatedContactsJson');
		String createdById = (String) jsonMap.get('CreatedById');
		String createdDate = (String) jsonMap.get('CreatedDate');

		// Iterate over the list and update each entry
		for(Object con : updatedContacts) {
			Map<String, Object> contactMap = (Map<String, Object>) con;
			// Replace the 'Id' value with the defined Contact ID
			contactMap.put('Id', contact.Id);
			System.debug('Contact Map -> ' + contactMap);
		}


		// Reserialize the outermost Map<String, Object>
		String updatedJsonString = JSON.serialize(jsonMap);
		System.debug('Old jsonString -> ' + jsonString);
		System.debug('Updated jsonString -> ' + updatedJsonString);

		ContactWrapper cw = ContactWrapper.parse(updatedJsonString);
		System.assert(cw != null);

		Test.stopTest();


		//String json = '{\"CreatedById\": \"0032g00000Ukx9bAAB\",\"CreatedDate\": \"1693078705\",\"updatedContactsJson\":[{\"Id\":\"0032g00000Ukx9bAAB\",\"Person_ID__c\":\"[55298146,55298147]\",\"First_volunteer_date__c\":\"2023-08-29\", \"Foster_End_Date__c\":\"2023-08-29\", \"Foster_Start_Date__c\":\"2023-08-29\", \"Last_volunteer_date__c\":\"2023-08-29\", \"Total_Volunteer_Hours__c\":\"106.5\", \"Volunteer_Status__c\":\"Active\", \"Volgistics_Id__c\":\"[9277188,5555555]\"}]}';

	}
}