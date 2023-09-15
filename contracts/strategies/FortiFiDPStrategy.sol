// SPDX-License-Identifier: MIT
// FortiFiDPStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./FortiFiDPFortress.sol";

pragma solidity ^0.8.18;

/// @title Delta Prime FortiFi Strategy contract
/// @notice This contract allows for FortiFi vaults to utilize Delta Prime strategies. 
contract FortiFiDPStrategy is FortiFiStrategy {

    constructor(address _strategy, address _depositToken, address _wrappedNative) 
        FortiFiStrategy(_strategy, _depositToken, _wrappedNative) {
    }

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiDPFortress contract
    /// instead of the base FortiFiFortress contract
    function depositToFortress(uint256 _amount, address _user, uint256 _tokenId) external override {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(isFortiFiVault[msg.sender], "FortiFi: Invalid vault");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        IFortress _fortress;

        // If user has not deposited previously, deploy Fortress
        if (vaultToTokenToFortress[msg.sender][_tokenId] == address(0)) {
            FortiFiDPFortress _fort = new FortiFiDPFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IFortress(address(_fort));
            vaultToTokenToFortress[msg.sender][_tokenId] = address(_fortress);
            emit FortressCreated(msg.sender, _tokenId, address(_strat));
        } else {
            _fortress = IFortress(vaultToTokenToFortress[msg.sender][_tokenId]);
        }

        // approve and deposit
        _dToken.approve(address(_fortress), _amount);
        uint256 _receipts = _fortress.deposit(_amount, _user);

        // mint receipt tokens equal to what was received from Fortress
        _mint(msg.sender, _receipts);

        // Refund left over deposit tokens, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            require(_dToken.transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        emit DepositToFortress(msg.sender, _user, address(_strat), _amount);
    }

}