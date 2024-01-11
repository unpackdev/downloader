// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface Voidish {
    function vanished(uint256 tokenId) external view returns (address, uint64);
    function hasBecomeSomething(uint256 tokenId) external view returns (bool);
}
