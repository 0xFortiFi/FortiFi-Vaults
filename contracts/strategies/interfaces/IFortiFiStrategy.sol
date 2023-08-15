// SPDX-License-Identifier: MIT
// IFortiFiStrategy Interface by FortiFi

pragma solidity ^0.8.2;

interface IFortiFiStrategy {
    function deposit(uint amount) external;
    function withdraw(uint amount) external;
    function strategy() external view returns(address);
}