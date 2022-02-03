function Get-IcaRecipeCategories {
    Test-IcaConnection

    # Invoke-RestMethod "$script:BaseURL/recipes/categories/general" @script:CommonParams | Select-Object -ExpandProperty Categories
    Invoke-RestMethod "$script:BaseURL/recipes/categories/puff?includeWeeklyMixCategory=true" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Categories
}