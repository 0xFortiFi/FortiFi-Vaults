// SPDX-License-Identifier: MIT
// FortiFiVectorStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./FortiFiVectorFortress.sol";
import "./interfaces/IVectorFortress.sol";

pragma solidity ^0.8.18;

/// @title Delta Prime FortiFi Strategy contract
/// @notice This contract allows for FortiFi vaults to utilize Vector Finance strategies. 
contract FortiFiVectorStrategy is FortiFiStrategy {
    uint256 public slippageBps = 100;

    constructor(address _strategy, address _depositToken, address _wrappedNative) 
        FortiFiStrategy(_strategy, _depositToken, _wrappedNative) {
    }

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiVectorFortress contract
    /// instead of the base FortiFiFortress contract
    function depositToFortress(uint256 _amount, address _user) external override {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        IVectorFortress _fortress;

        uint256 _beforeBalance = 0;

        // If user has not deposited previously, deploy Fortress
        if (userToFortress[_user] == address(0)) {
            FortiFiVectorFortress _fort = new FortiFiVectorFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IVectorFortress(address(_fort));
            userToFortress[_user] = address(_fortress);
        } else {
            _fortress = IVectorFortress(userToFortress[_user]);
            // set before balance since user has deposited previously
            _beforeBalance = _fortress.balanceOf(address(this));
        }

        // approve and deposit
        _dToken.approve(address(_fortress), _amount);
        _fortress.deposit(_amount);

        // mint receipt tokens = to what was received from Fortress
        _mint(msg.sender, (_fortress.balanceOf(address(this)) - _beforeBalance));

        // refund left over tokens, if any
        _refund();
    }

    /// @notice Function to withdraw
    /// @dev Override is required because Vector Fortresses need slippage passed in to withdrawal function
    function withdrawFromFortress(uint256 _amount, address _user) external override {
        require(_amount > 0, "FortiFi: 0 withdraw");
        require(userToFortress[_user] != address(0), "FortiFi: No fortress");

        // burn receipt tokens and withdraw from Fortress
        _burn(msg.sender, _amount);
        IVectorFortress(userToFortress[_user]).withdrawVector(_amount, slippageBps);

        // transfer underlying assets and refund left over tokens, if any
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
        _refund();
    }

    /// @notice Function to set the slippage if 1% is not sufficient
    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
    }

}