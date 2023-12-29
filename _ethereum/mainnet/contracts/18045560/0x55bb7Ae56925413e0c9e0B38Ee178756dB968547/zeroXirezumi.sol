// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract zeroXirezumi is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Mapping from token ID to token URI
    mapping(uint256 => string) private _customTokenURIs;

    // Base URI
    string private _baseTokenURI;

    constructor(string memory baseTokenURI) ERC721("zeroXirezumi", "ZXI") {
        _baseTokenURI = baseTokenURI;
    }

    function mintNFT(address recipient, string memory uri) public onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(recipient, newItemId);
        _setTokenURI(newItemId, uri);
        return newItemId;
    }

    function mintBatchNFT(address[] memory recipients, string[] memory uris) public onlyOwner {
        require(recipients.length == uris.length, "Mismatch between recipients and URIs");

        for (uint256 i = 0; i < recipients.length; i++) {
            mintNFT(recipients[i], uris[i]);
        }
    }

    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        _customTokenURIs[tokenId] = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(_baseTokenURI, _customTokenURIs[tokenId]));
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }
}
