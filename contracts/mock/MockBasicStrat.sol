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
        depositToken.transfer(msg.sender, amount);
    }

}