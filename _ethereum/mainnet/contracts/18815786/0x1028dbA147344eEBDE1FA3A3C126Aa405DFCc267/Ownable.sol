// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Ownable
 * @dev track owner
 */
contract Ownable {
    address internal _owner;

    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == _owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set owner's address
     */
    constructor(address owner) {
        _owner = owner;
    }
}
