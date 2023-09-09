// SPDX-License-Identifier: GPL-3.0-only
// IFortress Interface by FortiFi

pragma solidity ^0.8.2;

/// @title Interface for FortiFi Fortresses
interface IFortress {
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function recoverERC20(address to, address token, uint amount) external;
}