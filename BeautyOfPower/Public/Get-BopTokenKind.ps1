Function Get-BopTokenKind {
    <#
    .EXAMPLE
        Get-BopTokenKind

        Returns all TokenKind Names as String from .NET enumeration [System.Management.Automation.Language.TokenKind]

    .EXAMPLE
        Get-BopTokenKind -AsType

        Returns all TokenKind as Type of [System.Management.Automation.Language.TokenKind]

    .EXAMPLE
        Get-BopTokenKind -Filter 'Question*'

        Return all TokenKind which are start with Question (as Strings)
    #>
    [CmdletBinding()]
    Param(

        # uses the -Like operator with the TokenKind Names
        [String]$Filter,

        # return as [System.Management.Automation.Language.TokenKind]
        # default Returntype ist String
        [Switch]$AsType
    )

    Process {

        $SB = [Scriptblock]::Create("`$_ -Like '$Filter'")

        If($Filter) {
            $Names = ([Enum]::GetNames([System.Management.Automation.Language.TokenKind])).Where($SB)
        }
        Else {
            $Names = [Enum]::GetNames([System.Management.Automation.Language.TokenKind])
        }

        If([String]::IsNullOrEmpty($Names)) {
            Write-Warning -Message "$($MyInvocation.MyCommand.Name) Filter {TokenFlagGetNames -like $Filter} does not match a TokenKind Name`nReturning [TokenFlag]::None !"
            $Names = 'None'
        }

        If($AsType.IsPresent) {
            ForEach($Name in $Names) {
                [System.Management.Automation.Language.TokenKind]$Name
            }
        }
        Else {
            $Names
        }
    }
}