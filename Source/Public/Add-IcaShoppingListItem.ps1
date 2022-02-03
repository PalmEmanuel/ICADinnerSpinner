function Add-IcaShoppingListItem {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline = $true, ParameterSetName = 'Name')]
        [Parameter(Mandatory, ValueFromPipeline = $true, ParameterSetName = 'Product')]
        [string]$ListOfflineId,

        [Parameter(Mandatory, ValueFromPipeline = $true, ParameterSetName = 'Name')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ProductName,

        [Parameter(Mandatory, ValueFromPipeline = $true, ParameterSetName = 'Product')]
        [ValidateNotNullOrEmpty()]
        [IcaProduct[]]$Product
    )

    Test-IcaConnection

    switch ($PSCmdlet.ParameterSetName) {
        'Name' {
            $CreatedRows = @(
                $ProductName | ForEach-Object {
                    @{
                        'ProductName'   = $_
                        'IsStrikedOver' = $false
                    }
                }
            )
        }
        'Product' {
            $CreatedRows = @(
                $Product
            )
        }
    }
    
    $Body = @{
        'ChangedShoppingListProperties' = @{}
        'CreatedRows' = $CreatedRows
        'ChangedRows' = @()
        'DeletedRows' = @()

    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId/sync" @script:CommonParams -Method Post -Body $Body -ErrorAction Stop
}