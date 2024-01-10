// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ICryptoPunksData {
    function punkImageSvg(uint16 punkId) external view returns (string memory);
    function punkAttributes(uint16 punkId) external view returns (string memory);
}
