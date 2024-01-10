// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;
import "./Address.sol";
import "./Math.sol";

contract Owned is Address, Math {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    /**
        A modifier to only allow modifications by the owner of the contract
    */
    modifier ownerRestricted {
        require(msg.sender == owner, 'ERROR: Can only be called from the owner');
        _;
    }

    /**
        Reassigns the owner to the contract specified
    */
    function assignOwner(address _address) ownerRestricted isValidAddress(_address) isNotAddress(_address, owner) public {
        owner = _address;
    }
}