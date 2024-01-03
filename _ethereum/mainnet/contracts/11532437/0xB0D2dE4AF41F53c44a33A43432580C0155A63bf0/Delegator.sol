pragma solidity ^0.6.0;



contract Delegator {
    address payable owner;
    address implementation;

    constructor(address _implementation) public {
        owner = msg.sender;
        implementation = _implementation;
    }

    function setOwner(address payable _newOwner) external {
        require(msg.sender == owner);
        owner = _newOwner;
    }

    function upgrade(address _newImplementation) external {
        require(msg.sender == owner);
        implementation = _newImplementation;
    }
}
