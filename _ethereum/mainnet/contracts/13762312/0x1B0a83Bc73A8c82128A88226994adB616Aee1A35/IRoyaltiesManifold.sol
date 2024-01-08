// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @author jpegmint.xyz

interface IRoyaltiesManifold {
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}
