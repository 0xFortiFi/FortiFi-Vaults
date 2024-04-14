// SPDX-License-Identifier: GPL-3.0-only
// IWombatFortress Interface by FortiFi

pragma solidity 0.8.21;

/// @title Interface for FortiFi Wombat Fortresses
interface IWombatFortress {
    function depositWombat(uint amount, uint slippage, address user) external returns(uint);
    function withdrawWombat(address user, uint slippage, address[] memory extraTokens) external;
    function withdrawBricked(address user) external;
    function recoverERC20(address to, address token, uint amount) external;
    function balanceOf(address holder) external view returns(uint256);
}