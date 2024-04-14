// SPDX-License-Identifier: GPL-3.0-only
// FortiFiMockOracle by FortiFi

import "./interfaces/IFortiFiPriceOracle.sol";
import "./interfaces/AggregatorV3Interface.sol";

pragma solidity 0.8.21;


/// @title FortiFiMockOracle
/// @notice This contract is used to simulate an oracle, but only returns a static response
/// @dev this should only be used in a case where the returned price is not actually used in calculations, as is the 
/// case for our LST MultiYield where a custom router for ggAVAX doesn't swap but instead deposits/redeems from GoGoPool
contract FortiFiPriceOracle is IFortiFiPriceOracle {
    address public immutable token;

    constructor(address _token) {
        token = _token;
    }

    function getPrice() external view virtual returns(uint256) {   
        return uint(133700000000);
    }

    function decimals() external view virtual returns (uint8) {
        return 8;
    }
}