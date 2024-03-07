// SPDX-License-Identifier: GPL-3.0-only
// FortiFiTokenHelper by FortiFi

import "../vaults/interfaces/IMASS.sol";
import "../vaults/interfaces/ISAMS.sol";

interface IMASSHelper {
    function tokenInfo(uint) external view returns(IMASS.TokenInfo memory);
}

interface ISAMSHelper {
    function tokenInfo(uint) external view returns(ISAMS.TokenInfo memory);
}

pragma solidity 0.8.21;

/// @title FortiFiTokenHelper
/// @notice This contract is used to retrieve tokenInfo - check the chain
contract FortiFiTokenHelper {

    constructor() {}

    /// @notice Function to retrieve tokenInfo
    function getInfo(
        address[] calldata _contracts, 
        bool[] calldata _isMASS, 
        uint[][] calldata _tokenIds) external view returns(IMASS.TokenInfo[] memory) {
        
        IMASSHelper _mass;
        ISAMSHelper _sams;
        uint _tokenCount;
        uint _length = _contracts.length;

        for (uint i = 0; i < _length; i++ ) {
            _tokenCount += _tokenIds[i].length;
        }

        IMASS.TokenInfo[] memory _info = new IMASS.TokenInfo[](_tokenCount);

        for (uint i = 0; i < _length; i++ ) {
            uint _tokensLength = _tokenIds[i].length;

            if (_isMASS[i]) {
                _mass = IMASSHelper(_contracts[i]);
                for (uint j = 0; j < _tokensLength; j++) {
                    IMASS.TokenInfo memory _tokenInfo = _mass.tokenInfo(_tokenIds[i][j]);
                    _info[_info.length] = _tokenInfo;
                }
            } else {
                _sams = ISAMSHelper(_contracts[i]);
                for (uint j = 0; j < _tokensLength; j++) {
                    IMASS.TokenInfo memory _tokenInfo;
                    ISAMS.TokenInfo memory _samsInfo = _sams.tokenInfo(_tokenIds[i][j]);
                    _tokenInfo.deposit = _samsInfo.deposit;
                    uint _numPositions = _samsInfo.positions.length;
                    for (uint k = 0; k < _numPositions; k++) {
                        _tokenInfo.positions[k].receipt = _samsInfo.positions[k].receipt;
                        _tokenInfo.positions[k].strategy.strategy = _samsInfo.positions[k].strategy.strategy;
                        _tokenInfo.positions[k].strategy.isFortiFi = _samsInfo.positions[k].strategy.isFortiFi;
                        _tokenInfo.positions[k].strategy.bps = _samsInfo.positions[k].strategy.bps;
                    }
                    _info[_info.length] = _tokenInfo;
                }
            }
        }
        
        return _info;

    }
}