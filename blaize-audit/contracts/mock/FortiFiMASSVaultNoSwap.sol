// SPDX-License-Identifier: GPL-3.0-only
// FortiFiMASSVault by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../strategies/interfaces/IStrategy.sol";
import "../strategies/interfaces/IVectorStrategy.sol";
import "../fee-calculators/interfaces/IFortiFiFeeCalculator.sol";
import "../fee-managers/interfaces/IFortiFiFeeManager.sol";
import "../vaults/interfaces/IMASS.sol";
import "../vaults/interfaces/ISAMS.sol";
import "../vaults/interfaces/IRouter.sol";

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

/// @notice Error caused when swap fails
error SwapFailed();

/// @notice Error caused when trying to use a token with less decimals than USDC
error InvalidDecimals();

/// @notice Error caused when trying to set oracle to an invalid address
error InvalidOracle();

/// @notice Error caused by trying to set minDeposit below BPS
error InvalidMinDeposit();

/// @notice Error caused by trying to set a slippage too high
error InvalidSlippage();

/// @notice Error caused by mismatching array lengths
error InvalidArrayLength();

/// @notice Error caused when bps does not equal 10_000
error InvalidBps();

/// @notice Error caused when trying to transact with contract while paused
error ContractPaused();

/// @title Contract for FortiFi MASS Vaults
/// @notice This contract allows for the deposit of a single asset, which is then swapped into various assets and deposited in to 
/// multiple yield-bearing strategies. 
/// @dev THIS IS A TEST CONTRACT WITH NO SWAP FEATURE FOR BASIC TESTING - DO NOT DEPLOY
contract FortiFiMASSVaultNoSwap is IMASS, ERC1155Supply, IERC1155Receiver, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    address public depositToken;
    address public wrappedNative;
    uint8 public constant DECIMALS = 6; // USDC ONLY
    uint16 public constant BPS = 10_000;
    uint16 public slippageBps = 100;
    uint256 public minDeposit = 30_000;
    uint256 public nextToken = 1;
    bool public paused = true;

    IFortiFiFeeCalculator public feeCalc;
    IFortiFiFeeManager public feeMgr;

    Strategy[] public strategies;

    mapping(uint256 => TokenInfo) public tokenInfo;

    event Deposit(address indexed depositor, uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Add(address indexed depositor, uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Rebalance(uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Withdrawal(address indexed depositor, uint256 indexed tokenId, uint256 amountWithdrawn, uint256 profit, uint256 fee);

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
        Strategy[] memory _strategies) ERC1155(_metadata) {
        if (_wrappedNative == address(0)) revert ZeroAddress();
        if (_depositToken == address(0)) revert ZeroAddress();
        if (_feeManager == address(0)) revert ZeroAddress();
        if (_feeCalculator == address(0)) revert ZeroAddress();
        name = _name; 
        symbol = _symbol;
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
        IERC20 _depositToken = IERC20(depositToken);
        require(_depositToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to xfer deposit");
        _tokenId = _mintReceipt();
        _deposit(_amount, _tokenId, false);
        _info = tokenInfo[_tokenId];

        // refund left over tokens, if any
        _refund(_info);

        emit Deposit(msg.sender, _tokenId, _amount, _info);
    }

    /// @notice This function is used to add to a user's deposit when they already has a receipt (ERC1155). The user can add to their 
    /// deposit without needing to burn/withdraw first. 
    function add(uint256 _amount, uint256 _tokenId) external override nonReentrant whileNotPaused returns(TokenInfo memory _info) {
        if (_amount < minDeposit) revert InvalidDeposit();
        IERC20 _depositToken = IERC20(depositToken);
        require(_depositToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to xfer deposit");
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotTokenOwner();
        _deposit(_amount, _tokenId, true);
        _info = tokenInfo[_tokenId];

        // refund left over tokens, if any
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
        uint256 _fee = feeCalc.getFees(msg.sender, _profit);
        feeMgr.collectFees(depositToken, _fee);
         
        require(IERC20(depositToken).transfer(msg.sender, _amount - _fee), "FortiFi: Failed to send proceeds");

        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    if (!success) revert FailedToRefund();
        }

        emit Withdrawal(msg.sender, _tokenId, _amount, _profit, _fee);
    }

    function setMinDeposit(uint256 _amount) external onlyOwner {
        minDeposit = _amount;
    }

    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
    }

    function setFeeManager(address _contract) external onlyOwner {
        feeMgr = IFortiFiFeeManager(_contract);
    }

    function setFeeCalculator(address _contract) external onlyOwner {
        feeCalc = IFortiFiFeeCalculator(_contract);
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function recoverERC1155(address _token, uint256[] calldata _tokenIds, uint256[] calldata _amounts) external onlyOwner {
        IERC1155(_token).safeBatchTransferFrom(
            address(this),
            msg.sender,
            _tokenIds,
            _amounts,
            ""
        );
    }

    /// @notice Function to set max approvals for router and strategies. 
    /// @dev Since contract never holds deposit tokens max approvals should not matter. 
    function refreshApprovals() public {
        uint256 _length = strategies.length;
        IERC20 _depositToken = IERC20(depositToken);

        IERC20(depositToken).approve(address(feeMgr), type(uint256).max);
        for(uint256 i = 0; i < _length; i++) {
            IERC20(strategies[i].depositToken).approve(strategies[i].strategy, type(uint256).max);
            IERC20(strategies[i].depositToken).approve(strategies[i].router, type(uint256).max);
            _depositToken.approve(strategies[i].router, type(uint256).max);
        }
    }

    /// @notice This function sets up the underlying strategies used by the vault.
    function setStrategies(Strategy[] memory _strategies) public onlyOwner {
        uint256 _length = _strategies.length;
        if (_length == 0) revert NoStrategies();

        address[] memory _holdStrategies = new address[](_length);

        uint16 _bps = 0;
        for (uint256 i = 0; i < _length; i++) {
            _bps += _strategies[i].bps;
        }
        if (_bps != BPS) revert InvalidBps();

        delete strategies; // remove old array, if any

        for (uint256 i = 0; i < _length; i++) {
            if (_strategies[i].strategy == address(0)) revert ZeroAddress();
            if (_strategies[i].depositToken == address(0)) revert ZeroAddress();
            if (_strategies[i].router == address(0)) revert ZeroAddress();
            if (_strategies[i].oracle == address(0) &&
                    _strategies[i].depositToken != depositToken) revert InvalidOracle();
            if (_strategies[i].decimals <= DECIMALS &&
                    _strategies[i].depositToken != depositToken) revert InvalidDecimals();
            for (uint256 j = 0; j < i; j++) {
                if (_holdStrategies[j] == _strategies[i].strategy) revert DuplicateStrategy();
            }
            _holdStrategies[i] = _strategies[i].strategy;
            strategies.push(_strategies[i]);
        }

        refreshApprovals();
    }

    /// @notice This function allows a user to rebalance a receipt (ERC1155) token's underlying assets. 
    /// @dev This function utilizes the internal _deposit and _withdraw functions to rebalance based on 
    /// the strategies set in the contract. Since _deposit will set the TokenInfo.deposit to the total 
    /// deposited after the rebalance, we must store the original deposit and overwrite the TokenInfo
    /// before completing the transaction.
    function rebalance(uint256 _tokenId) public override nonReentrant whileNotPaused returns(TokenInfo memory) {
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotTokenOwner();
        uint256 _originalDeposit = tokenInfo[_tokenId].deposit;
        (uint256 _amount, ) = _withdraw(_tokenId);
        delete tokenInfo[_tokenId];
        _deposit(_amount, _tokenId, false);
        tokenInfo[_tokenId].deposit = _originalDeposit;
        TokenInfo memory _info = tokenInfo[_tokenId];

        // refund left over tokens, if any
        _refund(_info);

        emit Rebalance(_tokenId, _amount, _info);
        return _info;
    }

    /// @notice View function that returns all strategies
    function getStrategies() public view override returns(Strategy[] memory) {
        return strategies;
    }

    function _mintReceipt() internal returns(uint256 _tokenId) {
        _tokenId = nextToken;
        _mint(msg.sender, _tokenId, 1, "");
        nextToken += 1;
    }

    /// @notice Internal swap function for deposits.
    function _swapFromDepositToken(uint256 _amount, Strategy memory _strat) internal returns(uint256) {
        return _amount; 
    }

    /// @notice Internal swap function for withdrawals.

    function _swapToDepositToken(uint256 _amount, Strategy memory _strat) internal returns(uint256) {
        return _amount; 
    }

    /// @notice Internal deposit function.
    /// @dev This function will loop through the strategies in order split/swap/deposit the user's deposited tokens. 
    /// The function handles additions slightly differently, requiring that the current strategies match the 
    /// strategies that were set at the time of original deposit. 
    function _deposit(uint256 _amount, uint256 _tokenId, bool _isAdd) internal {
        TokenInfo storage _info = tokenInfo[_tokenId];
        uint256 _remainder = _amount;

        uint256 _length = strategies.length;
        for (uint256 i = 0; i < _length; i++) {
            Strategy memory _strategy = strategies[i];

            // cannot add to deposit if strategies have changed. must rebalance first
            if (_isAdd) {
                if (_strategy.strategy != _info.positions[i].strategy.strategy) revert CantAddToReceipt();
            }
            
            bool _isSAMS = _strategy.isSAMS;
            uint256 _receiptToken = 0;
            uint256 _depositAmount = 0;

            // split deposit and swap if necessary
            if (i == (_length - 1)) {
                if (depositToken != _strategy.depositToken) {
                    _depositAmount = _swapFromDepositToken(_remainder, _strategy);
                } else {
                    _depositAmount = _remainder;
                }    
            } else {
                uint256 _split = _amount * _strategy.bps / BPS;
                if (depositToken != _strategy.depositToken) {
                    _depositAmount = _swapFromDepositToken(_split, _strategy);
                } else {
                    _depositAmount = _split;
                }    
                _remainder -= _split;
            }
            
            if (_isSAMS) {
                if (_isAdd) {
                    _addSAMS(_depositAmount, _strategy.strategy, _info.positions[i].receipt);
                } else {
                    // if position is new, deposit and push to positions
                    _receiptToken = _depositSAMS(_depositAmount, _strategy.strategy);
                    _info.positions.push(Position({strategy: _strategy, receipt: _receiptToken}));
                }
            } else {
                IStrategy _strat = IStrategy(_strategy.strategy);

                // set current receipt balance
                uint256 _receiptBalance = _strat.balanceOf(address(this));

                // deposit based on type of strategy
                if (_strategy.isFortiFi) {
                    _strat.depositToFortress(_depositAmount, msg.sender, _tokenId);
                } else {
                    _strat.deposit(_depositAmount);
                }

                if (_isAdd) {
                    _info.positions[i].receipt += _strat.balanceOf(address(this)) - _receiptBalance;
                } else {
                    _info.positions.push(Position({strategy: _strategy, receipt: _strat.balanceOf(address(this)) - _receiptBalance}));
                }
            }
        }

        _info.deposit += _amount;
    }

    function _depositSAMS(uint256 _amount, address _strategy) internal returns (uint256 _receiptToken) {
        ISAMS _sams = ISAMS(_strategy);
        ISAMS.TokenInfo memory _receiptInfo;

        (_receiptToken, _receiptInfo) = _sams.deposit(_amount);
    }

    function _addSAMS(uint256 _amount, address _strategy, uint256 _tokenId) internal {
        ISAMS _sams = ISAMS(_strategy);
        ISAMS.TokenInfo memory _receiptInfo;

        _receiptInfo = _sams.add(_amount, _tokenId);
    }

    /// @notice Internal withdraw function that withdraws from strategies and calculates profits.
    function _withdraw(uint256 _tokenId) internal returns(uint256 _proceeds, uint256 _profit) {
        TokenInfo memory _info = tokenInfo[_tokenId];
        uint256 _length = _info.positions.length;
        _proceeds = 0;

        for (uint256 i = 0 ; i < _length; i++) {
            // withdraw based on the type of underlying strategy, if not SAMS check if FortiFi strategy
            if (_info.positions[i].strategy.isSAMS) {
                ISAMS _strat = ISAMS(_info.positions[i].strategy.strategy);
                _strat.withdraw(_info.positions[i].receipt);
            } else {
                IStrategy _strat = IStrategy(_info.positions[i].strategy.strategy);
                if (_info.positions[i].strategy.isFortiFi) {
                    _strat.withdrawFromFortress(_info.positions[i].receipt, msg.sender, _tokenId);
                } else {
                    _strat.withdraw(_info.positions[i].receipt);
                }
            }

            // swap out for deposit tokens 
            uint256 _depositTokenProceeds = IERC20(_info.positions[i].strategy.depositToken).balanceOf(address(this));
            _swapToDepositToken(_depositTokenProceeds, _info.positions[i].strategy);
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
            require(IERC20(depositToken).transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        // Refund left over wrapped native tokens, if any
        uint256 _wrappedNativeTokenBalance = IERC20(wrappedNative).balanceOf(address(this));
        if (_wrappedNativeTokenBalance > 0) {
            require(IERC20(wrappedNative).transfer(msg.sender, _wrappedNativeTokenBalance), "FortiFi: Failed to refund native");
        }

        // Refund left over native tokens, if any
        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    if (!success) revert FailedToRefund();
        }
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

}