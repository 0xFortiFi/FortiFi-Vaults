// SPDX-License-Identifier: MIT
// IFortiFiFeeManager Interface by FortiFi

pragma solidity ^0.8.2;

/// @title Interface for FortiFiFeeManager
interface IFortiFiFeeManager {
    function collectFees(address token, uint256 amount) external;
}