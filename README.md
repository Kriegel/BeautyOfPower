# BeautyOfPower
PowerShell Module to beautify sourcecode and to do refactoring on PowerShell Code

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
Get-BopTokenAndAst -Path $FileToBeParsed -IncludeNestedToken |
# Convert .NET Tokens to custom, writeable Bop-Tokens
ConvertTo-BopToken |
# Chain the Formating functions to process the tokens
#
# Function which correct the casing of the Tokens
Format-BopCasingTypeName |
Format-BopCasingAttributeName |
Format-BopCasingKeyword |
Format-BopCasingCommandName |
Format-BopCasingParameter |
Format-BopCasingTypeMemberName |
# Function to define the place of the opening brace (LCurly) (here on their own line)
Format-BopLCurly -LCurlyOnNewLine |
ForEach-Object {

    # Writing the processed Tokens one after the other to the output file and add spaces between the Tokens
    # Write the Surrogate to the file!
    Add-Content -Path $OutFilePath -Value ((' ' * $Token.PrefixSpaces)  + $Token.Surrogate) -NoNewline
}

# show the out file
Notepad.exe $OutFilePath

```

## Description

I an developing this Module to prettify PowerShell sourcecode, downloaded from the Internet.
I am a german resident, we germans have imbibe word casing from first day of writing.
Many coders in the world, do not care about correct casing, this has itched me so much,
that i have started to develop this Module. (even though I am very bad in grammar)

So the first bunch of Formating functions of this Module are processing PowerShell sourcecode for casing.

### Roadmap

- a bunch of functions to place braces (and space between them).

- replace aliases with the names who points the alias to (command alias and ParameterName alias or shorts)

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

#### Word casing

Format-BopCasingTypeName
Format-BopCasingAttributeName
Format-BopCasingKeyword
Format-BopCasingCommandName
Format-BopCasingParameter
Format-BopCasingTypeMemberName

#### Brace placement

Format-BopLCurly

## Insights

In this Module the Tokens parsed from PowerShell sourcecode are the first citizen.
The Tokens are handled as a Stream (of Tokens)

For more insights, read the sourcecode of the Module and functions and see documents in folder Doc!

## Credits

Credits goes to:

Tobias Welter

<https://github.com/TobiasPSP/Modules.PSOneTools>
<https://powershell.one/powershell-internals/parsing-and-tokenization/advanced-tokenizer>
<https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree>

Dan Ward

https://github.com/DTW-DanWard/PowerShell-Beautifier
