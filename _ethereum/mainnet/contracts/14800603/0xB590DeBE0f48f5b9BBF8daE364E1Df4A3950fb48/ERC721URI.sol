// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

abstract contract ERC721URI is ERC721A, Ownable {
    string internal _base;

    constructor(string memory base_) {
        _base = base_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _base;
    }

    function setBaseURI(string memory base_) external onlyOwner {
        _base = base_;
    }
}
