// SPDX-License-Identifier: GPL-3.0-only
// IStrategy Interface by FortiFi

pragma solidity 0.8.21;

/// @title Interface for basic strategies used by FortiFi SAMS Vaults
interface INativeStrategy {
    function approve(address spender, uint amount) external returns (bool);
    function deposit() external payable;
    function depositToFortress(uint amount, address user, uint tokenId) external;
    function withdraw(uint amount) external;
    function withdrawFromFortress(uint amount, address user, uint tokenId) external;
    function balanceOf(address holder) external view returns(uint256);
}