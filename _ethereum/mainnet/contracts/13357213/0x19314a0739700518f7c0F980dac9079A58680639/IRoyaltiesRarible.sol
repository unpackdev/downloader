// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

interface IRoyaltiesRarible {
    function getFeeRecipients(uint256 tokenId) external view returns (address payable[] memory);
    function getFeeBps(uint256 tokenId) external view returns (uint[] memory);
}
