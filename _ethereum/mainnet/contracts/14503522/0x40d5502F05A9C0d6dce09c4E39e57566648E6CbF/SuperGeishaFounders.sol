// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./PaymentSplitter.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract SuperGeishaFounders is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    PaymentSplitter,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor(address[] memory payees_, uint256[] memory shares_)
        ERC721("SuperGeishaFounders", "SGF")
        PaymentSplitter(payees_, shares_)
    {
        _tokenIdCounter.increment();
    }

    function mint(address to, string memory uri) external onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setTokenURI(uint256 _tokenId, string memory _tokenURI)
        external
        onlyOwner
    {
        _setTokenURI(_tokenId, _tokenURI);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
