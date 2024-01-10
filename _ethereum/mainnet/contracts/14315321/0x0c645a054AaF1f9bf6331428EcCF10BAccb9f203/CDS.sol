    // SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";

contract CryptoDinnerSeries is ERC721, ERC721URIStorage, Ownable {
    constructor() ERC721("Crypto Dinner Series", "CDS") {}

    function mint(address to, uint256 initTokenId, string[] memory _tokenURIs)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            _safeMint(to, initTokenId + i);
            _setTokenURI(initTokenId + i, _tokenURIs[i]);
        }
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory url) public onlyOwner {
        _setTokenURI(tokenId, url);
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

    