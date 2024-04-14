# Solidity API

## FortiFiVectorFortress

This Fortress contract is specifically made to interact with Vector Finance strategies

### BPS

```solidity
uint16 BPS
```

### _vectorStrat

```solidity
contract IVectorStrategy _vectorStrat
```

### constructor

```solidity
constructor(address _strategy, address _depositToken, address _wrappedNative) public
```

### withdraw

```solidity
function withdraw(address) external
```

Nullified withdraw function

_this override is to ensure an incorrect withdraw call is not made from the strategy contract.
Vector strategies require calling withdrawVector(_amount, _slippageBps)_

### withdrawVector

```solidity
function withdrawVector(address _user, uint16 _slippageBps) external
```

Function to withdraw

_Vector Finance strategies require that you pass in the amount of deposit tokens you expect to receive
rather than the amount of receipt tokens you want to burn as well as a minAmount. This is calculated by utilizing the
getDepositTokensForShares view function and applying a slippage amount (typically 1%)._

