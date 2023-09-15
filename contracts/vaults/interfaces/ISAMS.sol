// SPDX-License-Identifier: GPL-3.0-only
// ISAMS Interface by FortiFi

pragma solidity ^0.8.18;

/// @title Interface for FortiFi SAMS Vaults
interface ISAMS {
    struct Strategy {
        address strategy;
        bool isFortiFi;
        uint16 bps;
    }

    struct Position {
        Strategy strategy;
        uint256 receipt;
    }

    struct TokenInfo {
        uint256 deposit;
        Position[] positions;
    }

    function deposit(uint amount) external returns(uint256 tokenId, TokenInfo memory info);
    function add(uint amount, uint tokenId) external returns(TokenInfo memory info);
    function withdraw(uint amount) external;
    function rebalance(uint tokenId) external returns(TokenInfo memory info);
    function getTokenInfo(uint tokenId) external view returns(TokenInfo memory info);
    function getStrategies() external view returns(Strategy[] memory strategies);
}