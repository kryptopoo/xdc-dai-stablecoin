#!/usr/bin/env bash

# setting 
read -p 'network: ' network
read -p 'withdraw XDC amount: ' xdcAmount
read -p 'payback DAI amount: ' daiAmount

eval $(source $network.setup-env.sh)
eval $(jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' ./$network.addresses.json)

echo "Acount $ETH_FROM withdraw $xdcAmount XDC and payback $daiAmount DAI..."

export wad=$(seth --to-uint256 $(seth --to-wei $daiAmount eth))
export cdpId=$(seth --to-dec $(seth call $CDP_MANAGER 'last(address)' $ETH_FROM))
export urn=$(seth call $CDP_MANAGER 'urns(uint)(address)' $cdpId)
echo "wad: $wad, cdpId: $cdpId , urn: $urn"

# Approve $MCD_JOIN_DAI to withdraw $wad DAI from $MCD_DAI
echo "approve MCD_JOIN_DAI to withdraw DAI from MCD_DAI"
seth send $MCD_DAI 'approve(address,uint256)' $MCD_JOIN_DAI $wad

# Add Dai back to the MCD_JOIN_DAI adapter.
echo "add Dai back to the MCD_JOIN_DAI adapter"
seth send $MCD_JOIN_DAI 'join(address,uint256)' $urn $wad

# Pay back your Dai debt and unlock your collateral. 
export minusDaiHex=$(mcd --to-hex $(seth --to-wei -$daiAmount eth))
export minusXdcHex=$(mcd --to-hex $(seth --to-wei -$xdcAmount eth))
export dink=$(seth --to-uint256 $minusXdcHex)
export dart=$(seth --to-uint256 $minusDaiHex)
# echo "dink: $dink , dart: $dart"

# pay back Dai and unlock collateral
echo "pay back Dai and unlock collateral"
seth send $CDP_MANAGER "frob(uint256,int256,int256)" $cdpId $dink $dart

# move collateral to your own account
echo "move collateral to your own account"
seth send $CDP_MANAGER 'flux(uint256,address,uint256)' $cdpId $ETH_FROM $(seth --to-uint256 $(seth --to-wei $xdcAmount eth))

# call the exit function to withdraw
echo "call the exit function to withdraw"
seth send $MCD_JOIN_XDC_A 'exit(address,uint)' $ETH_FROM $(seth --to-uint256 $(seth --to-wei $xdcAmount eth))

# unwrap your XDC from the $WXDC contract
echo "unwrap your XDC from the WXDC contract"
seth send $XDC 'withdraw(uint)' $(seth --to-uint256 $(seth --to-wei $xdcAmount eth))

# check your account balance again and see that your XDC is back.
echo "Successfully payback DAI"
balance=$(seth balance $ETH_FROM) 
echo "Your balance: $balance XDC"