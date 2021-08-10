# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
#Read Token
$token = Get-Content -Path .\token.txt
$token = "enctoken " + $token

$strikeData = $(Get-Content -Path .\algo2.json | ConvertFrom-Json).data

$index = "BANKNIFTY"
$expPrefix = '21708'

$scrips = @()
FOREACH($item in $strikeData){
    $tmpScrip = $index + $expPrefix+ $item.Strike + $item.Type
    $scrips = $scrips+$tmpScrip
}


class strategyModel{
    $Symbol
    $SellPrice
    $LTP
    $BuyPrice
    $PnL  
    $isActive    
}
$algoModelList = New-Object 'System.Collections.Generic.List[strategyModel]'

FOREACH($item in $scrips){
    $uri = "https://api.kite.trade/quote/ltp?i=NFO:" + $item
    $datum = Invoke-WebRequest -Uri $uri -Headers @{"authorization"=$token}
    $LtpData =  $($datum.Content | ConvertFrom-Json).data
    $Ltp = $LtpData.psobject.properties.value.last_price

    $tmpObject = New-Object strategyModel
        $tmpObject.Symbol = $item
        $tmpObject.SellPrice = $Ltp
        $tmpObject.LTP = $Ltp
        $tmpObject.BuyPrice = 
        $tmpObject.PnL = 0
        $tmpObject.isActive = $True

    $algoModelList.Add($tmpObject)
}

$strategy = @{"status" = "Active";"data" = $algoModelList}
$strategy | ConvertTo-Json  | Out-File "algo2-positions.json"
