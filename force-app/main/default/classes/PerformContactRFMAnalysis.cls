public with sharing class PerformContactRFMAnalysis {

    /**
     * Invocable Apex Method that handles the collection of opportunities we get from the flow
     */
    @InvocableMethod(label='Perform Contact RFM Analysis')
    public static void PerformContactRFMAnalysis(List<List<sObject>> opportunities) {

        // Initialize Map of Contact Id -> related Opportunities
        Map<Id, List<Opportunity>> processedContactToOpportunities = processOpportunities(opportunities[0]);

        // Initialize Map of Contact Id -> RFM Scores
        Map<Id, Map<String, Integer>> contactToRFMScores = new Map<Id, Map<String, Integer>>();
        
        // Collecting all contact IDs
        Set<Id> contactIds = processedContactToOpportunities.keySet();

        // Query all contacts in one go
        Map<Id, Contact> contactsMap = new Map<Id, Contact>([
            SELECT Id, Name, Last_volunteer_date__c, Date_Of_Current_Foster__c, Date_Of_Last_Foster_Returned__c
            FROM Contact
            WHERE Id IN :contactIds
            WITH SECURITY_ENFORCED
        ]);


        for (Id key : processedContactToOpportunities.keySet()) {
            
            // Get current contact and their related opportunities
            Contact currentContact = contactsMap.get(key);
            System.debug('Contact record to perform RFM analysis: ' + currentContact);

            List<Opportunity> opps = processedContactToOpportunities.get(key);
            System.debug('Opportunitues tied to ' + currentContact + ': ' + opps);


            // Get daysBetween value
            Integer daysBetween = recency(opps);
            
            // Get numOpportunities value
            Integer numOpportunities = opps.size();

            // Get totalAmount value
            Integer totalAmount = monetary(opps);

            // Get volunteerOrFosterDaysBetween value
            Integer volunteerOrFosterDaysBetween = engagement(currentContact);

            contactToRFMScores.put(key, new Map<String, Integer>
            {
                'Days Between' => daysBetween, 
                'Number Of Opportunities' => numOpportunities,
                'Total Amount' => totalAmount,
                'Volunteer or Foster Days Between' => VolunteerOrFosterDaysBetween
            });
        }  

        updateScoresOnContact(contactToRFMScores);

    }

    /**
     * Method to map contacts to their related opportunities
     */
    public static Map<Id, List<Opportunity>> processOpportunities(List<Opportunity> opportunities) {

        // Initialize the map of contact -> list of related opportunities
        Map<Id, List<Opportunity>> contactToOpportunities = new Map<Id, List<Opportunity>>();

        // Initialize iterator on list of opportunities
        Iterator <Opportunity> it = opportunities.iterator();

        // Iterate over list of opportunities
        // If we do not find the contact key in the map then create the contact key
        // Else find the contact key and add the opportunity to the list of related opportunities
        while (it.hasNext()) {
            Opportunity opp = it.next();
            if(contactToOpportunities.containsKey(opp.npsp__Primary_Contact__c) == false) {
                List<Opportunity> contactsOpps = new List<Opportunity>();
                contactsOpps.add(opp);
                contactToOpportunities.put(opp.npsp__Primary_Contact__c, contactsOpps);
            } else if (contactToOpportunities.containsKey(opp.npsp__Primary_Contact__c) == true) {
                contactToOpportunities.get(opp.npsp__Primary_Contact__c).add(opp);
            }
        }
        return contactToOpportunities;
    }

    /**
     * Method to calculate the recency between today and close date of most recent close won opportunity
     */
    public static Integer recency(List<Opportunity> relatedOpportunities) {

        // Get todays date
        Date today = Date.today();

        // Get date of most recent close won opportunity
        Date mostRecentCloseDate = relatedOpportunities[0].CloseDate;

        // Get time delta in days between the two dates
        Integer daysBetween = mostRecentCloseDate.daysBetween(today);

        return daysBetween;
    }

    /**
     * Method to sum the amount of closed won opportunities
     */
    public static Integer monetary(List<Opportunity> relatedOpportunities) {
        Decimal totalAmountDonated = 0.0;

        Iterator <Opportunity> it = relatedOpportunities.iterator();

        while (it.hasNext()) {
            Opportunity opp = it.next();
            totalAmountDonated = totalAmountDonated + opp.Amount;
        }

        return totalAmountDonated.intValue();
    }

    /**
     * Method calculate days between last Volunteer and Fostered date and current date
     */
     public static Integer engagement(Contact currentContact) {

        Date today = Date.today();
        Date mostRecentVolunteerDate = currentContact.Last_volunteer_date__c;
        Date mostRecentDateCurrentFoster = currentContact.Date_Of_Current_Foster__c;
        Date mostRecentFosterReturnedDate = currentContact.Date_Of_Last_Foster_Returned__c;
    
        Integer daysBetween;
    
        if (mostRecentVolunteerDate == null && mostRecentDateCurrentFoster == null && mostRecentFosterReturnedDate == null) {
            daysBetween = -1;
        } else if (mostRecentVolunteerDate == null && mostRecentDateCurrentFoster == null && mostRecentFosterReturnedDate != null) {
            daysBetween = mostRecentFosterReturnedDate.daysBetween(today);
        } else if (mostRecentVolunteerDate == null && mostRecentDateCurrentFoster != null && mostRecentFosterReturnedDate == null) {
            daysBetween = mostRecentDateCurrentFoster.daysBetween(today);
        } else if (mostRecentVolunteerDate != null && mostRecentDateCurrentFoster == null && mostRecentFosterReturnedDate == null) {
            daysBetween = mostRecentVolunteerDate.daysBetween(today);
        } else {
            if (mostRecentVolunteerDate != null && (mostRecentVolunteerDate >= mostRecentDateCurrentFoster || mostRecentVolunteerDate >= mostRecentFosterReturnedDate)) {
                daysBetween = mostRecentVolunteerDate.daysBetween(today);
            } else if (mostRecentDateCurrentFoster != null && (mostRecentDateCurrentFoster >= mostRecentFosterReturnedDate)) {
                daysBetween = mostRecentDateCurrentFoster.daysBetween(today);
            } else {
                daysBetween = mostRecentFosterReturnedDate.daysBetween(today);
            }
        }
    
        return daysBetween;
    }

    /**
     * Method to update the RFM fields on the Contact
     */
    public static void updateScoresOnContact(Map<Id, Map<String, Integer>> contactToRFMScores) {

        // Initialize list of Contacts that will be updatedSale
        List<Contact> contactsToUpdate = new List<Contact>();

        // Query for Contacts
        List<Contact> contactsFound = [
            SELECT Id, Name, Recency__c, Number_Of_Opportunities__c, Monetary__c, Volunteer_or_Foster_Days_Between__c
            FROM Contact
            WHERE Id IN :contactToRFMScores.keySet()
            WITH SECURITY_ENFORCED
        ];

        // Initialize iterator for contactsFound list
        Iterator <Contact> it = contactsFound.iterator();
        
        // Iterate through contactsFound
        while (it.hasNext()) {

            // Create Contact to hold it.next()
            Contact con = it.next();

            // Match Id to keys in contactToRFMScores
            if (contactToRFMScores.containsKey(con.id)) {

                // Get Map of scores
                Map<String, Integer> rfmScores = contactToRFMScores.get(con.id);

                // Update related fields
                con.Recency__c = rfmScores.get('Days Between');
                con.Number_Of_Opportunities__c = rfmScores.get('Number Of Opportunities');
                con.Monetary__c = rfmScores.get('Total Amount');
                con.Volunteer_or_Foster_Days_Between__c = rfmScores.get('Volunteer or Foster Days Between');
                con.RFME_Analysis_Date__c = Date.today();

                // Add updated Contact to update list
                contactsToUpdate.add(con);
            }
        }

        System.debug('Contact to update: ' + contactsToUpdate);

        // Try to update list of Contacts
        try {
            update contactsToUpdate;
        } catch (DMLException e) {
            System.debug('Error Updating Contacts: ' + e.getMessage());
        }
    }
}