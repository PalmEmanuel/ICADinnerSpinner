function Get-IcaCurrentInfo {
    Test-IcaConnection

    Invoke-RestMethod "$script:BaseURL/info/urgent" @script:CommonParams -ErrorAction Stop
}