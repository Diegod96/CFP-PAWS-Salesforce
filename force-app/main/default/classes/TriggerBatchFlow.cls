/**
 * Created by diegodelgado on 9/23/24.
 */

public with sharing class TriggerBatchFlow {

    /**
     *
     */
    public class BatchRequest {
        @InvocableVariable
        public String jsonString;
    }

    /**
     * @param batchRequests
     */
    @InvocableMethod(label='Trigger Batch to Parse and Update Contacts')
    public static void invokeBatch(List<BatchRequest> batchRequests) {
        System.debug('Number of Batch Requests -> ' + batchRequests.size());
        for (BatchRequest request : batchRequests) {
            // Start the batch job, passing the JSON string
            ParseJSONBatch batchJob = new ParseJSONBatch(request.jsonString);
            Database.executeBatch(batchJob, 300); // Adjust batch size as needed
        }
    }
}