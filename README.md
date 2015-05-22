# ssh_notify.sh

Simple configurable script that will send an alert email when a user logs into
an the system. Also prints the system and service status of the server to the
user that is logging in.

Features
--------------------

* Optional __email alert__ when someone logs into the system.
* Define your own recipients for the alert.
* __Ignore__ logins from a list of IP address es.
* Optional welcome message with __system statuses__.
* Define your own services that will be tested on login.
* Color output

Requirements
--------------------

* Linux OS with bash
* Root access
* Installed mail for seding mails

Usage
--------------------

1. Download the script to your /etc/profile.d folder
2. Configure the script to match your needs
2. Login via ssh to test it


Credits
--------------------
Script has been written by the [Intellex](https://intellex.rs/en) team.
