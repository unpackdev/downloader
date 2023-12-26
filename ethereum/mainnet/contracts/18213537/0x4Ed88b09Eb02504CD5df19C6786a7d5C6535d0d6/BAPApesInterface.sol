// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface BAPApesInterface {
    function ownerOf(uint256) external view returns (address);

   function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function confirmChange(uint256 tokenId) external;
}
