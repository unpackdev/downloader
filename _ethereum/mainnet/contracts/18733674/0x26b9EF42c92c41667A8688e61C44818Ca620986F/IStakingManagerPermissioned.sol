// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IBaseStakingManager.sol";

/**
 * @title IStakingManagerPermissioned
 * @author pNetwork
 *
 * @notice This contract can ONLY be used togheter with LendingManager and RegistrationManager
 *         in order to keep separated the amount staked from the lending, from the sentinels registration
 *         and for voting.
 */
interface IStakingManagerPermissioned is IBaseStakingManager {
    /*
     * @notice Increase the amount at stake.
     *
     * @param owner
     * @param amount
     */
    function increaseAmount(address owner, uint256 amount) external;

    /*
     * @notice Increase the duration of a stake.
     *
     * @param owner
     * @param duration
     */
    function increaseDuration(address owner, uint64 duration) external;

    /*
     * @notice Stake an certain amount of tokens locked for a period of time in behalf of receiver.
     * in exchange of the governance token.
     *
     * @param receiver
     * @param amount
     * @param duration
     */
    function stake(address receiver, uint256 amount, uint64 duration) external;
}
