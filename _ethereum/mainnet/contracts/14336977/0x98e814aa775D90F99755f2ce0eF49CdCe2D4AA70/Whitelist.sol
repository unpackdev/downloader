//"SPDX-License-Identifier: <SPDX-License>"

pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    mapping(address => bool) public rafflelist;

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender] || rafflelist[msg.sender]);
        _;
    }

    function addAddressToWhitelist(address addr) onlyOwner public {
            whitelist[addr] = true;
    }

    function addAddressToRafflelist(address addr) onlyOwner public {
        rafflelist[addr] = true;
    }

    function addAddressesToWhitelist(address[] calldata addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }

    function addAddressesToRafflelist(address[] calldata addrs) onlyOwner public {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddressToRafflelist(addrs[i]);
        }
    }
}