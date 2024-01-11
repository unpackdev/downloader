//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Icollection {
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}