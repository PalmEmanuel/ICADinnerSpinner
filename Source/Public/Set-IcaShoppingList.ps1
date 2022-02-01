# Get input list, make a diff check and compose a body with created, changed and deleted rows
# function Set-IcaShoppingList {
#     [CmdletBinding()]
#     param (
#         [Parameter(Mandatory, ValueFromPipeline = $true)]
#         [string]$ListOfflineId,

#         [Parameter(ValueFromPipeline = $true)]
#         [string]$Name
#     )

#     Test-IcaTicket
    
#     $script:Headers = @{
#         'AuthenticationTicket' = $Ticket
#     }

#     $Body = @{
#         'ChangedShoppingListProperties' = @{
#             'Title'        = $Name
#             'LatestChange' = Get-Date -Format 'yyyy-MM-ddThh:mm:ssZ'
#         }
#         'CreatedRows'                   = @()
#         'ChangedRows'                   = @()
#         'DeletedRows'                   = @()
#     } | ConvertTo-Json -Depth 10 -Compress

#     Invoke-RestMethod "$script:BaseURL/user/offlineshoppinglists/$ListOfflineId/sync" @script:CommonParams -Method Post -Body $Body
# }