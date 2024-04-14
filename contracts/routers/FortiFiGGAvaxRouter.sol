// SPDX-License-Identifier: GPL-3.0-only
// FortiFiGGAvaxRouter by FortiFi

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity 0.8.21;

interface IGGAvax {
    function depositAVAX() external payable returns(uint);
    function redeemAVAX(uint) external returns(uint);
}

interface IWNative {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/// @title FortiFiGGAvaxRouter
/// @notice This contract is used as a proxy interface for Native MASS vaults that need to deposit AVAX for ggAVAX
contract FortiFiGGAvaxRouter {
    using SafeERC20 for IERC20;
    address public constant GG = 0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    constructor() {

    }

    receive() external payable { }

    function swapExactTokensForTokens(
            uint amountIn,
            uint,
            address[] calldata path,
            address,
            uint
        ) external returns (uint[] memory amounts) {
            uint256 amountOut;

            if(path[0] == GG) {
                IERC20(GG).safeTransferFrom(msg.sender, address(this), amountIn);
                amountOut = IGGAvax(GG).redeemAVAX(amountIn);
                IWNative(WAVAX).deposit{value: amountOut}();
                IERC20(WAVAX).safeTransfer(msg.sender, amountOut);
            } else if (path[0] == WAVAX) {
                IERC20(WAVAX).safeTransferFrom(msg.sender, address(this), amountIn);
                IWNative(WAVAX).withdraw(amountIn);
                amountOut = IGGAvax(GG).depositAVAX{value: amountIn}();
                IERC20(GG).safeTransfer(msg.sender, amountOut);
            } else {
                revert("Invalid Path");
            }

            uint[] memory _out = new uint[](1);
            _out[0] = amountOut;
            return _out;
        }
}