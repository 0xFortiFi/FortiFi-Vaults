// SPDX-License-Identifier: GPL-3.0-only
// IFortress Interface by FortiFi

pragma solidity ^0.8.18;

/// @title Interface for FortiFi Vector Fortresses
interface IVectorFortress {
    function deposit(uint amount) external;
    function withdrawVector(uint amount, uint slippage) external;
    function recoverERC20(address to, address token, uint amount) external;
    function balanceOf(address holder) external view returns(uint256);
}