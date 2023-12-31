// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

//@creator sinvali.eth

import "./ERC721.sol";

contract v is ERC721 {
   
        constructor() 
            ERC721("sinvali","v") {
            _mint(msg.sender);
        }

    function tokenURI(uint256 tokenId) public pure override returns (string memory) {
        require(tokenId == 1);
            bytes memory metadata = abi.encodePacked(
                'data:application/json;utf8,{"name": "v","description": "sinvali.eth"', 
                ',"image": "ipfs://QmeKRUq4fSq9GCn89rFusmHTxXnUvnwX1eqvn8M4LttMkT"}'    
            );
        return string(abi.encodePacked(metadata));
    }

}