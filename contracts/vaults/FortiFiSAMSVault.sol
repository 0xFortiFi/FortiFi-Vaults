// SPDX-License-Identifier: MIT
// FortiFiVault by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../strategies/interfaces/IStrategy.sol";
import "../strategies/interfaces/IVectorStrategy.sol";
import "../fee-calculators/interfaces/IFortiFiFeeCalculator.sol";
import "../fee-managers/interfaces/IFortiFiFeeManager.sol";

pragma solidity ^0.8.2;

/// @title Contract for FortiFi SAMS Vaults
/// @notice This contract allows for the deposit of a single asset, which is then split and deposited in to 
/// multiple yield-bearing strategies. 
contract FortiFiSAMSVault is ERC1155Supply, Ownable, ReentrancyGuard {
    struct Strategy {
        address strategy;
        bool isVector;
        uint16 bps;
    }

    struct Position {
        Strategy strategy;
        uint256 receipt;
    }

    struct TokenInfo {
        uint256 deposit;
        Position[] positions;
    }

    string public name;
    string public symbol;
    address public depositToken;
    uint16 public constant BPS = 10_000;
    uint16 public slippageBps = 100;
    uint256 public minDeposit;
    uint256 public nextToken = 1;
    bool public paused = true;

    IFortiFiFeeCalculator public feeCalc;
    IFortiFiFeeManager public feeMgr;

    Strategy[] public strategies;

    mapping(uint256 => TokenInfo) public tokenInfo;

    event Deposit(address indexed depositor, uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Rebalance(uint256 indexed tokenId, uint256 amount, TokenInfo tokenInfo);
    event Withdrawal(address indexed depositor, uint256 indexed tokenId, uint256 amountWithdrawn, uint256 profit, uint256 fee);

    /// @notice Used to restrict function access while paused.
    modifier whileNotPaused() {
        require(!paused, "FortiFi: Contract paused");
        _;
    }

    constructor(string memory _name, 
        string memory _symbol, 
        string memory _metadata,
        address _depositToken,
        address _feeManager,
        address _feeCalculator,
        address[] memory _strategies,
        bool[] memory _isVector,
        uint16[] memory _strategyBps,
        uint256 _minDeposit) ERC1155(_metadata) {
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        require(_feeManager != address(0), "FortiFi: Invalid feeManager");
        require(_feeCalculator != address(0), "FortiFi: Invalid feeCalculator");
        require(_minDeposit >= BPS, "FortiFi: Invalid min deposit");
        name = _name; 
        symbol = _symbol;
        minDeposit = _minDeposit;
        depositToken = _depositToken;
        feeCalc = IFortiFiFeeCalculator(_feeCalculator);
        feeMgr = IFortiFiFeeManager(_feeManager);
        setStrategies(_strategies, _isVector, _strategyBps);
    }

    /// @notice This function is used when a user does not already have a receipt (ERC1155). 
    /// @dev The user must deposit at least the minDeposit, and will receive an ERC1155 non-fungible receipt token. 
    /// The receipt token will be mapped to a TokenInfo containing the amount deposited as well as the strategy receipt 
    /// tokens received for later withdrawal.
    function deposit(uint256 _amount) external nonReentrant whileNotPaused returns(uint256 _tokenId, TokenInfo memory _info) {
        require(_amount > minDeposit, "FortiFi: Invalid deposit amount");
        require(IERC20(depositToken).transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to xfer deposit");
        _tokenId = _mintReceipt();
        _deposit(_amount, _tokenId, false);
        _info = tokenInfo[_tokenId];

        emit Deposit(msg.sender, _tokenId, _amount, _info);
    }

    /// @notice This function is used to add to a user's deposit when they already has a receipt (ERC1155). The user can add to their 
    /// deposit without needing to burn/withdraw first. 
    function add(uint256 _amount, uint256 _tokenId) external nonReentrant whileNotPaused returns(TokenInfo memory _info) {
        require(_amount > minDeposit, "FortiFi: Invalid deposit amount");
        require(IERC20(depositToken).transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to xfer deposit");
        require(balanceOf(msg.sender, _tokenId) > 0, "FortiFi: Not the owner of token");
        _deposit(_amount, _tokenId, true);
        _info = tokenInfo[_tokenId];

        emit Deposit(msg.sender, _tokenId, _amount, _info);
    }

    /// @notice This function is used to burn a receipt (ERC1155) and withdraw all underlying strategy receipt tokens. 
    /// @dev Once all receipts are burned and deposit tokens received, the fee manager will calculate the fees due, 
    /// and the fee manager will distribute those fees before transfering the user their proceeds.
    function withdraw(uint256 _tokenId) external nonReentrant whileNotPaused {
        require(balanceOf(msg.sender, _tokenId) > 0, "FortiFi: Not the owner of token");
        _burn(msg.sender, _tokenId, 1);

        (uint256 _amount, uint256 _profit) = _withdraw(_tokenId);
        uint256 _fee = feeCalc.getFees(msg.sender, _profit);
        feeMgr.collectFees(depositToken, _fee);
        
        require(IERC20(depositToken).transfer(msg.sender, _amount - _fee), "FortiFi: Failed to send proceeds");
        emit Withdrawal(msg.sender, _tokenId, _amount, _profit, _fee);
    }

    /// @notice This function can be used to force the rebalance of deposits. Should only be used in situations
    /// where an exploit of an underlying strategy requires immediate removal of that strategy. 
    function forceRebalance(uint256[] calldata _tokenIds) external onlyOwner {
        uint256 _length = _tokenIds.length;
        for (uint256 i = 0; i < _length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (exists(_tokenId)) {
                rebalance(_tokenId);
            }
        }
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

    function refreshApprovals() public {
        IERC20 _depositToken = IERC20(depositToken);
        uint8 _length = uint8(strategies.length);

        for(uint8 i = 0; i < _length; i++) {
            _depositToken.approve(strategies[i].strategy, type(uint256).max);
        }

        _depositToken.approve(address(feeMgr), type(uint256).max);
    }

    /// @notice This function sets up the underlying strategies used by the vault.
    function setStrategies(address[] memory _strategies, bool[] memory _isVector, uint16[] memory _strategyBps) public onlyOwner {
        uint8 _length = uint8(_strategies.length);
        require(_length > 0 &&
                _length == _isVector.length &&
                _length == _strategyBps.length, "FortiFi: Array length mismatch");

        uint16 _bps = 0;
        for (uint8 i = 0; i < _length; i++) {
            _bps += _strategyBps[i];
        }
        require(_bps == BPS, "FortiFi: Invalid bps array");

        delete strategies; // remove old array, if any

        for (uint8 i = 0; i < _length; i++) {
            require(_strategies[i] != address(0), "FortiFi: Invalid strat address");
            Strategy memory _strategy = Strategy({strategy: _strategies[i], isVector: _isVector[i], bps: _strategyBps[i]});
            strategies.push(_strategy);
        }

        refreshApprovals();
    }

    /// @notice This function allows a user to rebalance a receipt (ERC1155) token's underlying assets. 
    /// @dev This function utilizes the internal _deposit and _withdraw functions to rebalance based on 
    /// the strategies set in the contract. Since _deposit will set the TokenInfo.deposit to the total 
    /// deposited after the rebalance, we must store the original deposit and overwrite the TokenInfo
    /// before completing the transaction.
    function rebalance(uint256 _tokenId) public nonReentrant {
        require((balanceOf(msg.sender, _tokenId) > 0 && !paused) ||
                          msg.sender == owner(), "FortiFi: Invalid message sender");
        uint256 _originalDeposit = tokenInfo[_tokenId].deposit;
        (uint256 _amount, ) = _withdraw(_tokenId);
        delete tokenInfo[_tokenId];
        _deposit(_amount, _tokenId, false);
        TokenInfo storage _info = tokenInfo[_tokenId];
        _info.deposit = _originalDeposit;

        emit Rebalance(_tokenId, _amount, _info);
    }

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

        uint8 _length = uint8(strategies.length);
        for (uint8 i = 0; i < _length; i++) {
            Strategy memory _strategy = strategies[i];
            if (_isAdd) {
                require(_strategy.strategy == _info.positions[i].strategy.strategy, "FortiFi: Can't add to receipt");
            }
            
            IStrategy _strat = IStrategy(_strategy.strategy);
            uint256 _receiptBalance = _strat.balanceOf(address(this));

            if (i == (_length - 1)) {
                _strat.deposit(_remainder);
            } else {
                uint256 _split = _amount * _strategy.bps / BPS;
                _remainder -= _split;
                _strat.deposit(_split);
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
        uint8 _length = uint8(_info.positions.length);

        for (uint8 i = 0 ; i < _length; i++) {
            if (_info.positions[i].strategy.isVector) {
                IVectorStrategy _strat = IVectorStrategy(_info.positions[i].strategy.strategy);
                uint256 _tokensForShares = _strat.getDepositTokensForShares(_info.positions[i].receipt);
                uint256 _minAmount = _tokensForShares * (BPS - slippageBps) / BPS;
                
                _strat.withdraw(_tokensForShares, _minAmount);
            } else {
                IStrategy _strat = IStrategy(_info.positions[i].strategy.strategy);
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

}