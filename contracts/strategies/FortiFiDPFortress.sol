// SPDX-License-Identifier: MIT
// FortiFiDPFortress by FortiFi

import "./FortiFiFortress.sol";
import "./interfaces/IStrategy.sol";

pragma solidity ^0.8.17;

contract FortiFiDPFortress is FortiFiFortress {
    uint16 private constant BPS = 10_000;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _fortiFiStrat) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative, _fortiFiStrat) {
    }

    function withdraw(uint256 _amount) external override onlyOwner {
        require(_amount > 0, "FortiFi: 0 withdraw");
        _burn(msg.sender, _amount);
        uint256 _balance = _strat.balanceOf(address(this));
        
        _strat.withdraw(_balance);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");

        if (_strat.balanceOf(address(this)) > 0) {
            require(_strat.transfer(msg.sender, _strat.balanceOf(address(this))), "FortiFi: Failed to refund");
        }

        _refund();
    }

}