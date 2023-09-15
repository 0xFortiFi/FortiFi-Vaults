// SPDX-License-Identifier: MIT
// FortiFiVectorFortress by FortiFi

import "./FortiFiFortress.sol";
import "./interfaces/IVectorStrategy.sol";

pragma solidity ^0.8.18;

/// @title FortiFi Fortress contract for Vector Finance strategies
/// @notice This Fortress contract is specifically made to interact with Vector Finance strategies
contract FortiFiVectorFortress is FortiFiFortress {
    uint16 private constant BPS = 10_000;
    IVectorStrategy private immutable _vectorStrat;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _fortiFiStrat) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative, _fortiFiStrat) {
        _vectorStrat = IVectorStrategy(_strategy);
    }

    /// @notice Nullified withdraw function
    /// @dev this override is to ensure an incorrect withdraw call is not made from the strategy contract.
    /// Vector strategies require calling withdrawVector(_amount, _slippageBps)
    function withdraw(address) external override onlyOwner {
        revert("FortiFi: Invalid withdraw");
    }

    /// @notice Function to withdraw
    /// @dev Vector Finance strategies require that you pass in the amount of deposit tokens you expect to receive
    /// rather than the amount of receipt tokens you want to burn as well as a minAmount. This is calculated by utilizing the
    /// getDepositTokensForShares view function and applying a slippage amount (typically 1%).
    function withdrawVector(address _user, uint256 _slippageBps) external onlyOwner {
        uint256 _balance = _vectorStrat.balanceOf(address(this));
        require(_balance > 0, "FortiFi: 0 withdraw");

        // calculate _tokensForShares and apply slippage
        uint256 _tokensForShares = _vectorStrat.getDepositTokensForShares(_balance);
        uint256 _minAmount = _tokensForShares * (BPS - _slippageBps) / BPS;
        
        // withdraw from vector strategy
        _vectorStrat.withdraw(_tokensForShares, _minAmount);
        
        // ensure no strategy receipt tokens remain
        _balance = _vectorStrat.balanceOf(address(this));
        if (_balance > 0) {
            require(_vectorStrat.transfer(_user, _balance));
        }

        // transfer received deposit tokens and refund left over tokens, if any
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
        _refund(_user);
    }
    
}