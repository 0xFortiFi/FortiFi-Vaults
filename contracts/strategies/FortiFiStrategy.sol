// SPDX-License-Identifier: MIT
// FortiFiStrategy by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IFortress.sol";
import "./FortiFiFortress.sol";

pragma solidity ^0.8.18;

/// @title Base FortiFi Strategy contract
/// @notice This contract should be used when a yield strategy requires special logic beyond
/// simple deposit(amount deposit token) and withdraw(receipt tokens to burn)
contract FortiFiStrategy is Ownable, ERC20 {
    address internal immutable _strat;
    IERC20 internal immutable _dToken;
    IERC20 internal immutable _wNative;

    mapping(address => address) public userToFortress;

    constructor(address _strategy, address _depositToken, address _wrappedNative) ERC20("FortiFi Strategy Receipt", "FFSR") {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        require(_wrappedNative != address(0), "FortiFi: Invalid native token");
        _strat = _strategy;
        _dToken = IERC20(_depositToken);
        _wNative = IERC20(_wrappedNative);
    }

    receive() external payable { 
    }

    /// @notice Function to deposit
    /// @dev If a user has not deposited previously, this function will deploy a FortiFiFortress contract
    /// to interact with the underlying strategy for the user. This allows user deposits to be isolated
    /// as many strategies utilize special logic that is dependent on the balance of the address interacting
    /// with them.
    function depositToFortress(uint256 _amount, address _user) external virtual {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        IFortress _fortress;

        uint256 _beforeBalance = 0;

        // If user has not deposited previously, deploy Fortress
        if (userToFortress[_user] == address(0)) {
            FortiFiFortress _fort = new FortiFiFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IFortress(address(_fort));
            userToFortress[_user] = address(_fortress);
        } else {
            _fortress = IFortress(userToFortress[_user]);
            // set before balance since user has deposited previously
            _beforeBalance = _fortress.balanceOf(address(this));
        }

        // approve and deposit
        _dToken.approve(address(_fortress), _amount);
        _fortress.deposit(_amount);

        // mint receipt tokens = to what was received from Fortress
        _mint(msg.sender, (_fortress.balanceOf(address(this)) - _beforeBalance));

        // refund left over tokens, if any
        _refund();
    }

    /// @notice Function to withdraw
    function withdrawFromFortress(uint256 _amount, address _user) external virtual {
        require(_amount > 0, "FortiFi: 0 withdraw");
        require(userToFortress[_user] != address(0), "FortiFi: No fortress");

        // burn receipt tokens and withdraw from Fortress
        _burn(msg.sender, _amount);
        IFortress(userToFortress[_user]).withdraw(_amount);

        // transfer underlying assets and refund left over tokens, if any
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
        _refund();
    }

    /// @notice Emergency function to recover stuck tokens
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    /// @notice Emergency function to recover stuck tokens from Fortress
    function recoverFromFortress(address _fortress, address _token, uint256 _amount) external onlyOwner {
        IFortress(_fortress).recoverERC20(msg.sender, _token, _amount);
    }

    /// @notice View function to return specified wrapped native token address
    function wrappedNativeToken() external view returns(address) {
        return address(_wNative);
    }

    /// @notice View function to return specified deposit token address
    function depositToken() external view returns(address) {
        return address(_dToken);
    }

    /// @notice View function to return specified underlying strategy address
    function strategy() external view returns(address) {
        return _strat;
    }

    /// @notice Internal function to refund left over tokens from transactions
    function _refund() internal {
        // Refund left over deposit tokens, if any
        uint256 _depositTokenBalance = _dToken.balanceOf(address(this));
        if (_depositTokenBalance > 0) {
            require(_dToken.transfer(msg.sender, _depositTokenBalance), "FortiFi: Failed to refund ERC20");
        }

        // Refund left over wrapped native tokens, if any
        uint256 _wrappedNativeTokenBalance = _wNative.balanceOf(address(this));
        if (_wrappedNativeTokenBalance > 0) {
            require(_wNative.transfer(msg.sender, _wrappedNativeTokenBalance), "FortiFi: Failed to refund native");
        }

        // Refund left over native tokens, if any
        if (address(this).balance > 0) {
            (bool success, ) = payable(msg.sender).call{ value: address(this).balance }("");
		    require(success, "FortiFi: Failed to refund native");
        }
    }

}