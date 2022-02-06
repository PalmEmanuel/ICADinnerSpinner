function Get-IcaUserAuthInfo {
    Test-IcaConnection

    Invoke-RestMethod "$script:BaseURL/customer/ids" @script:CommonParams -ErrorAction Stop
}