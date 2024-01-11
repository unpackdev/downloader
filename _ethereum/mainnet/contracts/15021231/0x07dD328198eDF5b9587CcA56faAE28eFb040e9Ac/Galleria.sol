//SPDX-License-Identifier: MIT
//From One & Zeros 

pragma solidity ^ 0.8.1;

import "./console.sol";
import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Galleria is ERC721, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private currentTokenId;
    string public baseTokenURI;
    
    mapping(uint256 => string) private _tokenURIs;
    constructor(string memory tokenName, string memory symbol) ERC721(tokenName, symbol) {
        baseTokenURI = "ipfs://";
    }

    function mintToken(address owner, string memory metadataURI)
    public returns(uint256) {
        currentTokenId.increment();

        uint256 id = currentTokenId.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);
        return id;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns(string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId));
    }
    
    /// @dev Returns an URI for a given token ID
    function _baseURI() internal view virtual override returns(string memory) {
        return baseTokenURI;
    }

    /// @dev Sets the base token URI prefix.
    function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }
    
}