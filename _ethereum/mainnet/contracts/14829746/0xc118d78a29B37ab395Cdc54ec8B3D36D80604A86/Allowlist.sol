// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AdminPrivileges.sol";

/**
* @dev Adds allowlist functionality to a contract.
*
* Allowlist is tracked with a mapping which pairs an
* address to a uint - this provides versatile
* functionality to your base contract.
*
* If your allowlist is binary (e.g. an address is
* either allowed or not), simply check if the
* paired uint for the address is greater than 0.
* Alternatively, track how many allowlist places
* each address is entitled to with the uint.
*
* Use the {requireAllowlist} modifier to prevent
* a function from being run if the caller does
* not have at least 1 allowlist place.
*
* See more module contracts from Sibling Labs at
* https://github.com/NFTSiblings/Modules
*/
contract Allowlist is AdminPrivileges {
    mapping(address => uint) public allowlist;

    /**
    * @dev Adds one to the number of allowlist places
    * for each provided address.
    */
    function addToAllowlist(address[] calldata _addr) public onlyAdmins {
        for (uint i; i < _addr.length; i++) {
            allowlist[_addr[i]]++;
        }
    }

    /**
    * @dev Sets the number of allowlist places for
    * given addresses.
    */
    function setAllowlist(address[] calldata _addr, uint amount) public onlyAdmins {
        for (uint i; i < _addr.length; i++) {
            allowlist[_addr[i]] = amount;
        }
    }

    /**
    * @dev Removes all allowlist places for given
    * addresses - they will no longer be allowed.
    */
    function removeFromAllowList(address[] calldata _addr) public onlyAdmins {
        for (uint i; i < _addr.length; i++) {
            allowlist[_addr[i]] = 0;
        }
    }

    /**
    * @dev Add this modifier to a function to require
    * that the msg.sender is on the allowlist.
    */
    modifier requireAllowlist() {
        require(allowlist[msg.sender] > 0, "Allowlist: caller is not on the allowlist");
        _;
    }
}