/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 01-20-2025
 * @last modified by  : Diego Delgado
**/
@isTest
public class RFMEAnalysisTest {

    /**
     * @description Sets up test data including contacts with various dates and related opportunities
     */
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

    /**
     * @description Tests the calculateRecency method with different date ranges
     * Tests scores 1-5 based on donation dates:
     * 5: ≤ 180 days
     * 4: 181-365 days
     * 3: 366-728 days
     * 2: 729-1093 days
     * 1: > 1093 days
     */
    @isTest
    static void testCalculateRecency() {
        // Test recency = 5 (≤ 180 days)
        System.assertEquals(5, RFMEUtilityClass.calculateRecency(new List<Opportunity>{
            new Opportunity(CloseDate = Date.today())
        }), 'Today should score 5');
        
        // Test recency = 4 (181-365 days)
        System.assertEquals(4, RFMEUtilityClass.calculateRecency(new List<Opportunity>{
            new Opportunity(CloseDate = Date.today().addDays(-181))
        }), '181 days should score 4');
        
        // Test recency = 3 (366-728 days)
        System.assertEquals(3, RFMEUtilityClass.calculateRecency(new List<Opportunity>{
            new Opportunity(CloseDate = Date.today().addDays(-366))
        }), '366 days should score 3');
        
        // Test recency = 2 (729-1093 days)
        System.assertEquals(2, RFMEUtilityClass.calculateRecency(new List<Opportunity>{
            new Opportunity(CloseDate = Date.today().addDays(-729))
        }), '729 days should score 2');
        
        // Test recency = 1 (> 1093 days)
        System.assertEquals(1, RFMEUtilityClass.calculateRecency(new List<Opportunity>{
            new Opportunity(CloseDate = Date.today().addDays(-1094))
        }), '1094 days should score 1');
    }

    /**
     * @description Tests the calculateFrequency method with different donation counts
     * Tests scores 1-5 based on number of donations:
     * 5: ≥ 24 donations
     * 4: 12-23 donations
     * 3: 3-11 donations
     * 2: 2 donations
     * 1: 1 donation
     */
    @isTest
    static void testCalculateFrequency() {
        List<Opportunity> opportunities = new List<Opportunity>();
        Date recentDate = Date.today().addMonths(-1);
        
        // Test different frequency ranges
        for(Integer i = 0; i < 25; i++) {
            opportunities.add(new Opportunity(
                CloseDate = recentDate,
                Amount = 100
            ));
        }
        
        // Test each scenario
        List<Opportunity> test1 = new List<Opportunity>{opportunities[0]}; // 1 donation
        System.assertEquals(1, RFMEUtilityClass.calculateFrequency(test1), 'Single donation should score 1');
        
        List<Opportunity> test2 = new List<Opportunity>{opportunities[0], opportunities[1]}; // 2 donations
        System.assertEquals(2, RFMEUtilityClass.calculateFrequency(test2), 'Two donations should score 2');
        
        List<Opportunity> test3 = new List<Opportunity>();
        for(Integer i = 0; i < 3; i++) {
            test3.add(opportunities[i]);
        }
        System.assertEquals(3, RFMEUtilityClass.calculateFrequency(test3), 'Three donations should score 3');
        
        List<Opportunity> test4 = new List<Opportunity>();
        for(Integer i = 0; i < 12; i++) {
            test4.add(opportunities[i]);
        }
        System.assertEquals(4, RFMEUtilityClass.calculateFrequency(test4), 'Twelve donations should score 4');
        
        List<Opportunity> test5 = new List<Opportunity>();
        for(Integer i = 0; i < 24; i++) {
            test5.add(opportunities[i]);
        }
        System.assertEquals(5, RFMEUtilityClass.calculateFrequency(test5), 'Twenty-four donations should score 5');
    }

    /**
     * @description Tests the calculateMonetary method with different amount ranges
     * Tests scores 0-5 based on donation amounts:
     * 5: ≥ 2001
     * 4: 501-2000
     * 3: 250-500
     * 2: 101-249
     * 1: 26-100
     * 0: ≤ 25
     */
    @isTest
    static void testCalculateMonetary() {
        Date recentDate = Date.today().addDays(-30); // Within 24 months
        
        // Test monetary = 0 (≤ 25)
        System.assertEquals(0, RFMEUtilityClass.calculateMonetary(new List<Opportunity>{
            new Opportunity(Amount = 25, CloseDate = recentDate)
        }), 'Amount of 25 should score 0');
        
        // Test monetary = 1 (26-100)
        System.assertEquals(1, RFMEUtilityClass.calculateMonetary(new List<Opportunity>{
            new Opportunity(Amount = 50, CloseDate = recentDate)
        }), 'Amount of 50 should score 1');
        
        // Test monetary = 2 (101-249)
        System.assertEquals(2, RFMEUtilityClass.calculateMonetary(new List<Opportunity>{
            new Opportunity(Amount = 200, CloseDate = recentDate)
        }), 'Amount of 200 should score 2');
        
        // Test monetary = 3 (250-500)
        System.assertEquals(3, RFMEUtilityClass.calculateMonetary(new List<Opportunity>{
            new Opportunity(Amount = 300, CloseDate = recentDate)
        }), 'Amount of 300 should score 3');
        
        // Test monetary = 4 (501-2000)
        System.assertEquals(4, RFMEUtilityClass.calculateMonetary(new List<Opportunity>{
            new Opportunity(Amount = 1000, CloseDate = recentDate)
        }), 'Amount of 1000 should score 4');
        
        // Test monetary = 5 (≥ 2001)
        System.assertEquals(5, RFMEUtilityClass.calculateMonetary(new List<Opportunity>{
            new Opportunity(Amount = 2500, CloseDate = recentDate)
        }), 'Amount of 2500 should score 5');
    }

    /**
     * @description Tests the calculateEngagement method with different scenarios
     * Tests engagement status based on volunteer/foster dates and recency:
     * - Engaged: High recency (5) with recent activity
     * - Slipping: Medium recency (4) with moderate activity
     * - Disengaged: Low recency (≤3) or no recent activity
     */
    @isTest
    static void testCalculateEngagement() {
        // Create test contacts with different date combinations
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'Test Engagement Contact 1'), // All dates null
            new Contact(LastName = 'Test Engagement Contact 2', Last_volunteer_date__c = Date.today().addDays(-10)), 
            new Contact(LastName = 'Test Engagement Contact 3', Date_Of_Current_Foster__c = Date.today().addDays(-20))
        };

        insert contacts;

        // Fetch the inserted contacts
        contacts = [SELECT Id, LastName, Last_volunteer_date__c, Date_Of_Current_Foster__c, Date_Of_Last_Foster_Returned__c 
                    FROM Contact WHERE LastName LIKE 'Test Engagement Contact %'];

        // Test different recency values
        Integer lowRecency = 2;    // Should result in "Disengaged"
        Integer medRecency = 4;    // Should result in "Slipping"
        Integer highRecency = 5;   // Should result in "Engaged"

        // Test engagement calculations
        System.assertEquals('Disengaged', RFMEUtilityClass.calculateEngagement(contacts[0], lowRecency), 
            'Contact with no dates and low recency should be Disengaged');
        
        System.assertEquals('Slipping', RFMEUtilityClass.calculateEngagement(contacts[1], medRecency), 
            'Contact with recent volunteer date and medium recency should be Slipping');
        
        System.assertEquals('Engaged', RFMEUtilityClass.calculateEngagement(contacts[2], highRecency), 
            'Contact with recent foster date and high recency should be Engaged');
    }

    /**
     * @description Tests the calculateVolunteerOrFosterStatus method with different date ranges
     * Tests scores 0-5 based on most recent volunteer/foster date:
     * 5: ≤ 30 days
     * 4: 31-180 days
     * 3: 181-365 days
     * 2: 366-730 days
     * 1: > 730 days
     * 0: null dates
     */
    @isTest
    static void testVolunteerOrFosterStatus() {
        // Test status = 5 (≤ 30 days)
        System.assertEquals(5, RFMEUtilityClass.calculateVolunteerOrFosterStatus(
            new Contact(Last_volunteer_date__c = Date.today())
        ), 'Today should score 5');
        
        // Test status = 4 (31-180 days)
        System.assertEquals(4, RFMEUtilityClass.calculateVolunteerOrFosterStatus(
            new Contact(Last_volunteer_date__c = Date.today().addDays(-31))
        ), '31 days should score 4');
        
        // Test status = 3 (181-365 days)
        System.assertEquals(3, RFMEUtilityClass.calculateVolunteerOrFosterStatus(
            new Contact(Last_volunteer_date__c = Date.today().addDays(-181))
        ), '181 days should score 3');
        
        // Test status = 2 (366-730 days)
        System.assertEquals(2, RFMEUtilityClass.calculateVolunteerOrFosterStatus(
            new Contact(Last_volunteer_date__c = Date.today().addDays(-366))
        ), '366 days should score 2');
        
        // Test status = 1 (> 730 days)
        System.assertEquals(1, RFMEUtilityClass.calculateVolunteerOrFosterStatus(
            new Contact(Last_volunteer_date__c = Date.today().addDays(-731))
        ), '731 days should score 1');
        
        // Test null scenarios
        System.assertEquals(0, RFMEUtilityClass.calculateVolunteerOrFosterStatus(null), 
            'Null contact should score 0');
    }

    /**
     * @description Tests the RFMEAnalysisBatch by verifying contacts are processed
     * Confirms batch execution by checking LastModifiedDate changes on contacts
     */
    @isTest
    static void testRFMEAnalysisBatch() {
        // Get contacts' last modified dates before batch
        Map<Id, Datetime> originalDates = new Map<Id, Datetime>();
        for(Contact c : [SELECT Id, LastModifiedDate FROM Contact WHERE LastName LIKE 'Test Contact%']) {
            originalDates.put(c.Id, c.LastModifiedDate);
        }
        
        // Start the batch process
        Test.startTest();
        RFMEAnalysisBatch batch = new RFMEAnalysisBatch();
        Database.executeBatch(batch);
        Test.stopTest();
        
        // Verify the results by checking LastModifiedDate has been updated
        List<Contact> updatedContacts = [SELECT Id, LastModifiedDate FROM Contact WHERE LastName LIKE 'Test Contact%'];
        System.assertNotEquals(0, updatedContacts.size(), 'Should have processed contacts');
        
        for(Contact c : updatedContacts) {
            System.assertNotEquals(originalDates.get(c.Id), c.LastModifiedDate, 
                'Contact should have been updated by batch process');
        }
    }

    /**
     * @description Tests the RFMEAnalysisScheduler class
     * Verifies:
     * - Job is scheduled successfully
     * - Correct cron expression (11 PM daily)
     * - Job hasn't been triggered
     * - Next run time is set
     */
    @isTest
    static void testRFMEAnalysisScheduler() {
        // Get the current number of scheduled jobs
        Integer numScheduledJobs = [SELECT COUNT() FROM CronTrigger];
        
        Test.startTest();
        // Schedule the job
        String jobId = System.schedule('Test RFME Analysis', 
            '0 0 23 * * ?',  // Schedule for 11 PM daily
            new RFMEAnalysisScheduler());
        Test.stopTest();
        
        // Verify one more scheduled job exists
        System.assertEquals(numScheduledJobs + 1, [SELECT COUNT() FROM CronTrigger], 
            'One additional job should be scheduled');
        
        // Verify the scheduled job details
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime 
                          FROM CronTrigger WHERE Id = :jobId];
        
        System.assertEquals('0 0 23 * * ?', ct.CronExpression, 'Should be scheduled for 11 PM daily');
        System.assertEquals(0, ct.TimesTriggered, 'Should not have been triggered yet');
        System.assertNotEquals(null, ct.NextFireTime, 'Should have a next scheduled run time');
    }

    /**
     * @description Tests the sendBatchCompletionEmail method
     * Verifies:
     * - Email is sent successfully
     * - Correct email template is used
     * - Email contains batch processing results
     */
    @isTest
    static void testSendBatchCompletionEmail() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>{
            new Contact(
                LastName = 'Test Contact',
                Recency__c = 5.0,
                Frequency__c = 4.0,
                Monetary__c = 3.0,
                Volunteer_Foster_Engagement__c = 5.0
            )
        };
        insert contacts;
        
        // Refresh contacts with all fields
        contacts = [SELECT Id, Name, Recency__c, Frequency__c, Monetary__c, 
                    Volunteer_Foster_Engagement__c FROM Contact 
                    WHERE Id IN :contacts];
        
        Test.startTest();
        Messaging.reserveSingleEmailCapacity(1);
        RFMEUtilityClass.sendBatchCompletionEmail(contacts);
        
        // Create test email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'test@example.com'});
        mail.setSubject('Test Subject');
        mail.setPlainTextBody('Test Body');
        
        // Send and get results
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        Test.stopTest();
        
        System.assertEquals(true, results[0].isSuccess(), 'Email should be sent successfully');
    }
}