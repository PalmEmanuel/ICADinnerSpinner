function Remove-IcaRecipe {
    param (
        [Parameter(Mandatory)]
        [int[]]$Id
    )
    
    Test-IcaTicket

    Invoke-RestMethod "$script:BaseURL/user/recipes?recipes=$($Id -join ',')" @script:CommonParams -Method Delete
}