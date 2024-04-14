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

## InvalidAmounts

```solidity
error InvalidAmounts()
```

Error caused NFT amounts array is invalid

## FortiFiFeeCalculator

This contract is used by FortiFi Vaults to calculate fees based on a user's NFT holdings.

_When combineNftHoldings is true the contract will combine the user's balance across all NFT
contracts in the nftContracts array when determining fees. Otherwise, the contract will only take
the user's highest balance out of the nftContracts._

### BPS

```solidity
uint16 BPS
```

### combineNftHoldings

```solidity
bool combineNftHoldings
```

### tokenAmounts

```solidity
uint8[] tokenAmounts
```

### thresholdBps

```solidity
uint16[] thresholdBps
```

### nftContracts

```solidity
address[] nftContracts
```

### constructor

```solidity
constructor(address[] _nftContracts, uint8[] _tokenAmounts, uint16[] _thresholdBps, bool _combineHoldings) public
```

### FeesSet

```solidity
event FeesSet(address[] nftContracts, uint8[] tokenAmounts, uint16[] thresholdBps)
```

### CombineNftsSet

```solidity
event CombineNftsSet(bool combine)
```

### getFees

```solidity
function getFees(address _user, uint256 _amount) external view returns (uint256)
```

Function to determine fees due based on a user's NFT holdings and amount of profit

### setFees

```solidity
function setFees(address[] _nftContracts, uint8[] _tokenAmounts, uint16[] _thresholdBps) public
```

Function to set new values for NFT contracts, threshold amounts, and thresholdBps

_Each amount in _tokenAmounts must have a corresponding bps value in _thresholdBps. Bps values should
decrease at each index, and token amounts should increase at each index. This maintains that the more NFTs
a user holds, the lower the fee bps._

### setCombine

```solidity
function setCombine(bool _bool) external
```

Function to set combineNFTHoldings state variable.

_When true, holdings across all specified collections in nftContracts will be combined to set the
NFT count that is used when determining the _feeBps in _getFees._

### _validateAmountsAndBps

```solidity
function _validateAmountsAndBps(uint8[] _amounts, uint16[] _bps) internal pure returns (bool)
```

Validate that arrays meet specifications

### _getFees

```solidity
function _getFees(address _user, uint256 _amount) internal view returns (uint256)
```

Get fees for user

### _getCombinedFees

```solidity
function _getCombinedFees(address _user, uint256 _amount) internal view returns (uint256)
```

Get fees for user when combineNFTHoldings is true.

