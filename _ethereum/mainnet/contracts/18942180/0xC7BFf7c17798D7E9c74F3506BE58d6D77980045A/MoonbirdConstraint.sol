// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import "./IEligibilityConstraint.sol";
import "./IMoonbirds.sol";

/**
 * @notice Eligibility based on moonbird properties.
 */
abstract contract AMoonbirdConstraint is IEligibilityConstraint {
    /**
     * @notice The moonbird token.
     */
    IMoonbirds internal immutable _moonbirds;

    constructor(IMoonbirds moonbirds) {
        _moonbirds = moonbirds;
    }
}

/**
 * @notice Eligibility based on moonbird owner properties.
 */
abstract contract AMoonbirdOwnerConstraint is AMoonbirdConstraint {
    /**
     * @inheritdoc IEligibilityConstraint
     * @dev Returns true iff the holder of the given moonbird is eligible.
     */
    function isEligible(uint256 tokenId) public view virtual returns (bool) {
        return isEligible(_moonbirds.ownerOf(tokenId));
    }

    /**
     * @notice Returns true iff a given moonbird owner is eligible.
     * @dev Intended to be implemented by derived contracts.
     */
    function isEligible(address owner) public view virtual returns (bool);
}
