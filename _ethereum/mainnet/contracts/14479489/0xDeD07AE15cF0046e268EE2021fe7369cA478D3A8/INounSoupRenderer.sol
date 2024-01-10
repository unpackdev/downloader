// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INounSoupRenderer {
    function generateData(uint256 tokenId_)
        external
        view
        returns (string memory svg, string memory attributes);
}