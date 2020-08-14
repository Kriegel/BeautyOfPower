Function Format-BopCasingOperator {
<#
.SYNOPSIS
    Format PowerShell OperatorName Token to have an uniform casing

.DESCRIPTION
    Format PowerShell OperatorName Token to have an uniform casing

    Processes the following OperatorNames

        -Not
        -Bnot
        -And
        -Or
        -Xor
        -Band
        -Bor
        -Bxor
        -Join
        -Ieq, -eq
        -Ine, -ne
        -Ige, -ge
        -Igt, -gt
        -Ilt, -lt
        -Ile, -le
        -Ilike, -like
        -Inotlike, -notlike
        -Imatch, -match
        -Inotmatch, -notmatch
        -Ireplace, -replace
        -Icontains, -contains
        -Inotcontains, -notcontains
        -Iin, -in
        -Inotin, -notin
        -Isplit, -split
        -Ceq
        -Cne
        -Cge
        -Cgt
        -Clt
        -Cle
        -Clike
        -Cnotlike
        -Cmatch
        -Cnotmatch
        -Creplace
        -Ccontains
        -Cnotcontains
        -Cin
        -Cnotin
        -Csplit
        -Is
        -IsNot
        -As
        -Shl
        -Shr

.EXAMPLE

    Import-Module "BeautyOfPower" -Force

    $Code = @'
    'Hello' -IEq 'hELLO'
    'Hello' -Eq 'hELLO'
    '@

    Get-BopTokenAndAst -Code $Code |
    ConvertTo-BopToken |
    Format-BopCasingOperator |
    Where-Object { $_.Text -ieq '-ieq' -or $_.Text -ieq '-eq'  } |
    Select-Object Surrogate

.EXAMPLE

    Import-Module "BeautyOfPower" -Force

    $Code = @'
    -Not
    -BNot
    -And
    -Or
    -XOr
    -BAnd
    -BOr
    -BXor
    -Join
    -IEq
    -Eq
    -INe
    -Ne
    -IGe
    -Ge
    -IGt
    -Gt
    -ILt
    -Lt
    -ILe
    -Le
    -ILike
    -Like
    -INotLike
    -NotLike
    -IMatch
    -Match
    -INotMatch
    -NotMatch
    -IReplace
    -Replace
    -IContains
    -Contains
    -INotContains
    -NotContains
    -IIn
    -In
    -INotIn
    -NotIn
    -ISplit
    -Split
    -CEq
    -CNe
    -CGe
    -CGt
    -CLt
    -CLe
    -CLike
    -CNotlike
    -CMatch
    -CNotMatch
    -CReplace
    -CContains
    -CNotContains
    -CIn
    -CNotIn
    -CSplit
    -Is
    -IsNot
    -As
    -Shl
    -Shr
    '@

    Get-BopTokenAndAst -Code $Code |
    ConvertTo-BopToken |
    Format-BopCasingOperator -MixedCase |
    Where-Object { $_.Kind -ne 'NewLine'  } |
    Select-Object Surrogate

.NOTES
    Author: Peter Kriegel

    TODO: Support custom casing rule

#>

    [CmdletBinding(DefaultParameterSetName='ToLower')]
    Param (

        [Parameter(Mandatory=$true,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=0
        )]
        [ValidateNotNullOrEmpty()]
        [PsObject]$BopToken,

        [Parameter(ParameterSetName='CustomCasing')]
        [ValidateNotNullOrEmpty()]
        # Provide an Array with custom cased OperatorNames (see Example code, with full Array of OperatorNames)
        [String[]]$CustomCasing,

        # Lower case the whole OperatorName
        [Parameter(ParameterSetName='Lower')]
        [Switch]$Lower,

        # Capitalize the first letter of the OperatorName
        [Parameter(ParameterSetName='TitleCase')]
        [Switch]$TitleCase,

        [Parameter(ParameterSetName='PascalCase')]
        # do PascalCasing to the OperatorNames
        [Switch]$PascalCase,

        [Parameter(ParameterSetName='MixedCase')]
        # Most OperatorNames are PascalCased in Mixed Casing
        # except the explicit case insensitiv / sensitiv OperatorNames like -iNe or -cNe
        # the starting char c or i, of these OperatorNames are lower cased
        [Switch]$MixedCase

        # TODO: convert case insensitive Operators like -ne to explicit -ine OperatorName [Switch]$Explicit
    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

        # Helper Method to Capitalize the first letter of the OperatorName
        $TextInfo = ([System.Globalization.CultureInfo]::InvariantCulture).TextInfo

        $TokenKinds =  @([System.Management.Automation.Language.TokenKind]::Not,
                [System.Management.Automation.Language.TokenKind]::Bnot,
                [System.Management.Automation.Language.TokenKind]::And,
                [System.Management.Automation.Language.TokenKind]::Or,
                [System.Management.Automation.Language.TokenKind]::Xor,
                [System.Management.Automation.Language.TokenKind]::Band,
                [System.Management.Automation.Language.TokenKind]::Bor,
                [System.Management.Automation.Language.TokenKind]::Bxor,
                [System.Management.Automation.Language.TokenKind]::Join,
                [System.Management.Automation.Language.TokenKind]::Ieq,
                [System.Management.Automation.Language.TokenKind]::Ine,
                [System.Management.Automation.Language.TokenKind]::Ige,
                [System.Management.Automation.Language.TokenKind]::Igt,
                [System.Management.Automation.Language.TokenKind]::Ilt,
                [System.Management.Automation.Language.TokenKind]::Ile,
                [System.Management.Automation.Language.TokenKind]::Ilike,
                [System.Management.Automation.Language.TokenKind]::Inotlike,
                [System.Management.Automation.Language.TokenKind]::Imatch,
                [System.Management.Automation.Language.TokenKind]::Inotmatch,
                [System.Management.Automation.Language.TokenKind]::Ireplace,
                [System.Management.Automation.Language.TokenKind]::Icontains,
                [System.Management.Automation.Language.TokenKind]::Inotcontains,
                [System.Management.Automation.Language.TokenKind]::Iin,
                [System.Management.Automation.Language.TokenKind]::Inotin,
                [System.Management.Automation.Language.TokenKind]::Isplit,
                [System.Management.Automation.Language.TokenKind]::Ceq,
                [System.Management.Automation.Language.TokenKind]::Cne,
                [System.Management.Automation.Language.TokenKind]::Cge,
                [System.Management.Automation.Language.TokenKind]::Cgt,
                [System.Management.Automation.Language.TokenKind]::Clt,
                [System.Management.Automation.Language.TokenKind]::Cle,
                [System.Management.Automation.Language.TokenKind]::Clike,
                [System.Management.Automation.Language.TokenKind]::Cnotlike,
                [System.Management.Automation.Language.TokenKind]::Cmatch,
                [System.Management.Automation.Language.TokenKind]::Cnotmatch,
                [System.Management.Automation.Language.TokenKind]::Creplace,
                [System.Management.Automation.Language.TokenKind]::Ccontains,
                [System.Management.Automation.Language.TokenKind]::Cnotcontains,
                [System.Management.Automation.Language.TokenKind]::Cin,
                [System.Management.Automation.Language.TokenKind]::Cnotin,
                [System.Management.Automation.Language.TokenKind]::Csplit,
                [System.Management.Automation.Language.TokenKind]::Is,
                [System.Management.Automation.Language.TokenKind]::IsNot,
                [System.Management.Automation.Language.TokenKind]::As,
                [System.Management.Automation.Language.TokenKind]::Shl,
                [System.Management.Automation.Language.TokenKind]::Shr
        )

        $PascalCaseArray = @('-Not',
                        '-BNot',
                        '-And',
                        '-Or',
                        '-XOr',
                        '-BAnd',
                        '-BOr',
                        '-BXor',
                        '-Join',
                        '-IEq',
                        '-Eq',
                        '-INe',
                        '-Ne',
                        '-IGe',
                        '-Ge',
                        '-IGt',
                        '-Gt',
                        '-ILt',
                        '-Lt',
                        '-ILe',
                        '-Le',
                        '-ILike',
                        '-Like',
                        '-INotLike',
                        '-NotLike',
                        '-IMatch',
                        '-Match',
                        '-INotMatch',
                        '-NotMatch',
                        '-IReplace',
                        '-Replace',
                        '-IContains',
                        '-Contains',
                        '-INotContains',
                        '-NotContains',
                        '-IIn',
                        '-In',
                        '-INotIn',
                        '-NotIn',
                        '-ISplit',
                        '-Split',
                        '-CEq',
                        '-CNe',
                        '-CGe',
                        '-CGt',
                        '-CLt',
                        '-CLe',
                        '-CLike',
                        '-CNotlike',
                        '-CMatch',
                        '-CNotMatch',
                        '-CReplace',
                        '-CContains',
                        '-CNotContains',
                        '-CIn',
                        '-CNotIn',
                        '-CSplit',
                        '-Is',
                        '-IsNot',
                        '-As',
                        '-Shl',
                        '-Shr'
                    )

        $MixedCaseArray = @('-Not',
                        '-bNot',
                        '-And',
                        '-Or',
                        '-xOr',
                        '-bAnd',
                        '-bOr',
                        '-bXor',
                        '-Join',
                        '-iEq',
                        '-Eq',
                        '-iNe',
                        '-Ne',
                        '-iGe',
                        '-Ge',
                        '-iGt',
                        '-Gt',
                        '-iLt',
                        '-Lt',
                        '-iLe',
                        '-Le',
                        '-iLike',
                        '-Like',
                        '-iNotLike',
                        '-NotLike',
                        '-iMatch',
                        '-Match',
                        '-iNotMatch',
                        '-NotMatch',
                        '-iReplace',
                        '-Replace',
                        '-iContains',
                        '-Contains',
                        '-iNotContains',
                        '-NotContains',
                        '-iIn',
                        '-In',
                        '-iNotIn',
                        '-NotIn',
                        '-iSplit',
                        '-Split',
                        '-cEq',
                        '-cNe',
                        '-cGe',
                        '-cGt',
                        '-cLt',
                        '-cLe',
                        '-cLike',
                        '-cNotlike',
                        '-cMatch',
                        '-cNotMatch',
                        '-cReplace',
                        '-cContains',
                        '-cNotContains',
                        '-cIn',
                        '-cNotIn',
                        '-cSplit',
                        '-Is',
                        '-IsNot',
                        '-As',
                        '-Shl',
                        '-Shr'
                    )

    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok In $BopToken) {
                    IF($TokenKinds -notcontains $Tok.Kind) {
                        Write-Verbose "$MyCommandName; $($Tok.Text) is not in Operator list ; Continue"
                        Write-Output $Tok
                        Continue
                    }
            }

            # extract Operatorname from TokenKind and add dash - in front
            $OperatorName = "-$($Tok.Kind.ToString())"

            <#
                Creating equivalent names to case insensitiv Operators

                -Ieq, -eq
                -Ine, -ne
                -Ige, -ge
                -Igt, -gt
                -Ilt, -lt
                -Ile, -le
                -Ilike, -like
                -Inotlike, -notlike
                -Imatch, -match
                -Inotmatch, -notmatch
                -Ireplace, -replace
                -Icontains, -contains
                -Inotcontains, -notcontains
                -Iin, -in
                -Inotin, -notin
                -Isplit, -split
            #>

            $AlternativName = $null

            Switch ($OperatorName) {
                '-Ieq' {$AlternativName = '-eq'}
                '-Ine' {$AlternativName = '-ne'}
                '-Ige' {$AlternativName = '-ge'}
                '-Igt' {$AlternativName = '-gt'}
                '-Ilt' {$AlternativName = '-lt'}
                '-Ile' {$AlternativName = '-le'}
                '-Ilike' {$AlternativName = '-like'}
                '-Inotlike' {$AlternativName = '-notlike'}
                '-Imatch' {$AlternativName = '-match'}
                '-Inotmatch' {$AlternativName = '-notmatch'}
                '-Ireplace' {$AlternativName = '-replace'}
                '-Icontains' {$AlternativName = '-contains'}
                '-Inotcontains' {$AlternativName = '-notcontains'}
                '-Iin' {$AlternativName = '-in'}
                '-Inotin' {$AlternativName = '-notin'}
                '-Isplit' {$AlternativName = '-split'}

                Default {$AlternativName = $null}
            }

            If(($Tok.Text -ieq $OperatorName) -or ($Tok.Text -ieq $AlternativName)) {
                If($PSCmdlet.ParameterSetName -eq 'ToLower' -or $Lower.IsPresent) {
                    $Tok.Surrogate = $Tok.Text.ToLower()
                }

                If($TitleCase.IsPresent) {
                    $Tok.Surrogate = $TextInfo.ToTitleCase(($Tok.Text.ToLower()))
                }
            }

            If($PascalCase.IsPresent) {
                ForEach ($POp in $PascalCaseArray) {
                    If($Tok.Text -ieq $POp) {
                        $Tok.Surrogate = $POp
                        break
                    }
                }
            }

            If($MixedCase.IsPresent) {
                ForEach ($MOp in $MixedCaseArray) {
                    If($Tok.Text -ieq $MOp) {
                        $Tok.Surrogate = $MOp
                        break
                    }
                }
            }

            If($CustomCasing.count -gt 0) {
                ForEach ($COp in $CustomCasing) {
                    If($Tok.Text -ieq $COp) {
                        $Tok.Surrogate = $COp
                        break
                    }
                }
            }

            Write-Output $Tok

        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}