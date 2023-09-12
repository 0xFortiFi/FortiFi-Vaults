// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/// @title A mock ERC721
/// @notice This contract is a very basic ERC721 implementation for testing
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