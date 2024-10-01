public class ParseJSONBatch implements Database.Batchable<SObject>, Database.Stateful {

    // JSON string to process in the batch
    public String jsonString;

    // List to store failed records with error messages
    public List<String> failedRecords = new List<String>();

    // Constructor to accept the JSON string
    public ParseJSONBatch(String jsonString) {
        this.jsonString = jsonString;
    }

    // Start method to select Contact records to update
    public Database.QueryLocator start(Database.BatchableContext bc) {

        // Parse the incoming JSON and extract contact IDs
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        List<Object> updatedContactsJson = (List<Object>) jsonMap.get('updatedContactsJson');
        System.debug('updatedContactsJson -> ' + updatedContactsJson);

        List<String> contactIds = new List<String>();

        if (updatedContactsJson != null) {
            for (Object contactObj : updatedContactsJson) {
                Map<String, Object> contactMap = (Map<String, Object>) contactObj;
                String contactId = (String) contactMap.get('contactId');
                contactIds.add(contactId);
            }
        }

        // Query for the Contact records based on the parsed IDs
        return Database.getQueryLocator([
                SELECT Id, Last_Sync_With_Pipeline__c, First_volunteer_date__c, Last_volunteer_date__c, Duplicate_Person_Ids__c, Duplicate_Volgistic_Ids__c, Foster_Start_Date__c, Foster_End_Date__c, Total_volunteer_hours__c, Volunteer_Status__c
                FROM Contact
                WHERE Id IN :contactIds
        ]);
    }

    // Execute method to process and update the Contact records
    public void execute(Database.BatchableContext bc, List<Contact> scope) {

        List<Contact> contactsToUpdate = new List<Contact>();

        // Parse JSON again to map Contact IDs with their respective data
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        List<Object> updatedContactsJson = (List<Object>) jsonMap.get('updatedContactsJson');
        Map<String, Map<String, Object>> contactDataMap = new Map<String, Map<String, Object>>();

        for (Object contactObj : updatedContactsJson) {
            Map<String, Object> contactMap = (Map<String, Object>) contactObj;
            String contactId = (String) contactMap.get('contactId');
            contactDataMap.put(contactId, contactMap);
        }

        // Update each Contact based on the data in the JSON
        for (Contact contact : scope) {
            if (contactDataMap.containsKey(contact.Id)) {
                Map<String, Object> contactInfo = contactDataMap.get(contact.Id);

                // Retrieve values from the map and convert them to strings
                String stringPersonIds = String.valueOf(contactInfo.get('personIds'));
                String stringVolgisticIds = String.valueOf(contactInfo.get('volgisticIds'));

                // Check if the string is '[]', if so, set it to '[]'
                stringPersonIds = stringPersonIds == '[]' ? '[]' : stringPersonIds;
                stringVolgisticIds = stringVolgisticIds == '[]' ? '[]' : stringVolgisticIds;

                // Modify the strings by removing brackets if they are not '[]'
                String stringPersonIdsModified = stringPersonIds != null && stringPersonIds != '[]'
                    ? stringPersonIds.replace('[', '').replace(']', '')
                    : (stringPersonIds != null ? stringPersonIds : '');
                
                String stringVolgisticIdsModified = stringVolgisticIds != null && stringVolgisticIds != '[]'
                    ? stringVolgisticIds.replace('[', '').replace(']', '')
                    : (stringVolgisticIds != null ? stringVolgisticIds : '');

                contact.Last_Sync_With_Pipeline__c = Datetime.now();
                contact.First_volunteer_date__c = contactInfo.get('firstVolunteerDate') != null ? Date.valueOf((String) contactInfo.get('firstVolunteerDate')) : contact.First_volunteer_date__c;
                contact.Foster_End_Date__c = contactInfo.get('fosterEndDate') != null ? Date.valueOf((String) contactInfo.get('fosterEndDate')) : contact.Foster_End_Date__c;
                contact.Foster_Start_Date__c = contactInfo.get('fosterStartDate') != null ? Date.valueOf((String) contactInfo.get('fosterStartDate')) : contact.Foster_Start_Date__c;
                contact.Last_volunteer_date__c = contactInfo.get('lastVolunteerDate') != null ? Date.valueOf((String) contactInfo.get('lastVolunteerDate')) : contact.Last_volunteer_date__c;
                contact.Total_volunteer_hours__c = contactInfo.get('totalVolunteerHours') != null ? Decimal.valueOf(contactInfo.get('totalVolunteerHours').toString()) : contact.Total_volunteer_hours__c;
                contact.Volunteer_Status__c = contactInfo.get('volunteerStatus') != null ? (String) contactInfo.get('volunteerStatus') : contact.Volunteer_Status__c;
                contact.Duplicated_Volgistics_Ids__c = stringVolgisticIdsModified;
                contact.Duplicated_Person_Ids__c = stringPersonIdsModified;

                contactsToUpdate.add(contact);
            }
        }

        System.debug('Number of Contacts Being Updated -> ' + contactsToUpdate.size());

        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(contactsToUpdate, false);
            
            System.debug('Results ->'+ results);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMsg = results[i].getErrors()[0].getMessage();
                    failedRecords.add('Contact ID ' + contactsToUpdate[i].Id + ' failed due to error: ' + errorMsg);
                }
            }
        }
    }

    // Finish method to log when the batch completes
    public void finish(Database.BatchableContext bc) {
        if (!failedRecords.isEmpty()) {
            // Construct the email body with failed record details
            String body = 'The following contacts failed to update:\n\n';
            for (String failure : failedRecords) {
                body += failure + '\n';
            }
    
            // Construct the email
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            // Set the recipient email address
            email.setToAddresses(new String[] { 'ddphillyfan@gmail.com' });
            
            // Set subject and body for the email
            email.setSubject('Batch Update Failures: Contact Records');
            email.setPlainTextBody(body);
    
            // Optionally set a Reply-To address and Sender Name
            email.setReplyTo('ddphillyfan@gmail.com');
            email.setSenderDisplayName('Salesforce Batch Processor');
    
            // Send the email
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    
            System.debug('Failure email sent with body: ' + body);
        } else {
            System.debug('No failures detected in batch process.');
        }
    }
}