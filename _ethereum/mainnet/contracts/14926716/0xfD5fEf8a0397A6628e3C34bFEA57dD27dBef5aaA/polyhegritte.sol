// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Burnable.sol";

contract Polyhegritte is ERC721, ERC721Burnable {

    using Strings for uint256;

    constructor() ERC721("Polyhegritte NFT", "PHG"){
         _safeMint(msg.sender, 1);
    }
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId),'URI query for nonexistent token');
        uint256 dow = block.timestamp / 86400 % 7;
        return string(abi.encodePacked("https://ethpods.mypinata.cloud/ipfs/QmaH3oVW8jBiuJCqRY14ssv1QnFVJz9x915s6UGEj5d2iV/",dow.toString(),".json" )); 
    }
}
