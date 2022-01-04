#############################################################
#
# Script: Create-AddressObjects.PS1
# Description: This Script will Read a CSV file Included In
# In the folder with the script. Currently Hard Coded to
# ".\Hostnames.csv". you will also be prompted to provide a
# Name and Comment info for any group that you want to create
# for these new adddress objects.
#
#
#
#
#############################################################

# Make Script location the current folder
Split-Path -Path $MyInvocation.MyCommand.Definition -Parent | Set-Location
 
function Answer-YesNo {
  <#
    .DESCRIPTION
    Function Returns Boolean output from a yes/no question

    .EXAMPLE
    Answer-YesNo "Question Text" "Title Text"
  #>
  [OutputType('System.Boolean')]
  Param (
      [Parameter(Position = 0)]
      [string]$Question = 'Do you want to proceed',
      [Parameter(Position = 1)]
      [string]$Title = 'Warning!'
  )

  $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes",""
  $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No",""
  $choices = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

  $result = $Host.UI.PromptForChoice($Title, $Question, $choices, 0)

  if ($result -eq 0) {return $true}
  if ($result -eq 1) {return $false}
}

Clear-Host

Write-Host -ForegroundColor Green @'
#############################################################################
#
# FORTIGATE 5.X / 6.x / 7.x FQDN OBJECT BULK IMPORT SCRIPT GENERATOR
#
# Ver. 1.3 / December 13 2021
# Author: Dan Parr /dparr@granite-it.net
# 
# Modified by Usman Hussain
#
# This Script is provided without warranty of any kind.
# Use at your own discretion.
#
#############################################################################
 
'@

# Defining partial script templates
$vdom_template = @"
# VDOM SELECTION
config vdom
edit "{0}"


"@

$address_template = @'
# ADDRESS CREATION
config firewall adress
{0}
end
'@

$group_template = @'


# GROUP CREATION
config firewall addrgrp
  edit "{0}"
    set member {1}
    set comment "{2}"
  next
end
'@

# Importing addresses from the csv file
[array]$AddressObjects = Import-Csv .\Hostnames.csv
if ($AddressObjects.Count -eq 0) {
  throw "The Hostnames.csv file contains no addresses to create"
}

# Add a property called 'TitleCaseName' to all address objects with the properly formatted name
$AddressObjects = $AddressObjects | Select-Object Name, Hostname, Comment, @{'Name' = 'TitleCaseName'; 'Expression' = { [CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($_.Name) }}

# User questions
$UseVDOMs = Answer-YesNo "Does The Fortigate Configured with VDOMs?" "VDOM Configuration"
if ($UseVDOMs -eq $True) {
  # VDOM Names are Case Sensitive Using the wrong Case could create a new vdom in the CLI
  $VDOMName = Read-Host "Please Enter VDOM Name (!!Case Sensitive!!):"
}

$MakeGroup = Answer-YesNo "Will you be creating a group for the imported Objects?" "Please Provide a Y or N Answer:"

If ($MakeGroup -eq $true) {
  $GroupName = Read-Host -Prompt '
  Please Enter the Name of the Object Group You Wish to Create
  (NOTE:Avoid Using Spaces)'
  $GroupComment = Read-Host -Prompt '
  Enter A Comment Describing this Group
  (ex. "Webserver: dparr/Aug 4, 2016")'
}

# Prepare the cli commands for creating each address object
$addresses_cli = $AddressObjects | ForEach-Object {
@"
  edit "$($_.TitleCaseName)"
    set type fqdn
    set fqdn "$($_.Hostname)"
    set comment "$($_.Comment)"
  next
"@
}

# Assemble the final script from the previously defined partial templates
$Script = ""
if ($UseVDOMs) {
  $Script += $vdom_template -f $VDOMName
}

$Script += $address_template -f ($addresses_cli -join [System.Environment]::NewLine)

if ($MakeGroup) {
  $GroupMembersQuoted = $AddressObjects.TitleCaseName | ForEach-Object { '"{0}"' -f $_ }
  $Script += $group_template -f $GroupName, ($GroupMembersQuoted -join ','), $GroupComment
}

Write-Host "***** Script Preview *****"
Write-Host $Script
Write-Host "**************************"

Set-Content -LiteralPath .\Hostnames.txt -Value $Script

If ((Answer-YesNo "The CLI Script Has been Written to .\Hostnames.txt Would you like to open this file in notepad now?" "Open CLI Script File?") -eq $true) {
  Notepad .\Hostnames.txt
}
