# Solidity API

## MockBasicStrat

You can use this contract for only the most basic simulation since this contract
does not keep track of deposits.

_This contract is meant to mimic Yield Yak and other strategy contracts that 
allows for simple deposit and withdrawal. see: https://snowtrace.io/address/0xc8ceea18c2e168c6e767422c8d144c55545d23e9#code_

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
function withdraw(uint256 amount) external
```

### getDepositTokensForShares

```solidity
function getDepositTokensForShares(uint256 amount) internal view returns (uint256)
```

