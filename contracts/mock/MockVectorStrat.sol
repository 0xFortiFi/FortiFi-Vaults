// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title A mock Vector strategy contract
/// @notice You can use this contract for only the most basic simulation since this contract
/// does not keep track of deposits. 
/// @dev This contract is meant to mimic Vector and other strategy contracts that 
/// allows require calculations for withdrawal. see: https://snowtrace.io/address/0xcade1284aecc2d38bb957368f69a32fa370cf6f8#code
contract MockVectorStrat is ERC20 {
    IERC20 depositToken;

    constructor(address _depositToken) ERC20("Mock Vector Strategy", "vRECEIPT"){
        depositToken = IERC20(_depositToken);
    }

    function deposit(uint256 amount) external {
        depositToken.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount * 9000 / 10000);
    }

    function withdraw(uint256 amount, uint256 minAmount) external {
        uint256 _userBalance = balanceOf(msg.sender);
        uint256 _tokensForShares = getDepositTokensForShares(_userBalance);
        require(_tokensForShares >= minAmount, "MockVectorStrat: Shares < minAmount");
        uint256 _burnAmount = _userBalance;
        if (_tokensForShares > amount) {
            _tokensForShares = amount;
            _burnAmount = getSharesForTokens(amount);
        }
        _burn(msg.sender, _burnAmount);
        depositToken.transfer(msg.sender, _tokensForShares);
    }

    function getDepositTokensForShares(uint256 amount) public view returns(uint256) {
        uint256 _depositBalance = depositToken.balanceOf(address(this));
        uint256 _supply = totalSupply();

        if (_supply > 0) {
            return amount * _depositBalance / totalSupply();
        } 

        return 0;
    }

    function getSharesForTokens(uint256 amount) internal view returns(uint256) {
        uint256 _depositBalance = depositToken.balanceOf(address(this));
        uint256 _supply = totalSupply();

        if (_supply > 0) {
            return amount * totalSupply() / _depositBalance;
        } 

        return 0;
    }

}