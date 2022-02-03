function New-IcaShoppingList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter()]
        [int64]$StoreId = 0
    )

    Test-IcaConnection

    $OfflineId = (New-Guid).Guid

    $Body = @{
        'OfflineId'    = $OfflineId
        'Title'        = $Name
        'CommentText'  = ''
        'SortingStore' = $StoreId
        'Rows'         = @()
        'LatestChange' = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
    } | ConvertTo-Json -Compress

    $null = Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists" @script:CommonParams -Method Post -Body $Body -ErrorAction Stop
    return $OfflineId
}