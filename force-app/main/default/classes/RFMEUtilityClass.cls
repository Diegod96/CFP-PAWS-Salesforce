/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 10-19-2024
 * @last modified by  : Diego Delgado
**/
public class RFMEUtilityClass {
    public static Integer calculateRecency(List<Opportunity> opportunities) {
        Date mostRecentCloseDate = opportunities[0].CloseDate;
        for (Opportunity opp : opportunities) {
            if (opp.CloseDate > mostRecentCloseDate) {
                mostRecentCloseDate = opp.CloseDate;
            }
        }
        return Date.today().daysBetween(mostRecentCloseDate);
    }

    public static Integer calculateFrequency(List<Opportunity> opportunities) {
        return opportunities.size();
    }

    public static Decimal calculateMonetary(List<Opportunity> opportunities) {
        Decimal monetary = 0;
        for (Opportunity opp : opportunities) {
            monetary += opp.Amount;
        }
        return monetary;
    }


    public static Integer calculateEngagement(Contact contact) {
        
        System.debug('Calculating engagement for contact: ' + contact);

        Date today = Date.today();
        Date mostRecentVolunteerDate = contact.Last_volunteer_date__c;
        Date mostRecentDateCurrentFoster = contact.Date_Of_Current_Foster__c;
        Date mostRecentFosterReturnedDate = contact.Date_Of_Last_Foster_Returned__c;

        Integer daysBetween;

        if (mostRecentVolunteerDate == null && mostRecentDateCurrentFoster == null && mostRecentFosterReturnedDate == null) {
            // No engagement dates available
            daysBetween = -1;
        } else if (mostRecentVolunteerDate == null && mostRecentDateCurrentFoster == null && mostRecentFosterReturnedDate != null) {
            // Only foster returned date is available
            daysBetween = mostRecentFosterReturnedDate.daysBetween(today);
        } else if (mostRecentVolunteerDate == null && mostRecentDateCurrentFoster != null && mostRecentFosterReturnedDate == null) {
            // Only current foster date is available
            daysBetween = mostRecentDateCurrentFoster.daysBetween(today);
        } else if (mostRecentVolunteerDate != null && mostRecentDateCurrentFoster == null && mostRecentFosterReturnedDate == null) {
            // Only volunteer date is available
            daysBetween = mostRecentVolunteerDate.daysBetween(today);
        } else {
            // Multiple dates available, determine the most recent one
            if (mostRecentVolunteerDate != null && (mostRecentVolunteerDate >= mostRecentDateCurrentFoster || mostRecentVolunteerDate >= mostRecentFosterReturnedDate)) {
                // Volunteer date is the most recent
                daysBetween = mostRecentVolunteerDate.daysBetween(today);
            } else if (mostRecentDateCurrentFoster != null && (mostRecentDateCurrentFoster >= mostRecentFosterReturnedDate)) {
                // Current foster date is the most recent
                daysBetween = mostRecentDateCurrentFoster.daysBetween(today);
            } else if (mostRecentFosterReturnedDate != null) {
                // Foster returned date is the most recent
                daysBetween = mostRecentFosterReturnedDate.daysBetween(today);
            } else {
                // Default case, should not be reached
                daysBetween = 0;
            }
        }

        return daysBetween;
    }
}