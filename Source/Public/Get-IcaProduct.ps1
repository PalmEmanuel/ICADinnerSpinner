function Get-IcaProduct {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'All', DontShow)]
        [datetime]$LastSyncDate = (Get-Date '2001-01-01'),

        [Parameter(Mandatory, ParameterSetName = 'UPC', ValueFromPipeline = $true)]
        [int64[]]$UPCCode
    )
    
    Test-IcaConnection

    $LastSyncTimeString = $LastSyncDate.ToString('yyyy-MM-dd')

    switch ($PSCmdlet.ParameterSetName) {
        'All' {
            Invoke-RestMethod "$script:BaseURL/articles/articles?lastsyncdate=$LastSyncTimeString" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Articles
        }
        'UPC' {
            Invoke-RestMethod "$script:BaseURL/upclookup?upc=$($UPCCode -join ',')" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Items
        }
    }
}