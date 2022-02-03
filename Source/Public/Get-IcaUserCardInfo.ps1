function Get-IcaUserCardInfo {
    Test-IcaConnection
    
    Invoke-RestMethod "$script:BaseURL/user/cardaccounts" @script:CommonParams -ErrorAction Stop
}