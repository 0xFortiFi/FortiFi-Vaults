
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

MASS Vaults utilize FortiFiFeeCalculator and FortiFiFeeManager contracts to calculate and collect performance fees.

### FortiFiStrategy
FortiFiStrategy contracts are meant to be used as a sort of wrapper for yield strategies that do not adhere to the simple structure of:

```deposit(amount of deposit token)``` 

```withdraw(amount of receipt token to burn)```

Initial strategies inheriting from this contract are:

**FortiFiDPStrategy** (Delta Prime)

**FortiFiVectorStrategy** (Vector Finance)

FortiFiStrategies isolate user deposits into FortiFiFortress contracts.

### FortiFiFortress
FortiFiFortress contracts are used to isolate users' receipt tokens, which is necessary for strategies that have unique deposit or withdraw functions. Fortress contracts are deployed by FortiFiStrategy contracts, and can only be accessed by the contract that deploys them. A fortress is created for each vault receipt token (1155) used to deposit to the FortiFiStrategy.

Initial fortresses inheriting from this contract are:

**FortiFiDPFortress** (Delta Prime)

**FortiFiVectorFortress** (Vector Finance)

### FortiFiFeeCalculator
FortiFiFeeCalculator contracts are utilized by SAMS and MASS Vaults to calculate performance fees. The fees are calculated based on a user's NFT holdings as specified upon deployment. 

### FortiFiFeeManager
FortiFiFeeManager contracts are utilized by SAMS and MASS Vaults to split performance fees among one or more addresses.

## Notes for Auditors

Slither is included in this project. To run:

```slither .```

Most of the results from Slither are related to mock contracts or certain emergency functions like recoverERC20. It also doesn't like the _refund() functions used to ensure no ERC20 tokens remain in the contracts after transactions complete. 

**Our main concern is with possible reentrancy attacks and gas optimization. Any insights here would be greatly appreciated.**

Our test scripts utilize mock contracts that may not give you the full context for how the contracts function. Here are links to deployed contracts that will actually be utilized:

**Strategies**

YieldYak: 

https://snowtrace.io/address/0xf9cD4Db17a3FB8bc9ec0CbB34780C91cE13ce767#code

https://snowtrace.io/address/0xd0f41b1c9338eb9d374c83cc76b684ba3bb71557#code

https://snowtrace.io/address/0xc8ceea18c2e168c6e767422c8d144c55545d23e9#code

https://snowtrace.io/address/0xb8f531c0d3c53b1760bcb7f57d87762fd25c4977#code

Delta Prime:

https://snowtrace.io/address/0x475589b0ed87591a893df42ec6076d2499bb63d0#code

https://snowtrace.io/address/0x2323dac85c6ab9bd6a8b5fb75b0581e31232d12b#code

Vector Finance: 

https://snowtrace.io/address/0x8f9b2a7ae089aa01636996ebaf276f48fefdb916#code

https://snowtrace.io/address/0x53cca4921522e43ef6652420c3eec6fbfe987a55#code

**Routers**

Trader Joe: 

https://snowtrace.io/address/0x60ae616a2155ee3d9a68541ba4544862310933d4#code

Pangolin: 

https://snowtrace.io/address/0xe54ca86531e17ef3616d22ca28b0d458b6c89106#code
