/**
 * @description       : Parse the JSON Response we get from the PAWS-Pipeline
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-20-2024
 * @last modified by  : Diego Delgado
**/
public class ParseJSON {

    public class RequestWrapper {
        @InvocableVariable(required=true)
        public String jsonString;
    }
    
    public class ResponseWrapper {
        @InvocableVariable
        public List<ContactInfo> contactsInfo;
    }


    @InvocableMethod(label='Parse JSON')
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



                    contactInfo.personIds = stringPersonIdsModified;
                    contactInfo.volgisticIds = stringVolgisticIdsModified;
                    contactInfo.contactId = (String) contactMap.get('contactId');
                    contactInfo.firstVolunteerDate = (String) contactMap.get('firstVolunteerDate');
                    contactInfo.fosterEndDate = (String) contactMap.get('fosterEndDate');
                    contactInfo.fosterStartDate = (String) contactMap.get('fosterStartDate');
                    contactInfo.lastVolunteerDate = (String) contactMap.get('lastVolunteerDate');
                    contactInfo.totalVolunteerHours = String.valueOf(contactMap.get('totalVolunteerHours'));
                    contactInfo.volunteerStatus = (String) contactMap.get('volunteerStatus');

                    response.contactsInfo.add(contactInfo);
                }
            }
            
            responses.add(response);
        }
        
        System.debug('responses -> ' + responses);
        return responses;
    }
}