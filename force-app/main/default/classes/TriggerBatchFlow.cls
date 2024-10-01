public with sharing class TriggerBatchFlow {
    
    public class BatchRequest {
        @InvocableVariable
        public String jsonString;
    }
    
    @InvocableMethod(label='Trigger Batch to Parse and Update Contacts')
    public static void invokeBatch(List<BatchRequest> batchRequests) {
        System.debug('Number of Batch Requests -> ' + batchRequests.size());
        
        // Count the number of currently active or queued batch jobs
        Integer currentBatchJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND (Status = 'Processing' OR Status = 'Queued')];
        Integer maxBatchJobs = 5; // Salesforce allows a maximum of 5 active or queued batch jobs
        
        List<BatchRequest> remainingRequests = new List<BatchRequest>();
        
        for (BatchRequest request : batchRequests) {
            if (currentBatchJobs < maxBatchJobs) {
                // Start the batch job, passing the JSON string
                ParseJSONBatch batchJob = new ParseJSONBatch(request.jsonString);
                Database.executeBatch(batchJob, 300); // Adjust batch size as needed
                currentBatchJobs++;
            } else {
                // Queue remaining requests if batch limit is reached
                remainingRequests.add(request);
            }
        }
        
        if (!remainingRequests.isEmpty()) {
            // If remaining requests exist, queue them using Queueable
            System.debug('Batch job limit reached, queuing remaining requests');
            System.enqueueJob(new BatchQueueable(remainingRequests));
        }
    }
    
    public class BatchQueueable implements Queueable {
        private List<BatchRequest> batchRequests;
        
        public BatchQueueable(List<BatchRequest> requests) {
            this.batchRequests = requests;
        }
        
        public void execute(QueueableContext context) {
            System.debug('Processing remaining batch requests');
            
            // Limit the number of concurrent batch jobs
            Integer currentBatchJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND (Status = 'Processing' OR Status = 'Queued')];
            Integer maxBatchJobs = 5;
            
            // Split requests into a list of jobs to avoid deep recursion
            List<BatchRequest> remainingRequests = new List<BatchRequest>();
            
            for (BatchRequest request : batchRequests) {
                if (currentBatchJobs < maxBatchJobs) {
                    // Start the batch job
                    ParseJSONBatch batchJob = new ParseJSONBatch(request.jsonString);
                    Database.executeBatch(batchJob, 300); // Adjust batch size as needed
                    currentBatchJobs++;
                } else {
                    // Collect remaining requests
                    remainingRequests.add(request);
                }
            }
            
            // Avoid enqueuing if no remaining requests
            if (!remainingRequests.isEmpty() && remainingRequests.size() > 0) {
                // Check to prevent continuous enqueuing
                if (remainingRequests.size() < 100) { // Limit the size to prevent excessive depth
                    System.enqueueJob(new BatchQueueable(remainingRequests));
                }
            }
        }
    }
    
    
}