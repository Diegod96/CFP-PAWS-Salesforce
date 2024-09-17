public with sharing class CalculateTotalNumberOfDonations {

    @InvocableMethod(Label='Calculate Total Number Of Donations')
    public static void CalculateTotalNumberOfDonations(List<List<Opportunity>> closedWonDonations) {

        System.debug('Closed Won Donations: ' + closedWonDonations[0]);

        // Initialize Map of Contact Id -> related Opportunities
        Map<Id, List<Opportunity>> processedContactToOpportunities = assignContactToDonations(closedWonDonations[0]);

        Map<Id, Integer> contactToNumberOfClosedWonDonations = createContactToNumberOfClosedWonDonationsMap(processedContactToOpportunities);

        updateContacts(contactToNumberOfClosedWonDonations);

    }


    public static Map<Id, List<Opportunity>> assignContactToDonations(List<Opportunity> opportunities) {

        // Initialize the map of contact -> list of related opportunities
        Map<Id, List<Opportunity>> contactToOpportunities = new Map<Id, List<Opportunity>>();

        // Initialize iterator on list of opportunities
        Iterator <Opportunity> it = opportunities.iterator();

        // Iterate over list of opportunities
        // If we do not find the contact key in the map then create the contact key
        // Else find the contact key and add the opportunity to the list of related opportunities
        while (it.hasNext()) {
            Opportunity opp = it.next();
            if (contactToOpportunities.containsKey(opp.npsp__Primary_Contact__c) == false) {
                List<Opportunity> contactsOpps = new List<Opportunity>();
                contactsOpps.add(opp);
                contactToOpportunities.put(opp.npsp__Primary_Contact__c, contactsOpps);
            } else if (contactToOpportunities.containsKey(opp.npsp__Primary_Contact__c) == true) {
                contactToOpportunities.get(opp.npsp__Primary_Contact__c).add(opp);
            }
        }
        return contactToOpportunities;
    }

    public static Map<Id, Integer> createContactToNumberOfClosedWonDonationsMap(Map<Id, List<Opportunity>> processedContactToOpportunities) {
        Map<Id, Integer> contactToNumberOfClosedWonDonations = new Map<Id, Integer>();

        for (Id contactId : processedContactToOpportunities.keySet()) {
            Integer numberOfClosedWonDonations = processedContactToOpportunities.get(contactId).size();
            System.debug('Number of Closed Won Donations For ' + contactId + ' -> ' + numberOfClosedWonDonations);
            contactToNumberOfClosedWonDonations.put(contactId, numberOfClosedWonDonations);
        }

        return contactToNumberOfClosedWonDonations;
    }

    public static void updateContacts(Map<Id, Integer> contactToNumberOfClosedWonDonations) {

        List<Contact> contactsToUpdate = new List<Contact>();

        List<Contact> contactsFound = [
                SELECT Id, Name, Total_Number_of_Closed_Won_Donations__c
                FROM Contact
                WHERE Id IN :contactToNumberOfClosedWonDonations.keySet()
                WITH SECURITY_ENFORCED
        ];

        // Initialize iterator for contactsFound list
        Iterator <Contact> it = contactsFound.iterator();

        // Iterate through contactsFound
        while (it.hasNext()) {
            // Create Contact to hold it.next()
            Contact con = it.next();
            if (contactToNumberOfClosedWonDonations.containsKey(con.Id)) {
                con.Total_Number_of_Closed_Won_Donations__c = contactToNumberOfClosedWonDonations.get(con.Id);
                contactsToUpdate.add(con);
            }
        }

        // Try to update list of Contacts
        try {
            update contactsToUpdate;
        } catch (DmlException e) {
            System.debug('Error Updating Contacts: ' + e.getMessage());
        }
    }

}