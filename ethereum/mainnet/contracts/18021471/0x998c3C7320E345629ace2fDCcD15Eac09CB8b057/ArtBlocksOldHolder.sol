// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import "./IMoonbirds.sol";
import "./MoonbirdConstraint.sol";

/**
 * @notice Partial interface for the first ArtBlocks contract containing chromie
 * squiggles.
 * @dev
 * https://etherscan.io/address/0x059edd72cd353df5106d2b9cc5ab83a52287ac3a
 */
interface ArtBlocksOld {
    /**
     * @notice Returns the token IDs owned by `owner`.
     * @dev Token IDs are computed by multiplying the project ID by 1,000,000
     * and adding the sequential number within the project.
     */
    function tokensOfOwner(address) external view returns (uint256[] memory);
}

uint256 constant ARTBLOCKS_PROJECT_MULTIPLIER = 1_000_000;

/**
 * @notice Eligibility if the moonbird owner holds a token from a given
 * ArtBlocksOld project.
 */
abstract contract AArtBlocksOldHolder is AMoonbirdOwnerConstraint {
    /**
     * @notice The ArtblocksOld contract.
     */
    ArtBlocksOld internal immutable _artblocks;

    /**
     * @notice The project ID of interest.
     */
    uint256 internal immutable _projectId;

    constructor(ArtBlocksOld artblocks, uint256 projectId) {
        _artblocks = artblocks;
        _projectId = projectId;
    }

    /**
     * @inheritdoc AMoonbirdOwnerConstraint
     * @dev Returns true iff the moonbird holder also owns a token from a
     * pre-defined project within ArtblocksOld.
     */
    function isEligible(address owner)
        public
        view
        virtual
        override
        returns (bool)
    {
        uint256[] memory tokenIds = _artblocks.tokensOfOwner(owner);
        uint256 num = tokenIds.length;
        for (uint256 i = 0; i < num; ++i) {
            if (tokenIds[i] / ARTBLOCKS_PROJECT_MULTIPLIER == _projectId) {
                return true;
            }
        }
        return false;
    }
}

/**
 * @notice Eligibility if the moonbird owner holds a token from a given
 * ArtBlocksOld project.
 */
contract ArtBlocksOldHolder is AArtBlocksOldHolder {
    constructor(IMoonbirds moonbirds, ArtBlocksOld artblocks, uint256 projectId)
        AMoonbirdConstraint(moonbirds)
        AArtBlocksOldHolder(artblocks, projectId)
    {}
}
