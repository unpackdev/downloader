// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IDreamersRenderer {
    function tokenURI(uint256 tokenId, uint8 candy)
        external
        view
        returns (string memory);
}
