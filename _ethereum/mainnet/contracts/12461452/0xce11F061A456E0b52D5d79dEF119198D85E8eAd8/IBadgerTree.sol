// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Interface for Badger Tree.
 */
interface IBadgerTree {
    /// @dev Get the number of tokens claimable for an account, given a list of tokens and latest cumulativeAmounts data
    function getClaimableFor(
        address user,
        address[] memory tokens,
        uint256[] memory cumulativeAmounts
    ) external view returns (address[] memory, uint256[] memory);

    /// @notice Claim accumulated rewards for a set of tokens at a given cycle number
    function claim(
        address[] calldata tokens,
        uint256[] calldata cumulativeAmounts,
        uint256 index,
        uint256 cycle,
        bytes32[] calldata merkleProof,
        uint256[] calldata amountsToClaim
    ) external;
}