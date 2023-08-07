// SPDX-License-Identifier: MIT
// FortiFiFeeManager by FortiFi

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.2;

contract FortiFiFeeManager is Ownable {

    uint16[] public splitBps;
    address[] public receivers;

    constructor(address[] memory _receivers,
                uint16[] memory _splitBps) {

        setSplit(_receivers, _splitBps);
    }

    function collectFees(address _token, uint256 _amount) external {
        IERC20 _t = IERC20(_token);
        require(_t.transferFrom(msg.sender, address(this), _amount), "FortiFi: Unable to collect fees");

        uint256 _feeBalance = _t.balanceOf(address(this));
        if (_feeBalance >= 1000) {
            uint8 _length = uint8(receivers.length);
            for (uint8 i = 0; i < _length; i++) {
                if (i == (_length - 1)) {
                    require(_t.transfer(receivers[i], _t.balanceOf(address(this))), "FortiFi: Failed to transfer last share");
                } else {
                    uint256 _share = _feeBalance * splitBps[i] / 10000;
                    require(_t.transfer(receivers[i], _share), "FortiFi: Failed to transfer share");
                }
            }
        }
    }

    function setSplit(address[] memory _receivers, uint16[] memory _splitBps) public onlyOwner {
        uint8 _length = uint8(_receivers.length);
        require (_length > 0, "FortiFi: Invalid receiver array");

        for (uint8 i = 0; i < _length; i++) {
            require(_receivers[i] != address(0), "FortiFi: Invalid receiver address");
        }

        require(_length == _splitBps.length &&
                _validateBps(_splitBps), "FortiFi: Invalid array lengths");
        
        receivers = _receivers;
        splitBps = _splitBps;
    }

    function _validateBps(uint16[] memory _bps) internal pure returns(bool) {
        uint8 _length = uint8(_bps.length);
        uint16 _totalBps = 0;
        
        for (uint256 i = 0; i < _length; i++) {
            uint16 _b = _bps[i];
            require(_b > 9, "FortiFi: Invalid bps amount");
            _totalBps += _b;
        }

        require(_totalBps == 10000, "FortiFi: Invalid total bps");

        return true;
    }

    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

}