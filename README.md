# Enterprise Service Management - Self Service Monitoring

A set of Perl code to run self service monitoring solutions. Created for Openview Operations (OVO).

## History
Created in 2004 to allow application owners the flexibility of sending alerts using a CLI or logfile as part of an Enterprise Monitoring solution.

### VPOSEND
A commandline interface to send alerts.

### Monitors
#### Diskspace

#### Process

#### Fileage

#### Uptime

#### EMC Powerpath

### Errata
The process to refactor this code started in 2006 and was halted during the financial crisis of 2007-08. I am ressurecting this as a hobby project to learn several programming techniques, such as [Twelve Factor App](https://12factor.net/) methodologies.

Much of what I learned during the refactoring process has evolved into known techniques, such as test driven development.

The next generation solution started development in 2006 as part of a Enterprise Self Service Platform (ESS Agent and ESS Bus). This was based on Java / JBoss. While alpha and beta versions of that solution were code complete, the solution deployment was shelved due to the financial crisis and change in management.
