// SPDX-License-Identifier: GPL-3.0-only
// FortiFiTokenHelper by FortiFi

import "../vaults/interfaces/IMASS.sol";
import "../vaults/interfaces/ISAMS.sol";

interface IMASSHelper {
    function getTokenInfo(uint) external view returns(IMASS.TokenInfo memory);
}

interface ISAMSHelper {
    function getTokenInfo(uint) external view returns(ISAMS.TokenInfo memory);
}

pragma solidity 0.8.21;

/// @title FortiFiTokenHelper
/// @notice This contract is used to retrieve tokenInfo - check the chain
contract FortiFiTokenHelper {

    constructor() {}

    /// @notice Function to retrieve MASS tokenInfo
    function getMASSInfo(
        address[] calldata _contracts, 
        uint[][] calldata _tokenIds) external view returns(
            IMASS.TokenInfo memory _info1, 
            IMASS.TokenInfo memory _info2,
            IMASS.TokenInfo memory _info3,
            IMASS.TokenInfo memory _info4,
            IMASS.TokenInfo memory _info5) {
        
        IMASSHelper _mass;
        uint _tokenCount;
        uint _length = _contracts.length;

        for (uint i = 0; i < _length; i++ ) {
            uint _tokensLength = _tokenIds[i].length;

            _mass = IMASSHelper(_contracts[i]);
            for (uint j = 0; j < _tokensLength; j++) {
                if (_tokenCount == 0) {
                    _info1 = _mass.getTokenInfo(_tokenIds[i][j]);
                } else if (_tokenCount == 1) {
                    _info2 = _mass.getTokenInfo(_tokenIds[i][j]);
                } else if (_tokenCount == 2) {
                    _info3 = _mass.getTokenInfo(_tokenIds[i][j]);
                } else if (_tokenCount == 3) {
                    _info4 = _mass.getTokenInfo(_tokenIds[i][j]);
                } else {
                    _info5 = _mass.getTokenInfo(_tokenIds[i][j]);
                }
                _tokenCount += 1;
            } 
        }

    }

    /// @notice Function to retrieve SAMS tokenInfo
    function getSAMSInfo(
        address[] calldata _contracts, 
        uint[][] calldata _tokenIds) external view returns(
            ISAMS.TokenInfo memory _info1, 
            ISAMS.TokenInfo memory _info2,
            ISAMS.TokenInfo memory _info3,
            ISAMS.TokenInfo memory _info4,
            ISAMS.TokenInfo memory _info5) {
        
        ISAMSHelper _sams;
        uint _tokenCount;
        uint _length = _contracts.length;

        for (uint i = 0; i < _length; i++ ) {
            uint _tokensLength = _tokenIds[i].length;

            _sams = ISAMSHelper(_contracts[i]);
            for (uint j = 0; j < _tokensLength; j++) {
                if (_tokenCount == 0) {
                    _info1 = _sams.getTokenInfo(_tokenIds[i][j]);
                } else if (_tokenCount == 1) {
                    _info2 = _sams.getTokenInfo(_tokenIds[i][j]);
                } else if (_tokenCount == 2) {
                    _info3 = _sams.getTokenInfo(_tokenIds[i][j]);
                } else if (_tokenCount == 3) {
                    _info4 = _sams.getTokenInfo(_tokenIds[i][j]);
                } else {
                    _info5 = _sams.getTokenInfo(_tokenIds[i][j]);
                }
                _tokenCount += 1;
            }
        }

    }
}