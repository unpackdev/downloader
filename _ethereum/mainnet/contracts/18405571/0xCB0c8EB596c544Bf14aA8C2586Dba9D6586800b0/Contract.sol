// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleCounter {
    uint256 public counter;
    address public owner;
    constructor() {
        owner = msg.sender;
        counter - 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You have not permision to do this. (Only owner)");
        _;
    }

    function increment() public {
        counter++;
    }

    function decrement() public {
        require(counter > 0, "Conter can not be Negative!");
        counter--;
    }

    function reset() public onlyOwner{
        counter = 0;
    }

    function getCounter() public view returns(uint256){
        return counter;
    }
}