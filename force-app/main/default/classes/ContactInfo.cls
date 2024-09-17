/**
 * @description       : Apex Defined Variable to Hold Contact Info Attributes
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 02-20-2024
 * @last modified by  : Diego Delgado
**/
public class ContactInfo {
    @InvocableVariable(label='Contact ID')
    @AuraEnabled
    public String contactId;

    @InvocableVariable(label='Person IDs')
    @AuraEnabled
    public String personIds;

    @InvocableVariable(label='First Volunteer Date')
    @AuraEnabled
    public String firstVolunteerDate;

    @InvocableVariable(label='Foster End Date')
    @AuraEnabled
    public String fosterEndDate;

    @InvocableVariable(label='Foster Start Date')
    @AuraEnabled
    public String fosterStartDate;

    @InvocableVariable(label='Last Volunteer Date')
    @AuraEnabled
    public String lastVolunteerDate;

    @InvocableVariable(label='Total Volunteer Hours')
    @AuraEnabled
    public String totalVolunteerHours;

    @InvocableVariable(label='Volunteer Status')
    @AuraEnabled
    public String volunteerStatus;

    @InvocableVariable(label='Volgistic IDs')
    @AuraEnabled
    public String volgisticIds;
}