// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface RaregotchiToyInterface {
    function batchMint(
        address destinationAddress,
        uint256[] calldata tokenIds
    ) external;
    function isOpen(uint256 tokenId) external view returns (bool);
}