/**
* @author Thomas Wilkins
* @description The Logging class acts as a namespace for all logging related classes
*/ 
public without sharing class Logging  {
	/** Static error message */
	@TestVisible
	private static final String NO_LOGGING_LEVEL = 'Logging level must be provided.';
	/** Error message for not providing a required exception */
	@TestVisible
	private static final String NO_EXCEPTION = 'No Exception instance provided to ErrorLogger.';
	/** Error for when the cron string isn't appropriately set in custom metadata */
	@TestVisible
	private static final String NO_CRON_STRING = 'CRON not set in Persisted Logging Setting.';
	/** Logging setting to be used by the various logging components */
	@TestVisible
	private static Persisted_Logging_Setting__mdt LOGGING_SETTING {
		get {
			if (LOGGING_SETTING == null) {
				LOGGING_SETTING = [
					SELECT Enable_Error_Logging__c, Enable_Performance_Logging__c, Scheduler_CRON_String__c
					FROM Persisted_Logging_Setting__mdt
					WHERE DeveloperName = 'Persisted_Logging_Setting'
					LIMIT 1
				];
			}
			return LOGGING_SETTING;
		} set;
	}

	/**
	* @description base class that all loggers extend
	*/ 
	public abstract class Logger  {
		/** optional value for specifying which class called the logger */
		protected String stackTrace;

		/**
		* @description sets the calling class to be logged as the stack trace
		* @param stackTrace optional stack trace that can be specified
		* @return this
		*/ 
		public Logger setStackTrace(String stackTrace) {
			this.stackTrace = stackTrace;
			return this;
		}

		/**
		* @description abstract method that should execute logging functionality
		*/ 
		public abstract void log();
	
		/**
		* @description generates the stack trace for where the logger is being called
		* @return Either the provided stack trace or one that is auto generated
		*/ 
		protected String getStackTraceString() {
			if (this.stackTrace != null) return this.stackTrace;
			return (new DmlException()).getStackTraceString();
		}
	}

	/**
	* @description Wrapper around the standard System.debug functionality
	*/ 
	public without sharing class DebugLogger extends Logger {
		/** Logging level to be used */
		private System.LoggingLevel logLevel;
		/** Actual messaged to be logged */
		private String debugMessage;
		/**
		* @description 
		* @param logLevel the System.LoggingLevel to be used
		* @param debugMessage the message to be logged
		* @param stackTrace optional stack trace for specifiying where the log is coming from
		*/ 
		@TestVisible
		private DebugLogger(System.LoggingLevel logLevel, String debugMessage) {
			this.logLevel = logLevel;
			if (this.logLevel == null) throw new LoggingException(NO_LOGGING_LEVEL);
			this.debugMessage = debugMessage;
		}

		/**
		* @description See Logger
		*/ 
		public override void log() {
			System.debug(this.logLevel, debugMessage + '\nAt: ' + this.getStackTraceString());
		}
	}

	/**
	* @description abstract class for loggers that persist records in SF
	*/ 
	public abstract class PersistedLogger extends Logger {
		/**
		* @description See Logger
		*/ 
		public override void log() {
			insert this.mapToRecord();
		}

		/**
		* @description Creates the Log__c record that should be inserted
		* @return resulting log to be inserted
		*/ 
		protected abstract Log__c mapToRecord();
	}

	/**
	* @description Class for capturing errors
	*/ 
	public without sharing class ErrorLogger extends PersistedLogger {
		/** Exception to be logged */
		private Exception e;

		/**
		* @description constructo to inject exception
		* @param e the exception to be logged
		*/ 
		@TestVisible
		private ErrorLogger(Exception e) {
			this.e = e;
			if (this.e == null) throw new LoggingException(NO_EXCEPTION);
		}

		/**
		* @description See PersistedLogger
		*/ 
		protected override Log__c mapToRecord() {
			return new Log__c(
				Message__c = this.e.getMessage(),
				Stack_Trace__c = this.e.getStackTraceString()
			);
		}
	}

	/**
	* @description Class for capturing performance metrics
	*/ 
	public class PerformanceLogger extends PersistedLogger {
		private Long rawTime;

		/**
		* @description Constructor that injects a raw time (or overall running time)
		* @param rawTime the overall running time that wants to be captured
		*/
		@TestVisible 
		private PerformanceLogger(Long rawTime) {
			this.rawTime = rawTime;
		}

		/**
		* @description default constructor for no raw time
		*/ 
		@TestVisible
		private PerformanceLogger() {}

		/**
		* @description see PersistedLogger
		*/ 
		protected override Log__c mapToRecord() {
			Map<String, Object> jsonMap = new Map<String, Object> {
				'soqlOps' => System.Limits.getQueries(),
				'soqlRows' => System.Limits.getQueryRows(),
				'dmlOps' => System.Limits.getDmlStatements(),
				'dmlRows' => System.Limits.getDmlRows(),
				'cpu' => System.Limits.getCpuTime(),
				'heap' => System.Limits.getHeapSize(),
				'rawTime' => this.rawTime
			};
			return new Log__c(
				Message__c = JSON.serialize(jsonMap),
				Stack_Trace__c = this.getStackTraceString()
			);
		}
	}

	/**
	* @description base logger factory class that should be extended
	*/ 
	public abstract class LoggerFactory {
		/**
		* @description primary public facing method for generating loggers from factories
		* will return the approriate persisted logger if persisted logging is turned on
		* and the debug logger wrapper otherwise
		* @return Logger
		*/ 
		public Logger getLogger() {
			if (this.isEnabled()) return this.getPersistedLogger();
			return this.getDebugLogger();
		}

		/**
		* @description determines whether or not persisted logging is enabled for the type of
		* logger produced by the factory
		* @return Boolean true if enabled, false otherwise
		*/ 
		protected abstract Boolean isEnabled();

		/**
		* @description Returns the appropriate persisted logger for the logger factory implementation
		* @return PersistedLogger logger to be produced by the factory when persisted logging is turned on
		*/ 
		protected abstract PersistedLogger getPersistedLogger();

		/**
		* @description returns the appropriately configued debug logger
		* This is an abstract method to delegate the logging level to the implementing class
		* @return DebugLogger
		*/ 
		protected abstract DebugLogger getDebugLogger();
	}

	/**
	* @description Factory for producing error loggers
	*/ 
	public class ErrorLoggerFactory extends LoggerFactory {
		/** Exception used for logging */
		private Exception e;

		/**
		* @description Constructor for injecting the required exception
		* @param e the exception to be used for logging
		*/ 
		public ErrorLoggerFactory(Exception e) {
			this.e = e;
		}

		/**
		* @description see LoggerFactory
		*/ 
		protected override Boolean isEnabled() {
			return LOGGING_SETTING.Enable_Error_Logging__c;
		}

		/**
		* @description see LoggerFactory
		*/ 
		protected override PersistedLogger getPersistedLogger() {
			return new ErrorLogger(this.e);
		}

		/**
		* @description See LoggerFactory -- log level set to ERROR
		*/ 
		protected override DebugLogger getDebugLogger() {
			return new DebugLogger(System.LoggingLevel.ERROR, this.e.getMessage());
		}
	}

	/**
	* @description Factory for producing performance loggers
	*/ 
	public class PerformanceLoggerFactory extends LoggerFactory {
		/** 
		* rawTime is just a number that is intended to capture some sort of duration 
		* it is up to the consumer to determine how to provide this value and what it means
		*/
		private Long rawTime;
		public PerformanceLoggerFactory(Long rawTime) {
			this.rawTime = rawTime;
		} 

		/**
		* @description see LoggerFactory
		*/ 
		protected override Boolean isEnabled() {
			return LOGGING_SETTING.Enable_Performance_Logging__c;
		}

		/**
		* @description see LoggerFactory
		*/ 
		protected override PersistedLogger getPersistedLogger() {
			return new PerformanceLogger(this.rawTime);
		}
		
		/**
		* @description See LoggerFactory -- log level set to INFO
		*/ 
		protected override DebugLogger getDebugLogger() {
			return new DebugLogger(System.LoggingLevel.INFO, String.valueOf(this.rawTime));
		}
	}
	/**
	* @description logging exception
	*/ 
	public without sharing class LoggingException extends Exception {}
}
