// SPDX-License-Identifier: GPL-3.0-only
// IRouter Interface by FortiFi

pragma solidity ^0.8.18;

/// @title Simple router interface for FortiFi MASS Vaults
interface IRouter {
    function swapExactTokensForTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}