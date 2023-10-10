// SPDX-License-Identifier: GPL-3.0-only
// FortiFiPriceOracle by FortiFi

import "./interfaces/IFortiFiPriceOracle.sol";
import "./interfaces/AggregatorV3Interface.sol";

pragma solidity 0.8.21;

/// @title FortiFiPriceOracle
/// @notice This contract is used as a flexible interface to provide prices to FortiFiMASSVault implementations.
/// This base version is meant to use Chainlink on-chain price feeds, and can be inherited and modified to 
/// support other oracles.
contract FortiFiPriceOracle is IFortiFiPriceOracle {
    address public immutable token;
    AggregatorV3Interface public immutable feed;

    constructor(address _token, address _feed) {
        token = _token;
        feed = AggregatorV3Interface(_feed);
    }

    function getPrice() external view returns(uint256) {
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = feed.latestRoundData();
        return uint(answer);
    }
}