// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title IEpochsManager
 * @author pNetwork
 *
 * @notice
 */
interface IEpochsManager {
    /*
     * @notice Returns the current epoch number.
     *
     * @return uint16 representing the current epoch.
     */
    function currentEpoch() external view returns (uint16);

    /*
     * @notice Returns the epoch duration.
     *
     * @return uint256 representing the epoch duration.
     */
    function epochDuration() external view returns (uint256);

    /*
     * @notice Returns the timestamp at which the first epoch is started
     *
     * @return uint256 representing the timestamp at which the first epoch is started.
     */
    function startFirstEpochTimestamp() external view returns (uint256);
}
