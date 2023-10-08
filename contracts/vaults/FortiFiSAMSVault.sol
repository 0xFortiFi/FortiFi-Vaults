// SPDX-License-Identifier: GPL-3.0-only
// FortiFiSAMSVault by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../strategies/interfaces/IStrategy.sol";
import "../fee-calculators/interfaces/IFortiFiFeeCalculator.sol";
import "../fee-managers/interfaces/IFortiFiFeeManager.sol";
import "./interfaces/ISAMS.sol";

pragma solidity 0.8.21;

/// @notice Error caused by trying to set a strategy more than once
error DuplicateStrategy();

/// @notice Error caused by trying to set too many strategies
error TooManyStrategies();

/// @notice Error caused by using 0 address as a parameter
error ZeroAddress();

/// @notice Error caused by trying to deposit 0
error InvalidDeposit();

/// @notice Error caused by trying to withdraw 0
error InvalidWithdrawal();

/// @notice Error caused by trying to use a token not owned by user
error NotTokenOwner();

/// @notice Error thrown when refunding native token fails
error FailedToRefund();

/// @notice Error caused when strategies array is empty
error NoStrategies();

/// @notice Error caused when strategies change and a receipt cannot be added to without rebalancing
error CantAddToReceipt();

/// @notice Error caused by trying to set minDeposit below BPS
error InvalidMinDeposit();

/// @notice Error caused by mismatching array lengths
error InvalidArrayLength();

/// @notice Error caused when bps does not equal 10_000
error InvalidBps();

/// @notice Error caused when trying to transact with contract while paused
error ContractPaused();

/// @title Contract for FortiFi SAMS Vaults
/// @notice This contract allows for the deposit of a single asset, which is then split and deposited in to 
/// multiple yield-bearing strategies. 
contract FortiFiSAMSVault is ISAMS, ERC1155Supply, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    string public name;
    string public symbol;
    address public immutable depositToken;
    address public immutable wrappedNative; 
    uint16 public constant BPS = 10_000;
    uint256 public minDeposit;
    uint256 public nextToken = 1;
    bool public paused = true;

    IFortiFiFeeCalculator public feeCalc;
    IFortiFiFeeManager public feeMgr;

    Strategy[] public strategies;

    mapping(uint256 => TokenInfo) private tokenInfo;
    mapping(address => bool) public noFeesFor;

    event Deposit(address indexed depositor, uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Add(address indexed depositor, uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Rebalance(uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Withdrawal(address indexed depositor, uint256 indexed tokenId, uint256 amountWithdrawn, uint256 profit, uint256 fee);
    event ApprovalsRefreshed();
    event StrategiesSet(Strategy[]);
    event MinDepositSet(uint256 minAmount);
    event FeeManagerSet(address feeManager);
    event FeeCalculatorSet(address feeCalculator);
    event FeesSetForAddress(address vault, bool fees);
    event PauseStateUpdated(bool paused);
    event ERC20Recovered(address indexed token, uint256 amount);

    /// @notice Used to restrict function access while paused.
    modifier whileNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    constructor(string memory _name, 
        string memory _symbol, 
        string memory _metadata,
        address _wrappedNative,
        address _depositToken,
        address _feeManager,
        address _feeCalculator,
        uint256 _minDeposit,
        Strategy[] memory _strategies) ERC1155(_metadata) {
        if (_wrappedNative == address(0)) revert ZeroAddress();
        if (_depositToken == address(0)) revert ZeroAddress();
        if (_feeManager == address(0)) revert ZeroAddress();
        if (_feeCalculator == address(0)) revert ZeroAddress();
        if (_minDeposit < BPS) revert InvalidMinDeposit();
        name = _name; 
        symbol = _symbol;
        minDeposit = _minDeposit;
        wrappedNative = _wrappedNative;
        depositToken = _depositToken;
        feeCalc = IFortiFiFeeCalculator(_feeCalculator);
        feeMgr = IFortiFiFeeManager(_feeManager);
        setStrategies(_strategies);
    }

    receive() external payable { 
    }

    /// @notice This function is used when a user does not already have a receipt (ERC1155). 
    /// @dev The user must deposit at least the minDeposit, and will receive an ERC1155 non-fungible receipt token. 
    /// The receipt token will be mapped to a TokenInfo containing the amount deposited as well as the strategy receipt 
    /// tokens received for later withdrawal.
    function deposit(uint256 _amount) external override nonReentrant whileNotPaused returns(uint256 _tokenId, TokenInfo memory _info) {
        if (_amount < minDeposit) revert InvalidDeposit();
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), _amount);
        _tokenId = _mintReceipt();
        _deposit(_amount, _tokenId, false);
        _info = tokenInfo[_tokenId];

        // refund left over tokens
        _refund(_info);

        emit Deposit(msg.sender, _tokenId, _amount, _info);
    }

    /// @notice This function is used to add to a user's deposit when they already has a receipt (ERC1155). The user can add to their 
    /// deposit without needing to burn/withdraw first. 
    function add(uint256 _amount, uint256 _tokenId) external override nonReentrant whileNotPaused returns(TokenInfo memory _info) {
        if (_amount < minDeposit) revert InvalidDeposit();
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), _amount);
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotTokenOwner();
        _deposit(_amount, _tokenId, true);
        _info = tokenInfo[_tokenId];

        // refund left over tokens
        _refund(_info);

        emit Add(msg.sender, _tokenId, _amount, _info);
    }

    /// @notice This function is used to burn a receipt (ERC1155) and withdraw all underlying strategy receipt tokens. 
    /// @dev Once all receipts are burned and deposit tokens received, the fee manager will calculate the fees due, 
    /// and the fee manager will distribute those fees before transfering the user their proceeds.
    function withdraw(uint256 _tokenId) external override nonReentrant whileNotPaused {
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotTokenOwner();
        _burn(msg.sender, _tokenId, 1);

        (uint256 _amount, uint256 _profit) = _withdraw(_tokenId);
        uint256 _fee = 0;

        // MASS vaults don't pay fees to SAMS
        if (!noFeesFor[msg.sender]) {
            _fee = feeCalc.getFees(msg.sender, _profit);
            feeMgr.collectFees(depositToken, _fee);
        }
        
        IERC20(depositToken).safeTransfer(msg.sender, _amount - _fee);

        // Refund excess native token, if any
        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    if (!success) revert FailedToRefund();
        }

        emit Withdrawal(msg.sender, _tokenId, _amount, _profit, _fee);
    }

    /// @notice Setter for minDeposit state variable
    function setMinDeposit(uint256 _amount) external onlyOwner {
        if (_amount < BPS) revert InvalidMinDeposit();
        minDeposit = _amount;
        emit MinDepositSet(_amount);
    }

    /// @notice Setter for contract fee manager
    /// @dev Contract address specified should implement IFortiFiFeeManager
    function setFeeManager(address _contract) external onlyOwner {
        if (_contract == address(0)) revert ZeroAddress();
        feeMgr = IFortiFiFeeManager(_contract);
        emit FeeManagerSet(_contract);
    }

    /// @notice Setter for contract fee calculator
    /// @dev Contract address specified should implement IFortiFiFeeCalculator
    function setFeeCalculator(address _contract) external onlyOwner {
        if (_contract == address(0)) revert ZeroAddress();
        feeCalc = IFortiFiFeeCalculator(_contract);
        emit FeeCalculatorSet(_contract);
    }

    /// @notice Function to set noFeesFor a contract. 
    /// @dev This allows FortiFi MASS vaults to utilize this SAMS vault without paying a fee so that users
    /// do not pay fees twice.
    function setNoFeesFor(address _contract, bool _fees) external onlyOwner {
        noFeesFor[_contract] = _fees;
        emit FeesSetForAddress(_contract, _fees);
    }

    /// @notice Function to pause/unpause the contract.
    function flipPaused() external onlyOwner {
        paused = !paused;
        emit PauseStateUpdated(paused);
    }

    /// @notice Emergency function to recover stuck ERC20 tokens.
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit ERC20Recovered(_token, _amount);
    }

    /// @notice Function that approves ERC20 transfers for all strategy contracts
    /// @dev This function sets the max approval because no depositTokens should remain in this contract at the end of a 
    /// transaction. This means there should be no risk exposure. 
    function refreshApprovals() public {
        IERC20 _depositToken = IERC20(depositToken);
        uint256 _length = strategies.length;

        for(uint256 i = 0; i < _length; i++) {
            _depositToken.approve(strategies[i].strategy, type(uint256).max);
        }

        _depositToken.approve(address(feeMgr), type(uint256).max);
        emit ApprovalsRefreshed();
    }

    /// @notice This function sets up the underlying strategies used by the vault.
    function setStrategies(Strategy[] memory _strategies) public onlyOwner {
        uint256 _length = _strategies.length;
        if (_length == 0) revert NoStrategies();
        if (_length > 4) revert TooManyStrategies();

        address[] memory _holdStrategies = new address[](_length);

        uint16 _bps = 0;
        for (uint256 i = 0; i < _length; i++) {
            _bps += _strategies[i].bps;
        }
        if (_bps != BPS) revert InvalidBps();

        delete strategies; // remove old array, if any

        for (uint256 i = 0; i < _length; i++) {
            if (_strategies[i].strategy == address(0)) revert ZeroAddress();
            uint256 _holdLength = _holdStrategies.length;
            for (uint256 j = 0; j < _holdLength; j++) {
                if (_holdStrategies[j] == _strategies[i].strategy) revert DuplicateStrategy();
            }
            _holdStrategies[i] = _strategies[i].strategy;
            strategies.push(_strategies[i]);
        }

        refreshApprovals();
        emit StrategiesSet(_strategies);
    }

    /// @notice This function allows for changing the allocations of current strategies
    function setBpsForStrategies(uint16[] calldata _bps) external onlyOwner {
        uint256 _length = strategies.length;
        if (_bps.length != _length) revert InvalidArrayLength();
        uint256 _totalBps = 0;
        for (uint256 i = 0; i < _length; i++) {
            strategies[i].bps = _bps[i];
            _totalBps += _bps[i];
        }
        if (_totalBps != BPS) revert InvalidBps();
        emit StrategiesSet(strategies);
    }

    /// @notice This function allows a user to rebalance a receipt (ERC1155) token's underlying assets. 
    /// @dev This function utilizes the internal _deposit and _withdraw functions to rebalance based on 
    /// the strategies set in the contract. Since _deposit will set the TokenInfo.deposit to the total 
    /// deposited after the rebalance, we must store the original deposit and overwrite the TokenInfo
    /// before completing the transaction.
    function rebalance(uint256 _tokenId) public override nonReentrant whileNotPaused returns(TokenInfo memory) {
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotTokenOwner();
        uint256 _originalDeposit = tokenInfo[_tokenId].deposit;

        // withdraw from strategies first
        (uint256 _amount, ) = _withdraw(_tokenId);

        // delete token info
        delete tokenInfo[_tokenId];

        // deposit to (possibly new) strategies
        _deposit(_amount, _tokenId, false);
        
        // set deposit to original deposit to ensure withdrawal profit calculations are correct
        tokenInfo[_tokenId].deposit = _originalDeposit;
        TokenInfo memory _info = tokenInfo[_tokenId];

        // refund left over tokens, if any
        _refund(_info);

        emit Rebalance(_tokenId, _amount, _info);
        return _info;
    }

    /// @notice View function that returns all TokenInfo for a specific receipt
    function getTokenInfo(uint256 _tokenId) public view override returns(TokenInfo memory) {
        return tokenInfo[_tokenId];
    }

    /// @notice View function that returns all strategies
    function getStrategies() public view override returns(Strategy[] memory) {
        return strategies;
    }

    /// @notice Internal function to mint receipt and advance nextToken state variable.
    function _mintReceipt() internal returns(uint256 _tokenId) {
        _tokenId = nextToken;
        _mint(msg.sender, _tokenId, 1, "");
        nextToken += 1;
    }

    /// @notice Internal deposit function.
    /// @dev This function will loop through the strategies in order split/deposit the user's deposited tokens. 
    /// The function handles additions slightly differently, requiring that the current strategies match the 
    /// strategies that were set at the time of original deposit. 
    function _deposit(uint256 _amount, uint256 _tokenId, bool _isAdd) internal {
        TokenInfo storage _info = tokenInfo[_tokenId];
        uint256 _remainder = _amount;

        uint256 _length = strategies.length;
        for (uint256 i = 0; i < _length; i++) {
            Strategy memory _strategy = strategies[i];

            // cannot add to position if strategies have changed. must rebalance first
            if (_isAdd) {
                if (_strategy.strategy != _info.positions[i].strategy.strategy) revert CantAddToReceipt();
            }
            
            IStrategy _strat = IStrategy(_strategy.strategy);
            uint256 _receiptBalance = _strat.balanceOf(address(this));

            if (i == (_length - 1)) {
                if (_strategy.isFortiFi) {
                    _strat.depositToFortress(_remainder, msg.sender, _tokenId);
                } else {
                    _strat.deposit(_remainder);
                }
            } else {
                uint256 _split = _amount * _strategy.bps / BPS;
                _remainder -= _split;
                if (_strategy.isFortiFi) {
                    _strat.depositToFortress(_split, msg.sender, _tokenId);
                } else {
                    _strat.deposit(_split);
                }
            }

            if (_isAdd) {
                _info.positions[i].receipt += _strat.balanceOf(address(this)) - _receiptBalance;
            } else {
                _info.positions.push(Position({strategy: _strategy, receipt: _strat.balanceOf(address(this)) - _receiptBalance}));
            }
        }

        _info.deposit += _amount;
    }

    /// @notice Internal withdraw function that withdraws from strategies and calculates profits.
    function _withdraw(uint256 _tokenId) internal returns(uint256 _proceeds, uint256 _profit) {
        TokenInfo memory _info = tokenInfo[_tokenId];
        uint256 _length = _info.positions.length;

        for (uint256 i = 0 ; i < _length; i++) {
            IStrategy _strat = IStrategy(_info.positions[i].strategy.strategy);
            if (_info.positions[i].strategy.isFortiFi) {
                _strat.withdrawFromFortress(_info.positions[i].receipt, msg.sender, _tokenId);
            } else {
                _strat.withdraw(_info.positions[i].receipt);
            }
        }

        _proceeds = IERC20(depositToken).balanceOf(address(this));

        if (_proceeds > _info.deposit) {
            _profit = _proceeds - _info.deposit;
        } else {
            _profit = 0;
        }
    }

    /// @notice Internal function to refund left over tokens from deposit/add/rebalance transactions
    function _refund(TokenInfo memory _info) internal {
        // Refund left over deposit tokens, if any
        uint256 _depositTokenBalance = IERC20(depositToken).balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _info.deposit -= _depositTokenBalance;
            IERC20(depositToken).safeTransfer(msg.sender, _depositTokenBalance);
        }

        // Refund left over wrapped native tokens, if any
        uint256 _wrappedNativeTokenBalance = IERC20(wrappedNative).balanceOf(address(this));
        if (_wrappedNativeTokenBalance > 0) {
            IERC20(wrappedNative).safeTransfer(msg.sender, _wrappedNativeTokenBalance);
        }

        // Refund left over native tokens, if any
        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    if (!success) revert FailedToRefund();
        }
    }

    /// @notice Override to allow FortiFiStrategy contracts to verify that specified vaults implement ISAMS interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(ISAMS).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}