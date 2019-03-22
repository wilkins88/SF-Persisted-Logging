@IsTest
private class LogCleanupBatch_Tests  {

	@TestSetup
	private static void makeData() {
		insert new List<Log__c> {
			new Log__c(Do_Not_Delete__c = true),
			new Log__c(Do_Not_Delete__c = false)
		};
	}

	@IsTest
	private static void testBatchExecution() {
		// there should be 2 logs to begin with
		System.assertEquals(2, [SELECT Id FROM Log__c].size());
		
		System.Test.startTest();
		Database.executeBatch(new LogCleanupBatch());
		System.Test.stopTest();

		List<Log__c> logsAfter = [SELECT Do_Not_Delete__c FROM Log__c];
		// there should only be one log now
		System.assertEquals(1, logsAfter.size());
		// and it should be the one that was marked to not be deleted
		System.assertEquals(true, logsAfter[0].Do_Not_Delete__c);
	}
}