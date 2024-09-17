/**
 * Created by diegodelgado on 9/15/24.
 */

public class ParseJSONBatch implements Database.Batchable<SObject>, Database.Stateful {


    // JSON string we get from ParseJSON
    public String jsonString;

    //
    public ParseJSONBatch(String jsonString) {
        this.jsonString = jsonString;
    }

    /**
     * @param bc
     *
     * @return
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        //
        List<ParseJSON.RequestWrapper> requestList = new List<ParseJSON.RequestWrapper>();
        ParseJSON.RequestWrapper request = new ParseJSON.RequestWrapper();
        request.jsonString = jsonString;
        requestList.add(request);

        //
        List<ParseJSON.ResponseWrapper> responseList = ParseJSON.parseJson(requestList);

        List<String> contactIds = new List<String>();
        if (!responseList.isEmpty() && !responseList[0].contactsInfo.isEmpty()) {
            for (ParseJSON.ContactInfo info : responseList[0].contactsInfo) {
                contactIds.add(info.contactId);
            }
        }

        //
        return Database.getQueryLocator([
                SELECT Id, Last_Sync_With_Pipeline__c ,First_volunteer_date__c, Last_volunteer_date__c, Foster_Start_Date__c, Foster_End_Date__c, Total_volunteer_hours__c, Volunteer_Status__c, Duplicate_Person_Ids__c, Duplicate_Volgistic_Ids__c, Duplicate_Ids__c
                FROM Contact
                WHERE Id IN :contactIds
        ]);
    }

    /**
     * @param bc
     * @param scope
     */
    public void execute(Database.BatchableContext bc, List<Contact> scope) {

        List<Contact> contactsToUpdate = new List<Contact>();
        List<ParseJSON.RequestWrapper> requestList = new List<ParseJSON.RequestWrapper>();
        ParseJSON.RequestWrapper request = new ParseJSON.RequestWrapper();
        request.jsonString = jsonString;
        requestList.add(request);

        List<ParseJSON.ResponseWrapper> responseList = ParseJSON.parseJson(requestList);

        Map<String, ParseJSON.ContactInfo> contactDataMap = new Map<String, ParseJSON.ContactInfo>();
        if (!responseList.isEmpty()) {
            for (ParseJSON.ContactInfo contactInfo : responseList[0].contactsInfo) {
                contactDataMap.put(contactInfo.contactId, contactInfo);
            }
        }

        for (Contact contact : scope) {
            if (contactDataMap.containsKey(contact.Id)) {
                ParseJSON.ContactInfo contactInfo = contactDataMap.get(contact.Id);

                contact.Last_Sync_With_Pipeline__c = Datetime.now();
                contact.First_volunteer_date__c = contactInfo.firstVolunteerDate != null ? Date.valueOf(contactInfo.firstVolunteerDate) : contact.First_volunteer_date__c;
                contact.Foster_End_Date__c = contactInfo.fosterEndDate != null ? Date.valueOf(contactInfo.fosterEndDate) : contact.Foster_End_Date__c;
                contact.Foster_Start_Date__c = contactInfo.fosterStartDate != null ? Date.valueOf(contactInfo.fosterStartDate) : contact.Foster_Start_Date__c;
                contact.Last_volunteer_date__c = contactInfo.lastVolunteerDate != null ? Date.valueOf(contactInfo.lastVolunteerDate) : contact.Last_volunteer_date__c;
                contact.Total_volunteer_hours__c = contactInfo.totalVolunteerHours != null ? Decimal.valueOf(contactInfo.totalVolunteerHours) : contact.Total_volunteer_hours__c;
                contact.Volunteer_Status__c = contactInfo.volunteerStatus != null ? contactInfo.volunteerStatus : contact.Volunteer_Status__c;

                contactsToUpdate.add(contact);
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(contactsToUpdate, false);

            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    for (Database.Error error : results[i].getErrors()) {
                        System.debug('Failed to update Contact ID ' + contactsToUpdate[i].Id + ' due to error: ' + error.getMessage());
                    }
                }
            }
        }
    }

    /**
     * @param bc
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Contact Batch Processing Finished...');
    }


}