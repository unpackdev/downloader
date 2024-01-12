// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArtERC721V2 {
    function getAvailableMintsForMembership(uint256 membershipId)
        external
        view
        returns (uint256);
}
