// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract Owner {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    // isOwner checks whether the sender is the owner
    modifier isOwner() {
        require(owner == msg.sender, "Sender is not owner");
        _;
    }

    /// @dev setOwner sets the owner
    ///
    /// Requires the caller to be the current owner.
    ///
    /// @param owner_ is the new owner.
    function setOwner(address owner_) public isOwner() {
        owner = owner_;
    }
}
