// SPDX-License-Identifier: GPL-3.0-only
// FortiFiUniV3Router by FortiFi

import './libraries/TransferHelper.sol';
import './interfaces/ISwapRouter.sol';

pragma solidity 0.8.21;


/// @title FortiFiUniV3Router
/// @notice This contract is used as a proxy interface for MASS vaults that need to access Uniswap V3 liquidity
contract FortiFiUniV3Router {
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

            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: path[0],
                    tokenOut: path[path.length - 1],
                    fee: poolFee,
                    recipient: to,
                    deadline: deadline,
                    amountIn: amountIn,
                    amountOutMinimum: amountOutMin,
                    sqrtPriceLimitX96: 0
                });

            // The call to `exactInputSingle` executes the swap.
            uint256 amountOut = swapRouter.exactInputSingle(params);

            uint[] memory _out = new uint[](1);
            _out[0] = amountOut;
            return _out;
        }
}