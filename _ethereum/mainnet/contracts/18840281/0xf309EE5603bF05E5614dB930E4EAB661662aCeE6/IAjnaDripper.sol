// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./IAjnaRedeemer.sol";

/**
 * @title AjnaDripper
 * @notice A contract that drips a fixed amount of Ajna tokens to a designated AjnaRedeemer contract every week.
 * @dev Contract drips a specified amount of Ajna tokens defined by an offchain distribition schedule ( and it's limited by +-10% changes)
 * AjnaDripper is designed to be the only instance that will hold bulk of Ajna tokens. In case of emergency, the AjnaRedeemer contract can be
 * changed by the multisig to a new contract that will enable continuity of the rewards distribution.
 * ROLES:
 * - `DEFAULT_ADMIN_ROLE`: Can change the weekly drip amount, the designated AjnaRedeemer contract, \
 * and call the emergencyWithdraw function to transfer the Ajna tokens to the beneficiary address (trusted summer.fi address).
 * - `REDEEMER_ROLE`: Can call the drip function to transfer the weekly drip amount to the designated AjnaRedeemer contract (redeemer).
 */
interface IAjnaDripper {
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
     * @dev Changes the weekly drip amount, subject to admin access control.
     *
     * Requirements:
     * - The caller must have the DEFAULT_ADMIN_ROLE.
     * - The proposed weekly drip amount must be greater than 0, but less than MAX_WEEKLY_AMOUNT and 110% of the current weeklyAmount.
     * - The last update timestamp must be more than 4 weeks prior to the current block timestamp.
     *
     * Effects:
     * - Sets the weeklyAmount property to the newly specified drip amount.
     * - Sets the lastUpdate timestamp to the current block timestamp.
     *
     * @param _weeklyAmount The new value for the weekly drip amount.
     *
     * @notice This function throws an exception if the caller does not have the DEFAULT_ADMIN_ROLE, if the proposed weekly drip amount falls outside the allowed range, or if the lastUpdate timestamp is less than 4 weeks prior to the current block timestamp. Additionally, this function updates the weeklyAmount and lastUpdate properties as necessary.
     */
    function changeWeeklyAmount(uint256 _weeklyAmount) external;

    /**
     * @dev Changes the designated Ajna redeemer and weekly drip amount, subject to admin access control.
     *
     * Requirements:
     * - The caller must have the DEFAULT_ADMIN_ROLE.
     * - The proposed weekly drip amount must be within the allowable bounds.
     *
     * Effects:
     * - Revokes the Redemeer role from the current redeemer address.
     * - Grants the Redeemer role to the newly specified _redeemer contract address.
     * - Sets the weeklyAmount property to the newly specified drip amount.
     * - Sets the lastUpdate timestamp to the current block timestamp.
     * - Assigns the provided _redeemer address to the redeemer property.
     *
     * @param _redeemer The address of the contract that will be assigned the new REDEEMER_ROLE.
     *
     * @notice This function throws an exception if the caller does not have the DEFAULT_ADMIN_ROLE, or if the proposed weekly drip amount falls outside the allowed range. Additionally, this function revokes and grants the Redeemer role as necessary, and updates the weeklyAmount and lastUpdate properties.
     */
    function changeRedeemer(IAjnaRedeemer _redeemer) external;

    /**
     * @dev Initializes the designated AjnaRedeemer contract address and weekly drip amount.
     *
     * Requirements:
     * - Only the DEFAULT_ADMIN_ROLE can call this function.
     * - The new AjnaRedeemer contract address must not be zero.
     * - The current AjnaRedeemer contract address must not be set.
     * - The weeklyAmount property must not be set.
     * @dev Validates that the proposed weekly drip amount is within the allowable bounds.
     * Effects:
     * - Grants the REDEEMER_ROLE to the specified _redeemer contract address.
     * - Emits a RedeemerChanged event with the current week number, the zero address, and the new AjnaRedeemer contract address.
     *
     * @param _redeemer The address of the contract that will be assigned the REDEEMER_ROLE.
     * @param _weeklyAmount The value for the weekly drip amount.
     */
    function setup(IAjnaRedeemer _redeemer, uint256 _weeklyAmount) external;

    /**
     * @dev Allows the contract with 'REDEEMER_ROLE' to transfer a weekly amount of tokens to the designated 'redeemer' address.
     * @param week The week number for which to initiate the drip.
     * @return status A boolean indicating whether the token transfer was successful or not.
     *
     * Requirements:
     * - Only the user with 'REDEEMER_ROLE' can call this function.
     * - The weekly drip should not have already taken place for the given week.
     * - The requested week should not be earlier than the deployment week of the dripper contract and not later than the current week.
     *
     * Effects:
     * - Marks the given week as dripped in the 'weeklyDrip' mapping.
     * - Transfers the weekly amount of AJNA tokens to the 'redeemer' address.
     * - Emits a 'Dripped' event with the information about the week and the amount dripped.
     */

    function drip(uint256 week) external returns (bool status);

    /**
     * @dev Allows the default admin role to withdraw emergency funds.
     * @param amount The amount of tokens to withdraw from the contract.
     *
     * Requirements:
     * - Only the user with the default admin role can call this function.
     * - The contract should have a balance equal to or greater than the requested withdrawal amount.
     *
     * Effects:
     * - Transfers the requested amount of AJNA tokens to the designated beneficiary address.
     * - Emits a 'Transfer' event with the information about the amount and the sender address.
     * - Throws an error if any of the requirements are not met.
     */
    function emergencyWithdraw(uint256 amount) external;
}
