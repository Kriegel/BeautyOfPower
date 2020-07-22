Function New-BopLanguageToken {

    Param(
        $Token
    )

    Process {
        
        [Object[]]$Arguments = $Token.Extent,$Token.Kind,$Token.TokenFlags
        $Token.GetType().Assembly.CreateInstance(($Token.GetType().Fullname), $false,[System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic,$null, $Arguments, $null, $null)
    }
}