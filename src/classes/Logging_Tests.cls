@IsTest
private class Logging_Tests  {
	/**********************************************************************************************************
	/ DEBUG LOGGER TESTS
	**********************************************************************************************************/
	@IsTest
	private static void debugWithStackTrace() {
		Logging.DebugLogger log = new Logging.DebugLogger(System.LoggingLevel.ERROR, 'This is an error message');
		System.Test.startTest();
		log.log();
		System.Test.stopTest();
		// Nothing to assert -- it is just confirming that it successfully wrote to the console
	}
	
	@IsTest
	private static void debugWithoutStackTrace() {
		Logging.DebugLogger log = new Logging.DebugLogger(System.LoggingLevel.INFO, 'This is an info message');
		System.Test.startTest();
		log.log();
		System.Test.stopTest();
		// Nothing to assert -- it is just confirming that it successfully wrote to the console
	}
	
	@IsTest
	private static void debugNoLoggingLevelThrowsException() {
		String errMsg;
		System.Test.startTest();
		try {
			Logging.DebugLogger log = new Logging.DebugLogger(null, 'This should fail');
		} catch (Logging.LoggingException e) {
			errMsg = e.getMessage();
		} 
		System.Test.stopTest();
		System.assert(errMsg.contains(Logging.NO_LOGGING_LEVEL));
	}

	/**********************************************************************************************************
	/ ERROR LOGGER TESTS
	**********************************************************************************************************/
	private static final String TEST_MESSAGE = 'Kinda hot in these rhinos';
	@IsTest
	private static void logError() {
		// No logs have been created, we would expect one after thes test
		System.assertEquals(0, [SELECT Id FROM Log__c].size());
		DmlException e = new DmlException(TEST_MESSAGE);
		Logging.ErrorLogger errLogger = new Logging.ErrorLogger(e);
		System.Test.startTest();
		errLogger.log();
		System.Test.stopTest();
		// we should now have a log in the system
		List<Log__c> insertedLog = [SELECT Message__c, Stack_Trace__c FROM Log__c];
		// verify we have the one log
		System.assertEquals(1, insertedLog.size());
		// verify the correct fields were set from the exception
		System.assert(insertedLog[0].Message__c.contains(TEST_MESSAGE));
		System.assertEquals(e.getStackTraceString(), insertedLog[0].Stack_Trace__c);
	}

	@IsTest
	private static void logErrorNoErrorThrowsException() {
		// No logs have been created, we would expect one after thes test
		System.assertEquals(0, [SELECT Id FROM Log__c].size());
		String errMsg;
		System.Test.startTest();
		try {
			Logging.ErrorLogger log = new Logging.ErrorLogger(null);
		} catch (Logging.LoggingException e) {
			errMsg = e.getMessage();
		} 
		System.Test.stopTest();
		System.assert(errMsg.contains(Logging.NO_EXCEPTION));
		// should still have no logs
		System.assertEquals(0, [SELECT Id FROM Log__c].size());
	}
	
	/**********************************************************************************************************
	/ PERFORMANCE LOGGER TESTS
	**********************************************************************************************************/
	@IsTest
	private static void logPerformance() {
		// No logs have been created, we would expect one after the test
		System.assertEquals(0, [SELECT Id FROM Log__c].size());
		Long rawTime = Datetime.now().getTime();
		Logging.PerformanceLogger log = new Logging.PerformanceLogger(rawTime);
		System.Test.startTest();
		log.log();
		System.Test.stopTest();
		// we should now have a log in the system
		List<Log__c> insertedLog = [SELECT Message__c, Stack_Trace__c FROM Log__c];
		// verify we have the one log
		System.assertEquals(1, insertedLog.size());
		System.assert(insertedLog[0].Message__c.contains(String.valueOf(rawTime)));
	}
	/**********************************************************************************************************
	/ ERROR LOGGER FACTORY TESTS
	**********************************************************************************************************/
	@IsTest
	private static void logFactoryError() {
		Logging.ErrorLoggerFactory loggerFactory = new Logging.ErrorLoggerFactory(new DMLException('Test Error'));
		Logging.Logger logger;
		System.Test.startTest();
		logger = loggerFactory.getLogger();
		System.Test.stopTest();
		System.assert(logger instanceof Logging.ErrorLogger || logger instanceof Logging.DebugLogger);
	}
	/**********************************************************************************************************
	/ PERFORMANCE LOGGER FACTORY TESTS
	**********************************************************************************************************/
	@IsTest
	private static void logFactoryPerformance() {
		Logging.PerformanceLoggerFactory loggerFactory = new Logging.PerformanceLoggerFactory(Datetime.now().getTime());
		Logging.Logger logger;
		System.Test.startTest();
		logger = loggerFactory.getLogger();
		System.Test.stopTest();
		System.assert(logger instanceof Logging.PerformanceLogger || logger instanceof Logging.DebugLogger);
	}
}