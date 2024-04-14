# Solidity API

## InvalidVaultImplementation

```solidity
error InvalidVaultImplementation()
```

Error when vault does not implement ISAMS or IMASS interface (0x23c01392)

## InvalidCaller

```solidity
error InvalidCaller()
```

Error caused when calling address is not a valid vault

## NoFortress

```solidity
error NoFortress()
```

Error caused when trying to withdraw from non-existent fortress

## FortiFiStrategy

This contract should be used when a yield strategy requires special logic beyond
simple deposit(amount deposit token) and withdraw(receipt tokens to burn). These strategies
are designed to only be called by FortiFi SAMS and MASS Vaults.

### _strat

```solidity
address _strat
```

### _wNative

```solidity
address _wNative
```

### _dToken

```solidity
contract IERC20 _dToken
```

### isFortiFiVault

```solidity
mapping(address => bool) isFortiFiVault
```

### vaultToTokenToFortress

```solidity
mapping(address => mapping(uint256 => address)) vaultToTokenToFortress
```

### FortressCreated

```solidity
event FortressCreated(address vault, uint256 tokenId, address strategy)
```

### DepositToFortress

```solidity
event DepositToFortress(address vault, address user, address strategy, uint256 amountDeposited)
```

### WithdrawFromFortress

```solidity
event WithdrawFromFortress(address vault, address user, address strategy, uint256 amountReceived)
```

### VaultSet

```solidity
event VaultSet(address vault, bool approved)
```

### ERC20Recovered

```solidity
event ERC20Recovered(address token, uint256 amount)
```

### ERC20RecoveredFromFortress

```solidity
event ERC20RecoveredFromFortress(address fortress, address token, uint256 amount)
```

### constructor

```solidity
constructor(address _strategy, address _depositToken, address _wrappedNative) public
```

### depositToFortress

```solidity
function depositToFortress(uint256 _amount, address _user, uint256 _tokenId) external virtual
```

Function to deposit

_If a user has not deposited previously, this function will deploy a FortiFiFortress contract
to interact with the underlying strategy for a specific vault receipt token. This allows user deposits to be isolated
as many strategies utilize special logic that is dependent on the balance of the address interacting with them._

### withdrawFromFortress

```solidity
function withdrawFromFortress(uint256 _amount, address _user, uint256 _tokenId) external virtual
```

Function to withdraw

### setVault

```solidity
function setVault(address _vault, bool _approved) external
```

Set valid vaults

### recoverERC20

```solidity
function recoverERC20(address _token, uint256 _amount) external
```

Emergency function to recover stuck tokens

### recoverFromFortress

```solidity
function recoverFromFortress(address _fortress, address _token, uint256 _amount) external
```

Emergency function to recover stuck tokens from Fortress

