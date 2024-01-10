// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract SchoolforHumanityOnMars is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("School for Humanity-On Mars", "SfhmNFT") {
      _safeMint(msg.sender, 1);
      _setTokenURI(1, "1.json");
    }

    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://QmRGFU6GxVH7GUT6eWobtStRkGqb7tKSnZ3aQeG31NrPtp/";
    }


    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}