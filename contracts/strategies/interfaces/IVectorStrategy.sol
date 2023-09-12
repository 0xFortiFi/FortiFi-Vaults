// SPDX-License-Identifier: GPL-3.0-only
// IVectorStrategy Interface by FortiFi

pragma solidity ^0.8.18;

/// @title Interface for Vector strategies used by FortiFi SAMS Vaults
interface IVectorStrategy {
    function approve(address spender, uint amount) external returns (bool);
    function deposit(uint amount) external;
    function transferFrom(address from, address to, uint amount) external returns(bool);
    function transfer(address to, uint amount) external returns(bool);
    function withdraw(uint amount, uint minAmount) external;
    function balanceOf(address holder) external view returns(uint256);
    function getDepositTokensForShares(uint256 amount) external view returns(uint256);
    function strategy() external view returns(address);
}