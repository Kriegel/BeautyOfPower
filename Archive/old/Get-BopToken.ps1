Function Get-BoPToken {
 <#
.SYNOPSIS
    Parses a PowerShell Script (*.ps1, *.psm1, *.psd1) and returns the token

.DESCRIPTION
    Invokes the advanced PowerShell Parser and returns tokens and syntax errors

.EXAMPLE
    Get-BoPToken -Path c:\test.ps1
    Parses the content of c:\test.ps1 and returns tokens and syntax errors

.EXAMPLE
    Get-ChildItem -Path $home -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
    Get-BoPToken |
    Out-GridView

    parses all PowerShell files found anywhere in your user profile

.EXAMPLE
    Get-ChildItem -Path $home -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
    Get-BoPToken |
    Where-Object Errors

    parses all PowerShell files found anywhere in your user profile
    and returns only those files that contain syntax errors

.NOTES
    Author: Tobias Weltner
    Edited: Peter Kriegel

#>

  [CmdletBinding(DefaultParameterSetName='Path')]
  Param (
    # Path to PowerShell script file
    # can be a string or any object that has a "Path"
    # or "FullName" property:
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Path')]
    [Alias('FullName')]
    [String]$Path,

    # PowerShell Code as ScriptBlock
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='ScriptBlock')]
    [ScriptBlock]$ScriptBlock,

    # PowerShell Code as String
    [Parameter(Mandatory=$true, ValueFromPipeline=$true,ParameterSetName='Code')]
    [String]$Code,

    # the kind of token requested.
    # If neither TokenFlag nor TokenKind nor Text is requested, all Tokens are Returned
    # See: Select-BopToken
    [Alias('TokenKind')]
    [System.Management.Automation.Language.TokenKind[]]
    $Kind = $null,

    # the TokenFlags of token requested.
    # If neither TokenFlag nor TokenKind nor Text is requested, all Tokens are Returned
    # See: Select-BopToken
    [Alias('TokenFlag','TokenFlags')] # breaking the BP-Rules with plural alias, because the .Net Type name is plural.
    [System.Management.Automation.Language.TokenFlags[]]
    $Flag = $null,

    # Specifies the Text of the Token to search for.
    # A comma-separated list of Token Text is accepted.
    # Wildcards are accepted. (using the PowerShell -Like operator internally)
    # If neither TokenFlag nor TokenKind nor Text is requested, all Tokens are Returned
    # See: Select-BopToken
    [String[]]$Text = $null,

    # include nested token that are contained inside
    # ExpandableString tokens
    [Switch]$IncludeNestedToken,

    [Switch]$AsDotNetToken

  )

  Begin {
    $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

    # create variables to receive tokens and syntax errors:
    $errors = $null
    $tokens = $null

    # filter the Tokens?
    # when the user submits either one of these parameters, the return value should
    # be tokens of these kinds:
    $filterToken = ($PSBoundParameters.ContainsKey('Kind')) -or
    ($PSBoundParameters.ContainsKey('Flag')) -or ($PSBoundParameters.ContainsKey('Text'))
  }

  Process {
    # if a scriptblock was submitted, convert it to string
    If ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {
      $Code = $ScriptBlock.ToString()
    }

    # if a path was submitted, read code from file,
    If ($PSCmdlet.ParameterSetName -eq 'Path') {

      # parse the file:
      $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref] $tokens,
        [ref]$errors
      )
    }
    Else {

      # the code is already present in $Code

      # parse the string code:
      $null = [System.Management.Automation.Language.Parser]::ParseInput(
        $Code,
        [ref] $tokens,
        [ref]$errors
      )
    }

    If ($IncludeNestedToken) {
      # "unwrap" nested token
      $tokens = $tokens | Expand-PSOneToken
    }

    If ($filterToken) {
      Write-Verbose "$MyCommandName; calling Select-BopToken"
      $tokens = Select-BopToken -Token $tokens -Flag $Flag -Kind $Kind -Text $Text
    }

    If($AsDotNetToken.IsPresent) {
      Write-Output $tokens
    } ELse {
     New-BopToken -Token $tokens
    }

  }
}