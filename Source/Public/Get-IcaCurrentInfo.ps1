function Get-IcaCurrentInfo {
    Test-IcaTicket

    Invoke-RestMethod "$script:BaseURL/info/urgent" @script:CommonParams
}