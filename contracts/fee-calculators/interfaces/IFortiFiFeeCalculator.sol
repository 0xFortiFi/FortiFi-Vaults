// SPDX-License-Identifier: MIT
// IFortiFiFeeCalculator Interface by FortiFi

pragma solidity ^0.8.2;

/// @title Interface for FortiFiFeeCalculator
interface IFortiFiFeeCalculator {
    function getFees(address user, uint256 amount) external view returns(uint256);
}