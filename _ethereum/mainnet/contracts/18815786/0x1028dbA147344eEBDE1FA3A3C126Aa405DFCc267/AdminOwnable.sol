// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev track owner
 */
contract AdminOwnable {
    address internal _owner;
    address internal _admin;

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
     * @dev Set owner's address
     */
    constructor(address owner) {
        _owner = owner;
    }
}
