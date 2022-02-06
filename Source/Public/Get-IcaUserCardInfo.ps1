function Get-IcaUserCardInfo {
    Test-IcaConnection
    
    Invoke-RestMethod "$script:BaseURL/user/cardaccountswithbalance?version=2" @script:CommonParams -ErrorAction Stop
}