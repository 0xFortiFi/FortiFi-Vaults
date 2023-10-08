// SPDX-License-Identifier: GPL-3.0-only
// IFortiFiFeeManager Interface by FortiFi

pragma solidity 0.8.21;

/// @title Interface for FortiFiFeeManager
interface IFortiFiFeeManager {
    function collectFees(address token, uint256 amount) external;
}