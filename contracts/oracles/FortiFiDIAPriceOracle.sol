// SPDX-License-Identifier: GPL-3.0-only
// FortiFiDIAPriceOracle by FortiFi

import "./FortiFiPriceOracle.sol";

pragma solidity 0.8.21;

interface IDIAOracleV2{
    function getValue(string memory) external view returns (uint128, uint128);
}

/// @title FortiFiDIAPriceOracle
/// @notice This contract is an implementation of FortiFiPriceOracle adapted for DIA on-chain oracles
contract FortiFiDIAPriceOracle is FortiFiPriceOracle {
    string public key;

    constructor(address _token, address _feed, string memory _key) FortiFiPriceOracle(_token, _feed) {
        key = _key;
    }

    function getPrice() external view override returns(uint256) {
        (uint128 answer, uint128 timeStamp) = IDIAOracleV2(feed).getValue(key);

        if (answer <= 0) revert InvalidPrice();
        if (timeStamp < block.timestamp - (75*60) /*75 minutes*/ ) revert StalePrice();
        
        return uint(answer);
    }

    function decimals() external view override returns (uint8) {
        return 8;
    }
}