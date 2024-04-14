# Solidity API

## IVectorStrategy

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

### deposit

```solidity
function deposit(uint256 amount) external
```

### withdraw

```solidity
function withdraw(uint256 amount, uint256 minAmount) external
```

### balanceOf

```solidity
function balanceOf(address holder) external view returns (uint256)
```

### getDepositTokensForShares

```solidity
function getDepositTokensForShares(uint256 amount) external view returns (uint256)
```

### strategy

```solidity
function strategy() external view returns (address)
```

