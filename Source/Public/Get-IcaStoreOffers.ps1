function Get-IcaStoreOffers {
    param (
        [Parameter(Mandatory, ParameterSetName = "StoreId")]
        [Parameter(Mandatory, ParameterSetName = "OfferId")]
        [string[]]$StoreId,
        
        [Parameter(Mandatory, ParameterSetName = "OfferId")]
        [string[]]$OfferId
    )
    
    Test-IcaConnection

    switch ($PSCmdlet.ParameterSetName) {
        'StoreId' {
            Invoke-RestMethod "$script:BaseURL/offers?Stores=$($StoreId -join ',')" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Offers
        }
        'OfferId' {
            Invoke-RestMethod "$script:BaseURL/offers/search?offerids=$($OfferId -join ',')&includeValidityForStores=$($StoreId -join ',')" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Offers
        }
    }
}