// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

interface IRoyaltiesFoundation {
    function getFees(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}
