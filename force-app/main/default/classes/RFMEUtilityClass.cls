/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 12-06-2024
 * @last modified by  : Diego Delgado
**/
public class RFMEUtilityClass {
    

    /**
     * @description calculateRecency description
     * @param  opportunities opportunities description
     * @return               return description
     */
    public static Integer calculateRecency(List<Opportunity> opportunities) {
        System.debug('Calculating Recency for Opportunities => ' + JSON.serialize(opportunities));

        // Initialize recency to 0
        Integer recency = 0;

        // If there are no opportunities, return 0
        if (opportunities == null || opportunities.isEmpty()) {
            return recency;
        }

        // Convert to Date object
        Date mostRecentCloseDate = opportunities[0].CloseDate; 

        // Find the most recent close date
        for (Opportunity opp : opportunities) {
            if (opp.CloseDate > mostRecentCloseDate) {
                mostRecentCloseDate = opp.CloseDate;
            }
        }
        System.debug('Most Recent Close Date => ' + mostRecentCloseDate);

        // Calculate days between today and most recent donation
        Integer daysSinceLastDonation = mostRecentCloseDate.daysBetween(Date.today());
        System.debug('Days Since Last Donation => ' + daysSinceLastDonation);

        // Determine recency value based on days since last donation
        Integer daysRange = daysSinceLastDonation <= 180 ? 1 : daysSinceLastDonation <= 365 ? 2 : daysSinceLastDonation <= 728 ? 3 : daysSinceLastDonation <= 1093 ? 4 : 5;
        System.debug('Days Range => ' + daysRange);

        // Assign recency value based on days range
        switch on daysRange {
            when 1 {
                recency = 5;
            }
            when 2 {
                recency = 4;
            }
            when 3 {
                recency = 3;
            }
            when 4 {
                recency = 2;
            }
            when else {
                recency = 1;
            }
        }

        System.debug('Recency => ' + recency);
        return recency;
    }

    /**
    * @description calculateFrequency description
    * @param  opportunities opportunities description
    * @return               return description
    */
    public static Integer calculateFrequency(List<Opportunity> opportunities) {
        System.debug('Calculating Frequency for Opportunities => ' + JSON.serialize(opportunities));

        // Initialize frequency to 0
        Integer frequency = 0;
        
        // If there are no opportunities, return 0
        if (opportunities == null || opportunities.isEmpty()) {
            return frequency;
        }

        // Get date 24 months ago from today
        Date twentyFourMonthsAgo = Date.today().addMonths(-24);
        
        // Count donations in last 24 months
        Integer donationCount = 0;
        for (Opportunity opp : opportunities) {
            if (opp.CloseDate >= twentyFourMonthsAgo) {
                donationCount++;
            }
        }
        System.debug('Donation Count => ' + donationCount);
        
        // Determine range for switch statement
        Integer range = donationCount >= 24 ? 5 : 
                       donationCount >= 12 ? 4 : 
                       donationCount >= 3  ? 3 : 
                       donationCount == 2  ? 2 : 
                       donationCount == 1  ? 1 : 0;
        
        // Determine frequency value based on donation count
        switch on range {
            when 5 {
                frequency = 5;
            }
            when 4 {
                frequency = 4;
            }
            when 3 {
                frequency = 3;
            }
            when 2 {
                frequency = 2;
            }
            when 1 {
                frequency = 1;
            }
            when else {
                frequency = 0;
            }
        }
        
        System.debug('Frequency => ' + frequency);
        return frequency;
    }

    /**
    * @description calculateMonetary description
    * @param  opportunities opportunities description
    * @return               return description
    */
    public static Integer calculateMonetary(List<Opportunity> opportunities) {
        System.debug('Calculating Monetary for Opportunities => ' + JSON.serialize(opportunities));

        // Initialize monetary to 0
        Integer monetary = 0;
        
        // If there are no opportunities, return 0
        if (opportunities == null || opportunities.isEmpty()) {
            return monetary;
        }

        // Get date 24 months ago from today
        Date twentyFourMonthsAgo = Date.today().addMonths(-24);
        
        // Calculate total amount for donations in last 24 months
        Decimal totalAmount = 0;
        for (Opportunity opp : opportunities) {
            if (opp.CloseDate >= twentyFourMonthsAgo) {
                totalAmount += opp.Amount != null ? opp.Amount : 0;
            }
        }

        System.debug('Total Amount => ' + totalAmount);

        // Determine range for switch statement
        Integer range = totalAmount >= 2001 ? 5 :
                        totalAmount >= 501 ? 4 :
                        totalAmount >= 250 ? 3 :
                        totalAmount >= 101 ? 2 :
                        totalAmount > 25 ? 1 : 0;
        
        // Determine monetary value based on total amount
        switch on range {
            when 5 {
                monetary = 5;
            }
            when 4 {
                monetary = 4;
            }
            when 3 {
                monetary = 3;
            }
            when 2 {
                monetary = 2;
            }
            when 1 {
                monetary = 1;
            }
            when else {
                monetary = 0;
            }
        }
        
        
        System.debug('Monetary => ' + monetary);
        return monetary;
    }

    /**
    * @description calculateEngagement description
    * @param  contact contact description
    * @param  recency recency description
    * @return               return description
    */
    public static String calculateEngagement(Contact contact, Integer recency) {
        System.debug('Calculating Engagement for Contact => ' + JSON.serialize(contact) + ' with Recency => ' + recency);
        
        // Default to disengaged
        String engagementLabel = 'Disengaged';
        
        // Determine range for switch statement
        Integer range = recency == 5 ? 3 :      // Engaged
                       recency >= 3 ? 2 :       // Slipping
                       recency >= 1 ? 1 : 0;    // Disengaged
        
        // Determine engagement status based on recency
        switch on range {
            when 3 {
                engagementLabel = 'Engaged';
            }
            when 2 {
                engagementLabel = 'Slipping';
            }
            when else {
                engagementLabel = 'Disengaged';
            }
        }
        
        System.debug('Engagement Label => ' + engagementLabel);
        return engagementLabel;
    }

    /**
    * @description calculateEngagement description
    * @param  contact contact description
    * @return               return description
    */
    public static Integer calculateVolunteerOrFosterStatus(Contact contact) {
        System.debug('Calculating Volunteer or Foster Status for Contact => ' + JSON.serialize(contact));
        
        if (contact == null) {
            return 0;
        }

        // Create list and add all non-null dates
        List<Date> engagementDates = new List<Date>();
        if (contact.Last_volunteer_date__c != null) {
            engagementDates.add(contact.Last_volunteer_date__c);
        }
        if (contact.Date_Of_Current_Foster__c != null) {
            engagementDates.add(contact.Date_Of_Current_Foster__c);
        }
        if (contact.Date_Of_Last_Foster_Returned__c != null) {
            engagementDates.add(contact.Date_Of_Last_Foster_Returned__c);
        }
        System.debug('Engagement Dates => ' + JSON.serialize(engagementDates));

        // Find the most recent date
        Date mostRecentDate = null;
        if (!engagementDates.isEmpty()) {
            mostRecentDate = engagementDates[0];
            for(Date d : engagementDates) {
                if(d > mostRecentDate) {
                    mostRecentDate = d;
                }
            }
        }
        System.debug('Most Recent Date => ' + mostRecentDate);

        // If no engagement dates exist, return never
        if (mostRecentDate == null) {
            return 0;
        }

        // Calculate days since most recent engagement
        Integer daysSinceLastEngagement = mostRecentDate.daysBetween(Date.today());
        System.debug('Days Since Last Engagement => ' + daysSinceLastEngagement);

        
        // Determine range for switch statement
        Integer range = daysSinceLastEngagement <= 30   ? 5 :  // Past 30 days
                        daysSinceLastEngagement <= 180  ? 4 :  // Past 6 months
                        daysSinceLastEngagement <= 365  ? 3 :  // Past year
                        daysSinceLastEngagement <= 730  ? 2 :  // Past 2 years
                        daysSinceLastEngagement > 730   ? 1 :  // Ever
                                                        0;   // Never
        
        Integer volunteerOrFosterStatus;
        // Determine engagement value based on days since last engagement
        switch on range {
            when 5 {
                volunteerOrFosterStatus = 5;  // Past 30 days
            }
            when 4 {
                volunteerOrFosterStatus = 4;  // Past 6 months
            }
            when 3 {
                volunteerOrFosterStatus = 3;  // Past year
            }
            when 2 {
                volunteerOrFosterStatus = 2;  // Past 2 years
            }
            when else {
                volunteerOrFosterStatus = 1;  // Ever/Never
            }
        }
        
        System.debug('Volunteer/Foster Status => ' + volunteerOrFosterStatus);
        return volunteerOrFosterStatus;
    }

    
    /**
    * @description calculateImpact description
    * @param  contact contact description
    * @param  frequency frequency description
    * @param  monetary monetary description
    * @return               return description
    */
    public static String calculateImpact(Contact contact, Integer frequency, Integer monetary) {
        System.debug('Calculating Impact for Contact => ' + JSON.serialize(contact) + ' with Frequency => ' + frequency + ' and Monetary => ' + monetary);

        // Calculate average of F and M
        Decimal average = (frequency + monetary) / 2.0;
        System.debug('F+M Average => ' + average);

        
        // Determine range for switch statement
        Integer range = average >= 4 ? 2 :    // High impact (4-5)
                       average >= 1 ? 1 : 0;  // Low impact (1-3)
        
        String impactLevel;
        // Determine impact level based on average
        switch on range {
            when 2 {
                impactLevel = 'High Impact';
            }
            when else {
                impactLevel = 'Low Impact';
            }
        }
        
        System.debug('Impact Level => ' + impactLevel);
        return impactLevel;
    }
}