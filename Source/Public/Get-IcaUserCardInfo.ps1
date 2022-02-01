function Get-IcaUserCardInfo {
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/user/cardaccounts" @script:CommonParams
}