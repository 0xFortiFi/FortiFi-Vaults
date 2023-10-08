// SPDX-License-Identifier: MIT
// FortiFiFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IStrategy.sol";

pragma solidity 0.8.21;

/// @notice Error caused by trying to use recoverERC20 to withdraw strategy receipt tokens
error CannotWithdrawStrategyReceipts();

/// @title Base FortiFi Fortress contract
/// @notice Fortresses are vault contracts that are specific to an individual vault receipt. By isolating deposits,
/// Fortresses allow for balance-specific logic from underlying strategies.
contract FortiFiFortress is Ownable {
    using SafeERC20 for IERC20;
    IStrategy public immutable _strat;
    IERC20 public immutable _dToken;
    IERC20 public immutable _wNative;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _fortiFiStrat) {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        require(_wrappedNative != address(0), "FortiFi: Invalid native token");
        require(_fortiFiStrat != address(0), "FortiFi: Invalid owner");
        _strat = IStrategy(_strategy);
        _dToken = IERC20(_depositToken);
        _wNative = IERC20(_wrappedNative);

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);

        // owner is the FortiFiStrategy contract that creates this Fortress
        _transferOwnership(_fortiFiStrat);
    }

    receive() external payable { 
    }

    /// @notice Function to deposit
    function deposit(uint256 _amount, address _user) external virtual onlyOwner returns(uint256 _newStratReceipts){
        require(_amount > 0, "FortiFi: 0 deposit");
        _dToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 _beforeBalance = _strat.balanceOf(address(this));

        // deposit to underlying strategy
        _strat.deposit(_amount);

        // calculate new strategy receipt tokens received
        _newStratReceipts = _strat.balanceOf(address(this)) - _beforeBalance;

        // refund left over tokens, if any
        _refund(_user);
    }

    /// @notice Function to withdraw everything from vault
    function withdraw(address _user) external virtual onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        require(_balance > 0, "FortiFi: 0 withdraw");

        _strat.withdraw(_balance);

        // ensure no strategy receipt tokens remain
        _balance = _strat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_strat)).safeTransfer(_user, _balance);
        }

        // transfer received deposit tokens and refund left over tokens, if any
        _dToken.safeTransfer(msg.sender, _dToken.balanceOf(address(this)));
        _refund(_user);
    }

    /// @notice Grant max approval to underlying strategy for deposit token
    /// @dev Since Fortresses do not hold deposit tokens for longer than it takes to complete the 
    /// transaction there should be no risk in granting max approval
    function refreshApproval() external {
        _dToken.approve(address(_strat), type(uint256).max);
    }

    /// @notice Emergency function to recover stuck tokens. 
    function recoverERC20(address _to, address _token, uint256 _amount) external onlyOwner {
        if (_token == address(_strat)) revert CannotWithdrawStrategyReceipts();
        IERC20(_token).safeTransfer(_to, _amount);
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
		    require(success, "FortiFi: Failed to refund native");
        }
    }
}