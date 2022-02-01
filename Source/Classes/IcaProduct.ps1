class IcaProductRecipeReference {
    [int]$Id # Id of the recipe
    
    [double]$Quantity
    
    [ValidateNotNullOrEmpty()]
    [string]$Unit

    IcaProductRecipeReference(
        [int]$Id, 
        [double]$Quantity,
        [string]$Unit
    ) {
        $this.Id = $Id
        $this.Quantity = $Quantity
        $this.Unit = $Unit
    }
}

class IcaProduct {
    [int]$InternalOrder # -1..-$Count

    [ValidateNotNullOrEmpty()]
    [string]$ProductName

    [bool]$IsStrikedOver

    [double]$Quantity
    
    [int]$SourceId
    
    [int]$ArticleGroupId
    
    [int]$ArticleGroupIdExtended
    
    [ValidateNotNullOrEmpty()]
    [IcaProductRecipeReference[]]$Recipes
    
    [ValidateNotNullOrEmpty()]
    [string]$Unit
    
    [ValidateNotNullOrEmpty()]
    [string]$LatestChange # yyyy-MM-ddTHH:mm:ssZ
    
    [guid]$OfflineId # guid

    IcaProduct(
        [int]$InternalOrder,
        [string]$ProductName,
        [bool]$IsStrikedOver,
        [double]$Quantity,
        [int]$SourceId,
        [int]$ArticleGroupId,
        [int]$ArticleGroupIdExtended,
        [IcaProductRecipeReference[]]$Recipes,
        [string]$Unit,
        [string]$LatestChange, # yyyy-MM-ddTHH:mm:ssZ
        [guid]$OfflineId # guid
    ) {
        $this.InternalOrder = $InternalOrder
        $this.ProductName = $ProductName
        $this.IsStrikedOver = $IsStrikedOver
        $this.Quantity = $Quantity
        $this.SourceId = $SourceId
        $this.ArticleGroupId = $ArticleGroupId
        $this.ArticleGroupIdExtended = $ArticleGroupIdExtended
        $this.Recipes = $Recipes
        $this.Unit = $Unit
        $this.LatestChange = $LatestChange
        $this.OfflineId = $OfflineId
    }
}