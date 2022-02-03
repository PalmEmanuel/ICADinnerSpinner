function Get-IcaRecipeFilters {    
    Test-IcaConnection
    
    Invoke-RestMethod "$script:BaseURL/recipes/search/filters" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty categories
}