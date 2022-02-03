function Get-IcaProductGroups {
    [CmdletBinding()]
    param (
        [datetime]$LastSyncTime = (Get-Date '2001-01-01')
    )
    
    Test-IcaConnection

    $LastSyncTimeString = $LastSyncTime.ToString('yyyy-MM-dd')

    Invoke-RestMethod "$script:BaseURL/articles/articlegroups?lastsyncdate=$LastSyncTimeString" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty ArticleGroups
}