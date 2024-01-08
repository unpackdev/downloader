// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import "./IEligibilityConstraint.sol";
import "./IMoonbirds.sol";
import "./MoonbirdConstraint.sol";

/**
 * @notice Eligibility if a moonbird is nested.
 */
abstract contract ANested is AMoonbirdConstraint {
    /**
     * @inheritdoc IEligibilityConstraint
     * @dev Returns true iff the moonbird is nested.
     */
    function isEligible(uint256 tokenId) public view virtual returns (bool) {
        (bool nesting,,) = _moonbirds.nestingPeriod(tokenId);
        return nesting;
    }
}

/**
 * @notice Eligibility if a moonbird is nested since a given time.
 */
abstract contract ANestedSince is AMoonbirdConstraint {
    /**
     * @notice A moonbird has to be nested since this timestamp to be eligible.
     */
    uint256 private immutable _sinceTimestamp;

    constructor(uint256 sinceTimestamp_) {
        _sinceTimestamp = sinceTimestamp_;
    }

    /**
     * @inheritdoc IEligibilityConstraint
     * @dev Returns true iff the moonbird is nested since a given time.
     */
    function isEligible(uint256 tokenId) public view virtual returns (bool) {
        (bool nested, uint256 current,) = _moonbirds.nestingPeriod(tokenId);
        //solhint-disable-next-line not-rely-on-time
        return nested && block.timestamp - current <= _sinceTimestamp;
    }
}

/**
 * @notice Eligibility if a moonbird is nested.
 */
contract Nested is ANested {
    constructor(IMoonbirds moonbirds) AMoonbirdConstraint(moonbirds) {}
}

/**
 * @notice Eligibility if a moonbird is nested since a given time.
 */
contract NestedSince is ANestedSince {
    constructor(IMoonbirds moonbirds, uint256 sinceTimestamp)
        AMoonbirdConstraint(moonbirds)
        ANestedSince(sinceTimestamp)
    {}
}
