// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./IERC721Metadata.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

/// @custom:security-contact contact@inblocks.io
contract InBlocksNFT1 is IERC721Metadata, ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    string private _metadataURI;
    string private _baseTokenURI;

    constructor(string memory name, string memory symbol, string memory metadataURI, string memory baseTokenURI)
        ERC721(name, symbol)
    {
        _metadataURI = metadataURI;
        _baseTokenURI = baseTokenURI;
    }

    // https://docs.opensea.io/docs/contract-level-metadata
    function contractURI()
        public view virtual
        returns (string memory)
    {
        return _metadataURI;
    }

    function changeMetadataURI(string memory metadataURI)
        public
        onlyOwner
    {
        _metadataURI = metadataURI;
    }

    function _baseURI()
        internal view virtual override
        returns (string memory)
    {
        return _baseTokenURI;
    }

    function changeBaseURI(string memory baseURI)
        public
        onlyOwner
    {
        _baseTokenURI = baseURI;
    }

    function safeMint(address to, uint256 tokenId)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal override(ERC721)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public view override(IERC721Metadata, ERC721)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public view override(IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
