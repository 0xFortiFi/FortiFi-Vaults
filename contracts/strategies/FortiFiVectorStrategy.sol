// SPDX-License-Identifier: MIT
// FortiFiVectorStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./interfaces/IVectorStrategy.sol";

pragma solidity ^0.8.2;

contract FortiFiVectorStrategy is FortiFiStrategy {
    IVectorStrategy private _strat;
    IERC20 private _dToken;
    uint256 public slippageBps;

    constructor(address _strategy, address _depositToken, uint256 _slippageBps) FortiFiStrategy(_strategy, _depositToken){
        require(_strategy != address(0), "FortiFi: Invalid strategy address");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token address");
        require(_slippageBps < 10000, "FortiFi: Invalid slippage bps");
        _strat = IVectorStrategy(_strategy);
        _dToken = IERC20(_depositToken);
        slippageBps = _slippageBps;

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);
    }

    function withdraw(uint256 _amount) external override {
        require(_amount > 0, "FortiFi: Must withdraw more than 0");
        require(_strat.transferFrom(msg.sender, address(this), _amount), "FortiFiStrategy: Failed to transfer receipt");
        uint256 _tokensForShares = _strat.getDepositTokensForShares(_amount);
        uint256 _minAmount = _tokensForShares * (10000 - slippageBps) / 10000;
        
        _strat.withdraw(_tokensForShares, _minAmount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFiStrategy: Failed to transfer dToken");

        if (_strat.balanceOf(address(this)) > 0) {
            require(_strat.transfer(msg.sender, _strat.balanceOf(address(this))), "FortiFiStrategy: Failed to refund excess receipt tokens");
        }
    }

}