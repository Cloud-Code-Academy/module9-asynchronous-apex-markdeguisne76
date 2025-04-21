/*
 * NextStepFuture Class Description:
 * 
 * Question 1: Create a future method that updates all account and opportunities next step to 'Meeting in the future'
 * Question 2: Create a method that inserts a big deal opportunity and updates the user role name to 'CRO'
 * 
 * Benefits of using future methods:
 * 
 * 1. Asynchronous Processing: Allows long-running operations to be handled in the background, freeing up resources.
 * 2. Governor Limit Management: Asynchronous methods have a separate set of limits, providing more flexibility.
 * 3. User Experience Enhancement: Improves responsiveness in user interfaces by offloading processes to the background.
 * 4. Mixed DML Operations Handling: Helps overcome Mixed DML errors by allowing updates on setup and non-setup objects.
 * 5. Enhanced Integration Capabilities: Useful for making callouts to external systems without blocking the user interaction.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_invoking_future_methods.htm
 * 
 * Note: The class below contains placeholders for implementing a future method to update accounts and opportunities.
 *       The accompanying test class 'AsynchronousTest' should also be updated to test this method.
 */
public with sharing class NextStepFuture {

    /*
     * Question 1:
     * Future method to update all Account and Opportunity next steps to 'Meeting in the future'
     */
    @future
    public static void updateAllNextStep() {
        String nextStepValue = 'Meeting in the future';

        // Update Accounts (custom Next_Step__c field)
        List<Account> accountsToUpdate = [
            SELECT Id, Next_Step__c 
            FROM Account
        ];

        for (Account acc : accountsToUpdate) {
            acc.Next_Step__c = nextStepValue;
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }

        // Update Opportunities (standard NextStep field)
        List<Opportunity> oppsToUpdate = [
            SELECT Id, NextStep 
            FROM Opportunity
        ];

        for (Opportunity opp : oppsToUpdate) {
            opp.NextStep = nextStepValue;
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }

    /*
     * Question 2:
     * Inserts a big deal opportunity and schedules a future method to update the user's role to 'CRO'
     */
    public static void createDealAndUpdateRole() {
        Opportunity bigDeal = new Opportunity();
        insertBigDeal(bigDeal);

        // Schedule role update as a future call to avoid Mixed DML error
        updateUserRoleNameAsync();
    }

    // Helper method to insert big deal opportunity
    private static void insertBigDeal(Opportunity opp) {
        opp.Amount = 1000000;
        opp.Name = 'Big Deal';
        opp.StageName = 'Closed Won'; 
        opp.CloseDate = Date.today();

        insert opp;
    }

    // Future method to handle UserRole DML in separate transaction
    @future
    private static void updateUserRoleNameAsync() {
        UserRole[] roles = [
            SELECT Id, Name 
            FROM UserRole 
            WHERE Id = :UserInfo.getUserRoleId() OR Name = 'CRO' 
            LIMIT 1
        ];

        UserRole role;

        if (roles.isEmpty()) {
            role = new UserRole();
            role.portalType = 'None'; 
            role.CaseAccessForAccountOwner = 'Edit'; 
            // Uncomment if needed depending on org defaults:
            // role.OpportunityAccessForAccountOwner = 'Edit';
        } else {
            role = roles[0];
        }

        role.Name = 'CRO';

        upsert role;
    }
}
