// SPDX-License-Identifier: MIT
// FortiFiWombatFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStrategy.sol";
import "./FortiFiFortress.sol";

pragma solidity 0.8.21;

interface IWombatPool {
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

/// @title FortiFiFortress for Wombat Strategy
/// @notice This Fortress can only be used for FortiFiWombatStrategy contracts
contract FortiFiWombatFortress is FortiFiFortress {
    using SafeERC20 for IERC20;
    
    uint16 public constant BPS = 10000;

    address public pool;

    IERC20 public lpToken;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _lpToken, address _pool) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative) {
        if (_lpToken == address(0)) revert ZeroAddress();
        if (_pool == address(0)) revert ZeroAddress();
        lpToken = IERC20(_lpToken);
        pool = _pool;

        // grant approvals
        lpToken.approve(_strategy, type(uint256).max);
        lpToken.approve(pool, type(uint256).max);
        _dToken.approve(pool, type(uint256).max);
    }

    /// @notice Nullified deposit function
    /// @dev this override is to ensure an incorrect deposit call is not made from the strategy contract.
    /// Wombat strategies require calling depositWombat(_amount, _slippageBps, _user)
    function deposit(uint256, address) external override onlyOwner returns(uint256) {
        revert("FortiFi: Invalid deposit");
    }

    /// @notice Function to deposit
    function depositWombat(uint256 _amount, uint _slippage, address _user) external onlyOwner returns(uint256 _newStratReceipts){
        if (_amount == 0) revert InvalidDeposit();
        _dToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _beforeBalance = _strat.balanceOf(address(this));

        // deposit to Wombat
        uint _lpAmount = IWombatPool(pool).deposit(address(_dToken), 
                                                    _amount, 
                                                    (_amount * (BPS - _slippage) / BPS), 
                                                    address(this), 
                                                    block.timestamp + 1800,
                                                    false);

        // deposit to underlying strategy
        _strat.deposit(_lpAmount);

        // calculate new strategy receipt tokens received
        _newStratReceipts = _strat.balanceOf(address(this)) - _beforeBalance;

        // refund left over tokens, if any
        _refund(_user);

        emit DepositMade(_amount, _user);
    }

    /// @notice Nullified withdraw function
    /// @dev this override is to ensure an incorrect withdraw call is not made from the strategy contract.
    /// Wombat strategies require calling withdrawWombat(_amount, _slippage, _extraTokens)
    function withdraw(address, address[] memory) external override onlyOwner {
        revert("FortiFi: Invalid withdraw");
    }

    /// @notice Function to withdraw everything from vault
    function withdrawWombat(address _user, uint256 _slippage, address[] memory _extraTokens) external onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        if (_balance == 0) revert InvalidWithdrawal();

        _strat.withdraw(_balance);

        // ensure no strategy receipt tokens remain
        _balance = _strat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_strat)).safeTransfer(_user, _balance);
        }

        uint256 _lpReceived = lpToken.balanceOf(address(this));

        // remove liquidity
        IWombatPool(pool).withdraw(address(_dToken), 
                                    _lpReceived, 
                                    (_lpReceived * (BPS - _slippage) / BPS), 
                                    address(this), 
                                    block.timestamp + 1800);

        // transfer received deposit tokens and refund left over tokens, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _dToken.safeTransfer(msg.sender, _depositTokenBalance);
        }

        // transfer extra reward tokens
        uint256 _length = _extraTokens.length;
        if (_length > 0) {
            for(uint256 i = 0; i < _length; i++) {
                IERC20 _token = IERC20(_extraTokens[i]);
                uint256 _tokenBalance = _token.balanceOf(address(this));
                if (_tokenBalance > 0) {
                    _token.safeTransfer(msg.sender, _tokenBalance);
                }
            }
        }

        _refund(_user);

        emit WithdrawalMade(_user);
    }

    /// @notice Grant max approval to underlying strategy for Staked GLP
    /// @dev Since Fortresses do not hold deposit tokens for longer than it takes to complete the 
    /// transaction there should be no risk in granting max approval
    function refreshWombatApprovals() external {
        lpToken.approve(address(_strat), type(uint256).max);
        lpToken.approve(pool, type(uint256).max);
        _dToken.approve(pool, type(uint256).max);
        emit ApprovalsRefreshed();
    }

}