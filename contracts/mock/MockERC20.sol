// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";



contract MockERC20 is ERC20 {


    constructor() ERC20("Mock ERC20", "MOCK"){
    }


    function mint(address account, uint256 amount) external {
        
        _mint(account, amount);
    }

}