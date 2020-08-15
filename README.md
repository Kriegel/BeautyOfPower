# BeautyOfPower (BoP)

**PowerShell Module to format PowerShell script text (sourcecode) to beautify PowerShell sourcecode and to do refactoring on PowerShell sourcecode**


The Functions out of this Module will change (refactor) PowerShell sourcecode.
The Authors of this Module have done great care to do no harm or damage to the processed sourcecode and its execution behavior or results.

Best is to run the this Module in a Sandbox or an Sandbox like Virtual Machine to process, refactor or tidy PowerShell sourcecode.

TO REVIEW THE CHANGES MADE TO THE SOURCECODE, BEFORE EXECUTING IT, IS ON YOUR OWN RESPONSIBILITY.

for Disclaimer of liability see License.

**Alternativly** to this Module use the Module **PSScriptAnalyzer** and his Cmdlet **Invoke-Formatter**
<https://github.com/PowerShell/PSScriptAnalyzer>
<sub>(The reason I devlop my own Module here is that PSScriptAnalyzer is written in C# so I can not contribute there and Invoke-Fomatter seems to be an [unloved Kid](https://github.com/PowerShell/PSScriptAnalyzer/issues/775) and shows no development Progress. :-(  )</sub>

## Usage

```powershell

# import Module (from Path)
Import-Module 'BeautyOfPower'

# path to file which holds the sourcecode and is to be prettified
$FileToBeParsed = 'C:\PsCode\TestFile.ps1'

# define path for the resulting out file
$OutFilePath = "$env:Temp\Out-Tesfile.ps1"
# remove out file (if exist before)
$Null = Remove-Item $OutFilePath -confirm:$False -ErrorAction 'ignore'
# create an new empty out file
$Null = New-Item $OutFilePath -ItemType File -Force


# Let the sourcecode parsed by the PowerShell parser and Tokenize it
# parse File C:\PsCode\TestFile.ps1
# IT IS STRONGLY NOT RECOMENDED TO USE -IncludeNestedToken IN REFACTORING,
# THIS WILL DAMAGE THE CODE!
Get-BopTokenAndAst -Path $FileToBeParsed |
# Convert .NET Tokens to custom, writeable Bop-Tokens
ConvertTo-BopToken |
#
# Chain the Formating functions to process the tokens
#
# Functions which correct the casing of the Tokens
#
Format-BopCasingTypeName |
Format-BopCasingAttributeName |
Format-BopCasingKeyword -ToLower |
Format-BopCasingCommandName |
Format-BopCasingParameter |
Format-BopCasingTypeMemberName |
Format-BopCasingKnownVariables -MSDefault -IncludeUnknownVars |
Format-BopCasingScopeModifier |
Format-BopCasingOperator -MixedCase |
#
# Function to define the place of the opening brace (LCurly) (here on their own line)
#
Format-BopLCurly -LCurlyOnNewLine |
#
# Function to expand Command-Alias
#
Format-BopExpandCommandAlias -CaseSensitiv -IncludeAll |
#
# Functions to process Command ParameterNames
#
# Command Parameter casing
Format-BopCasingParameter | # this calls : Format-BopParameter -Format 'Casing'
# Shortened Command Parameter expanding
Format-BopExpandParameterShort | # this calls : Format-BopParameter -Format 'ExpandShort'
# Convert Command Parameter-Alias to real Parameter Name
Format-BopExpandParameterAlias  | # this calls : Format-BopParameter -Format 'ExpandAlias'
# For faster processing alternativly to the single functions, you can use :
# Format-BopParameter -Format 'All'
#
# Add ParameterName to Positional Parameter
# (convert Positional Parameters to Named Parameters)
# THIS FUNCTION IS EXPERIMENTAL! USE -Force TO USE IT REGARDLESS
Format-BopAddParameterName -Force|
#
ForEach-Object {

    # Writing the processed Tokens one after the other to the output file and add spaces between the Tokens
    # Write the Surrogate to the file!
    Add-Content -Path $OutFilePath -Value ((' ' * $Token.PrefixSpaces)  + $Token.Surrogate) -NoNewline
}

# show the out file
Notepad.exe $OutFilePath

```

## Description

I am developing this Module to prettify PowerShell sourcecode, downloaded from the Internet.
I am a german resident, we germans have imbibe word casing from first day of writing.
Many coders in the world, do not care about correct casing, this has itched me so much,
that i have started to develop this Module. (even though I am very bad in grammar)

So the first bunch of Formating functions of this Module are processing PowerShell sourcecode for casing.

### Roadmap

- Largely Done! :-) replace aliases with the names who points the alias to (command alias and ParameterName alias or shorts)

- a bunch of functions to place braces (and space between them).

- write some functions to ident the code and to correct other whitespace.

## Main Functions of this Module

### Get-BopTokenAndAst

Utilizes the PowerShell "advanced" parser to Parse PowerShell sourcecode from File (*.ps1, *.psm1, *.psd1) or Scriptblock or a String Variable.
Returns the Tokens, the AST, syntax Errors and additionally Informations as a custom Object.
(Big credits for this function goes to Tobias Weltner)

### ConvertTo-BopToken

This Function creates an flat clone from 'System.Management.Automation.Language.Token' Token Types.
With additional fields useful for refactoring and to prettify.

Microsoft allows not to Instantiate custom .NET Tokens and
most of the Properties (Fields) of the .NET Token Class members are not edit able.
For simple access of deep nested members, economize memory consumption and for speed reasons this function creates custom Token Object with writeable (set able) fields.

The custom Token Object produced by this function are consumed by the formatting functions.

### Formatting Functions

#### Casing

- Format-BopCasingTypeName

- Format-BopCasingAttributeName

- Format-BopCasingKeyword (uses PascalCase by default!)

- Format-BopCasingCommandName

- Format-BopCasingParameter

- Format-BopCasingTypeMemberName

- Format-BopCasingKnownVariables (uses PascalCase by default!)

- Format-BopCasingParameter ; alternativly use : Format-BopParameter -Format 'Casing'

- Format-BopCasingScopeModifier

- Format-BopCasingOperator

Watchout for additional Parameters a Function servers.
This can be used to change casing behavior

See also: Capitalization guidelines
<https://github.com/PoshCode/PowerShellPracticeAndStyle/issues/36>

#### Brace placement

- Format-BopLCurly (Kernighan & Ritchie Style and Allman style)

#### Adding content (that was not there before)

- Format-BopAddParameterName

#### Expanding Alias and shortnames

- Format-BopExpandCommandAlias

- Format-BopExpandParameterShort
  (alternativly use : Format-BopParameter -Format 'ExpandShort')

- Format-BopExpandParameterAlias
  (alternativly use : Format-BopParameter -Format 'ExpandAlias')

#### All in one Functions

- Format-BopParameter -Format 'All'
  (replacement for: Format-BopCasingParameter + Format-BopExpandParameterShort + Format-BopExpandParameterAlias)

## Insights

In this Module the Tokens parsed from PowerShell sourcecode are the first class citizen.
The Tokens are handled as a Stream (of Tokens)

For more insights, read the sourcecode of the Module and functions and see documents in folder Doc!

## Informations about Formating PowerShell Code

Windows PowerShell Language Specification Version 3.0
(download as Word document .docx Year 2012)
<https://www.microsoft.com/en-us/download/details.aspx?id=36389>

Powershell Practice and Style recomendations
<https://poshcode.gitbooks.io/powershell-practice-and-style/>

Also useful for general PowerShell code:
DSC Resource Style Guidelines & Best Practices
<https://github.com/PowerShell/DscResources/blob/master/StyleGuidelines.md>

Known Issues for PowerShell 6.0
Case-sensitivity in PowerShell etc. ...
<https://docs.microsoft.com/en-us/powershell/scripting/whats-new/known-issues-ps6>

## Credits

Credits goes to:

Tobias Welter

<https://github.com/TobiasPSP/Modules.PSOneTools>

<https://powershell.one/powershell-internals/parsing-and-tokenization/advanced-tokenizer>

<https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree>

Dan Ward

https://github.com/DTW-DanWard/PowerShell-Beautifier
