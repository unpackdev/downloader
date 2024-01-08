// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import "./IEligibilityConstraint.sol";
import "./IMoonbirds.sol";
import "./IERC1155.sol";
import "./Nested.sol";
import "./MoonbirdConstraint.sol";

/**
 * @notice Eligibility if the moonbird owner holds a specific kind of ERC1155
 * token.
 */
abstract contract ASpecificERC1155Holder is AMoonbirdOwnerConstraint {
    /**
     * @notice The collection of interest.
     */
    IERC1155 private immutable _token;

    /**
     * @notice The ERC1155 token-type (i.e. id) of interest within the
     * collection.
     */
    uint256 private immutable _id;

    constructor(IERC1155 token, uint256 id) {
        _token = token;
        _id = id;
    }

    /**
     * @inheritdoc AMoonbirdOwnerConstraint
     * @dev Returns true iff the moonbird holder also owns a token from a
     * pre-defined collection.
     */
    function isEligible(address owner)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _token.balanceOf(owner, _id) > 0;
    }
}

/**
 * @notice Eligibility if the moonbird is nested and the owner holds a specific
 * kind of ERC1155 token.
 */
abstract contract ANestedSpecificERC1155Holder is
    ANested,
    ASpecificERC1155Holder
{
    /**
     * @inheritdoc IEligibilityConstraint
     * @dev Returns true iff the moonbird is nested and its holder also owns a
     * token from a pre-defined collection.
     */
    function isEligible(uint256 tokenId)
        public
        view
        virtual
        override(ANested, AMoonbirdOwnerConstraint)
        returns (bool)
    {
        return ANested.isEligible(tokenId)
            && AMoonbirdOwnerConstraint.isEligible(tokenId);
    }
}

/**
 * @notice Eligibility if the moonbird owner holds a token from another ERC721
 * collection.
 */
contract SpecificERC1155Holder is ASpecificERC1155Holder {
    constructor(IMoonbirds moonbirds, IERC1155 token, uint256 id)
        AMoonbirdConstraint(moonbirds)
        ASpecificERC1155Holder(token, id)
    {}
}

/**
 * @notice Eligibility if the moonbird is nested and the owner holds a specific
 * kind of ERC1155 token.
 */
contract NestedSpecificERC1155Holder is ANestedSpecificERC1155Holder {
    constructor(IMoonbirds moonbirds, IERC1155 token, uint256 id)
        AMoonbirdConstraint(moonbirds)
        ASpecificERC1155Holder(token, id)
    {} //solhint-disable-line no-empty-blocks
}
