// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC173 standard
 */
interface ERC173 {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() view external returns (address);

    function transferOwnership(address _newOwner) external;
}
