// SPDX-License-Identifier: GPL-3.0-only
// FortiFiFeeManager by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../fee-managers/interfaces/IFortiFiFeeManager.sol";

pragma solidity ^0.8.18;

/// @title Contract to distribute fees for FortiFi Vaults
/// @notice This contract is used by FortiFi Vaults to distribute fees earned upon withdrawal.
/// @dev Fees will only be disbursed when the contract holds at least 1000 wei of the token being 
/// disbursed. This way the contract does not fail when splitting the amount amongst multiple receivers.
contract FortiFiFeeManager is IFortiFiFeeManager, Ownable {

    uint16 public constant BPS = 10_000;
    uint16[] public splitBps;
    address[] public receivers;

    constructor(address[] memory _receivers,
                uint16[] memory _splitBps) {

        setSplit(_receivers, _splitBps);
    }

    event FeesCollected(uint256 amount, address[] receivers, uint16[] split);
    event FeesChanged(address[] receivers, uint16[] split);

    /// @notice Function to collect fees from payer
    function collectFees(address _token, uint256 _amount) external override {
        IERC20 _t = IERC20(_token);
        require(_t.transferFrom(msg.sender, address(this), _amount), "FortiFi: Unable to collect fees");

        uint256 _feeBalance = _t.balanceOf(address(this));
        if (_feeBalance >= 1000) {
            uint256 _length = receivers.length;
            for (uint256 i = 0; i < _length; i++) {
                if (i == (_length - 1)) {
                    require(_t.transfer(receivers[i], _t.balanceOf(address(this))), "FortiFi: Failed to transfer last share");
                } else {
                    uint256 _share = _feeBalance * splitBps[i] / BPS;
                    require(_t.transfer(receivers[i], _share), "FortiFi: Failed to transfer share");
                }
            }
        }

        emit FeesCollected(_amount, receivers, splitBps);
    }

    /// @notice Function to set new receivers
    /// @dev This function replaces the current receivers and splitBps. Total bps must equal 10_000
    function setSplit(address[] memory _receivers, uint16[] memory _splitBps) public onlyOwner {
        uint256 _length = _receivers.length;
        require (_length > 0, "FortiFi: Invalid receiver array");

        for (uint256 i = 0; i < _length; i++) {
            require(_receivers[i] != address(0), "FortiFi: Invalid receiver address");
        }

        require(_length == _splitBps.length &&
                _validateBps(_splitBps), "FortiFi: Invalid array lengths");
        
        receivers = _receivers;
        splitBps = _splitBps;

        emit FeesChanged(receivers, splitBps);
    }

    /// @notice Validate that total bps in aray equals 10_000
    function _validateBps(uint16[] memory _bps) internal pure returns(bool) {
        uint256 _length = _bps.length;
        uint16 _totalBps = 0;
        
        for (uint256 i = 0; i < _length; i++) {
            uint16 _b = _bps[i];
            require(_b > 9, "FortiFi: Invalid bps amount");
            _totalBps += _b;
        }

        require(_totalBps == BPS, "FortiFi: Invalid total bps");

        return true;
    }

    /// @notice Emergency function to recover stuck ERC20 tokens
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

}