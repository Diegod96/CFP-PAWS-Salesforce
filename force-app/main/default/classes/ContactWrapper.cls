/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-19-2024
 * @last modified by  : Diego Delgado
**/
public class ContactWrapper {
    // public String createdById { get; set; }
    // public String createdDate { get; set; }
    public List<ContactDetails> updatedContactsJson { get; set; }

    public class ContactDetails {
        public String contactId { get; set; }
        public List<String> personIds { get; set; }
        public String firstVolunteerDate { get; set; }
        public String fosterEndDate { get; set; }
        public String fosterStartDate { get; set; }
        public String lastVolunteerDate { get; set; }
        public Decimal totalVolunteerHours { get; set; }
        public String volunteerStatus { get; set; }
        public List<String> volgisticIds { get; set; }
    }

    public static ContactWrapper parse(String json) {
        return (ContactWrapper) System.JSON.deserialize(json, ContactWrapper.class);
    }
}