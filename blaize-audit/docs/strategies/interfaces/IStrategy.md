# Solidity API

## IStrategy

### approve

```solidity
function approve(address spender, uint256 amount) external returns (bool)
```

### deposit

```solidity
function deposit(uint256 amount) external
```

### depositToFortress

```solidity
function depositToFortress(uint256 amount, address user, uint256 tokenId) external
```

### withdraw

```solidity
function withdraw(uint256 amount) external
```

### withdrawFromFortress

```solidity
function withdrawFromFortress(uint256 amount, address user, uint256 tokenId) external
```

### balanceOf

```solidity
function balanceOf(address holder) external view returns (uint256)
```

