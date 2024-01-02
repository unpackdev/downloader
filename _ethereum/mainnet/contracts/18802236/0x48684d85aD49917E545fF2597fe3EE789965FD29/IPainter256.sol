// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

interface IPainter256 {
    function art(uint256 tokenId) external view returns (string memory);
}
