// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10; 

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Royalty.sol";
import "./Ownable.sol";


contract FinalTransformation is ERC721, ERC721Royalty, ERC721URIStorage, Ownable {
    constructor() ERC721("Final Transformation", "FINAL TRANSFORMATION") {}

    function mint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setTokenURI(uint256 tokenId, string memory url) public onlyOwner {
        _setTokenURI(tokenId, url);
    }

    function setRoyalties(address recipient, uint96 fraction) external onlyOwner {
        _setDefaultRoyalty(recipient, fraction);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage, ERC721Royalty) {
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