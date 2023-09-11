// SPDX-License-Identifier: MIT
// FortiFiStrategy by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IFortress.sol";
import "./FortiFiFortress.sol";

pragma solidity ^0.8.2;

contract FortiFiStrategy is Ownable, ERC20 {
    address private _strat;
    IERC20 private _dToken;

    mapping(address => address) public userToFortress;

    constructor(address _strategy, address _depositToken) ERC20("FortiFi Strategy Receipt", "FFSR") {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        _strat = _strategy;
        _dToken = IERC20(_depositToken);
    }

    function depositToFortress(uint256 _amount, address _user) external virtual {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        FortiFiFortress _fortress;

        if (userToFortress[_user] == address(0)) {
            _fortress = new FortiFiFortress(_strat, address(_dToken), address(this));
            userToFortress[_user] = address(_fortress);
        } else {
            _fortress = FortiFiFortress(userToFortress[_user]);
        }

        uint256 _beforeBalance = _fortress.balanceOf(address(this));
        _dToken.approve(address(_fortress), _amount);
        _fortress.deposit(_amount);
        _mint(msg.sender, (_fortress.balanceOf(address(this)) - _beforeBalance));
    }

    function withdrawFromFortress(uint256 _amount, address _user) external {
        require(_amount > 0, "FortiFi: 0 withdraw");
        require(userToFortress[_user] != address(0), "FortiFi: No fortress");
        _burn(msg.sender, _amount);
        IFortress(userToFortress[_user]).withdraw(_amount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
    }

    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function recoverFromFortress(address _fortress, address _token, uint256 _amount) external onlyOwner {
        IFortress(_fortress).recoverERC20(msg.sender, _token, _amount);
    }

}