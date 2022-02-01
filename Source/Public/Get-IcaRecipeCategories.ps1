function Get-IcaRecipeCategories {
    Test-IcaTicket

    # Invoke-RestMethod "$script:BaseURL/recipes/categories/general" @script:CommonParams | Select-Object -ExpandProperty Categories
    Invoke-RestMethod "$script:BaseURL/recipes/categories/puff?includeWeeklyMixCategory=true" @script:CommonParams | Select-Object -ExpandProperty Categories
}