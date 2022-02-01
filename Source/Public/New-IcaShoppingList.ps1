function New-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter()]
        [int64]$StoreId = 0
    )

    Test-IcaTicket

    $OfflineId = (New-Guid).Guid

    $Body = @{
        'Title'        = $Name
        'OfflineId'    = $OfflineId
        'SortingStore' = $StoreId
        'Rows'         = @()
        'LatestChange' = Get-Date -Format 'yyyy-MM-ddThh:mm:ssZ'
    }

    $null = Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists" @script:CommonParams -Method Post -Body $Body
    return $OfflineId
}