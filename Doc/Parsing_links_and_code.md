# Useful links and code for PowerShell code Parsing

## Very good PowerShell code parsing blog articles

Since PowerShell 3.0 code parsing you can go 2 ways to parse the code.
(with use of the same one .NET Class 'System.Management.Automation.Language.Parser')

- Tokenize
- AST (Abstract Syntax Tree)

Tokenizing PowerShell Scripts
(Simple Tokenizer since PowerShell 1.0 and 2.0)
(old .NET class ! but still useful! 'System.Management.Automation.PSParser')
<https://powershell.one/powershell-internals/parsing-and-tokenization/simple-tokenizer>

Advanced Tokenizing PowerShell Scripts
(Since PowerShell 3.0)
<https://powershell.one/powershell-internals/parsing-and-tokenization/advanced-tokenize>

Abstract Syntax Tree
(Since PowerShell 3.0)
<https://powershell.one/powershell-internals/parsing-and-tokenization/abstract-syntax-tree>

Searching the PowerShell Abstract Syntax Tree
(Since PowerShell 3.0)
<https://vexx32.github.io/2018/12/20/Searching-PowerShell-Abstract-Syntax-Tree>

## Informations about Formating PowerShell Code

Windows PowerShell Language Specification Version 3.0
(download as Word document .docx Year 2012)
<https://www.microsoft.com/en-us/download/details.aspx?id=36389>

Powershell Practice and Style recomendations
<https://poshcode.gitbooks.io/powershell-practice-and-style/>

Known Issues for PowerShell 6.0
Case-sensitivity in PowerShell etc. ...
<https://docs.microsoft.com/en-us/powershell/scripting/whats-new/known-issues-ps6>

### Informations to single items

Understanding Type Accelerators (Part 1)
<https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/understanding-type-accelerators-part-1>
```powershell
[PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')::Get
```

Get Informations about Cmdlet Parameters
The Cmdlet Parameters are nested (accidentally) as Hashtable in an Hashtable
To get Informations we must use a Hashtable in between ...
```powershell
# Example to get parameter informations from Get-ChildItem cmdlet
$Dict = (Get-Command Get-ChildItem).Parameters
ForEach($Key in $Dict.Keys) {
    $Dict[$Key]
}
```
TextInfo.ToTitleCase() Method is to Capitalize the first letter of each word
TextInfo can be found in the CultureInfo Object
```powershell
$TextInfo = ([System.Globalization.CultureInfo]::InvariantCulture).TextInfo
# Capitalize the first letter of 'hello'
$TextInfo.ToTitleCase('hello')
```

About Automatic Variables
<https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7>

Curly Braces

There is no One True Brace Style
<https://github.com/PoshCode/PowerShellPracticeAndStyle/issues/81>

<https://poshcode.gitbooks.io/powershell-practice-and-style/Style-Guide/Code-Layout-and-Formatting.html>