pragma solidity ^0.5.16;

contract Lock {
    address private owner;
    bool public lock;

    modifier onylOwner {
        require(msg.sender == owner, "Lock: onlyOwner");
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function setLock() external {
        lock = true;
    }

    function resetLock() external onylOwner {
        lock = false;
    }
}