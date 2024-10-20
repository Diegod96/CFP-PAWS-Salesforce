/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 10-18-2024
 * @last modified by  : Diego Delgado
**/
global class RFMEAnalysisBatch implements Database.Batchable<SObject>, Database.Stateful {

    private List<Contact> updatedContacts = new List<Contact>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Amount, npsp__Primary_Contact__c, CloseDate ' +
                       'FROM Opportunity ' +
                       'WHERE Amount != null AND npsp__Primary_Contact__c != null ' +
                       'AND CloseDate >= LAST_N_DAYS:365 AND StageName = \'Closed Won\'';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        Map<Id, List<Opportunity>> contactToOpportunitiesMap = new Map<Id, List<Opportunity>>();

        // Map contacts to their opportunities
        for (Opportunity opp : scope) {
            if (!contactToOpportunitiesMap.containsKey(opp.npsp__Primary_Contact__c)) {
                contactToOpportunitiesMap.put(opp.npsp__Primary_Contact__c, new List<Opportunity>());
            }
            contactToOpportunitiesMap.get(opp.npsp__Primary_Contact__c).add(opp);
        }

        Set<Id> contactIds = contactToOpportunitiesMap.keySet();
        List<Contact> contacts = [SELECT Id, Name, Last_volunteer_date__c, Date_Of_Current_Foster__c, Date_Of_Last_Foster_Returned__c FROM Contact WHERE Id IN :contactIds];

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact contact : contacts) {
            List<Opportunity> opportunities = contactToOpportunitiesMap.get(contact.Id);

            // Calculate RFME values using RFMEUtilityClass
            Integer recency = RFMEUtilityClass.calculateRecency(opportunities);
            Integer frequency = RFMEUtilityClass.calculateFrequency(opportunities);
            Decimal monetary = RFMEUtilityClass.calculateMonetary(opportunities);
            Integer engagement = RFMEUtilityClass.calculateEngagement(contact);

            // Update Contact record with RFME values
            contact.Recency__c = recency;
            contact.Number_Of_Opportunities__c = frequency;
            contact.Monetary__c = monetary;
            contact.Volunteer_or_Foster_Days_Between__c = engagement;

            // Add contact to list of contacts to update
            System.debug('Contact record added to update list: ' + contact);
            contactsToUpdate.add(contact);
            updatedContacts.add(contact);

        }

        // Check heap size and update contacts if necessary
        if (Limits.getHeapSize() > (Limits.getLimitHeapSize() - 20000)) { // 20KB buffer
            Database.update(contactsToUpdate, false);
            contactsToUpdate.clear(); // Clear the list to free up heap space
        }

        // Final update for any remaining contacts
        if (!contactsToUpdate.isEmpty()) {
            Database.update(contactsToUpdate, false);
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Get the current date
        String currentDate = Date.today().format();

        // Construct email content
        String emailContent = '<h1>Updated Contacts</h1>';
        emailContent += '<p>Date: ' + currentDate + '</p>';
        emailContent += '<table border="1"><tr><th>Contact Name</th><th>Recency Score</th><th>Frequency Score</th><th>Monetary Score</th><th>Engagement Score</th></tr>';


        for (Contact contact : updatedContacts) {
            emailContent += '<tr>';
            emailContent += '<td>' + contact.Name + '</td>';
            emailContent += '<td>' + contact.Recency__c + '</td>';
            emailContent += '<td>' + contact.Number_Of_Opportunities__c + '</td>';
            emailContent += '<td>' + contact.Monetary__c + '</td>';
            emailContent += '<td>' + contact.Volunteer_or_Foster_Days_Between__c + '</td>';
            emailContent += '</tr>';
        }

        emailContent += '</table>';

        // Send email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { 'ddphillyfan@gmail.com' });
        email.setSubject('RFME Analysis Batch Job Completed');
        email.setHtmlBody(emailContent);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}