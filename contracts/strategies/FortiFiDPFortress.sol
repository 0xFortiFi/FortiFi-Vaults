// SPDX-License-Identifier: MIT
// FortiFiDPFortress by FortiFi

import "./FortiFiFortress.sol";
import "./interfaces/IStrategy.sol";

pragma solidity ^0.8.18;

/// @title FortiFi Fortress contract for Delta Prime strategies
/// @notice This Fortress contract is specifically made to interact with Delta Prime strategies
contract FortiFiDPFortress is FortiFiFortress {

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _fortiFiStrat) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative, _fortiFiStrat) {
    }

    /// @notice Function to withdraw
    /// @dev Delta Prime strategies mint new receipt tokens as accrued interest so in order to calculate total tokens to be burned
    /// you must call balanceOf on the strategy, which returns the total balance including interest.
    /// This means that total balance will be withdrawn every time withdraw is called.
    function withdraw(address _user) external override onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        require(_balance > 0, "FortiFi: 0 withdraw");
        
        // withdraw from strategy
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

}