function Get-IcaProduct {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(Mandatory, ParameterSetName = 'UPC', ValueFromPipeline = $true)]
        [int64[]]$UPCCode
    )
    
    Test-IcaTicket

    $LastSyncTimeString = $LastSyncTime.ToString('yyyy-MM-dd')

    switch ($PSCmdlet.ParameterSetName) {
        'All' {
            Invoke-RestMethod "$script:BaseURL/articles/articles?lastsyncdate=$LastSyncTimeString" @script:CommonParams | Select-Object -ExpandProperty Articles
        }
        'UPC' {
            Invoke-RestMethod "$script:BaseURL/upclookup?upc=$($UPCCode -join ',')" @script:CommonParams
        }
    }
}