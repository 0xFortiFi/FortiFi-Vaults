# Solidity API

## MockVectorStrat

You can use this contract for only the most basic simulation since this contract
does not keep track of deposits.

_This contract is meant to mimic Vector and other strategy contracts that 
allows require calculations for withdrawal. see: https://snowtrace.io/address/0xcade1284aecc2d38bb957368f69a32fa370cf6f8#code_

### depositToken

```solidity
contract IERC20 depositToken
```

### constructor

```solidity
constructor(address _depositToken) public
```

### deposit

```solidity
function deposit(uint256 amount) external
```

### withdraw

```solidity
function withdraw(uint256 amount, uint256 minAmount) external
```

### getDepositTokensForShares

```solidity
function getDepositTokensForShares(uint256 amount) public view returns (uint256)
```

### getSharesForTokens

```solidity
function getSharesForTokens(uint256 amount) internal view returns (uint256)
```

