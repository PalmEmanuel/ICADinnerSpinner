function Get-IcaRecipeCurrentRating {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [int[]]$Id
    )
    
    Test-IcaConnection

    $Body = @{
        'idn' = @(
            $Id
        )
    } | ConvertTo-Json -Compress

    Invoke-RestMethod "$script:BaseURL/recipes/ratings" @script:CommonParams -Method Post -Body $Body -ErrorAction Stop
}