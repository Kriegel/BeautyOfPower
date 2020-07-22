Function Format-BopLCurly {
<#
.SYNOPSIS
    Format the place of the left (opening) curly brace (LCurly) after a Keyword (statement) in PowerShell code

.DESCRIPTION
    Format the place of the left (opening) curly brace (LCurly) afte a Keyword (statement) in PowerShell code

    The default behavior of this Function is to implement the so-called "One True Brace Style" variant to K&R,
    which requires that every braceable statement should have the opening brace on
    the same line like the Keyword (statement) at the end of this line.

    If you use the -LCurlyOnNewLine switch with this Function,
    it puts braces on their own line, indented to the same level as the keyword (statement) (Allman style)

    Currently this Function does this only for the braces after the following PowerShell keywords :

            If,
            Else,
            ElseIf,
            Switch,
            Foreach,
            For,
            Do,
            While, # Remark: in a Do{} While() the While has not LCurly ;-)
            Try,
            Catch,
            Finally,
            Function,
            Begin,
            Process,
            End,
            Enum,
            DynamicParam,
            Data,
            Class,
            Workflow,
            InlineScript,
            Trap,
            Filter


.EXAMPLE
    Get-BopTokenAndAstAndAst -Path 'C:\PsCode\TestFile.ps1' | ConvertTo-BopToken | Format-BopLCurly

    # puts the opening brace on the same line like the Keyword (statement) at the end of this line

.EXAMPLE

    Get-BopTokenAndAstAndAst -Path 'C:\PsCode\TestFile.ps1' | ConvertTo-BopToken | Format-BopLCurly -LCurlyOnNewLine

    # puts the opening brace on their own line direct after the keyword, indented to the same level as the keyword (statement) (Allman style)


.NOTES
    Author: Peter Kriegel

    See discussion here: https://github.com/PoshCode/PowerShellPracticeAndStyle/issues/81
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

        # puts braces on their own line direct after the keyword, indented to the same level as the keyword (statement) (Allman style)
        [Switch]$LCurlyOnNewLine
    )

    Begin {

        # init Function variables
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name
        $TokenSequence = [System.Collections.ArrayList]@()
        $KeywordFound = $false
        $NewLineBetweenKeywordAndLCurly = $false
        $KeywordTok = $null


        # Token Kind Kewords with scriptblocks (curly braces) to Process
        # see GetHelp about_language_keywords
        $KindToProcess = @(
            ([System.Management.Automation.Language.TokenKind]::If),
            ([System.Management.Automation.Language.TokenKind]::Else),
            ([System.Management.Automation.Language.TokenKind]::ElseIf),
            ([System.Management.Automation.Language.TokenKind]::Switch),
            ([System.Management.Automation.Language.TokenKind]::Foreach),
            ([System.Management.Automation.Language.TokenKind]::For),
            ([System.Management.Automation.Language.TokenKind]::Do),
            ([System.Management.Automation.Language.TokenKind]::While), # Do{}While()  has not LCurly !!!!!!
            ([System.Management.Automation.Language.TokenKind]::Try),
            ([System.Management.Automation.Language.TokenKind]::Catch),
            ([System.Management.Automation.Language.TokenKind]::Finally),
            ([System.Management.Automation.Language.TokenKind]::Function),
            ([System.Management.Automation.Language.TokenKind]::Begin),
            ([System.Management.Automation.Language.TokenKind]::Process),
            ([System.Management.Automation.Language.TokenKind]::End),
            ([System.Management.Automation.Language.TokenKind]::Enum),
            ([System.Management.Automation.Language.TokenKind]::DynamicParam),
            ([System.Management.Automation.Language.TokenKind]::Data),
            ([System.Management.Automation.Language.TokenKind]::Class),
            ([System.Management.Automation.Language.TokenKind]::Workflow),
            ([System.Management.Automation.Language.TokenKind]::InlineScript),
            ([System.Management.Automation.Language.TokenKind]::Trap),
            ([System.Management.Automation.Language.TokenKind]::Filter)
        )
    }

    Process {

        Try {

            If( $BopToken.Psobject.TypeNames -notcontains 'BeautyOfPower.BopToken') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            ForEach ($Tok In $BopToken) {

            # $Tok = Current Token !

                # is the current Token a Keyword witch must have a LCurly?
                If($KindToProcess -contains $Tok.Kind) {
                    $KeywordFound = $true
                    # remember Keyword Token to easely set frontspace to Lcurly Later
                    $KeywordTok = $Tok
                }

                # find out While loop or Do-While Loop ?
                If($Tok.Kind -eq ([System.Management.Automation.Language.TokenKind]::While)) {

                    Write-Verbose 'While found !'

                    $WhileBopAst = Get-BopAstFromToken -Token $Tok -AstTypeName 'WhileStatementAst'
                    If($Null -eq $WhileBopAst) {
                        Write-Verbose 'While is not a While Loop !'
                        $KeywordFound = $false
                        $KeywordTok = $null
                        Write-Output $Tok
                        Continue
                    }
                }

                # The Keyword opens a sequence (as Arry of token) the end is the LCurly
                # remember all Tokens (in between) this sequence (chronologic order)
                If ($KeywordFound) {
                    $Null = $TokenSequence.Add($Tok)
                }
                Else {
                    # no keyword opens a sequence
                    # return  current Token and Continue with next
                    Write-Output $Tok
                    Continue
                }

                # remember if there is a NewLine between Keyword and LCurly
                If($Tok.Kind -eq ([System.Management.Automation.Language.TokenKind]::NewLine)) {
                    $NewLineBetweenKeywordAndLCurly = $true
                }

                # Current Token is an LCurly this closes the sequence (Array)
                If($Tok.Kind -eq ([System.Management.Automation.Language.TokenKind]::LCurly)) {
                    $KeywordFound = $false

                    # user wish to have the LCurly on a new Line
                    # putting it direct under the keyword here
                    If ($LCurlyOnNewLine.IsPresent) {

                        # assure that the LCurly has the same amount of Spaces in front like the keyword
                        ForEach($SeqTok in $TokenSequence) {
                            If($SeqTok.Kind -eq ([System.Management.Automation.Language.TokenKind]::NewLine)) {
                               $SeqTok.PrefixSpaces = 0
                            }

                            # set LCurly PrefixSpaces to Keyword-Token PrefixSpaces
                            If($SeqTok.Kind -eq ([System.Management.Automation.Language.TokenKind]::LCurly)) {
                                If (-Not $NewLineBetweenKeywordAndLCurly) {
                                    # add newline and spaces in front of the LCurly
                                    $SeqTok.Surrogate = ([System.Environment]::NewLine) + (' ' * $KeywordTok.PrefixSpaces) + $SeqTok.Text
                                }
                                Else {
                                    $SeqTok.PrefixSpaces = $KeywordTok.PrefixSpaces
                                }
                            }
                        }
                    }
                    Else {

                    # user wish to have the LCurly on the same Line like the Keyword


                        # Begin Format LCurly on the same line as Keyword
                        # "One True Brace Style" variant to K&R
                        ForEach($SeqTok in $TokenSequence) {
                            # suppress new Lines
                            If($SeqTok.Kind -eq ([System.Management.Automation.Language.TokenKind]::NewLine)) {
                                $SeqTok.Surrogate = ''
                                $SeqTok.PrefixSpaces = 0
                            }

                            # LCurly has only 1 space in front
                            If($SeqTok.Kind -eq ([System.Management.Automation.Language.TokenKind]::LCurly)) {
                                $SeqTok.PrefixSpaces = 1
                            }
                        }
                        # End Format LCurly on the same line as Keyword
                    }

                    # output of the Token Sequence (chronologic order)
                    ForEach($SeqTok in $TokenSequence) {
                        Write-Output $SeqTok
                    }

                    # clean up the Token Sequence and init variables
                    $NewLineBetweenKeywordAndLCurly = $false
                    $Null = $TokenSequence.Clear()
                    $KeywordTok = $null
                }
            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }
}