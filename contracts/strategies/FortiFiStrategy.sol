// SPDX-License-Identifier: MIT
// FortiFiStrategy by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStrategy.sol";

pragma solidity ^0.8.2;

contract FortiFiStrategy is Ownable {
    IStrategy private _strat;
    IERC20 private _dToken;

    constructor(address _strategy, address _depositToken) {
        require(_strategy != address(0), "FortiFi: Invalid strategy address");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token address");
        _strat = IStrategy(_strategy);
        _dToken = IERC20(_depositToken);

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);
    }

    function deposit(uint256 _amount) external virtual {
        require(_amount > 0, "FortiFi: Must deposit more than 0");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFiStrategy: Failed to transfer deposit");
        _strat.deposit(_amount);
        require(_strat.transfer(msg.sender, _strat.balanceOf(address(this))), "FortiFiStrategy: Failed to transfer receipt");
    }

    function withdraw(uint256 _amount) external virtual {
        require(_amount > 0, "FortiFi: Must withdraw more than 0");
        require(_strat.transferFrom(msg.sender, address(this), _amount), "FortiFiStrategy: Failed to transfer receipt");
        _strat.withdraw(_amount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFiStrategy: Failed to transfer dToken");
    }

    function refreshApproval() external {
        _dToken.approve(address(_strat), type(uint256).max);
    }

    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
}