function Get-IcaRecipeFilters {    
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/recipes/search/filters" @script:CommonParams | Select-Object -ExpandProperty categories
}