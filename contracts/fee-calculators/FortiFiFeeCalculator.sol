// SPDX-License-Identifier: MIT
// FortiFiFeeCalculator by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

pragma solidity ^0.8.2;

contract FortiFiFeeCalculator is Ownable {

    uint8[] public tokenAmounts;
    uint16[] public threshholdBps;
    address[] public nftContracts;
    bool public combineNftHoldings;

    constructor(address[] memory _nftContracts,
                uint8[] memory _tokenAmounts,
                uint16[] memory _threshholdBps,
                bool _combineHoldings) {

        setFees(_nftContracts, _tokenAmounts, _threshholdBps);
        combineNftHoldings = _combineHoldings;
    }

    function getFees(address _user, uint256 _amount) external view returns(uint256) {
        if (combineNftHoldings) {
            return _getCombinedFees(_user, _amount);
        } 

        return _getFees(_user, _amount);
    }

    function setFees(address[] memory _nftContracts, uint8[] memory _tokenAmounts, uint16[] memory _threshholdBps) public onlyOwner {
        uint8 _length = uint8(_nftContracts.length);
        require (_length > 0, "FortiFi: Invalid NFT array");

        for (uint8 i = 0; i < _length; i++) {
            require(_nftContracts[i] != address(0), "FortiFi: Invalid NFT address");
        }

        require(_tokenAmounts.length == _threshholdBps.length &&
                _validateAmountsAndBps(_tokenAmounts, _threshholdBps), "FortiFi: Invalid amounts or bps");
        
        nftContracts = _nftContracts;
        tokenAmounts = _tokenAmounts;
        threshholdBps = _threshholdBps;
    }

    function setCombine(bool _bool) external onlyOwner {
        combineNftHoldings = _bool;
    }

    function _validateAmountsAndBps(uint8[] memory _amounts, uint16[] memory _bps) internal pure returns(bool) {
        require(_amounts.length > 0 &&
                _amounts[0] == 0, "FortiFi: Invalid amounts array");
        uint8 _length = uint8(_bps.length);
        for (uint256 i = 0; i < _length; i++) {
            if (i > 0) {
                require(_bps[i] < _bps[i-1], "FortiFi: Invalid bps array");
            }
        }
        return true;
    }

    function _getFees(address _user, uint256 _amount) internal view returns (uint256) {
        uint8 _length = uint8(nftContracts.length);
        uint8 _amountLength = uint8(tokenAmounts.length);
        uint16 _feeBps = threshholdBps[0];

        for (uint8 i = 0; i < _length; i++) {
            IERC721 _nft = IERC721(nftContracts[i]);
            uint256 _balance = _nft.balanceOf(_user);

            if (_balance > 0) {
                for (uint8 j = 1; j < _amountLength; j++) {
                    if (_balance < tokenAmounts[j]) {
                        uint16 _bps = threshholdBps[j - 1];
                        if (_bps < _feeBps) {
                            _feeBps = _bps;
                        }
                        break;
                    } else if (_balance == tokenAmounts[j] || j == (_amountLength - 1)) {
                        uint16 _bps = threshholdBps[j];
                        if (_bps < _feeBps) {
                            _feeBps = _bps;
                        }
                    }
                }
            } 
        }

        // return 0 fee if amount is too small
        if (_amount * _feeBps < 10000) {
            return 0;
        }

        return _amount * _feeBps / 10000;
    }

    function _getCombinedFees(address _user, uint256 _amount) internal view returns (uint256) {
        uint8 _length = uint8(nftContracts.length);
        uint8 _amountLength = uint8(tokenAmounts.length);
        uint16 _feeBps = threshholdBps[0];
        uint256 _balance = 0;

        for (uint8 i = 0; i < _length; i++) {
            IERC721 _nft = IERC721(nftContracts[i]);
            _balance += _nft.balanceOf(_user);
        }

        if (_balance > 0) {
            for (uint8 j = 1; j < _amountLength; j++) {
                if (_balance < tokenAmounts[j]) {
                    uint16 _bps = threshholdBps[j - 1];
                    if (_bps < _feeBps) {
                        _feeBps = _bps;
                    }
                    break;
                } else if (_balance == tokenAmounts[j] || j == (_amountLength - 1)) {
                    uint16 _bps = threshholdBps[j];
                    if (_bps < _feeBps) {
                        _feeBps = _bps;
                    }
                }
            }
        } 

        // return 0 fee if amount is too small
        if (_amount * _feeBps < 10000) {
            return 0;
        }

        return _amount * _feeBps / 10000;
    }
}