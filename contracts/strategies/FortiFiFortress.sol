// SPDX-License-Identifier: MIT
// FortiFiFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IStrategy.sol";

pragma solidity ^0.8.2;

contract FortiFiFortress is Ownable, ERC20 {
    IStrategy private _strat;
    IERC20 private _dToken;

    constructor(address _strategy, address _depositToken) ERC20("FortiFi Fortress Receipt", "FFFR") {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        _strat = IStrategy(_strategy);
        _dToken = IERC20(_depositToken);

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);
    }

    function deposit(uint256 _amount) external virtual {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        uint256 _beforeBalance = _strat.balanceOf(address(this));
        _strat.deposit(_amount);
        _mint(msg.sender, (_strat.balanceOf(address(this)) - _beforeBalance));
    }

    function withdraw(uint256 _amount) external virtual {
        require(_amount > 0, "FortiFi: 0 withdraw");
        _burn(msg.sender, _amount);
        _strat.withdraw(_amount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
    }

    function refreshApproval() external {
        _dToken.approve(address(_strat), type(uint256).max);
    }

    function depositToken() external view returns(address) {
        return address(_dToken);
    }

    function strategy() external view returns(address) {
        return address(_strat);
    }

    function recoverERC20(address _to, address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}