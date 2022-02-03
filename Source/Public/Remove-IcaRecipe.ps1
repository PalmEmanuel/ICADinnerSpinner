function Remove-IcaRecipe {
    param (
        [Parameter(Mandatory)]
        [int[]]$Id
    )
    
    Test-IcaConnection

    Invoke-RestMethod "$script:BaseURL/user/recipes?recipes=$($Id -join ',')" @script:CommonParams -Method Delete -ErrorAction Stop
}