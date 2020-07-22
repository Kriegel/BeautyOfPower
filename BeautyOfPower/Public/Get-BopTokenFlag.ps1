Function Get-BopTokenFlag {
<#
.EXAMPLE
    Get-BopTokenFlag

    Returns all TokenFlag Names as String from .NET enumeration [System.Management.Automation.Language.TokenFlags]

.EXAMPLE
    Get-BopTokenFlag -AsType

    Returns all TokenFlags as Type of [System.Management.Automation.Language.TokenFlags]

.EXAMPLE
    Get-BopTokenFlag -Filter '*Operator'
    
    Return all TokenFlags which are end with Operator (as Strings)
#>
    [CmdletBinding()]
    Param(

        # uses the -Like operator with the TokenFlags Names
        [String]$Filter,

        # return as [System.Management.Automation.Language.TokenFlags]
        # default Returntype ist String
        [Switch]$AsType
    )

    Process {

        $SB = [Scriptblock]::Create("`$_ -Like '$Filter'")

        If($Filter) {
            $Names = ([Enum]::GetNames([System.Management.Automation.Language.TokenFlags])).Where($SB)
        }
        Else {
            $Names = [Enum]::GetNames([System.Management.Automation.Language.TokenFlags])
        }

        If([String]::IsNullOrEmpty($Names)) {
            Write-Warning -Message "$($MyInvocation.MyCommand.Name) Filter {TokenFlagGetNames -like $Filter} does not match a TokenFlags Name`nReturning [TokenFlag]::None !"
            $Names = 'None'
        }

        If($AsType.IsPresent) {
            ForEach($Name in $Names) {
                [System.Management.Automation.Language.TokenFlags]$Name
            }
        }
        Else {
            $Names
        }
    }
}