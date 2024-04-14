# Solidity API

## IMASS

### Strategy

```solidity
struct Strategy {
  address strategy;
  address depositToken;
  address router;
  address oracle;
  bool isFortiFi;
  bool isSAMS;
  uint16 bps;
  uint8 decimals;
}
```

### Position

```solidity
struct Position {
  struct IMASS.Strategy strategy;
  uint256 receipt;
}
```

### TokenInfo

```solidity
struct TokenInfo {
  uint256 deposit;
  struct IMASS.Position[] positions;
}
```

### deposit

```solidity
function deposit(uint256 amount) external returns (uint256 tokenId, struct IMASS.TokenInfo info)
```

### add

```solidity
function add(uint256 amount, uint256 tokenId) external returns (struct IMASS.TokenInfo info)
```

### withdraw

```solidity
function withdraw(uint256 amount) external
```

### rebalance

```solidity
function rebalance(uint256 tokenId) external returns (struct IMASS.TokenInfo info)
```

### getTokenInfo

```solidity
function getTokenInfo(uint256 tokenId) external view returns (struct IMASS.TokenInfo info)
```

### getStrategies

```solidity
function getStrategies() external view returns (struct IMASS.Strategy[] strategies)
```

