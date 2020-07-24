Function Format-BopCasingKnownVariables {
<#
.SYNOPSIS
    Format PowerShell known Variables Token to have an uniform casing
    Known Variables are: Automatic Variables and Preference Variables

.DESCRIPTION
    Format PowerShell known Variables Token to have an uniform casing

    The Automatic Variables are inconsistent in casing by Microsoft, most of the Variablese are PascalCase. But ...
    The following Variables are complete lowercase by Microsoft.
    $true, $false, $null, $args, $this, $input, $foreach, $switch

    The default behavior is to return ALL known Variables as PascalCase.

    If you like to have the Microsoft defaults, use the switch Parameter -MSDefault

    Automatic Variables

        $true
        $false
        $args
        $foreach
        $this
        $null
        $input
        $switch
        $ConsoleFileName
        $Error
        $Event
        $EventArgs
        $EventSubscriber
        $ExecutionContext
        $HOME
        $Host
        $IsCoreCLR
        $IsLinux
        $IsMacOS
        $IsWindows
        $LastExitCode
        $Matches
        $MyInvocation
        $NestedPromptLevel
        $PID
        $PROFILE
        $PSBoundParameters
        $PSCmdlet
        $PSCommandPath
        $PSCulture
        $PSDebugContext
        $PSHOME
        $PSItem
        $PSScriptRoot
        $PSSenderInfo
        $PSUICulture
        $PSVersionTable
        $PWD
        $Sender
        $ShellId
        $StackTrace

    Preference Variables

        $ConfirmPreference
        $DebugPreference
        $ErrorActionPreference
        $ErrorView
        $FormatEnumerationLimit
        $InformationPreference
        $LogCommandHealthEvent
        $LogCommandLifecycleEvent
        $LogEngineHealthEvent
        $LogEngineLifecycleEvent
        $LogProviderLifecycleEvent
        $LogProviderHealthEvent
        $MaximumHistoryCount
        $OFS
        $OutputEncoding
        $ProgressPreference
        $PSDefaultParameterValues
        $PSEmailServer
        $PSModuleAutoLoadingPreference
        $PSSessionApplicationName
        $PSSessionConfigurationName
        $PSSessionOption
        $Transcript
        $VerbosePreference
        $WarningPreference
        $WhatIfPreference

.EXAMPLE


.NOTES
    Author: Peter Kriegel
#>

    [CmdletBinding()]
    Param (

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [PsObject]$BopToken,

        # The following Variables going to be complete lowercase: $true, $false, $null, $args, $this, $input, $foreach, $switch
        [Switch]$MSDefault,

        # Capitalize the first letter of each unknown variable
        [Switch]$IncludeUnknownVars
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

        $LowerVars = @('$true', '$false', '$args', '$foreach', '$this', '$null', '$input', '$switch')
        $PascalVars = @('$True', '$False', '$Args', '$ForEach', '$This', '$Null', '$Input', '$Switch')

        $VarNames = @('$ConsoleFileName',
                    '$Error',
                    '$Event',
                    '$EventArgs',
                    '$EventSubscriber',
                    '$ExecutionContext',
                    '$HOME',
                    '$Host',
                    '$IsCoreCLR',
                    '$IsLinux',
                    '$IsMacOS',
                    '$IsWindows',
                    '$LastExitCode',
                    '$Matches',
                    '$MyInvocation',
                    '$NestedPromptLevel',
                    '$PID',
                    '$PROFILE',
                    '$PSBoundParameters',
                    '$PSCmdlet',
                    '$PSCommandPath',
                    '$PSCulture',
                    '$PSDebugContext',
                    '$PSHOME',
                    '$PSItem',
                    '$PSScriptRoot',
                    '$PSSenderInfo',
                    '$PSUICulture',
                    '$PSVersionTable',
                    '$PWD',
                    '$Sender',
                    '$ShellId',
                    '$StackTrace',
                    '$ConfirmPreference',
                    '$DebugPreference',
                    '$ErrorActionPreference',
                    '$ErrorView',
                    '$FormatEnumerationLimit',
                    '$InformationPreference',
                    '$LogCommandHealthEvent',
                    '$LogCommandLifecycleEvent',
                    '$LogEngineHealthEvent',
                    '$LogEngineLifecycleEvent',
                    '$LogProviderLifecycleEvent',
                    '$LogProviderHealthEvent',
                    '$MaximumHistoryCount',
                    '$OFS',
                    '$OutputEncoding',
                    '$ProgressPreference',
                    '$PSDefaultParameterValues',
                    '$PSEmailServer',
                    '$PSModuleAutoLoadingPreference',
                    '$PSSessionApplicationName',
                    '$PSSessionConfigurationName',
                    '$PSSessionOption',
                    '$Transcript',
                    '$VerbosePreference',
                    '$WarningPreference',
                    '$WhatIfPreference'
        )

        # making a lower copy of the Array
        # because the Array.IndexOf() Method is not case insensitiv
        # this array is only used to find the IndexOf faster
        $VarNamesLower = ForEach ($Item in $VarNames) {$Item.Tolower()}

        # create TextInfo instance to Capitalize the first letter of each word later with its method
        $TextInfo = ([System.Globalization.CultureInfo]::InvariantCulture).TextInfo

    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok In $BopToken) {

                If(-Not ($Tok.Kind  -eq [System.Management.Automation.Language.TokenKind]::Variable)) {
                    Write-Output $Tok
                    Continue
                }

                # first process all unknown variables
                If($VarNames -inotcontains $Tok.Text -and $LowerVars -inotcontains $Tok.Text) {
                    If($IncludeUnknownVars.IsPresent) {
                        #TextInfo.ToTitleCase() Method is to Capitalize the first letter of each word

                        $Tok.Surrogate = $TextInfo.ToTitleCase(($Tok.Text))

                    }

                    Write-Output $Tok
                    Continue

                }

                # process well cased variables
                If($VarNames -icontains $Tok.Text) {
                    $IndexOf = $VarNamesLower.IndexOf(($Tok.Text.ToLower()))
                    $Tok.Surrogate = $VarNames[$IndexOf]
                    Write-Output $Tok
                    Continue
                }

                # process variables which are lower cased by Microsoft
                If($LowerVars -icontains $Tok.Text) {
                    $IndexOf = $LowerVars.IndexOf(($Tok.Text.ToLower()))

                    If($MSDefault.IsPresent) {
                        # return it as lowercase
                        $Tok.Surrogate = $LowerVars[$IndexOf]
                    }
                    Else{
                        # return it as PascalCase
                        $Tok.Surrogate = $PascalVars[$IndexOf]
                    }
                    Write-Output $Tok
                }
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}