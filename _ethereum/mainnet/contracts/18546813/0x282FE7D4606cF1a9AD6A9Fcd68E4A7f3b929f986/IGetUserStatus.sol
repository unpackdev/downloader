// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGetUserStatus {
    /**
     * @dev Returns true if the user is blocked.
     * @param user address of the user
     * @return true if the user is blocked, false otherwise
     */
    function isUserBlocked(address user) external view returns (bool);

    /**
     * @dev Returns true if the user is blocked.
     * @param users array of addresses of the users
     * @return array of booleans, true if the user is blocked, false otherwise
     */
    function batchIsUserBlocked(address[] calldata users) external view returns (bool[] memory);
}
