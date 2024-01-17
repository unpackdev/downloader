// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721.sol";

contract TestOperatorFilter is ERC721("TestOperatorFilter", "TEST") {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "";
    }

    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }
}
