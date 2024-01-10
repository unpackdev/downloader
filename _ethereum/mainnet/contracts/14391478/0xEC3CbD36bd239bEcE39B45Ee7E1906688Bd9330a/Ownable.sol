// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

abstract contract Ownable {
    error AccessDenied();

    address immutable public owner;

    constructor(address newOwner) {
        owner = newOwner;
    }

    modifier onlyOwner() {
        if (address(msg.sender) != owner)
            revert AccessDenied();
        _;
    }
}
