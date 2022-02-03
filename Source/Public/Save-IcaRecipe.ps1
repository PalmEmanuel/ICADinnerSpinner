function Save-IcaRecipe {
    param (
        [Parameter(Mandatory)]
        [int[]]$Id
    )
    
    Test-IcaConnection

    $Body = @{
        'Recipes' = @($Id)
    } | ConvertTo-Json -Depth 10 -Compress

    Invoke-RestMethod "$script:BaseURL/user/recipes" @script:CommonParams -Method Post -Body $Body -ErrorAction Stop
}