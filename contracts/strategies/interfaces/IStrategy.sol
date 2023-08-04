// SPDX-License-Identifier: MIT
// IStrategy Interface by FortiFi

pragma solidity ^0.8.2;

interface IStrategy {
    function approve(address spender, uint amount) external;
    function deposit(uint amount) external;
    function transferFrom(address from, address to, uint amount) external returns(bool);
    function transfer(address to, uint amount) external returns(bool);
    function withdraw(uint amount) external;
    function balanceOf(address holder) external view returns(uint256);
}