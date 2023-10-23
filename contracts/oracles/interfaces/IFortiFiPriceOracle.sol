// SPDX-License-Identifier: GPL-3.0-only
// IFortiFiPriceOracle Interface by FortiFi

pragma solidity 0.8.21;

/// @title Interface for FortiFiPriceOracle
interface IFortiFiPriceOracle {
    function getPrice() external view returns(uint256);
    function token() external view returns(address);
    function decimals() external view returns (uint8);
}