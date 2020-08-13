Function Get-BopParameterBindingFromInside {
<#
.SYNOPSIS
    Uses an CommandInfo and an fittingly CommandAst to find out which Parameters get bound by the PowerShell Parameterbinder

.DESCRIPTION
    Uses an CommandInfo and an fittingly CommandAst to find out which Parameters get bound by the PowerShell Parameterbinder

    In my Expirience the best way to find out which Parameter was bound in a Command, is to to look from inside the Command.

    This Function Takes an CommandInfo Object, to create an internal Function similar to the origin (like a Proxy Function).
    ( i call it a 'Parameter Proxy Function' (PPF).

    The PPF has NO executeable code except the Parameter section and
    in the Process-Block, calls to PSBoundParameters and detection of the used ParameterSetName.

    The CommandElements of the CommandAst which holds the Command Parameters are feeded to the PPF.
    So the PPF can return from inside which Parameters was bound and returns the $PSBoundParameters.

    Additionally the PPF reports the used ParametersetName.
    The ParametersetName Value can be found in the returned $PSBoundParameters with the Key named:
    'BeautyOfPowerPSCmdletParameterSetName'

    !!!!!!!!!!! CAUTION !!!!!!!

    The Parameter Section of a Command (and there for the PPF), can have Script Elements that are doing something.
    This can be (in very rare cases) Script-Code which will do Changes or do Harm to the System it runs on!

    Using this Function is on your own accountability !

    Secondly the execution of the PPF Function has a High risk to fail, because Parameter Binding may Fail.
    This is a calculate Risk and is taken with a smile. *Ha, ha, ha, ha* (greets from the Joker)


.EXAMPLE

    $Input = "Get-ChildItem -Path 'C:\windows' '*run*' -Force"

    $AST = [System.Management.Automation.Language.Parser]::ParseInput($Input, [ref]$null, [ref]$null)

    $CmdAst = $AST.FindAll({$args[0] -is [System.Management.Automation.Language.CommandAst]}, $true)

    Get-BopParameterBindingFromInside -CommandInfo (Get-Command Get-ChildItem) -CommandAst ($CmdAst[0])

.NOTES
    Author: Peter Kriegel

#>

    [CmdletBinding()]
    Param(

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=0
        )]
        [System.Management.Automation.CommandInfo]$CommandInfo,

        [System.Management.Automation.Language.CommandAst]$CommandAst
    )

    Process {

        Try {

            # name of Temporary Parameter Proxy Function (PPF)
            $PPFunctionName = 'Get-BopParameterBindingFromInsideParameterProxyFunction'

            $DirChar = [System.IO.Path]::DirectorySeparatorChar

            If(Test-Path -Path "Function:$DirChar$PPFunctionName") {
                Remove-Item -Path "Function:$DirChar$PPFunctionName" -Force -ErrorAction 'Ignore'
            }

            $metaData = New-Object -TypeName 'System.Management.Automation.CommandMetaData' -ArgumentList $CommandInfo

            # TODO: is the .NET Stringbuilder faster here??

            $Text = "Function $PPFunctionName {`n`n"

            $Text += [System.Management.Automation.ProxyCommand]::GetCmdletBindingAttribute($metaData) + "`nParam(`n"
            $Text += [System.Management.Automation.ProxyCommand]::GetParamBlock($metaData) + "`n)`n`n"
            $Text += "DynamicParam {`n"
            $Text += [System.Management.Automation.ProxyCommand]::GetDynamicParam($metaData)
            $Text += "`n}`n"

            $Text += "`nProcess{ `$PSBoundParameters.Add('BeautyOfPowerPSCmdletParameterSetName',`$PSCmdlet.ParameterSetName) ; `$PSBoundParameters  }`n"


            $Text += "`n}"

            # define Temporary Parameter Proxy Function (PPF)
            . ([Scriptblock]::Create($Text))


            # Creating Command Line from Command Ast
            # using the PPF as Command instead the origin

            $Count = $CommandAst.CommandElements.Count

            # start by 1 to skipt the command Name
            $CommandParameter = $(For ($i = 1; $i -lt $Count; $i++) {
            $CommandAst.CommandElements[$i].Extent.Text
            }) -join ' '

            # Executing Temporary Parameter Proxy Function (PPF)
            . ([Scriptblock]::Create("`$ErrorActionPreference = 'Stop' ; $PPFunctionName $CommandParameter"))

            # removing Temporary Parameter Proxy Function (PPF)
            If(Test-Path -Path "Function:$DirChar$PPFunctionName") {
                Remove-Item -Path "Function:$DirChar$PPFunctionName" -Force -ErrorAction 'Ignore'
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }

}