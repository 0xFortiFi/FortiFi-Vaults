// SPDX-License-Identifier: MIT
// FortiFiDPFortress by FortiFi

import "./FortiFiFortress.sol";
import "./interfaces/IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.21;

/// @title FortiFi Fortress contract for Delta Prime strategies
/// @notice This Fortress contract is specifically made to interact with Delta Prime strategies
contract FortiFiDPFortress is FortiFiFortress {
    using SafeERC20 for IERC20;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _fortiFiStrat) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative, _fortiFiStrat) {
    }

    /// @notice Function to withdraw
    /// @dev Delta Prime strategies mint new receipt tokens as accrued interest so in order to calculate total tokens to be burned
    /// you must call balanceOf on the strategy, which returns the total balance including interest.
    /// This means that total balance will be withdrawn every time withdraw is called.
    function withdraw(address _user) external override onlyOwner {
        uint256 _balance = _strat.balanceOf(address(this));
        require(_balance > 0, "FortiFi: 0 withdraw");
        
        // withdraw from strategy
        _strat.withdraw(_balance);

        // ensure no strategy receipt tokens remain
        _balance = _strat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_strat)).safeTransfer(_user, _balance);
        }

        // transfer received deposit tokens and refund left over tokens, if any
        _dToken.safeTransfer(msg.sender, _dToken.balanceOf(address(this)));
        _refund(_user);
    }

}