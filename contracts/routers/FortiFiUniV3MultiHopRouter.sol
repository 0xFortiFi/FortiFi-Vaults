// SPDX-License-Identifier: GPL-3.0-only
// FortiFiUniV3MultiHopRouter by FortiFi

import './libraries/TransferHelper.sol';
import './interfaces/ISwapRouter.sol';

pragma solidity 0.8.21;


/// @title FortiFiUniV3MultiHopRouter
/// @notice This contract is used as a proxy interface for MASS vaults that need to access Uniswap V3 liquidity
contract FortiFiUniV3MultiHopRouter {
    ISwapRouter public immutable swapRouter;

    uint24 public immutable poolFee;

    constructor(address _router, uint24 _fee) {
        swapRouter = ISwapRouter(_router);
        poolFee = _fee;
    }

    function swapExactTokensForTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts) {
            TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

            TransferHelper.safeApprove(path[0], address(swapRouter), amountIn);

            ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(path[0], poolFee, path[1], poolFee, path[2]),
                recipient: to,
                deadline: deadline,
                amountIn: amountIn,
                amountOutMinimum: amountOutMin
            });

            uint256 amountOut = swapRouter.exactInput(params);

            uint[] memory _out = new uint[](1);
            _out[0] = amountOut;
            return _out;
        }
}