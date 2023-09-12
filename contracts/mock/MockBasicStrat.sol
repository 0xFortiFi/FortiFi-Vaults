// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title A basic mock strategy contract
/// @notice You can use this contract for only the most basic simulation since this contract
/// does not keep track of deposits. 
/// @dev This contract is meant to mimic Yield Yak and other strategy contracts that 
/// allows for simple deposit and withdrawal. see: https://snowtrace.io/address/0xc8ceea18c2e168c6e767422c8d144c55545d23e9#code
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