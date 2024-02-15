// SPDX-License-Identifier: GPL-3.0-only
// FortiFiDIAPriceOracleL2 by FortiFi

import "./FortiFiPriceOracleL2.sol";

pragma solidity 0.8.21;

interface IDIAOracleV2{
    function getValue(string memory) external view returns (uint128, uint128);
}

/// @title FortiFiDIAPriceOracleL2
/// @notice This contract is an implementation of FortiFiPriceOracle adapted for DIA on-chain oracles
/// @dev Only use on Arbitrum, Optimism, and Metis per Chainlink Documentation
contract FortiFiDIAPriceOracleL2 is FortiFiPriceOracleL2 {
    string public key;

    constructor(address _token, address _feed, address _uptimeFeed, string memory _key) FortiFiPriceOracleL2(_token, _feed, _uptimeFeed) {
        key = _key;
    }

    function getPrice() external view override returns(uint256) {
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
        
        (uint128 answer2, uint128 timeStamp) = IDIAOracleV2(feed).getValue(key);

        if (answer2 <= 0) revert InvalidPrice();
        if (timeStamp < block.timestamp - (75*60) /*75 minutes*/ ) revert StalePrice();
        
        return uint(answer2);
    }

    function decimals() external view override returns (uint8) {
        return 8;
    }
}