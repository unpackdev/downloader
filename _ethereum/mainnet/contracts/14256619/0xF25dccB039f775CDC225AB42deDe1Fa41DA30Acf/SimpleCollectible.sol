// SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

import "ERC721.sol";

contract SimpleCollectible is ERC721 {
    uint256 public tokenCounter;
    constructor () public ERC721 ("Dogie", "DOG"){
        tokenCounter = 0;
    }

    function mint(uint256 _mintAmount) public payable{
        for (uint256 i = 0; i < _mintAmount; i++) {
            uint256 newItemId = tokenCounter;
            _safeMint(msg.sender, newItemId);
            tokenCounter = tokenCounter + 1;
        }
    }

}
