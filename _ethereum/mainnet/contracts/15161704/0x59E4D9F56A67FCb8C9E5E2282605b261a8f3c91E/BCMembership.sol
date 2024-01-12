// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./draft-EIP712.sol";
import "./draft-ERC721Votes.sol";
import "./Counters.sol";

contract BCMembership is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    Ownable,
    ERC721Burnable,
    EIP712,
    ERC721Votes
{

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public baseUri;


    event Mint(address indexed _to, uint256 indexed _tokenId);


    constructor() ERC721("BCMembership", "BCM") EIP712("BCMembership", "1") {}


    function setBaseUri(
        string memory _baseUri
    )
        public
        onlyOwner
    {
        baseUri = _baseUri;
    }

    function _baseURI()
        internal
        view
        override
        returns (string memory)
    {
        return baseUri;
    }

    function updateTokenURI(
        uint256 tokenId,
        string memory newTokenURI
    )
        public
        onlyOwner
    {
        _setTokenURI(tokenId, newTokenURI);
    }

    function safeMint(
        address to
    )
        public
        onlyOwner
    {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);

        emit Mint(to, tokenId);
    }

    function safeMint(
        address to,
        string memory uri
    )
        public
        onlyOwner
    {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();

        _safeMint(to, tokenId);

        _setTokenURI(tokenId, uri);

        emit Mint(to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Enumerable)
    {
        require(balanceOf(to) == 0, "Only one NFT per address allowed");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function _burn(
        uint256 tokenId
    )
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}
