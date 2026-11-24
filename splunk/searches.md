# Splunk searches: Gulfside Failed Logins dashboard

Data input: Settings > Data inputs > Local event log collection > Security (default index).
Run each search over "All time", or a range that covers the events you want.

## All failed-login related events

```
source="WinEventLog:Security" (EventCode=4625 OR EventCode=4740 OR EventCode=4776)
```

## Panel 1: Failed sign-ins over time (column chart)

```
source="WinEventLog:Security" (EventCode=4625 OR EventCode=4740 OR (EventCode=4776 Keywords="Audit Failure")) | timechart span=1h count by EventCode
```

Event 4776 is logged for successful checks too, so it is limited to audit failures.

## Panel 2: Failed sign-ins by account (bar chart)

```
source="WinEventLog:Security" EventCode=4625 | eval user=mvindex(Account_Name,-1) | stats count by user | sort -count
```

Event 4625 carries two account names: the subject and the account that failed. `mvindex(Account_Name,-1)` takes the last one, which is the account that failed.

## Panel 3: Account lockouts, Event 4740 (table)

```
source="WinEventLog:Security" EventCode=4740 | eval locked_account=mvindex(Account_Name,-1) | table _time locked_account Caller_Computer_Name
```
