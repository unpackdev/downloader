// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface PausableInterface {

    /**
     * @dev Returns the paused state of the contract.
     */
    function paused() external view returns (bool);

    /**
     * @dev Pauses state changing activity of the entire contract
     */
    function pause() external;

    /**
     * @dev Restores state changing activity to the entire contract
     */
    function unpause() external;

}