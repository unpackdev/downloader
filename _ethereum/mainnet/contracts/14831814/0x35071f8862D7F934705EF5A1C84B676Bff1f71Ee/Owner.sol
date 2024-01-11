// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./Context.sol";

/**
 * @dev Contract module which provides an account that can represent the "owner"
 * of the contract.  This contract does not provide any access restrictions. This
 * is a stripped down version of OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
 *
 * The main purpose of this contract is to provide third-party marketplaces with
 * the "owner" address of the contract.  This is required in many cases for off-chain
 * management of the contract.
 *
 * This module is used through inheritance.
 */
abstract contract Owner is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
