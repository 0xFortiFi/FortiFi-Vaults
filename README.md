
![Logo](https://372453455-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F43popf5VC0KlvwcpE7fk%2Fuploads%2FxXBnexrGFEUHxjAO3CZP%2FFortiFi-Word-light-press.png?alt=media&token=534aff84-e551-42f0-b1f1-2b32d3ee83f5)


## Authors

- [@xrpant](https://www.x.com/xrpant)


## Introduction

This repository contains all of the contracts related to the FortiFi Vaults Ecosystem, as well as testing scripts and deployment information. 

To get started, clone the repo and:

```yarn``` to install all dependencies





## Environment Variables

`PRIVATE_KEY`

Make a burner wallet for this, just in case you commit by mistake but .env is in the .gitignore.


## Running Tests

To run tests, run the following command

```bash
  yarn test
```

You can specify the test script to run in package.json. 

Test scripts are located in the /test directory, and cover basic functionality of all FortiFi contracts. 

There are supporting 'mock' contracts in contracts/mock, which should not be deployed and are solely for the purpose of testing. These mock contracts include mock strategies and a mock MASS Vault contract that does not require a working swap router. 
## Contract Descriptions

### FortiFiSAMSVault
SAMS Vaults are the heart of the FortiFi ecosystem. They allow for the deposit of a single token, which is then split and deposited into multiple sub-strategies, including FortiFiStrategy strategies. This allows for diversified yield from a single asset.

SAMS Vaults utilize FortiFiFeeCalculator and FortiFiFeeManager contracts to calculate and collect performance fees.

### FortiFiMASSVault
MASS Vaults allow for the deposit of a single token, which is then split, swapped into other assets if necessary, and then deposited into sub-strategies, including FortiFiStrategy strategies and SAMS Vaults. MASS Vaults are designed to function similarly to ETF tokens, but the underlying assets are yield-bearing.

When setting strategies you must specify the router and oracle you would like to use to get prices and swap for the strategy deposit token. Routers must be Uniswap V2 style routers with a swapTokensForExactTokens function, and the oracle should be a Chainlink price feed or similar oracle with a latestAnswer view function that returns the price.

MASS Vaults utilize FortiFiFeeCalculator and FortiFiFeeManager contracts to calculate and collect performance fees.

MASS Vaults utilize FortiFiPriceOracle contracts to get on-chain price feeds to calculate swap values.

### FortiFiStrategy
FortiFiStrategy contracts are meant to be used as a sort of wrapper for yield strategies that do not adhere to the simple structure of:

```deposit(amount of deposit token)``` 

```withdraw(amount of receipt token to burn)```

This contract must be used for Delta Prime strategies, and can be used as is. Other strategies can inherit this contract and add necessary modifications.

Initial strategies inheriting from this contract are:

**FortiFiVectorStrategy** (Vector Finance)

FortiFiStrategies isolate user deposits into FortiFiFortress contracts.

### FortiFiFortress
FortiFiFortress contracts are used to isolate users' receipt tokens, which is necessary for strategies that have unique deposit or withdraw functions. Fortress contracts are deployed by FortiFiStrategy contracts, and can only be accessed by the contract that deploys them. A fortress is created for each vault receipt token (1155) used to deposit to the FortiFiStrategy.

Initial fortresses inheriting from this contract are:

**FortiFiVectorFortress** (Vector Finance)

### FortiFiFeeCalculator
FortiFiFeeCalculator contracts are utilized by SAMS and MASS Vaults to calculate performance fees. The fees are calculated based on a user's NFT holdings as specified upon deployment. 

### FortiFiFeeManager
FortiFiFeeManager contracts are utilized by SAMS and MASS Vaults to split performance fees among one or more addresses.

### FortiFiPriceOracle
FortiFiPriceOracle contracts are utilized by MASS Vaults to calculate swap prices. The base contract uses Chainlink's AggregatorV3Interface and can be extended for other price feeds.

