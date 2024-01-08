// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

contract ILoveYouNancyCallahan is ERC721, Ownable {
    constructor() ERC721("I Love You, Nancy Callahan", "FMSC9") {}
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return "ipfs://QmXuSNwPVAath31u9YmmmBCrFXGE2kpdCBvEZhsVY1NeiD";
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}
