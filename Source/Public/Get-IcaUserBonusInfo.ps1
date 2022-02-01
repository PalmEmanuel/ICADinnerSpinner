function Get-IcaUserBonusInfo {    
    Test-IcaTicket
    
    Invoke-RestMethod "$script:BaseURL/user/minbonustransaction" @script:CommonParams | Select-Object -ExpandProperty TransactionSummaryByMonth
}