// SPDX-License-Identifier: MIT
// Wombat LP-ggAVAX Zapper by FortiFi

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../strategies/interfaces/IStrategy.sol";
import "../vaults/interfaces/IRouter.sol";

pragma solidity 0.8.21;

interface IWombatPool {
    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}

/// @notice Error caused by trying to zap 0
error InvalidAmount();

/// @notice Error caused by ggAvaxPremium < 10000
error InvalidPremium();

/// @notice Error caused when swap fails
error SwapFailed();

/// @title LP-ggAVAX to WAVAX Zapper
/// @notice This zapper takes Wombat LP-ggAVAX YRT tokens and converts them to WAVAX
contract FortiFiWombatGGAvaxZapper is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    
    uint16 public constant BPS = 10000;
    uint16 public slippage = 0;
    uint16 public slippageBps = 25;

    address public pool = 0xBbA43749efC1bC29eA434d88ebaf8A97DC7aEB77; // Wombat Pool
    address public router = 0x30503D5edb95a817D05709961862cE74b94edD53;

    IERC20 public constant GGAVAX = IERC20(0xA25EaF2906FA1a3a13EdAc9B9657108Af7B703e3);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public lpToken = IERC20(0x2DdfdD8e1BEc473f07815FA3cFeA3Bba4D39F37E); // LP-ggAVAX
    IStrategy public strategy = IStrategy(0x13404B1C715aF60869fc658d6D99c117e3543592); // YRT

    constructor() {
        // grant approvals
        lpToken.approve(address(strategy), type(uint256).max);
        lpToken.approve(pool, type(uint256).max);
        GGAVAX.approve(pool, type(uint256).max);
        GGAVAX.approve(router, type(uint256).max);
    }

    /// @notice Function to convert YRT to WAVAX
    function zap(uint256 _amount, uint256 _ggAvaxPremium) external nonReentrant {
        if (_amount == 0) revert InvalidAmount();
        if (_ggAvaxPremium < 10000) revert InvalidPremium();
        IERC20(address(strategy)).safeTransferFrom(msg.sender, address(this), _amount);
        strategy.withdraw(_amount);

        // ensure no strategy receipt tokens remain
        uint256 _balance = strategy.balanceOf(address(this));
        if (_balance > 0) {
            IERC20(address(strategy)).safeTransfer(msg.sender, _balance);
        }

        uint256 _lpReceived = lpToken.balanceOf(address(this));

        // remove liquidity
        IWombatPool(pool).withdraw(address(GGAVAX), 
                                    _lpReceived, 
                                    (_lpReceived * (BPS - slippage) / BPS), 
                                    address(this), 
                                    block.timestamp + 1800);

        // transfer received deposit tokens and refund left over tokens, if any
        uint256 _ggAvaxBalance = GGAVAX.balanceOf(address(this));
        if (_ggAvaxBalance > 0) {
            address[] memory _route = new address[](2);
            IRouter _router = IRouter(router);

            _route[0] = address(GGAVAX);
            _route[1] = address(WAVAX);

            uint256 _swapAmount = _ggAvaxBalance * _ggAvaxPremium / BPS;

            _router.swapExactTokensForTokens(_ggAvaxBalance, 
                (_swapAmount * (BPS - slippageBps) / BPS), 
                _route, 
                address(this), 
                block.timestamp + 1800);

            uint256 _wavaxBalance = WAVAX.balanceOf(address(this));
            if (_wavaxBalance == 0) revert SwapFailed();

            WAVAX.safeTransfer(msg.sender, _wavaxBalance);

            _ggAvaxBalance = GGAVAX.balanceOf(address(this));
            if (_ggAvaxBalance > 0) {
                GGAVAX.safeTransfer(msg.sender, _ggAvaxBalance);
            }

        } else {
            revert SwapFailed();
        }

    }

    function setSlippage(uint16 _newAmount) external onlyOwner {
        slippage = _newAmount;
    }

    function setSlippageBps(uint16 _newAmount) external onlyOwner {
        slippageBps = _newAmount;
    }

    function setRouter(address _newRouter) external onlyOwner {
        router = _newRouter;
    }

}