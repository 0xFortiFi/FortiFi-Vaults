// SPDX-License-Identifier: MIT
// FortiFiVectorStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./FortiFiVectorFortress.sol";

pragma solidity ^0.8.18;

contract FortiFiVectorStrategy is FortiFiStrategy {

    constructor(address _strategy, address _depositToken, address _wrappedNative) 
        FortiFiStrategy(_strategy, _depositToken, _wrappedNative) {
    }

    function depositToFortress(uint256 _amount, address _user) external override {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        IFortress _fortress;

        if (userToFortress[_user] == address(0)) {
            FortiFiVectorFortress _fort = new FortiFiVectorFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IFortress(address(_fort));
            userToFortress[_user] = address(_fortress);
        } else {
            _fortress = IFortress(userToFortress[_user]);
        }

        uint256 _beforeBalance = _fortress.balanceOf(address(this));
        _dToken.approve(address(_fortress), _amount);
        _fortress.deposit(_amount);
        _mint(msg.sender, (_fortress.balanceOf(address(this)) - _beforeBalance));
        _refund();
    }

}