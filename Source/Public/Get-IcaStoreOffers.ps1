function Get-IcaStoreOffers {
    param (
        [Parameter(Mandatory)]
        [string[]]$StoreId
    )
    
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/offers?Stores=$($StoreId -join ',')" @script:CommonParams
}