# SF-Persisted-Logging

Classes and configuration components for persisted logging on the salesforce platform.

Salesforce already provides mechanisms for gathering robust, detailed logs. However, those logs do have limitations:

- Limited amount can be stored, which causes problems for orgs with high volumes of traffic
- It can be difficult to do 24/7 logging, since that typically involves setting trace flags on a per user basis
- Visibility of performance and error specific logic can be lost in a detailed, large debug log file

This library provides a mechanism for working around some of the above concerns by affording the storage of pertinent details in a Log sObject in Salesforce. However, one key consideration for using this library is the volume of logging records that can be accumulated. To address those potential problems, a simple batch has also been provided and can be scheduled to run at your discretion. Additionaly, logs can be persisted even through the cleanup batch if the Do_Not_Delete__c flag is set.

# API 

Most of the functionality is encapsulated and cannot be accessed outside of the Logging class. The 2 public class which are available for use
are the ErrorLoggerFactory and the PerformanceLoggerFactory.

## Creating an error log

```
try {
    // code that throws some exception;
    ...
} catch (SomeException e) {
    Logging.ErrorLoggerFactory.getLogger(e).log();
}
```

## Creating a performance log

```
long startTime = Datetime.now().getTime();
// code that does some stuff
...
// end of the code you want to gather performance data on
Logging.PerformanceLoggerFactory.getLogger(Datetime.now().getTime() - startTime).log();
```

## Configuring Logging

There are two configuration activities involved with this library: Activating logging and scheduling the batch.

Activating logging is done through custom metadata. Navigate to Setup -> Custom Metadata -> Persisted Logging Setting -> Manage Records -> Persisted Logging Setting. Within that record, you will see two checkboxes: one for controlling performance logging and one for controlling error logging. Note that when either logging mechanism is turned off, the logging libraries will still operate -- they just will only output the logging contents to the debug logs.

The second activity is scheduling the batch. This is done by navigating to Apex Classes -> Schedule Apex.

## Information about log records

Message__c: For error loggers, this is the error message. For performance, this value holds the stringified JSON of several performance and operational metrics.

Stack_Trace__c: For error loggers, this is set to the stack trace provided by the error. For performance loggers, this can either be a string provided to the Performance Logger, or it will be a stack trace generated from roughly where the call is made. The latter has been identified as an area of improvement.
