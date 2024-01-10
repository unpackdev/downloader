// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Whitelist is Ownable {

    mapping(address => bool) public whitelist;

    function addAddressToWhitelist(address addr) onlyOwner public{
        if (!whitelist[addr]) {
            whitelist[addr] = true;
        }
    }

    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }

    function removeAddressFromWhitelist(address addr) onlyOwner public {
        if (whitelist[addr]) {
            whitelist[addr] = false;
        }
    }

    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            removeAddressFromWhitelist(addrs[i]);
        }
    }
}
