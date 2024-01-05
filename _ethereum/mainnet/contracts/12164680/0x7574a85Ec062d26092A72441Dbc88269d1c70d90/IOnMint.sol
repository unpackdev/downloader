// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnMint {
    function onMint(address minter, address to, uint256 tokenId, uint256 extra) external;
}