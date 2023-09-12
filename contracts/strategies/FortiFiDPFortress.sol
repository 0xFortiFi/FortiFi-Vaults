// SPDX-License-Identifier: MIT
// FortiFiDPFortress by FortiFi

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FortiFiFortress.sol";
import "./interfaces/IStrategy.sol";

pragma solidity ^0.8.2;

contract FortiFiDPFortress is FortiFiFortress {
    uint16 private constant BPS = 10_000;
    IStrategy private _strat;
    IERC20 private _dToken;
    IERC20 private _wNative;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _owner) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative, _owner) {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        require(_wrappedNative != address(0), "FortiFi: Invalid native token");
        require(_owner != address(0), "FortiFi: Invalid owner");
        _strat = IStrategy(_strategy);
        _dToken = IERC20(_depositToken);
        _wNative = IERC20(_wrappedNative);

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);

        _transferOwnership(_owner);
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