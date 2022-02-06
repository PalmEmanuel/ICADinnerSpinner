function Add-IcaStore {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int]$StoreId
    )

    Test-IcaConnection

    $Body = @{
        'Store' = $StoreId
    } | ConvertTo-Json

    Invoke-RestMethod "$script:BaseURL/user/stores" @script:CommonParams -Method Post -Body $Body -ErrorAction Stop
}