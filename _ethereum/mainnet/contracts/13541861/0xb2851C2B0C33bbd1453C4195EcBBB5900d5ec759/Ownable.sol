// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;

// The Ownable contract has an owner address, and provides basic
// authorization control functions, this simplifies the implementation of
// "user permissions". Subclasses are responsible for initializing the
// `owner` property (it is not done in a constructor to faciliate use of
// a factory proxy pattern).
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}
