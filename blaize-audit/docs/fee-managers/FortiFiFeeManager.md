# Solidity API

## ZeroAddress

```solidity
error ZeroAddress()
```

Error caused by using 0 address as a parameter

## InvalidArrayLength

```solidity
error InvalidArrayLength()
```

Error caused by mismatching array lengths

## InvalidBps

```solidity
error InvalidBps()
```

Error caused when bps does not equal 10_000

## FortiFiFeeManager

This contract is used by FortiFi Vaults to distribute fees earned upon withdrawal.

_Fees will only be disbursed when the contract holds at least 1000 wei of the token being 
disbursed. This way the contract does not fail when splitting the amount amongst multiple receivers._

### BPS

```solidity
uint16 BPS
```

### splitBps

```solidity
uint16[] splitBps
```

### receivers

```solidity
address[] receivers
```

### constructor

```solidity
constructor(address[] _receivers, uint16[] _splitBps) public
```

### FeesCollected

```solidity
event FeesCollected(uint256 amount, address[] receivers, uint16[] split)
```

### FeesChanged

```solidity
event FeesChanged(address[] receivers, uint16[] split)
```

### ERC20Recovered

```solidity
event ERC20Recovered(address token, uint256 amount)
```

### collectFees

```solidity
function collectFees(address _token, uint256 _amount) external
```

Function to collect fees from payer

### setSplit

```solidity
function setSplit(address[] _receivers, uint16[] _splitBps) public
```

Function to set new receivers

_This function replaces the current receivers and splitBps. Total bps must equal 10_000_

### _validateBps

```solidity
function _validateBps(uint16[] _bps) internal pure returns (bool)
```

Validate that total bps in aray equals 10_000

### recoverERC20

```solidity
function recoverERC20(address _token, uint256 _amount) external
```

Emergency function to recover stuck ERC20 tokens

