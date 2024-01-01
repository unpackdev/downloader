// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import "Errors.sol";

contract ImmutableOwner {
    address public immutable owner;

    modifier onlyOwner() {
        if (msg.sender != owner) revert Errors.NotAuthorized(msg.sender, owner);
        _;
    }

    constructor(address _owner) {
        owner = _owner;
    }
}
