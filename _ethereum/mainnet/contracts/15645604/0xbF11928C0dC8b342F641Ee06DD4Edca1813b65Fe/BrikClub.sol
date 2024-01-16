// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Owned.sol";

contract BrikClub is Owned, ERC721A {
    uint256 public constant MAX_SUPPLY = 1009;
    string private baseURI;

    constructor() Owned(msg.sender) ERC721A("BrikClub1", "BRIK_CLUB1") {
        _mint(msg.sender, MAX_SUPPLY);
    }

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string calldata _URI) public onlyOwner {
        baseURI = _URI;
    }

}