// SPDX-License-Identifier: MIT
// FortiFiVectorStrategy by FortiFi

import "./FortiFiStrategy.sol";
import "./FortiFiVectorFortress.sol";
import "./interfaces/IVectorFortress.sol";

pragma solidity ^0.8.18;

/// @title Delta Prime FortiFi Strategy contract
/// @notice This contract allows for FortiFi vaults to utilize Vector Finance strategies. 
contract FortiFiVectorStrategy is FortiFiStrategy {
    uint256 public slippageBps = 100;

    constructor(address _strategy, address _depositToken, address _wrappedNative) 
        FortiFiStrategy(_strategy, _depositToken, _wrappedNative) {
    }

    event SlippageSet(uint256 newSlippage);

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiVectorFortress contract
    /// instead of the base FortiFiFortress contract
    function depositToFortress(uint256 _amount, address _user, uint256 _tokenId) external override {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(isFortiFiVault[msg.sender], "FortiFi: Invalid vault");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        IVectorFortress _fortress;

        // If user has not deposited previously, deploy Fortress
        if (vaultToTokenToFortress[msg.sender][_tokenId] == address(0)) {
            FortiFiVectorFortress _fort = new FortiFiVectorFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IVectorFortress(address(_fort));
            vaultToTokenToFortress[msg.sender][_tokenId] = address(_fortress);
            emit FortressCreated(msg.sender, _tokenId, address(_strat));
        } else {
            _fortress = IVectorFortress(vaultToTokenToFortress[msg.sender][_tokenId]);
        }

        // approve and deposit
        _dToken.approve(address(_fortress), _amount);
        uint256 _receipts = _fortress.deposit(_amount, _user);

        // mint receipt tokens = to what was received from Fortress
        _mint(msg.sender, _receipts);

        // Refund left over deposit tokens, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            require(_dToken.transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        emit DepositToFortress(msg.sender, _user, address(_strat), _amount);
    }

    /// @notice Function to withdraw
    /// @dev Override is required because Vector Fortresses need slippage passed in to withdrawal function
    function withdrawFromFortress(uint256 _amount, address _user, uint256 _tokenId) external override {
        require(_amount > 0, "FortiFi: 0 withdraw");
        require(vaultToTokenToFortress[msg.sender][_tokenId] != address(0), "FortiFi: No fortress");

        // burn receipt tokens and withdraw from Fortress
        _burn(msg.sender, _amount);
        IVectorFortress(vaultToTokenToFortress[msg.sender][_tokenId]).withdrawVector(_user, slippageBps);

        uint256 _depositTokenReceived = _dToken.balanceOf(address(this));

        // transfer received deposit tokens
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");

        emit WithdrawFromFortress(msg.sender, _user, address(_strat), _depositTokenReceived);
    }

    /// @notice Function to set the slippage if 1% is not sufficient
    function setSlippage(uint16 _amount) external onlyOwner {
        slippageBps = _amount;
        emit SlippageSet(_amount);
    }

}