// SPDX-License-Identifier: GPL-3.0-only
// FortiFiFeeCalculator by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../fee-calculators/interfaces/IFortiFiFeeCalculator.sol";

pragma solidity ^0.8.18;

/// @title Contract to calculate fees for FortiFi Vaults
/// @notice This contract is used by FortiFi Vaults to calculate fees based on a user's NFT holdings. 
/// @dev When combineNftHoldings is true the contract will combine the user's balance across all NFT
/// contracts in the nftContracts array when determining fees. Otherwise, the contract will only take 
/// the user's highest balance out of the nftContracts.
contract FortiFiFeeCalculator is IFortiFiFeeCalculator, Ownable {

    uint16 public constant BPS = 10_000;
    bool public combineNftHoldings;
    uint8[] public tokenAmounts;
    uint16[] public thresholdBps;
    address[] public nftContracts;
    
    constructor(address[] memory _nftContracts,
                uint8[] memory _tokenAmounts,
                uint16[] memory _thresholdBps,
                bool _combineHoldings) {

        setFees(_nftContracts, _tokenAmounts, _thresholdBps);
        combineNftHoldings = _combineHoldings;
    }

    /// @notice Function to determine fees due based on a user's NFT holdings and amount of profit
    function getFees(address _user, uint256 _amount) external view override returns(uint256) {
        if (combineNftHoldings) {
            return _getCombinedFees(_user, _amount);
        } 

        return _getFees(_user, _amount);
    }

    /// @notice Function to set new values for NFT contracts, threshold amounts, and thresholdBps
    /// @dev Each amount in _tokenAmounts must have a corresponding bps value in _thresholdBps. Bps values should 
    /// decrease at each index, and token amounts should increase at each index. This maintains that the more NFTs
    /// a user holds, the lower the fee bps.
    function setFees(address[] memory _nftContracts, uint8[] memory _tokenAmounts, uint16[] memory _thresholdBps) public onlyOwner {
        uint256 _length = _nftContracts.length;
        require (_length > 0, "FortiFi: Invalid NFT array");

        for (uint256 i = 0; i < _length; i++) {
            require(_nftContracts[i] != address(0), "FortiFi: Invalid NFT address");
        }

        require(_tokenAmounts.length == _thresholdBps.length &&
                _validateAmountsAndBps(_tokenAmounts, _thresholdBps), "FortiFi: Invalid amounts or bps");
        
        nftContracts = _nftContracts;
        tokenAmounts = _tokenAmounts;
        thresholdBps = _thresholdBps;
    }

    /// @notice Function to set combineNFTHoldings state variable. 
    /// @dev When true, holdings across all specified collections in nftContracts will be combined to set the
    /// NFT count that is used when determining the _feeBps in _getFees.
    function setCombine(bool _bool) external onlyOwner {
        combineNftHoldings = _bool;
    }

    /// @notice Validate that arrays meet specifications
    function _validateAmountsAndBps(uint8[] memory _amounts, uint16[] memory _bps) internal pure returns(bool) {
        require(_amounts.length > 0 &&
                _amounts[0] == 0, "FortiFi: Invalid amounts array");
        uint256 _length = _bps.length;
        for (uint256 i = 0; i < _length; i++) {
            if (i > 0) {
                require(_bps[i] < _bps[i-1], "FortiFi: Invalid bps array");
                require(_amounts[i] > _amounts[i-1], "FortiFi: Invalid amount values");
            }
        }
        return true;
    }

    /// @notice Get fees for user
    function _getFees(address _user, uint256 _amount) internal view returns (uint256) {
        uint256 _length = nftContracts.length;
        uint256 _amountLength = tokenAmounts.length;
        uint16 _feeBps = thresholdBps[0];

        for (uint256 i = 0; i < _length; i++) {
            IERC721 _nft = IERC721(nftContracts[i]);
            uint256 _balance = _nft.balanceOf(_user);

            if (_balance > 0) {
                for (uint256 j = 1; j < _amountLength; j++) {
                    if (_balance < tokenAmounts[j]) {
                        uint16 _bps = thresholdBps[j - 1];
                        if (_bps < _feeBps) {
                            _feeBps = _bps;
                        }
                        break;
                    } else if (_balance == tokenAmounts[j] || j == (_amountLength - 1)) {
                        uint16 _bps = thresholdBps[j];
                        if (_bps < _feeBps) {
                            _feeBps = _bps;
                        }
                    }
                }
            } 
        }

        // return 0 fee if amount is too small
        if (_amount * _feeBps < BPS) {
            return 0;
        }

        return _amount * _feeBps / BPS;
    }

    /// @notice Get fees for user when combineNFTHoldings is true.
    function _getCombinedFees(address _user, uint256 _amount) internal view returns (uint256) {
        uint256 _length = nftContracts.length;
        uint256 _amountLength = tokenAmounts.length;
        uint256 _balance = 0;
        uint16 _feeBps = thresholdBps[0];

        for (uint256 i = 0; i < _length; i++) {
            IERC721 _nft = IERC721(nftContracts[i]);
            _balance += _nft.balanceOf(_user);
        }

        if (_balance > 0) {
            for (uint256 j = 1; j < _amountLength; j++) {
                if (_balance < tokenAmounts[j]) {
                    uint16 _bps = thresholdBps[j - 1];
                    if (_bps < _feeBps) {
                        _feeBps = _bps;
                    }
                    break;
                } else if (_balance == tokenAmounts[j] || j == (_amountLength - 1)) {
                    uint16 _bps = thresholdBps[j];
                    if (_bps < _feeBps) {
                        _feeBps = _bps;
                    }
                }
            }
        } 

        // return 0 fee if amount is too small
        if (_amount * _feeBps < BPS) {
            return 0;
        }

        return _amount * _feeBps / BPS;
    }
}