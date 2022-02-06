function Get-IcaUserStoreExperience {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$StoreId,

        [Parameter(DontShow)]
        [int]$Version = 2
    )

    Test-IcaConnection

    $Result = Invoke-RestMethod "$script:BaseURL/start?storeid=$StoreId&version=$Version" @script:CommonParams -ErrorAction Stop | Select-Object -ExpandProperty Cards

    $Result | ForEach-Object -Begin {
        $Hash = @{}
    } -Process {
        $PropertyName = $_ | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
        $Hash[$PropertyName] = $_.$PropertyName
    } -End {
        [pscustomobject]$Hash
    }
}