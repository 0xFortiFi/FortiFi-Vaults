// SPDX-License-Identifier: GPL-3.0-only
// IStrategy Interface by FortiFi

pragma solidity ^0.8.18;

/// @title Interface for basic strategies used by FortiFi SAMS Vaults
interface IStrategy {
    function approve(address spender, uint amount) external returns (bool);
    function deposit(uint amount) external;
    function depositToFortress(uint amount, address user, uint tokenId) external;
    function transferFrom(address from, address to, uint amount) external returns(bool);
    function transfer(address to, uint amount) external returns(bool);
    function withdraw(uint amount) external;
    function withdrawFromFortress(uint amount, address user, uint tokenId) external;
    function balanceOf(address holder) external view returns(uint256);
}