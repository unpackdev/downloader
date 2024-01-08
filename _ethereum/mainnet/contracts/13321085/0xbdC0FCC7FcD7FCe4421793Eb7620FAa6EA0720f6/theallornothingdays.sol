// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";

contract TheAllOrNothingDays is ERC721, Ownable {
    constructor() ERC721("The All or Nothing Days", "FMSC1") {}
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        return "ipfs://QmfHKLLYyYrCskvEEQRNVqo4m48syZweo17iNWhkiZoNBe";
    }

    function safeMint(address to, uint256 tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }
}
