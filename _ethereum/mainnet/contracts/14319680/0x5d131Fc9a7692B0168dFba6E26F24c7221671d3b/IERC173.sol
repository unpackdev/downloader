// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC173 Interface
 *
 * @dev Interface of the ERC173 standard according to the EIP
 */
interface IERC173 {
    /**
     * @dev ERC173 standard events
     */

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev ERC173 standard functions
     */

    function owner() view external returns (address);

    function transferOwnership(address _newOwner) external;
}
