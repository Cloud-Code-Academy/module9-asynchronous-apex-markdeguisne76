/*
 * NextStepQueueable Class Description:
 * 
 * Implement the Queueable interface to process records asynchronously.
 * This example processes up to 10 accounts at a time.
 * It removes the Next Step from the accounts and related opportunities.
 *  
 * Benefits of using Queueable methods:
 * 
 * 1. Chaining Jobs: Allows for the chaining of jobs, meaning you can add another job to the queue from a running job.
 * 2. Stateful Execution: Supports stateful execution, which allows member variables to retain their values between job invocations.
 * 3. High Concurrency: Processes large sets of data without hitting governor limits.
 * 4. Flexibility: Useful for operations that need more flexibility in execution, especially when there's a possibility of chaining or performing related async operations.
 * 5. Enhanced Integration Capabilities: Useful for making asynchronous callouts to external systems, allowing for more extended processing times.
 * 
 * For more detailed information, refer to the official Salesforce documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_queueing_jobs.htm
 * 
 * Note: The class below contains placeholders for implementing a queueable job to update accounts and opportunities.
 */
public with sharing class NextStepQueueable implements Queueable {

    // Member variable to store the accounts
    private Map<Id, Account> accounts;

    // Constructor to accept the accounts
    public NextStepQueueable(Map<Id, Account> accounts) {
        this.accounts = accounts;
    }

    // Method to enqueue the job
    public static void enqueueJob() {
        // Get up to 10 accounts where Next_Step__c is not null
        List<Account> accountsWithNextStep = [
            SELECT Id, Next_Step__c
            FROM Account
            WHERE Next_Step__c != null
            LIMIT 10
        ];

        if (!accountsWithNextStep.isEmpty()) {
            Map<Id, Account> accountMap = new Map<Id, Account>();
            for (Account acc : accountsWithNextStep) {
                accountMap.put(acc.Id, acc);
            }

            System.enqueueJob(new NextStepQueueable(accountMap));
        }
    }

    // Execute method for Queueable interface
    public void execute(QueueableContext context) {
        if (accounts == null || accounts.isEmpty()) return;

        // Remove Next Step from accounts
        for (Account acc : accounts.values()) {
            removeNextStep(acc);
        }
        update accounts.values();

        // Get Opportunities related to those Accounts
        List<Opportunity> oppsToUpdate = [
            SELECT Id, NextStep, AccountId
            FROM Opportunity
            WHERE AccountId IN :accounts.keySet()
        ];

        for (Opportunity opp : oppsToUpdate) {
            removeNextStep(opp);
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }

        // Chain the next batch if more exist
        enqueueJob();
    }

    // Helper method to remove the Next Step from Opportunity
    private static void removeNextStep(Opportunity opp) {
        opp.NextStep = null;
    }

    // Helper method to remove the Next Step from Account
    private static void removeNextStep(Account acc) {
        acc.Next_Step__c = null;
    }
}
