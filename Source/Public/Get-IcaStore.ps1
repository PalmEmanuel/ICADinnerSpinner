function Get-IcaStore {
    param (
        [Parameter(Mandatory, ParameterSetName = 'Id', ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [int]$Id,

        [Parameter(Mandatory, ParameterSetName = 'String')]
        [ValidateNotNullOrEmpty()]
        [string]$SearchString,

        [Parameter(Mandatory, ParameterSetName = 'SyncTime')]
        [ValidateNotNullOrEmpty()]
        [datetime]$LastSyncTime,
        
        [Parameter(Mandatory, ParameterSetName = 'User')]
        [ValidateNotNullOrEmpty()]
        [switch]$FromUser
    )
    
    Test-IcaTicket
    
    switch ($PSCmdlet.ParameterSetName) {
        'Id' {
            Invoke-RestMethod "$script:BaseURL/stores/$Id" @script:CommonParams
        }
        'String' {
            Invoke-RestMethod "$script:BaseURL/stores/search?Filters&Phrase=$SearchString" @script:CommonParams
        }
        'SyncTime' {
            Invoke-RestMethod "$script:BaseURL/stores/?LastSyncDate=$($LastSyncTime.ToString('yyyy-MM-dd'))" @script:CommonParams
        }
        'User' {
            Invoke-RestMethod "$script:BaseURL/user/stores" @script:CommonParams
        }
    }
}