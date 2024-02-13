// SPDX-License-Identifier: MIT
// FortiFiVectorFortress by FortiFi

import "./FortiFiFortress.sol";
import "./interfaces/IVectorStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.21;

/// @title FortiFi Fortress contract for Vector Finance strategies
/// @notice This Fortress contract is specifically made to interact with Vector Finance strategies
contract FortiFiVectorFortress is FortiFiFortress {
    using SafeERC20 for IERC20;
    uint16 private constant BPS = 10_000;
    IVectorStrategy public immutable _vectorStrat;

    constructor(address _strategy, address _depositToken, address _wrappedNative) 
        FortiFiFortress(_strategy, _depositToken, _wrappedNative) {
        _vectorStrat = IVectorStrategy(_strategy);
    }

    /// @notice Nullified withdraw function
    /// @dev this override is to ensure an incorrect withdraw call is not made from the strategy contract.
    /// Vector strategies require calling withdrawVector(_amount, _slippageBps)
    function withdraw(address, address[] memory extraTokens) external override onlyOwner {
        revert("FortiFi: Invalid withdraw");
    }

    /// @notice Function to withdraw
    /// @dev Vector Finance strategies require that you pass in the amount of deposit tokens you expect to receive
    /// rather than the amount of receipt tokens you want to burn as well as a minAmount. This is calculated by utilizing the
    /// getDepositTokensForShares view function and applying a slippage amount (typically 1%).
    function withdrawVector(address _user, address[] memory _extraTokens, uint16 _slippageBps) external onlyOwner {
        uint256 _balance = _vectorStrat.balanceOf(address(this));
        if (_balance == 0) revert InvalidWithdrawal();

        // calculate _tokensForShares and apply slippage
        uint256 _tokensForShares = _vectorStrat.getDepositTokensForShares(_balance);
        uint256 _minAmount = _tokensForShares * (BPS - _slippageBps) / BPS;
        
        // withdraw from vector strategy
        _vectorStrat.withdraw(_tokensForShares, _minAmount);
        
        // ensure no strategy receipt tokens remain
        _balance = _vectorStrat.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(_vectorStrat)).safeTransfer(_user, _balance);
        }

        // transfer received deposit tokens and refund left over tokens, if any
        _dToken.safeTransfer(msg.sender, _dToken.balanceOf(address(this)));

        // transfer extra reward tokens
        uint256 _length = _extraTokens.length;
        if (_length > 0) {
            for(uint256 i = 0; i < _length; i++) {
                IERC20 _token = IERC20(_extraTokens[i]);
                uint256 _tokenBalance = _token.balanceOf(address(this));
                if (_tokenBalance > 0) {
                    _token.safeTransfer(msg.sender, _tokenBalance);
                }
            }
        }

        _refund(_user);

        emit WithdrawalMade(_user);
    }
    
}