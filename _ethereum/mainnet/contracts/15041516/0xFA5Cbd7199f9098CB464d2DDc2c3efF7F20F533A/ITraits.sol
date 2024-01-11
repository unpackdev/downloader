// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ITraits {

    function mintTraits(address receiver, uint256 traitsRefs) external;

    function burnTraits(address traitsOwner, uint256[] calldata traitTokenIds, uint256[] calldata signedTraitIds) external;
}