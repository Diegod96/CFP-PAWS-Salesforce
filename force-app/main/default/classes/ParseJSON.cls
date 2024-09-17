/**
 * @description       : Parse the JSON Response we get from the PAWS-Pipeline
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-20-2024
 * @last modified by  : Diego Delgado
**/
public class ParseJSON {

    public class ContactInfo {
        @InvocableVariable
        public String contactId;

        @InvocableVariable
        public String firstVolunteerDate;

        @InvocableVariable
        public String fosterEndDate;

        @InvocableVariable
        public String fosterStartDate;

        @InvocableVariable
        public String lastVolunteerDate;

        @InvocableVariable
        public String totalVolunteerHours;

        @InvocableVariable
        public String volunteerStatus;

        @InvocableVariable
        public String personIds;

        @InvocableVariable
        public String volgisticIds;
    }

    public class RequestWrapper {
        @InvocableVariable(Required=true)
        public String jsonString;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public List<ParseJSON.ContactInfo> contactsInfo;
    }

    @InvocableMethod(label='Parse JSON Request From PAWS Pipeline')
    public static List<ResponseWrapper> parseJson(List<RequestWrapper> requests) {
        
        System.debug('In ParseJSON');
        System.debug('Requests: ' + requests);
        
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
 
                    // Retrieve values from the map and convert them to strings
                    String stringPersonIds = String.valueOf(contactMap.get('personIds'));
                    String stringVolgisticIds = String.valueOf(contactMap.get('volgisticIds'));
                    
                    // Check if the string is '[]', if so, set it to '[]'
                    stringPersonIds = stringPersonIds == '[]' ? '[]' : stringPersonIds;
                    stringVolgisticIds = stringVolgisticIds == '[]' ? '[]' : stringVolgisticIds;
                    
                    // Modify the strings by removing brackets if they are not '[]'
                    String stringPersonIdsModified = stringPersonIds != '[]' ? stringPersonIds.replace('[', '').replace(']', '') : stringPersonIds;
                    String stringVolgisticIdsModified = stringVolgisticIds != '[]' ? stringVolgisticIds.replace('[', '').replace(']', '') : stringVolgisticIds;
                    
                    // Debug statements to verify the values
                    System.debug('stringPersonIdsModified: ' + stringPersonIdsModified);
                    System.debug('stringVolgisticIdsModified: ' + stringVolgisticIdsModified);


                    // Assign to response
                    contactInfo.personIds = stringPersonIdsModified;
                    contactInfo.volgisticIds = stringVolgisticIdsModified;

                    // These fields will always have a value
                    contactInfo.contactId = (String) contactMap.get('contactId');
                    contactInfo.volunteerStatus = (String) contactMap.get('volunteerStatus');

                    // These fields may be null
                    contactInfo.firstVolunteerDate = contactMap.containsKey('firstVolunteerDate') && contactMap.get('firstVolunteerDate') != null ? (String) contactMap.get('firstVolunteerDate') : null;
                    contactInfo.fosterEndDate = contactMap.containsKey('fosterEndDate') && contactMap.get('fosterEndDate') != null ? (String) contactMap.get('fosterEndDate') : null;
                    contactInfo.fosterStartDate = contactMap.containsKey('fosterStartDate') && contactMap.get('fosterStartDate') != null ? (String) contactMap.get('fosterStartDate') : null;
                    contactInfo.lastVolunteerDate = contactMap.containsKey('lastVolunteerDate') && contactMap.get('lastVolunteerDate') != null ? (String) contactMap.get('lastVolunteerDate') : null;
                    contactInfo.totalVolunteerHours = contactMap.containsKey('totalVolunteerHours') && contactMap.get('totalVolunteerHours') != null ? String.valueOf(contactMap.get('totalVolunteerHours')) : null;


                    response.contactsInfo.add(contactInfo);
                }
            }
            
            responses.add(response);
        }
        
        System.debug('responses -> ' + responses);
        return responses;
    }
}