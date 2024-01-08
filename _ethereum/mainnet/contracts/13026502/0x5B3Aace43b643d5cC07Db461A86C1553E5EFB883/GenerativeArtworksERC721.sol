// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";


contract GenerativeArtworksERC721 is ERC721URIStorage, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => bool) public isAdmin;

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only admin");
        _;
    }

    function addAdmin(address _address) external onlyAdmin {
        isAdmin[_address] = true;
    }

    function removeAdmin(address _address) external onlyAdmin {
        isAdmin[_address] = false;
    }

    constructor(string memory tokenName, string memory tokenSymbol) ERC721(tokenName, tokenSymbol) {
        isAdmin[msg.sender] = true;
    }

    function mint(address receiver, string memory tokenURIData) external onlyAdmin returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _safeMint(receiver, newItemId);
        _setTokenURI(newItemId, tokenURIData);

        _tokenIds.increment();

        return newItemId;
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
