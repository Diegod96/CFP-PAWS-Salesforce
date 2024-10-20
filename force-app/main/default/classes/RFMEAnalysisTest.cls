/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 10-19-2024
 * @last modified by  : Diego Delgado
**/
@isTest
public class RFMEAnalysisTest {
    @testSetup
    static void setup() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                LastName = 'Test Contact ' + i,
                Last_volunteer_date__c = Date.today().addDays(-i * 10),
                Date_Of_Current_Foster__c = Date.today().addDays(-i * 20),
                Date_Of_Last_Foster_Returned__c = Date.today().addDays(-i * 30)
            ));
        }
        insert contacts;

        // Create test opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Contact contact : contacts) {
            for (Integer j = 0; j < 3; j++) {
                opportunities.add(new Opportunity(
                    Name = 'Test Opportunity ' + j,
                    Amount = 1000 * (j + 1),
                    npsp__Primary_Contact__c = contact.Id,
                    CloseDate = Date.today().addDays(-j * 15),
                    StageName = 'Closed Won'
                ));
            }
        }
        insert opportunities;
    }

    @isTest
    static void testRFMEAnalysisBatch() {
        // Execute the batch job
        Test.startTest();
        RFMEAnalysisBatch batch = new RFMEAnalysisBatch();
        Database.executeBatch(batch);
        Test.stopTest();

        // Verify that the contacts are updated correctly
        List<Contact> updatedContacts = [SELECT Id, Recency__c, Number_Of_Opportunities__c, Monetary__c, Volunteer_or_Foster_Days_Between__c FROM Contact];
        System.assertEquals(5, updatedContacts.size(), 'Expected 5 contacts to be updated.');

        for (Contact contact : updatedContacts) {
            System.assertNotEquals(null, contact.Recency__c, 'Recency__c should not be null.');
            System.assertNotEquals(null, contact.Number_Of_Opportunities__c, 'Number_Of_Opportunities__c should not be null.');
            System.assertNotEquals(null, contact.Monetary__c, 'Monetary__c should not be null.');
            System.assertNotEquals(null, contact.Volunteer_or_Foster_Days_Between__c, 'Volunteer_or_Foster_Days_Between__c should not be null.');
        }
    }

    @isTest
    static void testCalculateRecency() {
        // Fetch test opportunities
        List<Opportunity> opportunities = [SELECT Id, CloseDate FROM Opportunity LIMIT 3];
        
        // Calculate Recency
        Integer recency = RFMEUtilityClass.calculateRecency(opportunities);
        
        // Verify Recency
        Integer expectedRecency = Date.today().daysBetween(opportunities[0].CloseDate);
        System.assertEquals(expectedRecency, recency, 'Recency calculation is incorrect.');
    }

    @isTest
    static void testCalculateFrequency() {
        // Fetch test opportunities
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 3];
        
        // Calculate Frequency
        Integer frequency = RFMEUtilityClass.calculateFrequency(opportunities);
        
        // Verify Frequency
        System.assertEquals(3, frequency, 'Frequency calculation is incorrect.');
    }

    @isTest
    static void testCalculateMonetary() {
        // Fetch test opportunities
        List<Opportunity> opportunities = [SELECT Id, Amount FROM Opportunity LIMIT 3];
        
        // Calculate Monetary
        Decimal monetary = RFMEUtilityClass.calculateMonetary(opportunities);
        
        // Verify Monetary
        Decimal expectedMonetary = 1000 + 2000 + 3000;
        System.assertEquals(expectedMonetary, monetary, 'Monetary calculation is incorrect.');
    }

    @isTest
    static void testCalculateEngagement() {
        // Create test contacts with different date combinations
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'Test Engagement Contact 1'), // All dates null
            new Contact(LastName = 'Test Engagement Contact 2', Last_volunteer_date__c = Date.today().addDays(-10)), // Only Last_volunteer_date__c not null
            new Contact(LastName = 'Test Engagement Contact 3', Date_Of_Current_Foster__c = Date.today().addDays(-20)), // Only Date_Of_Current_Foster__c not null
            new Contact(LastName = 'Test Engagement Contact 4', Date_Of_Last_Foster_Returned__c = Date.today().addDays(-30)), // Only Date_Of_Last_Foster_Returned__c not null
            new Contact(LastName = 'Test Engagement Contact 5', Last_volunteer_date__c = Date.today().addDays(-10), Date_Of_Current_Foster__c = Date.today().addDays(-20), Date_Of_Last_Foster_Returned__c = Date.today().addDays(-30)) // All dates not null
        };

        insert contacts;

        // Fetch the inserted contacts
        contacts = [SELECT Id, LastName, Last_volunteer_date__c, Date_Of_Current_Foster__c, Date_Of_Last_Foster_Returned__c FROM Contact WHERE LastName LIKE 'Test Engagement Contact %'];


        // Test case 1: All dates are null
        System.debug('Testing engagement calculation for all dates null - ' + contacts[0]);
        Integer engagement1 = RFMEUtilityClass.calculateEngagement(contacts[0]);
        System.assertEquals(-1, engagement1, 'Engagement calculation is incorrect for all dates null.');

        // Test case 2: Only Last_volunteer_date__c is not null
        System.debug('Testing engagement calculation for only Last_volunteer_date__c not null - ' + contacts[1]);
        Integer engagement2 = RFMEUtilityClass.calculateEngagement(contacts[1]);
        Integer expectedEngagement2 = Math.abs(Date.today().daysBetween(contacts[1].Last_volunteer_date__c));
        System.assertEquals(expectedEngagement2, engagement2, 'Engagement calculation is incorrect for only Last_volunteer_date__c not null.');

        // Test case 3: Only Date_Of_Current_Foster__c is not null
        System.debug('Testing engagement calculation for only Date_Of_Current_Foster__c not null - ' + contacts[2]);
        Integer engagement3 = RFMEUtilityClass.calculateEngagement(contacts[2]);
        Integer expectedEngagement3 = Math.abs(Date.today().daysBetween(contacts[2].Date_Of_Current_Foster__c));
        System.assertEquals(expectedEngagement3, engagement3, 'Engagement calculation is incorrect for only Date_Of_Current_Foster__c not null.');

        // Test case 4: Only Date_Of_Last_Foster_Returned__c is not null
        System.debug('Testing engagement calculation for only Date_Of_Last_Foster_Returned__c not null - ' + contacts[3]);
        Integer engagement4 = RFMEUtilityClass.calculateEngagement(contacts[3]);
        Integer expectedEngagement4 = Math.abs(Date.today().daysBetween(contacts[3].Date_Of_Last_Foster_Returned__c));
        System.assertEquals(expectedEngagement4, engagement4, 'Engagement calculation is incorrect for only Date_Of_Last_Foster_Returned__c not null.');

        // Test case 5: All dates are not null
        System.debug('Testing engagement calculation for all dates not null - ' + contacts[4]);
        Integer engagement5 = RFMEUtilityClass.calculateEngagement(contacts[4]);
        Integer expectedEngagement5 = Math.abs(Date.today().daysBetween(contacts[4].Last_volunteer_date__c));
        System.assertEquals(expectedEngagement5, engagement5, 'Engagement calculation is incorrect for all dates not null.');
    }
}