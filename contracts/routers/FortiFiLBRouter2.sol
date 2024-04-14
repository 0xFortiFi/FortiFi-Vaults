// SPDX-License-Identifier: GPL-3.0-only
// FortiFiLBRouter2 by FortiFi

import './libraries/TransferHelper.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity 0.8.21;

interface ILBRouter {
    enum Version {
        V1,
        V2,
        V2_1,
        V2_2,
        V3 // doesn't exist, but may help future-proof this router
    }

    /**
     * @dev The path parameters, such as:
     * - pairBinSteps: The list of bin steps of the pairs to go through
     * - versions: The list of versions of the pairs to go through
     * - tokenPath: The list of tokens in the path to go through
     */
    struct Path {
        uint256[] pairBinSteps;
        Version[] versions;
        IERC20[] tokenPath;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Path memory path,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);
}

/// @title FortiFiLBRouter2
/// @notice This contract is used as a proxy interface for MASS vaults that need to access Trader Joe LB Liquidity
/// @dev Because you must specify bin steps, you will likely need a router for each pair you want to use.
/// This version of the LBRouter has a backup failsafe for pairs that do not have a v1 LP
contract FortiFiLBRouter2 is Ownable {
    ILBRouter public lb;
    ILBRouter.Version public version = ILBRouter.Version.V2_1;
    uint256 public binSteps;
    bool public directV1;

    constructor(address _router, uint256 _binSteps) {
        lb = ILBRouter(_router);
        binSteps = _binSteps;
    }

    /// @notice Function to execute swap on Liquidity Book using traditional UniV2 swap parameters
    /// @dev In a case where the Liquidity Book pool no longer has sufficient liquidity, the router can be made
    /// to execute the swap via Trader Joe V1 pools by setting the version to V1 (0). By default this will 
    /// use WAVAX as an intermediary step in the swap, but if a direct pool exists you can set directV1 to true and 
    /// set binSteps to 0
    function swapExactTokensForTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline
        ) external returns (uint[] memory amounts) {
            TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), amountIn);

            // Approve the router
            TransferHelper.safeApprove(path[0], address(lb), amountIn);

            uint256 amountOut;

            if (version != ILBRouter.Version.V1 || directV1) {
                IERC20[] memory tokenPath = new IERC20[](2);
                tokenPath[0] = IERC20(path[0]);
                tokenPath[1] = IERC20(path[1]);

                uint256[] memory pairBinSteps = new uint256[](1);
                pairBinSteps[0] = binSteps;

                ILBRouter.Version[] memory versions = new ILBRouter.Version[](1);
                versions[0] = version; // add the version of the Dex to perform the swap on

                ILBRouter.Path memory route; // instanciate and populate the path to perform the swap.
                route.pairBinSteps = pairBinSteps;
                route.versions = versions;
                route.tokenPath = tokenPath;

                amountOut = lb.swapExactTokensForTokens(amountIn, amountOutMin, route, to, deadline);
            } else {
                IERC20[] memory tokenPath = new IERC20[](3);
                tokenPath[0] = IERC20(path[0]);
                tokenPath[1] = IERC20(path[1]);
                tokenPath[2] = IERC20(path[2]);

                uint256[] memory pairBinSteps = new uint256[](2);
                pairBinSteps[0] = 0;
                pairBinSteps[1] = 0;

                ILBRouter.Version[] memory versions = new ILBRouter.Version[](2);
                versions[0] = version; // add the version of the Dex to perform the swap on
                versions[1] = version;

                ILBRouter.Path memory route; // instanciate and populate the path to perform the swap.
                route.pairBinSteps = pairBinSteps;
                route.versions = versions;
                route.tokenPath = tokenPath;

                amountOut = lb.swapExactTokensForTokens(amountIn, amountOutMin, route, to, deadline);
            }
            
            uint[] memory _out = new uint[](1);
            _out[0] = amountOut;
            return _out;
        }

        /// @notice set Liquidity Book version
        function setVersion(uint _version) external onlyOwner {
            version = ILBRouter.Version(_version);
        }

        /// @notice set Bin Steps for pair
        function setBinSteps(uint256 _binSteps) external onlyOwner {
            binSteps = _binSteps;
        }

        /// @notice set Liquidity Book Router contract
        function setLB(address _lb) external onlyOwner {
            lb = ILBRouter(_lb);
        }

        /// @notice flip the boolean state of directV1 variable
        /// @dev Use this only if there is a direct asset/asset V1 pool 
        function flipDirectV1() external onlyOwner {
            directV1 = !directV1;
        }
}