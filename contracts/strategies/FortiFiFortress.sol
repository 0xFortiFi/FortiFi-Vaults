// SPDX-License-Identifier: MIT
// FortiFiFortress by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IStrategy.sol";

pragma solidity ^0.8.2;

contract FortiFiFortress is Ownable, ERC20 {
    IStrategy private _strat;
    IERC20 private _dToken;
    IERC20 private _wNative;

    constructor(address _strategy, address _depositToken, address _wrappedNative, address _owner) ERC20("FortiFi Fortress Receipt", "FFFR") {
        require(_strategy != address(0), "FortiFi: Invalid strategy");
        require(_depositToken != address(0), "FortiFi: Invalid deposit token");
        require(_wrappedNative != address(0), "FortiFi: Invalid native token");
        require(_owner != address(0), "FortiFi: Invalid owner");
        _strat = IStrategy(_strategy);
        _dToken = IERC20(_depositToken);
        _wNative = IERC20(_wrappedNative);

        // grant approvals
        _dToken.approve(_strategy, type(uint256).max);

        _transferOwnership(_owner);
    }

    receive() external payable { 
    }

    function deposit(uint256 _amount) external virtual onlyOwner {
        require(_amount > 0, "FortiFi: 0 deposit");
        require(_dToken.transferFrom(msg.sender, address(this), _amount), "FortiFi: Failed to transfer dep.");
        uint256 _beforeBalance = _strat.balanceOf(address(this));
        _strat.deposit(_amount);
        _mint(msg.sender, (_strat.balanceOf(address(this)) - _beforeBalance));
        _refund();
    }

    function withdraw(uint256 _amount) external virtual onlyOwner {
        require(_amount > 0, "FortiFi: 0 withdraw");
        _burn(msg.sender, _amount);
        _strat.withdraw(_amount);
        require(_dToken.transfer(msg.sender, _dToken.balanceOf(address(this))), "FortiFi: Failed to transfer dep.");
        _refund();
    }

    function refreshApproval() external {
        _dToken.approve(address(_strat), type(uint256).max);
    }

    function depositToken() external view returns(address) {
        return address(_dToken);
    }

    function strategy() external view returns(address) {
        return address(_strat);
    }

    function recoverERC20(address _to, address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
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