// SPDX-License-Identifier: MIT
// FortiFiVault by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "../strategies/interfaces/IFortiFiStrategy.sol";
import "../fee-calculators/interfaces/IFortiFiFeeCalculator.sol";
import "../fee-managers/interfaces/IFortiFiFeeManager.sol";

pragma solidity ^0.8.2;

contract FortiFiVault is ERC1155, Ownable, ReentrancyGuard {
    struct Position {
        address strategy;
        uint256 deposit;
    }

    string public name;
    string public symbol;
    address[] public strategies;
    uint16[] public strategyBps;

    IFortiFiFeeCalculator public feeCalc;
    IFortiFiFeeManager public feeMgr;

    mapping (uint256 => Position[]) public tokenToPositions;

    constructor(string memory _name, 
                string memory _symbol, 
                string memory _metadata,
                address _feeManager,
                address _feeCalculator,
                address[] memory _strategies,
                uint16[] memory _strategyBps) ERC1155(_metadata) {
        name = _name; 
        symbol = _symbol;
        feeCalc = IFortiFiFeeCalculator(_feeCalculator);
        feeMgr = IFortiFiFeeManager(_feeManager);
        strategies = _strategies;
        strategyBps = _strategyBps;
    }

}