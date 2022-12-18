#!/usr/bin/env bash

# setting 
read -p 'network: ' network
read -p 'deposit XDC amount: ' xdcAmount
read -p 'generate DAI amount: ' daiAmount

eval $(source $network.setup-env.sh)
eval $(jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]' ./$network.addresses.json)

# export xdcAmount=100;
# export daiAmount=1;
echo "Acount $ETH_FROM deposit $xdcAmount XDC to generate $daiAmount DAI..."

export ilk=$(seth --to-bytes32 "$(seth --from-ascii "XDC-A")")
echo "ilk: $ilk"

#  open the Vault using the CDP Manager
echo "open vault..."
seth send -F $ETH_FROM $CDP_MANAGER 'open(bytes32,address)' "$ilk" "$ETH_FROM"

# determine the Id and urn address of the vault
export cdpId=$(seth --to-dec $(seth call $CDP_MANAGER 'last(address)' $ETH_FROM))
export urn=$(seth call $CDP_MANAGER 'urns(uint)(address)' $cdpId)
echo "cdpId: $cdpId , urn: $urn"

# deposit XDC into the WXDC adapter:
echo "deposit $xdcAmount XDC into the WXDC adapter..."
seth send $XDC 'deposit()' --value $(seth --to-wei $xdcAmount ETH)

#  approve MCD_JOIN_XDC_A to withdraw some WXDC:
echo "approve MCD_JOIN_XDC_A to withdraw some WETH..."
seth send $XDC 'approve(address,uint256)' $MCD_JOIN_XDC_A $(seth --to-uint256 $(seth --to-wei $xdcAmount ETH))

# lock ethers into adapter, to the benefit of our vault (urn):
echo "lock $xdcAmount XDC into adapter, to the benefit of our vault (urn)..."
seth send $MCD_JOIN_XDC_A 'join(address,uint256)' $urn $(seth --to-uint256 $(seth --to-wei $xdcAmount ETH))

# As a validation, confirm that the collateral is available to our vault:
echo "the available collateral is..."
seth --from-wei $(seth --to-dec $(seth call $MCD_VAT 'gem(bytes32,address)(uint256)' $ilk $urn)) eth

# To prepare the locking of collateral, you set two variables with the amount of collateral 
# that you will put in the Vault and the amount of Dai you will be generating:
export dink=$(seth --to-uint256 $(seth --to-hex $(seth --to-wei $xdcAmount eth)))
export dart=$(seth --to-uint256 $(seth --to-hex $(seth --to-wei $daiAmount eth)))

# Finally, lock up collateral in the Vat and generate Dai
echo "lock up collateral in the Vat and generate Dai..."
seth send $CDP_MANAGER 'frob(uint256,int256,int256)' $cdpId $dink $dart

# check successfully generated (output is in rad):
seth call $MCD_VAT 'dai(address)(uint256)' $urn

# move internal Dai balance from urn to account
echo "move internal Dai balance from urn to account..."
export rad=$(seth call $MCD_VAT 'dai(address)(uint256)' $urn)
seth send $CDP_MANAGER 'move(uint256,address,uint256)' $cdpId $ETH_FROM $(seth --to-uint256 $rad)

# approve to Dai adapter to withdraw created Dai from urn
echo "approve to Dai adapter to withdraw created Dai from urn..."
seth send $MCD_VAT 'hope(address)' $MCD_JOIN_DAI

# Finally, you withdraw the Dai to your account. 
# You need the $wad parameter that will define the amount of Dai you want to withdraw.
echo "withdraw the Dai to account $ETH_FROM"
export wad=$(seth --to-uint256 $(seth --to-wei $daiAmount eth))
seth send $MCD_JOIN_DAI "exit(address,uint256)" $ETH_FROM $wad

# Checking the balance in the account
echo "Successfully created an Vault and drawn some fresh DAI"
balance=$(seth --from-wei $(seth --to-dec $(seth call $MCD_DAI 'balanceOf(address)' $ETH_FROM)) eth)
echo "Your balance: $balance DAI"