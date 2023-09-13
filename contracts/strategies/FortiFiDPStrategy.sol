// SPDX-License-Identifier: MIT
// FortiFiDPStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./FortiFiDPFortress.sol";

pragma solidity ^0.8.18;

/// @title Delta Prime FortiFi Strategy contract
/// @notice This contract allows for FortiFi vaults to utilize Delta Prime strategies. 
contract FortiFiDPStrategy is FortiFiStrategy {

    constructor(address _strategy, address _depositToken, address _wrappedNative) 
        FortiFiStrategy(_strategy, _depositToken, _wrappedNative) {
    }

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiDPFortress contract
    /// instead of the base FortiFiFortress contract
    function depositToFortress(uint256 _amount, address _user) external override {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        IFortress _fortress;

        uint256 _beforeBalance = 0;

        // If user has not deposited previously, deploy Fortress
        if (userToFortress[_user] == address(0)) {
            FortiFiDPFortress _fort = new FortiFiDPFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IFortress(address(_fort));
            userToFortress[_user] = address(_fortress);
        } else {
            _fortress = IFortress(userToFortress[_user]);
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

}