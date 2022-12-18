# xDAI Stablecoin
This is inspired by `MakerDAO` `Dai Stablecoin System`. A Stablecoin backed by XDC and utilizes the potential of the XDC Network.

DAI crypto is crypto-collateralized because it’s backed by XDC. The ratio in which DAI converts to XDC varies, though it’s usually hovering around 1.5 XDC to 1 DAI. 

Allow users interact with the system to
- Open Vaults (formerly CDPs collateralized debt positions)
- Borrow DAI by locking XDC as collateral
- Payback DAI and unlock collateral

## Screenshot

![xdc-dai-avatar-2](https://user-images.githubusercontent.com/44108463/208279019-eb601614-0ac5-4b7c-9fb7-3d140e757b8d.png)

### Blockscan contract addresses

![xdc-dai-screenshot-blockscan](https://user-images.githubusercontent.com/44108463/208279020-025548f2-83a9-4875-a4e3-8875aea93ff4.png)

### Open vaults and borrow DAI

![xdc-dai-screenshot-openvault](https://user-images.githubusercontent.com/44108463/208279021-0481be59-39a1-4c1a-b1f7-c8bffd4efdd6.png)

### Payback DAI

![xdc-dai-screenshot-payback](https://user-images.githubusercontent.com/44108463/208279022-670c249a-4136-4a07-8826-18c8dcf11835.png)


## Prerequisite
- Ubuntu 20.04
- nixos
- dapptools
- mcd

## Installation
- install python
    ```
    sudo apt install python3-pip
    ```

- install nixos
    ```
    curl -L https://nixos.org/nix/install | sh
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    ```

- install dapp tool
    ```
    curl https://dapp.tools/install | sh
    ```
- install mcd
    ```
    sudo curl https://raw.githubusercontent.com/makerdao/mcd-cli/master/install.sh | sh
    ```

## Deployment

- Import deployer account
```
rm ~/keys/deployer/*
export ETH_KEYSTORE=~/keys/deployer
export ETH_PASSWORD=/dev/null
ethsign import 
```

### 1. Deploy `WXDC`
```
cd ds-weth
dapp --use solc:0.5.17 build
source ../xdc-scripts/apothem.setup-env.sh
dapp create WXDC
```

### 2. Deploy XDC Price Feed
```
cd dss
export xdcPrice=0.02
export PIP=$(dapp create DSValue)
seth send $PIP 'poke(bytes32)' $(seth --to-uint256 "$(seth --to-wei $xdcPrice ETH)")
```

#### 3. Deploy `dss` using `dss-deploy-scripts`

- Configure `WXDC` and `PIP` to `apothem.json`
- Configure environment variables in  `./xdc-scripts/apothem.setup-env.sh`
- Deploy dss
    ```
    cd dss-deploy-scripts
    export PATH="$PATH:/nix/var/nix/profiles/default/bin"
    nix-shell --pure
    source ../xdc-scripts/apothem.setup-env.sh
    dss-deploy apothem
    ```

## Interacting with Maker Protocol contracts

### Setup environment

Configure environment variables in  `./xdc-scripts/apothem.setup-env.sh`

Example:
```
export SETH_CHAIN=
export ETH_KEYSTORE=~/keys/deployer
export ETH_PASSWORD=/dev/null
export ETH_FROM=0xB568aa07085319B731369FeAF4a7da29F2C4c341
export ETH_RPC_URL=https://erpc.apothem.network/
export ETH_GAS=40000000
```

#### Open vault 
```
cd xdc-scripts
source apothem.setup-env.sh
bash open-vault.sh
```

#### Pay back
```
cd xdc-scripts
source apothem.setup-env.sh
bash pay-back.sh
```

## Deployed Contracts

All contracts are deployed to Apothem testnet and XDC mainnet at [deployed-contracts.md](https://github.com/kryptopoo/xdc-dai-stablecoin/blob/master/deployed-contracts.md)

## References
- https://github.com/makerdao/awesome-makerdao
- https://github.com/makerdao/dss-deploy-scripts
- https://github.com/makerdao/developerguides

## License
MIT License