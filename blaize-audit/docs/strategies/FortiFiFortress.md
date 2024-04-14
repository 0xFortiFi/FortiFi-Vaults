# Solidity API

## CannotWithdrawStrategyReceipts

```solidity
error CannotWithdrawStrategyReceipts()
```

Error caused by trying to use recoverERC20 to withdraw strategy receipt tokens

## ZeroAddress

```solidity
error ZeroAddress()
```

Error caused by using 0 address as a parameter

## InvalidDeposit

```solidity
error InvalidDeposit()
```

Error caused by trying to deposit 0

## InvalidWithdrawal

```solidity
error InvalidWithdrawal()
```

Error caused by trying to withdraw 0

## FailedToRefund

```solidity
error FailedToRefund()
```

Error thrown when refunding native token fails

## FortiFiFortress

Fortresses are vault contracts that are specific to an individual vault receipt. By isolating deposits,
Fortresses allow for balance-specific logic from underlying strategies.

### _strat

```solidity
contract IStrategy _strat
```

### _dToken

```solidity
contract IERC20 _dToken
```

### _wNative

```solidity
contract IERC20 _wNative
```

### constructor

```solidity
constructor(address _strategy, address _depositToken, address _wrappedNative) public
```

### DepositMade

```solidity
event DepositMade(uint256 amount, address user)
```

### WithdrawalMade

```solidity
event WithdrawalMade(address user)
```

### ApprovalsRefreshed

```solidity
event ApprovalsRefreshed()
```

### ERC20Recovered

```solidity
event ERC20Recovered(address to, address token, uint256 amount)
```

### receive

```solidity
receive() external payable
```

### deposit

```solidity
function deposit(uint256 _amount, address _user) external virtual returns (uint256 _newStratReceipts)
```

Function to deposit

### withdraw

```solidity
function withdraw(address _user) external virtual
```

Function to withdraw everything from vault

### refreshApproval

```solidity
function refreshApproval() external
```

Grant max approval to underlying strategy for deposit token

_Since Fortresses do not hold deposit tokens for longer than it takes to complete the 
transaction there should be no risk in granting max approval_

### recoverERC20

```solidity
function recoverERC20(address _to, address _token, uint256 _amount) external
```

Emergency function to recover stuck tokens.

### _refund

```solidity
function _refund(address _user) internal
```

Internal function to refund left over tokens from transactions to user who initiated vault transaction

