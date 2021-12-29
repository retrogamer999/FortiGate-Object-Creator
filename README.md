# FortiGate-Object-Creator
Create FQDN and IP Address Objects Script

All credit goes to Dan Parr whom originally created the script. Link to his WordPress is below

https://granitedansblog.wordpress.com/author/renegadeit/

Thanks Dan.


## IP Address CSV layout

Name - Give the object a unique name

Address - The actual IP address

Subnet - This needs to be the full network mask e.g. 255.255.255.0 for a /24 subnet

Comment - Free text, put in what you want!



## FQDN CSV Layout

Name - Give the object a unique name

Hostname - the FQDN of the object you want to create e.g. www.google.com

Comment - Free text, put in what you want!


## How to use this

Populate the CSV files using Excel or equivalent and save changes. Run the PowerShell script for the objects you want to create, follow the wizard and the script will spit out the config to create the objects.

Copy and paste the script into the cli and the objects will be created.

## Notes:

When creating onjects ensure that there is no trailing space (" ") at the end or the FortiGate CLI will kick up an error and the object will not be imported.
