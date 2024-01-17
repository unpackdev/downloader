// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ERC721.sol";

contract TestOperatorFilter is ERC721("TestOperatorFilter", "TEST") {
    error OperatorNotAllowed();

    modifier onlyAllowedOperator(address addr) virtual {
        if (
            addr == 0x00000000000111AbE46ff893f3B2fdF1F759a8A8 ||
            addr == 0xF849de01B080aDC3A814FaBE1E2087475cF2E354 ||
            addr == 0x59728544B08AB483533076417FbBB2fD0B17CE3a ||
            addr == 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329
        ) {
            revert OperatorNotAllowed();
        }
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(msg.sender) {
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
