// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @author jpegmint.xyz

interface IRoyaltiesCreatorCore {
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}
