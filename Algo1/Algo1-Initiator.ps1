# Input bindings are passed in via param block.
param($Timer)

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

$options = @('CE','PE')
$expPrefix = '21701'
$index = 'BANKNIFTY'

$scrips = @()
FOREACH($item in $options){
    $tmpScrip = $index+$expPrefix+$strike+$item
    $scrips = $scrips+$tmpScrip
}

class strategyModel{
    $Symbol
    #$ScripToken
    $SellPrice
    $LTP
    $StopLoss
    $BuyPrice
    $PnL  
    $isActive
    
}
$algoModelList = New-Object 'System.Collections.Generic.List[strategyModel]'

#create sell orders
$slLegs = @(1.23,1.46,1.69)

FOREACH($item in $scrips){
    #$ins_token = $($mylist | Where-Object tradingsymbol -EQ $item).instrument_token
    $uri = "https://api.kite.trade/quote/ltp?i=NFO:" + $item
    $datum = Invoke-WebRequest -Uri $uri -Headers @{"authorization"=$token}
    $LtpData =  $($datum.Content | ConvertFrom-Json).data
    $Ltp = $LtpData.psobject.properties.value.last_price
    FOREACH($legs in $slLegs){
        $tmpObject = New-Object strategyModel
        $tmpObject.Symbol = $item
        #$tmpObject.ScripToken = $ins_token
        $tmpObject.SellPrice = $Ltp
        $tmpObject.LTP = $Ltp
        $tmpObject.StopLoss = [math]::Round(($Ltp * $legs),2)
        $tmpObject.BuyPrice = 
        $tmpObject.PnL = 0
        $tmpObject.isActive = $True

        $algoModelList.Add($tmpObject)
    }
}

#$algoModelList | ConvertTo-Json  | Out-File "positions.json"

$strategy = @{"status" = "Active";"data" = $algoModelList}
$strategy | ConvertTo-Json  | Out-File "positions.json"

