// SPDX-License-Identifier: MIT
// FortiFiNativeFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/INativeStrategy.sol";

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

/// @notice Error thrown when deposit token is not wrapped native token
error InvalidDepositToken();

interface IWNative {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/// @title Base FortiFi Fortress contract for strategies that require native tokens for deposit
/// @notice Fortresses are vault contracts that are specific to an individual vault receipt. By isolating deposits,
/// Fortresses allow for balance-specific logic from underlying strategies.
contract FortiFiNativeFortress is Ownable {
    using SafeERC20 for IERC20;
    INativeStrategy public immutable _strat;
    IERC20 public immutable _wNative;

    constructor(address _strategy, address _wrappedNative) {
        if (_strategy == address(0)) revert ZeroAddress();
        if (_wrappedNative == address(0)) revert ZeroAddress();
        _strat = INativeStrategy(_strategy);
        _wNative = IERC20(_wrappedNative);
    }

    event DepositMade(uint256 amount, address indexed user);
    event WithdrawalMade(address user);
    event ERC20Recovered(address indexed to, address indexed token, uint256 amount);

    receive() external payable { 
    }

    /// @notice Function to deposit
    function deposit(uint256 _amount, address _user) external virtual onlyOwner returns(uint256 _newStratReceipts){
        if (_amount == 0) revert InvalidDeposit();
        _wNative.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _beforeBalance = _strat.balanceOf(address(this));

        // unwrap
        IWNative(address(_wNative)).withdraw(_amount);

        // deposit to underlying strategy
        _strat.deposit{value: _amount}(_amount);

        // calculate new strategy receipt tokens received
        _newStratReceipts = _strat.balanceOf(address(this)) - _beforeBalance;

        // refund left over tokens, if any
        _refund(_user);

        emit DepositMade(_amount, _user);
    }

    /// @notice Function to withdraw everything from vault
    function withdraw(address _user, address[] memory _extraTokens) external virtual onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        if (_balance == 0) revert InvalidWithdrawal();

        _strat.withdraw(_balance);

        // ensure no strategy receipt tokens remain
        _balance = _strat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_strat)).safeTransfer(_user, _balance);
        }

        uint256 _nativeBalance = address(this).balance;

        // wrap
        IWNative(address(_wNative)).deposit{value: _nativeBalance}();

        // transfer received deposit tokens and refund left over tokens, if any
        _wNative.safeTransfer(msg.sender, _nativeBalance);

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

    /// @notice Function to return strategy receipts to user when strategy is bricked
    function withdrawBricked(address _user) external virtual onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        if (_balance == 0) revert InvalidWithdrawal();

        // ensure no strategy receipt tokens remain
        _balance = _strat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_strat)).safeTransfer(_user, _balance);
        }

        emit WithdrawalMade(_user);
    }

    /// @notice Emergency function to recover stuck tokens. 
    function recoverERC20(address _to, address _token, uint256 _amount) external onlyOwner {
        if (_token == address(_strat)) revert CantWithdrawStrategyReceipts();
        IERC20(_token).safeTransfer(_to, _amount);
        emit ERC20Recovered(_to, _token, _amount);
    }

    /// @notice Internal function to refund left over tokens from transactions to user who initiated vault transaction
    function _refund(address _user) internal {
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