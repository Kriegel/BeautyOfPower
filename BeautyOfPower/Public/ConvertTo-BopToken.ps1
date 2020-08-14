Function ConvertTo-BopToken {
<#
.SYNOPSIS
    Creates an flat clone from 'System.Management.Automation.Language.Token' Token Types and
    puts each processed Token in an returned Array.

.DESCRIPTION
    Creates an flat clone from 'System.Management.Automation.Language.Token' Token Types and
    puts each processed Token in an returned Array.

    Because some Operations need to process on the whole array of Tokens this
    function returns the Array of processed Tokens at the end {} block of pipeline processing.


    Main (useful) Properties of each custom Object in the resulting Array are:

    Property 'Surrogate'
    --------------------

    (DO NOT CHANGE THE ORIGIN TEXT FIELD !!!)
    The Property 'Surrogate' is the place to make changes to the Token Text

    On creation initialisation the Property 'Surrogate' receives an copy of the Token Text

    Property 'PrefixSpaces'
    --------------------

    If you provide an Array of Tokens to this Function (a TokenStream)
    This Function calculates the number of Space between 2 Tokens

    The Property 'PrefixSpaces' holds the Number (for Spaces) to add in front of the Text or Surrogate.

    you can use the following pseudo code to create the Text with spaces

    (' ' * $Token.PrefixSpaces) + $Token.Text
    # or
    (' ' * $Token.PrefixSpaces) + $Token.Surrogate

    If you prefer Tab instead of Spaces you have to do more processing work on your own. (sorry)


    Property 'CounterPieceIndex'
    --------------------

    index position in an array of Tokens of (brace, quotation mark) counter piece

    Property 'NestingDepth'
    --------------------

    nesting depth of brace or quotation mark (can be used to ident)

    Hint !
    ---------------

    If you provide an Array of Tokens to this Function (a TokenStream)
    you can simply write out the Tokens to a File one after another at the end of the processing Pipeline.
    If nothing in the Pipeline changes the order of the Array, the Script is written properly
    (use the String out of the (changed) Surrogate not the Text property!)

    Example Code at the end of the Pipeline:

    Add-Content -Path 'C:\temp\Beauty-Code.ps1' -Value ((' ' * $Token.PrefixSpaces)  + $Token.Surrogate) -NoNewline


    Why this Function ?
    -------------------

    .NET allows not to Instantiate custom Tokens and
    most of the Properties (Fields) of the .Net Token Class members are not edit able.

    Even the .Net Token Types having deep nestet members.

    A single PowerShell script can have a great amount of Tokens, tokens are delivered in an Array bag.
    This can have a high memory consuption.

    So for simpleness, memory and speed reasons
    this Function creates an flat clone from 'System.Management.Automation.Language.Token' Token Types

.NOTES

    Author: Peter Kriegel

    TODO: At the end of development, make this a .NET Class to protect some Properties from change

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
        [PsObject]$BopTokenAndAst

    )

    Begin {
        $MyCommandName = $PSCmdlet.MyInvocation.MyCommand.Name

        $ResultArray = [System.Collections.ArrayList]@()

        # helper Variable to calculate the number of spaces between 2 Tokens
        $EndOffsetPreceding = -1

        # Create Stacks to Push and Pop CounterPiece Objects
        # TODO: quotation marks are not processed yet
        $CurlyStack = New-Object System.Collections.Stack
        $ParenStack = New-Object System.Collections.Stack
        $BracketStack = New-Object System.Collections.Stack

        # variables to track the nesting level of braces (TODO: or quotation marks)
        $LCurlyNestingDepth = 0
        $LParenNestingDepth = 0
        $LBracketNestingDepth = 0

    }

    Process {

        Try {

            # check if we are processing an BopTokenAndAst custom object
            If( $BopTokenAndAst.Psobject.TypeNames -notcontains 'BeautyOfPower.BopTokenAndAst') {
                Throw "$MyCommandName; Parameter -BopToken has wrong Type!"
            }

            # count the index of the Tokens in array
            # used to fill the CounterPieceIndex; position of (brace, quotation mark) counter piece
            [Uint32]$IndexCounter = 0

            ForEach ($Tok in $BopTokenAndAst.Tokens) {

                # calculate the Number of spaces between current Token and predecessor Token
                # ($EndOffsetPreceding -gt -1) ensure to not process the very first Token
                If(($EndOffsetPreceding -gt -1) -and ($Tok.Extent.StartOffset -gt $EndOffsetPreceding)) {
                    $PrefixSpaces = $Tok.Extent.StartOffset - $EndOffsetpreceding
                }
                Else {
                    $PrefixSpaces = 0
                }

                # most Properties are commented to enable it later if needed
                # the Properties are aggregated from the different .NET Token Types (one Object fits all approach)
                $ResultObject =  ([PSCustomObject]@{
                    Name = $BopTokenAndAst.Name
                    Path = $BopTokenAndAst.Filepath
                    RootAst = $BopTokenAndAst.Ast
                    TypeName = $Tok.GetType().Fullname # Typename of the .NET Token we are comming from
                    Text = $Tok.Text
                    Surrogate = $Tok.Text
                    TokenFlags = $Tok.TokenFlags
                    Kind = $Tok.Kind
                    #StartLineNumber = $Tok.Extent.StartLineNumber
                    #StartColumnNumber = $Tok.Extent.StartColumnNumber
                    #EndLineNumber = $Tok.Extent.EndLineNumber
                    #EndColumnNumber = $Tok.Extent.EndColumnNumber
                    StartOffset = $Tok.Extent.StartOffset # used to find the corresponding AST (see: Get-BopAstFromToken)
                    #EndOffset = $Tok.Extent.EndOffset
                    #HasError = $Tok.HasError
                    #NestedTokens = $Tok.NestedTokens
                    #LabelText = $Tok.LabelText
                    #ParameterName = $Tok.ParameterName
                    UsedColon = $Tok.UsedColon
                    #Append = $Tok.Append
                    #FromStream = $Tok.FromStream
                    #Name = $Tok.Name
                    #ToStream = $Tok.ToStream
                    #Value = $Tok.Value
                    #VariablePath = $Tok.VariablePath
                    PrefixSpaces = $PrefixSpaces # Number of Spaces to put in front of this Token Text
                    CounterPieceIndex = -1 # index position of (brace, quotation mark) counter piece
                    NestingDepth = 0 # nesting depth of brace or quotation mark
                    PsTypeName = 'BeautyOfPower.BopToken'
                })

                # Use the stacks to push and pop braces and
                # to find the counter piece Index of the brace in the Token Array

                If (($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::LCurly) -or ($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::AtCurly)){

                    # push my LCurly Array Index position to the stack
                    Write-Verbose "Pushing LCurly or AtCurly $($Tok.Text)"
                    $CurlyStack.Push($IndexCounter)

                    $ResultObject.NestingDepth = $LCurlyNestingDepth

                    $LCurlyNestingDepth++

                }

                If (($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::LParen) -or ($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::AtParen) -or ($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::DollarParen)){

                    # push my LParen Array Index position to the stack
                    Write-Verbose "Pushing LParen or AtParen or DollarParen $($Tok.Text)"
                    $ParenStack.Push($IndexCounter)

                    $ResultObject.NestingDepth = $LParenNestingDepth

                    $LParenNestingDepth++

                }

                If (($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::LBracket)) {

                    # push my LBracket Array Index position to the stack
                    Write-Verbose "Pushing LBracket $($Tok.Text)"
                    $BracketStack.Push($IndexCounter)

                    $ResultObject.NestingDepth = $LBracketNestingDepth

                    $LBracketNestingDepth++

                }


                If ($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::RCurly){

                    $LCurlyNestingDepth--

                    # the Stack holds the correct Array Index to the counter piece
                    Write-Verbose "Popping RCurly $($Tok.Text)"
                    [Uint32]$CounterPieceIndex = $CurlyStack.Pop()

                    # writing data to current Token
                    $ResultObject.CounterPieceIndex = $CounterPieceIndex
                    $ResultObject.NestingDepth = $LCurlyNestingDepth

                    # writing data to predecessor counter piece Token
                    ($ResultArray[($CounterPieceIndex)]).CounterPieceIndex = $IndexCounter

                }


                If ($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::RParen){

                    $LParenNestingDepth--

                    # the Stack holds the correct Array Index to the counter piece
                    Write-Verbose "Popping RParen $($Tok.Text)"
                    [Uint32]$CounterPieceIndex = $ParenStack.Pop()

                    $ResultObject.CounterPieceIndex = $CounterPieceIndex
                    $ResultObject.NestingDepth = $LParenNestingDepth

                    # writing data to predecessor counter piece Token
                    ($ResultArray[($CounterPieceIndex)]).CounterPieceIndex = $IndexCounter

                }

                If (($Tok.Kind -eq [System.Management.Automation.Language.TokenKind]::RBracket)) {

                    $LBracketNestingDepth--

                    # push my LBracket Array Index position to the stack
                    Write-Verbose "Popping RBracket $($Tok.Text)"
                    [Uint32]$CounterPieceIndex = $BracketStack.Pop()

                    $ResultObject.CounterPieceIndex = $CounterPieceIndex
                    $ResultObject.NestingDepth = $LBracketNestingDepth

                    # writing data to predecessor counter piece Token
                    ($ResultArray[($CounterPieceIndex)]).CounterPieceIndex = $IndexCounter

                }

                $IndexCounter = $ResultArray.Add($ResultObject)

                $EndOffsetPreceding = $Tok.Extent.EndOffset

                $IndexCounter++

            }
        }
        Catch {
            Write-Error -ErrorRecord $_
        }
    }

    End {

        Write-Output $ResultArray
    }
}