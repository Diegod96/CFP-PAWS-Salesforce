public with sharing class TriggerBatchFlow {
    
    public class BatchRequest {
        @InvocableVariable
        public String jsonString;
    }
    

    // Invocable apex method to kick off the batch processing of contacts from the PAWS Pipeline platform message
    // A platform message from the PAWS Pipeline consits of an array of Contact objects with updated field values
    // We are batching out processings platform messages from the PAWS Pipeline to preserve system resources
    @InvocableMethod(label='Trigger Batch to Parse and Update Contacts')
    public static void invokeBatch(List<BatchRequest> batchRequests) {
        System.debug('Number of Batch Requests -> ' + batchRequests.size());
        
        // Count the number of currently active or queued batch jobs
        // Capped out at 5 batch jobs running at once
        Integer currentBatchJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND (Status = 'Processing' OR Status = 'Queued')];
        Integer maxBatchJobs = 5;
        
        List<BatchRequest> remainingRequests = new List<BatchRequest>();
        
        // Process the batch requests in batches, starting a new batch job for each request
        // If the batch limit is reached, queue the remaining requests for later processing
        for (BatchRequest request : batchRequests) {
            if (currentBatchJobs < maxBatchJobs) {
                ParseJSONBatch batchJob = new ParseJSONBatch(request.jsonString);
                Database.executeBatch(batchJob, 300); // Adjust batch size as needed
                currentBatchJobs++;
            } else {
                remainingRequests.add(request);
            }
        }
        
        // Queue the remaining requests
        if (!remainingRequests.isEmpty()) {
            System.debug('Batch job limit reached, queuing remaining requests');
            System.enqueueJob(new BatchQueueable(remainingRequests));
        }
    }
    
    // Inner class to handle remaining batch requests
    public class BatchQueueable implements Queueable {
        private List<BatchRequest> batchRequests;
        
        public BatchQueueable(List<BatchRequest> requests) {
            this.batchRequests = requests;
        }
        
        public void execute(QueueableContext context) {
            System.debug('Processing remaining batch requests');
            
            // Count the number of currently active or queued batch jobs
            // Capped out at 5 batch jobs running at once
            Integer currentBatchJobs = [SELECT COUNT() FROM AsyncApexJob WHERE JobType = 'BatchApex' AND (Status = 'Processing' OR Status = 'Queued')];
            Integer maxBatchJobs = 5;
            
            // Split requests into a list of jobs to avoid deep recursion
            List<BatchRequest> remainingRequests = new List<BatchRequest>();
            
            // Process the batch requests in batches, starting a new batch job for each request
            // If the batch limit is reached, queue the remaining requests for later processing
            for (BatchRequest request : batchRequests) {
                if (currentBatchJobs < maxBatchJobs) {
                    ParseJSONBatch batchJob = new ParseJSONBatch(request.jsonString);
                    Database.executeBatch(batchJob, 300); // Adjust batch size as needed
                    currentBatchJobs++;
                } else {
                    remainingRequests.add(request);
                }
            }
            
            // Avoid enqueuing if no remaining requests
            // Check to prevent continuous enqueuing
            // Limit the size to prevent excessive depth
            if (!remainingRequests.isEmpty() && remainingRequests.size() > 0) {
                if (remainingRequests.size() < 100) { 
                    System.enqueueJob(new BatchQueueable(remainingRequests));
                }
            }
        }
    }
    
    
}