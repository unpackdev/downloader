// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint256 constant ARTBLOCKS_ENGINE_PROJECT_MULTIPLIER = 1_000_000;

/**
 * @notice Converts an Artblocks projectId + editionId (i.e. the ID of the token within the given project) to a tokenId.
 */
function artblocksTokenID(uint256 projectId, uint256 editionId) pure returns (uint256) {
    return (projectId * ARTBLOCKS_ENGINE_PROJECT_MULTIPLIER) + editionId;
}
