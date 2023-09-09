// SPDX-License-Identifier: GPL-3.0-only
// FortiFiSAMSVault by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../strategies/interfaces/IStrategy.sol";
import "../strategies/interfaces/IVectorStrategy.sol";
import "../fee-calculators/interfaces/IFortiFiFeeCalculator.sol";
import "../fee-managers/interfaces/IFortiFiFeeManager.sol";
import "./interfaces/ISAMS.sol";

pragma solidity ^0.8.2;

/// @title Contract for FortiFi SAMS Vaults
/// @notice This contract allows for the deposit of a single asset, which is then split and deposited in to 
/// multiple yield-bearing strategies. 
contract FortiFiSAMSVault is ISAMS, ERC1155Supply, Ownable, ReentrancyGuard {
    string public name;
    string public symbol;
    address public depositToken;
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
        uint256 _minDeposit,
        Strategy[] memory _strategies) ERC1155(_metadata) {
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
        setStrategies(_strategies);
    }

    receive() external payable { 
    }

    /// @notice This function is used when a user does not already have a receipt (ERC1155). 
    /// @dev The user must deposit at least the minDeposit, and will receive an ERC1155 non-fungible receipt token. 
    /// The receipt token will be mapped to a TokenInfo containing the amount deposited as well as the strategy receipt 
    /// tokens received for later withdrawal.
    function deposit(uint256 _amount) external override nonReentrant whileNotPaused returns(uint256 _tokenId, TokenInfo memory _info) {
        require(_amount > minDeposit, "FortiFi: Invalid deposit amount");
        IERC20 _depositToken = IERC20(depositToken);
        require(_depositToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to xfer deposit");
        _tokenId = _mintReceipt();
        _deposit(_amount, _tokenId, false);
        _info = tokenInfo[_tokenId];

        uint256 _depositTokenBalance = _depositToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _info.deposit -= _depositTokenBalance;
            require(_depositToken.transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    require(success, "FortiFi: Failed to refund native");
        }

        emit Deposit(msg.sender, _tokenId, _amount, _info);
    }

    /// @notice This function is used to add to a user's deposit when they already has a receipt (ERC1155). The user can add to their 
    /// deposit without needing to burn/withdraw first. 
    function add(uint256 _amount, uint256 _tokenId) external override nonReentrant whileNotPaused returns(TokenInfo memory _info) {
        require(_amount > minDeposit, "FortiFi: Invalid deposit amount");
        IERC20 _depositToken = IERC20(depositToken);
        require(_depositToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to xfer deposit");
        require(balanceOf(msg.sender, _tokenId) > 0, "FortiFi: Not the owner of token");
        _deposit(_amount, _tokenId, true);
        _info = tokenInfo[_tokenId];

        uint256 _depositTokenBalance = _depositToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _info.deposit -= _depositTokenBalance;
            require(_depositToken.transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    require(success, "FortiFi: Failed to refund native");
        }

        emit Add(msg.sender, _tokenId, _amount, _info);
    }

    /// @notice This function is used to burn a receipt (ERC1155) and withdraw all underlying strategy receipt tokens. 
    /// @dev Once all receipts are burned and deposit tokens received, the fee manager will calculate the fees due, 
    /// and the fee manager will distribute those fees before transfering the user their proceeds.
    function withdraw(uint256 _tokenId) external override nonReentrant whileNotPaused {
        require(balanceOf(msg.sender, _tokenId) > 0, "FortiFi: Not the owner of token");
        _burn(msg.sender, _tokenId, 1);

        (uint256 _amount, uint256 _profit) = _withdraw(_tokenId);
        uint256 _fee = 0;

        if (!noFeesFor[msg.sender]) {
            _fee = feeCalc.getFees(msg.sender, _profit);
            feeMgr.collectFees(depositToken, _fee);
        }
        
        require(IERC20(depositToken).transfer(msg.sender, _amount - _fee), "FortiFi: Failed to send proceeds");

        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    require(success, "FortiFi: Failed to refund native");
        }

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

    /// @notice Setter for minDeposit state variable
    function setMinDeposit(uint256 _amount) external onlyOwner {
        minDeposit = _amount;
    }

    /// @notice Setter for contract fee manager
    /// @dev Contract address specified should implement IFortiFiFeeManager
    function setFeeManager(address _contract) external onlyOwner {
        feeMgr = IFortiFiFeeManager(_contract);
    }

    /// @notice Setter for contract fee calculator
    /// @dev Contract address specified should implement IFortiFiFeeCalculator
    function setFeeCalculator(address _contract) external onlyOwner {
        feeCalc = IFortiFiFeeCalculator(_contract);
    }

    /// @notice Function to set noFeesFor a contract. 
    /// @dev This allows FortiFi MASS vaults to utilize this SAMS vault without paying a fee so that users
    /// do not pay fees twice.
    function setNoFeesFor(address _contract, bool _fees) external onlyOwner {
        noFeesFor[_contract] = _fees;
    }

    /// @notice Function to pause/unpause the contract.
    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    /// @notice Emergency function to recover stuck ERC20 tokens.
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    /// @notice Function that approves ERC20 transfers for all strategy contracts
    /// @dev This function sets the max approval because no depositTokens should remain in this contract at the end of a 
    /// transaction. This means there should be no risk exposure. 
    function refreshApprovals() public {
        IERC20 _depositToken = IERC20(depositToken);
        uint8 _length = uint8(strategies.length);

        for(uint8 i = 0; i < _length; i++) {
            _depositToken.approve(strategies[i].strategy, type(uint256).max);
        }

        _depositToken.approve(address(feeMgr), type(uint256).max);
    }

    /// @notice This function sets up the underlying strategies used by the vault.
    function setStrategies(Strategy[] memory _strategies) public onlyOwner {
        uint8 _length = uint8(_strategies.length);
        require(_length > 0, "FortiFi: No strategies");

        uint16 _bps = 0;
        for (uint8 i = 0; i < _length; i++) {
            _bps += _strategies[i].bps;
        }
        require(_bps == BPS, "FortiFi: Invalid total bps");

        delete strategies; // remove old array, if any

        for (uint8 i = 0; i < _length; i++) {
            require(_strategies[i].strategy != address(0), "FortiFi: Invalid strat address");
            strategies.push(_strategies[i]);
        }

        refreshApprovals();
    }

    /// @notice This function allows a user to rebalance a receipt (ERC1155) token's underlying assets. 
    /// @dev This function utilizes the internal _deposit and _withdraw functions to rebalance based on 
    /// the strategies set in the contract. Since _deposit will set the TokenInfo.deposit to the total 
    /// deposited after the rebalance, we must store the original deposit and overwrite the TokenInfo
    /// before completing the transaction.
    function rebalance(uint256 _tokenId) public override nonReentrant  returns(TokenInfo memory) {
        require((balanceOf(msg.sender, _tokenId) > 0 && !paused) ||
                          msg.sender == owner(), "FortiFi: Invalid message sender");
        uint256 _originalDeposit = tokenInfo[_tokenId].deposit;
        (uint256 _amount, ) = _withdraw(_tokenId);
        delete tokenInfo[_tokenId];
        _deposit(_amount, _tokenId, false);
        tokenInfo[_tokenId].deposit = _originalDeposit;
        TokenInfo memory _info = tokenInfo[_tokenId];

        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    require(success, "FortiFi: Failed to refund native");
        }

        IERC20 _depositToken = IERC20(depositToken);
        uint256 _depositTokenBalance = _depositToken.balanceOf(address(this));

        if (_depositTokenBalance > 0) {
            tokenInfo[_tokenId].deposit = _originalDeposit - _depositTokenBalance;
            require(_depositToken.transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        emit Rebalance(_tokenId, _amount, _info);
        return _info;
    }

    /// @notice View function that returns all TokenInfo for a specific receipt
    function getTokenInfo(uint256 _tokenId) public view override returns(TokenInfo memory) {
        return tokenInfo[_tokenId];
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

        uint8 _length = uint8(strategies.length);
        for (uint8 i = 0; i < _length; i++) {
            Strategy memory _strategy = strategies[i];
            if (_isAdd) {
                require(_strategy.strategy == _info.positions[i].strategy.strategy, "FortiFi: Can't add to receipt");
            }
            
            IStrategy _strat = IStrategy(_strategy.strategy);
            uint256 _receiptBalance = _strat.balanceOf(address(this));

            if (i == (_length - 1)) {
                if (_strategy.isFortiFi) {
                    _strat.depositToFortress(_remainder, msg.sender);
                } else {
                    _strat.deposit(_remainder);
                }
            } else {
                uint256 _split = _amount * _strategy.bps / BPS;
                _remainder -= _split;
                if (_strategy.isFortiFi) {
                    _strat.depositToFortress(_split, msg.sender);
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
        uint8 _length = uint8(_info.positions.length);

        for (uint8 i = 0 ; i < _length; i++) {
            IStrategy _strat = IStrategy(_info.positions[i].strategy.strategy);
            if (_info.positions[i].strategy.isFortiFi) {
                _strat.withdrawFromFortress(_info.positions[i].receipt, msg.sender);
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

}