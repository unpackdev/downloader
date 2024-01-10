pragma solidity ^0.8.2;

contract Mortal {
    /* Define variable owner of the type address */
    address owner;

    /* This function is executed at initialization and sets the owner of the contract */
    constructor()  { owner = msg.sender; }

    /* Function to recover the funds on the contract */
    function kill() public  { if (msg.sender == owner) selfdestruct(payable(owner)); }
}