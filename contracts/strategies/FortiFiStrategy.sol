// SPDX-License-Identifier: MIT
// FortiFiStrategy by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IFortress.sol";
import "./FortiFiFortress.sol";

pragma solidity ^0.8.2;

contract FortiFiStrategy is Ownable, ERC20 {
    address internal _strat;
    IERC20 internal _dToken;
    IERC20 internal _wNative;

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

    function depositToFortress(uint256 _amount, address _user) external virtual {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        IFortress _fortress;

        if (userToFortress[_user] == address(0)) {
            FortiFiFortress _fort = new FortiFiFortress(_strat, address(_dToken), address(_wNative), address(this));
            _fortress = IFortress(address(_fort));
            userToFortress[_user] = address(_fortress);
        } else {
            _fortress = IFortress(userToFortress[_user]);
        }

        uint256 _beforeBalance = _fortress.balanceOf(address(this));
        _dToken.approve(address(_fortress), _amount);
        _fortress.deposit(_amount);
        _mint(msg.sender, (_fortress.balanceOf(address(this)) - _beforeBalance));
        _refund();
    }

    function withdrawFromFortress(uint256 _amount, address _user) external {
        require(_amount > 0, "FortiFi: 0 withdraw");
        require(userToFortress[_user] != address(0), "FortiFi: No fortress");
        _burn(msg.sender, _amount);
        IFortress(userToFortress[_user]).withdraw(_amount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
        _refund();
    }

    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function recoverFromFortress(address _fortress, address _token, uint256 _amount) external onlyOwner {
        IFortress(_fortress).recoverERC20(msg.sender, _token, _amount);
    }

    function wrappedNativeToken() external view returns(address) {
        return address(_wNative);
    }

    function depositToken() external view returns(address) {
        return address(_dToken);
    }

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