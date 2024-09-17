public class ParseJSONBatchApexInvoker {

    // Invocable method to run Batch Apex
    @InvocableMethod(label='Invoke Batch for JSON Parsing' description='Starts the Batch Apex for JSON parsing')
    public static void startBatchApex(List<String> jsonList) {
        // Assuming jsonList contains the JSON string(s) to process
        String jsonString = jsonList[0];

        // Initialize and run the Batch Apex job
        ParseJSONBatch batch = new ParseJSONBatch(jsonString);
        Database.executeBatch(batch, 100); // Adjust batch size if necessary
    }
}