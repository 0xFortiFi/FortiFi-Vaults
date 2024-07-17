// SPDX-License-Identifier: GPL-3.0-only
// FortiFiWNativeMASSVault V3 by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../strategies/interfaces/IStrategy.sol";
import "../fee-calculators/interfaces/IFortiFiFeeCalculator.sol";
import "../fee-managers/interfaces/IFortiFiFeeManager.sol";
import "../oracles/interfaces/IFortiFiPriceOracle.sol";
import "./interfaces/IMASS.sol";
import "./interfaces/IRouter.sol";

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

/// @notice Error caused by trying to use recoverERC20 to withdraw strategy receipt tokens
error CantWithdrawStrategyReceipts();

/// @notice Error caused when trying to deposit to bricked strategy
error StrategyBricked();

/// @title Contract for FortiFi Wrapped Native MASS Vaults V2
/// @notice This contract allows for the deposit of wrapped native tokens, which is then swapped into various assets and deposited in to 
/// multiple yield-bearing strategies. 
/// @dev This V3 contract updated swap logic that incorrectly set slippage for swaps back to the deposit token
contract FortiFiWNativeMASSVaultV3 is IMASS, ERC1155Supply, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    string public name;
    string public symbol;
    address public immutable wrappedNative;
    uint8 public constant WNATIVE_DECIMALS = 18;
    uint16 public constant SWAP_DEADLINE_BUFFER = 1800;
    uint16 public constant BPS = 10_000;
    uint16 public slippageBps = 25;
    uint256 public minDeposit = 30_000;
    uint256 public nextToken = 1;
    bool public paused = true;

    IFortiFiFeeCalculator public feeCalc;
    IFortiFiFeeManager public feeMgr;
    IFortiFiPriceOracle public nativeOracle;

    Strategy[] public strategies;

    mapping(uint256 => TokenInfo) private tokenInfo;
    mapping(address => bool) public strategyIsBricked;


    event Deposit(address indexed depositor, uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Add(address indexed depositor, uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Rebalance(uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Withdrawal(address indexed depositor, uint256 indexed tokenId, uint256 amountWithdrawn, uint256 profit, uint256 fee);
    event ApprovalsRefreshed();
    event StrategiesSet(Strategy[]);
    event MinDepositSet(uint256 minAmount);
    event SlippageSet(uint16 slippage);
    event FeeManagerSet(address feeManager);
    event FeeCalculatorSet(address feeCalculator);
    event NativeOracleSet(address oracle);
    event PauseStateUpdated(bool paused);

    /// @notice Used to restrict function access while paused.
    modifier whileNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }

    constructor(string memory _name, 
        string memory _symbol, 
        string memory _metadata,
        address _wrappedNative,
        address _feeManager,
        address _feeCalculator,
        address _nativeOracle,
        Strategy[] memory _strategies) ERC1155(_metadata) {
        if (_wrappedNative == address(0)) revert ZeroAddress();
        if (_feeManager == address(0)) revert ZeroAddress();
        if (_feeCalculator == address(0)) revert ZeroAddress();
        if (_nativeOracle == address(0)) revert ZeroAddress();
        name = _name; 
        symbol = _symbol;
        wrappedNative = _wrappedNative;
        feeCalc = IFortiFiFeeCalculator(_feeCalculator);
        feeMgr = IFortiFiFeeManager(_feeManager);
        nativeOracle = IFortiFiPriceOracle(_nativeOracle);
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
        IERC20(wrappedNative).safeTransferFrom(msg.sender, address(this), _amount);
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
        IERC20(wrappedNative).safeTransferFrom(msg.sender, address(this), _amount);
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
    function withdraw(uint256 _tokenId) external override nonReentrant {
        if (balanceOf(msg.sender, _tokenId) == 0) revert NotTokenOwner();
        _burn(msg.sender, _tokenId, 1);

        (uint256 _amount, uint256 _profit) = _withdraw(_tokenId);
        uint256 _fee = feeCalc.getFees(msg.sender, _profit);
        feeMgr.collectFees(wrappedNative, _fee);
        
        IERC20(wrappedNative).safeTransfer(msg.sender, _amount - _fee);

        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    if (!success) revert FailedToRefund();
        }

        emit Withdrawal(msg.sender, _tokenId, _amount, _profit, _fee);
    }

    /// @notice Function to set minimum deposit
    function setMinDeposit(uint256 _amount) external onlyOwner {
        if (_amount < 30_000) revert InvalidMinDeposit();
        minDeposit = _amount;
        emit MinDepositSet(_amount);
    }

    /// @notice Function to set slippage used in swap functions. Must be 0.1-5% (10-500)
    function setSlippage(uint16 _amount) external onlyOwner {
        if (_amount < 10 || _amount > 500) revert InvalidSlippage();
        slippageBps = _amount;
        emit SlippageSet(_amount);
    }

    /// @notice Function to set new FortiFiFeeManager contract
    function setFeeManager(address _contract) external onlyOwner {
        if (_contract == address(0)) revert ZeroAddress();
        feeMgr = IFortiFiFeeManager(_contract);
        emit FeeManagerSet(_contract);
    }

    /// @notice Function to set new FortiFiFeeCalculator contract
    function setFeeCalculator(address _contract) external onlyOwner {
        if (_contract == address(0)) revert ZeroAddress();
        feeCalc = IFortiFiFeeCalculator(_contract);
        emit FeeCalculatorSet(_contract);
    }

    
    /// @notice Function to set a strategy as bricked
    function setStrategyAsBricked(address _strategy, bool _bool) external onlyOwner {
        strategyIsBricked[_strategy] = _bool;
    }

    /// @notice Function to set new native oracle contract
    function setNativeOracle(address _contract) external onlyOwner {
        if (_contract == address(0)) revert ZeroAddress();
        nativeOracle = IFortiFiPriceOracle(_contract);
        emit NativeOracleSet(_contract);
    }

    /// @notice Function to flip paused state
    function flipPaused() external onlyOwner {
        paused = !paused;
        emit PauseStateUpdated(paused);
    }

    /// @notice Emergency function to recover stuck ERC20 tokens
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        uint256 _length = strategies.length;
        for (uint256 i = 0; i < _length; i++) {
            if (_token == strategies[i].strategy) {
                revert CantWithdrawStrategyReceipts();
            }
        }
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /// @notice Function to set max approvals for router and strategies. 
    /// @dev Since contract never holds deposit tokens max approvals should not matter. 
    function refreshApprovals() public {
        uint256 _length = strategies.length;
        IERC20 _depositToken = IERC20(wrappedNative);

        _depositToken.approve(address(feeMgr), type(uint256).max);
        for(uint256 i = 0; i < _length; i++) {
            IERC20(strategies[i].depositToken).approve(strategies[i].strategy, type(uint256).max);
            IERC20(strategies[i].depositToken).approve(strategies[i].router, type(uint256).max);
            _depositToken.approve(strategies[i].router, type(uint256).max);
        }
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
            if (_strategies[i].depositToken == address(0)) revert ZeroAddress();
            if (_strategies[i].router == address(0)) revert ZeroAddress();
            if (_strategies[i].depositToken != wrappedNative &&
                (_strategies[i].oracle == address(0) ||
                 _strategies[i].depositToken != IFortiFiPriceOracle(_strategies[i].oracle).token() ||
                 IFortiFiPriceOracle(_strategies[i].oracle).decimals() != nativeOracle.decimals()) 
               ) revert InvalidOracle();
            for (uint256 j = 0; j < i; j++) {
                if (_holdStrategies[j] == _strategies[i].strategy) revert DuplicateStrategy();
            }
            _holdStrategies[i] = _strategies[i].strategy;
            strategies.push(_strategies[i]);
        }

        refreshApprovals();
        emit StrategiesSet(_strategies);
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

        //delete token info
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

    /// @notice View function that returns all strategies
    function getStrategies() public view override returns(Strategy[] memory) {
        return strategies;
    }

    /// @notice View function that returns tokenInfo
    function getTokenInfo(uint256 _tokenId) public view returns(TokenInfo memory) {
        return tokenInfo[_tokenId];
    }

    /// @notice Internal function to mint ERC1155 receipts and advance nextToken state variable
    function _mintReceipt() internal returns(uint256 _tokenId) {
        _tokenId = nextToken;
        _mint(msg.sender, _tokenId, 1, "");
        nextToken += 1;
    }

    /// @notice Internal swap function for deposits.
    /// @dev This function can use any uniswapV2-style router to swap from deposited tokens to the strategy deposit tokens.
    /// since this contract does not hold strategy deposit tokens, return contract balance after swap.
    function _swapFromDepositTokenDirect(uint256 _amount, Strategy memory _strat) internal returns(uint256) {
        address _strategyDepositToken = _strat.depositToken;
        address[] memory _route = new address[](2);
        IRouter _router = IRouter(_strat.router);
        IFortiFiPriceOracle _oracle = IFortiFiPriceOracle(_strat.oracle);
        
        _route[0] = wrappedNative;
        _route[1] = _strategyDepositToken;

        uint256 _latestPriceNative = nativeOracle.getPrice();
        uint256 _latestPriceTokenB = _oracle.getPrice();
        uint256 _swapAmount = _amount * _latestPriceNative * 10**18 / _latestPriceTokenB / 10**18 / 10**(WNATIVE_DECIMALS - _strat.decimals);

        _router.swapExactTokensForTokens(_amount, 
            (_swapAmount * (BPS - slippageBps) / BPS), 
            _route, 
            address(this), 
            block.timestamp + SWAP_DEADLINE_BUFFER);

        uint256 _strategyDepositTokenBalance = IERC20(_strategyDepositToken).balanceOf(address(this));
        if (_strategyDepositTokenBalance == 0) revert SwapFailed();

        return _strategyDepositTokenBalance;
    }

    /// @notice Internal swap function for withdrawals
    /// @dev This function can use any uniswapV2-style router to swap from deposited tokens to the strategy deposit tokens.
    function _swapToDepositTokenDirect(uint256 _amount, Strategy memory _strat) internal {
        address _strategyDepositToken = _strat.depositToken;
        address[] memory _route = new address[](2);
        IRouter _router = IRouter(_strat.router);
        IFortiFiPriceOracle _oracle = IFortiFiPriceOracle(_strat.oracle);

        _route[0] = _strategyDepositToken;
        _route[1] = wrappedNative;
        
        uint256 _latestPriceNative = nativeOracle.getPrice();
        uint256 _latestPriceTokenB = _oracle.getPrice();

        uint256 _swapAmount = _amount * _latestPriceTokenB * 10**18 * 10**(WNATIVE_DECIMALS - _strat.decimals) / 10**18 / _latestPriceNative;

        _router.swapExactTokensForTokens(_amount, 
            (_swapAmount * (BPS - slippageBps) / BPS), 
            _route, 
            address(this), 
            block.timestamp + SWAP_DEADLINE_BUFFER);

        uint256 _depositTokenBalance = IERC20(wrappedNative).balanceOf(address(this));
        if (_depositTokenBalance == 0) revert SwapFailed();
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

            if (strategyIsBricked[_strategy.strategy]) revert StrategyBricked();

            // cannot add to deposit if strategies have changed. must rebalance first
            if (_isAdd) {
                if (_strategy.strategy != _info.positions[i].strategy.strategy) revert CantAddToReceipt();
            }
            
            uint256 _depositAmount = 0;

            // split deposit and swap if necessary
            if (i == (_length - 1)) {
                if (wrappedNative != _strategy.depositToken) {
                    _depositAmount = _swapFromDepositTokenDirect(_remainder, _strategy);
                } else {
                    _depositAmount = _remainder;
                }    
            } else {
                uint256 _split = _amount * _strategy.bps / BPS;
                if (wrappedNative != _strategy.depositToken) {
                    _depositAmount = _swapFromDepositTokenDirect(_split, _strategy);
                } else {
                    _depositAmount = _split;
                }    
                _remainder -= _split;
            }
            
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

        _info.deposit += _amount;
    }

    /// @notice Internal withdraw function that withdraws from strategies and calculates profits.
    function _withdraw(uint256 _tokenId) internal returns(uint256 _proceeds, uint256 _profit) {
        TokenInfo memory _info = tokenInfo[_tokenId];
        uint256 _length = _info.positions.length;
        _proceeds = 0;

        for (uint256 i = 0 ; i < _length; i++) {
            // withdraw based on the type of underlying strategy, if not SAMS check if FortiFi strategy
            IStrategy _strat = IStrategy(_info.positions[i].strategy.strategy);
            bool _bricked = strategyIsBricked[_info.positions[i].strategy.strategy];

            if (_bricked) {
                // send receipt tokens to user without withdrawing from strategy
                IERC20(_info.positions[i].strategy.strategy).safeTransfer(msg.sender, _info.positions[i].receipt);
            } else if (_info.positions[i].strategy.isFortiFi) {
                _strat.withdrawFromFortress(_info.positions[i].receipt, msg.sender, _tokenId);
            } else {
                _strat.withdraw(_info.positions[i].receipt);
            }

            // swap out for deposit tokens if needed
            if (_info.positions[i].strategy.depositToken != wrappedNative && !_bricked) {
                uint256 _strategyDepositTokenProceeds = IERC20(_info.positions[i].strategy.depositToken).balanceOf(address(this));
                _swapToDepositTokenDirect(_strategyDepositTokenProceeds, _info.positions[i].strategy);
            }  
        }

        _proceeds = IERC20(wrappedNative).balanceOf(address(this));
        
        if (_proceeds > _info.deposit) {
            _profit = _proceeds - _info.deposit;
        } else {
            _profit = 0;
        }
    }

    /// @notice Internal function to refund left over tokens from deposit/add/rebalance transactions
    function _refund(TokenInfo memory _info) internal {
        // Refund left over deposit tokens, if any
        uint256 _depositTokenBalance = IERC20(wrappedNative).balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _info.deposit -= _depositTokenBalance;
            IERC20(wrappedNative).safeTransfer(msg.sender, _depositTokenBalance);
        }

        // Refund left over native tokens, if any
        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    if (!success) revert FailedToRefund();
        }
    }

    /// @notice Override to allow FortiFiStrategy contracts to verify that specified vaults implement IMASS interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(IMASS).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}