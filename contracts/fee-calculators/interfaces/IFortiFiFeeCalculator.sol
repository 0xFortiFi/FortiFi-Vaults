// SPDX-License-Identifier: GPL-3.0-only
// IFortiFiFeeCalculator Interface by FortiFi

pragma solidity ^0.8.18;

/// @title Interface for FortiFiFeeCalculator
interface IFortiFiFeeCalculator {
    function getFees(address user, uint256 amount) external view returns(uint256);
}