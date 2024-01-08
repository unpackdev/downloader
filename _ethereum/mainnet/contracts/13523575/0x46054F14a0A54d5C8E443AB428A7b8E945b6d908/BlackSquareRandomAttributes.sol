// SPDX-License-Identifier: UNLICENSED
// Copyright 2021; All rights reserved
// Author: 0x99c520ed5a5e57b2128737531f5626d026ea39f20960b0e750077b9768543949
pragma solidity >=0.8.0 <0.9.0;

import "./RandomAttributes.sol";

/// @notice A concrete extension of the abstract RandomAttributes contract, used
/// for the BlackSquare token.
contract BlackSquareRandomAttributes is RandomAttributes {
    constructor(uint256 maxTokens) RandomAttributes(maxTokens) {}
    
    /// @notice Returns an ERC721 metadata attribute for the trait[_type] and
    /// value.
    /// @dev Assumes that there is already another attribute before this one in
    /// the JSON list.
    function attrForTrait(string memory trait, string memory value) override internal pure returns (bytes memory) {
        return abi.encodePacked(',{"trait_type": "', trait, '", "value": "', value, '"}');
    }

    /// @notice Returns attrForTrait("Looks Rare", @name).
    function attrFromName(string memory name) override internal pure returns (bytes memory) {
        return attrForTrait("Looks Rare", name);
    }

    /// @notice Returns the i'th tiered trait to allow for testing of exhaustive
    /// proportions (i.e. add to 100%).
    function tieredTrait(uint256 i) external view returns (RandomAttributes.TieredTrait memory) {
        return RandomAttributes._tiered[i];
    }

    /// @notice Returns the total number of tiered traits.
    function numTraits() external view returns (uint256) {
        return RandomAttributes._tiered.length;
    }
}