# Input bindings are passed in via param block.
param($Timer)

# Get the current universal time in the default string format.
#Read Token
$token = Get-Content -Path .\token.txt
$token = "enctoken " + $token

$today = Get-Date -Format "yyyy-MM-dd"

#Get ATM

$tickerUri = "https://quotes-api.tickertape.in/quotes?sids=.NSEBANK"  #.NSEI for NIFTY50
$tickerReq =  Invoke-WebRequest -Uri $tickerUri
$tickerPrice = $(($tickerReq.Content | ConvertFrom-Json).data).price
$strike = ([math]::Round( $tickerPrice/100))*100
echo $strike

$expPrefix = '21701'
$index = 'BANKNIFTY'

$ce1 = $strike + 300
$ce2 = $strike + 400
$ce3 = $strike + 500
$pe1 = $strike - 300
$pe2 = $strike - 400
$pe3 = $strike - 500


$ceStrike1 = $index + $expPrefix + [string]$ce1 + 'CE'
$ceStrike2 = $index + $expPrefix + [string]$ce2 + 'CE'
$ceStrike3 = $index + $expPrefix + [string]$ce3 + 'CE'
$peStrike1 = $index + $expPrefix + [string]$pe1 + 'PE'
$peStrike2 = $index + $expPrefix + [string]$pe2 + 'PE'
$peStrike3 = $index + $expPrefix + [string]$pe3 + 'PE'


$scrips = @($ceStrike1,$ceStrike2,$ceStrike3,$peStrike1,$peStrike2,$peStrike3)


class strategyModel{
    $Symbol
    $SellPrice
    $LTP
    $StopLoss
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
        $tmpObject.StopLoss = [math]::Round(($Ltp * 1.33),2)
        $tmpObject.BuyPrice = 0
        $tmpObject.PnL = 0
        $tmpObject.isActive = $True

        $algoModelList.Add($tmpObject)
}

#$algoModelList | ConvertTo-Json  | Out-File "positions.json"

$strategy = @{"status" = "Active";"data" = $algoModelList}
$strategy | ConvertTo-Json  | Out-File "algo3-positions.json"



#Get Quote from Kite
#$uri = "https://api.kite.trade/quote/ltp?i=NFO:BANKNIFTY2170135000CE"
#$datum = Invoke-WebRequest -Uri $uri -Headers @{"authorization"=$token}
#$LtpData =  $($datum.Content | ConvertFrom-Json).data
#$Ltp = $LtpData.psobject.properties.value.last_price
