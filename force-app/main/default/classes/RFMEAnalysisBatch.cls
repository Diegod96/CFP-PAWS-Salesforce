/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 01-28-2025
 * @last modified by  : Diego Delgado
**/
global class RFMEAnalysisBatch implements Database.Batchable<SObject>, Database.Stateful {

    private List<Contact> updatedContacts = new List<Contact>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        
        
        String query = 'SELECT Id, Amount, StageName, npsp__Primary_Contact__c, CloseDate ' +
                       'FROM Opportunity ' +
                       'WHERE Amount != null AND npsp__Primary_Contact__c != null ' +
                       'AND CloseDate >= THIS_YEAR AND StageName = \'Closed Won\'';
        

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

        System.debug('contactToOpportunitiesMap => ' + contactToOpportunitiesMap);

        Set<Id> contactIds = contactToOpportunitiesMap.keySet();
        List<Contact> contacts = [SELECT Id, Name, Recency__c, Frequency__c, Monetary__c, Volunteer_Foster_Engagement__c, Impact__c, Total_Closed_Won_Donations_This_Year__c, Last_volunteer_date__c, Date_Of_Current_Foster__c, Date_Of_Last_Foster_Returned__c FROM Contact WHERE Id IN :contactIds];

        List<Contact> contactsToUpdate = new List<Contact>();

        for (Contact contact : contacts) {
            List<Opportunity> opportunities = contactToOpportunitiesMap.get(contact.Id);

            // Calculate RFME values using RFMEUtilityClass
            Integer recency = RFMEUtilityClass.calculateRecency(opportunities);
            Integer frequency = RFMEUtilityClass.calculateFrequency(opportunities);
            Integer monetary = RFMEUtilityClass.calculateMonetary(opportunities);
            String engagement = RFMEUtilityClass.calculateEngagement(contact, recency);
            Integer volunteerOrFosterStatus = RFMEUtilityClass.calculateVolunteerOrFosterStatus(contact);
            String impact = RFMEUtilityClass.calculateImpact(contact, frequency, monetary);
            Integer closedWonDonationsThisYear = RFMEUtilityClass.calculateClosedWonDonationsThisYear(opportunities);

            // Update Contact record with RFME values
            contact.Recency__c = recency;
            contact.Frequency__c = frequency;
            contact.Monetary__c = monetary;
            contact.Engagement__c = engagement;
            contact.Volunteer_Foster_Engagement__c = volunteerOrFosterStatus;
            contact.Impact__c = impact;
            contact.Total_Closed_Won_Donations_This_Year__c = closedWonDonationsThisYear;

            // Set the RFME analysis date to today's date
            contact.RFME_Analysis_Date__c = Date.today();

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
        // Send completion email with updated contacts summary
        RFMEUtilityClass.sendBatchCompletionEmail(updatedContacts);
        
        // Clear the list after sending
        updatedContacts.clear();
    }
}