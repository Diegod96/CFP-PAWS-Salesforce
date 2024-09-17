/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-19-2024
 * @last modified by  : Diego Delgado
**/
public class ContactParser {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String jsonString;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public List<ContactInfo> contactsInfo;
    }

    public class ContactInfo {
        @InvocableVariable(label='Contact ID')
        public String contactId;
        @InvocableVariable(label='Person IDs')
        public List<String> personIds;
        @InvocableVariable(label='First Volunteer Date')
        public String firstVolunteerDate;
        @InvocableVariable(label='Foster End Date')
        public String fosterEndDate;
        @InvocableVariable(label='Foster Start Date')
        public String fosterStartDate;
        @InvocableVariable(label='Last Volunteer Date')
        public String lastVolunteerDate;
        @InvocableVariable(label='Total Volunteer Hours')
        public String totalVolunteerHours; // Adjusted to String to ensure compatibility
        @InvocableVariable(label='Volunteer Status')
        public String volunteerStatus;
        @InvocableVariable(label='Volgistic IDs')
        public List<String> volgisticIds;
    }

    @InvocableMethod(label='Parse JSON')
    public static List<ResponseWrapper> parseJson(List<RequestWrapper> requests) {
        List<ResponseWrapper> responses = new List<ResponseWrapper>();
        
        // Process each request
        for(RequestWrapper request : requests) {
            ResponseWrapper response = new ResponseWrapper();
            response.contactsInfo = new List<ContactInfo>();
            
            // Parse JSON string
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(request.jsonString);

            // Extract data from "updatedContactsJson" array
            List<Object> updatedContactsJson = (List<Object>) jsonMap.get('updatedContactsJson');
            if (updatedContactsJson != null) {
                for (Object contactObj : updatedContactsJson) {
                    Map<String, Object> contactMap = (Map<String, Object>) contactObj;
                    ContactInfo contactInfo = new ContactInfo();

                    contactInfo.contactId = (String) contactMap.get('contactId');
                    contactInfo.personIds = (List<String>) contactMap.get('personIds');
                    contactInfo.firstVolunteerDate = (String) contactMap.get('firstVolunteerDate');
                    contactInfo.fosterEndDate = (String) contactMap.get('fosterEndDate');
                    contactInfo.fosterStartDate = (String) contactMap.get('fosterStartDate');
                    contactInfo.lastVolunteerDate = (String) contactMap.get('lastVolunteerDate');
                    contactInfo.totalVolunteerHours = String.valueOf(contactMap.get('totalVolunteerHours')); // Ensure string representation
                    contactInfo.volunteerStatus = (String) contactMap.get('volunteerStatus');
                    contactInfo.volgisticIds = (List<String>) contactMap.get('volgisticIds');

                    response.contactsInfo.add(contactInfo);
                }
            }
            
            responses.add(response);
        }
        
        return responses;
    }
}