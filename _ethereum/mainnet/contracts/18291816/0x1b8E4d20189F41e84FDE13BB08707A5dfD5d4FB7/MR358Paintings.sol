// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./IERC4906.sol";
import "./Ownable.sol";

contract MR358Paintings is ERC721, Ownable, IERC4906 {
    constructor(
        string memory baseTokenURI_,
        string memory name_,
        string memory symbol_,
        uint startTokenId_,
        uint tokenCount_
    ) ERC721(name_, symbol_) {
        baseTokenURI = baseTokenURI_;
        startTokenId = startTokenId_;
        tokenCount = tokenCount_;
        for (uint i = startTokenId_; i <= (tokenCount_ + startTokenId_ - 1); ++i) {
            _safeMint(_msgSender(), i);
        }
    }

    string public baseTokenURI;
    uint public startTokenId;
    uint public tokenCount;

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata _baseTokenURI) external onlyOwner {
        baseTokenURI = _baseTokenURI;
        emit BatchMetadataUpdate(startTokenId, tokenCount);
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }
}