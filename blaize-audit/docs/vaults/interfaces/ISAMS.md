# Solidity API

## ISAMS

### Strategy

```solidity
struct Strategy {
  address strategy;
  bool isFortiFi;
  uint16 bps;
}
```

### Position

```solidity
struct Position {
  struct ISAMS.Strategy strategy;
  uint256 receipt;
}
```

### TokenInfo

```solidity
struct TokenInfo {
  uint256 deposit;
  struct ISAMS.Position[] positions;
}
```

### deposit

```solidity
function deposit(uint256 amount) external returns (uint256 tokenId, struct ISAMS.TokenInfo info)
```

### add

```solidity
function add(uint256 amount, uint256 tokenId) external returns (struct ISAMS.TokenInfo info)
```

### withdraw

```solidity
function withdraw(uint256 amount) external
```

### rebalance

```solidity
function rebalance(uint256 tokenId) external returns (struct ISAMS.TokenInfo info)
```

### getTokenInfo

```solidity
function getTokenInfo(uint256 tokenId) external view returns (struct ISAMS.TokenInfo info)
```

### getStrategies

```solidity
function getStrategies() external view returns (struct ISAMS.Strategy[] strategies)
```

