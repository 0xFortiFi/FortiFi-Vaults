// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/// @title A mock ERC20
/// @notice This contract is a very basic ERC20 implementation for testing
contract MockERC20 is ERC20 {


    constructor() ERC20("Mock ERC20", "MOCK"){
    }


    function mint(address account, uint256 amount) external {
        
        _mint(account, amount);
    }

}