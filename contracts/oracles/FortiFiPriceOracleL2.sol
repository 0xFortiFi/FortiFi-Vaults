// SPDX-License-Identifier: GPL-3.0-only
// FortiFiPriceOracleL2 by FortiFi

import "./interfaces/IFortiFiPriceOracle.sol";
import "./interfaces/AggregatorV2V3Interface.sol";

pragma solidity 0.8.21;

/// @notice Error caused by negative price returned from oracle
error InvalidPrice();

/// @notice Error caused by stale price returned from oracle
error StalePrice();

/// @notice Error caused by the sequencer being down
error SequencerDown();

/// @notice Error caused when sequencer has not been up longer than the grace period
error GracePeriodNotOver();


/// @title FortiFiPriceOracleL2
/// @notice This contract is used as a flexible interface to provide prices to FortiFiMASSVault implementations.
/// This base version is meant to use Chainlink on-chain price feeds, and can be inherited and modified to 
/// support other oracles.
/// @dev Only use on Arbitrum, Optimism, and Metis per Chainlink Documentation
contract FortiFiPriceOracleL2 is IFortiFiPriceOracle {
    address public immutable token;
    address public immutable feed;
    uint256 internal constant GRACE_PERIOD_TIME = 3600;
    AggregatorV2V3Interface internal sequencerUptimeFeed;

    constructor(address _token, address _feed, address _uptimeFeed) {
        token = _token;
        feed = _feed;
        sequencerUptimeFeed = AggregatorV2V3Interface(_uptimeFeed);
    }

    function getPrice() external view virtual returns(uint256) {
        // Sequencer check from Chainlink documentation 
        (
            /*uint80 roundID*/,
            int256 answer,
            uint256 startedAt,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = sequencerUptimeFeed.latestRoundData();

        // Answer == 0: Sequencer is up
        // Answer == 1: Sequencer is down
        bool isSequencerUp = answer == 0;
        if (!isSequencerUp) {
            revert SequencerDown();
        }

        // Make sure the grace period has passed after the
        // sequencer is back up.
        uint256 timeSinceUp = block.timestamp - startedAt;
        if (timeSinceUp <= GRACE_PERIOD_TIME) {
            revert GracePeriodNotOver();
        }

        AggregatorV2V3Interface _feed = AggregatorV2V3Interface(feed);
        (
            /* uint80 roundID */,
            int answer2,
            /*uint startedAt*/,
            uint timeStamp,
            /*uint80 answeredInRound*/
        ) = _feed.latestRoundData();

        if (answer2 <= 0) revert InvalidPrice();
        if (timeStamp < block.timestamp - (75*60) /*75 minutes*/ ) revert StalePrice();
        
        return uint(answer2);
    }

    function decimals() external view virtual returns (uint8) {
        AggregatorV2V3Interface _feed = AggregatorV2V3Interface(feed);
        return _feed.decimals();
    }
}