# Parsing PowerShell code

> Advice: Please use use very litle code to examin!
> You make your live easier with that!

```powershell
# Please use use very litle code to examin!
# You make your live easier with that!
# Code to examin
$Input = 'Get-ChildItem -Path "C:\windows"'

# this Variable is a container for the Tokens
# the parser fills this by referencing it [ref]
$Tokens = $null

# this Variable is a container for parsing errors (Syntax error)
# the parser fills this by referencing it [ref]
$Errors = $null

# The AST is returned by the parser (and can be used in Pipelinig)
# Start Parsing the PowerShell code here with the .NET class
$AST = [System.Management.Automation.Language.Parser]::ParseInput($Input, [ref]$tokens, [ref]$errors)

# test if errors are there
If($Errors.count -gt 0) {

    # Display Errors
    # "move" nested "Extent" up one level
    # so all important properties are shown immediately
    # Author: Tobias Weltner
    $Errors |
        Select-Object -Property Message,
        IncompleteInput,
        ErrorId -ExpandProperty Extent

    Return # stopping if errors
}

# now you can Find all Tokens in the Variable $Tokens
# Play with that Variable content !!!
$Tokens

# to get all AST-Tokens we need to do a FindAll on it
$AstTokens = $AST.FindAll({$true}, $true)

# now you can Find all AST-Tokens in the Variable $AstTokens
# Play with that Variable content !!!
$AstTokens
```

The AST-Tokens are filtered by their .NET Type !
If you play with the AST you can make your live easier by adding the (full) Typename to each AST Object to show the Typename immediately

```powershell
$AstTokens = $AST.FindAll({$true}, $true) | ForEach-Object {Add-Member -InputObject $_ -MemberType 'NoteProperty' -Name 'FullTypeName' -Value ($_.gettype().Fullname) ; $_ }
```

## Examples

All Examples here are (re)using the Variables produces in the first parsing Example above!

### Token Examples

Find all Command Tokens (using TokenFlags)

```powershell
$Tokens | Where-Object { $_.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName) }
```

Find all Parameter Tokens (using TokenKind)

```powershell
$Tokens | Where-Object { $_.Kind -eq ([System.Management.Automation.Language.Tokenkind]::Parameter) }
```

### AST Examples

Find all Command AST-Tokens
using Type 'System.Management.Automation.Language.CommandAst' as filter

```powershell
$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
```

Find all Parameter AST-Tokens
using Type 'System.Management.Automation.Language.CommandParameterAst' as filter

```powershell
$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandParameterAst]}, $true)
```

#### A full blown Example

```powershell
# Please use use very litle code to examin!
# You make your live easier with that!
# Code to examin
$Input = 'Get-ChildItem -Path "C:\windows"'

# this Variable is a container for the Tokens
# the parser fills this by referencing it [ref]
$Tokens = $null

# this Variable is a container for parsing errors (Syntax error)
# the parser fills this by referencing it [ref]
$Errors = $null

# The AST is returned by the parser (and can be used in Pipelinig
# Start Parsing the PowerShell code here with the .NET class
$AST = [System.Management.Automation.Language.Parser]::ParseInput($Input, [ref]$Tokens, [ref]$Errors)


# test if errors are there
If($Errors.count -gt 0) {

    # Display Errors
    # "move" nested "Extent" up one level
    # so all important properties are shown immediately
    # Author: Tobias Weltner
    $Errors |
        Select-Object -Property Message,
        IncompleteInput,
        ErrorId -ExpandProperty Extent

    Return # stopping if errors
}

# Find all Command Tokens (using TokenFlags)
$Tokens | Where-Object { $_.TokenFlags.HasFlag([System.Management.Automation.Language.TokenFlags]::CommandName) }


# Find all Command AST-Tokens
$AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)
```
