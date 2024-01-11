// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "ERC721.sol";
import "Ownable.sol";

contract HallMH is ERC721, Ownable {
    mapping(uint256 => string) internal tokenURIs;
    mapping(uint256 => bool) internal isLockedURIs;

    constructor(string memory name_, string memory symbol_) payable ERC721(name_, symbol_) { }

    modifier notCreated(uint256 tokenId) {
        require(bytes(tokenURIs[tokenId]).length == 0, "Existent token");
        _;
    }

    modifier created(uint256 tokenId) {
        require(bytes(tokenURIs[tokenId]).length > 0, "Nonexistent token");
        _;
    }

    modifier notLockedURI(uint256 tokenId) {
        require(!isLockedURIs[tokenId], "URI change has been locked");
        _;
    }

    function tokenURI(uint256 tokenId) public view override created(tokenId) returns (string memory) {
        return tokenURIs[tokenId];
    }

    function create(uint256 tokenId, string memory tokenURI) external onlyOwner notCreated(tokenId) {
        tokenURIs[tokenId] = tokenURI;
    }

    function changeURI(uint256 tokenId, string memory tokenURI) external onlyOwner created(tokenId) notLockedURI(tokenId) {
        require(bytes(tokenURI).length > 0, "Cannot remove URI");
        tokenURIs[tokenId] = tokenURI;
    }

    function lockURI(uint256 tokenId) external onlyOwner created(tokenId) {
        isLockedURIs[tokenId] = true;
    }

    function safeMint(address to, uint256 tokenId, bytes memory _data) external onlyOwner created(tokenId) {
        _safeMint(to, tokenId, _data);
    }

    function safeCreateAndMint(address to, uint256 tokenId, string memory tokenURI, bytes memory _data) external onlyOwner notCreated(tokenId) {
        tokenURIs[tokenId] = tokenURI;
        _safeMint(to, tokenId, _data);
    }
}
