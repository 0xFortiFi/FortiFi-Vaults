// SPDX-License-Identifier: MIT
// FortiFiFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStrategy.sol";

pragma solidity ^0.8.18;

/// @title Base FortiFi Fortress contract
/// @notice Fortresses are vault contracts that are specific to an individual vault receipt. By isolating deposits,
/// Fortresses allow for balance-specific logic from underlying strategies.
contract FortiFiFortress is Ownable {
    IStrategy internal immutable _strat;
    IERC20 internal immutable _dToken;
    IERC20 internal immutable _wNative;

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
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
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
            require(_strat.transfer(_user, _balance));
        }

        // transfer received deposit tokens and refund left over tokens, if any
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
        _refund(_user);
    }

    /// @notice Grant max approval to underlying strategy for deposit token
    /// @dev Since Fortresses do not hold deposit tokens for longer than it takes to complete the 
    /// transaction there should be no risk in granting max approval
    function refreshApproval() external {
        _dToken.approve(address(_strat), type(uint256).max);
    }

    /// @notice View function returns specified wrapped native token address
    function wrappedNativeToken() external view returns(address) {
        return address(_wNative);
    }

    /// @notice View function returns specified deposit token address
    function depositToken() external view returns(address) {
        return address(_dToken);
    }

    /// @notice View function returns specified underlying strategy address
    function strategy() external view returns(address) {
        return address(_strat);
    }

    /// @notice Emergency function to recover stuck tokens. 
    function recoverERC20(address _to, address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }

    /// @notice Internal function to refund left over tokens from transactions to user who initiated vault transaction
    function _refund(address _user) internal {
        // Refund left over deposit tokens to strategy, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            require(_dToken.transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        // Refund left over wrapped native tokens to user, if any
        uint256 _wrappedNativeTokenBalance = _wNative.balanceOf(address(this));
        if (_wrappedNativeTokenBalance > 0) {
            require(_wNative.transfer(_user, _wrappedNativeTokenBalance), "FortiFi: Failed to refund native");
        }

        // Refund left over native tokens to user, if any
        if (address(this).balance > 0) {
            (bool success, ) = payable(_user).call{ value: address(this).balance }("");
		    require(success, "FortiFi: Failed to refund native");
        }
    }
}