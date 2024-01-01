// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title AjnaRedeemer
 * @notice A contract that allows users to redeem their Ajna tokens for rewards. Pulls Ajan tokens from the Ajna Dripper contract.
 *
 * ROLES:
 * - `OPERATOR_ROLE`: Can add weekly reward snapshot merkle tree roots.
 * - `EMERGENCY_ROLE`: Can withdraw all the Ajna tokens to AjnaDripper contract in case of emergency.
 */
interface IAjnaRedeemer {
    function deploymentWeek() external returns (uint256);

    /**
     * @dev Gets the current week number since the UNIX epoch.
     *
     * The week is defined as a 7 day period starting from Thursday at 00:00:00 UTC. This means that
     * the week number changes on Thursdays, and that Thursday is always considered part of the current week.
     *
     * Effects:
     * - Calculates the current week by dividing the block timestamp by 1 week.
     *
     * @return The current week number since the UNIX epoch as a uint256 value.
     */
    function getCurrentWeek() external view returns (uint256);

    /**
     * @dev Adds a Merkle root for a given week.
     *
     * Requirements:
     * - The caller must have the OPERATOR_ROLE.
     * - The provided week number must be greater than or equal to the deployment week.
     * - The provided week number must not be greater than the current week number.
     * - The provided week must not already have a root set.
     * - The drip call from the Ajna Dripper contract must succeed.
     *
     * Effects:
     * - Sets the provided Merkle root for the given week.
     *
     * @param week The week number for which to add the Merkle root.
     * @param root The Merkle root to be added for the specified week.
     */
    function addRoot(uint256 week, bytes32 root) external;

    /**
     * @dev Retrieves the Merkle root for a given week.
     *
     * Requirements:
     * - The provided week must have a root set.
     *
     * Effects:
     * - None.
     *
     * @param week The week number for which to retrieve the Merkle root.
     * @return The Merkle root associated with the specified week.
     *
     * @notice returns bytes32(0) if the provided week does not have a root set.
     */
    function getRoot(uint256 week) external view returns (bytes32);

    /**
     * @dev Claims multiple rewards using Merkle proofs.
     *
     * Requirements:
     * - The number of weeks, amounts, and proofs given must all match.
     * - The caller must not have already claimed any of the specified weeks' rewards.
     * - The provided proofs must be valid and eligible to claim a reward for their corresponding weeks and amounts.
     *
     * Effects:
     * - Rewards will be transferred to the caller's account if the claims are successful.
     * - Logs an event with the details of each successful claim.
     *
     * @param _weeks An array of week numbers for which to claim rewards.
     * @param amounts An array of reward amounts to claim.
     * @param proofs An array of Merkle proofs, one for each corresponding week and amount given.
     *
     * @notice This function throws an exception if the provided parameters are invalid or the caller has already claimed rewards for one or more of the specified weeks. Additionally, it transfers rewards to the caller if all claims are successful.
     */
    function claimMultiple(
        uint256[] calldata _weeks,
        uint256[] calldata amounts,
        bytes32[][] calldata proofs
    ) external;

    /**
     * @dev Determines if the caller is eligible to claim a reward for a specified week and amount using a Merkle proof.
     *
     * Requirements:
     * - The provided Merkle proof must be valid for the given week and amount.
     *
     * @param proof A Merkle proof, which should be generated from the root of the Merkle tree for the corresponding week.
     * @param week The number of the week for which to check eligibility.
     * @param amount The amount of rewards to claim.
     *
     * @return A boolean indicating whether or not the caller is eligible to claim rewards for the given week and amount using the provided Merkle proof.
     *
     * @notice This function does not modify any state.
     */
    function canClaim(
        bytes32[] memory proof,
        uint256 week,
        uint256 amount
    ) external view returns (bool);

    /**
     * @dev Allows a user with the EMERGENCY_ROLE to withdraw all AjnaToken tokens held by this contract.
     *
     * Requirements:
     * - The caller must have the EMERGENCY_ROLE.
     * - The contract must hold a non-zero balance of AjnaToken tokens.
     *
     * Effects:
     * - Transfers the entire balance of AjnaToken tokens held by this contract to the designated "drip" address.
     *
     * @notice This function should only be used in emergency situations and may result in significant loss of funds if used improperly.
     */

    function emergencyWithdraw() external;
}
