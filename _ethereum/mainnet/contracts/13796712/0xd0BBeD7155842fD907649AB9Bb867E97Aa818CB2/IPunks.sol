// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.8;

interface IPunks {
    function getPunk(uint16 index) external view returns (bytes memory);
    function getPunkOwner(uint256 index) external view returns (address);
    function punkImageSvg(uint16 index) external view returns (bytes memory);
}
