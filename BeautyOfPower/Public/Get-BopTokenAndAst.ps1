

Function Get-BopTokenAndAst {
  <#
.SYNOPSIS
  Parses PowerShell sourcecode from File (*.ps1, *.psm1, *.psd1) or Scriptblock or a String Variable.    
  Returns the Tokens, the AST, syntax Errors and additionally Informations as a custom Object.

.DESCRIPTION
    Invokes the advanced PowerShell Parser and returns Tokens, AST and syntax errors

.EXAMPLE
    Get-BopTokenAndAst -Path c:\test.ps1

    Parses the content of c:\test.ps1 and returns Tokens, AST and syntax errors

.EXAMPLE
    Get-ChildItem -Path $home -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
    Get-BopTokenAndAst |
    Out-GridView

    parses all PowerShell files found anywhere in your user profile

.EXAMPLE
    Get-ChildItem -Path $home -Recurse -Include *.ps1,*.psm1,*.psd1 -File |
    Get-BopTokenAndAst |
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
    [String]
    [Parameter(Mandatory,ValueFromPipeline,ParameterSetName='Path')]
    [Alias('FullName')]
    $Path,
    
    # PowerShell Code as ScriptBlock
    [ScriptBlock]
    [Parameter(Mandatory,ValueFromPipeline,ParameterSetName='ScriptBlock')]
    $ScriptBlock,
    
    # PowerShell Code as String
    [String]
    [Parameter(Mandatory, ValueFromPipeline,ParameterSetName='Code')]
    $Code,

    # include nested token that are contained inside
    # ExpandableString tokens
    [Switch]
    $IncludeNestedToken

  )
  
  Begin {
    # create variables to receive tokens and syntax errors:
    $errors = $null
    $tokens = $null
  }

  Process {
    # If a scriptblock was submitted, convert it to string
    If ($PSCmdlet.ParameterSetName -eq 'ScriptBlock') {

      $Code = $ScriptBlock.ToString()
    }

    # If a path was submitted, read code from file,
    If ($PSCmdlet.ParameterSetName -eq 'Path') {

      $code = Get-Content -Path $Path -Raw -Encoding Default
      $name = Split-Path -Path $Path -Leaf
      $filepath = $Path

      # parse the file:
      $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $Path, 
        [ref] $tokens, 
      [ref]$errors)
    }
    Else {

      # the code is already present in $Code
      $name = $Code
      $filepath = ''

      # parse the string code:
      $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $Code, 
        [ref] $tokens, 
      [ref]$errors)
    }

    If ($IncludeNestedToken) {
      # "unwrap" nested token
      $tokens = $tokens | Expand-PSOneToken
    }

    # return the results as a custom object
    Write-Output ([PSCustomObject]@{
    Name = $name
    Path = $filepath
    # default is to convert .NET Tokens to editable custom BobTokens with New-BobToken
    # Every 'Format-BobToken...' Function will consume custom BopTokens and not .NET Tokens
    Tokens = $tokens
    # "move" nested "Extent" up one level 
    # so all important properties are shown immediately
    Errors = $errors | 
    Select-Object -Property Message, 
    IncompleteInput, 
    ErrorId -ExpandProperty Extent
    Ast = $ast
    # add TypeName
    PsTypeName = 'BeautyOfPower.BopTokenAndAst'
    })

  }
}