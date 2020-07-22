. $PsScriptroot\Expand-PSOneToken.ps1
. $PsScriptroot\Get-PSOneToken.ps1

$TestFilePath = 'C:\temp\Out-Tesfile.ps1'
Remove-Item $TestFilePath -confirm:$False -ErrorAction 'ignore' 
New-Item $TestFilePath -ItemType File -Force

$EndOffsetpreceding = 0


#######################################
# Testing 
#  System.Collections.ArrayList vs. [System.Collections.Generic.List[Object]]
#  ArrayList winns!
#######################################


Measure-Command -Expression {
    
    $ArrayList = [System.Collections.ArrayList]@() # TotalMilliseconds : 18774,244
    
    #$List = [System.Collections.Generic.List[Object]]@() # TotalMilliseconds : 27513,277
    #[Func[Object,bool]]$delegate = { param($ListToken); return $ListToken.Text -Like '*Item' }
#$ParsePath = 'a:\PowerShell-Code\AST\PsOne\ParseMe.ps1' # Parse Edit File
$ParsePath = 'A:\PowerShell-Code\AST\PSScripts-to-Test\Microsoft.PowerShell.ODataUtilsHelper.ps1' # medium size File
#$ParsePath = 'A:\PowerShell-Code\AST\PSScripts-to-Test\PowerShellCookbook.psm1' # Large size File
(Get-PSOneToken -Path $ParsePath ).Tokens  | ForEach-Object {  # TotalMilliseconds : 360,6852
    $Token = $_

    $MyToken = [PSCustomObject] @{
        TokenType = $Token.GetType().Fullname
        Text = $Token.Text
        ExtentText = $Token.Extent.Text
        TokenFlags = $Token.TokenFlags
        Kind = $Token.Kind
        StartLineNumber = $Token.Extent.StartLineNumber
        StartColumnNumber = $Token.Extent.StartColumnNumber
        EndLineNumber = $Token.Extent.EndLineNumber
        EndColumnNumber = $Token.Extent.EndColumnNumber
        StartOffset = $Token.Extent.StartOffset
        EndOffset = $Token.Extent.EndOffset
        HasError = $Token.HasError
        NestedTokens = $Token.NestedTokens
        LabelText = $Token.LabelText
        ParameterName = $Token.ParameterName
        UsedColon = $Token.UsedColon
        Append = $Token.Append
        FromStream = $Token.FromStream
        Name = $Token.Name
        ToStream = $Token.ToStream
        Value = $Token.Value
        VariablePath = $Token.VariablePath
        PrefixSpaces = $Token.Extent.StartOffset - $EndOffsetpreceding
    }
    
    $EndOffsetpreceding = $Token.Extent.EndOffset
    
    #Add-Content -Path $TestFilePath -Value ((' ' * $MyToken.PrefixSpaces)  + $MyToken.Text) -NoNewline

    #$null = $List.Add($MyToken)
    $Null = $ArrayList.Add($MyToken)

    $ArrayList.Where({$_.Text -like '*Item'  })
    
    
   #[Linq.Enumerable]::Where($List, $delegate)


}
}

# Notepad.exe $TestFilePath