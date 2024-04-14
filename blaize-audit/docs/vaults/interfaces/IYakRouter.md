# Solidity API

## Query

```solidity
struct Query {
  address adapter;
  address tokenIn;
  address tokenOut;
  uint256 amountOut;
}
```

## Offer

```solidity
struct Offer {
  bytes amounts;
  bytes adapters;
  bytes path;
  uint256 gasEstimate;
}
```

## FormattedOffer

```solidity
struct FormattedOffer {
  uint256[] amounts;
  address[] adapters;
  address[] path;
}
```

## Trade

```solidity
struct Trade {
  uint256 amountIn;
  uint256 amountOut;
  address[] path;
  address[] adapters;
}
```

## IYakRouter

### UpdatedTrustedTokens

```solidity
event UpdatedTrustedTokens(address[] _newTrustedTokens)
```

### UpdatedAdapters

```solidity
event UpdatedAdapters(address[] _newAdapters)
```

### UpdatedMinFee

```solidity
event UpdatedMinFee(uint256 _oldMinFee, uint256 _newMinFee)
```

### UpdatedFeeClaimer

```solidity
event UpdatedFeeClaimer(address _oldFeeClaimer, address _newFeeClaimer)
```

### YakSwap

```solidity
event YakSwap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _amountOut)
```

### setTrustedTokens

```solidity
function setTrustedTokens(address[] _trustedTokens) external
```

### setAdapters

```solidity
function setAdapters(address[] _adapters) external
```

### setFeeClaimer

```solidity
function setFeeClaimer(address _claimer) external
```

### setMinFee

```solidity
function setMinFee(uint256 _fee) external
```

### trustedTokensCount

```solidity
function trustedTokensCount() external view returns (uint256)
```

### adaptersCount

```solidity
function adaptersCount() external view returns (uint256)
```

### queryAdapter

```solidity
function queryAdapter(uint256 _amountIn, address _tokenIn, address _tokenOut, uint8 _index) external returns (uint256)
```

### queryNoSplit

```solidity
function queryNoSplit(uint256 _amountIn, address _tokenIn, address _tokenOut, uint8[] _options) external view returns (struct Query)
```

### queryNoSplit

```solidity
function queryNoSplit(uint256 _amountIn, address _tokenIn, address _tokenOut) external view returns (struct Query)
```

### findBestPathWithGas

```solidity
function findBestPathWithGas(uint256 _amountIn, address _tokenIn, address _tokenOut, uint256 _maxSteps, uint256 _gasPrice) external view returns (struct FormattedOffer)
```

### findBestPath

```solidity
function findBestPath(uint256 _amountIn, address _tokenIn, address _tokenOut, uint256 _maxSteps) external view returns (struct FormattedOffer)
```

### swapNoSplit

```solidity
function swapNoSplit(struct Trade _trade, address _to, uint256 _fee) external
```

### swapNoSplitFromAVAX

```solidity
function swapNoSplitFromAVAX(struct Trade _trade, address _to, uint256 _fee) external payable
```

### swapNoSplitToAVAX

```solidity
function swapNoSplitToAVAX(struct Trade _trade, address _to, uint256 _fee) external
```

### swapNoSplitWithPermit

```solidity
function swapNoSplitWithPermit(struct Trade _trade, address _to, uint256 _fee, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external
```

### swapNoSplitToAVAXWithPermit

```solidity
function swapNoSplitToAVAXWithPermit(struct Trade _trade, address _to, uint256 _fee, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external
```

