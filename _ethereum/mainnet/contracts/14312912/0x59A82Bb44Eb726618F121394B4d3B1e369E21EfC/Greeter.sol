pragma solidity ^0.8.2;

import "./Mortal.sol";

contract Greeter is Mortal {
    /* Define variable greeting of the type string */
    string greeting;
    uint16 __num;

    /* This runs when the contract is executed */
    constructor(uint16 _num)  {
        __num = _num;
        greeting = string(abi.encodePacked("Hello World! ", _num));
    }

    /* Main function */
    function greet() public view returns (string memory) {
        return string(greeting);
    }
}