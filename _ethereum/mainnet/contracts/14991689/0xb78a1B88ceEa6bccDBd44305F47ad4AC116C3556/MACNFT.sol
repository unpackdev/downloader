// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Enumerable.sol";

contract MACNFT is AccessControl, ERC721Enumerable, ERC721URIStorage {
    using Counters for Counters.Counter;
    string baseURI;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant TOKEN_ADMIN_ROLE = keccak256("TOKEN_ADMIN_ROLE");

    Counters.Counter private _tokenIdTracker;

    constructor(string memory _name, string memory _symbol, string memory baseURI_) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(TOKEN_ADMIN_ROLE, _msgSender());
        baseURI = baseURI_; // https://ipfs.io/ipfs/   Seamammon series,   MAMON
    }
    

    function mint(
        address owner, string memory metadataURI
    ) external returns (uint256){
        require(hasRole(MINTER_ROLE, _msgSender()), "Must have minter role to mint");
        _safeMint(owner, _tokenIdTracker.current());
        _setTokenURI(_tokenIdTracker.current(), metadataURI);
        _tokenIdTracker.increment();
        return _tokenIdTracker.current()-1;
    }

    function setTokenURI(
        uint256 tokenId,
        string memory newTokenURI
    ) external {
        // require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), "Must have Token Admin role to modify URIs");
        _setTokenURI(tokenId, newTokenURI);
    }

    function setBaseURI(string memory baseURI_) external {
        // require(hasRole(TOKEN_ADMIN_ROLE, _msgSender()), "Must have Token Admin role to modify URIs");
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        return super.tokenURI(tokenId);
    }

}