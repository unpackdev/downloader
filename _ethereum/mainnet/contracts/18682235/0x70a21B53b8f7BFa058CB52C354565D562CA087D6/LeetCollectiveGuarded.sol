// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "./ILeetCollective.sol";
import "./Ownable.sol";

abstract contract LeetCollectiveGuarded is Ownable {
    ILeetCollective internal _collective;

    error Unauthorized();

    constructor(address collective) {
        _collective = ILeetCollective(collective);
    }

    function leetCollectiveAddress() public view returns (address) {
        return address(_collective);
    }

    function setLeetCollective(address collective) external serOrOwner {
        _collective = ILeetCollective(collective);
    }

    modifier serOrOwner() {
        uint16 role = _collective.roleOf(msg.sender);
        if (role != 532 && owner() != msg.sender) revert Unauthorized();
        _;
    }

    modifier onlySer() {
        uint16 role = _collective.roleOf(msg.sender);
        if (role != 532) revert Unauthorized();
        _;
    }

    modifier serOrForce() {
        uint16 role = _collective.roleOf(msg.sender);
        if (role != 532 && role != 1337) revert Unauthorized();
        _;
    }
}
