//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Interface for MSD
 */
interface IMSD {
    function burn(address from, uint256 amount) external;
}
