// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev track owner
 */
contract AdminOwnable {
    address internal _owner;
    address internal _admin;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address owner) {
        _owner = owner;
    }

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    // modifier to check if caller is owner
    modifier isAdminOrOwner() {
        require(msg.sender == _owner || msg.sender == _admin, "Caller is not owner or admin");
        _;
    }

    
    /**
     * @dev Returns the address of the current owner.
     */
    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (getOwner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }

        /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual isOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
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
