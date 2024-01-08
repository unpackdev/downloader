// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract HonoraryGopher is ERC721, Ownable {
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(uint256 => string) private tokenURIs;

    constructor() ERC721("Honorary Gopher", "HGPR") {}

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return tokenURIs[tokenId];
    }

    /**
     * @dev Mints one token for the given address, using the given metadata URI for the new token.
     */
    function mint(address to, string memory metadataURI) public onlyOwner {
        _safeMint(to, _tokenIdCounter.current());
        tokenURIs[_tokenIdCounter.current()] = metadataURI;
        _tokenIdCounter.increment();
    }
}