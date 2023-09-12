// SPDX-License-Identifier: MIT
// FortiFiVectorStrategy by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IStrategy.sol";
import "./FortiFiStrategy.sol";
import "./FortiFiVectorFortress.sol";

pragma solidity ^0.8.2;

contract FortiFiVectorStrategy is FortiFiStrategy {
    address private _strat;
    IERC20 private _dToken;
    IERC20 private _wNative;

    constructor(address _strategy, address _depositToken, address _wrappedNative) FortiFiStrategy(_strategy, _depositToken, _wrappedNative) {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        require(_wrappedNative != address(0), "FortiFi: Invalid native token");
        _strat = _strategy;
        _dToken = IERC20(_depositToken);
        _wNative = IERC20(_wrappedNative);
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