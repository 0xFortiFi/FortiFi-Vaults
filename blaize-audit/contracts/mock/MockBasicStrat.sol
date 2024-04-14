// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/// @title A basic mock strategy contract
/// @notice You can use this contract for only the most basic simulation since this contract
/// does not keep track of deposits.
/// @dev This contract is meant to mimic Yield Yak and other strategy contracts that
/// allows for simple deposit and withdrawal. see: https://snowtrace.io/address/0xc8ceea18c2e168c6e767422c8d144c55545d23e9#code
contract MockBasicStrat is ERC20 {
    using SafeMath for uint;
    uint private constant MAX_DEPOSIT = 500_000_000;
    IERC20 depositToken;

    constructor(address _depositToken) ERC20("Mock Basic Strategy", "RECEIPT") {
        depositToken = IERC20(_depositToken);
    }

    function deposit(uint256 amount) external {
        if (amount <= MAX_DEPOSIT) {
            depositToken.transferFrom(msg.sender, address(this), amount);
            _mint(msg.sender, amount);
        } else {
            depositToken.transferFrom(msg.sender, address(this), MAX_DEPOSIT);
            _mint(msg.sender, MAX_DEPOSIT);
        }
    }

    function withdraw(uint256 amount, uint256) external {
        _burn(msg.sender, amount);
        depositToken.transfer(msg.sender, getDepositTokensForShares(amount));
    }

        function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
        depositToken.transfer(msg.sender, getDepositTokensForShares(amount));
    }

    function getDepositTokensForShares(uint256 amount) public view returns (uint256) {
        uint256 _depositBalance = depositToken.balanceOf(address(this));
        uint256 _supply = totalSupply() + amount;

        if (_supply > 0) {
            return (amount * _depositBalance) / _supply;
        }

        return 0;
    }
}
