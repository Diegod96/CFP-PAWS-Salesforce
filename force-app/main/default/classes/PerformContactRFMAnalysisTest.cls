@IsTest
public with sharing class PerformContactRFMAnalysisTest {

    @IsTest
    static void testPerformContactRFMAnalysis(){

        Test.startTest();

        Account account1 = new Account();
        account1.Name = 'John Doe 1 Household';

        Account account2 = new Account();
        account2.Name = 'John Doe 2 Household';

        insert account1;
        insert account2;

        Contact contact1 = new Contact();
        contact1.LastName = 'John'; 
        contact1.FirstName = 'Doe 1';
        contact1.AccountId = account1.Id;
        contact1.Date_Of_Last_Foster_Returned__c = Date.today() - 5;
        contact1.Last_volunteer_date__c = Date.today() - 10;
        System.debug('Contact 1: ' + contact1);

        Contact contact2 = new Contact();
        contact2.LastName = 'John'; 
        contact2.FirstName = 'Doe 2';
        contact2.AccountId = account2.Id;
        System.debug('Contact 2: ' + contact2);

        insert contact1;
        insert contact2;

        Opportunity donation1 = new Opportunity(
            npsp__Primary_Contact__c=contact1.Id, 
            Amount=2000, 
            CloseDate=Date.today() + 1,
            StageName='Closed Won',
            Name='John Doe 1 Donation #1');

        Opportunity donation2 = new Opportunity(
            npsp__Primary_Contact__c=contact1.Id, 
            Amount=2001, 
            CloseDate=Date.today() + 2,
            StageName='Closed Won',
            Name='John Doe 1 Donation #2');

        Opportunity donation3 = new Opportunity(
            npsp__Primary_Contact__c=contact2.Id,
            Amount=2000, 
            CloseDate= Date.today() + 1,
            StageName='Closed Won',
            Name='John Doe 2 Donation #1');

        insert donation1;
        insert donation2;
        insert donation3;

        List<SObject> donationList = new List<SObject>();
        donationList.add(donation1);
        donationList.add(donation2);
        donationList.add(donation3);

        List<List<SObject>> x = new List<List<SObject>>();
        x.add(donationList);

        PerformContactRFMAnalysis.PerformContactRFMAnalysis(x);

        Test.stopTest();  
    }

}