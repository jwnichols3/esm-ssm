# Enterprise Service Management - Self Service Monitoring

A set of Perl code to run self service monitoring solutions. Created for Openview Operations (OVO).

## History
Created in 2004 to allow application owners the flexibility of sending alerts using a CLI or logfile as part of an Enterprise Monitoring solution.

### VPOSEND
A commandline interface to send alerts.

### Self Service Logfile
Any monitored logfile can append key pairs after a delimiter (__VPO__) to send alerts to app owners. 
```
00-00-0000 MM:HH Anything goes here __VPO__ app=app_name sev=Major message=what you want the alert to say
```

### Monitors
#### Diskspace
Use a configuration file to identify the thresholds and severities for the file systems you're interested in watching.

```
app=app_name fs=/ severity=major threshold=98 message=custom message about the disk space

```

#### Process
Use a configuration file to identify process (or windows service) you're interested in watching.

```
app=app_name process=process severity=major message=custom message about the process
```

#### Fileage
Use a configuration file to check the age of files you're interested in watching.

```
app=app_name file=/app/log/log.txt severity=major age=120 message=custom message about the age of the file
```

### Errata
The process to refactor this code started in 2006 and was halted during the financial crisis of 2007-08. I am ressurecting this as a hobby project to learn several programming techniques, such as [Twelve Factor App](https://12factor.net/) methodologies.

Much of what I learned during the refactoring process has evolved into known techniques, such as test driven development.

The next generation solution started development in 2006 as part of a Enterprise Self Service Platform (ESS Agent and ESS Bus). This was based on Java / JBoss. While alpha and beta versions of that solution were code complete, the solution deployment was shelved due to the financial crisis and change in management.
