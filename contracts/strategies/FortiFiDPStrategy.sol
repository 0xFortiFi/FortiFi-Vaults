// SPDX-License-Identifier: MIT
// FortiFiDPStrategy by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IStrategy.sol";
import "./FortiFiStrategy.sol";
import "./FortiFiDPFortress.sol";

pragma solidity ^0.8.2;

contract FortiFiDPStrategy is FortiFiStrategy {
    address private _strat;
    IERC20 private _dToken;

    constructor(address _strategy, address _depositToken) FortiFiStrategy(_strategy, _depositToken) {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        _strat = _strategy;
        _dToken = IERC20(_depositToken);
    }

    function depositToFortress(uint256 _amount, address _user) external override {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        FortiFiDPFortress _fortress;

        if (userToFortress[_user] == address(0)) {
            _fortress = new FortiFiDPFortress(_strat, address(_dToken), address(this));
            userToFortress[_user] = address(_fortress);
        } else {
            _fortress = FortiFiDPFortress(userToFortress[_user]);
        }

        uint256 _beforeBalance = _fortress.balanceOf(address(this));
        _dToken.approve(address(_fortress), _amount);
        _fortress.deposit(_amount);
        _mint(msg.sender, (_fortress.balanceOf(address(this)) - _beforeBalance));
    }

}