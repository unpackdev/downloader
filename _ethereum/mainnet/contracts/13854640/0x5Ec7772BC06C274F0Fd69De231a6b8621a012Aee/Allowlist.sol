// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./IAllowlist.sol";

/**
 * @title Allowlist
 * @dev The Allowlist contract has a allowlist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Allowlist is IAllowlist, Ownable {
    mapping(address => bool) public override allowlist;
    uint256 public override remainingSeats = 2500;
    // 2022-01-15 12:00 pm UTC
    uint256 public override deadline = 1642248000;

    // ------------------
    // Public write functions
    // ------------------

    function addAddressToAllowlist(address _addr) external override {
        require(block.timestamp <= deadline, "RetroPhonesAllowlist: Allowlist already closed");
        require(remainingSeats > 0, "RetroPhonesAllowlist: Allowlist is full");
        require(!allowlist[_addr], "RetroPhonesAllowlist: Already on the list");
        remainingSeats--;
        allowlist[_addr] = true;
    }

    function removeSelfFromAllowlist() external override {
        require(allowlist[msg.sender], "RetroPhonesAllowlist: Not on the list");
        remainingSeats++;
        allowlist[msg.sender] = false;
    }

    // ------------------
    // Function for the owner
    // ------------------

    function addSeats(uint256 _seatsToAdd) external override onlyOwner {
        remainingSeats = remainingSeats + _seatsToAdd;
    }

    function reduceSeats(uint256 _seatsToSubstract) external override onlyOwner {
        remainingSeats = remainingSeats - _seatsToSubstract;
    }

    function setDeadline(uint256 _newDeadline) external override onlyOwner {
        deadline = _newDeadline;
    }

    function addAddressesToAllowlist(address[] calldata _addrs) external override onlyOwner {
        require(block.timestamp <= deadline, "RetroPhonesAllowlist: Allowlist already closed");
        require(remainingSeats >= _addrs.length, "RetroPhonesAllowlist: Allowlist is full");

        for (uint256 i = 0; i < _addrs.length; i++) {
            if (!allowlist[_addrs[i]]) {
                remainingSeats--;
                allowlist[_addrs[i]] = true;
            }
        }
    }
}
