// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./ERC721A.sol";

abstract contract ERC721Capped is ERC721A {
    uint256 public supplyCap;

    constructor(uint256 supplyCap_) {
        supplyCap = supplyCap_;
    }

    function _mint(address to, uint256 quantity) internal virtual override {
        require(totalSupply() + quantity <= supplyCap, "ERC721Capped: mint overflows cap");
        super._mint(to, quantity);
    }

    function _multiMint(address[] memory to) internal virtual override {
        require(totalSupply() + to.length <= supplyCap, "ERC721Capped: mint overflows cap");
        super._multiMint(to);
    }
}
