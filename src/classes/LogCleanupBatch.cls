/**
* @author Thomas Wilkins
* @description Cleanup batch that can be scheduled or called directly
* Clears all logs that aren't marked to be retained
*/ 
public class LogCleanupBatch implements Database.Batchable<SObject>, Schedulable {
	public Database.QueryLocator start(Database.BatchableContext BC) {
		return  Database.getQueryLocator('SELECT Id FROM Log__c WHERE Do_Not_Delete__c = false');
	}

	public void execute(Database.BatchableContext bc, List<Log__c> scope) {
		delete scope;
	}

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new LogCleanupBatch());
	}

	public void finish(Database.BatchableContext bc) {}
}