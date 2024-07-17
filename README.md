
![Logo](https://372453455-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2F43popf5VC0KlvwcpE7fk%2Fuploads%2FxXBnexrGFEUHxjAO3CZP%2FFortiFi-Word-light-press.png?alt=media&token=534aff84-e551-42f0-b1f1-2b32d3ee83f5)


## Authors

- [@xrpant](https://www.github.com/anthonybautista)


## Introduction

This repository contains all of the contracts related to the FortiFi Vaults Ecosystem, as well as testing scripts and deployment information. 

To get started, clone the repo and:

```yarn``` to install all dependencies

```npx hardhat compile``` to compile contracts





## Environment Variables

`PRIVATE_KEY`

Make a burner wallet for this, just in case you commit by mistake but .env is in the .gitignore.

`ETHERSCAN_KEY`

Explorer API key used for contract verification


## Audit Information

An audit of the ForiFi Vault architecture was performed by Blaize Security in October 2023. You can view artifacts from their audit in the ```blaize-audit``` directory of this repository, including their test suite.

[Audit Report](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/blaize-audit/FortiFi-audit-report-v2-%5B30-Oct-2023%5D.pdf)

After this audit was conducted, development on the protocol continued to include new strategies, additional safety mechanisms, router adapters, and support for wrapped native token deposits. 

A description of changes can be found here:
[Post-Audit Change Report #1](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/change-reports/FortiFi_Post-Audit_Change_Report.pdf)

Bug Bounty submissions which included markdown can be found here: 
[Bug Bounty Submissions](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/bug-bounty/)

Bug Bounty conclusion and recap can be found here: 
[Bug Bounty Recap](https://fortifi.substack.com/p/bug-bounty-conclusion-and-change)

## Contract Descriptions

### FortiFiSAMSVault
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/vaults/FortiFiSAMSVault.sol)

SAMS Vaults are the most basic vault type in the FortiFi ecosystem. They allow for the deposit of a single token, which is then split and deposited into multiple sub-strategies, including FortiFiStrategy strategies. This allows for diversified yield from a single asset.

SAMS Vaults utilize FortiFiFeeCalculator and FortiFiFeeManager contracts to calculate and collect performance fees.

### FortiFiMASSVault
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/vaults/FortiFiMASSVaultV3.sol)

MASS Vaults allow for the deposit of a single token, which is then split, swapped into other assets if necessary, and then deposited into sub-strategies, including FortiFiStrategy strategies. MASS Vaults allow for highly customizable yield strategies to be implemented.

MASS Vaults utilize FortiFiFeeCalculator and FortiFiFeeManager contracts to calculate and collect performance fees, as well as FortiFiPriceOracle contracts and FortiFiRouter contracts to assist in swapping assets.

**V2 of this contract was created to allow the retrieval of assets deposited into an underlying strategy that has become bricked, preventing normal withdrawal**

### FortiFiWNativeMASSVault
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/vaults/FortiFiWNativeMASSVaultV3.sol)

Wrapped Native MASS Vaults allow for the deposit of the wrapped native asset of whatever chain the vault is on (i.e. WAVAX for Avalanche), which is then split, swapped into other assets if necessary, and then deposited into sub-strategies, including FortiFiStrategy strategies. Wrapped Native MASS Vaults allow for highly customizable yield strategies to be implemented.

MASS Vaults utilize FortiFiFeeCalculator and FortiFiFeeManager contracts to calculate and collect performance fees, as well as FortiFiPriceOracle contracts and FortiFiRouter contracts to assist in swapping assets.

**V2 of this contract was created to allow the retrieval of assets deposited into an underlying strategy that has become bricked, preventing normal withdrawal**

### FortiFiStrategy
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiStrategy.sol)

FortiFiStrategy contracts are meant to be used as a sort of wrapper for yield strategies that do not adhere to the simple structure of:

```deposit(amount of deposit token)``` 

```withdraw(amount of receipt token to burn)```

These strategies can be modified to allow for arbitrary logic to be performed before depositing to the underlying yield strategy. For example, the FortiFiGLPStrategy mints/burns GLP using USDC in order to deposit GLP into Yield Yak.

Initial strategies inheriting from this contract are:

[**FortiFiNativeStrategy**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiNativeStrategy.sol) (For strategies that use wrapped native tokens as the deposit token)

[**FortiFiGLPStrategy**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiGLPStrategy.sol) (GMX / GLP)

[**FortiFiWombatStrategy**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiWombatStrategy.sol) (Wombat Finance)

[**FortiFiVectorStrategy**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiVectorStrategy.sol) (Vector Finance)

FortiFiStrategies isolate user deposits into FortiFiFortress contracts.

### FortiFiFortress
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiFortress.sol)

FortiFiFortress contracts are used to isolate users' receipt tokens, which is necessary for strategies that have unique deposit or withdraw functions. Fortress contracts are deployed by FortiFiStrategy contracts, and can only be accessed by the contract that deploys them.

Initial fortresses inheriting from this contract are:

[**FortiFiNativeFortress**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiNativeFortress.sol) (Allows unwrapping of wrapped native assets in order to utilize protocols that require native asset deposits)

[**FortiFiWombatFortress**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiWombatFortress.sol) (Wombat Finance)

[**FortiFiVectorFortress**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/strategies/FortiFiVectorFortress.sol) (Vector Finance)

### FortiFiPriceOracle
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/oracles/FortiFiPriceOracle.sol)

FortiFiPriceOracle contracts are used as an interface to on-chain price feeds in order to provide the vaults accurate price information without relying on pool reserves or other manipulable methods. Non-chainlink price feeds can be used by inheriting this contract and modifying as necessary.

Initial oracles inheriting from this contract are:

[**FortiFiDIAPriceOracle**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/oracles/FortiFiDIAPriceOracle.sol) (DIA)

[**FortiFiMockPriceOracle**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/oracles/FortiFiMockOracle.sol) (Used in a case where an oracle is not needed for logic executed by the router (i.e. For ggAVAX since the ggAVAX router deposits/redeems directly from the contract without needing to swap). Returns a static price.)

### FortiFiPriceOracleL2
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/oracles/FortiFiPriceOracleL2.sol)

FortiFiPriceOracleL2 contracts are a modified version of FortiFiPriceOracle that allows for use on layer 2 networks that may experience sequencer downtime. These contract utilize Chainlink's sequencer uptime feeds to ensure that swaps cannot happen while the sequencer is down or for the first 60 minutes after the sequencer comes back online.

Non-chainlink price feeds can be used by inheriting this contract and modifying as necessary.

Initial oracles inheriting from this contract are:

[**FortiFiDIAPriceOracleL2**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/oracles/FortiFiDIAPriceOracleL2.sol) (DIA)

### FortiFiRouter
FortiFiRouter contracts are adapters that act as an interface to concentrated liquidity pools. Since the original architecture of MASS vaults only allowed for swapExactTokensForTokens calls to UniV2/Trader Joe V1 pools, these routers must utilize data contained in these calls to execute swaps.

Initial oracles inheriting from this contract are:

[**FortiFiUniV3Router**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/routers/FortiFiUniV3Router.sol) (Uniswap)

[**FortiFiUniV3MultiHopRouter**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/routers/FortiFiUniV3MultiHopRouter.sol) (Uniswap for when assets don't have a direct pair and wrapped native tokens are used as an intermediate step in the swap)

[**FortiFiLBRouter**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/routers/FortiFiLBRouter.sol) (Trader Joe Liquidity Book)

[**FortiFiLBRouter2**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/routers/FortiFiLBRouter2.sol) (Trader Joe Liquidity Book, used when there is no asset/asset fallback v1 pool that can be executed to swap, and wrapped native assets must be used as an intermediate step in the swap)

[**FortiFiGGAvaxRouter**](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/routers/FortiFiGGAvaxRouter.sol) (gogopool, used to deposit/redeem ggAVAX directly without swapping)

### FortiFiFeeCalculator
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/fee-calculators/FortiFiFeeCalculator.sol)

FortiFiFeeCalculator contracts are utilized by SAMS and MASS Vaults to calculate performance fees. The fees are calculated based on a user's NFT holdings as specified upon deployment. 

### FortiFiFeeManager
[View Code](https://github.com/0xFortiFi/FortiFi-Vaults/blob/main/contracts/fee-managers/FortiFiFeeManager.sol)

FortiFiFeeManager contracts are utilized by SAMS and MASS Vaults to split performance fees among one or more addresses.

## Deployed Contracts

Current Active Deployments:

**MultiYields (fka Vaults)**

[Avalanche LST Wrapped Native MASS MultiYield](https://snowscan.xyz/address/0x853e7a9dcc5037cd624834dc5f33151aa49d2d73#code)

[Avalance Stability MASS MultiYield](https://snowscan.xyz/address/0x432963c721599cd039ff610fad447d487380d858#code)

**Strategies**

[FortiFiGLPStrategy](https://snowscan.xyz/address/0x72a1702785e1208973819b9f692801ab26fca882#code)

[FortiFiWombatStrategy - sAVAX](https://snowscan.xyz/address/0xca33e819b1a3e519b02830ced658fd0543599410#code)

[FortiFiWombatStrategy - ggAVAX](https://snowscan.xyz/address/0x666d883b9d5bb40f4d100d3c9919abfe29608f30#code)

**Oracles**

[FortiFiPriceOracle - AVAX](https://snowscan.xyz/address/0xdfabbc3d82b8234a88a9f64faab1f514a857a3df#code)

[FortiFiDIAPriceOracle - sAVAX](https://snowscan.xyz/address/0x0c53b73efdde61874c945395a813253326de8eea#code)

[FortiFiDIAPriceOracle - USDT](https://snowscan.xyz/address/0xdc655e3dc8f36096c779294d03c62b3af15de8b0#code)

[FortiFiMockPriceOracle - ggAVAX](https://snowscan.xyz/address/0x4a30cb77aac31c9b7fec0700feacd3bdb44147f6#code)

**Routers**

[FortiFiLBRouter - sAVAX](https://snowscan.xyz/address/0x8b8cb06b4e9b171064345e32ff575c77ca805ce3#code)

[FortiFiLBRouter2 - USDT](https://snowscan.xyz/address/0xd2746098c8ff73cd676f293b061248b124eb2806#code)

[FortiFiGGAvaxRouter](https://snowscan.xyz/address/0xa5eec52dd815ee7b3b91da8af5face1aa996336c#code)

**Price Managers**

[FortiFiPriceManager - Avalanche](https://snowscan.xyz/address/0xf964894470afc11037f6bcb38609f77e9eba9851#code)

**Fee Calculators**

[FortiFiPriceCalculator - Avalanche LST](https://snowscan.xyz/address/0xc15711c7c8deac7a360f9b8826e7c151088d0d8c#code)

[FortiFiPriceCalculator - Avalanche Stability](https://snowscan.xyz/address/0x97f9fe54aa908ac0e8b2d10244bd4bba87d51160#code)


