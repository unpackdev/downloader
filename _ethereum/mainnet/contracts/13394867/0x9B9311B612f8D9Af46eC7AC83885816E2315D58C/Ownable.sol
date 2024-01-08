// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Ownable {

    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function getOnwer() public view returns (address) {
        return owner;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Must be the owner of the contract.");
        _;
    }

    function transferOwnership(address newOwner) public isOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}