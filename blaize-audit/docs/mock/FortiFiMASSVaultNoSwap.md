# Solidity API

## DuplicateStrategy

```solidity
error DuplicateStrategy()
```

Error caused by trying to set a strategy more than once

## TooManyStrategies

```solidity
error TooManyStrategies()
```

Error caused by trying to set too many strategies

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

## NotTokenOwner

```solidity
error NotTokenOwner()
```

Error caused by trying to use a token not owned by user

## FailedToRefund

```solidity
error FailedToRefund()
```

Error thrown when refunding native token fails

## NoStrategies

```solidity
error NoStrategies()
```

Error caused when strategies array is empty

## CantAddToReceipt

```solidity
error CantAddToReceipt()
```

Error caused when strategies change and a receipt cannot be added to without rebalancing

## SwapFailed

```solidity
error SwapFailed()
```

Error caused when swap fails

## InvalidDecimals

```solidity
error InvalidDecimals()
```

Error caused when trying to use a token with less decimals than USDC

## InvalidOracle

```solidity
error InvalidOracle()
```

Error caused when trying to set oracle to an invalid address

## InvalidMinDeposit

```solidity
error InvalidMinDeposit()
```

Error caused by trying to set minDeposit below BPS

## InvalidSlippage

```solidity
error InvalidSlippage()
```

Error caused by trying to set a slippage too high

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

## ContractPaused

```solidity
error ContractPaused()
```

Error caused when trying to transact with contract while paused

## FortiFiMASSVaultNoSwap

This contract allows for the deposit of a single asset, which is then swapped into various assets and deposited in to 
multiple yield-bearing strategies.

_THIS IS A TEST CONTRACT WITH NO SWAP FEATURE FOR BASIC TESTING - DO NOT DEPLOY_

### name

```solidity
string name
```

### symbol

```solidity
string symbol
```

### depositToken

```solidity
address depositToken
```

### wrappedNative

```solidity
address wrappedNative
```

### DECIMALS

```solidity
uint8 DECIMALS
```

### BPS

```solidity
uint16 BPS
```

### slippageBps

```solidity
uint16 slippageBps
```

### minDeposit

```solidity
uint256 minDeposit
```

### nextToken

```solidity
uint256 nextToken
```

### paused

```solidity
bool paused
```

### feeCalc

```solidity
contract IFortiFiFeeCalculator feeCalc
```

### feeMgr

```solidity
contract IFortiFiFeeManager feeMgr
```

### strategies

```solidity
struct IMASS.Strategy[] strategies
```

### tokenInfo

```solidity
mapping(uint256 => struct IMASS.TokenInfo) tokenInfo
```

### Deposit

```solidity
event Deposit(address depositor, uint256 tokenId, uint256 amount, struct IMASS.TokenInfo tokenInfo)
```

### Add

```solidity
event Add(address depositor, uint256 tokenId, uint256 amount, struct IMASS.TokenInfo tokenInfo)
```

### Rebalance

```solidity
event Rebalance(uint256 tokenId, uint256 amount, struct IMASS.TokenInfo tokenInfo)
```

### Withdrawal

```solidity
event Withdrawal(address depositor, uint256 tokenId, uint256 amountWithdrawn, uint256 profit, uint256 fee)
```

### whileNotPaused

```solidity
modifier whileNotPaused()
```

Used to restrict function access while paused.

### constructor

```solidity
constructor(string _name, string _symbol, string _metadata, address _wrappedNative, address _depositToken, address _feeManager, address _feeCalculator, struct IMASS.Strategy[] _strategies) public
```

### receive

```solidity
receive() external payable
```

### deposit

```solidity
function deposit(uint256 _amount) external returns (uint256 _tokenId, struct IMASS.TokenInfo _info)
```

This function is used when a user does not already have a receipt (ERC1155).

_The user must deposit at least the minDeposit, and will receive an ERC1155 non-fungible receipt token. 
The receipt token will be mapped to a TokenInfo containing the amount deposited as well as the strategy receipt 
tokens received for later withdrawal._

### add

```solidity
function add(uint256 _amount, uint256 _tokenId) external returns (struct IMASS.TokenInfo _info)
```

This function is used to add to a user's deposit when they already has a receipt (ERC1155). The user can add to their 
deposit without needing to burn/withdraw first.

### withdraw

```solidity
function withdraw(uint256 _tokenId) external
```

This function is used to burn a receipt (ERC1155) and withdraw all underlying strategy receipt tokens.

_Once all receipts are burned and deposit tokens received, the fee manager will calculate the fees due, 
and the fee manager will distribute those fees before transfering the user their proceeds._

### setMinDeposit

```solidity
function setMinDeposit(uint256 _amount) external
```

### setSlippage

```solidity
function setSlippage(uint16 _amount) external
```

### setFeeManager

```solidity
function setFeeManager(address _contract) external
```

### setFeeCalculator

```solidity
function setFeeCalculator(address _contract) external
```

### flipPaused

```solidity
function flipPaused() external
```

### recoverERC20

```solidity
function recoverERC20(address _token, uint256 _amount) external
```

### recoverERC1155

```solidity
function recoverERC1155(address _token, uint256[] _tokenIds, uint256[] _amounts) external
```

### refreshApprovals

```solidity
function refreshApprovals() public
```

Function to set max approvals for router and strategies.

_Since contract never holds deposit tokens max approvals should not matter._

### setStrategies

```solidity
function setStrategies(struct IMASS.Strategy[] _strategies) public
```

This function sets up the underlying strategies used by the vault.

### rebalance

```solidity
function rebalance(uint256 _tokenId) public returns (struct IMASS.TokenInfo)
```

This function allows a user to rebalance a receipt (ERC1155) token's underlying assets.

_This function utilizes the internal _deposit and _withdraw functions to rebalance based on 
the strategies set in the contract. Since _deposit will set the TokenInfo.deposit to the total 
deposited after the rebalance, we must store the original deposit and overwrite the TokenInfo
before completing the transaction._

### getTokenInfo

```solidity
function getTokenInfo(uint256 _tokenId) public view returns (struct IMASS.TokenInfo)
```

### getStrategies

```solidity
function getStrategies() public view returns (struct IMASS.Strategy[])
```

View function that returns all strategies

### _mintReceipt

```solidity
function _mintReceipt() internal returns (uint256 _tokenId)
```

### _swapFromDepositToken

```solidity
function _swapFromDepositToken(uint256 _amount, struct IMASS.Strategy _strat) internal returns (uint256)
```

Internal swap function for deposits.

### _swapToDepositToken

```solidity
function _swapToDepositToken(uint256 _amount, struct IMASS.Strategy _strat) internal returns (uint256)
```

Internal swap function for withdrawals.

### _deposit

```solidity
function _deposit(uint256 _amount, uint256 _tokenId, bool _isAdd) internal
```

Internal deposit function.

_This function will loop through the strategies in order split/swap/deposit the user's deposited tokens. 
The function handles additions slightly differently, requiring that the current strategies match the 
strategies that were set at the time of original deposit._

### _depositSAMS

```solidity
function _depositSAMS(uint256 _amount, address _strategy) internal returns (uint256 _receiptToken)
```

### _addSAMS

```solidity
function _addSAMS(uint256 _amount, address _strategy, uint256 _tokenId) internal
```

### _withdraw

```solidity
function _withdraw(uint256 _tokenId) internal returns (uint256 _proceeds, uint256 _profit)
```

Internal withdraw function that withdraws from strategies and calculates profits.

### _refund

```solidity
function _refund(struct IMASS.TokenInfo _info) internal
```

Internal function to refund left over tokens from deposit/add/rebalance transactions

### onERC1155Received

```solidity
function onERC1155Received(address, address, uint256, uint256, bytes) public virtual returns (bytes4)
```

### onERC1155BatchReceived

```solidity
function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) public virtual returns (bytes4)
```

