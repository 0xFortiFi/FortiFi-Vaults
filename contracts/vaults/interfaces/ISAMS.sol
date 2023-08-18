// SPDX-License-Identifier: MIT
// ISAMS Interface by FortiFi

pragma solidity ^0.8.2;

interface ISAMS {
    struct Strategy {
        address strategy;
        bool isVector;
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

    function deposit(uint amount) external;
    function add(uint amount, uint tokenId) external;
    function withdraw(uint amount) external;
    function tokenInfo(uint tokenId) external view returns(TokenInfo memory);
}