Function Select-BopToken {
<#
.SYNOPSIS
  Filters Tokens by TokenFlags, TokenKind and Token Text

.DESCRIPTION
  Filters Tokens by TokenFlags, TokenKind and Token Text

.EXAMPLE

  Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Select-BopToken -Flag 'CommandName'

.EXAMPLE

  Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Select-BopToken -Flag 'TypeName', 'AttributeName' -Text 'CmdletBinding'

.EXAMPLE

  Get-BopTokenAndAst -Path 'C:\ScriptName.ps1' -IncludeNestedToken | Select-BopToken -Flag 'TypeName','CommandName' -Kind 'Generic','Identifier' -Text '*ashtabl*','Get-*'

.NOTES

    Author: Tobias Weltner
    Edited: Peter Kriegel
#>
    [CmdletBinding()]
    Param(

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [System.Collections.Arraylist]$Token,

        # the TokenFlags of token requested.
        # If neither TokenFlag nor TokenKind nor Text is requested, all Tokens are Returned
        [Alias('TokenFlag','TokenFlags')] # breaking the BP-Rules with plural alias, because the .Net Type name is plural.
        [System.Management.Automation.Language.TokenFlags[]]
        $Flag = $null,

        # the kind of token requested.
        # If neither TokenFlag nor TokenKind nor Text is requested, all Tokens are Returned
        [Alias('TokenKind')]
        [System.Management.Automation.Language.TokenKind[]]
        $Kind = $null,

        # Specifies the Text of the Token to search for.
        # A comma-separated list of Token Text is accepted.
        # Wildcards are accepted. (using the PowerShell -Like operator internally)
        # If neither TokenFlag nor TokenKind nor Text is requested, all Tokens are Returned
        [Alias('TokenText')]
        [String[]]$Text = $null
    )

    Begin {
      $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name
    }

    Process {

      # for Debuging and verbosity
      If($VerbosePreference -ne 'SilentlyContinue') {
        $FlagsMessage = ''
        $KindMessage = ''
        $TokenTextMessage = ''
        If($null -ne $Flag) {
          $FlagNames = ForEach($Fl In $Flag) {$Fl.ToString()}
          $FlagsString = $FlagNames -join ', '
          $FlagsMessage = "TokenFlag: $FlagsString" + "`n"
        }
        If($null -ne $Kind) {
          $KindNames = ForEach($Ki In $Kind) {$Ki.ToString()}
          $KindString = $KindNames  -join ', '
          $KindMessage = "TokenKind: $KindString" + "`n"
        }
        If(-Not [String]::IsNullOrEmpty($Text)) {
          $TokenTextString = $Text -join ', '
          $TokenTextMessage = "Text: $TokenTextString" + "`n"
        }

        Write-Verbose "$MyCommandName;`n$FlagsMessage$KindMessage$TokenTextMessage"
      }

      # Thank you Tobias Weltner *hug*
      # filter token and use fast scriptblock filtering instead of Where-Object:
      $Token |
      & { Process { If ($null -eq $Kind -or
          $Kind -contains $_.Kind)
          { $_ }
      }} |
      & { Process {
          $CurrentToken = $_
          If ($null -eq $Flag) { $CurrentToken }
          Else {
            $Flag |
            Foreach-Object {
              If ($CurrentToken.TokenFlags.HasFlag($_))
            { $CurrentToken } } |
            Select-Object -First 1
          }
        }
      } |
      & { Process {
        $CurrentToken = $_
        If ([String]::IsNullOrEmpty($Text)) {$CurrentToken}
        Else {
          $Text |
          Foreach-Object {
            If ( $CurrentToken.Text -Like $_)
          { $CurrentToken } }
        }
      }}
    }
}