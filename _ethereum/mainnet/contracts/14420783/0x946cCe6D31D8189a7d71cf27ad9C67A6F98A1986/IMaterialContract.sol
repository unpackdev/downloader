// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IMaterialContract {
    function ownerOf(uint256 tokenId) external view returns (address);
    function burn(uint256 tokenId) external;
}
