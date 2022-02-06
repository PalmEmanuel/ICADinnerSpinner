function Test-IcaAuthToken {
    Test-IcaConnection
    
    Invoke-RestMethod "$script:BaseURL/login/expiresWhen" @script:CommonParams -ErrorAction Stop
}