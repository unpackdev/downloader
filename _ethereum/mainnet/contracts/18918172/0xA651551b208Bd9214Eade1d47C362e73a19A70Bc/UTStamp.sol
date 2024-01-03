// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title UTStamp
 */
contract UTStamp {
    address public owner;

    string public stamp;

    event StampCommit(string indexed stampIndex, string stamp);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier validate(string memory newStamp) {
        require(bytes(newStamp).length == 64, "stamp length should be 64");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function commitStamp(string memory newStamp)
        public
        isOwner
        validate(newStamp)
    {
        emit StampCommit(newStamp, newStamp);
        stamp = newStamp;
    }
}