# Solidity API

## FortiFiVectorStrategy

This contract allows for FortiFi vaults to utilize Vector Finance strategies.

### slippageBps

```solidity
uint16 slippageBps
```

### constructor

```solidity
constructor(address _strategy, address _depositToken, address _wrappedNative) public
```

### SlippageSet

```solidity
event SlippageSet(uint16 newSlippage)
```

### depositToFortress

```solidity
function depositToFortress(uint256 _amount, address _user, uint256 _tokenId) external
```

Function to deposit

_If a user has not deposited previously, this function will deploy a FortiFiVectorFortress contract
instead of the base FortiFiFortress contract_

### withdrawFromFortress

```solidity
function withdrawFromFortress(uint256 _amount, address _user, uint256 _tokenId) external
```

Function to withdraw

_Override is required because Vector Fortresses need slippage passed in to withdrawal function_

### setSlippage

```solidity
function setSlippage(uint16 _amount) external
```

Function to set the slippage if 1% is not sufficient

