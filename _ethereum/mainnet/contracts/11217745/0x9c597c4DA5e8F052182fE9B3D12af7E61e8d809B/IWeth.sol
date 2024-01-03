pragma solidity ^0.5.0;

contract IWeth {
    function deposit() public payable;
    function withdraw(uint256 amount) public;
}