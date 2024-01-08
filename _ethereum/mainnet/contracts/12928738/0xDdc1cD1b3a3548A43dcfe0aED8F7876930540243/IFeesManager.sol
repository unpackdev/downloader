// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev {IFeesManager} interface:
 */
interface IFeesManager {

    /**
     * @dev Returns 'true' if seizure of item with 'id' allowed, 'false' otherwise.
     */
    function isSeizureAllowed(uint256 id, address owner) external returns (bool);

    /**
     * @dev Returns 'true' if payment for storage was successful, 'false' otherwise.
     */
    function payStorage(uint256 id, address owner) external;
}
