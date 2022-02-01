# Define a ValidateSetGenerator that gets the recipe categories
class IcaFilter : System.Management.Automation.IValidateSetValuesGenerator {
    [string[]] GetValidValues() {
        return (Get-IcaRecipeFilters).Options.Id | Select-Object -Unique
    }
}