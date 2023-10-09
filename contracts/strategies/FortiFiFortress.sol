// SPDX-License-Identifier: MIT
// FortiFiFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStrategy.sol";

pragma solidity 0.8.21;

/// @notice Error caused by trying to use recoverERC20 to withdraw strategy receipt tokens
error CantWithdrawStrategyReceipts();

/// @notice Error caused by using 0 address as a parameter
error ZeroAddress();

/// @notice Error caused by trying to deposit 0
error InvalidDeposit();

/// @notice Error caused by trying to withdraw 0
error InvalidWithdrawal();

/// @notice Error thrown when refunding native token fails
error FailedToRefund();

/// @title Base FortiFi Fortress contract
/// @notice Fortresses are vault contracts that are specific to an individual vault receipt. By isolating deposits,
/// Fortresses allow for balance-specific logic from underlying strategies.
contract FortiFiFortress is Ownable {
    using SafeERC20 for IERC20;
    IStrategy public immutable _strat;
    IERC20 public immutable _dToken;
    IERC20 public immutable _wNative;

    constructor(address _strategy, address _depositToken, address _wrappedNative) {
        if (_strategy == address(0)) revert ZeroAddress();
        if (_depositToken == address(0)) revert ZeroAddress();
        if (_wrappedNative == address(0)) revert ZeroAddress();
        _strat = IStrategy(_strategy);
        _dToken = IERC20(_depositToken);
        _wNative = IERC20(_wrappedNative);

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);
    }

    event DepositMade(uint256 amount, address indexed user);
    event WithdrawalMade(address user);
    event ApprovalsRefreshed();
    event ERC20Recovered(address indexed to, address indexed token, uint256 amount);

    receive() external payable { 
    }

    /// @notice Function to deposit
    function deposit(uint256 _amount, address _user) external virtual onlyOwner returns(uint256 _newStratReceipts){
        if (_amount == 0) revert InvalidDeposit();
        _dToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _beforeBalance = _strat.balanceOf(address(this));

        // deposit to underlying strategy
        _strat.deposit(_amount);

        // calculate new strategy receipt tokens received
        _newStratReceipts = _strat.balanceOf(address(this)) - _beforeBalance;

        // refund left over tokens, if any
        _refund(_user);

        emit DepositMade(_amount, _user);
    }

    /// @notice Function to withdraw everything from vault
    function withdraw(address _user) external virtual onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        if (_balance == 0) revert InvalidWithdrawal();

        _strat.withdraw(_balance);

        // ensure no strategy receipt tokens remain
        _balance = _strat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_strat)).safeTransfer(_user, _balance);
        }

        // transfer received deposit tokens and refund left over tokens, if any
        _dToken.safeTransfer(msg.sender, _dToken.balanceOf(address(this)));
        _refund(_user);

        emit WithdrawalMade(_user);
    }

    /// @notice Grant max approval to underlying strategy for deposit token
    /// @dev Since Fortresses do not hold deposit tokens for longer than it takes to complete the 
    /// transaction there should be no risk in granting max approval
    function refreshApproval() external {
        _dToken.approve(address(_strat), type(uint256).max);
        emit ApprovalsRefreshed();
    }

    /// @notice Emergency function to recover stuck tokens. 
    function recoverERC20(address _to, address _token, uint256 _amount) external onlyOwner {
        if (_token == address(_strat)) revert CantWithdrawStrategyReceipts();
        IERC20(_token).safeTransfer(_to, _amount);
        emit ERC20Recovered(_to, _token, _amount);
    }

    /// @notice Internal function to refund left over tokens from transactions to user who initiated vault transaction
    function _refund(address _user) internal {
        // Refund left over deposit tokens to strategy, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            _dToken.safeTransfer(msg.sender, _depositTokenBalance);
        }

        // Refund left over wrapped native tokens to user, if any
        uint256 _wrappedNativeTokenBalance = _wNative.balanceOf(address(this));
        if (_wrappedNativeTokenBalance > 0) {
            _wNative.safeTransfer(_user, _wrappedNativeTokenBalance);
        }

        // Refund left over native tokens to user, if any
        if (address(this).balance > 0) {
            (bool success, ) = payable(_user).call{ value: address(this).balance }("");
		    if (!success) revert FailedToRefund();
        }
    }
}