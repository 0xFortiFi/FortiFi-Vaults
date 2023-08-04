// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";



contract MockERC721 is ERC721 {
    uint256 public totalSupply = 0;

    constructor() ERC721("Mock ERC721", "NFT"){
    }


    function mint(address account, uint256 amount) external {
        for (uint256 i = 0; i < amount; i++) {
            totalSupply += 1;
            _mint(account, totalSupply);
        }
    }

}