function Get-IcaStoreOffers {
    param (
        [Parameter(Mandatory)]
        [string[]]$StoreId
    )
    
    Test-IcaConnection
    
    Invoke-RestMethod "$script:BaseURL/offers?Stores=$($StoreId -join ',')" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Offers
}