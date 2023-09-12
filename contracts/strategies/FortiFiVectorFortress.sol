// SPDX-License-Identifier: MIT
// FortiFiVectorFortress by FortiFi

import "./FortiFiFortress.sol";
import "./interfaces/IVectorStrategy.sol";

pragma solidity ^0.8.2;

contract FortiFiVectorFortress is FortiFiFortress {
    uint16 private constant BPS = 10_000;
    uint256 private slippageBps = 100;
    IVectorStrategy private _vectorStrat;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _owner) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative, _owner) {
        _vectorStrat = IVectorStrategy(_strategy);
    }

    function withdraw(uint256 _amount) external override onlyOwner {
        require(_amount > 0, "FortiFi: 0 withdraw");
        _burn(msg.sender, _amount);
        uint256 _tokensForShares = _vectorStrat.getDepositTokensForShares(_amount);
        uint256 _minAmount = _tokensForShares * (BPS - slippageBps) / BPS;
        
        _vectorStrat.withdraw(_tokensForShares, _minAmount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");

        if (_vectorStrat.balanceOf(address(this)) > 0) {
            require(_vectorStrat.transfer(msg.sender, _vectorStrat.balanceOf(address(this))), "FortiFi: Failed to refund");
        }

        _refund();
    }

    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
    }
    
}