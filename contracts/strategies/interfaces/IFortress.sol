// SPDX-License-Identifier: GPL-3.0-only
// IFortress Interface by FortiFi

pragma solidity ^0.8.18;

/// @title Interface for FortiFi Fortresses
interface IFortress {
    function deposit(uint amount, address user) external returns(uint);
    function withdraw(address user) external;
    function recoverERC20(address to, address token, uint amount) external;
    function balanceOf(address holder) external view returns(uint256);
}