/**
 * @description       : 
 * @author            : Diego Delgado
 * @group             : 
 * @last modified on  : 10-14-2024
 * @last modified by  : Diego Delgado
**/
global class WeeklyRFMEAnalysisScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        RFMEAnalysisBatch batch = new RFMEAnalysisBatch();
        Database.executeBatch(batch);
    }
}