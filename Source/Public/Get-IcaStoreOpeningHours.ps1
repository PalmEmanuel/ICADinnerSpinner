function Get-IcaStoreOpeningHours {
    Test-IcaConnection
    
    Invoke-RestMethod "$script:BaseURL/stores/openinghours" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Stores
}