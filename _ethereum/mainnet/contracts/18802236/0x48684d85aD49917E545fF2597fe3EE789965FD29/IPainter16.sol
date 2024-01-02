// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 .0;

interface IPainter16 {
    function art(uint16 tokenId) external view returns (string memory);
}
