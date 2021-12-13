#############################################################
#
# Script: Create-AddressObjects.PS1
# Description: This Script will Read a CSV file Included In
# In the folder with the script. Currently Hard Coded to
# ".\IPAddresses.csv". you will also be prompted to provide a
# Name and Comment info for any group that you want to create
# for these new adddress objects.
#
#
#
#
#############################################################
#Make Script location the current folder
Split-Path -parent $MyInvocation.MyCommand.Definition | Set-Location
 
function Answer-YesNo {
#Function Returns Boolean output from a yes/no question
#
# Usage: Answer-YesNo "Question Text" "Title Text"
#
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",""
$choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes,$no)
$caption = "Warning!" #Default Caption
if ($args[1] -ne $null){
$caption = $args[1]} # Caption Passed as argument
$message = "Do you want to proceed" #Default Message
if ($args[0] -ne $null){
$message = $args[0]} #Message passed as argument
$result = $Host.UI.PromptForChoice($caption,$message,$choices,0)
if($result -eq 0) {return $true}
if($result -eq 1) {return $false}
}
clear
Write-Host -ForegroundColor Green "
#############################################################################
#
#############################################################################
#
# FORTIGATE 5.X / 6.x / 7.x IP ADDRESS OBJECT BULK IMPORT SCRIPT GENERATOR
# Ver. 1.3 / December 13 2021
# Author: Dan Parr /dparr@granite-it.net
# 
# Modified by Usman Hussain
#
# This Script is provided without warranty of any kind.
# Use at your own discretion.
#
#############################################################################
 
"
 
$VDOMName= ""
$ScriptStart = ""
$UseVDOMs = Answer-YesNo "Does The Fortigate Configured with VDOMs?" "VDOM Configuration"
If ($UseVDOMs -eq $True){
#VDOM Names are Case Sensitive Using the wrong Case could create a new vdom in the CLI
$VDOMName = Read-Host "Please Enter VDOM Name (!!Case Sensitive!!):"
$ScriptStart = "
config vdom
edit $VDOMName"}
$MakeGroup = Answer-YesNo "Will you be creating a group for the imported Objects?" "Please Provide a Y or N Answer:"
$AddressObjects = Import-Csv .\IPAddresses.csv
$Script = "
$ScriptStart
config firewall address
"
$MemberList = ""
If ($MakeGroup -eq $true){
$GroupName = Read-Host -Prompt "
Please Enter the Name of the Object Group You Wish to Create
(NOTE:Avoid Using Spaces)"
$GroupComment = Read-Host -Prompt "
Enter A Comment Describing this Group
(ex. `"Webserver: dparr/Aug 4, 2016`")"
$GroupScript = "
$ScriptStart
config firewall addrgrp
edit `"$GroupName`"
set member"
}
$AddressObjects | foreach {
$Addr = $_.Address
$Name = $_.Name.substring(0,1).toupper()+$_.Name.substring(1).tolower()
$Mask = $_.Mask
$Comment = $_.Comment
 
$Script += "
edit `"$Name`"
set subnet $Addr $Mask
set comment `"$Comment`"
next"
if ($MakeGroup -eq $true){
$MemberList += " `"$Name`""}
}
$Script += "
end"
if ($MakeGroup -eq $true){
$GroupScript += "$MemberList
set comment `"$GroupComment`"
next
end"
}
Write-Host $Script
$Script > .\IPAddresses.txt
$GroupScript >> .\IPAddresses.txt
Clear
 
If ((Answer-YesNo "The CLI Script Has been Written to .\IPAddresses.txt Would you like to open this file in notepad now?" "Open CLI Script File?") -eq $true){
 
Notepad .\IPAddresses.txt
}