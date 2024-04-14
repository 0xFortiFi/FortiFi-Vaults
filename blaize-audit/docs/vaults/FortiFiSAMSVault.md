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

## InvalidMinDeposit

```solidity
error InvalidMinDeposit()
```

Error caused by trying to set minDeposit below BPS

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

## FortiFiSAMSVault

This contract allows for the deposit of a single asset, which is then split and deposited in to 
multiple yield-bearing strategies.

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

### BPS

```solidity
uint16 BPS
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
struct ISAMS.Strategy[] strategies
```

### tokenInfo

```solidity
mapping(uint256 => struct ISAMS.TokenInfo) tokenInfo
```

### noFeesFor

```solidity
mapping(address => bool) noFeesFor
```

### Deposit

```solidity
event Deposit(address depositor, uint256 tokenId, uint256 amount, struct ISAMS.TokenInfo tokenInfo)
```

### Add

```solidity
event Add(address depositor, uint256 tokenId, uint256 amount, struct ISAMS.TokenInfo tokenInfo)
```

### Rebalance

```solidity
event Rebalance(uint256 tokenId, uint256 amount, struct ISAMS.TokenInfo tokenInfo)
```

### Withdrawal

```solidity
event Withdrawal(address depositor, uint256 tokenId, uint256 amountWithdrawn, uint256 profit, uint256 fee)
```

### ApprovalsRefreshed

```solidity
event ApprovalsRefreshed()
```

### StrategiesSet

```solidity
event StrategiesSet(struct ISAMS.Strategy[])
```

### MinDepositSet

```solidity
event MinDepositSet(uint256 minAmount)
```

### FeeManagerSet

```solidity
event FeeManagerSet(address feeManager)
```

### FeeCalculatorSet

```solidity
event FeeCalculatorSet(address feeCalculator)
```

### FeesSetForAddress

```solidity
event FeesSetForAddress(address vault, bool fees)
```

### PauseStateUpdated

```solidity
event PauseStateUpdated(bool paused)
```

### ERC20Recovered

```solidity
event ERC20Recovered(address token, uint256 amount)
```

### whileNotPaused

```solidity
modifier whileNotPaused()
```

Used to restrict function access while paused.

### constructor

```solidity
constructor(string _name, string _symbol, string _metadata, address _wrappedNative, address _depositToken, address _feeManager, address _feeCalculator, uint256 _minDeposit, struct ISAMS.Strategy[] _strategies) public
```

### receive

```solidity
receive() external payable
```

### deposit

```solidity
function deposit(uint256 _amount) external returns (uint256 _tokenId, struct ISAMS.TokenInfo _info)
```

This function is used when a user does not already have a receipt (ERC1155).

_The user must deposit at least the minDeposit, and will receive an ERC1155 non-fungible receipt token. 
The receipt token will be mapped to a TokenInfo containing the amount deposited as well as the strategy receipt 
tokens received for later withdrawal._

### add

```solidity
function add(uint256 _amount, uint256 _tokenId) external returns (struct ISAMS.TokenInfo _info)
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

Setter for minDeposit state variable

### setFeeManager

```solidity
function setFeeManager(address _contract) external
```

Setter for contract fee manager

_Contract address specified should implement IFortiFiFeeManager_

### setFeeCalculator

```solidity
function setFeeCalculator(address _contract) external
```

Setter for contract fee calculator

_Contract address specified should implement IFortiFiFeeCalculator_

### setNoFeesFor

```solidity
function setNoFeesFor(address _contract, bool _fees) external
```

Function to set noFeesFor a contract.

_This allows FortiFi MASS vaults to utilize this SAMS vault without paying a fee so that users
do not pay fees twice._

### flipPaused

```solidity
function flipPaused() external
```

Function to pause/unpause the contract.

### recoverERC20

```solidity
function recoverERC20(address _token, uint256 _amount) external
```

Emergency function to recover stuck ERC20 tokens.

### refreshApprovals

```solidity
function refreshApprovals() public
```

Function that approves ERC20 transfers for all strategy contracts

_This function sets the max approval because no depositTokens should remain in this contract at the end of a 
transaction. This means there should be no risk exposure._

### setStrategies

```solidity
function setStrategies(struct ISAMS.Strategy[] _strategies) public
```

This function sets up the underlying strategies used by the vault.

### setBpsForStrategies

```solidity
function setBpsForStrategies(uint16[] _bps) external
```

This function allows for changing the allocations of current strategies

### rebalance

```solidity
function rebalance(uint256 _tokenId) public returns (struct ISAMS.TokenInfo)
```

This function allows a user to rebalance a receipt (ERC1155) token's underlying assets.

_This function utilizes the internal _deposit and _withdraw functions to rebalance based on 
the strategies set in the contract. Since _deposit will set the TokenInfo.deposit to the total 
deposited after the rebalance, we must store the original deposit and overwrite the TokenInfo
before completing the transaction._

### getTokenInfo

```solidity
function getTokenInfo(uint256 _tokenId) public view returns (struct ISAMS.TokenInfo)
```

View function that returns all TokenInfo for a specific receipt

### getStrategies

```solidity
function getStrategies() public view returns (struct ISAMS.Strategy[])
```

View function that returns all strategies

### _mintReceipt

```solidity
function _mintReceipt() internal returns (uint256 _tokenId)
```

Internal function to mint receipt and advance nextToken state variable.

### _deposit

```solidity
function _deposit(uint256 _amount, uint256 _tokenId, bool _isAdd) internal
```

Internal deposit function.

_This function will loop through the strategies in order split/deposit the user's deposited tokens. 
The function handles additions slightly differently, requiring that the current strategies match the 
strategies that were set at the time of original deposit._

### _withdraw

```solidity
function _withdraw(uint256 _tokenId) internal returns (uint256 _proceeds, uint256 _profit)
```

Internal withdraw function that withdraws from strategies and calculates profits.

### _refund

```solidity
function _refund(struct ISAMS.TokenInfo _info) internal
```

Internal function to refund left over tokens from deposit/add/rebalance transactions

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view virtual returns (bool)
```

Override to allow FortiFiStrategy contracts to verify that specified vaults implement ISAMS interface

