// SPDX-License-Identifier: MIT
// FortiFiVectorFortress by FortiFi

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./FortiFiFortress.sol";
import "./interfaces/IVectorStrategy.sol";

pragma solidity ^0.8.2;

contract FortiFiVectorFortress is FortiFiFortress {
    uint16 public constant BPS = 10_000;
    uint256 public slippageBps = 100;
    IVectorStrategy private _strat;
    IERC20 private _dToken;

    constructor(address _strategy, address _depositToken) FortiFiFortress(_strategy, _depositToken) {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        _strat = IVectorStrategy(_strategy);
        _dToken = IERC20(_depositToken);

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);
    }

    function withdraw(uint256 _amount) external override {
        require(_amount > 0, "FortiFi: 0 withdraw");
        _burn(msg.sender, _amount);
        uint256 _tokensForShares = _strat.getDepositTokensForShares(_amount);
        uint256 _minAmount = _tokensForShares * (BPS - slippageBps) / BPS;
        
        _strat.withdraw(_tokensForShares, _minAmount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");

        if (_strat.balanceOf(address(this)) > 0) {
            require(_strat.transfer(msg.sender, _strat.balanceOf(address(this))), "FortiFi: Failed to refund");
        }
    }

    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
    }

}