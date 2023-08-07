// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// Simple stub to simulate Yak and DP strategies
contract MockBasicStrat is ERC20 {
    IERC20 depositToken;

    constructor(address _depositToken) ERC20("Mock Basic Strategy", "RECEIPT"){
        depositToken = IERC20(_depositToken);
    }

    function deposit(uint256 amount) external {
        depositToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        depositToken.transfer(msg.sender, getDepositTokensForShares(amount));
    }

    function getDepositTokensForShares(uint256 amount) internal view returns(uint256) {
        uint256 _depositBalance = depositToken.balanceOf(address(this));
        uint256 _supply = totalSupply() + amount;

        if (_supply > 0) {
            return amount * _depositBalance / _supply;
        } 

        return 0;
    }

}