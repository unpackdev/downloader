// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract SaintSophiaCathedral is ERC721, ERC721URIStorage, Ownable {
    constructor(uint256 id, address to, string memory uri) ERC721("SSC TEST 2", "SSCTEST2") {
        _safeMint(to, id);
        _setTokenURI(id, uri);
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
